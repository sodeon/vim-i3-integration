" Singleton guard
if exists('g:loaded_tmux_i3_integration') || &cp
  finish
endif
let g:loaded_tmux_i3_integration = 1

" Window navigation
function Focus(direction) 
    if a:direction == 'left'
        let vim_cmd = 'h'
    elseif a:direction == 'right'
        let vim_cmd = 'l'
    elseif a:direction == 'up'
        let vim_cmd = 'k'
    elseif a:direction == 'down'
        let vim_cmd = 'j'
    else
        return
    endif

    let oldw = winnr()
    silent exe 'wincmd ' . vim_cmd
    let neww = winnr()
    if oldw == neww
        call system("vim-tmux-i3-integration focus ".a:direction)
    elseif exists('$TMUX')
        call system("printf '\033]2;" . @% ."\033\\' > $TTY")
    endif
endfunction

" Window movement
function Move(direction)
    if a:direction == 'left'
        let vim_cmd = 'H'
    elseif a:direction == 'right'
        let vim_cmd = 'L'
    elseif a:direction == 'up'
        let vim_cmd = 'K'
    elseif a:direction == 'down'
        let vim_cmd = 'J'
    else
        return
    endif

    let old_layout = string(winlayout())
    silent exe 'wincmd ' . vim_cmd
    let new_layout = string(winlayout())
    if old_layout == new_layout
        call system("vim-tmux-i3-integration move ".a:direction)
    endif
endfunction

" Window resize
" @param orientation horizontal|vertical
" @param delta signed integer, "size in column"
function Resize(orientation, delta)
    " Find layout situation: if there are corresponding split for resize orientation
    let split = {'has_horizontal': 0, 'has_vertical': 0}
    call s:get_buf_split(winlayout(), split, win_getid())

    " If orientation is horizontal and there is no split on the left/right, delegate resize operation.
    " If orientation is vertical   and there is no split above/below      , delegate resize operation.
    if a:orientation == 'horizontal'
        if !split.has_vertical
            if a:delta > 0
                call system("vim-tmux-i3-integration resize grow width")
                return
            else
                call system("vim-tmux-i3-integration resize shrink width")
                return
            endif
        endif
    elseif a:orientation == 'vertical'
        if !split.has_horizontal
            if a:delta > 0
                call system("vim-tmux-i3-integration resize grow height")
                return
            else
                call system("vim-tmux-i3-integration resize shrink height")
                return
            endif
        endif
    else " If configured properly, should never enter this branch.
        return
    endif

    " There are corresponding split in current layout, resize vim splits
    if a:orientation == 'horizontal'
        if a:delta > 0
            let vim_cmd = '>'
        else
            let vim_cmd = '<'
        endif
    elseif a:orientation == 'vertical'
        if a:delta > 0
            let vim_cmd = '+'
        else
            let vim_cmd = '-'
        endif
    endif
    silent exe abs(a:delta).'wincmd '.vim_cmd
endfunction

" Tab navigation
function TabFocus(direction) 
    if a:direction == 'left'
        let vim_cmd = 'h'
    elseif a:direction == 'right'
        let vim_cmd = 'l'
    else
        return
    endif

    let oldw = tabpagenr()
    silent exe 'TWcmd tcm ' . vim_cmd
    let neww = tabpagenr()

    if !exists('$TMUX')
        return
    endif
    if oldw == neww
        if a:direction == 'left'
            call system("tmux previous-window")
        else
            call system("tmux next-window")
        endif
    else
        call system("printf '\033]2;" . @% ."\033\\' > $TTY")
    endif
endfunction

" Tab movement
function TabMove(direction) 
    if a:direction == 'left'
        let vim_cmd = 'h'
    elseif a:direction == 'right'
        let vim_cmd = 'l'
    else
        return
    endif

    let oldw = tabpagenr()
    silent exe 'TWcmd tmv ' . vim_cmd
    let neww = tabpagenr()

    if !exists('$TMUX')
        return
    endif
    if oldw == neww
        if a:direction == 'left'
            call system("tmux swap-window -t -1")
        else
            call system("tmux swap-window -t +1")
        endif
    endif
endfunction


"------------------------------------------------------------------------------
" Helper functions
"------------------------------------------------------------------------------
" Find if current window has adjacent vertical or horizontal split. This function is recursive.
" @param split, split content will be modified and is part of return value for split information
function s:get_buf_split(layout, split, winid)
    let node = string(a:layout[0]) " Workaround to [1, 2] == 'gg' comparison (vim does not allow list compared to string), find no way to detect if an variable is array. So convert to string.
    if node == "'leaf'"
        if a:layout[1] == a:winid
            return 1
        else
            return 0
        endif
    elseif node == "'row'"
        let val = s:get_buf_split(a:layout[1], a:split, a:winid)
        if val
            let a:split.has_vertical = 1
        endif
        return val
    elseif node == "'col'"
        let val = s:get_buf_split(a:layout[1], a:split, a:winid)
        if val
            let a:split.has_horizontal = 1
        endif
        return val
    endif
    for item in a:layout
        if s:get_buf_split(item, a:split, a:winid)
            return 1
        endif
    endfor
    return 0
endfunction
