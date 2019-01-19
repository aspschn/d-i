; Debian-Installer Loader - Final customisation
; 
; Copyright (C) 2007,2008,2009  Robert Millan <rmh@aybabtu.com>
; Copyright (C) 2010,2011       Didier Raboud <odyx@debian.org>
;
; This program is free software: you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation, either version 3 of the License, or
; (at your option) any later version.
;
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
;
; You should have received a copy of the GNU General Public License
; along with this program.  If not, see <http://www.gnu.org/licenses/>.


Function ShowCustom
; Gather all the missing information before ShowCustom is displayed

!ifndef NOCD

; ********************************************** Media-based install
  Var /GLOBAL g2ldr
  Var /GLOBAL g2ldr_mbr
  ReadINIStr $g2ldr	$d\win32-loader.ini "grub" "g2ldr"
  ReadINIStr $g2ldr_mbr	$d\win32-loader.ini "grub" "g2ldr.mbr"
  StrCmp $g2ldr		"" incomplete_ini
  StrCmp $g2ldr_mbr	"" incomplete_ini
  ${If} $kernel == "linux"
    Var /GLOBAL linux
    Var /GLOBAL initrd
    ReadINIStr $linux	$d\win32-loader.ini "installer" "$arch/$gtklinux"
    ReadINIStr $initrd	$d\win32-loader.ini "installer" "$arch/$gtkinitrd"
    StrCmp $linux	"" incomplete_ini
    StrCmp $initrd	"" incomplete_ini
    Goto ini_is_ok
  ${ElseIf} $kernel == "kfreebsd"
    Var /GLOBAL kfreebsd
    Var /GLOBAL kfreebsd_module
    ReadINIStr $kfreebsd	$d\win32-loader.ini "installer" "kfreebsd-$arch/$gtkkfreebsd"
    ReadINIStr $kfreebsd_module	$d\win32-loader.ini "installer" "kfreebsd-$arch/$gtkkfreebsd_module"
    StrCmp $kfreebsd		"" incomplete_ini
    StrCmp $kfreebsd_module	"" incomplete_ini
  ${ElseIf} $kernel == "hurd"
    Var /GLOBAL gnumach
    Var /GLOBAL ext2fs
    Var /GLOBAL ld
    ReadINIStr $gnumach		$d\win32-loader.ini "installer" "hurd-$arch/$gtkgnumach"
    ReadINIStr $ext2fs		$d\win32-loader.ini "installer" "hurd-$arch/$gtkext2fs"
    ReadINIStr $initrd		$d\win32-loader.ini "installer" "hurd-$arch/$gtkinitrd"
    ReadINIStr $ld		$d\win32-loader.ini "installer" "hurd-$arch/$gtklt"
    StrCmp $gnumach		"" incomplete_ini
    StrCmp $ext2fs		"" incomplete_ini
    StrCmp $initrd		"" incomplete_ini
    StrCmp $ld			"" incomplete_ini
  ${EndIf}
  Goto ini_is_ok
incomplete_ini:
  MessageBox MB_OK|MB_ICONSTOP "$(error_incomplete_ini)"
  Quit
ini_is_ok:

!endif

; ********************************************** Initialise proxy (even when in network-less mode, for the sake of preseeding)
  StrCpy $proxy ""
  ReadRegDWORD $0 HKCU "Software\Microsoft\Windows\CurrentVersion\Internet Settings" ProxyEnable
  IntCmp $0 1 0 proxyless
  ReadRegStr $0 HKCU "Software\Microsoft\Windows\CurrentVersion\Internet Settings" ProxyServer
  StrCmp $0 "" proxyless
  StrCpy $proxy "$0"
proxyless:

; ********************************************** preseed locale
  ${If} $unsupported_language == false
    ReadINIStr $0 $PLUGINSDIR\maps.ini "languages" "$LANGUAGE"
    ReadRegStr $1 HKCU "Control Panel\International" iCountry
    ReadINIStr $1 $PLUGINSDIR\maps.ini "countries" "$1"
    ${If} $0 != ""
      ${If} $1 != ""
        StrCpy $0 "$0_$1"
      ${Endif}
      StrCpy $preseed_cfg "\
$preseed_cfg$\n\
d-i debian-installer/locale string $0"
    ${Endif}
  ${Endif}

; ********************************************** preseed domain
  systeminfo::domain
  Pop $2
  Pop $0
  ${If} $2 != 0
    ${If} $0 != ""
      StrCpy $preseed_cfg "\
$preseed_cfg$\n\
d-i netcfg/get_domain string $0$\n\
d-i netcfg/get_domain seen false"
    ${Endif}
  ${EndIf}

; ********************************************** preseed timezone
  ReadRegStr $0 HKLM SYSTEM\CurrentControlSet\Control\TimeZoneInformation TimeZoneKeyName
  ${If} $0 == ""
    ReadRegStr $0 HKLM SYSTEM\CurrentControlSet\Control\TimeZoneInformation StandardName
  ${Endif}
  ReadINIStr $0 $PLUGINSDIR\maps.ini "timezones" "$0"
  ${If} $0 != ""
    StrCpy $preseed_cfg "\
$preseed_cfg$\n\
d-i time/zone string $0$\n\
d-i time/zone seen false"
  ${Endif}

