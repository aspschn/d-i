; Debian-Installer Loader - Initialisation
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

!include include/bootcfg.nsh

!macro SetUp UN
!insertmacro BOOTCFG_FUNCINC "${UN}" ConnectWMI
!insertmacro BOOTCFG_FUNCINC "${UN}" GetObject
!insertmacro BOOTCFG_FUNCINC "${UN}" OpenDefaultBcdStore
Function `${UN}Setup`
  Push $0
  Push $1

  !insertmacro ${BOOTCFG_PREFIX}ConnectWMI_Call "${UN}" $locator $services $0
  ${If} $0 != 0
    StrCpy $1 $services
    StrCpy $services ""
    StrCpy $locator ""
  ${Else}
    !insertmacro ${BOOTCFG_PREFIX}GetObject_Call "${UN}" \
      $services "BcdStore" $basebcdstore $0
    ${If} $0 != 0
      StrCpy $1 $basebcdstore
      StrCpy $basebcdstore ""
    ${Else}
      !insertmacro ${BOOTCFG_PREFIX}GetObject_Call "${UN}" \
        $services "BcdObject" $basebcdobject $0
      ${If} $0 != 0
        StrCpy $1 $basebcdobject
        StrCpy $basebcdobject ""
      ${Else}
        !insertmacro ${BOOTCFG_PREFIX}OpenDefaultBcdStore_Call "${UN}" \
          $services $basebcdstore $bcdstore $0
        ${If} $0 != 0
          StrCpy $1 $bcdstore
          StrCpy $bcdstore ""
        ${EndIf}
      ${EndIf}
    ${EndIf}
  ${EndIf}

  ${If} $0 != 0
    IntFmt $0 "0x%08X" $0
    DetailPrint "$1: $0"
  ${EndIf}

  Pop $1
  Pop $0
FunctionEnd
!macroend

!macro CleanUp UN
Function `${UN}CleanUp`
  !insertmacro ${BOOTCFG_PREFIX}ReleaseObject_Call "${UN}" $bcdstore
  !insertmacro ${BOOTCFG_PREFIX}ReleaseObject_Call "${UN}" $basebcdobject
  !insertmacro ${BOOTCFG_PREFIX}ReleaseObject_Call "${UN}" $basebcdstore
  !insertmacro ${BOOTCFG_PREFIX}ReleaseObject_Call "${UN}" $services
  !insertmacro ${BOOTCFG_PREFIX}ReleaseObject_Call "${UN}" $locator
  StrCpy $bcdstore ""
  StrCpy $basebcdobject ""
  StrCpy $basebcdstore ""
  StrCpy $services ""
  StrCpy $locator ""
FunctionEnd
!macroend

!insertmacro SetUp ""
!insertmacro Setup "un."
!insertmacro CleanUp ""
!insertmacro CleanUp "un."

Function .onInit
  InitPluginsDir

  Call SetUp

!ifdef TARGET_DISTRO
  StrCpy $target_distro "${TARGET_DISTRO}"
!else
  StrCpy $target_distro "Debian"
!endif

  ; needed by: timezones, keymaps, languages
  File /oname=$PLUGINSDIR\maps.ini maps.ini

  ; default to English
  StrCpy $LANGUAGE ${LANG_ENGLISH}

  ; Language selection dialog
  Push ""
!include l10n/templates/dialog.nsh
  Push unsupported
  Push "-- Not in this list --"

  Push A ; A means auto count languages
         ; for the auto count to work the first empty push (Push "") must remain
  LangDLL::LangDialog "Choose language" "Please choose the language used for \
the installation process. This language will be the default language for the \
final system."

  Pop $LANGUAGE
  ${If} $LANGUAGE == "cancel"
    Abort
  ${Endif}

  ; Note: Possible API abuse here.  Nsis *seems* to fallback sanely to English
  ; when $LANGUAGE == "unsupported", so we'll use that to decide wether to
  ; preseed later.

  Var /GLOBAL unsupported_language
  ${If} $LANGUAGE == "unsupported"
    StrCpy $unsupported_language true
    ; Translators: your language is supported by d-i, but not yet by nsis.
    ; Please get your translation in nsis before translating win32-loader.
    MessageBox MB_OK "Because your language is not supported by this \
stage of the installer, English will be used for now.  On the second \
(and last) stage of the install process, you will be offered a much \
wider choice, where your language is more likely to be present."
    ; Test in Windows 7 shows a somehow random choice, force it to LANG_ENGLISH.
    StrCpy $LANGUAGE ${LANG_ENGLISH}
  ${Else}
    StrCpy $unsupported_language false
  ${Endif}
FunctionEnd

Function .onUserAbort
  Call CleanUp
FunctionEnd

Function un.onInit
  Call un.SetUp
FunctionEnd

Function un.onUserAbort
  Call un.CleanUp
FunctionEnd
