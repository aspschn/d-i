" Vim syntax file
" Language:	Debian di-netboot-assistant's  di-sources.list
" Maintainer:	Frank Lin PIAT <fpiat@klabs.be>
" Last Change:	2008/11/15
" URL: http://wiki.debian.org/DebianInstaller/NetbootAssistant
" $Revision: 1.1 $

" this is a very simple syntax file, based on Matthijs Mohlmann's debsources.vim

" Standard syntax initialization
if version < 600
  syntax clear
elseif exists("b:current_syntax")
  finish
endif

" case sensitive
syn case match

" Architectures that support netbooting
" all arch, including historical:
"syn match diSourcesArchs        /\(alpha\|amd64\|arm\(64\|el\|hf\|\)\|hppa\|kfreebsd-\(i386\|amd64\)\|i386\|ia64\|lpia\|mips\(\|el\)\|power\(pc\|pcel\)\|sparc\(\|32\|64\)\)/
" current Ones
syn match diSourcesArchs        /\(amd64\|i386\|arm64\)/

" Architectures that don't support netbooting, and other forbiden characters
syn match diSourcesNoNetbootarch  /\(m68k\|s390\|s390x\)/

" Match comments
syn match diSourcesComment        /#.*/

" Match uri's
syn match diSourcesUri            +\(http://\|ftp://\|[rs]sh://\|debtorrent://\|\(cdrom\|copy\|file\):\)[^' 	<>"]\++
syn match diSourcesDistrKeyword   +\([[:alnum:]_./]*\)\(sarge\|etch\|lenny\|squeeze\|wheezy\|\(old\)\=stable\|testing\|unstable\|daily\|sid\|experimental\|dapper\|hardy\|karmic\|lucid\|maverick\|natty\)\([-[:alnum:]_./]*\)+

" Associate our matches and regions with pretty colours
hi def link diSourcesArchs           Statement
hi def link diSourcesNoNetbootarch   Error
hi def link diSourcesDistrKeyword    Type
hi def link diSourcesComment         Comment
hi def link diSourcesUri             Constant

let b:current_syntax = "disources"

" vim: ts=8
