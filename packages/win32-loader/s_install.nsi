; Debian-Installer Loader - Installation
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
${BOOTCFG_CreateGUID}
${BOOTCFG_CreateObject}
${BOOTCFG_SetDescription}
${BOOTCFG_SetPartition}
${BOOTCFG_SetPath}
${BOOTCFG_AppendBootEntry}

; Create boot entry and add it to display list of boot manager
; Parameter:
;   guid - global unique identifier of boot entry
;   label - brief description of boot entry
Function AddBootEntry
  Exch $0
  Exch
  Exch $1
  Push $2
  Push $3
  Push $4

  StrCpy $3 $0
  StrCpy $2 $1
  StrCpy $1 $c
  System::Call "kernel32::QueryDosDevice(t r1, t .r4, \
    i${NSIS_MAX_STRLEN}) i .r0"

  ; guid=$2, label=$3, systempartition=$4
  ${If} $2 != ""
    ${BOOTCFG_CreateObject} $services $basebcdstore $bcdstore \
      ${BOOTCFG_BOOT_SECTOR} $2 $1 $0
    ${If} $0 == 0
      ${BOOTCFG_SetDescription} $services $basebcdobject $1 "$3" $3 $0
      ${If} $0 == 0
        ; Release result
        ${BOOTCFG_ReleaseObject} $3
        ${BOOTCFG_SetPartition} $services $basebcdobject $1 $4 $3 $0
        ${If} $0 == 0
          ; Release result
          ${BOOTCFG_ReleaseObject} $3
          ${BOOTCFG_SetPath} $services $basebcdobject $1 \
            "\g2ldr.mbr" $3 $0
          ${If} $0 == 0
            ; Release result
            ${BOOTCFG_ReleaseObject} $3
          ${EndIf}
        ${EndIf}
      ${EndIf}
      ; Release bcdobject
      ${BOOTCFG_ReleaseObject} $1
      ${If} $0 != 0
        StrCpy $1 $3
      ${Else}
        ; Append boot entry to list
        ${BOOTCFG_AppendBootEntry} $services $basebcdstore \
          $bcdstore $basebcdobject $2 $1 $0
        ${If} $0 == 0
          ; Release result
          ${BOOTCFG_ReleaseObject} $1
        ${EndIf}
      ${EndIf}
    ${EndIf}
  ${EndIf}

  ${If} $0 != 0
    IntFmt $2 "0x%08X" $0
    MessageBox MB_OK "$1: $2"
  ${EndIf}

  Pop $4
  Pop $3
  Pop $2
  Pop $1
  Pop $0
FunctionEnd

Function CreateBootEntry
  ${If} $windows_boot_method == bootmgr
    ReadRegStr $0 HKLM "${REGSTR_WIN32}" "bootmgr"
    ${If} $0 == ""
      ${BOOTCFG_CreateGUID} $2
      ${If} $2 != ""
        Push "$2"
!ifdef PXE
        ${If} $pxe_mode == "true"
          Push "$(pxe)"
        ${Else}
!endif ; PXE
          Push "$(d-i)"
!ifdef PXE
        ${EndIf} ; $pxe_mode == "true"
!endif ; PXE
        Call AddBootEntry
        WriteRegStr HKLM "${REGSTR_WIN32}" "bootmgr" "$2"
        Call CleanUp
      ${Else}
        MessageBox MB_OK|MB_ICONSTOP "$(error_bcdedit_extract_id)"
        Quit
      ${EndIf}
    ${Endif}
  ${Endif}
FunctionEnd

Section "Installer Loader"
; ******************************************************************************
; ***************************************** THIS IS WHERE THE REAL ACTION STARTS
; ******************************************************************************

  ; Up to this point, we haven't modified host system.  The first modification
  ; we want to do is preparing the Uninstaller (so that in case something went
  ; wrong, our half-install can be undone).
  WriteUninstaller "$INSTDIR\Uninstall.exe"
  WriteRegStr HKLM "${REGSTR_UNINST}" "DisplayName" $(program_name)
  WriteRegStr HKLM "${REGSTR_UNINST}" "UninstallString" "$INSTDIR\Uninstall.exe"
  ; Add more branding (see branding.nsi)
  WriteRegStr HKLM "${REGSTR_UNINST}" "Publisher" "${_COMPANY_NAME}"
  WriteRegStr HKLM "${REGSTR_UNINST}" "DisplayIcon" "$INSTDIR\Uninstall.exe"
  WriteRegStr HKLM "${REGSTR_UNINST}" "NoModify" "1"
  WriteRegStr HKLM "${REGSTR_UNINST}" "NoRepair" "1"
  WriteRegStr HKLM "${REGSTR_UNINST}" "DisplayVersion" "${VERSION_OPT}"
  WriteRegStr HKLM "${REGSTR_UNINST}" "ProductID" "${4DIGITS_DATE}"
  

