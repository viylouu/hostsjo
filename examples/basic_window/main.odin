package main

import "../../eng"
import "../../eng/input"
import "../../eng/draw"

import w "vendor:glfw"

main :: proc() {
    using eng

    init("window example",800,600)
    defer end()

    vsync(true)

    loop(
        proc() /* update */ {
            using input
            if is_key_press(w.KEY_ESCAPE) { stop() }
        },
        proc() /* render */ {
            using draw
            clear(0,0,0)

            frect(input.mouse_x, input.mouse_y, 32,32, [3]u8{255,0,0})
        }
    )
}
