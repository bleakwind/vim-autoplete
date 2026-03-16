# vim-autoplete

## A lightweight automatic completion plugin for vim...
vim-autoplete is a lightweight auto-completion plugin for Vim that provides multiple completion sources including:
- Omni completion
- Dict completion
- Keyword completion
- Buffer completion
- File completion

## Features
- Multiple configurable completion sources
- Smart completion triggering
- Automatic duplicate removal
- Lightweight implementation with no external dependencies
- Extensible dictionary system

## Screenshot
![Autoplete Screenshot](https://github.com/bleakwind/vim-autoplete/blob/main/vim-autoplete.png)

## Requirements
Recommended Vim 8.1+

## Installation
```vim
" Using Vundle
Plugin 'bleakwind/vim-autoplete'
```

And Run:
```vim
:PluginInstall
```

## Configuration
Add these to your `.vimrc`:
```vim
" Set 1 enable autoplete (default: 0)
let g:autoplete_enabled = 1
" enable/disable omni (default: 1)
let g:autoplete_useomni = 1
" enable/disable dict (default: 1)
let g:autoplete_usedict = 1
" enable/disable keyword (default: 1)
let g:autoplete_usekeyword = 1
" enable/disable buffer (default: 1)
let g:autoplete_usebuffer = 1
" enable/disable file (default: 1)
let g:autoplete_usefile = 1
" Enable auto-completion while typing (default: 1)
let g:autoplete_insenabled = 1
" Delay in milliseconds before showing completions while typing (default: 500)
let g:autoplete_insdelay   = 500
" Minimum number of characters typed before triggering completion (default: 2)
let g:autoplete_insminchar = 2
" File types to enable auto-completion for (* for all)
let g:autoplete_insftype   = ['*']
```

## Usage
- In insert mode, type part of a word then press `<Tab>` to trigger completion
- Navigate completion menu with `<Tab>` and `<S-Tab>`
- Press `<Enter>` to select current completion

## License
BSD 2-Clause - See LICENSE file

