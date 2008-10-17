let SessionLoad = 1
if &cp | set nocp | endif
let s:cpo_save=&cpo
set cpo&vim
map! <D-v> *
vmap <silent> ,x <Plug>VisualTraditional
vmap <silent> ,c <Plug>VisualTraditionalj
nmap <silent> ,x <Plug>Traditional
nmap <silent> ,c <Plug>Traditionalj
nmap ,tl :TlistToggle
nmap ,tn :tabn 
nmap ,tp :tabp 
vmap bl :!svn blame =expand("%:p")  | sed -n =line("'<") ,=line("'>") p 
nmap gx <Plug>NetrwBrowseX
nnoremap <silent> <Plug>NetrwBrowseX :call netrw#NetrwBrowseX(expand("<cWORD>"),0)
noremap <Plug>VisualFirstLine :call EnhancedCommentify('', 'first',   line("'<"), line("'>"))
noremap <Plug>VisualTraditional :call EnhancedCommentify('', 'guess',   line("'<"), line("'>"))
noremap <Plug>VisualDeComment :call EnhancedCommentify('', 'decomment',   line("'<"), line("'>"))
noremap <Plug>VisualComment :call EnhancedCommentify('', 'comment',   line("'<"), line("'>"))
noremap <Plug>FirstLine :call EnhancedCommentify('', 'first')
noremap <Plug>Traditional :call EnhancedCommentify('', 'guess')
noremap <Plug>DeComment :call EnhancedCommentify('', 'decomment')
noremap <Plug>Comment :call EnhancedCommentify('', 'comment')
noremap <F8> :cnext
noremap <F7> :cprevious
noremap <F6> :bnext
noremap <F5> :bprevious
noremap <F4> :next
noremap <F3> :previous
vmap <BS> "-d
vmap <D-x> "*d
vmap <D-c> "*y
vmap <D-v> "-d"*P
nmap <D-v> "*P
imap <silent> ,x <Plug>Traditional
imap <silent> ,c <Plug>Traditionalji
iabbr Therese Thérèse
iabbr #e andy@hexten.net
let &cpo=s:cpo_save
unlet s:cpo_save
set autowrite
set background=dark
set backspace=indent,eol,start
set expandtab
set fileencodings=ucs-bom,utf-8,default,latin1
set formatoptions=qro
set formatprg=perl\ -MText::Autoformat\ -e'autoformat'
set grepprg=ack\ -a
set helplang=en
set hlsearch
set incsearch
set isfname=@,48-57,/,.,-,_,+,,,#,$,%,~,=,:
set laststatus=2
set lazyredraw
set scrolloff=5
set shiftround
set shiftwidth=2
set showcmd
set showmatch
set statusline=%f%4(%m%)%r%h%w\ format:\ [%{&ff}]\ type:\ %y\ loc:\ [%4l,\ %3v,\ %3p%%]\ lines:\ [%L]\ buf:\ [%n]\ %a
set tabstop=2
set title
set visualbell
let s:so_save = &so | let s:siso_save = &siso | set so=0 siso=0
let v:this_session=expand("<sfile>:p")
silent only
cd ~/Works/Perl/Net-CIDR-Set/trunk
if expand('%') == '' && !&modified && line('$') <= 1 && getline(1) == ''
  let s:wipebuf = bufnr('%')
