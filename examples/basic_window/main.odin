package main

import "../../eng"
import "../../eng/input"
import "../../eng/draw"

import im "../../eng/lib/imgui"

import "core:fmt"

import w "vendor:glfw"

main :: proc() {
    using eng

    init("window example",800,600)
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
