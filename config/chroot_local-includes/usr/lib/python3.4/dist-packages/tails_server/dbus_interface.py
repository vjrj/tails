import dbus
import dbus.mainloop.glib
from gi.repository import GLib
import threading
import logging

dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)


class StatusMonitor(object):

    def __init__(self, service_name, status_receiver_function):
        logging.debug("Initializing status monitor for service %r", service_name)
        self.service_name = service_name
        self.status_receiver = status_receiver_function

        self.bus = dbus.SystemBus()
        self.systemd = self.bus.get_object('org.freedesktop.systemd1', '/org/freedesktop/systemd1')
        self.manager = dbus.Interface(self.systemd,
                                      dbus_interface='org.freedesktop.systemd1.Manager')
        self.unit = self.manager.LoadUnit(self.service_name)
        self.loop = GLib.MainLoop()
        self.threads = list()
        # proxy = bus.get_object('org.freedesktop.systemd1', str(unit))
        # # interface = Interface(proxy, dbus_interface='org.freedesktop.systemd1.Unit')
        # proxy.Get('org.freedesktop.systemd1.Unit', 'ActiveState', dbus_interface='org.freedesktop.DBus.Properties')

    def signal_receiver(self, interface_name, changed_properties, invalidated_properties, **kwargs):
        if 'ActiveState' in changed_properties:
            logging.debug("%r ActiveState: %r", self.service_name, changed_properties[
                'ActiveState'])
            self.status_receiver(changed_properties['ActiveState'])
        if 'SubState' in changed_properties:
            logging.debug("%r SubState: %r", self.service_name, changed_properties['SubState'])
        # XXX: We have to listen to "SubState" too, because if the systemd unit has
        # "RemainAfterExit" enabled, then the ActiveState will remain "active" after the service
        # exited and only the SubState is set to "exited". Now actually, this "RemainAfterExit"
        # should simply not be enabled for units which run a daemon - but unfortunately, all
        # systemd units generated from Sys V init files have this set to true.
        # See https://bugs.launchpad.net/ubuntu/+source/apache2/+bug/1488962/comments/5

    def run(self):
        logging.info("Starting status monitor for service %r", self.service_name)
        thread = threading.Thread(target=self.add_signal_receiver, args=(self.signal_receiver,))
        self.threads.append(thread)
        thread.start()

    def stop(self):
        if self.loop.is_running:
            logging.info("Stopping status monitor for service %r", self.service_name)
            self.loop.quit()

    def add_signal_receiver(self, receiver_function):
        self.bus.add_signal_receiver(
            receiver_function,
            None,
            'org.freedesktop.DBus.Properties',
            path=self.unit,
            sender_keyword='sender',
            destination_keyword='destination',
            member_keyword='member',
            path_keyword='path'
        )
        # self.loop.run()


def get_active_status(interface_name, changed_properties, invalidated_properties, **kwargs):
    if 'ActiveState' in changed_properties:
        print(changed_properties['ActiveState'])

# mumble_monitor = StatusMonitor("mumble-server.service", "foo")
# mumble_monitor.add_signal_receiver(get_active_status)