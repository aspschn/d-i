# Force include/debian-installer not to be in the default search path.
# (It provides string.h and trumps the system copy.)
DEFAULT_INCLUDES = -I.@am__isrc@

AM_CPPFLAGS = \
	-I$(top_srcdir)/include -I$(top_builddir)/

noinst_LTLIBRARIES = libsystem.la

libsystem_la_SOURCES = \
	devfs.c \
	dpkg.c \
	efi.c \
	packages.c \
	prebaseconfig.c \
	utils.c

EXTRA_libsystem_la_SOURCES = \
	subarch-generic.c \
	subarch-arm-linux.c \
	subarch-arm64-linux.c \
	subarch-armeb-linux.c \
	subarch-armel-linux.c \
	subarch-armhf-linux.c \
	subarch-m68k-linux.c \
	subarch-mips-linux.c \
	subarch-mipsel-linux.c \
	subarch-mips64el-linux.c \
	subarch-powerpc-linux.c \
	subarch-ppc64-linux.c \
	subarch-ppc64el-linux.c \
	subarch-sh4-linux.c \
	subarch-sparc-linux.c \
	subarch-sparc64-linux.c \
	subarch-x86-linux.c \
	subarch-x86-kfreebsd.c

libsystem_la_LIBADD = \
	@SUBARCH_SYSTEM@

libsystem_la_DEPENDENCIES = \
	@SUBARCH_SYSTEM@
