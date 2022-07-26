#!/bin/bash
### BEGIN INIT INFO
# Provides:          adbd
# Required-Start:
# Required-Stop:
# Default-Start: S
# Default-Stop: 6
# Short-Description:
# Description:       Linux ADB
### END INIT INFO


############################# zic
# for ecm
mac_ecm_h=1e:ff:c9:42:c9:e2
mac_ecm_d=1e:ff:c9:42:c9:e3

mac_rndis_h=1e:ff:c9:42:c9:e0
mac_rndis_d=1e:ff:c9:42:c9:e1
############################# zic


# setup configfs for adbd, usb mass storage and MTP....

UMS_EN=on
ADB_EN=off
MTP_EN=off
ECM_EN=off
HID_EN=on
RNDIS_EN=on


make_config_string()
{
	tmp=$CONFIG_STRING
	if [ -n "$CONFIG_STRING" ]; then
		CONFIG_STRING=${tmp}_${1}
	else
		CONFIG_STRING=$1
	fi
}

parameter_init()
{
	while read line
	do
		case "$line" in
			usb_mtp_en)
				MTP_EN=on
				make_config_string mtp
				;;
			usb_adb_en)
				ADB_EN=on
				make_config_string adb
				;;
			usb_ums_en)
				UMS_EN=on
				make_config_string ums
				;;
			usb_ecm_en)
				ECM_EN=on
				make_config_string ecm
				;;
			usb_hid_en)
				HID_EN=on
				make_config_string hid
				;;
			usb_rndis_en)
				RNDIS_EN=on
				make_config_string rndis
				;;
		esac
	done < $DIR/.usb_config


	case "$CONFIG_STRING" in
		ums)
			PID=0x0000
			;;
		mtp)
			PID=0x0001
			;;
		adb)
			PID=0x0006
			;;
		mtp_adb | adb_mtp)
			PID=0x0011
			;;
		ums_adb | adb_ums)
			PID=0x0018
			;;
		*)
			PID=0x0019
	esac
}

configfs_init()
{
	mkdir -p /sys/kernel/config/usb_gadget/rockchip -m 0770
	echo 0x2207 > /sys/kernel/config/usb_gadget/rockchip/idVendor
	echo $PID > /sys/kernel/config/usb_gadget/rockchip/idProduct
	mkdir -p /sys/kernel/config/usb_gadget/rockchip/strings/0x409 -m 0770
	echo "0123456789ABCDEF" > /sys/kernel/config/usb_gadget/rockchip/strings/0x409/serialnumber
	echo "vtouch"  > /sys/kernel/config/usb_gadget/rockchip/strings/0x409/manufacturer
	echo "STP90SHC"  > /sys/kernel/config/usb_gadget/rockchip/strings/0x409/product
	mkdir -p /sys/kernel/config/usb_gadget/rockchip/configs/b.1 -m 0770
	mkdir -p /sys/kernel/config/usb_gadget/rockchip/configs/b.1/strings/0x409 -m 0770
	echo 500 > /sys/kernel/config/usb_gadget/rockchip/configs/b.1/MaxPower
	echo \"$CONFIG_STRING\" > /sys/kernel/config/usb_gadget/rockchip/configs/b.1/strings/0x409/configuration
}