!ifndef NOCD
  ${If} $kernel == "linux"
    ClearErrors
    StrCpy $0 "$EXEDIR\$linux"
    StrCpy $1 "$INSTDIR\linux"
    CopyFiles /FILESONLY "$0" "$1"
    IfErrors 0 +3
      MessageBox MB_OK|MB_ICONSTOP "$(error_copyfiles)"
      Quit
    StrCpy $0 "$EXEDIR\$initrd"
    StrCpy $1 "$INSTDIR\initrd.gz"
    CopyFiles /FILESONLY "$0" "$1"
    IfErrors 0 +3
      MessageBox MB_OK|MB_ICONSTOP "$(error_copyfiles)"
      Quit
  ${ElseIf} $kernel == "kfreebsd"
    ClearErrors
    StrCpy $0 "$EXEDIR\$kfreebsd"
    StrCpy $1 "$INSTDIR\kfreebsd.gz"
    CopyFiles /FILESONLY "$0" "$1"
    IfErrors 0 +3
      MessageBox MB_OK|MB_ICONSTOP "$(error_copyfiles)"
      Quit
    StrCpy $0 "$EXEDIR\$kfreebsd_module"
    StrCpy $1 "$INSTDIR\initrd.gz"
    CopyFiles /FILESONLY "$0" "$1"
    IfErrors 0 +3
      MessageBox MB_OK|MB_ICONSTOP "$(error_copyfiles)"
      Quit
  ${ElseIf} $kernel == "hurd"
    ClearErrors
    StrCpy $0 "$EXEDIR\$gnumach"
    StrCpy $1 "$INSTDIR\gnumach.gz"
    CopyFiles /FILESONLY "$0" "$1"
    IfErrors 0 +3
      MessageBox MB_OK|MB_ICONSTOP "$(error_copyfiles)"
      Quit
    StrCpy $0 "$EXEDIR\$ext2fs"
    StrCpy $1 "$INSTDIR\ext2fs.static"
    CopyFiles /FILESONLY "$0" "$1"
    IfErrors 0 +3
      MessageBox MB_OK|MB_ICONSTOP "$(error_copyfiles)"
      Quit
    StrCpy $0 "$EXEDIR\$initrd"
    StrCpy $1 "$INSTDIR\initrd.gz"
    CopyFiles /FILESONLY "$0" "$1"
    IfErrors 0 +3
      MessageBox MB_OK|MB_ICONSTOP "$(error_copyfiles)"
      Quit
    StrCpy $0 "$EXEDIR\$ld"
    StrCpy $1 "$INSTDIR\ld.so.1"
    CopyFiles /FILESONLY "$0" "$1"
    IfErrors 0 +3
      MessageBox MB_OK|MB_ICONSTOP "$(error_copyfiles)"
      Quit
  ${EndIf}
!else ;NOCD
!ifdef PXE
 ${If} $pxe_mode == "false"
