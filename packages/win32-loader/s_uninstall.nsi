; Debian-Installer Loader - Uninstallation
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

; Include required functions
${un.BOOTCFG_DeleteObject}
${un.BOOTCFG_RemoveBootEntry}

Function un.RemoveBootEntry
  ReadRegStr $0 HKLM "${REGSTR_WIN32}" "bootmgr"
  ${If} $0 != ""
    ${un.BOOTCFG_DeleteObject} $services $basebcdstore $bcdstore $0 $2 $1
    ${If} $1 != 0
      IntFmt $1 "0x%08X" $1
      MessageBox MB_OK "$2: $1"
    ${EndIf}
    ${un.BOOTCFG_RemoveBootEntry} $services $basebcdstore $bcdstore \
      $basebcdobject $0 $2 $1
    ${If} $1 != 0
      IntFmt $1 "0x%08X" $1
      MessageBox MB_OK "$2: $1"
    ${EndIf}
  ${Endif}

  Call un.CleanUp
FunctionEnd

Section "Uninstall"
  ; Initialise $c
  ReadRegStr $c HKLM "${REGSTR_WIN32}" "system_drive"

  IfFileExists "$c\boot.ini" 0 no_saved_boot_ini_timeout
  SetFileAttributes "$c\boot.ini" NORMAL
  SetFileAttributes "$c\boot.ini" SYSTEM|HIDDEN
  DeleteINIStr "$c\boot.ini" "operating systems" "$c\g2ldr.mbr"
    
  ReadIniStr $0 "$c\boot.ini" "boot loader" "old_timeout_win32-loader"
  IfErrors 0 no_saved_boot_ini_timeout
     ; Restore original timeout
     ClearErrors
     WriteIniStr "$c\boot.ini" "boot loader" "timeout" $0
     DeleteINIStr "$c\boot.ini" "boot loader" "old_timeout_win32-loader"
  no_saved_boot_ini_timeout:

  DeleteRegKey HKLM "${REGSTR_WIN32}"
  DeleteRegKey HKLM "${REGSTR_UNINST}"
  Delete $c\g2ldr
  Delete $c\g2ldr.mbr
  RMDir /r /REBOOTOK $INSTDIR
SectionEnd
