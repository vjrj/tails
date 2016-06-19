import argparse
import sys

import tails_server.services

service_names = tails_server.services.service_names


class HelpfulParser(argparse.ArgumentParser):
    def error(self, message):
        sys.stderr.write('error: %s\n' % message)
        self.print_help()
        sys.exit(2)


class CommandParser(HelpfulParser):
    descriptions = {
        'info': "Print information about the service",
        'status': "Print whether the service is installed and running",
        'install': "Install the service",
        'enable': "Install, configure, and start the service",
        'disable': "Stop the service",
        'get-option': "Print the current value of an option",
        'set-option': "Set an option. If the service is running, the option will be applied "
                      "immediately and, if necessary, the service will be restarted!",
        'reset-option': "Same as set-option, but using the option's default value"
    }

    service_commands = descriptions.keys()

    def add_service_command(self, command_name, *arguments):
        command = self.subparsers.add_parser(command_name,
                                             help=self.descriptions[command_name],
                                             description=self.descriptions[command_name])
        for argument in arguments:
            command.add_argument(**argument)
        return command

    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.add_argument("--verbose", "-v", action="store_true")

        self.subparsers = self.add_subparsers(dest="command", parser_class=HelpfulParser)
        info_parser = self.add_service_command("info")
        info_parser.add_argument("--details", action="store_true")

        self.add_service_command("status")
        self.add_service_command("install")
        self.add_service_command("enable")
        self.add_service_command("disable")
        self.add_service_command("get-option", {"dest": "OPTION", "type": str})
        self.add_service_command("set-option", {"dest": "OPTION", "type": str},
                                 {"dest": "VALUE", "type": str})
        self.add_service_command("reset-option", {"dest": "OPTION", "type": str})

    def parse_args(self, **kwargs):
        args = super().parse_args(**kwargs)

        if not any(vars(args).values()):
            self.print_help()
            self.exit()

        return args


class WrapperParser(CommandParser):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.subparsers.add_parser("list", help="Print list of available services")
        self.subparsers.add_parser("list-enabled", help="Print list of enabled services")

    def add_service_command(self, command_name, *arguments):
        command = super().add_service_command(command_name, *arguments)
        command.add_argument(dest="SERVICE", type=str, metavar="SERVICE", choices=service_names)
        return command


class ServiceParser(CommandParser):
    pass
