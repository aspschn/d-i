TESTS = test

check_PROGRAMS = test

EXTRA_DIST = Packages

# Force include/debian-installer not to be in the default search path.
# (It provides string.h and trumps the system copy.)
DEFAULT_INCLUDES = -I.@am__isrc@

AM_CFLAGS = -I$(top_srcdir)/include @CHECK_CFLAGS@ -DDATADIR=\"$(srcdir)\"

test_SOURCES = main.c test_hash.c test_system_packages.c test_exec.c
test_LDADD = $(top_builddir)/src/.libs/libdebian-installer.la @CHECK_LIBS@
