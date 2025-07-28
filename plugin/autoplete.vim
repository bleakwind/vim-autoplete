" vim: set expandtab tabstop=4 softtabstop=4 shiftwidth=4: */
"
" +--------------------------------------------------------------------------+
" | $Id: autoplete.vim 2025-05-23 02:30:17 Bleakwind Exp $                   |
" +--------------------------------------------------------------------------+
" | Copyright (c) 2008-2025 Bleakwind(Rick Wu).                              |
" +--------------------------------------------------------------------------+
" | This source file is autoplete.vim.                                       |
" | This source file is release under BSD license.                           |
" +--------------------------------------------------------------------------+
" | Author: Bleakwind(Rick Wu) <bleakwind@qq.com>                            |
" +--------------------------------------------------------------------------+
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
let g:autoplete_useomni     = get(g:, 'autoplete_useomni',      1)
let g:autoplete_usedict     = get(g:, 'autoplete_usedict',      1)
let g:autoplete_usekeyword  = get(g:, 'autoplete_usekeyword',   1)
let g:autoplete_usebuffer   = get(g:, 'autoplete_usebuffer',    1)
let g:autoplete_usefile     = get(g:, 'autoplete_usefile',      1)

" dict path
let g:autoplete_dictpath    = get(g:, 'autoplete_dictpath',     expand('<sfile>:p:h:h').'/dict')

" ============================================================================
" autoplete detail
" g:autoplete_enabled = 1
" ============================================================================
if exists('g:autoplete_enabled') && g:autoplete_enabled == 1

    " --------------------------------------------------
    " autoplete#OperateComplete
    " --------------------------------------------------
    function! autoplete#OperateComplete(type, base) abort
        if a:type
            let l:line = getline('.')
            let l:colpos = col('.') - 1
            while l:colpos > 0 && l:line[l:colpos - 1] =~# '\k'
                let l:colpos -= 1
            endwhile
            return l:colpos
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
                if type(il) == type({}) && has_key(il, 'word')
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
            try
                let l:omni_comp = call(&omnifunc, [0, a:base])
                if type(l:omni_comp) == type([])
                    for il in l:omni_comp
                        if type(il) == type({}) && has_key(il, 'word')
                            let l:word = il.word
                            if l:word =~# '^'.a:base
                                call add(l:comp_list, { 'word': l:word[l:base_len:], 'abbr': l:word, 'menu': '[O] '.il.menu })
                            endif
                        endif
                    endfor
                endif
            catch
                " ignore error
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
                        call add(l:comp_list, { 'word': iw[l:base_len:], 'abbr': iw, 'menu': '[D] '.fnamemodify(il, ':t')})
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
        let l:line = getline('.')
        let l:colpos = col('.') - 1
        let l:start = l:colpos
        while l:start > 0 && l:line[l:start - 1] =~# '\k'
            let l:start -= 1
        endwhile
        let l:current_word = l:line[l:start:l:colpos - 1]

        " if base empty, use current
        let l:search_term = empty(a:base) ? l:current_word : a:base

        " search current buffer
        let l:saved_pos = getpos('.')
        let l:word_list = {}

        " search all buffer
        keepjumps call cursor(1, 1)
        while 1
            let [lnum, cnum] = searchpos('\<'.l:search_term.'\k\+', 'W')
            if lnum == 0 | break | endif

            let l:line = getline(lnum)
            let l:word = matchstr(l:line, '\<'.l:search_term.'\k\+', cnum - 1)
            if !empty(l:word) && l:word !=# l:search_term
                let l:word_list[l:word] = 1
            endif

            " move next
            keepjumps call cursor(lnum, cnum + 1)
        endwhile

        " recover cursor
        keepjumps call setpos('.', l:saved_pos)

        " convert to list
        for iw in keys(l:word_list)
            call add(l:comp_list, { 'word': iw[l:base_len:], 'abbr': iw, 'menu': '[K] '.l:menu_suffix })
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
                call add(l:comp_list, { 'word': l:word[l:base_len:], 'abbr': l:word, 'menu': '[B] buffer'})
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
                call add(l:comp_list, { 'word': iw[l:base_len:], 'abbr': iw, 'menu': '[F] file & dir'})
            endfor
        catch
            " ignore error
        endtry

        return l:comp_list
    endfunction

    " --------------------------------------------------
    " autoplete#TriggerNext
    " --------------------------------------------------
    function! autoplete#TriggerNext() abort
        if pumvisible()
            return "\<C-n>"
        endif

        " check space
        let l:line = getline('.')
        let l:colpos = col('.') - 1
        if l:colpos <= 0 || l:line[l:colpos - 1] =~# '\v\s\c'
            return "\<Tab>"
        endif

        " check inputkey
        if complete_check()
            return "\<Tab>"
        endif

        " trigger completion
        call complete(col('.'), autoplete#OperateComplete(0, matchstr(getline('.')[0:col('.')-2], '\k\+$')))

        " select first
        if pumvisible()
            return "\<C-n>"
        else
            return ''
        endif
    endfunction

    " --------------------------------------------------
    " autoplete#TriggerPrev
    " --------------------------------------------------
    function! autoplete#TriggerPrev() abort
        if pumvisible()
            return "\<C-p>"
        else
            return "\<S-Tab>"
        endif
    endfunction

    " --------------------------------------------------
    " option
    " --------------------------------------------------
    set completefunc=autoplete#OperateComplete

    " --------------------------------------------------
    " keymap
    " --------------------------------------------------
    inoremap <silent> <expr> <Tab> "\<C-r>=autoplete#TriggerNext()\<CR>"
    inoremap <silent> <expr> <S-Tab> "\<C-r>=autoplete#TriggerPrev()\<CR>"

endif

" ============================================================================
" Other
" ============================================================================
let &cpoptions = s:save_cpo
unlet s:save_cpo
