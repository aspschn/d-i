AUTOMAKE_OPTIONS = foreign

SUBDIRS = doc include src
if ENABLE_CHECK
SUBDIRS += test
endif

pkgconfigdir = ${libdir}/pkgconfig
pkgconfig_DATA = \
	libdebian-installer.pc \
	libdebian-installer-extra.pc
