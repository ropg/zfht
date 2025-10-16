# POSIX-compatible Makefile
PREFIX ?= /usr/local
MANDIR ?= $(PREFIX)/share/man
BINDIR ?= $(PREFIX)/bin

SCRIPTS = zfht zfht-update-serial zfht-sign
MANPAGES = man/man8/zfht.8 man/man8/zfht-update-serial.8 man/man8/zfht-sign.8

.PHONY: all docs test install uninstall clean

all: docs

docs:
	@mkdir -p docs
	@for m in $(MANPAGES); do \
		base=$$(basename $$m .8); \
		if mandoc -T markdown $$m > docs/$$base.md 2>/dev/null; then \
			echo "generated docs/$$base.md"; \
		else \
			echo "mandoc -T markdown not supported, using pandoc fallback"; \
			pandoc -s -f man -t gfm $$m -o docs/$$base.md; \
			echo "generated docs/$$base.md (via pandoc)"; \
		fi; \
	done

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

clean:
	rm -rf docs

