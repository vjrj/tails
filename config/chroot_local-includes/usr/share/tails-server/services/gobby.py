#!/usr/bin/env python3

import logging
import os
import sh
import random
import string

from tails_server import file_util
from tails_server import option_util
from tails_server import service_template
from tails_server import service_option_template

CONFIG_FILE = "/etc/xdg/infinoted.conf"
DATA_DIR = "/var/lib/infinoted"
DOCS_DIR = os.path.join(DATA_DIR, "docs")
LOG_FILE = os.path.join(DATA_DIR, "infinoted.log")


class ServerPasswordOption(service_option_template.TailsServiceOption):
    DEFAULT_LENGTH = 20
    name = "server-password"
    description = "Password required to connect to service"
    type = str

    @property
    def default(self):
        return ''.join(random.SystemRandom().choice(string.ascii_letters + string.digits) for _ in
                       range(self.DEFAULT_LENGTH))

    def store(self):
        file_util.delete_lines_starting_with(CONFIG_FILE, "password=")
        if self.value:
            file_util.insert_to_section(CONFIG_FILE, "[infinoted]", "password=%s\n" % self.value)

    def load(self):
        value = option_util.get_option(CONFIG_FILE, "password=")
        return value


class AutoSaveInterval(service_option_template.TailsServiceOption):
    name = "autosave-interval"
    description = "Interval in seconds to automatically save all open documents"
    default = 30
    type = int

    def store(self):
        file_util.delete_section(CONFIG_FILE, "autosave")
        file_util.append_to_file(CONFIG_FILE, "\n[autosave]\n")
        file_util.append_to_file(CONFIG_FILE, "interval=%s\n" % self.value)

    def load(self):
        value = option_util.get_option(CONFIG_FILE, "interval=")
        return value


class GobbyServer(service_template.TailsService):
    name = "gobby"
    systemd_service = "gobby-server.service"
    description = "A collaborative text editor"
    packages = ["infinoted"]
    default_target_port = 6523
    documentation = "file:///usr/share/doc/tails/website/doc/tails_server/gobby.en.html"
    persistent_paths = [CONFIG_FILE, DATA_DIR]
    icon_name = "gobby-0.5"

    options = [
        service_option_template.PersistenceOption,
        service_option_template.AutoStartOption,
        service_option_template.AllowLanOption,
        ServerPasswordOption,
        AutoSaveInterval,
    ]

    # def start(self):
    #     logging.info("Starting gobby server infinoted")
    #     sh.infinoted("-d")
    #
    # def stop(self):
    #     logging.info("Stopping gobby server infinoted")
    #     sh.infinoted("-D")

    def install(self):
        super(GobbyServer, self).install()
        self.configure()

    def configure(self):
        with open(CONFIG_FILE, "w+") as f:
            f.write("[infinoted]\n")
            f.write("root-directory=%s\n" % DATA_DIR)
            f.write("log-file=%s\n" % LOG_FILE)
            f.write("security-policy=no-tls\n")
        if not os.path.isdir(DATA_DIR):
            os.mkdir(DATA_DIR, mode=0o700)


service_class = GobbyServer


def main():
    service = service_class()
    args = service.arg_parser.parse_args()
    service.set_up_logging(args)
    service.dispatch_command(args)

if __name__ == "__main__":
    main()
