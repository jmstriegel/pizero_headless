# Headless Configuration and Deployment for Raspberry Pi Zero (Bullseye edition)

A set of utilities for making configuration changes and updates on a Raspberry Pi Zero without needing to connect it to a monitor or keyboard.

Deployment changes are configured in the boot partition of the sdcard, and can then be deployed to the device during boot. Additionally, the device is configured to provide USB access to both a serial terminal and an ethernet device. This is helpful for administering and debugging a device when WiFi is absent or misconfigured.

Features:
- headless serial port and ethernet access via USB
- DHCP on the USB ethernet for easy access on a laptop
- copy a user-supplied script to the sdcard and have it run during boot
- reset the user password without connecting a monitor or keyboard

**NOTE (Jan 2024): this won't work with bookworm.** There have been several updates to how networking is configured which will require a number of changes. Use Bullseye for now.


## Installation

The basic outline looks like this:

 - Step 1: create and configure a normal Raspbian Bullseye SD card, following the official instructions
 - Step 2: place this folder (deploy) in the Raspbian boot partition
 - Step 3: set your initial wpa_supplicant.conf, ssh, userconf.txt, and config.txt
 - Step 4: let the official installer do its first boot
 - Step 5: edit cmdline.txt to run the headless deployment installer
 - Step 6: after installing, you can connect to your Pi Zero over USB and perform future updates via USB or SD card scripts


If you've already installed and booted Raspberry Pi OS Bullseye, you can mostly skip to step 5, but please look at the configuration requirements described in step 3. There may be something you will need to tweak.


### Step 1: Create SD card media

Create a Raspberry Pi OS (Bullseye) sdcard using your preferred method.

Recommended version: Raspberry Pi OS (32-bit) Lite.


### Step 2: Copy this deploy folder to the boot partition

Copy this folder (deploy) to the newly created boot partition. The deployment scripts depend on this being located at `/boot/deploy/` so don't rename it. The boot partition is a normal Windows FAT filesystem, so you should be able to do this on any Windows, Mac or Linux computer.

### Step 3: Configure the stock image with required boot configuration settings

Use the official "first boot" configuration settings to set up your Pi Zero. Below are the standard settings you need to make.

**NOTE:** If you used the official Raspberry Pi Imager program to make your SD card, many of these things are handled for you already. The normal installer handles these changes by making a script named `firstrun.sh`. Pay attention to the notes below for things you can safely ignore.



**/boot/cmdline.txt**
At this step, you probably don't want to change anything from the default here. Depending on which installer you used, there may be some necessary first-run items that need to run before we change anything else.

**IMPORTANT:** Do not load any of the gadget modules (g_ether, g_serial, etc). We will use the "composite gadget" configuration method to enable both ethernet and serial I/O on the USB port. These functions will be copied to `/usr/bin/usb_gadget_composite`, and will be started from `/etc/rc.local` in order to run at the end of every boot. Both of these files will be deployed by the headless update script.


**/boot/config.txt**

Add `dtoverlay=dwc2` to the bottom of your `config.txt`. For an example, see `examples/config.txt.example`.

**/boot/ssh**

NOTE: this is already handled by Raspberry Pi Imager, but if you made your SD card manually, you need this.

Create an empty file with the name `ssh` at the base of the boot partition. Without ssh, you will only have basic serial terminal access.


**/boot/userconf.txt**

NOTE: this is already handled by Raspberry Pi Imager, but if you made your SD card manually, you need this.

If you ran the Raspberry Pi Imager to create your SD card, you've probably already set a username and password. For everyone else, create a userconf.txt file containing a single line, with the following format:

`user:encryptedpassword`

"user" is your desired username, Ie. pi, user, bob or whatever.
"encryptedpassword" is the hashed version of your desired password. Use the following command to generate this:

`openssl passwd -6`

Here's an example of what it should look like, using the username "user" and password "raspberry" as an example:

`user:$6$aYpAWftKauMrS9TO$CQ9jjdLHebVtwEI6ZqPEj3Aq47kkyTpl3mn5ZqcfviYRSwc3Axr8/T5kokVQIB50WQwjW3TZJvMqb06jvzrr20`

**/boot/wpa_supplicant.conf**

NOTE: this is already handled by Raspberry Pi Imager, but if you made your SD card manually, you need this.

This file contains your wireless network configuration. If your created your SD card manually (using dd, for instance), you will need to create this file and update it with your WiFi's SSID and password. An example is in `examples/wpa_supplicant.conf.example`. Make a copy of that and place it in the base of the boot partition, rename it to `wpa_supplicant.conf`, and edit the file to change your country code, SSID, and password.


### Step 4: Boot and wait

The first boot for the Pi Zero can take several minutes. Just give it time. When the standard install is all complete, unplug your Pi. You are finally ready to install the headless deployment configuration.


### Step 5: Install the headless deployment configuration

Modify the `/boot/cmdline.txt` file to trigger the headless deployment installer. Add the following the the very end of the `cmdline.txt`:

```
systemd.run=/boot/deploy/scripts/first_install.sh systemd.run_success_action=reboot systemd.unit=kernel-command-line.target
```

It should look something like this now:

```
console=serial0,115200 console=tty1 root=PARTUUID=95b37beb-02 rootfstype=ext4 fsck.repair=yes rootwait cfg80211.ieee80211_regdom=US  systemd.run=/boot/deploy/scripts/first_install.sh systemd.run_success_action=reboot systemd.unit=kernel-command-line.target

```

**If you configured the network:**

If you configured the WiFi network in Step 3 and your Pi has internet access, copy `/boot/deploy/examples/do_once.sh.installdhcp` to `/boot/deploy/do_once.sh`:

```
cp deploy/examples/do_once.sh.installdhcp deploy/examples/do_once.sh
```

This will set up the USB ethernet device to provide an address to your computer automatically. _The script requires access to the internet to download the necessary package, so this won't work until you have WiFi correctly configured._

**If you haven't yet configured internet access:**

Without DHCP, you will need to manually configure the USB ethernet connection. The Pi will be located at 10.6.6.1. The USB ethernet device, when it becomes available, can be configured with the static IP:

   - IP: 10.6.6.2
   - Netmask 255.255.255.0

Later, when you've set up WiFi, you can manually run `/boot/deploy/scripts/enable_usb_dhcp.sh` as root to set up dhcp on the USB ethernet device.



### Step 6: Connect and allow the headless setup to complete


**Finally!**

Connect the Pi Zero USB port (the one closer to the middle of the board) to your computer. Boot the Pi with your updated SD card to complete the installation.

The installer will make the necessary configuration changes and reboot a couple of times. When it's complete, you will see a heartbeat blinking pattern on the LED before the final reboot. After the final reboot, you should notice a USB serial and ethernet device become available on your computer.

**NOTE:** if you chose to install DHCP in step 5, this could take a really long time, as packages and updates will need to be downloaded over WiFi. Just be patient and wait for the hearbeat LED to know when it's complete. It could take 5-10 minutes.



## Connecting to your device over USB

You can connect directly to your device via the USB cable. Your computer
should see a new ethernet connection as well as a serial device.

The deploy script will configure the USB device to provide serial and
ethernet connectivity to the USB host computer. Make sure `config.txt` has
`dtoverlay=dwc2` at the end. Also, the `cmdline.txt` should NOT load the
USB gadet modules, such as g_ether, g_serial, etc.

The ethernet device will be available at 10.6.6.1. You may need to manually
set your computer's IP address to 10.6.6.2 netmask 255.255.255.0 to be able
to ssh to the device.

Serial access is also provided. In Linux, the device will be available
at /dev/ttyACM0. To connect, run `screen /dev/ttyACM0 9600`. To exit screen,
type the sequence `ctrl-A k`. Make sure to log out first or the user session
may still be connected.


## Re-running the headless installer

Create a file called `/boot/headless_deploy.txt`. The default behavior will
be to configure the Pi using the files detailed above. Usually this is only
needed to reconfigure the Pi's network and USB connectivity to a default
initial state so that you may log in and perform further changes.

After performing the updates, the device will blink a heartbeat pattern and
reboot.


**/boot/headless_deploy.txt**
Create this file (it can be empty) to initiate the headless configuration deployment
on the next boot. One the next boot, `/usr/bin/do_headless_updates.sh` will
reconfigure the Pi as described above, and `/boot/headless_deploy.txt` will be
removed so that the deployment doesn't happen on subsequent boots.

`/boot/deploy_complete.txt`
The deployment process will create this file. If the update process runs, this
file will contain a log of what happened during the deployment.



## Running commands from the SD card

You can automate a deployment task, or execute commands
on the Pi if you can't otherwise connect to it.

Create a shell script called `do_once.sh` and place it in the `boot/deploy/`
directory. Then `touch /boot/headless_deploy.txt` and your script will be
executed as root on the next boot.

When your script has completed, it will be renamed to `do_once.sh.done`, the
LED will blink in a heartbeat pattern, and the device will automatically
reboot.

Look in `/boot/deploy_complete.txt` after the reboot. It will contain any output
from your script.


## Resetting the user password

To reset the user password as part of the deployment, create the `/boot/deploy/userconf.txt` file as described below, and `touch /boot/headless_deploy.txt`.

**/boot/deploy/userconf.txt**
To reset your password, this file should contain a single line of text, consisting of "username:encyptedpassword", where "username" is your existing username, followed immediately by a colon, followed immediately by the new encrypted password.

Use the command `openssl passwd -6` to create a hashed password in the proper format. In a pinch, you can use `userconf.txt.example` (found in the examples subdirectory), which sets the password for "user" to "raspberry". Make sure to change your password immediately after regaining access.

**NOTE:** You can't change the username this way. Make sure to use the correct username that your Pi was initially configured with.

The userconf.txt file will be removed when this process has completed.


