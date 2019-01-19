
export SHELL := bash

# Targets that will always be run (as they depend on stuff from installed packages)
.PHONY: core.img g2ldr g2ldr.mbr loadlin.pif loadlin.exe pxe.lkrn

PACKAGE	:= win32-loader
VERSION	:= $(shell head -n 1 debian/changelog | sed -e "s/^$(PACKAGE) (\(.*\)).*/\1/g")
BUILD_DATE	?= $(shell LC_ALL=C date +'%a, %d %b %Y %T %z')
FOUR_DIGITS_DATE	:= $(shell date -u +'%Y.%m.%d.%H%M' --date="$(BUILD_DATE)")

NSIS_CC		:= i686-w64-mingw32-gcc -Os -Xlinker --no-insert-timestamp
NSIS_STRIP	:= i686-w64-mingw32-strip
NSIS_CFLAGS	:= -Wl,--file-alignment,512 -Werror -D_WIN32_WINNT=0x0500

ICONSIZES       := 16 24 32 48 256

ifeq ($(wildcard /usr/i686-w64-mingw32/include/exdll.h), /usr/i686-w64-mingw32/include/exdll.h)
NSIS_CFLAGS	+= -DHAVE_EXDLL_H
else
NSIS_CFLAGS	+= -L/usr/i686-w64-mingw32/lib/nsis/ -lpluginapi-x86-ansi
endif

# Standard makensis call
MAKENSIS	:= makensis -V3

# Add to it some version'ing and date
MAKENSIS	+= -DVERSION=$(VERSION) -D4DIGITS_DATE=$(FOUR_DIGITS_DATE)

ifdef OUTFILE_NAME
MAKENSIS	+= -D_OUTFILE_NAME=$(OUTFILE_NAME)
endif

# Distributor/Company name (defaults to "The Debian Project")
ifdef COMPANY_NAME
MAKENSIS	+= -D_COMPANY_NAME=$(COMPANY_NAME)
endif

# Distribution name (ASCII only, please)
ifdef TARGET_DISTRO
MAKENSIS	+= -DTARGET_DISTRO=$(TARGET_DISTRO)
endif

# Standalone version : Not linked to a website with preseed.cfg
ifdef STANDALONE
MAKENSIS	+= -DNOCD=yes
OPTIONS_TXT	+= +net
endif

# Network version : Linked to a website with preseed.cfg
ifdef NETWORK_BASE_URL
# Embed the md5sum or sha1sum of the $(NETWORK_BASE_URL)/preseed.cfg file for enhanced security.
MAKENSIS	+= -DNETWORK_BASE_URL=$(NETWORK_BASE_URL) -DNOCD=yes -DNETWORK_BASE_URL_CHECKSUM=$(NETWORK_BASE_URL_CHECKSUM)
OPTIONS_TXT	+= +url
endif

# PXE version (which is standalone too)
ifdef PXE
MAKENSIS	+= -DPXE=yes -DNOCD=yes
OPTIONS_TXT	+= +pxe
endif

# Disabling the kFreeBSD download
ifndef NOT_ALLKERNELS
MAKENSIS	+= -DALLKERNELS=yes
OPTIONS_TXT	+= +kernels
endif

# Allowing the branch selection
ifdef DAILIES
MAKENSIS	+= -DDAILIES=yes
OPTIONS_TXT	+= +dailies
endif

ifdef OPTIONS_TXT
MAKENSIS	+= -DOPTIONS_TXT="$(OPTIONS_TXT)"
endif

# hard disk
GRUB_MODULES	+= biosdisk
# partmap
GRUB_MODULES	+= part_msdos part_gpt
# fs
GRUB_MODULES	+= fat ntfs ntfscomp
# used in our grub.cfg
GRUB_MODULES	+= search linux bsd multiboot vbe boot
# might be useful for debugging
GRUB_MODULES	+= minicmd cat cpuid chain halt help ls reboot
# useful for loading files from ISO images
GRUB_MODULES	+= loopback iso9660
ifndef NOT_ALLKERNELS
# gzio is needed for kFreeBSD
GRUB_MODULES    += gzio
endif
ifdef PXE
# Booting the pxe.lkrn requires linux16
GRUB_MODULES	+= linux16
endif

all: win32-loader.exe g2ldr g2ldr.mbr

core.img:
	grub-mkimage --output=$@ --prefix=/win32-loader --format=i386-pc $(GRUB_MODULES)

g2ldr: /usr/lib/grub/i386-pc/g2hdr.bin core.img
	cat $^ > $@

g2ldr.mbr: /usr/lib/grub/i386-pc/g2ldr.mbr
	cp $^ $@

loadlin.pif: genpif
	bash $^ > $@

loadlin.exe: /usr/lib/loadlin/loadlin.exe.gz
	gunzip -c $^ > $@

pxe.lkrn: /usr/lib/ipxe/ipxe.lkrn
	cp $^ $@

ifdef PXE
PXE_TARGETS = pxe.lkrn templates/ternary_choice.ini
else
PXE_TARGETS =
endif

templates/gtk.bmp: templates/gtk_orig.png
	convert $^ -resize 107x80 BMP3:$@

# Build icons out of the SVG source, force them being square
icon/swirl-%.png: icon/swirl.svg
	rsvg-convert -f png -h $* -w $* $^ > $@

# Build the icon out of the PNG icons
win32-loader.ico: $(ICONSIZES:%=icon/swirl-%.png)
	icotool -c -o $@ $^

