PREFIX=/usr/local

dist:
	tar czf ../../gridpulse.tar.gz ../gridpulse/*
install:
	chmod +x gridpulse
	mkdir -p $(DESTDIR)/$(PREFIX)/lib/gridpulse
	cp system_shorts.pulse $(DESTDIR)/$(PREFIX)/lib/gridpulse/
	mkdir -p $(DESTDIR)/$(PREFIX)/bin
	cp gridpulse $(DESTDIR)/$(PREFIX)/bin/
	mkdir -p $(DESTDIR)/$(PREFIX)/share/doc/gridpulse
	cp README $(DESTDIR)/$(PREFIX)/share/doc/gridpulse/

	
