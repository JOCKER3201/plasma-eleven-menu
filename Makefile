# plasma-eleven-menu — installation and packaging
#
#   make install        install/update for the current user
#   sudo make install   global (system-wide) install/update
#   make uninstall      removal (sudo make uninstall — for the global version)
#   make package        plasma-eleven-menu-<version>.tar.xz archive

PKGTOOL ?= kpackagetool6
TYPE    := Plasma/Applet
NAME    := plasma-eleven-menu
ID      := com.github.jocker3201.elevenmenu
VERSION := $(shell sed -n 's/.*"Version": *"\([^"]*\)".*/\1/p' package/metadata.json)

# When run as root (sudo make install), install globally.
ifeq ($(shell id -u),0)
GLOBAL := --global
endif

.PHONY: install uninstall package

install:
	$(PKGTOOL) --type $(TYPE) $(GLOBAL) --upgrade package \
		|| $(PKGTOOL) --type $(TYPE) $(GLOBAL) --install package

uninstall:
	$(PKGTOOL) --type $(TYPE) $(GLOBAL) --remove $(ID)

package:
	tar -cJf $(NAME)-$(VERSION).tar.xz -C package metadata.json contents
	@echo "Created: $(NAME)-$(VERSION).tar.xz"