function_init()
{
	# change to root of usb gadget device
	cd /sys/kernel/config/usb_gadget/rockchip
	
	cfg=/sys/kernel/config/usb_gadget/rockchip/configs/b.1

	if [ $RNDIS_EN = on ];then
		if [ ! -e "mkdir -p /sys/kernel/config/usb_gadget/rockchip/functions/rndis.usb0" ] ;
		then
			# Note: RNDIS must be the first function in the configuration, or Windows'
			# RNDIS support will not operate correctly.
			func=/sys/kernel/config/usb_gadget/rockchip/functions/rndis.usb0

			mkdir -p "${func}"
			echo "${mac_rndis_h}" > "${func}/host_addr"
			echo "${mac_rndis_d}" > "${func}/dev_addr"
			# echo 1 > "${func}/protocol"
			ln -sf "${func}" "${cfg}"

			# Informs Windows that this device is compatible with the built-in RNDIS
			# driver. This allows automatic driver installation without any need for
			# a .inf file or manual driver selection.
			echo 1 > os_desc/use
			echo 0xcd > os_desc/b_vendor_code
			echo MSFT100 > os_desc/qw_sign
			echo RNDIS > "${func}/os_desc/interface.rndis/compatible_id"
			echo 5162001 > "${func}/os_desc/interface.rndis/sub_compatible_id"
			ln -sf "${cfg}" os_desc
		fi
	fi

	if [ $UMS_EN = on ];then
		if [ ! -e "/sys/kernel/config/usb_gadget/rockchip/functions/mass_storage.0" ] ;
		then
			mkdir -p /sys/kernel/config/usb_gadget/rockchip/functions/mass_storage.0
			# echo /dev/disk/by-partlabel/userdata > /sys/kernel/config/usb_gadget/rockchip/functions/mass_storage.0/lun.0/file
			echo /home/firefly/public/mass_storage > /sys/kernel/config/usb_gadget/rockchip/functions/mass_storage.0/lun.0/file
			ln -s /sys/kernel/config/usb_gadget/rockchip/functions/mass_storage.0 /sys/kernel/config/usb_gadget/rockchip/configs/b.1/mass_storage.0
		fi
	fi

	if [ $ADB_EN = on ];then
		if [ ! -e "/sys/kernel/config/usb_gadget/rockchip/functions/ffs.adb" ] ;
		then
			mkdir -p /sys/kernel/config/usb_gadget/rockchip/functions/ffs.adb
			ln -s /sys/kernel/config/usb_gadget/rockchip/functions/ffs.adb /sys/kernel/config/usb_gadget/rockchip/configs/b.1/ffs.adb
		fi
	fi

	if [ $MTP_EN = on ];then
		if [ ! -e "mkdir -p /sys/kernel/config/usb_gadget/rockchip/functions/mtp.gs0" ] ;
		then
			mkdir -p /sys/kernel/config/usb_gadget/rockchip/functions/mtp.gs0
			ln -s /sys/kernel/config/usb_gadget/rockchip/functions/mtp.gs0 /sys/kernel/config/usb_gadget/rockchip/configs/b.1/mtp.gs0
		fi
	fi

	if [ $ECM_EN = on ];then
		if [ ! -e "mkdir -p /sys/kernel/config/usb_gadget/rockchip/functions/ecm.usb0" ] ;
		then
			mkdir -p /sys/kernel/config/usb_gadget/rockchip/functions/ecm.usb0
			echo "${mac_ecm_h}" > "/sys/kernel/config/usb_gadget/rockchip/functions/ecm.usb0/host_addr"
			echo "${mac_ecm_d}" > "/sys/kernel/config/usb_gadget/rockchip/functions/ecm.usb0/dev_addr"
			ln -s /sys/kernel/config/usb_gadget/rockchip/functions/ecm.usb0 /sys/kernel/config/usb_gadget/rockchip/configs/b.1/ecm.usb0
		fi
	fi

	if [ $HID_EN = on ];then
		if [ ! -e "mkdir -p /sys/kernel/config/usb_gadget/rockchip/functions/hid.usb0" ] ;
		then
			echo "add HID device"
			func=/sys/kernel/config/usb_gadget/rockchip/functions/hid.usb0
			mkdir -p "${func}"

			echo 1 > "${func}/protocol"
			echo 1 > "${func}/subclass"
			echo 8 > "${func}/report_length"

			hidMode=$(awk -F ', ' '$2 ~ /hidMode/ {gsub(/"/, "", $3);  print $3}' /home/firefly/public/vpscpp/param.json)
			echo $hidMode

			case $hidMode in
				0)
					;;
				1)
					# vps hidMode=1
					# touch #0
					# win7, win10, linux
					echo -ne \\x05\\x01\\x09\\x01\\xa1\\x01\\x05\\x01\\x09\\x01\\xa1\\x00\\x05\\x09\\x19\\x01\\x29\\x01\\x15\\x00\\x25\\x01\\x35\\x00\\x45\\x01\\x66\\x00\\x00\\x75\\x01\\x95\\x01\\x81\\x62\\x75\\x01\\x95\\x07\\x81\\x01\\x05\\x01\\x09\\x30\\x09\\x31\\x16\\x00\\x00\\x26\\x10\\x27\\x36\\x00\\x00\\x46\\x10\\x27\\x66\\x00\\x00\\x75\\x10\\x95\\x02\\x81\\x62\\xc0\\xc0 > "${func}/report_desc"
					;;
				2)
					# vps hidMode=2
					# touch #1
					# android
					# no cursor / press / drag / up
					echo -ne \\x05\\x0d\\x09\\x02\\xa1\\x01\\x09\\x20\\xA1\\x00\\x09\\x42\\x09\\x32\\x15\\x00\\x25\\x01\\x75\\x01\\x95\\x02\\x81\\x02\\x75\\x01\\x95\\x06\\x81\\x01\\x05\\x01\\x09\\x01\\xA1\\x00\\x09\\x30\\x09\\x31\\x16\\x00\\x00\\x26\\x10\\x27\\x36\\x00\\x00\\x46\\x10\\x27\\x66\\x00\\x00\\x75\\x10\\x95\\x02\\x81\\x02\\xc0\\xc0\\xc0 > "${func}/report_desc"
					;;
				3)
					# touch #2
					echo -ne \\x05\\x0D\\x09\\x04\\xA1\\x01\\x09\\x55\\x25\\x01\\xB1\\x02\\x09\\x54\\x95\\x01\\x75\\x08\\x81\\x02\\x09\\x22\\xA1\\x02\\x09\\x51\\x75\\x08\\x95\\x01\\x81\\x02\\x09\\x42\\x09\\x32\\x15\\x00\\x25\\x01\\x75\\x01\\x95\\x02\\x81\\x02\\x95\\x06\\x81\\x03\\x05\\x01\\x09\\x30\\x09\\x31\\x16\\x00\\x00\\x26\\x10\\x27\\x36\\x00\\x00\\x46\\x10\\x27\\x66\\x00\\x00\\x75\\x10\\x95\\x02\\x81\\x02\\xC0\\xC0 > "${func}/report_desc"
					;;
				5)
					# mouse rel
					echo -ne \\x05\\x01\\x09\\x02\\xa1\\x01\\x09\\x01\\xa1\\x00\\x05\\x09\\x19\\x01\\x29\\x03\\x15\\x00\\x25\\x01\\x95\\x03\\x75\\x01\\x81\\x02\\x95\\x01\\x75\\x05\\x81\\x03\\x05\\x01\\x09\\x30\\x09\\x31\\x15\\x81\\x25\\x7f\\x75\\x08\\x95\\x02\\x81\\x06\\xc0\\xc0 > "${func}/report_desc"
					;;

			esac


			# touch #0
			# echo -ne \\x05\\x01\\x09\\x01\\xa1\\x01\\x05\\x01\\x09\\x01\\xa1\\x00\\x05\\x09\\x19\\x01\\x29\\x01\\x15\\x00\\x25\\x01\\x35\\x00\\x45\\x01\\x66\\x00\\x00\\x75\\x01\\x95\\x01\\x81\\x62\\x75\\x01\\x95\\x07\\x81\\x01\\x05\\x01\\x09\\x30\\x09\\x31\\x16\\x00\\x00\\x26\\x10\\x27\\x36\\x00\\x00\\x46\\x10\\x27\\x66\\x00\\x00\\x75\\x10\\x95\\x02\\x81\\x62\\xc0\\xc0 > "${func}/report_desc"


			ln -sf "${func}" "${cfg}"
		fi
	fi



}