win32-loader.exe: main.nsi maps.ini \
		templates/binary_choice.ini templates/graphics.ini templates/custom.ini templates/4_choices.ini \
		templates/gtk.bmp templates/text.bmp \
		plugins/cpuid/test64.dll plugins/systeminfo/systeminfo.dll plugins/string.dll \
		plugins/libgcrypt_hash.dll \
		$(PXE_TARGETS) \
		win32-loader.ico loadlin.pif loadlin.exe g2ldr g2ldr.mbr
	find $^ -newermt "$(BUILD_DATE)" -print0 | xargs -0r touch --date="$(BUILD_DATE)"
	$(MAKE) -C l10n
	$(MAKENSIS) main.nsi
ifndef OUTFILE_NAME
	du -h win32-loader.exe
else
	du -h $(OUTFILE_NAME)
endif

plugins/cpuid/test64.dll: plugins/cpuid/cpuid.c plugins/cpuid/plugin.c
	$(NSIS_CC) $^ $(NSIS_CFLAGS) -shared -o $@
	$(NSIS_STRIP) $@

plugins/systeminfo/systeminfo.dll: plugins/systeminfo/systeminfo.c
	$(NSIS_CC) $^ $(NSIS_CFLAGS) -shared -o $@
	$(NSIS_STRIP) $@

plugins/string.dll: plugins/string.c
	$(NSIS_CC) $^ $(NSIS_CFLAGS) -shared -o $@
	$(NSIS_STRIP) $@

plugins/libgcrypt_hash.dll: plugins/libgcrypt_hash.c
	$(NSIS_CC) $^ $(NSIS_CFLAGS) -shared -static-libgcc /usr/i686-w64-mingw32/lib/libgcrypt.a /usr/i686-w64-mingw32/lib/libgpg-error.a /usr/i686-w64-mingw32/lib/libwsock32.a -o $@
	$(NSIS_STRIP) $@

iso: stable.iso daily.iso
stable.iso: \
  netboot/download-stable-stamp \
  netboot/stable/win32-loader.exe netboot/stable/g2ldr netboot/stable/g2ldr.mbr \
  netboot/stable/autorun.inf netboot/stable/win32-loader.ini \
  $(NULL)
	genisoimage -r -J -o $@ netboot/stable

daily.iso: \
  netboot/download-daily-stamp \
  netboot/daily/win32-loader.exe netboot/daily/g2ldr netboot/daily/g2ldr.mbr \
  netboot/daily/autorun.inf netboot/daily/win32-loader.ini \
  $(NULL)
	genisoimage -r -J -o $@ netboot/daily

BASE_URL=http://deb.debian.org/debian/dists/stable/main
netboot/download-stable-stamp:
	mkdir -p netboot/stable/install.{386,amd}/gtk
	wget $(BASE_URL)/installer-i386/current/images/netboot/debian-installer/i386/linux \
		-O netboot/stable/install.386/vmlinuz
	wget $(BASE_URL)/installer-i386/current/images/netboot/debian-installer/i386/initrd.gz \
		-O netboot/stable/install.386/initrd.gz
	wget $(BASE_URL)/installer-i386/current/images/netboot/gtk/debian-installer/i386/initrd.gz \
		-O netboot/stable/install.386/gtk/initrd.gz
	wget $(BASE_URL)/installer-amd64/current/images/netboot/debian-installer/amd64/linux \
		-O netboot/stable/install.amd/vmlinuz
	wget $(BASE_URL)/installer-amd64/current/images/netboot/debian-installer/amd64/initrd.gz \
		-O netboot/stable/install.amd/initrd.gz
	wget $(BASE_URL)/installer-amd64/current/images/netboot/gtk/debian-installer/amd64/initrd.gz \
		-O netboot/stable/install.amd/gtk/initrd.gz
	touch $@

netboot/download-daily-stamp:
	mkdir -p netboot/daily/install.{386,amd}/gtk
	wget https://d-i.debian.org/daily-images/i386/daily/netboot/debian-installer/i386/linux \
		-O netboot/daily/install.386/vmlinuz
	wget https://d-i.debian.org/daily-images/i386/daily/netboot/debian-installer/i386/initrd.gz \
		-O netboot/daily/install.386/initrd.gz
	wget https://d-i.debian.org/daily-images/i386/daily/netboot/gtk/debian-installer/i386/initrd.gz \
		-O netboot/daily/install.386/gtk/initrd.gz
	wget https://d-i.debian.org/daily-images/amd64/daily/netboot/debian-installer/amd64/linux \
		-O netboot/daily/install.amd/vmlinuz
	wget https://d-i.debian.org/daily-images/amd64/daily/netboot/debian-installer/amd64/initrd.gz \
		-O netboot/daily/install.amd/initrd.gz
	wget https://d-i.debian.org/daily-images/amd64/daily/netboot/gtk/debian-installer/amd64/initrd.gz \
		-O netboot/daily/install.amd/gtk/initrd.gz
	touch $@

netboot/stable/autorun.inf netboot/daily/autorun.inf: autorun.inf
	mkdir -p netboot/{stable,daily}
	todos < $< > $@
netboot/stable/win32-loader.ini netboot/daily/win32-loader.ini: win32-loader.ini
	mkdir -p netboot/{stable,daily}
	todos < $< > $@

netboot/stable/win32-loader.exe netboot/daily/win32-loader.exe: win32-loader.exe
	mkdir -p netboot/{stable,daily}
	cp $^ $@

netboot/stable/% netboot/daily/%: %
	mkdir -p netboot/{stable,daily}
	cp $(shell basename $@) $@

clean:
	$(MAKE) -C l10n clean
	rm -f plugins/cpuid/*.dll plugins/cpuid/*.exe plugins/systeminfo/*.dll plugins/*.dll win32-loader.exe \
		*.iso *~ */*~ core.img g2ldr g2ldr.mbr loadlin.pif loadlin.exe pxe.lkrn icon/*.png win32-loader.ico

distclean: clean
	rm -rf netboot
