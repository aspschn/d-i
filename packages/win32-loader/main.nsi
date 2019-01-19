; Debian-Installer Loader
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

; SetCompressor must _always_ be the first command
SetCompressor /SOLID lzma

!include l10n/templates/all.nsh

!include branding.nsi

; Needed to disable idiotic compatibility mode where Vista identifies itself
; as XP.  Otherwise useless (admin privilege is the default for installers).
RequestExecutionLevel admin

!include LogicLib.nsh
!include FileFunc.nsh
!include WinMessages.nsh
!include WinVer.nsh
!insertmacro GetRoot

!addplugindir plugins
!addplugindir plugins/cpuid
!addplugindir plugins/systeminfo

;--------------------------------

; Pages

Page custom ShowExpert ; expert.nsi
Page custom ShowRescue ; rescue.nsi
Page custom ShowKernel ; kernel.nsi
Page custom ShowGraphics ; graphics.nsi
!ifdef NOCD
Page custom ShowBranch ; download.nsi and branch.nsi
!endif
Page custom ShowCustom ; custom.nsi
Page instfiles CreateBootEntry

UninstPage uninstConfirm
UninstPage instfiles un.RemoveBootEntry

;--------------------------------
Var /GLOBAL c
!ifndef NOCD
Var /GLOBAL d
!endif
Var /GLOBAL preseed_cmdline
Var /GLOBAL preseed_cfg
Var /GLOBAL proxy
Var /GLOBAL arch
Var /GLOBAL services
Var /GLOBAL locator
Var /GLOBAL basebcdstore
Var /GLOBAL basebcdobject
Var /GLOBAL bcdstore
Var /GLOBAL target_distro

;--------------------------------
; Installer
!include onInit.nsi
!include expert.nsi
!include rescue.nsi
!include kernel.nsi
!include graphics.nsi
!ifdef NOCD
	!include download.nsi
	!include branch.nsi
!endif
!include custom.nsi
!include s_install.nsi
!include instSuccess.nsi
;--------------------------------
; Uninstaller
!include s_uninstall.nsi
