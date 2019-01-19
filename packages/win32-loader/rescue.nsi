; Debian-Installer Loader - Rescue mode selection
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


Function ShowRescue
!ifdef PXE
 ${If} $pxe_mode == "false"
!endif ;PXE
  File /oname=$PLUGINSDIR\rescue.ini	templates/binary_choice.ini
  WriteINIStr $PLUGINSDIR\rescue.ini "Field 1" "Text" $(rescue1)
  WriteINIStr $PLUGINSDIR\rescue.ini "Field 2" "Text" $(rescue2)
  WriteINIStr $PLUGINSDIR\rescue.ini "Field 3" "Text" $(rescue3)
  InstallOptions::dialog $PLUGINSDIR\rescue.ini

  ReadINIStr $0 $PLUGINSDIR\rescue.ini "Field 3" "State"
  ${If} $0 == "1"
    StrCpy $preseed_cfg "\
$preseed_cfg$\n\
d-i rescue/enable boolean true"
  ${Endif}
!ifdef PXE
 ${Endif} ; $pxe_mode == "false"
!endif ;PXE
FunctionEnd

