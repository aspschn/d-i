; Debian-Installer Loader - Graphical installer choice
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


Function ShowGraphics
  Var /GLOBAL user_interface
  Var /GLOBAL gtk

!ifndef NOCD
  Var /GLOBAL predefined_user_interface
  ReadINIStr $predefined_user_interface $d\win32-loader.ini "installer" "user_interface"

  ${If} $predefined_user_interface == ""
!endif
    ${If} $expert == true
      File /oname=$PLUGINSDIR\graphics.ini	templates/graphics.ini
      File /oname=$PLUGINSDIR\gtk.bmp	templates/gtk.bmp
      File /oname=$PLUGINSDIR\text.bmp	templates/text.bmp
      WriteINIStr $PLUGINSDIR\graphics.ini "Field 1" "Text" $(graphics1)
      WriteINIStr $PLUGINSDIR\graphics.ini "Field 2" "Text" "$PLUGINSDIR\gtk.bmp"
      WriteINIStr $PLUGINSDIR\graphics.ini "Field 3" "Text" "$PLUGINSDIR\text.bmp"
      WriteINIStr $PLUGINSDIR\graphics.ini "Field 4" "Text" $(graphics2)
      WriteINIStr $PLUGINSDIR\graphics.ini "Field 5" "Text" $(graphics3)
      InstallOptions::dialog $PLUGINSDIR\graphics.ini
      ReadINIStr $0 $PLUGINSDIR\graphics.ini "Field 4" "State"
      ${If} $0 == "1"
        StrCpy $user_interface graphical
      ${EndIf}
    ${Else}
      ; ** Default to graphical interface for all kernels
      StrCpy $user_interface graphical
    ${Endif}
!ifndef NOCD
  ${Else}
    StrCpy $user_interface $predefined_user_interface
  ${Endif}
!endif

${If} $user_interface == "graphical"
  StrCpy $gtk "gtk/"
${Endif}

; ********************************************** Preseed vga mode
${If} $kernel == "linux"
  ; See debian-installer/build/config/{i386,amd64}.cfg
  StrCpy $preseed_cmdline "$preseed_cmdline vga=788"
${ElseIf} $kernel == "hurd"
  ${If} "$user_interface" != "graphical"
    StrCpy $preseed_cmdline "$preseed_cmdline GTK_NOVESA=1"
  ${Endif}
${Endif}
FunctionEnd
