"  vim: set expandtab tabstop=4 softtabstop=4 shiftwidth=4: */
"
"  +-------------------------------------------------------------------------+
"  | $Id: autoplete.vim 2026-03-16 12:31:32 Bleakwind Exp $                  |
"  +-------------------------------------------------------------------------+
"  | Copyright (c) 2008-2026 Bleakwind(Rick Wu).                             |
"  +-------------------------------------------------------------------------+
"  | This source file is autoplete.vim.                                      |
"  | This source file is release under BSD license.                          |
"  +-------------------------------------------------------------------------+
"  | Author: Bleakwind(Rick Wu) <bleakwind@qq.com>                           |
"  +-------------------------------------------------------------------------+
"

if exists('g:autoplete_plugin') || &compatible
    finish
endif
let g:autoplete_plugin = 1

scriptencoding utf-8

let s:save_cpo = &cpoptions
set cpoptions&vim

" ============================================================================
" autoplete setting
" ============================================================================
" public setting
let g:autoplete_enabled         = get(g:, 'autoplete_enabled',      0)

let g:autoplete_useomni         = get(g:, 'autoplete_useomni',      1)
let g:autoplete_usedict         = get(g:, 'autoplete_usedict',      1)
let g:autoplete_usekeyword      = get(g:, 'autoplete_usekeyword',   1)
let g:autoplete_usebuffer       = get(g:, 'autoplete_usebuffer',    1)
let g:autoplete_usefile         = get(g:, 'autoplete_usefile',      1)

let g:autoplete_insenabled      = get(g:, 'autoplete_insenabled',   1)
let g:autoplete_insdelay        = get(g:, 'autoplete_insdelay',     500)
let g:autoplete_insminchar      = get(g:, 'autoplete_insminchar',   2)
let g:autoplete_insftype        = get(g:, 'autoplete_insftype',     ['*'])

" dict path
let g:autoplete_dictpath        = get(g:, 'autoplete_dictpath',     expand('<sfile>:p:h:h').'/dict')

" plugin variable
let g:autoplete_insshow_timer   = 0

