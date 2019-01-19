#! /usr/bin/make -f

VERSION?=UNRELEASED
MODULES:=devicename-detect devicetype-detect laptop-detect
SCRIPTS= $(foreach module,${MODULES},${module}.sh)


all: ${SCRIPTS}

%.sh: %.in
	sed -e "s/@VERSION@/${VERSION}/" < $< > $@

clean:
	-rm -r ${SCRIPTS}

install: ${SCRIPTS}
	install -D -m 755 devicename-detect.sh \
	    ${DESTDIR}/usr/sbin/devicename-detect
	install -D -m 755 devicetype-detect.sh \
	    ${DESTDIR}/usr/sbin/devicetype-detect
	install -D -m 755 laptop-detect.sh \
	    ${DESTDIR}/usr/sbin/laptop-detect

.PHONY: all clean install