!endif ;PXE
  ${If} $base_path_hashes != ""
    ; Download the Release and Release.gpg files
    Push "false"
    Push "false"
    Push "Release"
    Push "$PLUGINSDIR"
    Push "$base_url"
    Call Download
    Push "false"
    Push "false"
    Push "Release.gpg"
    Push "$PLUGINSDIR"
    Push "$base_url"
    Call Download

    ; Now check gpg validity of this
    File /oname=$PLUGINSDIR\gpgv.exe /usr/share/win32/gpgv.exe
    File /oname=$PLUGINSDIR\debian-archive-keyring.gpg /usr/share/keyrings/debian-archive-keyring.gpg
    File /oname=$PLUGINSDIR\debian-archive-removed-keys.gpg /usr/share/keyrings/debian-archive-removed-keys.gpg
    StrCpy $0 "Release"
    DetailPrint $(gpg_checking_release)
    nsExec::Exec '"$PLUGINSDIR\gpgv.exe" --keyring $PLUGINSDIR\debian-archive-removed-keys.gpg --keyring $PLUGINSDIR\debian-archive-keyring.gpg $PLUGINSDIR\Release.gpg $PLUGINSDIR\Release'
    Pop $0
    ${If} $0 != 0
      StrCpy $0 "Release"
      MessageBox MB_OK|MB_ICONSTOP "$(unsecure_release)"
      Quit
    ${EndIf}

    ; Get SHA256SUMS file SHA1SUM
    Push "$PLUGINSDIR\Release"
    Push "$base_path_hashesSHA256SUMS"
    Call Get_SHA256_ref
    ; SHA-256 is on the stack.
  ${Else}
    Push "false" ; Don't try to compare the SHA1SUM (daily images don't have that).
  ${EndIf}
  
  ; Download the SHA256SUMS file
  ; SHA-1 or "false" is on the stack
  Push "false"
  Push "SHA256SUMS"
  Push "$PLUGINSDIR"
  Push "$base_url$base_path_hashes"
  Call Download

  ${If} $kernel == "linux"
    Push "$PLUGINSDIR\SHA256SUMS"
    Push "$base_path_images/linux"
    Call Get_SHA256_ref
    ; SHA256 is on stack
    Push "false"
    Push "linux"
    Push "$INSTDIR"
    Push "$base_url$base_path_hashes$base_path_images"
    Call Download
    
    Push "$PLUGINSDIR\SHA256SUMS"
    Push "$base_path_images/initrd.gz"
    Call Get_SHA256_ref
    ; SHA256 is on stack
    Push "false"
    Push "initrd.gz"
    Push "$INSTDIR"
    Push "$base_url$base_path_hashes$base_path_images"
    Call Download
  ${ElseIf} $kernel == "kfreebsd"
    Push "$PLUGINSDIR\SHA256SUMS"
    Push "$base_path_images/kfreebsd.gz"
    Call Get_SHA256_ref
    ; SHA256 is on stack
    Push "false"
    Push "kfreebsd.gz"
    Push "$INSTDIR"
    Push "$base_url$base_path_hashes$base_path_images"
    Call Download

    Push "$PLUGINSDIR\SHA256SUMS"
    Push "$base_path_images/initrd.gz"
    Call Get_SHA256_ref
    ; SHA256 is on stack
    Push "false"
    Push "initrd.gz"
    Push "$INSTDIR"
    Push "$base_url$base_path_hashes$base_path_images"
    Call Download
  ${ElseIf} $kernel == "hurd"
    Push "$PLUGINSDIR\SHA256SUMS"
    Push "$base_path_images/gnumach.gz"
    Call Get_SHA256_ref
    ; SHA256 is on stack
    Push "false"
    Push "gnumach.gz"
    Push "$INSTDIR"
    Push "$base_url$base_path_hashes$base_path_images"
    Call Download

    Push "$PLUGINSDIR\SHA256SUMS"
    Push "$base_path_images/ext2fs.static"
    Call Get_SHA256_ref
    ; SHA256 is on stack
    Push "false"
    Push "ext2fs.static"
    Push "$INSTDIR"
    Push "$base_url$base_path_hashes$base_path_images"
    Call Download

    Push "$PLUGINSDIR\SHA256SUMS"
    Push "$base_path_images/initrd.gz"
    Call Get_SHA256_ref
    ; SHA256 is on stack
    Push "false"
    Push "initrd.gz"
    Push "$INSTDIR"
    Push "$base_url$base_path_hashes$base_path_images"
    Call Download

    Push "$PLUGINSDIR\SHA256SUMS"
    Push "$base_path_images/ld.so.1"
    Call Get_SHA256_ref
    ; SHA256 is on stack
    Push "false"
    Push "ld.so.1"
    Push "$INSTDIR"
    Push "$base_url$base_path_hashes$base_path_images"
    Call Download
  ${EndIf}
!ifdef PXE
 ${EndIf} ; $pxe_mode == "false"
!endif ;PXE
!endif

; We're about to write down our preseed line.  This would be a nice place
; to add post-install parameters.
  StrCpy $preseed_cmdline "$preseed_cmdline ---"

; ********************************************** preseed quietness
  ${If} $expert == false
    StrCpy $preseed_cmdline "$preseed_cmdline quiet"
  ${Endif}

; ********************************************** grub.cfg
  StrCpy $0 "$INSTDIR\grub.cfg"
  DetailPrint "$(generating)"
  FileOpen $0 $INSTDIR\grub.cfg w
!ifdef PXE
 ${If} $pxe_mode == "true"
    FileWrite $0 "\
linux16 /win32-loader/pxe.lkrn$\n\
boot$\n"
 ${Else}
