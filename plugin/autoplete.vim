"  vim: set expandtab tabstop=4 softtabstop=4 shiftwidth=4: */
"
"  +-------------------------------------------------------------------------+
"  | $Id: autoplete.vim 2026-03-22 13:48:04 Bleakwind Exp $                  |
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

let g:autoplete_usedefdict  = get(g:, 'autoplete_usedefdict',   1)
let g:autoplete_usecusdict  = get(g:, 'autoplete_usecusdict',   1)
let g:autoplete_useomni     = get(g:, 'autoplete_useomni',      1)
let g:autoplete_usekeyword  = get(g:, 'autoplete_usekeyword',   1)
let g:autoplete_usebuffer   = get(g:, 'autoplete_usebuffer',    1)
let g:autoplete_usefile     = get(g:, 'autoplete_usefile',      1)

let g:autoplete_insstate    = get(g:, 'autoplete_insstate',     1)
let g:autoplete_insdelay    = get(g:, 'autoplete_insdelay',     500)
let g:autoplete_insminchar  = get(g:, 'autoplete_insminchar',   2)
let g:autoplete_insftype    = get(g:, 'autoplete_insftype',     ['*'])

let g:autoplete_maxabbr     = get(g:, 'autoplete_maxabbr',      30)
let g:autoplete_maxmenu     = get(g:, 'autoplete_maxmenu',      80)
let g:autoplete_maxaddi     = get(g:, 'autoplete_maxaddi',      20)
let g:autoplete_cusdict     = get(g:, 'autoplete_cusdict',      '')

