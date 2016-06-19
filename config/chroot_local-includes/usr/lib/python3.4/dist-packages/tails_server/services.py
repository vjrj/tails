import os
import collections
import importlib.machinery

from tails_server import config

SERVICES_DIR = config.SERVICES_DIR

service_names = list()
service_module_paths = collections.OrderedDict()


class DuplicateServiceError(Exception):
    pass


def load_service_names():
    global service_names
    global service_module_paths
    service_module_paths = collections.OrderedDict()
    filenames = os.listdir(SERVICES_DIR)
    filenames.sort()
    for filename in filenames:
        root = os.path.splitext(filename)[0]
        name = os.path.basename(root)
        if name.startswith("__"):
            continue
        if name in service_module_paths:
            raise DuplicateServiceError("Multiple files for service %r" % root)
        service_module_paths[name] = os.path.join(SERVICES_DIR, filename)
    service_names = list(service_module_paths.keys())


def import_service_modules():
    service_modules = collections.OrderedDict()
    for service_name in service_names:
        module_path = service_module_paths[service_name]
        source_file_loader = importlib.machinery.SourceFileLoader(service_name, module_path)
        service_modules[service_name] = source_file_loader.load_module()
    # print("service_modules: %r" % service_modules)
    return service_modules

load_service_names()
# print("service_names: %r" % service_names)
# print("service_module_paths: %r" % service_module_paths)