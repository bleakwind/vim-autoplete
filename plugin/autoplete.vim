"  vim: set expandtab tabstop=4 softtabstop=4 shiftwidth=4: */
"
"  +-------------------------------------------------------------------------+
"  | $Id: autoplete.vim 2026-03-21 12:26:47 Bleakwind Exp $                  |
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
let g:autoplete_enabled     = get(g:, 'autoplete_enabled',      0)
let g:autoplete_trigtype    = get(g:, 'autoplete_trigtype',     'ins')

let g:autoplete_useomni     = get(g:, 'autoplete_useomni',      1)
let g:autoplete_usedefdict  = get(g:, 'autoplete_usedefdict',   1)
let g:autoplete_usecusdict  = get(g:, 'autoplete_usecusdict',   1)
let g:autoplete_usekeyword  = get(g:, 'autoplete_usekeyword',   1)
let g:autoplete_usebuffer   = get(g:, 'autoplete_usebuffer',    1)
let g:autoplete_usefile     = get(g:, 'autoplete_usefile',      1)

let g:autoplete_insdelay    = get(g:, 'autoplete_insdelay',     500)
let g:autoplete_insminchar  = get(g:, 'autoplete_insminchar',   2)
let g:autoplete_insftype    = get(g:, 'autoplete_insftype',     ['*'])

let g:autoplete_cusdict     = get(g:, 'autoplete_cusdict',      '')

