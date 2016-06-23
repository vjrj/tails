import os
import abc
import shutil
import sh
import logging
import yaml

from tails_server import config
from tails_server import file_util

TOR_DIR = config.TOR_DIR
TOR_USER = config.TOR_USER
TOR_SERVICE = config.TOR_SERVICE
TORRC = config.TORRC
PERSISTENCE_DIR = config.PERSISTENCE_DIR
PERSISTENCE_DIR_NAME = config.PERSISTENCE_DIR_NAME
PERSISTENCE_CONFIG = config.PERSISTENCE_CONFIG

PERSISTENT_TORRC = "/usr/share/tor/tor-service-defaults-torrc"
CONFIG_DIR_PREFIX = "config_"


class AlreadyPersistentError(Exception):
    pass


class NotPersistentError(Exception):
    pass


class OptionNotFoundError(Exception):
    pass


class TailsServiceOption(metaclass=abc.ABCMeta):
    @property
    @abc.abstractmethod
    def name(self):
        pass

    @property
    def name_in_gui(self):
        return self.name.replace("-", " ").title()

    @property
    @abc.abstractmethod
    def description(self):
        pass

    @property
    @abc.abstractmethod
    def type(self):
        pass

    @property
    @abc.abstractmethod
    def default(self):
        pass

    @property
    def value(self):
        return self._value

    @value.setter
    def value(self, value):
        if self.type == bool and type(value) != bool:
            choices = ["true", "false"]
            if value.lower() not in choices:
                self.service.arg_parser.error("Invalid value %r for option %r. Possible values: %r"
                                              % (value, self.name, choices))
            value = value.lower() == "true"
        logging.debug("New value: %r, old value: %r", self._value, value)
        if self._value != value:
            self._value = value
            self.on_value_changed()


    @property
    def info_attributes(self):
        return {
            "name": self.name,
            "description": self.description,
            "type": self.type,
            "default": self.default,
            "value": self.value,
        }

    group = None

    def __init__(self, service):
        self.service = service        
        try:
            self._value = self.load()
        except OptionNotFoundError as e:
            logging.debug("OptionNotFoundError: " + str(e))
            self._value = self.default
            self.store()

    def load(self):
        try:
            return self.do_load()
        except (FileNotFoundError, ValueError, TypeError):
            self.service.create_options_file()
            return self.do_load()

    def do_load(self):
        logging.debug("Loading option %r", self.name)
        with open(self.service.options_file) as f:
            options = yaml.load(f)
            logging.debug("options: %r", options)
        if self.name not in options:
            raise OptionNotFoundError("Could not find option %r in %r" %
                                      (self.name, self.service.options_file))
        return options[self.name]

    def store(self):
        logging.debug("Storing option %r", self.name)
        with open(self.service.options_file) as f:
            options = yaml.load(f)
        options[self.name] = self.value
        with open(self.service.options_file, 'w+') as f:
            yaml.dump(options, f, default_flow_style=False)

    def on_value_changed(self):
        logging.debug("Option %r set to %r", self.name, self.value)
        self.store()
        self.apply()

    def apply(self):
        logging.debug("Applying option %s", self.name)

    def __str__(self):
        return "%s: %s" % (self.name, self.value)


class VirtualPort(TailsServiceOption):
    name = "virtual-port"
    description = "Port opened on the Tor network"
    type = int
    group = "connection"

    @property
    def default(self):
        logging.debug("VirtualPort default value: %r" % self.service.default_virtual_port)
        return self.service.default_virtual_port


class AllowLanOption(TailsServiceOption):
    name = "allow-lan"
    name_in_gui = "Allow LAN"
    description = "Allow connections from the local network"
    type = bool
    default = False
    group = "generic-checkbox"

    @property
    def rule(self):
        return ["OUTPUT", "--out-interface", "lo", "--protocol", "tcp", "--dport",
                self.service.target_port, "--jump", "ACCEPT"]

    def apply(self):
        super().apply()
        if self.value:
            self.accept_lan_connections()
        else:
            self.reject_lan_connections()

    def accept_lan_connections(self):
        sh.iptables("-I", *self.rule)

    def reject_lan_connections(self):
        sh.iptables("-D", *self.rule)


class AutoStartOption(TailsServiceOption):
    name = "autostart"
    name_in_gui = "Autostart"
    description = "Start service automatically after booting Tails"
    type = bool
    default = False
    group = "generic-checkbox"

    def apply(self):
        super().apply()
        raise NotImplementedError()