!endif ;PXE
  ${If} $kernel == "linux"
    FileWrite $0 "\
linux	/win32-loader/linux $preseed_cmdline$\n\
initrd	/win32-loader/initrd.gz$\n\
boot$\n"
  ${ElseIf} $kernel == "kfreebsd"
    FileWrite $0 "\
kfreebsd	/win32-loader/kfreebsd.gz$\n\
kfreebsd_module	/win32-loader/initrd.gz type=mfs_root$\n\
set kFreeBSD.vfs.root.mountfrom=ufs:/dev/md0$\n\
set kFreeBSD.hw.ata.ata_dma=0   # needed for qemu hard disk # TODO: delete$\n\
set kFreeBSD.hw.ata.atapi_dma=0 # needed for qemu cd # TODO: 1$\n\
boot$\n"
  ${ElseIf} $kernel == "hurd"
    FileWrite $0 "\
multiboot		/win32-loader/gnumach.gz root=gunzip:device:rd0 $preseed_cmdline$\n\
module --nounzip	/win32-loader/initrd.gz initrd '$$(ramdisk-create)'$\n\
module 			/win32-loader/ext2fs.static ext2fs \$\n\
			--multiboot-command-line='$${kernel-command-line}' \$\n\
			--host-priv-port='$${host-port}' \$\n\
			--device-master-port='$${device-port}' \$\n\
			--exec-server-task='$${exec-task}' -T typed '$${root}' \$\n\
			'$$(task-create)' '$$(task-resume)'$\n\
module			/win32-loader/ld.so.1 exec /hurd/exec '$$(exec-task=task-create)'$\n\
boot$\n"
  ${EndIf}
!ifdef PXE
 ${EndIf} ; $pxe_mode == "true"
!endif ;PXE
  FileClose $0

!ifdef PXE
 ${If} $pxe_mode == "false"
!endif ; PXE
; ********************************************** cpio hack
  File /oname=$INSTDIR\cpio.exe /usr/share/win32/cpio.exe
  File /oname=$INSTDIR\gzip.exe /usr/share/win32/gzip.exe

  StrCpy $0 "$INSTDIR\initrd.gz"
  DetailPrint "$(appending_preseeding)"

  FileOpen $0 $INSTDIR\preseed.cfg w
  FileWrite $0 "$preseed_cfg$\n"
  FileClose $0

  ; cpio awkward CLI, meet Winf**k awkward CLI
  FileOpen $0 $INSTDIR\cpio_list w
  FileWrite $0 "preseed.cfg"
  FileClose $0

  ; IMPORTANT!!  All files accessed by this script must be in the same
  ; filesystem as the script itself, because cmd.exe/command.com gets
  ; confused when using absolute paths.  This is why $INSTDIR is used
  ; instead of $PLUGINSDIR.
  FileOpen $0 $INSTDIR\cpio.bat w
  FileWrite $0 "\
cpio.exe -o -H newc < cpio_list > newc_chunk$\r$\n\
attrib -r initrd.gz$\r$\n\
gzip.exe -1 < newc_chunk >> initrd.gz$\r$\n\
"
  FileClose $0
; TODO: FIX THIS FOR kFreeBSD
${If} $kernel == "linux"
  nsExec::Exec '"$INSTDIR\cpio.bat"'
  Pop $0
  ${If} $0 != 0
    StrCpy $0 "$INSTDIR\cpio.bat"
    MessageBox MB_OK|MB_ICONSTOP "$(error_exec)"
    Quit
  ${Endif}
${EndIf}
!ifdef PXE
 ${EndIf} ; $pxe_mode == "false"
!endif ; PXE

; ********************************************** Do bootloader last, because it's the most dangerous
  ${If} $windows_boot_method == ntldr
!ifdef NOCD
       File /oname=$c\g2ldr g2ldr
       File /oname=$c\g2ldr.mbr g2ldr.mbr
      !ifdef PXE
       ${If} $pxe_mode == "true"
          File /oname=$INSTDIR\pxe.lkrn pxe.lkrn
       ${EndIf} ; $pxe_mode == "true"
      !endif ; PXE
