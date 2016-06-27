import os
import shutil
import abc
import sh
import logging
from collections import OrderedDict
import inspect
import time

import yaml
import yaml.resolver
import apt
import stem.control

from tails_server import config
from tails_server import file_util
from tails_server import util
from tails_server import argument_parser
from tails_server import service_option_template

TOR_DIR = config.TOR_DIR
TOR_USER = config.TOR_USER
TOR_SERVICE = config.TOR_SERVICE
TORRC = config.TORRC
TOR_CONTROL_PORT = config.TOR_CONTROL_PORT
ADDITIONAL_SOFTWARE_CONFIG = config.ADDITIONAL_SOFTWARE_CONFIG
STATE_DIR = config.STATE_DIR
OPTIONS_FILE_NAME = config.OPTIONS_FILE_NAME


class UnknownOptionError(Exception):
    pass


class ServiceAlreadyEnabledError(Exception):
    pass


class ServiceNotInstalledError(Exception):
    pass


class TorIsNotRunningError(Exception):
    pass


class LazyOptionDict(OrderedDict):
    """Expects classes as it's values. Returns an instance of the respective class."""
    def __init__(self, service, *args, **kwargs):
        self.service = service
        super().__init__(*args, **kwargs)

    def __getitem__(self, key):
        item = super(LazyOptionDict, self).__getitem__(key)
        if inspect.isclass(item):
            logging.debug("Instantiating %r", item)
            self.__setitem__(key, item(self.service))
        return super(LazyOptionDict, self).__getitem__(key)


