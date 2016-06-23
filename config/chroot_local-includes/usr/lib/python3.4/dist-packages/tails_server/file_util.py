import os
import sh
import json

from tails_server.config import ANSIBLE_PLAYBOOK_DIR

# XXX: Use an existing solution to modify config files, e.g. Ansible


def ansible_add_hs_to_torrc(service_name, content):
    playbook = os.path.join(ANSIBLE_PLAYBOOK_DIR, "add_hs.yml")
    extra_vars = {"service_name": service_name, "content": content}
    sh.ansible_playbook(playbook, "--extra-vars", json.dumps(extra_vars))


def ansible_remove_hs_from_torrc(service_name):
    playbook = os.path.join(ANSIBLE_PLAYBOOK_DIR, "remove_hs.yml")
    extra_vars = {"service_name": service_name}
    sh.ansible_playbook(playbook, "--extra-vars", json.dumps(extra_vars))


def append_to_file(file_path, s):
    with open(file_path, 'a+') as f:
        f.write(s)


def prepend_to_file(file_path, s):
    with open(file_path, 'r') as original:
        original_content = original.read()
    with open(file_path, 'w') as f:
        f.write(s + original_content)


def append_line_if_not_present(file_path, line_):
    with open(file_path, 'r+') as f:
        if line_ in f.readlines():
            return False
        f.write(line_)
        return True


def remove_line_if_present(file_path, line_):
    removed = False
    with open(file_path, 'r') as f:
        lines = f.readlines()
    for i, line in enumerate(lines):
        if line == line_:
            del lines[i]
            removed = True
    with open(file_path, 'w+') as f:
        f.writelines(lines)
    return removed


def delete_lines_starting_with(file_path, s):
    with open(file_path, 'r') as f:
        lines = f.readlines()
    for i, line in enumerate(lines):
        if line.startswith(s):
            del lines[i]
    with open(file_path, 'w+') as f:
        f.writelines(lines)


def insert_to_section(file_path, section_name, s):
    def write_to_file():
        with open(file_path, 'w+') as f:
            f.writelines(lines)

    with open(file_path, 'r') as f:
        lines = f.readlines()
    for i, line in enumerate(lines):
        if line.startswith("[%s]" % section_name):
            lines.insert(i+1, s)
            write_to_file()
            return

    lines.append("[%s]" % section_name)
    lines.append(s)


def delete_section(file_path, section_name):
    def delete_until_next_section(lines):
        for i, line in enumerate(lines):
            if line.startswith("["):
                return
            del lines[i]

    with open(file_path, 'r') as f:
        lines = f.readlines()
    for i, line in enumerate(lines):
        if line.startswith("[%s]" % section_name):
            print("in line %s found %s" % (i, line))
            delete_until_next_section(lines[i:])
    with open(file_path, 'w+') as f:
        f.writelines(lines)


def find_line_starting_with(file_path, s):
    with open(file_path, 'r') as f:
        lines = f.readlines()
    for line in lines:
        if line.startswith(s):
            return line
