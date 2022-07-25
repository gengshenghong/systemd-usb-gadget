sbindir=/sbin
sysconfdir=/etc
unitdir=$(sysconfdir)/systemd/system

UNITS = \
	checkOTG.service \
	usb-gadget.service  

SCRIPTS = \
	configure-gadget.sh \
	remove-gadget.sh \
	check-gadget.sh

all:

install: install-scripts install-units
	mkdir -p $(DESTDIR)$(sysconfdir)/gadget

install-scripts: $(SCRIPTS)
	mkdir -p $(DESTDIR)$(sbindir)
	for s in $(SCRIPTS); do \
		install -m 755 $$s $(DESTDIR)$(sbindir)/$${s%.sh}; \
	done

install-units: $(UNIT)
	mkdir -p $(DESTDIR)$(unitdir)
	for u in $(UNITS); do \
		install -m 600 $$u $(DESTDIR)$(unitdir); \
	done