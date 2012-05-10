" File: nosyntaxwords.vim
" Author: Alexey Radkov
" Version: 0.1
" Description: find words that are not syntactically highlighted in current
"              buffer
" Usage:
"   Command :NextNoSyntaxWord to find next word that is not syntactically
"   highlighted.
"
"   Command :GetNoSyntaxWords to get list of words that are not syntactically
"   highlighted. The list is stored in buffer variable b:nosyntaxwords and it
"   can be shown again by issuing command
"
"       :echo b:nosyntaxwords
"
"   Due to difference between algorithms 'normal w' and 'expand("<cword>")'
"   that are used in implementation of the plugin, global variable
"   g:NswSkipSymbols was involved. This variable is a dictionary that contains
"   lists of special symbols for specified filetypes that are supposed to be
"   not syntactically highlighted for this filetype and must be skipped when
"   using 'normal w', otherwise they will be included in the list or,
"   even worse (if they do not belong to 'iskeyword' list), following them
"   words will be included in the list.
"
"   By default g:NswSkipSymbols has support for filetypes 'c', 'cpp',
"   'python', 'perl', 'vim' and 'tagbar', but if needed this can be extended
"   for using with other filetypes, default symbols for a supported filetype
"   can be changed as well. For example, to add support for filetype 'ruby'
"   put in your .vimrc lines
"
"       let g:NswSkipSymbols = {}
"       let g:NswSkipSymbols['ruby'] = ['(', ')']  " whatever else
"
"   Recommended mappings:
"
"       nmap <silent> ,vv  :echo synIDattr(synID(line("."), col("."), 1), "name")<CR>
"       nmap <silent> ,vn  :NextNoSyntaxWord<CR>
"       nmap <silent> ,vl  :GetNoSyntaxWords<CR>
"
"  (mapping ,vv is for showing syntax class of word under cursor and does not
"  refer directly to this plugin).


if !exists("g:NswSkipSymbols")
    let g:NswSkipSymbols = {}
endif

if !exists("g:NswSkipSymbols['c']")
    let g:NswSkipSymbols['c'] = [':', '?']
endif

if !exists("g:NswSkipSymbols['cpp']")
    let g:NswSkipSymbols['cpp'] = [':', '?']
endif

if !exists("g:NswSkipSymbols['python']")
    let g:NswSkipSymbols['python'] =
                \ ['(', ')', ':', '[', ']', '=', '+', '-', '*', '/', '<', '>',
                \  '!', ',', '.']
endif

if !exists("g:NswSkipSymbols['perl']")
    let g:NswSkipSymbols['perl'] =
                \ ['(', ')', ':', '[', ']', '=', '+', '-', '*', '/', '<', '>',
                \  '!', ',', '.', ';', '|', '&', '?', '\', '{', '}']
endif

if !exists("g:NswSkipSymbols['vim']")
    let g:NswSkipSymbols['vim'] =
                \ ['[', ']', '/', '\', '&', '!', '{', '}', '?']
endif

if !exists("g:NswSkipSymbols['tagbar']")
    let g:NswSkipSymbols['tagbar'] = [':', '~']
endif


fun! <SID>find_nosyntaxword(silent)
    let iseof = 0
    while 1
        normal w
        let trycnt = 0
        while 1
            normal yl
            exe "let skip_symb = exists(\"g:NswSkipSymbols['".&ft.
                        \ "']\") && index(g:NswSkipSymbols['".&ft.
                        \ "'], @\") >= 0"
            if empty(expand("<cword>")) || skip_symb
                if line(".") == line("$")
                    let trycnt += 1
                    if col(".") == col("$") || trycnt > 10
                        let iseof = 1
                        break
                    endif
                endif
                normal w
                continue
            endif
            break
        endwhile
        if iseof
            break
        endif
        while empty(expand("<cword>"))
            if line(".") == line("$") && col(".") == col("$")
                let iseof = 1
                break
            endif
            normal w
        endwhile
        if iseof
            break
        endif
        let iseof = line(".") == line("$") && col(".") == col("$") - 1
        let cur_type = synIDattr(synID(line("."), col("."), 1), "name")
        if empty(cur_type) || iseof
            break
        endif
    endwhile
    if iseof
        if !a:silent
            echo "Search finished: EOF reached"
        endif
        return 1
    endif
    return 0
endfun

fun! <SID>get_nosyntaxwords()
    let save_cursor = getpos('.')
    let save_winline = winline()
    normal gg
    let b:nosyntaxwords = []
    while 1
        let eof = <SID>find_nosyntaxword(1)
        if eof
            break
        endif
        let cur_type = synIDattr(synID(line("."), col("."), 1), "name")
        if empty(cur_type)
            let cword = expand("<cword>")
            if index(b:nosyntaxwords, cword) < 0
                call add(b:nosyntaxwords, expand("<cword>"))
            endif
        endif
    endwhile
    call setpos('.', save_cursor)
    let move = winline() - save_winline
    if move != 0
        let dir = move < 0 ? '' : ''
        exe "normal ".abs(move).dir
    endif
    echo "No syntax words:"
    call sort(b:nosyntaxwords)
    echo b:nosyntaxwords
endfun


command NextNoSyntaxWord call <SID>find_nosyntaxword(0)
command GetNoSyntaxWords call <SID>get_nosyntaxwords()

