package main

import "../../eng"
import "../../eng/input"
import "../../eng/draw"
import "../../eng/texture"

import "vendor:glfw"

tex: texture.texture

main :: proc() {
    using eng

    init("window example",800,600)
    defer end()

    vsync(true)

    tex = texture.load("examples/textures/tex.png")
    defer texture.remove(&tex)

    loop(
        proc() /* update */ {
            using input
            using glfw

            if is_key_press(KEY_ESCAPE) { stop() }
        },
        proc() /* render */ {
            using draw
            clear(0,0,0)

            texture(tex, 0,0, 800,600, [3]u8{255,0,0})
        }
    )
}

