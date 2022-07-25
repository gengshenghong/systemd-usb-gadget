for (( ; ; ))
do
	ret=`cat /sys/class/udc/fcc00000.dwc3/state`
	if [[ $ret != "configured" ]]; then
        /sbin/configure-gadget
	fi
	sleep 1
done