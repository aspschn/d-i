; Debian-Installer Loader - Kernel choice
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


Function ShowKernel
  Var /GLOBAL kernel 
!ifdef NOCD
 !ifdef ALLKERNELS
  ${If} $expert == true
  ${AndIf} $windows_boot_method != direct ; loadlin can only load linux
    File /oname=$PLUGINSDIR\kernel.ini	templates/ternary_choice.ini
    WriteINIStr $PLUGINSDIR\kernel.ini "Field 1" "Text" $(kernel1)
    WriteINIStr $PLUGINSDIR\kernel.ini "Field 2" "Text" $(kernel2)
    WriteINIStr $PLUGINSDIR\kernel.ini "Field 3" "Text" $(kernel3)
    WriteINIStr $PLUGINSDIR\kernel.ini "Field 4" "Text" $(kernel4)
    InstallOptions::dialog $PLUGINSDIR\kernel.ini
 
    ReadINIStr $0 $PLUGINSDIR\kernel.ini "Field 3" "State"
    ReadINIStr $1 $PLUGINSDIR\kernel.ini "Field 4" "State"
    ${If} $0 == "1"
      StrCpy $kernel kfreebsd
    ${ElseIf} $1 == "1"
      StrCpy $kernel hurd
      # hurd doesn't exist in other architectures other than i386
      StrCpy $arch i386
    ${Else}
      StrCpy $kernel linux
    ${Endif}
  ${Else}
    ; ** Default to GNU/Linux
    StrCpy $kernel linux
  ${Endif}
 !else ; ALLKERNELS
    StrCpy $kernel linux
 !endif ; ALLKERNELS
!else ; NOCD
  ; When on CD, the win32-loader.ini contains a kernel={linux,kfreebsd} in the [installer] section
  ReadINIStr $kernel $d\win32-loader.ini "installer" "kernel"
  ; If there is nothing, default to linux
  ${If} $kernel == ""
    StrCpy $kernel linux
  ${EndIf}
!endif ; NOCD
  Var /GLOBAL kernel_name
  ${If} $kernel == "kfreebsd"
    StrCpy $kernel_name "GNU/kFreeBSD"
  ${ElseIf} $kernel == "linux"
    StrCpy $kernel_name "GNU/Linux"
  ${ElseIf} $kernel == "hurd"
    StrCpy $kernel_name "GNU/Hurd"
    # hurd doesn't exist in other architectures other than i386
    StrCpy $arch i386
  ${EndIf}
FunctionEnd

