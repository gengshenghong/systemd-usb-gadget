#!/bin/bash -e

SYSDIR=/sys/kernel/config/usb_gadget
DEVDIR=$SYSDIR/rockchip

# These are the default values that will be used if you have not provided
# an explicit value in the environment.
USB_IDVENDOR=0x2207
USB_IDPRODUCT=0x0006
USB_BCDDEVICE=0x0419
USB_BCDUSB=0x0200
USB_SERIALNUMBER="0123456789ABCDEF"
USB_PRODUCT="STP90SHC"
USB_MANUFACTURER="vtouch"
USB_MAXPOWER=500
USB_CONFIG="b.1"
USB_FUNCTIONS="rndis.usb0 ffs.adb hid.usb0 mass_storage.0"

############################# zic
# for ecm
mac_ecm_h="1e:ff:c9:42:c9:e2"
mac_ecm_d="1e:ff:c9:42:c9:e3"

mac_rndis_h="1e:ff:c9:42:c9:e0"
mac_rndis_d="1e:ff:c9:42:c9:e1"
############################# zic

echo "Creating USB gadget"

mkdir -p $DEVDIR -m 0770
 
echo $USB_IDVENDOR > $DEVDIR/idVendor
echo $USB_IDPRODUCT > $DEVDIR/idProduct
echo $USB_BCDDEVICE > $DEVDIR/bcdDevice
echo $USB_BCDUSB > $DEVDIR/bcdUSB
 
mkdir -p $DEVDIR/strings/0x409 -m 0770
echo "$USB_SERIALNUMBER" > $DEVDIR/strings/0x409/serialnumber
echo "$USB_MANUFACTURER"        > $DEVDIR/strings/0x409/manufacturer
echo "$USB_PRODUCT"   > $DEVDIR/strings/0x409/product
 
mkdir -p $DEVDIR/configs/$USB_CONFIG -m 0770
echo $USB_MAXPOWER > $DEVDIR/configs/$USB_CONFIG/MaxPower

