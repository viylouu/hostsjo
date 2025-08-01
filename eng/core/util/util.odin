package util

import "../const"

import "vendor:glfw"

w_x,w_y, w_w,w_h: i32

vsync :: proc(enabled: bool) {
    using glfw
    SwapInterval(enabled? 1 : 0)
}

fullscreen :: proc(enabled: bool) {
    using glfw
    using const
    
    if enabled {
        mon := GetPrimaryMonitor()
        mode := GetVideoMode(mon)

        w_x, w_y = GetWindowPos(__handle)
        w_w, w_h = GetWindowSize(__handle)
        
        SetWindowMonitor(__handle, mon, 0,0, mode^.width, mode^.height, mode^.refresh_rate)
        return
    }

    SetWindowMonitor(__handle, nil, w_x,w_y,w_w,w_h, 0)
}
