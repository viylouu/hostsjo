package main

import "../eng"
import "../eng/input"
import "../eng/draw"

import w "vendor:glfw"

main :: proc() {
    using eng

    init("title",800,600)
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
        }
    )
}
