AC_INIT

PACKAGE=entropy
AC_DEFINE_UNQUOTED(PACKAGE,"$PACKAGE")

AC_PROG_MAKE_SET
AC_PROG_CC

dnl dh_auto_configure may pass these options, used by some automake macros.
dnl Ignore them.
AC_ARG_ENABLE([maintainer-mode], [])
AC_ARG_ENABLE([dependency-tracking], [])

dnl Enable debugging?
AC_ARG_WITH(debug,[  --without-debug         turn off debugging?])
if test "$with_debug" == "yes"; then
  AC_DEFINE(DODEBUG)
  CFLAGS="$CFLAGS -g -D_DEBUG_"
fi

FRONTENDS="text"

AC_CHECK_LIB([textwrap], [textwrap_init],
        [TEXTWRAP_LIBS="-ltextwrap"
         CPPFLAGS="$CPPFLAGS -DHAVE_LIBTEXTWRAP"])
AC_SUBST([TEXTWRAP_LIBS])

PKG_CHECK_MODULES([NEWT], [libnewt],
                          FRONTENDS="$FRONTENDS newt",
                          echo "*** Cannot build Newt plugin ***")

AC_ARG_WITH([gtk-version], [AS_HELP_STRING([--with-gtk-version],
            [Select version of GTK+ to build for (default 2)])],
            [],
            [with_gtk_version=2])

case $with_gtk_version in
     2)PKG_CHECK_MODULES([GTK], [gtk+-x11-2.0],
                               FRONTENDS="$FRONTENDS gtk",
                               echo "*** Cannot build GTK+ plugin ***");;
     3)PKG_CHECK_MODULES([GTK], [gtk+-x11-3.0],
                               FRONTENDS="$FRONTENDS gtk",
                               echo "*** Cannot build GTK+ plugin ***");;
     *);;
esac

AC_SUBST(FRONTENDS)
AC_SUBST(PACKAGE)

AC_OUTPUT(Makefile)
