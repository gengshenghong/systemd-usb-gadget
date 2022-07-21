sbindir=/sbin
sysconfdir=/etc
unitdir=$(sysconfdir)/systemd/system

UNIT = usb-gadget.service

SCRIPTS = \
	configure-gadget.sh \
	remove-gadget.sh

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
	install -m 600 $(UNIT) $(DESTDIR)$(unitdir); \
	done
