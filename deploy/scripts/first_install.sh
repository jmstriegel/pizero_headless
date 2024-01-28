#!/bin/bash


if [ ${EUID} -ne 0 ]
then
        printf "This should only be run as root\n"
        exit 1
fi

# Install headless updater
cp /boot/deploy/scripts/do_headless_updates.sh /usr/bin/do_headless_updates.sh
chmod 755 /usr/bin/do_headless_updates.sh

# Run headless updater on the next boot
grep -qxF '/usr/bin/do_headless_updates.sh' /etc/rc.local || sed -i -e '/^exit 0/i \# Perform headless updates if needed\n/usr/bin/do_headless_updates.sh\n' /etc/rc.local

# Remove startup run hack from cmdline.txt
sed -i 's| systemd.run.*||g' /boot/cmdline.txt
#sed -i 's| init=.*||' /boot/cmdline.txt

# Trigger the full update on the next boot
touch /boot/headless_deploy.txt

exit 0
