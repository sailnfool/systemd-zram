SHELL=/bin/bash
.sh:
	@rm -f $@
	cp $< $@
INSTALL = add_zram_firmware
LINSTALL = add_zram_firmware

EXECDIR := $(HOME)/bin
LEXECDIR := $(HOME)/github/systemd-zram/bin

.PHONY: clean uninstall all
all: $(INSTALL)
install: $(INSTALL)
	mkdir -p $(EXECDIR)
	install -g $(USER) -o $(USER) -C $? $(EXECDIR)
	rm -f $?
linstall: $(LINSTALL) 
	mkdir -p $(SEXECDIR)
	install -g root -o root  -C $? $(SEXECDIR)
clean: 
	@for execfile in $(INSTALL) ; do \
		echo rm -f $$execfile; \
		rm -f $$execfile; \
	done
uninstall: 
	@for execfile in $(INSTALL); do \
		echo "rm -f $(EXECDIR)/$$execfile" ; \
		rm -f $(EXECDIR)/$$execfile; \
	done
	@for execfile in $(LINSTALL); do \
		echo "rm -f $(LEXECDIR)/$$execfile" ; \
		rm -f $(LEXECDIR)/$$execfile; \
	done
$(EXECDIR):
	mkdir -p $(EXECDIR)
$(LEXECDIR):
	mkdir -p $(LEXECDIR)
