package main

import "../eng"
import "../eng/input"
import "../eng/draw"

import "core:fmt"

import w "vendor:glfw"

main :: proc() {
    using eng

    init("title",800,600, WF_DRAW_LIB | WF_RESIZABLE)
    defer end()

    vsync(true)

    loop(
        proc() /* update */ {
            using input
            if get_key(w.KEY_ESCAPE) == .press { stop() }
        },
        proc() /* render */ {
            using draw
            clear(0,0,0)

            frect(input.mouse_x, input.mouse_y, 32,32, [3]u8{255,0,0})
        }
    )
}
