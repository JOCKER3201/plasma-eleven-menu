# plasma-eleven-menu — instalacja i pakowanie
#
#   make install        instalacja/aktualizacja dla bieżącego użytkownika
#   sudo make install   instalacja/aktualizacja globalna (systemowa)
#   make uninstall      usunięcie (sudo make uninstall — wersji globalnej)
#   make package        archiwum plasma-eleven-menu-<wersja>.tar.xz

PKGTOOL ?= kpackagetool6
TYPE    := Plasma/Applet
NAME    := plasma-eleven-menu
ID      := com.github.jocker3201.elevenmenu
VERSION := $(shell sed -n 's/.*"Version": *"\([^"]*\)".*/\1/p' package/metadata.json)

# Uruchomione przez roota (sudo make install) instaluje globalnie.
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
	@echo "Utworzono: $(NAME)-$(VERSION).tar.xz"