; ********************************************** preseed keymap
  systeminfo::keyboard_layout
  Pop $0
  ; lower word is the locale identifier (higher word is a handler to the actual layout)
  IntOp $0 $0 & 0x0000FFFF
  IntFmt $0 "0x%04X" $0
  ReadINIStr $0 $PLUGINSDIR\maps.ini "keymaps" "$0"
  ; FIXME: do we need to support non-AT keyboards here?
  ${If} $0 != ""
    ${If} $expert == true
      MessageBox MB_YESNO|MB_ICONQUESTION $(detected_keyboard_is) IDNO keyboard_bad_guess
      StrCpy $preseed_cfg "\
$preseed_cfg$\n\
d-i console-keymaps-at/keymap select $0$\n\
d-i console-keymaps-at/keymap seen true"
      Goto keyboard_end
keyboard_bad_guess:
      MessageBox MB_OK $(keyboard_bug_report)
keyboard_end:
    ${Else}
      StrCpy $preseed_cfg "\
$preseed_cfg$\n\
d-i console-keymaps-at/keymap select $0$\n\
d-i console-keymaps-at/keymap seen false"
    ${Endif}
  ${Endif}

; ********************************************** preseed hostname
  systeminfo::hostname
  Pop $2
  Pop $0
  ${If} $2 != 0
    ${If} $0 != ""
      StrCpy $preseed_cfg "\
$preseed_cfg$\n\
d-i netcfg/get_hostname string $0$\n\
d-i netcfg/get_hostname seen false"
    ${Endif}
  ${EndIf}

; ********************************************** preseed priority
  ${If} $expert == true
    StrCpy $preseed_cmdline "$preseed_cmdline priority=low"
  ${Endif}

; ********************************************** preseed user-fullname
  systeminfo::username
  Pop $0
  ${If} $0 != ""
    StrCpy $preseed_cfg "\
$preseed_cfg$\n\
d-i passwd/user-fullname string $0$\n\
d-i passwd/user-fullname seen false"
  ${Endif}

!ifdef NETWORK_BASE_URL
; ********************************************** if ${NETWORK_BASE_URL} provides a preseed.cfg, use it
  Push ${NETWORK_BASE_URL_CHECKSUM}
  Push true
  Push "preseed.cfg"
  Push "$PLUGINSDIR"
  Push "${NETWORK_BASE_URL}"
  Call Download
  Pop $0
  ${If} $0 == "success"
    StrCpy $preseed_cfg "$preseed_cfg$\n$\n"
    ClearErrors
    FileOpen $0 $PLUGINSDIR\preseed.cfg r
network_preseed_loop:
    FileRead $0 $1
    IfErrors +3
    StrCpy $preseed_cfg "\
$preseed_cfg\
$1"
    Goto network_preseed_loop
    FileClose $0
    StrCpy $preseed_cfg "$preseed_cfg$\n"
  ${Endif}
!endif

; ********************************************** Display customisation dialog now
  ${If} $expert == true
    File /oname=$PLUGINSDIR\custom.ini templates/custom.ini
    WriteINIStr $PLUGINSDIR\custom.ini "Field 1" "Text" $(custom1)
    WriteINIStr $PLUGINSDIR\custom.ini "Field 2" "Text" $(custom2)
    WriteINIStr $PLUGINSDIR\custom.ini "Field 3" "Text" $(custom3)
    WriteINIStr $PLUGINSDIR\custom.ini "Field 4" "Text" "Kernel commandline:"
    WriteINIStr $PLUGINSDIR\custom.ini "Field 5" "Text" $(custom5)
    WriteINIStr $PLUGINSDIR\custom.ini "Field 6" "State" "$proxy"
!ifdef NOCD
    WriteINIStr $PLUGINSDIR\custom.ini "Field 8" "State" "$base_url"
!endif
    WriteINIStr $PLUGINSDIR\custom.ini "Field 9" "State" "$preseed_cmdline"
    InstallOptions::dialog $PLUGINSDIR\custom.ini
    ReadINIStr $proxy		$PLUGINSDIR\custom.ini "Field 6" "State"
!ifdef NOCD
    ReadINIStr $base_url	$PLUGINSDIR\custom.ini "Field 8" "State"
!endif
    ReadINIStr $preseed_cmdline	$PLUGINSDIR\custom.ini "Field 9" "State"
  ${Endif}

; do this inmediately after custom.ini, because proxy settings can be
; overriden there
; ********************************************** preseed proxy
  ${If} $proxy == ""
    StrCpy $preseed_cfg "\
$preseed_cfg$\n\
d-i mirror/http/proxy seen true$\n"
  ${Else}
    StrCpy $preseed_cfg "\
$preseed_cfg$\n\
d-i mirror/http/proxy string http://$proxy/$\n"
  ${Endif}
FunctionEnd
