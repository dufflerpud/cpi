ifneq (,$(wildcard /boot/home/config/non-packaged))
    USRLOCAL?=/boot/home/config/non-packaged
else
    USRLOCAL?=/usr/local
endif

SYSTEMBIN?=$(USRLOCAL)/bin
GIT?=git

ifeq (,$(SUDO))
    ifneq (0,$(shell id -u))
        SUDO=sudo
    endif
endif

ifeq (,$(MAKE))
    ifneq (,$(shell command -v gmake))
        MAKE=gmake
    else
        MAKE=make
    endif
endif

ifeq (,$(GNUINSTALL))
    ifneq (,$(wildcard /usr/gnu/bin/install))
	GNUINSTALL=/usr/gnu/bin/install
    else
	GNUINSTALL=install
    endif
endif

install:
	-cd src; $(SUDO) $(MAKE) install_required_modules
	-cd src; $(SUDO) $(MAKE) install
	$(GNUINSTALL) -d $(SYSTEMBIN)
	$(GNUINSTALL) -m 0755 tests/cpi_user.pl $(SYSTEMBIN)/cpi_user
	$(GNUINSTALL) -m 0755 tests/cpi_db.pl $(SYSTEMBIN)/cpi_db

fresh:
	@$(GIT) pull
	@$(MAKE) install
