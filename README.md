# Headless Configuration and Deployment for Raspberry Pi Zero

This is a set of utilities for making configuration changes and updates on a Raspberry Pi Zero without needing to connect it to a monitor or keyboard.


## Supported Devices

Tested with the Pi Zero W and Pi Zero 2 W with Raspberry Pi OS 11 (Bullseye). It should also work with the non-wireless, original Pi Zero, but that hasn't been tested.



## Working Raspbian OS Version

Tested with Raspbian OS 11 (Bullseye) Legacy. It should also work with other Bullseye variants.

**NOTE (Jan 2024): not compatable with Bookworm.**
There have been several updates to how Bookworm is configured which will require a number of changes. Use Bullseye for now.



## Features

Deployment changes are configured in the boot partition of the sdcard, and can then be deployed to the device during boot. Additionally, the device is configured to provide USB access to both a serial terminal and an ethernet device. This is helpful for administering and debugging a device when WiFi is absent or misconfigured.

Features:
- headless serial port and ethernet access via USB
- DHCP on the USB ethernet for easy access on a laptop
- copy a user-supplied script to the sdcard and have it run during boot
- reset the user password without connecting a monitor or keyboard


## Instructions

After installing stock Raspbian, copy the deploy directory to the SD card boot partition and refer to the installation instructions in deploy/README.md.

