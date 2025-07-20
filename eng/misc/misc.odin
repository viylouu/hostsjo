package misc

import "../"

import w "vendor:glfw"

move_window :: proc(x,y: i32) {
    w.SetWindowPos(eng.__handle, x,y)
}
