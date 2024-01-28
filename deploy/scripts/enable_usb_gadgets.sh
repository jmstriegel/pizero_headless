#!/usr/bin/bash
# Configures Pi Zero USB gadget for headless shell access

# usb_gadget_composite runs during boot to define and start the gadget kernel module
cp /boot/deploy/files/usr/bin/usb_gadget_composite /usr/bin/usb_gadget_composite
chmod 755 /usr/bin/usb_gadget_composite

# update rc.local to run the above usb_gadget_composite script
grep -qxF '/usr/bin/usb_gadget_composite' /etc/rc.local || sed -i -e '/^exit 0/i \# Start the USB gadget\n/usr/bin/usb_gadget_composite\n' /etc/rc.local

# usb0 ethernet device should be configured for a static address
cp /boot/deploy/files/etc/network/interfaces.d/usb0 /etc/network/interfaces.d/usb0
chmod 644 /etc/network/interfaces.d/usb0

# set up agetty to provide shell access on the usb gadget tty
SRCDIR="/boot/deploy/files"
DIR="etc/systemd/system/serial-getty@ttyGS0.service.d"
FNAME="override.conf"
if [ ! -d /$DIR ]; then
	mkdir /$DIR
fi
cp $SRCDIR/$DIR/$FNAME /$DIR/$FNAME
chmod 644 /$DIR/$FNAME
systemctl reenable serial-getty@ttyGS0.service


