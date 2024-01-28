#!/usr/bin/env bash

if [ ${EUID} -ne 0 ]
then
	printf "This should only be run as root\n"
	exit 1
fi

UPDATE_REQUIRED="/boot/headless_deploy.txt"
UPDATE_COMPLETE="/boot/deploy_complete.txt"

USERCONF="/boot/deploy/userconf.txt"

UPDATE_USB="/boot/deploy/update_usb"
UPDATE_DEPLOY="/boot/deploy/update_deploy"
DO_ONCE_SCRIPT="/boot/deploy/do_once.sh"
DO_ONCE_SCRIPT_COMPLETE="/boot/deploy/do_once.sh.done"
WPA_CONFIG="/boot/deploy/wpa_supplicant.conf"
WPA_DEST="/etc/wpa_supplicant/wpa_supplicant.conf"

if [ -f $UPDATE_REQUIRED ]; then
	echo "-----PERFORMING HEADLESS DEPLOYMENT-----" | tee $UPDATE_COMPLETE


	# If /boot/deploy/userconf.txt exists, use it to change passwords.
	# File format is a single line: [user]:[encrypted_pass] where encrypted_pass
	# is created using the `openssl passwd -6` utility.
	#
	# The userconf.txt file will be deleted afterward.
	if [ -f $USERCONF ]; then
		echo "-----FOUND USERCONF, UPDATING PASSWORD-----" | tee -a $UPDATE_COMPLETE
		cat $USERCONF | chpasswd -e 2>&1 | tee -a $UPDATE_COMPLETE
		rm -f $USERCONF
	fi


	# Make sure we can access the device over USB serial and ethernet
	if [ -f $UPDATE_USB ]; then
		echo "-----SETTING UP HEADLESS USB ACCESS-----" | tee -a $UPDATE_COMPLETE
		/boot/deploy/scripts/enable_usb_gadgets.sh 2>&1 | tee -a $UPDATE_COMPLETE
	fi
	
	# Update wpasupplicant.conf, if provided
	if [ -f $WPA_CONFIG ]; then
		echo "-----UPDATING WPA SUPPLICANT-----" | tee -a $UPDATE_COMPLETE
		mv $WPA_CONFIG $WPA_DEST 2>&1 | tee -a $UPDATE_COMPLETE
		chmod 600 $WPA_DEST 2>&1 | tee -a $UPDATE_COMPLETE
		systemctl restart wpa_supplicant.service 2>&1 | tee -a $UPDATE_COMPLETE
	fi	


	if [ -f $UPDATE_DEPLOY ]; then
		echo "-----INSTALLING THE DEPLOYMENT SCRIPT-----" | tee -a $UPDATE_COMPLETE
		cp /boot/deploy/scripts/do_headless_updates.sh /usr/bin/do_headless_updates.sh 2>&1 | tee -a $UPDATE_COMPLETE
		chmod 750 /usr/bin/do_headless_updates.sh 2>&1 | tee -a $UPDATE_COMPLETE
		grep -qxF '/usr/bin/do_headless_updates.sh' /etc/rc.local || sed -i -e '/^exit 0/i \# Perform headless updates if needed\n/usr/bin/do_headless_updates.sh\n' /etc/rc.local 2>&1 | tee -a $UPDATE_COMPLETE
	fi

	if [ -f $DO_ONCE_SCRIPT ]; then
		echo "-----RUNNING DO ONCE SCRIPT-----" | tee -a $UPDATE_COMPLETE
		$DO_ONCE_SCRIPT 2>&1 | tee -a $UPDATE_COMPLETE
		mv $DO_ONCE_SCRIPT $DO_ONCE_SCRIPT_COMPLETE
	fi



	# Delete the update trigger file to prevent endless updates
	rm -f $UPDATE_REQUIRED

	# start led blinking and reboot
	echo "-----REBOOTING-----" | tee -a $UPDATE_COMPLETE
	echo heartbeat > /sys/class/leds/ACT/trigger
	/usr/sbin/reboot
fi
