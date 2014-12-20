include config

LD         = ${CC}

CFLAGS     = -lobjc -arch armv6 -Wall -Werror
LDFLAGS    = -bind_at_load
FRAMEWORKS = -framework Foundation \
	     -framework CoreFoundation \
	     -framework CoreGraphics \
	     -framework UIKit \
	     -I lib/obj-c

DEB_TMP    = out/deb-build

all: deb


src/gui/AppBackupGUI: lib/obj-c/*.m src/gui/*.m
	[ x"${CC}" == x"" ] && true || "${CC}" ${CFLAGS} ${LDFLAGS} ${FRAMEWORKS} -o $@ $^
	[ x"${CC}" == x"" ] && true || ldid -S $@

src/FixPermissions/FixPermissions: src/FixPermissions/*.c
	[ x"${CC}" == x"" ] && true || "${CC}" ${CFLAGS} ${LDFLAGS} -o $@ $^
	[ x"${CC}" == x"" ] && true || ldid -S $@


.PHONY: sdist out/python/path deb install test clean

sdist: src/python/setup.py
	mkdir -p out/python/sdist/src
	cp -a "$(dir $^)" out/python/sdist/src
	cd out/python/sdist; \
	 "$^" sdist && \
	 rm -f ../"$$("$^" --name)"-*.tar.gz && \
	 cp -a dist/"$$("$^" --fullname)".tar.gz ..
	rm -rf out/python/sdist

out/python/path: src/python/setup.py
	mkdir -p $@ $@/../src
	rm -rf $@/iosappbackup $@/iosappbackup-*
	cp -a $(dir $^) $@/../src
	cd $@/..; \
	 PYTHONPATH=$(notdir $@): $^ easy_install -d $(notdir $@) -Z -N -a -O2 $(dir $^)
	rm -rf $@/../src

deb: src/gui/AppBackupGUI src/FixPermissions/FixPermissions out/python/path
	rm -rf "${DEB_TMP}"
	mkdir "${DEB_TMP}"
	mkdir -p "${DEB_TMP}"/Applications/AppBackup.app
	cp -a data/DEBIAN "${DEB_TMP}"/
	cp -a data/AppBackup.app "${DEB_TMP}"/Applications/
	cp -a data/usr "${DEB_TMP}"/
	cp -a out/python/path "${DEB_TMP}"/Applications/AppBackup.app/python
	cp -a src/gui/AppBackupGUI "${DEB_TMP}"/Applications/AppBackup.app/AppBackupGUI_
	cp -a src/FixPermissions/FixPermissions "${DEB_TMP}"/Applications/AppBackup.app/
	i18n/ini-to-strings.py i18n "${DEB_TMP}"/Applications/AppBackup.app
	cp -a CHANGELOG "${DEB_TMP}"/Applications/AppBackup.app/
	cp -a CREDITS "${DEB_TMP}"/Applications/AppBackup.app/
	cp -a LICENSE "${DEB_TMP}"/Applications/AppBackup.app/
	rm -f "${DEB_TMP}"/Applications/AppBackup.app/python/*/*.py[co]
	rm -f "${DEB_TMP}"/Applications/AppBackup.app/python/*.py[co]
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
	 rm -rf out/python