class PersistenceOption(TailsServiceOption):
    PERSISTENT_HS_DIR = "hidden_service"
    PERSISTENT_OPTIONS_FILE = "options"

    name = "persistence"
    name_in_gui = "Persistent"
    description = "Store service configuration and data on the persistent volume"
    type = bool
    default = False
    group = "generic-checkbox"

    @property
    def persistence_dir(self):
        return os.path.join(PERSISTENCE_DIR, self.service.name)

    def apply(self):
        super().apply()
        if self.value:
            self.make_persistent()
        else:
            self.remove_persistence()

    def make_persistent(self):
        self.create_persistence_dirs()
        self.service.create_hs_dir()
        self.make_path_persistent(self.service.hs_dir, persistence_name=self.PERSISTENT_HS_DIR)
        self.make_path_persistent(self.service.options_file,
                                  persistence_name=self.PERSISTENT_OPTIONS_FILE)
        self.make_config_files_persistent()
        self.service.add_to_additional_software()

    def create_persistence_dirs(self):
        if not os.path.exists(PERSISTENCE_DIR):
            os.mkdir(PERSISTENCE_DIR)
            os.chmod(PERSISTENCE_DIR, 0o755)
        if not os.path.exists(self.persistence_dir):
            os.mkdir(self.persistence_dir)
            os.chmod(self.persistence_dir, 0o755)

    def make_path_persistent(self, path, persistence_name=None):
        if not persistence_name:
            persistence_name = os.path.basename(path)
        self.add_to_persistence_config(path, persistence_name)
        if os.path.isdir(path):
            self.move_to_persistence_volume(path, persistence_name)
            os.mkdir(path)
        else:
            self.move_to_persistence_volume(path, persistence_name)
            open(path, 'w+').close()
        sh.mount("--bind", os.path.join(self.persistence_dir, persistence_name), path)

    def add_to_persistence_config(self, path, persistence_name):
        line = "%s source=%s\n" % (
            path, os.path.join(PERSISTENCE_DIR_NAME, self.service.name, persistence_name))
        self.add_line_to_persistence_config(line)

    def add_line_to_persistence_config(self, line):
        written = file_util.append_line_if_not_present(PERSISTENCE_CONFIG, line)
        if not written:
            raise AlreadyPersistentError(
                "Service %r already seems to have an entry in persistence config file %r" %
                (self.service.name, PERSISTENCE_CONFIG))
        logging.debug("Added line to persistence.config: %r", line)

    def move_to_persistence_volume(self, path, persistence_name):
        dest = os.path.join(self.persistence_dir, persistence_name)
        if os.path.isdir(path):
            shutil.copytree(path, dest)
            shutil.rmtree(path)
        else:
            shutil.move(path, dest)
        logging.debug("Copied %r to %r", path, dest)

    def make_config_files_persistent(self):
        for path in self.service.persistent_paths:
            self.make_path_persistent(path)

    def remove_persistence(self):
        self.remove_from_persistence(self.service.hs_dir, self.PERSISTENT_HS_DIR)
        self.remove_from_persistence(self.service.options_file,
                                     persistence_name=self.PERSISTENT_OPTIONS_FILE)
        self.remove_config_files_from_persistence()
        self.service.remove_from_additional_software()

    def remove_from_persistence(self, path, persistence_name=None):
        if not persistence_name:
            persistence_name = os.path.basename(path)
        try:
            self.remove_from_persistence_config(path, persistence_name)
        except NotPersistentError as e:
            logging.error(e)
        self.remove_from_persistence_volume(path, persistence_name)

    def remove_from_persistence_volume(self, path, persistence_name):
        try:
            sh.umount(path)
        except sh.ErrorReturnCode_32 as e:
            logging.error(e)

        try:
            if os.path.isdir(path):
                os.rmdir(path)
            else:
                os.remove(path)
        except FileNotFoundError as e:
            logging.error(e)

        try:
            # shutil.move doesn't preserve ownership, so we use sh.mv here instead
            sh.mv(os.path.join(self.persistence_dir, persistence_name), path)
        except FileNotFoundError as e:
            logging.error(e)

    def remove_from_persistence_config(self, path, persistence_name):
        line = "%s source=%s\n" % (
            path, os.path.join(PERSISTENCE_DIR_NAME, self.service.name, persistence_name))
        self.remove_line_from_persistence_config(line)

    def remove_line_from_persistence_config(self, line):
        logging.debug("Removing line %r from persistence.conf", line)
        removed = file_util.remove_line_if_present(PERSISTENCE_CONFIG, line)
        if not removed:
            raise NotPersistentError(
                "Service %r seems to have no entry in persistence config file %r. "
                "Line not found: %r" % (self.service.name, PERSISTENCE_CONFIG, line))

    def remove_config_files_from_persistence(self):
        for path in self.service.persistent_paths:
            self.remove_from_persistence(path)