" plugin variable
let g:autoplete_defdict     = get(g:, 'autoplete_defdict',      expand('<sfile>:p:h:h').'/dict')
let g:autoplete_tabtimer    = 0
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
            let l:base_len = strdisplaywidth(a:base)

            " 1. defdict
            if g:autoplete_usedefdict
                let l:defdict_comp = autoplete#CompleteDefdict(a:base)
                call extend(l:comp_list, l:defdict_comp)
            endif

            " 2. cusdict
            if g:autoplete_usecusdict
                let l:cusdict_comp = autoplete#CompleteCusdict(a:base)
                call extend(l:comp_list, l:cusdict_comp)
            endif

            " 3. omni
            if g:autoplete_useomni
                let l:omni_comp = autoplete#CompleteOmni(a:base)
                call extend(l:comp_list, l:omni_comp)
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

            " for ic in l:comp_list
            "     echo printf(">>> word='%s' | abbr='%s' | menu='%s'", get(ic, 'word', ''), get(ic, 'abbr', ''), get(ic, 'menu', ''))
            " endfor
            " call getchar()

            " remove duplicates
            let l:comp_check = {}
            let l:comp_unique = []
            for ic in l:comp_list
                if type(ic) ==# type({}) && has_key(ic, 'indx')
                    if !has_key(l:comp_check, ic.indx)
                        let l:comp_check[ic.indx] = 1
                        call add(l:comp_unique, ic)
                    endif
                endif
            endfor
            return l:comp_unique
        endif
    endfunction

    " --------------------------------------------------
    " autoplete#FormatItem
    " --------------------------------------------------
    function! autoplete#FormatItem(word, menu, addi, info, len) abort
        let l:bld_indx = a:word
        let l:bld_word = a:word
        let l:bld_abbr = a:word
        let l:bld_menu = a:menu
        let l:bld_addi = a:addi

        if g:autoplete_maxabbr > 0 && strdisplaywidth(l:bld_abbr) > g:autoplete_maxabbr
            let l:bld_abbr = l:bld_abbr[0:g:autoplete_maxabbr-3] . '...'
        endif

        if g:autoplete_maxmenu > 0 && strdisplaywidth(l:bld_menu) > g:autoplete_maxmenu
            let l:bld_menu = l:bld_menu[0:g:autoplete_maxmenu-3] . '...'
        elseif g:autoplete_maxmenu > 0 && strdisplaywidth(l:bld_menu) < g:autoplete_maxmenu
            let l:bld_menu = l:bld_menu . repeat(' ', g:autoplete_maxmenu - strdisplaywidth(l:bld_menu) + 1)
        endif

        if g:autoplete_maxaddi > 0 && strdisplaywidth(l:bld_addi) > g:autoplete_maxaddi
            let l:bld_addi = l:bld_addi[0:g:autoplete_maxaddi-3] . '...'
        endif

        return {'indx':l:bld_indx, 'word':l:bld_word[a:len:], 'abbr':l:bld_abbr, 'menu':l:bld_menu . ' ' . l:bld_addi}
    endfunction

    " --------------------------------------------------
    " autoplete#CompleteDefdict
    " --------------------------------------------------
    function! autoplete#CompleteDefdict(base) abort
        let l:comp_list = []
        let l:file_type = &filetype
        let l:base_len = strdisplaywidth(a:base)

        " check filetype
        if empty(l:file_type)
            return l:comp_list
        endif

        " dict path list
        let l:dict_list = []
        if !empty(g:autoplete_defdict) && isdirectory(g:autoplete_defdict)
            let l:defdict = split(globpath(g:autoplete_defdict, l:file_type . '.dict'), '\n')
            call extend(l:dict_list, l:defdict)
            let l:defdict = split(globpath(g:autoplete_defdict, l:file_type . '_*.dict'), '\n')
            call extend(l:dict_list, l:defdict)
        endif

        " dict list
        for df in l:dict_list
            if filereadable(df)
                let l:word_list = readfile(df)
                for iw in l:word_list
                    if iw =~# '^' . a:base
                        let l:match = matchlist(iw, '\v([^(]*\()([^)]*)\)')

                        let l:word = !empty(l:match) ? l:match[1] : iw
                        let l:menu = !empty(l:match) ? '[D] ' . l:match[2] : '[D] ' . iw
                        let l:addi = '[DEF] ' . fnamemodify(df, ':t')
                        let l:info = iw
                        call add(l:comp_list, autoplete#FormatItem(l:word, l:menu, l:addi, l:info, l:base_len))
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
        let l:base_len = strdisplaywidth(a:base)

        " check filetype
        if empty(l:file_type)
            return l:comp_list
        endif

        " dict path list
        let l:dict_list = []
        if !empty(g:autoplete_cusdict) && isdirectory(g:autoplete_cusdict)
            let l:cusdict = split(globpath(g:autoplete_cusdict, l:file_type . '.dict'), '\n')
            call extend(l:dict_list, l:cusdict)
            let l:cusdict = split(globpath(g:autoplete_cusdict, l:file_type . '_*.dict'), '\n')
            call extend(l:dict_list, l:cusdict)
        endif

        " dict list
        for df in l:dict_list
            if filereadable(df)
                let l:word_list = readfile(df)
                for iw in l:word_list
                    if iw =~# '^' . a:base
                        let l:match = matchlist(iw, '\v([^(]*\()([^)]*)\)')

                        let l:word = !empty(l:match) ? l:match[1] : iw
                        let l:menu = !empty(l:match) ? '[D] ' . l:match[2] : '[D] ' . iw
                        let l:addi = '[CUS] ' . fnamemodify(df, ':t')
                        let l:info = iw
                        call add(l:comp_list, autoplete#FormatItem(l:word, l:menu, l:addi, l:info, l:base_len))
                    endif
                endfor
            endif
        endfor

        return l:comp_list
    endfunction

    " --------------------------------------------------
    " autoplete#CompleteOmni
    " --------------------------------------------------
    function! autoplete#CompleteOmni(base) abort
        let l:comp_list = []
        let l:file_type = &filetype
        let l:base_len = strdisplaywidth(a:base)

        if &omnifunc != ''
            let l:orig_view = winsaveview()
            let l:orig_pos = getpos('.')
            try
                let l:omni_comp = call(&omnifunc, [0, a:base])
                call winrestview(l:orig_view)
                call setpos('.', l:orig_pos)
                if type(l:omni_comp) ==# type([])
                    for iw in l:omni_comp
                        if type(iw) ==# type({}) && has_key(iw, 'word')
                            let l:word = iw.word
                            if a:base ==# '' || l:word =~# '^' . a:base
                                let l:word = l:word
                                let l:menu = has_key(iw, 'menu') ? '[O] ' . iw.menu : '[O]'
                                let l:addi = '[OMN] ' . &filetype
                                let l:info = has_key(iw, 'info') ? iw.info : l:word . l:menu
                                call add(l:comp_list, autoplete#FormatItem(l:word, l:menu, l:addi, l:info, l:base_len))
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
    " autoplete#CompleteKeyword
    " --------------------------------------------------
    function! autoplete#CompleteKeyword(base) abort
        let l:save_iskeyword = &iskeyword
        set iskeyword+=.,:,-

        " get env
        let l:comp_list = []
        let l:file_type = &filetype
        let l:curr_file = !empty(expand('%:t')) ? expand('%:t') : 'keyword'
        let l:base_len = strdisplaywidth(a:base)

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
            let [lnum, cnum] = searchpos('\<' . l:search_term . '\k\+', 'W')
            if lnum ==# 0 | break | endif

            let l:line = getline(lnum)
            let l:word = matchstr(l:line, '\<' . l:search_term . '\k\+', cnum - 1)
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
            let l:word = iw
            let l:menu = '[K] ' . iw
            let l:addi = '[KWD] ' . l:curr_file
            let l:info = iw
            call add(l:comp_list, autoplete#FormatItem(l:word, l:menu, l:addi, l:info, l:base_len))
        endfor

        let &iskeyword = l:save_iskeyword
        return l:comp_list
    endfunction

    " --------------------------------------------------
    " autoplete#CompleteBuffer
    " --------------------------------------------------
    function! autoplete#CompleteBuffer(base) abort
        let l:comp_list = []
        let l:file_type = &filetype
        let l:base_len = strdisplaywidth(a:base)

        " get list
        try
            let l:word_list = complete_check() ? [] : getcompletion(a:base, 'buffer')
            for iw in l:word_list
                let l:word = fnamemodify(iw, ':t')
                let l:menu = '[B] ' . fnamemodify(iw, ':t')
                let l:addi = '[BUF] ' . 'buffer'
                let l:info = iw
                call add(l:comp_list, autoplete#FormatItem(l:word, l:menu, l:addi, l:info, l:base_len))
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
        let l:base_len = strdisplaywidth(a:base)

        " get list
        try
            let l:word_list = complete_check() ? [] : getcompletion(a:base, 'file')
            for iw in l:word_list
                let l:word = iw
                let l:menu = '[B] ' . iw
                let l:addi = '[FLE] ' . 'file & dir'
                let l:info = iw
                call add(l:comp_list, autoplete#FormatItem(l:word, l:menu, l:addi, l:info, l:base_len))
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
    " autoplete#TriggerTabnext
    " --------------------------------------------------
    function! autoplete#TriggerTabnext() abort
        let l:save_iskeyword = &iskeyword
        set iskeyword+=.,:,-

        if pumvisible() || complete_check()
            let &iskeyword = l:save_iskeyword
            return "\<C-n>"
        endif

        let l:line = getline('.')
        let l:cpos = col('.') - 1
        if l:cpos <= 0 || l:line[l:cpos - 1] =~# '\v\s\c'
            let &iskeyword = l:save_iskeyword
            return "\<Tab>"
        endif

        if exists('g:autoplete_tabtimer') && g:autoplete_tabtimer > 0
            call timer_stop(g:autoplete_tabtimer)
        endif
        let g:autoplete_tabtimer = timer_start(0, {-> autoplete#TriggerTabrun()})

        let &iskeyword = l:save_iskeyword
        return ""
    endfunction

    " --------------------------------------------------
    " autoplete#TriggerTabnext
    " --------------------------------------------------
    function! autoplete#TriggerTabrun() abort
        let l:save_iskeyword = &iskeyword
        set iskeyword+=.,:,-

        if mode() ==# 'i' && !pumvisible() && !complete_check()
            let l:word = matchstr(getline('.')[0:col('.')-2], '\k\+$')
            if !empty(l:word)
                call complete(col('.'), autoplete#OperateComplete(0, l:word))
                call feedkeys("\<C-n>", 'n')
            endif
        endif
        let g:autoplete_tabtimer = 0

        let &iskeyword = l:save_iskeyword
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
    " autoplete#TriggerInsshow
    " --------------------------------------------------
    function! autoplete#TriggerInsshow() abort
        if g:autoplete_insftype ==# ['*'] || index(g:autoplete_insftype, &filetype) >= 0
            if exists('g:autoplete_instimer') && g:autoplete_instimer > 0
                call timer_stop(g:autoplete_instimer)
            endif
            let g:autoplete_instimer = timer_start(g:autoplete_insdelay, {-> autoplete#TriggerInsrun()})
        endif
        return ""
    endfunction

    " --------------------------------------------------
    " autoplete#TriggerInsrun
    " --------------------------------------------------
    function! autoplete#TriggerInsrun()
        let l:save_iskeyword = &iskeyword
        set iskeyword+=.,:,-

        if mode() ==# 'i' && !pumvisible() && !complete_check()
            let l:word = matchstr(getline('.')[0:col('.')-2], '\k\+$')
            if !empty(l:word) && strdisplaywidth(l:word) >= g:autoplete_insminchar
                call complete(col('.'), autoplete#OperateComplete(0, l:word))
            endif
        endif
        let g:autoplete_instimer = 0

        let &iskeyword = l:save_iskeyword
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
        if g:autoplete_insstate ==# 1
            autocmd TextChangedI * call autoplete#TriggerInsshow()
        endif
    augroup END

    " --------------------------------------------------
    " keymap
    " --------------------------------------------------
    inoremap <silent> <expr> <Tab> autoplete#TriggerTabnext()
    inoremap <silent> <expr> <S-Tab> autoplete#TriggerTabprev()
    inoremap <silent> <expr> <BS> autoplete#DeleteSelchar()

endif

" ============================================================================
" Other
" ============================================================================
let &cpoptions = s:save_cpo
unlet s:save_cpo

