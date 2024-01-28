#/usr/bin/bash

# Installs dnsmasq and configures it for DHCP services on the
# usb0 device. This will allow your computer to get an address
# automatically when connected to usb. 

apt-get -y install dnsmasq

# Copy over a custom dnsmasq configuration
cp /boot/deploy/files/etc/dnsmasq.conf /etc/dnsmasq.conf
chmod 644 /etc/dnsmasq.conf

cp /boot/deploy/files/etc/default/dnsmasq /etc/default/dnsmasq
chmod 644 /etc/default/dnsmasq


# Prevent dhcp client from running on usb0
cp /boot/deploy/files/etc/dhcpcd.conf /etc/dhcpcd.conf
chown root:netdev /etc/dhcpcd.conf
chmod 664 /etc/dhcpcd.conf


# Start the service
systemctl enable dnsmasq
systemctl start dnsmasq