" plugin variable
let g:autoplete_defdict     = get(g:, 'autoplete_defdict',      expand('<sfile>:p:h:h').'/dict')
let g:autoplete_instimer    = 0

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

            " 2. defdict
            if g:autoplete_usedefdict
                let l:defdict_comp = autoplete#CompleteDefdict(a:base)
                call extend(l:comp_list, l:defdict_comp)
            endif

            " 3. cusdict
            if g:autoplete_usecusdict
                let l:cusdict_comp = autoplete#CompleteCusdict(a:base)
                call extend(l:comp_list, l:cusdict_comp)
            endif

            " 4. keyword
            if g:autoplete_usekeyword
                let l:keyword_comp = autoplete#CompleteKeyword(a:base)
                call extend(l:comp_list, l:keyword_comp)
            endif

            " 5. buffer
            if g:autoplete_usebuffer
                let l:buffer_comp = autoplete#CompleteBuffer(a:base)
                call extend(l:comp_list, l:buffer_comp)
            endif

            " 6. file
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
    " autoplete#CompleteDefdict
    " --------------------------------------------------
    function! autoplete#CompleteDefdict(base) abort
        let l:comp_list = []
        let l:file_type = &filetype
        let l:base_len = len(a:base)

        " check filetype
        if empty(l:file_type)
            return l:comp_list
        endif

        " dict path list
        let l:dict_list = []
        if !empty(g:autoplete_defdict) && isdirectory(g:autoplete_defdict)
            let l:defdict = split(globpath(g:autoplete_defdict, l:file_type.'.dict'), '\n')
            call extend(l:dict_list, l:defdict)
            let l:defdict = split(globpath(g:autoplete_defdict, l:file_type.'_*.dict'), '\n')
            call extend(l:dict_list, l:defdict)
        endif

        " dict list
        for df in l:dict_list
            if filereadable(df)
                let l:word_list = readfile(df)
                for iw in l:word_list
                    if iw =~# '^'.a:base
                        call add(l:comp_list, {'word': iw[l:base_len:], 'abbr': iw, 'menu': '[D] default - '.fnamemodify(df, ':t')})
                    endif
                endfor
            endif
        endfor

        return l:comp_list
    endfunction

    " --------------------------------------------------
    " autoplete#CompleteCusdict
    " --------------------------------------------------
    function! autoplete#CompleteCusdict(base) abort
        let l:comp_list = []
        let l:file_type = &filetype
        let l:base_len = len(a:base)

        " check filetype
        if empty(l:file_type)
            return l:comp_list
        endif

        " dict path list
        let l:dict_list = []
        if !empty(g:autoplete_cusdict) && isdirectory(g:autoplete_cusdict)
            let l:cusdict = split(globpath(g:autoplete_cusdict, l:file_type.'.dict'), '\n')
            call extend(l:dict_list, l:cusdict)
            let l:cusdict = split(globpath(g:autoplete_cusdict, l:file_type.'_*.dict'), '\n')
            call extend(l:dict_list, l:cusdict)
        endif

        " dict list
        for df in l:dict_list
            if filereadable(df)
                let l:word_list = readfile(df)
                for iw in l:word_list
                    if iw =~# '^'.a:base
                        call add(l:comp_list, {'word': iw[l:base_len:], 'abbr': iw, 'menu': '[D] custom - '.fnamemodify(df, ':t')})
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
        let l:save_iskeyword = &iskeyword
        set iskeyword+=.,:,-

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

        let &iskeyword = l:save_iskeyword
        unlet l:save_iskeyword

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
    " autoplete#TriggerTabnext
    " --------------------------------------------------
    function! autoplete#TriggerTabnext() abort
        let l:save_iskeyword = &iskeyword
        set iskeyword+=.,:,-

        if pumvisible() || complete_check()
            return "\<C-n>"
        endif

        if g:autoplete_trigtype ==# 'tab'
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
        endif

        let &iskeyword = l:save_iskeyword
        unlet l:save_iskeyword

        return "\<Tab>"
    endfunction

    " --------------------------------------------------
    " autoplete#TriggerTabprev
    " --------------------------------------------------
    function! autoplete#TriggerTabprev() abort
        if pumvisible() || complete_check()
            return "\<C-p>"
        endif
        return "\<S-Tab>"
    endfunction

    " --------------------------------------------------
    " autoplete#DeleteSelchar
    " --------------------------------------------------
    function! autoplete#DeleteSelchar() abort
        if pumvisible() || complete_check()
            let l:selected = complete_info().selected
            if l:selected >= 0
                let l:items = complete_info().items
                if len(l:items) > l:selected
                    return "\<C-e>"
                endif
            endif
            return "\<C-e>\<BS>"
        endif
        return "\<BS>"
    endfunction

    " --------------------------------------------------
    " autoplete#TriggerInsshow
    " --------------------------------------------------
    function! autoplete#TriggerInsshow() abort
        if g:autoplete_insftype ==# ['*'] || index(g:autoplete_insftype, &filetype) >= 0
            if exists('g:autoplete_instimer') && g:autoplete_instimer > 0
                call timer_stop(g:autoplete_instimer)
            endif
            let g:autoplete_instimer = timer_start(g:autoplete_insdelay, {-> autoplete#TriggerInsrun()})
        endif
    endfunction

    " --------------------------------------------------
    " autoplete#TriggerInsrun
    " --------------------------------------------------
    function! autoplete#TriggerInsrun()
        let l:save_iskeyword = &iskeyword
        set iskeyword+=.,:,-

        if mode() ==# 'i' && !pumvisible() && !complete_check()
            let l:word = matchstr(getline('.')[0:col('.')-2], '\k\+$')
            if !empty(l:word) && len(l:word) >= g:autoplete_insminchar
                call complete(col('.'), autoplete#OperateComplete(0, l:word))
            endif
        endif
        let g:autoplete_instimer = 0

        let &iskeyword = l:save_iskeyword
        unlet l:save_iskeyword
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
        if g:autoplete_trigtype ==# 'ins'
            autocmd TextChangedI * call autoplete#TriggerInsshow()
        endif
    augroup END

    " --------------------------------------------------
    " keymap
    " --------------------------------------------------
    inoremap <silent> <expr> <Tab> "\<C-r>=autoplete#TriggerTabnext()\<CR>"
    inoremap <silent> <expr> <S-Tab> "\<C-r>=autoplete#TriggerTabprev()\<CR>"
    inoremap <silent> <expr> <BS> "\<C-r>=autoplete#DeleteSelchar()\<CR>"

endif

" ============================================================================
" Other
" ============================================================================
let &cpoptions = s:save_cpo
unlet s:save_cpo