" ============================================================================
" autoplete detail
" g:autoplete_enabled = 1
" ============================================================================
if exists('g:autoplete_enabled') && g:autoplete_enabled ==# 1

    " --------------------------------------------------
    " autoplete#OperateComplete
    " --------------------------------------------------
    function! autoplete#OperateComplete(type, base) abort
        if a:type
            let l:line = getline('.')
            let l:cpos = col('.') - 1
            while l:cpos > 0 && l:line[l:cpos - 1] =~# '\k'
                let l:cpos -= 1
            endwhile
            return l:cpos
        else
            let l:comp_list = []
            let l:file_type = &filetype
            let l:base_len = len(a:base)

            " 1. omni
            if g:autoplete_useomni
                let l:omni_comp = autoplete#CompleteOmni(a:base)
                call extend(l:comp_list, l:omni_comp)
            endif

            " 2. dict
            if g:autoplete_usedict
                let l:dict_comp = autoplete#CompleteDict(a:base)
                call extend(l:comp_list, l:dict_comp)
            endif

            " 3. keyword
            if g:autoplete_usekeyword
                let l:keyword_comp = autoplete#CompleteKeyword(a:base)
                call extend(l:comp_list, l:keyword_comp)
            endif

            " 4. buffer
            if g:autoplete_usebuffer
                let l:buffer_comp = autoplete#CompleteBuffer(a:base)
                call extend(l:comp_list, l:buffer_comp)
            endif

            " 5. file
            if g:autoplete_usefile
                let l:file_comp = autoplete#CompleteFile(a:base)
                call extend(l:comp_list, l:file_comp)
            endif

            " echo getline('.')[0:col('.')-2]
            " call getchar()

            " for il in l:comp_list
            "     echo printf(">>> word='%s' | abbr='%s' | menu='%s'", get(il, 'word', ''), get(il, 'abbr', ''), get(il, 'menu', ''))
            " endfor
            " call getchar()

            " remove duplicates
            let l:comp_check = {}
            let l:comp_unique = []
            for il in l:comp_list
                if type(il) ==# type({}) && has_key(il, 'word')
                    if !has_key(l:comp_check, il.word)
                        let l:comp_check[il.word] = 1
                        call add(l:comp_unique, il)
                    endif
                endif
            endfor

            return l:comp_unique
        endif
    endfunction

    " --------------------------------------------------
    " autoplete#CompleteOmni
    " --------------------------------------------------
    function! autoplete#CompleteOmni(base) abort
        let l:comp_list = []
        let l:file_type = &filetype
        let l:base_len = len(a:base)

        if &omnifunc != ''
            let l:orig_view = winsaveview()
            let l:orig_pos = getpos('.')
            try
                let l:omni_comp = call(&omnifunc, [0, a:base])
                call winrestview(l:orig_view)
                call setpos('.', l:orig_pos)
                if type(l:omni_comp) ==# type([])
                    for il in l:omni_comp
                        if type(il) ==# type({}) && has_key(il, 'word')
                            let l:word = il.word
                            if a:base ==# '' || l:word =~# '^'.a:base
                                let l:menu = has_key(il, 'menu') ? il.menu : ''
                                call add(l:comp_list, {'word': l:word[l:base_len:], 'abbr': l:word, 'menu': '[O] '.l:menu})
                            endif
                        endif
                    endfor
                endif
            catch
                call winrestview(l:orig_view)
                call setpos('.', l:orig_pos)
            endtry
        endif

        return l:comp_list
    endfunction

    " --------------------------------------------------
    " autoplete#CompleteDict
    " --------------------------------------------------
    function! autoplete#CompleteDict(base) abort
        let l:comp_list = []
        let l:file_type = &filetype
        let l:base_len = len(a:base)

        " check filetype
        if empty(l:file_type)
            return l:comp_list
        endif

        " get list
        let l:dict_files = split(globpath(g:autoplete_dictpath, l:file_type.'*.dict'), '\n')
        for il in l:dict_files
            if filereadable(il)
                let l:word_list = readfile(il)
                for iw in l:word_list
                    if iw =~# '^'.a:base
                        call add(l:comp_list, {'word': iw[l:base_len:], 'abbr': iw, 'menu': '[D] '.fnamemodify(il, ':t')})
                    endif
                endfor
            endif
        endfor

        return l:comp_list
    endfunction

    " --------------------------------------------------
    " autoplete#CompleteKeyword
    " --------------------------------------------------
    function! autoplete#CompleteKeyword(base) abort
        let l:comp_list = []
        let l:file_type = &filetype
        let l:base_len = len(a:base)

        " get filename
        let l:current_file = expand('%:t')
        let l:menu_suffix = empty(l:current_file) ? 'keyword' : l:current_file

        " get input word
        let l:word = matchstr(getline('.')[0:col('.')-2], '\k\+$')

        " if base empty, use current
        let l:search_term = empty(a:base) ? l:word : a:base

        " save env
        let l:orig_cursor = getpos('.')
        let l:word_list = {}

        " search all buffer
        keepjumps call setpos('.', [0, 1, 1, 0])
        while 1
            let [lnum, cnum] = searchpos('\<'.l:search_term.'\k\+', 'W')
            if lnum ==# 0 | break | endif

            let l:line = getline(lnum)
            let l:word = matchstr(l:line, '\<'.l:search_term.'\k\+', cnum - 1)
            if !empty(l:word) && l:word !=# l:search_term
                let l:word_list[l:word] = 1
            endif

            " move next
            keepjumps call setpos('.', [0, lnum, cnum + 1, 0])
        endwhile

        " restore env
        keepjumps call setpos('.', l:orig_cursor)

        " convert to list
        for iw in keys(l:word_list)
            call add(l:comp_list, {'word': iw[l:base_len:], 'abbr': iw, 'menu': '[K] '.l:menu_suffix})
        endfor

        return l:comp_list
    endfunction

    " --------------------------------------------------
    " autoplete#CompleteBuffer
    " --------------------------------------------------
    function! autoplete#CompleteBuffer(base) abort
        let l:comp_list = []
        let l:file_type = &filetype
        let l:base_len = len(a:base)

        " get list
        try
            let l:word_list = complete_check() ? [] : getcompletion(a:base, 'buffer')
            for iw in l:word_list
                let l:word = fnamemodify(iw, ':t')
                call add(l:comp_list, {'word': l:word[l:base_len:], 'abbr': l:word, 'menu': '[B] buffer'})
            endfor
        catch
            " ignore error
        endtry

        return l:comp_list
    endfunction

    " --------------------------------------------------
    " autoplete#CompleteFile
    " --------------------------------------------------
    function! autoplete#CompleteFile(base) abort
        let l:comp_list = []
        let l:file_type = &filetype
        let l:base_len = len(a:base)

        " get list
        try
            let l:word_list = complete_check() ? [] : getcompletion(a:base, 'file')
            for iw in l:word_list
                call add(l:comp_list, {'word': iw[l:base_len:], 'abbr': iw, 'menu': '[F] file & dir'})
            endfor
        catch
            " ignore error
        endtry

        return l:comp_list
    endfunction

    " --------------------------------------------------
    " autoplete#DeleteSelchar
    " --------------------------------------------------
    function! autoplete#DeleteSelchar() abort
        if pumvisible()
            let l:selected = complete_info().selected
            if l:selected >= 0
                let l:items = complete_info().items
                if len(l:items) > l:selected
                    return "\<C-e>"
                endif
            endif
            return "\<C-e>\<BS>"
        else
            return "\<BS>"
        endif
    endfunction

    " --------------------------------------------------
    " autoplete#TriggerTabnext
    " --------------------------------------------------
    function! autoplete#TriggerTabnext() abort
        if exists('g:autoplete_insshow_timer') && g:autoplete_insshow_timer > 0
            call timer_stop(g:autoplete_insshow_timer)
        endif

        if pumvisible() || complete_check()
            return "\<C-n>"
        endif

        let l:line = getline('.')
        let l:cpos = col('.') - 1
        if l:cpos <= 0 || l:line[l:cpos - 1] =~# '\v\s\c'
            return "\<Tab>"
        endif

        let l:word = matchstr(getline('.')[0:col('.')-2], '\k\+$')
        if !empty(l:word)
            call complete(col('.'), autoplete#OperateComplete(0, l:word))
            if pumvisible()
                return "\<C-n>"
            endif
        endif
        return "\<Tab>"
    endfunction

    " --------------------------------------------------
    " autoplete#TriggerTabprev
    " --------------------------------------------------
    function! autoplete#TriggerTabprev() abort
        if pumvisible()
            return "\<C-p>"
        else
            return "\<S-Tab>"
        endif
    endfunction

    " --------------------------------------------------
    " autoplete#TriggerInsshow
    " --------------------------------------------------
    function! autoplete#TriggerInsshow() abort
        if g:autoplete_insftype ==# ['*'] || index(g:autoplete_insftype, &filetype) >= 0
            if exists('g:autoplete_insshow_timer') && g:autoplete_insshow_timer > 0
                call timer_stop(g:autoplete_insshow_timer)
            endif
            let g:autoplete_insshow_timer = timer_start(g:autoplete_insdelay, {-> autoplete#TriggerInsrun()})
        endif
    endfunction

    " --------------------------------------------------
    " autoplete#TriggerInsrun
    " --------------------------------------------------
    function! autoplete#TriggerInsrun()
        if mode() ==# 'i' && !pumvisible() && !complete_check()
            let l:word = matchstr(getline('.')[0:col('.')-2], '\k\+$')
            if !empty(l:word) && len(l:word) >= g:autoplete_insminchar
                call complete(col('.'), autoplete#OperateComplete(0, l:word))
            endif
        endif
        let g:autoplete_insshow_timer = 0
    endfunction

    " --------------------------------------------------
    " option
    " --------------------------------------------------
    set completefunc=autoplete#OperateComplete

    " --------------------------------------------------
    " autoplete_cmd_bas
    " --------------------------------------------------
    augroup autoplete_cmd_bas
        autocmd!
        if g:autoplete_insenabled ==# 1
            autocmd TextChangedI * call autoplete#TriggerInsshow()
        endif
    augroup END

    " --------------------------------------------------
    " keymap
    " --------------------------------------------------
    inoremap <silent> <expr> <Tab> g:autoplete_insshow_timer <= 0 ? "\<C-r>=autoplete#TriggerTabnext()\<CR>" : ""
    inoremap <silent> <expr> <S-Tab> "\<C-r>=autoplete#TriggerTabprev()\<CR>"
    inoremap <silent> <expr> <BS> "\<C-r>=autoplete#DeleteSelchar()\<CR>"

endif

" ============================================================================
" Other
" ============================================================================
let &cpoptions = s:save_cpo
unlet s:save_cpo