endif
set shortmess=aoO
badd +111 lib/Net/CIDR/Set.pm
badd +109 ~/Works/Perl/NotMine/Net-CIDR-Lite/Lite.pm
badd +3 t/all-range.t
badd +44 t/misc.t
badd +10 andy/pack.pl
badd +0 t/basic.t
badd +28 t/string.t
badd +1 lib/Net/CIDR/Set/IPv4.pm
badd +31 lib/Net/CIDR/Set/IPv6.pm
args lib/Net/CIDR/Set.pm
edit lib/Net/CIDR/Set.pm
set splitbelow splitright
wincmd _ | wincmd |
vsplit
1wincmd h
wincmd w
wincmd _ | wincmd |
split
1wincmd k
wincmd w
set nosplitbelow
set nosplitright
wincmd t
set winheight=1 winwidth=1
exe 'vert 1resize ' . ((&columns * 84 + 85) / 170)
exe '2resize ' . ((&lines * 22 + 23) / 47)
exe 'vert 2resize ' . ((&columns * 85 + 85) / 170)
exe '3resize ' . ((&lines * 22 + 23) / 47)
exe 'vert 3resize ' . ((&columns * 85 + 85) / 170)
argglobal
setlocal noautoindent
setlocal nobinary
setlocal bufhidden=
setlocal buflisted
setlocal buftype=
setlocal cindent
setlocal cinkeys=0{,0},0),:,!^F,o,O,e
setlocal cinoptions=
setlocal cinwords=if,else,while,do,for,switch
setlocal comments=:#
setlocal commentstring=#%s
setlocal complete=.,w,b,u,t,i
setlocal completefunc=
setlocal nocopyindent
setlocal nocursorcolumn
setlocal nocursorline
setlocal define=[^A-Za-z_]
setlocal dictionary=
setlocal nodiff
setlocal equalprg=
setlocal errorformat=
setlocal expandtab
if &filetype != 'perl'
setlocal filetype=perl
endif
setlocal foldcolumn=0
setlocal foldenable
setlocal foldexpr=0
setlocal foldignore=#
set foldlevel=100
setlocal foldlevel=100
setlocal foldmarker={{{,}}}
set foldmethod=indent
setlocal foldmethod=indent
setlocal foldminlines=1
setlocal foldnestmax=20
setlocal foldtext=foldtext()
setlocal formatexpr=
setlocal formatoptions=ocrq
setlocal formatlistpat=^\\s*\\d\\+[\\]:.)}\\t\ ]\\s*
setlocal grepprg=ack\ --type=perl
setlocal iminsert=0
setlocal imsearch=0
setlocal include=\\<\\(use\\|require\\)\\>
setlocal includeexpr=substitute(substitute(v:fname,'::','/','g'),'$','.pm','')
setlocal indentexpr=GetPerlIndent()
setlocal indentkeys=0{,0},:,0#,!^F,o,O,e,0=,0),0=or,0=and
setlocal noinfercase
setlocal iskeyword=@,48-57,_,192-255,:
setlocal keywordprg=perldoc\ -f
setlocal nolinebreak
setlocal nolisp
setlocal nolist
setlocal makeprg=
setlocal matchpairs=(:),{:},[:]
setlocal modeline
setlocal modifiable
setlocal nrformats=octal,hex
setlocal nonumber
setlocal numberwidth=4
setlocal omnifunc=
setlocal path=/alt/local/lib/perl5/5.10.0/darwin-thread-multi-2level,/alt/local/lib/perl5/5.10.0,/alt/local/lib/perl5/site_perl/5.10.0/darwin-thread-multi-2level,/alt/local/lib/perl5/site_perl/5.10.0,,
setlocal nopreserveindent
setlocal nopreviewwindow
setlocal quoteescape=\\
setlocal noreadonly
setlocal noscrollbind
setlocal shiftwidth=2
setlocal noshortname
setlocal nosmartindent
setlocal softtabstop=0
setlocal nospell
setlocal spellcapcheck=[.?!]\\_[\\])'\"\	\ ]\\+
setlocal spellfile=
setlocal spelllang=en
setlocal statusline=
setlocal suffixesadd=
setlocal swapfile
setlocal synmaxcol=3000
if &syntax != 'perl'
setlocal syntax=perl
endif
setlocal tabstop=2
setlocal tags=./tags,./perltags,tags,perltags,~/.vim/perltags
setlocal textwidth=72
setlocal thesaurus=
setlocal nowinfixheight
setlocal nowinfixwidth
setlocal wrap
setlocal wrapmargin=0
62
normal zo
62
normal zo
117
normal zo
117
normal zo
167
normal zo
170
normal zo
172
normal zo
170
normal zo
167
normal zo
let s:l = 115 - ((6 * winheight(0) + 22) / 45)
if s:l < 1 | let s:l = 1 | endif
exe s:l
normal! zt
115
normal! 0
wincmd w
argglobal
edit lib/Net/CIDR/Set/IPv6.pm
setlocal noautoindent
setlocal nobinary
setlocal bufhidden=
setlocal buflisted
setlocal buftype=
setlocal cindent
setlocal cinkeys=0{,0},0),:,!^F,o,O,e
setlocal cinoptions=
setlocal cinwords=if,else,while,do,for,switch
setlocal comments=:#
setlocal commentstring=#%s
setlocal complete=.,w,b,u,t,i
setlocal completefunc=
setlocal nocopyindent
setlocal nocursorcolumn
setlocal nocursorline
setlocal define=[^A-Za-z_]
setlocal dictionary=
setlocal nodiff
setlocal equalprg=
setlocal errorformat=
setlocal expandtab
if &filetype != 'perl'
setlocal filetype=perl
endif
setlocal foldcolumn=0
setlocal foldenable
setlocal foldexpr=0
setlocal foldignore=#
set foldlevel=100
setlocal foldlevel=100
setlocal foldmarker={{{,}}}
set foldmethod=indent
setlocal foldmethod=indent
setlocal foldminlines=1
setlocal foldnestmax=20
setlocal foldtext=foldtext()
setlocal formatexpr=
setlocal formatoptions=ocrq
setlocal formatlistpat=^\\s*\\d\\+[\\]:.)}\\t\ ]\\s*
setlocal grepprg=ack\ --type=perl
setlocal iminsert=0
setlocal imsearch=0
setlocal include=\\<\\(use\\|require\\)\\>
setlocal includeexpr=substitute(substitute(v:fname,'::','/','g'),'$','.pm','')
setlocal indentexpr=GetPerlIndent()
setlocal indentkeys=0{,0},:,0#,!^F,o,O,e,0=,0),0=or,0=and
setlocal noinfercase
setlocal iskeyword=@,48-57,_,192-255,:
setlocal keywordprg=perldoc\ -f
setlocal nolinebreak
setlocal nolisp
setlocal nolist
setlocal makeprg=
setlocal matchpairs=(:),{:},[:]
setlocal modeline
setlocal modifiable
setlocal nrformats=octal,hex
setlocal nonumber
setlocal numberwidth=4
setlocal omnifunc=
setlocal path=/alt/local/lib/perl5/5.10.0/darwin-thread-multi-2level,/alt/local/lib/perl5/5.10.0,/alt/local/lib/perl5/site_perl/5.10.0/darwin-thread-multi-2level,/alt/local/lib/perl5/site_perl/5.10.0,,
setlocal nopreserveindent
setlocal nopreviewwindow
setlocal quoteescape=\\
setlocal noreadonly
setlocal noscrollbind
setlocal shiftwidth=2
setlocal noshortname
setlocal nosmartindent
setlocal softtabstop=0
setlocal nospell
setlocal spellcapcheck=[.?!]\\_[\\])'\"\	\ ]\\+
setlocal spellfile=
setlocal spelllang=en
setlocal statusline=
setlocal suffixesadd=
setlocal swapfile
setlocal synmaxcol=3000
if &syntax != 'perl'
setlocal syntax=perl
endif
setlocal tabstop=2
setlocal tags=./tags,./perltags,tags,perltags,~/.vim/perltags
setlocal textwidth=72
setlocal thesaurus=
setlocal nowinfixheight
setlocal nowinfixwidth
setlocal wrap
setlocal wrapmargin=0
let s:l = 37 - ((10 * winheight(0) + 11) / 22)
if s:l < 1 | let s:l = 1 | endif
exe s:l
normal! zt
37
normal! 015l
lcd ~/Works/Perl/Net-CIDR-Set/trunk
wincmd w
argglobal
edit ~/Works/Perl/Net-CIDR-Set/trunk/lib/Net/CIDR/Set/IPv4.pm
setlocal noautoindent
setlocal nobinary
setlocal bufhidden=
setlocal buflisted
setlocal buftype=
setlocal nocindent
setlocal cinkeys=0{,0},0),:,!^F,o,O,e
setlocal cinoptions=
setlocal cinwords=if,else,while,do,for,switch
setlocal comments=
setlocal commentstring=#%s
setlocal complete=.,w,b,u,t,i
setlocal completefunc=
setlocal nocopyindent
setlocal nocursorcolumn
setlocal nocursorline
setlocal define=[^A-Za-z_]
setlocal dictionary=
setlocal nodiff
setlocal equalprg=
setlocal errorformat=
setlocal expandtab
if &filetype != 'perl'
setlocal filetype=perl
endif
setlocal foldcolumn=0
setlocal foldenable
setlocal foldexpr=0
setlocal foldignore=#
set foldlevel=100
setlocal foldlevel=100
setlocal foldmarker={{{,}}}
set foldmethod=indent
setlocal foldmethod=indent
setlocal foldminlines=1
setlocal foldnestmax=20
setlocal foldtext=foldtext()
setlocal formatexpr=
setlocal formatoptions=nroql2
setlocal formatlistpat=^\\s*\\d\\+[\\]:.)}\\t\ ]\\s*
setlocal grepprg=ack\ --type=perl
setlocal iminsert=0
setlocal imsearch=0
setlocal include=\\<\\(use\\|require\\)\\>
setlocal includeexpr=substitute(substitute(v:fname,'::','/','g'),'$','.pm','')
setlocal indentexpr=GetPerlIndent()
setlocal indentkeys=0{,0},:,0#,!^F,o,O,e,0=,0),0=or,0=and
setlocal noinfercase
setlocal iskeyword=@,48-57,_,192-255,:
setlocal keywordprg=perldoc\ -f
setlocal nolinebreak
setlocal nolisp
setlocal nolist
setlocal makeprg=
setlocal matchpairs=(:),{:},[:]
setlocal modeline
setlocal modifiable
setlocal nrformats=octal,hex
setlocal nonumber
setlocal numberwidth=4
setlocal omnifunc=
setlocal path=/alt/local/lib/perl5/5.10.0/darwin-thread-multi-2level,/alt/local/lib/perl5/5.10.0,/alt/local/lib/perl5/site_perl/5.10.0/darwin-thread-multi-2level,/alt/local/lib/perl5/site_perl/5.10.0,,
setlocal nopreserveindent
setlocal nopreviewwindow
setlocal quoteescape=\\
setlocal noreadonly
setlocal noscrollbind
setlocal shiftwidth=2
setlocal noshortname
setlocal nosmartindent
setlocal softtabstop=0
setlocal nospell
setlocal spellcapcheck=[.?!]\\_[\\])'\"\	\ ]\\+
setlocal spellfile=
setlocal spelllang=en
setlocal statusline=
setlocal suffixesadd=
setlocal swapfile
setlocal synmaxcol=3000
if &syntax != 'perl'
setlocal syntax=perl
endif
setlocal tabstop=2
setlocal tags=./tags,./perltags,tags,perltags,~/.vim/perltags
setlocal textwidth=0
setlocal thesaurus=
setlocal nowinfixheight
setlocal nowinfixwidth
setlocal wrap
setlocal wrapmargin=0
let s:l = 37 - ((16 * winheight(0) + 11) / 22)
if s:l < 1 | let s:l = 1 | endif
exe s:l
normal! zt
37
normal! 014l
wincmd w
exe 'vert 1resize ' . ((&columns * 84 + 85) / 170)
exe '2resize ' . ((&lines * 22 + 23) / 47)
exe 'vert 2resize ' . ((&columns * 85 + 85) / 170)
exe '3resize ' . ((&lines * 22 + 23) / 47)
exe 'vert 3resize ' . ((&columns * 85 + 85) / 170)
tabnext 1
if exists('s:wipebuf')
  silent exe 'bwipe ' . s:wipebuf
endif
unlet! s:wipebuf
set winheight=1 winwidth=20 shortmess=filnxtToO
let s:sx = expand("<sfile>:p:r")."x.vim"
if file_readable(s:sx)
  exe "source " . s:sx
endif
let &so = s:so_save | let &siso = s:siso_save
doautoall SessionLoadPost
unlet SessionLoad
" vim: set ft=vim :
