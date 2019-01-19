; Debian-Installer Loader - Download functions
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

Function Download
    ; Base URL
    Pop $0
    ; Target dir
    Pop $6
    ; Filename
    Pop $2
    ; Allow it to fail?
    Pop $3
    ; Check its md5sum ?
    Pop $4
    Var /GLOBAL nsisdl_proxy
    ${If} $proxy == ""
      StrCpy $nsisdl_proxy /NOIEPROXY
    ${Else}
      StrCpy $nsisdl_proxy "/PROXY $proxy"
    ${Endif}

    DetailPrint "GET: $0/$2"
    NSISdl::download /TRANSLATE $(nsisdl1) $(nsisdl2) $(nsisdl3) $(nsisdl4) $(nsisdl5) $(nsisdl6) $(nsisdl7) $(nsisdl8) $nsisdl_proxy $0/$2 $6\$2
    Pop $R0
    ${If} $R0 != "success"
      ${If} $R0 != "cancel"
         MessageBox MB_OK|MB_ICONSTOP "$(error): $0/$2 $R0"
      ${EndIf}
      ${If} $3 == "false"
        Quit
      ${Endif}
    ${EndIf}

    ${If} $4 != "false"
      ; $2 goes in the text
      DetailPrint "$(computing_checksum)"
      ; Compute sha256sum of downloaded file, put it as $1
      libgcrypt_hash::hashsum "sha256" $6\$2
      Pop $1
      ${If} $4 != $1
       ; SHA256 don't match, try sha1sum
       libgcrypt_hash::hashsum "sha1" $6\$2
       Pop $1
       ${If} $4 != $1
        ; SHA1 don't match, try md5sum
        libgcrypt_hash::hashsum "md5" $6\$2
        Pop $1
        ${If} $4 != $1
          MessageBox MB_OK|MB_ICONSTOP "$(checksum_mismatch)"
          Quit
        ${EndIf}
       ${EndIf}
      ${EndIf}
      DetailPrint "$4 = $1"
    ${EndIf}

    Push "$R0"
FunctionEnd

Function Get_SHA1_ref
;Line is like:
; dc61910e515a26d252330d311136fa200e4d06fa       94 main/debian-installer/binary-amd64/Release
    ; Url we are looking for
    Pop $0
    ; Release file
    Pop $1
    ClearErrors
    FileOpen $3 $1 r
    IfErrors sha1_done ; Make sure it's readable
  sha1_readline:
    FileRead $3 $4
    IfErrors sha1_endoffile
    StrCpy $5 $4 -1 51 ; space + sha1sum + space-leftpadded size, -1 to get rid of newline
    ; Compare what we want with what we have
    StrCmpS $0 $5 0 sha1_readline
    StrCpy $0 $4 40 1 ; Copying the found sha1sum to $0
    Push $0
    FileClose $3
    Goto sha1_done
  sha1_endoffile:
    Push "false-sha1"
    FileClose $3
  sha1_done:
FunctionEnd

Function Get_SHA256_ref
;Line is like:
; d62f7850ef1a0a381c1e856936761ddd678e16dfdab90685de2deaf248f8d655      108 contrib/debian-installer/binary-amd64/Release
;or like;
;8716fec256b2df0b3e7c2f45a90813285b28fe7a72e4925c14d456d40af4caa1  ./netboot/debian-installer/amd64/linux
    ; Url we are looking for
    Pop $0
    ; Release file
    Pop $1
    ClearErrors
    FileOpen $3 $1 r
    IfErrors sha256_done ; Make sure it's readable
  sha256_readline:
    FileRead $3 $4
    IfErrors sha256_endoffile
    StrCpy $5 $4 -1 75 ; space + sha256sum + space-leftpadded size, -1 to get rid of newline
    ; Compare what we want with what we have
    StrCmpS $0 $5 0 sha256_alternativesyntax
    StrCpy $0 $4 64 1 ; Copying the found sha256sum to $0
    Push $0
    Goto sha256_done
  sha256_alternativesyntax:
    StrCpy $5 $4 -1 68 ; sha256sum + spaces and ./, -1 to get rid of newline
    ; Compare what we want with what we have
    StrCmpS $0 $5 0 sha256_readline
    StrCpy $0 $4 64 ; Copying the found sha256sum to $0
    Push $0
    Goto sha256_done
  sha256_endoffile:
    Push "false-sha256"
  sha256_done:
    FileClose $3
FunctionEnd
