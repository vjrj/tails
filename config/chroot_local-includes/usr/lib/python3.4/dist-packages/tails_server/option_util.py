from tails_server import service_option_template
from tails_server import file_util

# XXX: Use an existing solution to parse config files


def get_option(file_path, s):
    try:
        line = file_util.find_line_starting_with(file_path, s)
    except FileNotFoundError as e:
        raise service_option_template.OptionNotFoundError(e.strerror)
    if not line:
        raise service_option_template.OptionNotFoundError(
            "Could not find line starting with %r in file %r" % (s, file_path))
    return line.replace(s, "").rstrip()