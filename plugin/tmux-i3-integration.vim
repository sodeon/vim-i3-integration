" Singleton guard
if exists('g:loaded_tmux_i3_integration') || &cp
  finish
endif
let g:loaded_tmux_i3_integration = 1


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
        " Use python to invoke the i3-msg command so that vim doesn't need to be redrawn.
        call tmux_i3_integration#PythonExecProcess("i3-msg", ["-q", "focus", a:direction])
    endif
endfunction

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

    let oldw = winnr()
    silent exe 'wincmd ' . vim_cmd
    let neww = winnr()
    if oldw == neww
        " Use python to invoke the i3-msg command so that vim doesn't need to be redrawn.
        call tmux_i3_integration#PythonExecProcess("i3-msg", ["-q", "move", a:direction])
    endif
endfunction

" @param orientation horizontal|vertical
" @param delta signed integer, "size in column"
function Resize(orientation, delta)
    " Find layout situation: if there are corresponding split for resize orientation
    let split = {'has_horizontal': 0, 'has_vertical': 0}
    call s:get_buf_split(winlayout(), split, bufwinid("%"))

    " If orientation is horizontal and there is no split on the left/right, delegate resize operation.
    " If orientation is vertical   and there is no split above/below      , delegate resize operation.
    if a:orientation == 'horizontal'
        if !split.has_vertical
            if a:delta > 0
                call tmux_i3_integration#PythonExecProcess("i3-msg", ["-q", "resize", "grow   width 10px or 7ppt"])
                return
            else
                call tmux_i3_integration#PythonExecProcess("i3-msg", ["-q", "resize", "shrink width 10px or 7ppt"])
                return
            endif
        endif
    elseif a:orientation == 'vertical'
        if !split.has_horizontal
            if a:delta > 0
                call tmux_i3_integration#PythonExecProcess("i3-msg", ["-q", "resize", "grow   height 10px or 7ppt"])
                return
            else
                call tmux_i3_integration#PythonExecProcess("i3-msg", ["-q", "resize", "shrink height 10px or 7ppt"])
                return
            endif
        endif
    else
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

" Find if current window has adjacent vertical or horizontal split
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