!else
    ClearErrors
    StrCpy $0 "$EXEDIR\$g2ldr"
    StrCpy $1 "$c\g2ldr"
    CopyFiles /FILESONLY "$0" "$1"
    IfErrors 0 +3
      MessageBox MB_OK|MB_ICONSTOP "$(error_copyfiles)"
      Quit
    StrCpy $0 "$EXEDIR\$g2ldr_mbr"
    StrCpy $1 "$c\g2ldr.mbr"
    CopyFiles /FILESONLY "$0" "$1"
    IfErrors 0 +3
      MessageBox MB_OK|MB_ICONSTOP "$(error_copyfiles)"
      Quit
!endif
    DetailPrint "$(registering_ntldr)"
    SetFileAttributes "$c\boot.ini" NORMAL
    SetFileAttributes "$c\boot.ini" SYSTEM|HIDDEN

    ; Sometimes timeout isn't set.  This may result in ntldr booting straight to
    ; Windows (bad) or straight to Debian-Installer (also bad)!  Force it to 30
    ; just in case. Store its eventual old value alongside
    ; Read the already defined timeout
    ReadIniStr $0 "$c\boot.ini" "boot loader" "timeout"
    IfErrors 0 no_boot_ini_timeout
       ClearErrors
       WriteIniStr "$c\boot.ini" "boot loader" "old_timeout_win32-loader" $0
    no_boot_ini_timeout:
    WriteIniStr "$c\boot.ini" "boot loader" "timeout" "30"
!ifdef PXE
   ${If} $pxe_mode == "true"
    StrCpy $1 "$(pxe)"
   ${Else}
!endif ; PXE
    StrCpy $1 "$(d-i)"
!ifdef PXE
   ${EndIf} ; $pxe_mode == "true"
!endif ; PXE
   System::Call "kernel32::WideCharToMultiByte(i 850, i 0, w r1, i -1, \
     m.r2, i${NSIS_MAX_STRLEN}, p 0, p 0) i.r0"
   WriteIniStr "$c\boot.ini" "operating systems" "$c\g2ldr.mbr" '"$2"'
  ${Endif}

  ${If} $windows_boot_method == direct
    File /oname=$INSTDIR\loadlin.exe loadlin.exe
    File /oname=$INSTDIR\loadlin.pif loadlin.pif
  ${Endif}

  ${If} $windows_boot_method == bootmgr
!ifdef NOCD
       File /oname=$c\g2ldr g2ldr
       File /oname=$c\g2ldr.mbr g2ldr.mbr
      !ifdef PXE
       ${If} $pxe_mode == "true"
          File /oname=$INSTDIR\pxe.lkrn pxe.lkrn
       ${EndIf} ; $pxe_mode == "true"
      !endif ; PXE
!else
    ClearErrors
    StrCpy $0 "$EXEDIR\$g2ldr"
    StrCpy $1 "$c\g2ldr"
    CopyFiles /FILESONLY "$0" "$1"
    IfErrors 0 +3
      MessageBox MB_OK|MB_ICONSTOP "$(error_copyfiles)"
      Quit
    StrCpy $0 "$EXEDIR\$g2ldr_mbr"
    StrCpy $1 "$c\g2ldr.mbr"
    CopyFiles /FILESONLY "$0" "$1"
    IfErrors 0 +3
      MessageBox MB_OK|MB_ICONSTOP "$(error_copyfiles)"
      Quit
!endif
    ${If} $bcdstore != ""
      Call CleanUp
    ${Else}
      DetailPrint "$(registering_bootmgr)"
    ${EndIf}
  ${Endif}

; ********************************************** Needed for systems with compressed NTFS
  DetailPrint "$(disabling_ntfs_compression)"
  nsExec::Exec '"compact" /u $c\g2ldr $c\g2ldr.mbr $INSTDIR\grub.cfg'
  ; in my tests, uncompressing $INSTDIR\grub.cfg wasn't necessary, but better be safe than sorry
  ${If} $kernel == "linux"
    nsExec::Exec '"compact" /u $INSTDIR\linux $INSTDIR\initrd.gz'
  ${ElseIf} $kernel == "kfreebsd"
    nsExec::Exec '"compact" /u $INSTDIR\kfreebsd.gz $INSTDIR\initrd.gz'
  ${ElseIf} $kernel == "hurd"
    nsExec::Exec '"compact" /u $INSTDIR\gnumach.gz $INSTDIR\ext2fs.static $INSTDIR\initrd.gz $INSTDIR\ld.so.1'
  ${EndIf}
!ifdef PXE
  ${If} $pxe_mode == "true"
    nsExec::Exec '"compact" /u $INSTDIR\pxe.lkrn'
  ${EndIf}
!endif ;PXE
SectionEnd
