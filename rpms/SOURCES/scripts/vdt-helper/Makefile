PREFIX=/usr/local

dist:
	tar czf ../../vdt-helper.tar.gz ../vdt-helper/*
install:
	chmod +x vdt-helper
	mkdir -p $(DESTDIR)/$(PREFIX)/share/doc/vdt-helper
	cp vdt-config.example $(DESTDIR)/$(PREFIX)/share/doc/vdt-helper
	mkdir -p $(DESTDIR)/$(PREFIX)/sbin
	cp vdt-helper $(DESTDIR)/$(PREFIX)/sbin/vdt-install-helper

	
