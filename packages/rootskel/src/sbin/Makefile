
DEB_HOST_ARCH_OS ?= $(shell dpkg-architecture -qDEB_HOST_ARCH_OS 2>/dev/null)

dir = sbin

files_exec = \
	debian-installer \
	debian-installer-startup \
	shutdown \
	init:init-$(DEB_HOST_ARCH_OS) \
	reopen-console:reopen-console-$(DEB_HOST_ARCH_OS) \
	steal-ctty

ifeq ($(DEB_HOST_ARCH_OS),linux)
  files_exec += \
	console-type \
	get-real-console-linux
endif

console-type: console-type.c
	gcc -Os -Wall console-type.c -o console-type

get-real-console-linux:
	gcc -Os -Wall get-real-console-linux.c -o get-real-console-linux

steal-ctty: steal-ctty.c
	gcc -Os -Wall steal-ctty.c -o steal-ctty

ifeq ($(DEB_HOST_ARCH_OS),linux)
build: console-type get-real-console-linux steal-ctty
else
build: steal-ctty
endif

clean:
	rm -f console-type get-real-console-linux steal-ctty

include ../../Makefile.inc
