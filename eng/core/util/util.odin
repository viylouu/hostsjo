package util

import eng "../"

import "vendor:glfw"

w_x,w_y, w_w,w_h: i32

vsync :: proc(enabled: bool) {
    using glfw
    SwapInterval(enabled? 1 : 0)
}

fullscreen :: proc(enabled: bool) {
    using glfw
    
    if enabled {
        mon := GetPrimaryMonitor()
        mode := GetVideoMode(mon)

        w_x, w_y = GetWindowPos(eng.__handle)
        w_w, w_h = GetWindowSize(eng.__handle)
        
        SetWindowMonitor(eng.__handle, mon, 0,0, mode^.width, mode^.height, mode^.refresh_rate)
        return
    }

    SetWindowMonitor(eng.__handle, nil, w_x,w_y,w_w,w_h, 0)
}
