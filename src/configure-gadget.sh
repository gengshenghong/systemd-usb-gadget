#!/bin/bash -e

SYSDIR=/sys/kernel/config/usb_gadget
DEVDIR=$SYSDIR/rockchip

# These are the default values that will be used if you have not provided
# an explicit value in the environment.
# except USB_BCDUSB, all can be configurated to anything
USB_IDVENDOR=0x1b6d					# Vendor ID, the Linux Foundation
USB_IDPRODUCT=0x0104				# Product ID, Multifunction Composite Gadget
USB_BCDDEVICE=0x0100				# Device version, 1.0.0
USB_BCDUSB=0x0200					# Maximum supported USB version, USB2.0
USB_SERIALNUMBER="0123456789ABCDEF"	# Device serial number.
USB_PRODUCT="Linux Gadget"			# Product name
USB_MANUFACTURER="Linux"			# Manufacturer name
USB_MAXPOWER=250					# Maximum power required, 250
USB_CONFIG="conf.1"					# config directory, must be format of <name>.<number> with any value
# functions to be enabled
# USB_FUNCTIONS="acm.usb0"
# USB_FUNCTIONS="mass_storage.0"
# USB_FUNCTIONS="rndis.usb0"
# USB_FUNCTIONS="ncm.usb0"
USB_FUNCTIONS="rndis.usb0 ncm.usb0"

############################# zic
# for ecm/ncm
mac_ecm_h="1e:ff:c9:42:c9:e2"
mac_ecm_d="1e:ff:c9:42:c9:e3"
# for rndis
mac_rndis_h="1e:ff:c9:42:c9:e0"
mac_rndis_d="1e:ff:c9:42:c9:e1"
############################# zic

if [ -e "${DEVDIR}" ]; then
	echo "already configured!"
	exit 0
fi

echo "Creating USB gadget"

mkdir -p $DEVDIR -m 0770

echo 0xEF > $DEVDIR/bDeviceClass
echo 0x02 > $DEVDIR/bDeviceSubClass
echo 0x01 > $DEVDIR/bDeviceProtocol

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
	if [ ! -e "${DEVDIR}/functions/${func}" ] ;
	then
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
				if [ ! -e "mkdir -p /sys/kernel/config/usb_gadget/rockchip/functions/mass_storage.0" ] ;
				then
					# echo "/home/firefly/public/mass_storage" > "${DEVDIR}/functions/${func}/lun.0/file"
					ln -sf "${DEVDIR}/functions/${func}" "${DEVDIR}/configs/${USB_CONFIG}/${func}"
				fi
			;;
			"ncm.usb0")
				if [ ! -e "mkdir -p /sys/kernel/config/usb_gadget/rockchip/functions/ncm.usb0" ] ;
				then
					echo "${mac_ecm_h}" > "${DEVDIR}/functions/${func}/host_addr"
					echo "${mac_ecm_d}" > "${DEVDIR}/functions/${func}/dev_addr"
					ln -sf $DEVDIR/functions/$func $DEVDIR/configs/$USB_CONFIG/$func
				fi
			;;
			*)
				ln -sf "${DEVDIR}/functions/${func}" "${DEVDIR}/configs/${USB_CONFIG}/${func}"
			;;
			esac
		fi
done

udevadm settle -t 5 || :
ls /sys/class/udc/ > $DEVDIR/UDC

# if [[ $USB_FUNCTIONS == *"rndis.usb0"* ]]; then
# 	# ipv4
# 	ifconfig "$(cat ${DEVDIR}/functions/rndis.usb0/ifname)" 192.168.55.1 broadcast 192.168.55.100 netmask 255.255.255.0 up
# 	# ipv6 : link local
# 	ifconfig "$(cat ${DEVDIR}/functions/rndis.usb0/ifname)" add fe80::1
# fi

# if [[ $USB_FUNCTIONS == *"ncm.usb0"* ]]; then
# 	# ipv4
# 	ifconfig "$(cat ${DEVDIR}/functions/ncm.usb0/ifname)" 192.168.66.1 broadcast 192.168.66.100 netmask 255.255.255.0 up
# 	# ipv6 : link local
# 	ifconfig "$(cat ${DEVDIR}/functions/ncm.usb0/ifname)" add fe80::1
# fi

if [[ $USB_FUNCTIONS == *"rndis.usb0"* || $USB_FUNCTIONS == *"ncm.usb0"* ]]; then
	# creat bridge net l44tbr0, requires 'bridge-utils' package
	brctl addbr usbgadget
	ifconfig usbgadget down
	if [[ $USB_FUNCTIONS == *"rndis.usb0"* ]]; then
		brctl addif usbgadget "$(cat ${DEVDIR}/functions/rndis.usb0/ifname)"
		ifconfig "$(cat ${DEVDIR}/functions/rndis.usb0/ifname)" up
	fi
	if [[ $USB_FUNCTIONS == *"ncm.usb0"* ]]; then
		brctl addif usbgadget "$(cat ${DEVDIR}/functions/ncm.usb0/ifname)"
		ifconfig "$(cat ${DEVDIR}/functions/ncm.usb0/ifname)" up
	fi
	# bring up
	ifconfig usbgadget 192.168.55.1 netmask 255.255.255.0 up
	ifconfig usbgadget add fe80::1
fi
