include config

LD         = ${CC}

CFLAGS     = -arch armv6 -Wall
LDFLAGS    = -lobjc -arch armv6 \
	     -bind_at_load
FRAMEWORKS = -framework Foundation \
	     -framework CoreFoundation \
	     -framework CoreGraphics \
	     -framework UIKit

DEB_TMP    = out/deb-build

all: deb


src/gui/AppBackupGUI: lib/obj-c/*.m src/gui/*.m
	[ x"${CC}" == x"" ] && true || "${CC}" ${LDFLAGS} ${FRAMEWORKS} -o $@ $^
	[ x"${CC}" == x"" ] && true || ldid -S $@

src/FixPermissions/FixPermissions: src/FixPermissions/*.c
	[ x"${CC}" == x"" ] && true || "${CC}" ${LDFLAGS} -o $@ $^
	[ x"${CC}" == x"" ] && true || ldid -S $@


.PHONY: deb install test clean

deb: src/gui/AppBackupGUI src/FixPermissions/FixPermissions
	rm -rf "${DEB_TMP}"
	mkdir "${DEB_TMP}"
	mkdir -p "${DEB_TMP}"/Applications/AppBackup.app/python
	cp -a data/DEBIAN "${DEB_TMP}"/
	cp -pRL data/AppBackup.app "${DEB_TMP}"/Applications/
	cp -a data/usr "${DEB_TMP}"/
	cp -a src/gui/AppBackupGUI "${DEB_TMP}"/Applications/AppBackup.app/AppBackupGUI_
	cp -a src/FixPermissions/FixPermissions "${DEB_TMP}"/Applications/AppBackup.app/
	i18n/ini-to-strings.py i18n "${DEB_TMP}"/Applications/AppBackup.app
	cp -a src/python/* "${DEB_TMP}"/Applications/AppBackup.app/python
	cp -a CHANGELOG "${DEB_TMP}"/Applications/AppBackup.app/
	cp -a CREDITS "${DEB_TMP}"/Applications/AppBackup.app/
	cp -a LICENSE "${DEB_TMP}"/Applications/AppBackup.app/
	rm -f "${DEB_TMP}"/Applications/AppBackup.app/python/*/*.py[co]
	rm -f "${DEB_TMP}"/Applications/AppBackup.app/python/*.py[co]
	rm -f "${DEB_TMP}"/Applications/AppBackup.app/python/setup.py
	rm -rf "${DEB_TMP}"/Applications/AppBackup.app/python/simplejson/tests
	chmod +x "${DEB_TMP}"/Applications/AppBackup.app/appbackup-cli
	chmod +x "${DEB_TMP}"/Applications/AppBackup.app/AppBackupGUI{,_}
	chmod +x "${DEB_TMP}"/usr/bin/appbackup{,-fix-permissions}
	touch "${DEB_TMP}"/Applications/AppBackup.app/about.html
	src/gui/about.html/make-about-html.py > "${DEB_TMP}"/Applications/AppBackup.app/about.html
	cp -a src/gui/about.html/basic.css "${DEB_TMP}"/Applications/AppBackup.app/basic.css
	dpkg-deb -b "${DEB_TMP}" out
	rm -r "${DEB_TMP}"

install:
	@[ x"${DEVICE}" != x"" ] && true || \
	  { echo "Usage: make install DEVICE=<hostname/address>" >&2; exit 2; }
	scp -p "`ls -rt out/*.deb | tail -n 1`" mobile@${DEVICE}:/tmp/appbackup.deb
	ssh root@${DEVICE} "dpkg -i /tmp/appbackup.deb && rm /tmp/appbackup.deb"

test:
	@[ x"${DEVICE}" != x"" ] && true || \
	  { echo "Usage: make test DEVICE=<hostname/address>" >&2; exit 2; }
	make
	make install
	ssh mobile@${DEVICE}

clean:
	 rm -f src/gui/AppBackupGUI src/gui/*.o
	 rm -f src/FixPermissions/FixPermissions src/FixPermissions/*.o