case "$1" in
	start|recon)
		UDC=`ls /sys/class/udc/| awk '{print $1}'`
		if [ -z "$UDC" ]; then
			exit 0
		fi

		DIR=$(cd `dirname $0`; pwd)
		if [ ! -e "$DIR/.usb_config" ]; then
			echo "$0: Cannot find .usb_config"
			exit 0
		fi

		parameter_init
		if [ -z $CONFIG_STRING ]; then
			echo "$0: no function be selected"
			exit 0
		fi

		if [ $1 = start ];then
			configfs_init
			function_init
		fi

		if [ $ADB_EN = on ];then
			if [ ! -e "/dev/usb-ffs/adb" ] ;
			then
				mkdir -p /dev/usb-ffs/adb
				mount -o uid=2000,gid=2000 -t functionfs adb /dev/usb-ffs/adb
			fi
			export service_adb_tcp_port=5555
			start-stop-daemon --start --oknodo --pidfile /var/run/adbd.pid --startas /usr/local/bin/adbd --background
			sleep 1
		fi

		if [ $MTP_EN = on ];then
			if [ $MTP_EN = on ]; then
				mtp-server&
			else
				sleep 1 && mtp-server&
			fi
		fi
		
		udevadm settle -t 5 || :

		echo $UDC > /sys/kernel/config/usb_gadget/rockchip/UDC

		# ipv4
		ifconfig usb0 192.168.55.1 broadcast 192.168.55.100 netmask 255.255.255.0 up

		# ipv6 : link local
		ifconfig usb0 add fe80::1
		sleep 5
		chmod 666 /dev/hidg0

		cpufreq-set -r -g performance

		# disable ipv6
		# sysctl -w net.ipv6.conf.all.disable_ipv6=1
		# sysctl -w net.ipv6.conf.default.disable_ipv6=1

		;;
	stop)
		UDC=`ls /sys/class/udc/| awk '{print $1}'`
		if [ -z "$UDC" ]; then
			exit 0
		fi
		echo "none" > /sys/kernel/config/usb_gadget/rockchip/UDC
		if [ $ADB_EN = on ];then
			start-stop-daemon --stop --oknodo --pidfile /var/run/adbd.pid --retry 5
		fi
		;;
	restart|reload)
		;;

	retry) 
		echo $UDC > /sys/kernel/config/usb_gadget/rockchip/UDC



		;;
	*)
		echo "Usage: $0 {start|stop|restart}"
		exit 1
esac

exit 0
