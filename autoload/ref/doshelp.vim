scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim

let s:source = {'name': 'doshelp'}

function! s:system(cmd, ...)
  if get(g:, 'ref_use_vimproc', 0) && exists(':VimProcBang')
    let res = vimproc#system(a:cmd)
  else
    let res = system(a:cmd)
  endif
  if &encoding != 'cp932'
    let res = iconv(res, 'cp932', &enc)
  endif
  return a:0 ? split(res, '\v\r\n|\r|\n') : res
endfunction

function! s:getCmdList() abort
  if exists('s:cmdlist')
    return copy(s:cmdlist)
  endif
  let s:cmdlist = []
  for line in s:system('cmd /c help', 1)
    if line[0] =~# '\v^\C[A-Z]'
      let pos = matchend(line, '\v[A-Z]+')
      call add(s:cmdlist, strpart(line, 0, pos))
    endif
  endfor
  return s:getCmdList()
endfunction
function! s:source.available() abort
  return has('win32') && executable('help')
endfunction
function! s:source.get_body(query) abort
  let cmds = split(a:query)
  let cmdname = get(cmds, 0,'')
  let q = matchstr(toupper(cmdname), '\v\C^[A-Z]+$')
  if index(s:getCmdList(), q) != -1
    if q ==# 'SC'
      let cmd = ''
    else
      if cmds[-1] ==# '/?'
        let cmd = printf('cmd /c %s',q . join(cmds[1:]))
      else
        let cmd = printf('cmd /c %s /?',q)
      endif
    endif
  else
    let cmd = printf('cmd /c help %s', q)
  endif
  return join(map(s:system(cmd, 1), 'substitute(v:val, ''\v\s+$'', '''', ''g'')'), "\n")
endfunction
function! s:source.get_keyword() abort
  return expand('<cword>')
endfunction
function! s:source.complete(query) abort
  let q = toupper(a:query)
  return filter(s:getCmdList(), 'stridx(v:val, q) == 0')
endfunction

function! ref#doshelp#define()
  return copy(s:source)
endfunction

call ref#register_detection('dosbatch', 'doshelp')

let &cpo = s:save_cpo
unlet s:save_cpo
