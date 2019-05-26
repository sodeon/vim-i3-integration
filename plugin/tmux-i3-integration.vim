func! Focus(comando)
    if a:comando == 'left'
        let vim_comando = 'h'
    elseif a:comando == 'right'
        let vim_comando = 'l'
    elseif a:comando == 'up'
        let vim_comando = 'k'
    elseif a:comando == 'down'
        let vim_comando = 'j'
    else
        return
    endif

    let oldw = winnr()
    silent exe 'wincmd ' . vim_comando
    let neww = winnr()
    if oldw == neww
        " Use python to invoke the i3-msg command so that vim doesn't need to be redrawn.
        call tmux_i3_integration#PythonExecProcess("i3-msg", ["-q", "focus", a:comando])
    endif
endfunction
