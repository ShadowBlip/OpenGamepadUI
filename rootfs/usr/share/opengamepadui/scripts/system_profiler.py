#!/sbin/python3
# System Profiler
# Copyright 2022-2023 Derek J. Clark <derekjohn dot clark at gmail dot com>
# Produces an output file that caputres relevant system data that can be uploaded
# to github when reporting a new device.

import asyncio
import signal

from evdev import InputDevice, list_devices

# Declare global variables
event_devices = None
captured_keys = []
keybd = None
proc_devices = None
sys_id = None
sys_vendor = None
xb360 = None
user = None

import os
import getpass
import pwd

def get_user():
    """Try to find the user who called sudo/pkexec."""
    try:
        return os.getlogin()
    except OSError:
        pass

    try:
        user = os.environ['USER']
    except KeyError:
        # possibly a systemd service. no sudo was used
        return getpass.getuser()

    if user == 'root':
        try:
            return os.environ['SUDO_USER']
        except KeyError:
            # no sudo was used
            pass

        try:
            pkexec_uid = int(os.environ['PKEXEC_UID'])
            return pwd.getpwuid(pkexec_uid).pw_name
        except KeyError:
            # no pkexec was used
            pass

    return user

def capture_system():
    
    global event_devices
    global keybd
    global proc_devices
    global sys_id
    global sys_vendor
    global xb360

    kb_path = None
    xb_path = None

    # Identify the current device type. Kill script if not compatible.
    sys_id = open("/sys/devices/virtual/dmi/id/product_name", "r").read().strip()
    sys_vendor = open("/sys/devices/virtual/dmi/id/sys_vendor", "r").read().strip()
    proc_devices = open("/proc/bus/input/devices").read()

    # Identify system input event devices.
    devices = [InputDevice(path) for path in list_devices()]
    for device in devices:
        
        # Xbox 360 Controller
        if device.name in ['Microsoft X-Box 360 pad', 'Generic X-Box pad', 'OneXPlayer Gamepad']:
            xb_path = device.path

        # Keyboard Device
        elif device.name in ['AT Translated Set 2 keyboard', '  Mouse for Windows']:
            kb_path = device.path
    
    # Catch if devices weren't found.
    if not xb_path or kb_path:
        event_devices = devices

    # Grab the built-in devices.
    if kb_path:
        keybd = InputDevice(kb_path)
    if xb_path:
        xb360 = InputDevice(xb_path)

async def capture_events(device):
    
    global captured_keys
    current = []

    # Capture events for the given device.
    async for event in device.async_read_loop():

        # We use active keys instead of ev1.code as we will override ev1 and
        # we don't want to trigger additional/different events when doing that
        active = device.active_keys()
        captured_keys.append(["Event type: " + str(event.type), " Event code: " + str(event.code), " Event value: " + str(event.value)])


def save_capture():
    
    global event_devices
    global captured_keys
    global keybd
    global proc_devices
    global sys_id
    global sys_vendor
    global xb360
    user = get_user()
    with open('/home/'+user+'/'+sys_id+'_system_profile.txt', 'w') as f:
        
        # System ID
        f.write('System Data\n')
        f.write('ID: ' + sys_id + '\n')
        f.write('Vendor: ' + sys_vendor + '\n')
        f.write('\n')

        # Proc Devices
        f.write("/proc/bus/input/devices:\n")
        f.write(proc_devices)

        # All Devices:
        f.write('All Devices:')
        if event_devices:
            for d in event_devices:
                f.write('\n')
                f.write(d.name)
                f.write(' | ')
                f.write(d.phys)
                f.write(' | ')
                f.write('bustype: ')
                f.write(str(d.info.bustype))
                f.write(' vendor: ')
                f.write(str(d.info.vendor))
                f.write(' product: ')
                f.write(str(d.info.product))
                f.write(' version: ')
                f.write(str(d.info.version))
        f.write('\n\n')

        # Captured Keys
        f.write('Captured Key Events:\n')
        for keymap in captured_keys:
            f.write(str(keymap))
            f.write('\n')
    print('Capture complete. Please upload the (DeviceName)_system_profile.txt \
    file in a new GitHub issue to https://github.com/ShadowBlip/HandyGCCS/issues \
    and any additional information you have.')


def main(killer):
    print('Gathering system info...')
    
    capture_system()
    
    if xb360 and keybd:
        print('Successfully identified compatible controllers. Press each \
non-functioning button in succession. When complete press ctrl+c to end capture.')
    else:
        print('Unable to identify compatible controller. Additional steps may be \
required after uploading your capture file to fully integrate your device.')
        killer.alive = False 
        return

    # Run asyncio loop to capture all events
    asyncio.ensure_future(capture_events(xb360))
    asyncio.ensure_future(capture_events(keybd))
        
    loop = asyncio.get_event_loop()
    loop.run_forever()


class GracefulKiller:
    alive = True

    def __init__(self):
        signal.signal(signal.SIGINT, self.exit_gracefully)
        signal.signal(signal.SIGTERM, self.exit_gracefully)

    def exit_gracefully(self, *args):
        self.alive = False
        save_capture()
        exit(0)

if __name__ == "__main__":
    print('Scanning system and creating device profile.')
    killer = GracefulKiller()
    while killer.alive:
        main(killer)
    save_capture()
    exit(0)
