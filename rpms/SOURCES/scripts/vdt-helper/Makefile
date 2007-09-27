DESTDIR=/usr/local

all:
	chmod +x vdt-helper

install: all
	mkdir -p $(DESTDIR)/share/doc/vdt-helper
	cp vdt-config.example $(DESTDIR)/share/doc/vdt-helper
	mkdir -p $(DESTDIR)/sbin
	cp vdt-helper $(DESTDIR)/sbin/vdt-install-helper

