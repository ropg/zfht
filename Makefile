# POSIX-compatible Makefile
PREFIX ?= /usr/local
MANDIR ?= $(PREFIX)/share/man
BINDIR ?= $(PREFIX)/sbin

SCRIPTS = zfht zfht-update-serial zfht-sign
MANPAGES = man/man8/zfht.8 man/man8/zfht-update-serial.8 man/man8/zfht-sign.8

.PHONY: test test-baseline install uninstall

test:
	@sh tests/run.sh

test-baseline:
	@sh tests/run.sh write

install:
	@for s in $(SCRIPTS); do \
		install -d $(DESTDIR)$(BINDIR); \
		install -m 0755 $$s $(DESTDIR)$(BINDIR)/$$s; \
		echo "installed $(DESTDIR)$(BINDIR)/$$s"; \
	done
	@install -d $(DESTDIR)$(MANDIR)/man8
	@for m in $(MANPAGES); do \
		install -m 0644 $$m $(DESTDIR)$(MANDIR)/man8/; \
		echo "installed $(DESTDIR)$(MANDIR)/man8/$$(basename $$m)"; \
	done

uninstall:
	@for s in $(SCRIPTS); do \
		rm -f $(DESTDIR)$(BINDIR)/$$s; \
	done
	@for m in $(MANPAGES); do \
		rm -f $(DESTDIR)$(MANDIR)/man8/$$(basename $$m); \
	done