for func in $USB_FUNCTIONS; do
	echo "Adding function $func to USB gadget $1"
	mkdir -p $DEVDIR/functions/$func 

	case $func in
		"rndis.usb0")
			if [ ! -e "mkdir -p /sys/kernel/config/usb_gadget/rockchip/functions/rndis.usb0" ] ;
			then
				echo "${mac_rndis_h}" > "${DEVDIR}/functions/${func}/host_addr"
				echo "${mac_rndis_d}" > "${DEVDIR}/functions/${func}/dev_addr"
				# echo 1 > "${DEVDIR}/functions/${func}/protocol"
				ln -sf $DEVDIR/functions/$func $DEVDIR/configs/$USB_CONFIG

				# Informs Windows that this device is compatible with the built-in RNDIS
				# driver. This allows automatic driver installation without any need for
				# a .inf file or manual driver selection.
				echo 1 > "${DEVDIR}/os_desc/use"
				echo 0xcd > "${DEVDIR}/os_desc/b_vendor_code"
				echo MSFT100 > "${DEVDIR}/os_desc/qw_sign"
				echo RNDIS > "${DEVDIR}/functions/${func}/os_desc/interface.rndis/compatible_id"
				echo 5162001 > "${DEVDIR}/functions/${func}/os_desc/interface.rndis/sub_compatible_id"
				ln -sf $DEVDIR/configs/$USB_CONFIG $DEVDIR/os_desc
			fi
		;;
		"mass_storage.0")
			if [ ! -e "/sys/kernel/config/usb_gadget/rockchip/functions/mass_storage.0" ] ;
			then
				echo /home/firefly/public/mass_storage > $DEVDIR/functions/$func/lun.0/file
				ln -sf $DEVDIR/functions/$func $DEVDIR/configs/$USB_CONFIG/$func
			fi
		;;
		"ecm.usb0")
			if [ ! -e "mkdir -p /sys/kernel/config/usb_gadget/rockchip/functions/ecm.usb0" ] ;
			then
				echo "${mac_ecm_h}" > "${DEVDIR}/functions/${func}/host_addr"
				echo "${mac_ecm_d}" > "${DEVDIP}/functions/${func}/dev_addr"
				ln -sf $DEVDIR/functions/$func $DEVDIR/configs/$USB_CONFIG/$func
			fi
		;;
		"hid.usb0")
			if [ ! -e "mkdir -p /sys/kernel/config/usb_gadget/rockchip/functions/hid.usb0" ] ;
			then
				echo 1 > "${DEVDIR}/functions/${func}/protocol"
				echo 1 > "${DEVDIR}/functions/${func}/subclass"
				echo 8 > "${DEVDIR}/functions/${func}/report_length"

				hidMode=$(awk -F ', ' '$2 ~ /hidMode/ {gsub(/"/, "", $3);  print $3}' /home/firefly/public/vpscpp/param.json)
				case $hidMode in
					0)
						;;
					1)
						# vps hidMode=1
						# touch #0
						# win7, win10, linux
						echo -ne \\x05\\x01\\x09\\x01\\xa1\\x01\\x05\\x01\\x09\\x01\\xa1\\x00\\x05\\x09\\x19\\x01\\x29\\x01\\x15\\x00\\x25\\x01\\x35\\x00\\x45\\x01\\x66\\x00\\x00\\x75\\x01\\x95\\x01\\x81\\x62\\x75\\x01\\x95\\x07\\x81\\x01\\x05\\x01\\x09\\x30\\x09\\x31\\x16\\x00\\x00\\x26\\x10\\x27\\x36\\x00\\x00\\x46\\x10\\x27\\x66\\x00\\x00\\x75\\x10\\x95\\x02\\x81\\x62\\xc0\\xc0 > "${DEVDIR}/functions/${func}/report_desc"
						;;
					2)
						# vps hidMode=2
						# touch #1
						# android
						# no cursor / press / drag / up
						echo -ne \\x05\\x0d\\x09\\x02\\xa1\\x01\\x09\\x20\\xA1\\x00\\x09\\x42\\x09\\x32\\x15\\x00\\x25\\x01\\x75\\x01\\x95\\x02\\x81\\x02\\x75\\x01\\x95\\x06\\x81\\x01\\x05\\x01\\x09\\x01\\xA1\\x00\\x09\\x30\\x09\\x31\\x16\\x00\\x00\\x26\\x10\\x27\\x36\\x00\\x00\\x46\\x10\\x27\\x66\\x00\\x00\\x75\\x10\\x95\\x02\\x81\\x02\\xc0\\xc0\\xc0 > "${DEVDIR}/functions/${func}/report_desc"
						;;
					3)
						# touch #2
						echo -ne \\x05\\x0D\\x09\\x04\\xA1\\x01\\x09\\x55\\x25\\x01\\xB1\\x02\\x09\\x54\\x95\\x01\\x75\\x08\\x81\\x02\\x09\\x22\\xA1\\x02\\x09\\x51\\x75\\x08\\x95\\x01\\x81\\x02\\x09\\x42\\x09\\x32\\x15\\x00\\x25\\x01\\x75\\x01\\x95\\x02\\x81\\x02\\x95\\x06\\x81\\x03\\x05\\x01\\x09\\x30\\x09\\x31\\x16\\x00\\x00\\x26\\x10\\x27\\x36\\x00\\x00\\x46\\x10\\x27\\x66\\x00\\x00\\x75\\x10\\x95\\x02\\x81\\x02\\xC0\\xC0 > "${DEVDIR}/functions/${func}/report_desc"
						;;
					5)
						# mouse rel
						echo -ne \\x05\\x01\\x09\\x02\\xa1\\x01\\x09\\x01\\xa1\\x00\\x05\\x09\\x19\\x01\\x29\\x03\\x15\\x00\\x25\\x01\\x95\\x03\\x75\\x01\\x81\\x02\\x95\\x01\\x75\\x05\\x81\\x03\\x05\\x01\\x09\\x30\\x09\\x31\\x15\\x81\\x25\\x7f\\x75\\x08\\x95\\x02\\x81\\x06\\xc0\\xc0 > "${DEVDIR}/functions/${func}/report_desc"
						;;

				esac
				ln -sf $DEVDIR/functions/$func $DEVDIR/configs/$USB_CONFIG/$func
			fi
		;;
		ffs.adb)
			if [ ! -e "/sys/kernel/config/usb_gadget/rockchip/functions/ffs.adb" ] ;
			then
				ln -sf $DEVDIR/functions/$func $DEVDIR/configs/$USB_CONFIG/$func
			fi
			if [ ! -e "/dev/usb-ffs/adb" ] ;
			then
				mkdir -p /dev/usb-ffs/adb
				mount -o uid=2000,gid=2000 -t functionfs adb /dev/usb-ffs/adb
			fi
			export service_adb_tcp_port=5555
			start-stop-daemon --start --oknodo --pidfile /var/run/adbd.pid --startas /usr/local/bin/adbd --background
		;;
		*)
			ln -sf $DEVDIR/functions/$func $DEVDIR/configs/$USB_CONFIG/$func
		;;
		esac
done


udevadm settle -t 5 || :
ls /sys/class/udc/ > $DEVDIR/UDC

# ipv4
ifconfig usb0 192.168.55.1 broadcast 192.168.55.100 netmask 255.255.255.0 up

# ipv6 : link local
ifconfig usb0 add fe80::1

sleep 10
if [[ $USB_FUNCTIONS == *"hid.usb0"* ]]; then
	chmod 666 /dev/hidg0
fi

cpufreq-set -r -g performance