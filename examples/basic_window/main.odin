package main

import eng "../../eng/core"
import "../../eng/core/util"
import "../../eng/core/input"
import "../../eng/render/draw"

import "vendor:glfw"

main :: proc() {
    using eng

    init("window example",800,600)
    defer end()

    util.vsync(true)

    loop(
        proc() /* update */ {
            using input
            using glfw

            if is_key_press(KEY_ESCAPE) do stop()
        },
        proc() /* render */ {
            using draw
            clear(0,0,0)

            frect(input.mouse_x, input.mouse_y, 32,32, [3]u8{255,0,0})
        }
    )
}