class TailsService(metaclass=abc.ABCMeta):

    arg_parser = argument_parser.ServiceParser()

    @classmethod
    def set_up_logging(cls, args):
        format_ = '%(levelname)s %(message)s'
        if args.verbose:
            logging.basicConfig(format=format_, level=logging.DEBUG)
        else:
            logging.basicConfig(format=format_, level=logging.INFO)
        logging.debug("args: %r", args)

    @property
    @abc.abstractmethod
    def name(self):
        """The name of the service, as used in the CLI.
        This should be the same as the basename of the service's script."""
        return str()

    @property
    def name_in_gui(self):
        """The name of the service, as displayed in the GUI."""
        return self.name.capitalize()

    @property
    @abc.abstractmethod
    def description(self):
        return str()

    @property
    @abc.abstractmethod
    def packages(self):
        return list()

    @property
    def systemd_service(self):
        """The name of the service's systemd service"""
        return self.name

    @property
    @abc.abstractmethod
    def default_target_port(self):
        return int()

    @property
    def target_port(self):
        if "target-port" in self.options_dict:
            return self.options_dict["target-port"].value
        return self.default_target_port

    @property
    def default_virtual_port(self):
        return self.default_target_port

    @property
    def virtual_port(self):
        if "virtual-port" in self.options_dict:
            return self.options_dict["virtual-port"].value
        return self.default_virtual_port

    @property
    def connection_string(self):
        if self.address:
            return "%s:%s" % (self.address, self.virtual_port)
        return None

    @property
    def connection_string_in_gui(self):
        return self.connection_string

    @property
    @abc.abstractmethod
    def icon_name(self):
        return str()

    documentation = str()
    persistent_paths = list()

    options = [
        service_option_template.AllowLanOption,
        service_option_template.PersistenceOption,
    ]

    _options_dict = None

    @property
    def options_dict(self):
        if not self._options_dict:
            self._options_dict = LazyOptionDict(
                self, [(option.name, option) for option in self.options])
        return self._options_dict

    @property
    def is_installed(self):
        cache = apt.Cache()
        if any(package not in cache for package in self.packages):
            return False
        return all(cache[package].is_installed for package in self.packages)

    @property
    def is_running(self):
        try:
            sh.systemctl("is-active", self.systemd_service)
        except sh.ErrorReturnCode_3:
            return False
        return True

    @property
    def is_persistent(self):
        if "persistence" not in self.options_dict:
            return False
        return self.options_dict["persistence"].value

    @property
    def address(self):
        try:
            with open(self.hs_hostname_file, 'r') as f:
                return f.read().strip()
        except FileNotFoundError:
            return None

    @property
    def info_attributes(self):
        return OrderedDict([
            ("description", self.description),
            ("installed", self.is_installed),
            ("running", self.is_running),
            ("address", self.address),
            ("local-port", self.target_port),
            ("remote-port", self.virtual_port),
            ("persistent-paths", self.persistent_paths),
            ("options", OrderedDict([(option.name, option.value) for option in
                                     self.options_dict.values()])),
        ])

    @property
    def info_attributes_all(self):
        attributes = OrderedDict()
        attributes["name"] = self.name
        attributes["name-in-gui"] = self.name_in_gui
        attributes.update(self.info_attributes)
        attributes["hidden-service-dir"] = self.hs_dir
        attributes["packages"] = self.packages
        attributes["systemd-service"] = self.systemd_service
        attributes["icon-name"] = self.icon_name
        attributes["options"] = [option.info_attributes for option in self.options_dict.values()]
        return attributes

    @staticmethod
    def print_yaml(*args, **kwargs):
        def _dict_representer(dumper, data):
            return dumper.represent_mapping(yaml.resolver.BaseResolver.DEFAULT_MAPPING_TAG,
                                            data.items())

        class OrderedDictDumper(yaml.Dumper):
            def ignore_aliases(self, data):
                return True

        OrderedDictDumper.add_representer(OrderedDict, _dict_representer)
        print(yaml.dump(*args, Dumper=OrderedDictDumper, default_flow_style=False, **kwargs))

    def __init__(self):
        self.hs_dir = os.path.join(TOR_DIR, self.name)
        self.state_dir = os.path.join(STATE_DIR, self.name)
        if not os.path.exists(self.state_dir):
            self.create_state_dir()
        self.hs_private_key_file = os.path.join(self.state_dir, "hs_private_key")
        self.hs_hostname_file = os.path.join(self.state_dir, "hs_hostname")
        self.options_file = os.path.join(self.state_dir, OPTIONS_FILE_NAME)
        self._target_port = self.default_target_port
        self._virtual_port = self.default_virtual_port

    def instantiate_options(self):
        logging.debug("Instantiating options of %r", self.name)
        for i, option in enumerate(self.options_dict.values()):
            logging.debug("Instantiating option %r", option.name)
            assert (issubclass(option, service_option_template.TailsServiceOption))
            self.options_dict[i] = option(self)

    def get_status(self):
        return {"installed": self.is_installed,
                "enabled": self.is_running}

    def print_status(self):
        status = self.get_status()
        self.print_yaml(status)

    def print_info(self, detailed=False):
        logging.debug("Getting attributes")
        attributes = self.info_attributes_all if detailed else self.info_attributes
        logging.debug("Dumping attributes")
        self.print_yaml(attributes)

    def enable(self, skip_add_onion=False):
        if self.is_running:
            raise ServiceAlreadyEnabledError("Service %r is already enabled" % self.name)
        logging.info("Enabling service %r" % self.name)

        if not self.is_installed:
            self.install()
        self.start()
        self.create_hs_dir()
        if not skip_add_onion:
            self.add_onion()

    def install(self):
        logging.info("Installing packages: %s" % " ".join(self.packages))

        def update_packages():
            logging.info("Updating packages")
            cache.update()

        cache = apt.Cache()
        if any([package not in cache for package in self.packages]):
            update_packages()

        with util.PolicyNoAutostartOnInstallation():
            sh.apt_get("install", "-y", "-o", 'Dpkg::Options::=--force-confold',
                       "--no-install-recommends", self.packages)

        self.configure()

    def configure(self):
        """Initial configuration after installing the service"""
        for option in self.options_dict.values():
            option.value = option.default

    def install_using_apt_module(self):
        # There seems to be no way to automatically keep old config on conflicts with the apt module
        cache = apt.Cache()
        for package in self.packages:
            cache[package].mark_install()
        with util.PolicyNoAutostartOnInstallation():
            cache.commit()
        logging.info("Service %r installed", self.name)

    def uninstall(self):
        if self.is_persistent:
            self.remove_persistence()
        self.uninstall_packages()
        self.remove_options_file()
        self.remove_state_dir()
        if os.path.exists(self.hs_dir):
            self.remove_hs_dir()
        logging.info("Service %r uninstalled", self.name)

    def remove_persistence(self):
        logging.info("Removing persistence of service %r", self.name)
        self.options_dict["persistence"].value = False

    def uninstall_packages(self):
        # XXX: This could delete packages which were not installed by this service
        # (i.e. packages that are required by this service but were already installed)
        logging.info("Uninstalling packages: %s" % " ".join(self.packages))
        cache = apt.Cache()
        for package in self.packages:
            cache[package].mark_delete(purge=True)
        cache.commit()

    def create_state_dir(self):
        logging.debug("Creating state directory %r", self.state_dir)
        os.mkdir(self.state_dir)

    def remove_state_dir(self):
        logging.debug("Removing state directory %r", self.state_dir)
        shutil.rmtree(self.state_dir)

    def create_options_file(self):
        logging.debug("Creating empty options file for %r", self.name)
        with open(self.options_file, "w+") as f:
            yaml.dump(dict(), f)

    def remove_options_file(self):
        logging.info("Removing options file %r", self.options_file)
        os.remove(self.options_file)

    def create_hs_dir(self):
        logging.info("Creating hidden service directory %r", self.hs_dir)
        try:
            os.mkdir(self.hs_dir, mode=0o700)
        except FileExistsError:
            # The UID of debian-tor might change between Tails releases (it did before)
            # This would cause existing persistent directories to have wrong UIDs,
            # so we reset them here
            for dirpath, _, filenames in os.walk(self.hs_dir):
                for filename in filenames:
                    shutil.chown(os.path.join(dirpath, filename), TOR_USER, TOR_USER)
        shutil.chown(self.hs_dir, TOR_USER, TOR_USER)

    def remove_hs_dir(self):
        logging.info("Removing HS directory %r", self.hs_dir)
        shutil.rmtree(self.hs_dir)

    def start(self):
        logging.info("Starting service %r", self.name)
        sh.systemctl("start", self.systemd_service)

    def disable(self):
        self.stop()
        self.remove_hs()

    def stop(self):
        logging.info("Stopping service %r", self.name)
        sh.systemctl("stop", self.systemd_service)

    def get_option(self, option_name):
        try:
            option = self.options_dict[option_name]
        except KeyError:
            raise UnknownOptionError("Service %r has no option %r" % (self.name, option_name))
        self.print_yaml({option.name: option.value})

    def set_option(self, option_name, value):
        if not self.is_installed:
            raise ServiceNotInstalledError("Service %r is not installed" % self.name)

        try:
            option = self.options_dict[option_name]
        except KeyError:
            raise UnknownOptionError("Service %r has no option %r" % (self.name, option_name))

        option.value = value
        option.apply()
        logging.debug("Option %r set to %r", option_name, value)
        return

    def reset_option(self, option_name):
        try:
            option = self.options_dict[option_name]
        except KeyError:
            raise UnknownOptionError("Service %r has no option %r" % (self.name, option_name))
        option.value = option.default
        option.apply()
        logging.debug("Option %r reset to %r", option_name, option.value)
        return

    def add_onion(self):
        # create_hidden_service() fails because the Tor sandbox prevents accessing the filesystem
        # see https://github.com/micahflee/onionshare/issues/179
        logging.debug("Adding HS with create_ephemeral_hidden_service")

        try:
            key_type = "RSA1024"
            with open(self.hs_private_key_file, 'r') as f:
                key_content = f.read()
        except FileNotFoundError:
            key_type = "NEW"
            key_content = "RSA1024"

        if "client-authentication" in self.options_dict:
            client_auth = self.options_dict["client-authentication"].value
        else:
            client_auth = None

        controller = stem.control.Controller.from_port(port=TOR_CONTROL_PORT)
        controller.authenticate()
        response = controller.create_ephemeral_hidden_service(
            ports={self.virtual_port: self.target_port},
            key_type=key_type,
            key_content=key_content,
            discard_key=False,
            detached=True,
            await_publication=True,
            # XXX: This option will be available in stem 1.5.0
            # basic_auth=client_auth
        )

        if response.service_id:
            self.set_onion_address(response.service_id)
        if response.private_key:
            self.set_hs_private_key(response.private_key)
        # XXX: Set client authentication

    def set_onion_address(self, address):
        with open(self.hs_hostname_file, 'w+') as f:
            f.write(address + ".onion")

    def remove_onion_address(self):
        os.remove(self.hs_hostname_file)
        os.remove(self.hs_private_key_file)

    def set_hs_private_key(self, key):
        with open(self.hs_private_key_file, 'w+') as f:
            f.write(key)

    def remove_hs(self):
        logging.debug("Removing HS with remove_ephemeral_hidden_service")
        controller = stem.control.Controller.from_port(port=TOR_CONTROL_PORT)
        controller.authenticate()
        controller.remove_ephemeral_hidden_service(self.address.replace(".onion", ""))

    @staticmethod
    def reload_tor():
        out = None
        while True:
            out = sh.systemctl("is-active", TOR_SERVICE, _ok_code=[0, 3])
            if out.startswith("activating"):
                time.sleep(1)
            else:
                break

        if out.startswith("active"):
            logging.info("Reloading Tor")
            sh.systemctl("reload", TOR_SERVICE)
        else:
            raise TorIsNotRunningError(
                "\"systemctl is-active %s\" returned %r " % (TOR_SERVICE, out))

    def add_to_additional_software(self):
        lines = self.packages
        for line in lines:
            file_util.append_line_if_not_present(ADDITIONAL_SOFTWARE_CONFIG, line)

    def remove_from_additional_software(self):
        lines = self.packages
        for line in lines:
            file_util.remove_line_if_present(ADDITIONAL_SOFTWARE_CONFIG, line)

    def dispatch_command(self, args):
        if args.command == "info":
            return self.print_info(detailed=args.details)
        elif args.command == "status":
            return self.print_status()
        elif args.command == "install":
            return self.install()
        elif args.command == "enable":
            return self.enable()
        elif args.command == "disable":
            return self.disable()
        elif args.command == "get-option":
            return self.get_option(args.OPTION)
        elif args.command == "set-option":
            return self.set_option(args.OPTION, args.VALUE)
        elif args.command == "reset-option":
            return self.reset_option(args.OPTION)
