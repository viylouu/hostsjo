package main

import eng "../../eng/core"
import "../../eng/core/util"
import "../../eng/core/input"
import "../../eng/render/draw"
import "../../eng/render/texture"

import "vendor:glfw"

tex: texture.texture

main :: proc() {
    using eng

    init("window example",800,600)
    defer end()

    util.vsync(true)

    tex = texture.load("examples/textures/tex.png")
    defer texture.unload(&tex)

    loop(
        proc() /* update */ {
            using input
            using glfw

            if is_key_press(KEY_ESCAPE) do stop()
        },
        proc() /* render */ {
            using draw
            clear(0,0,0)

            texture(tex, 0,0, eng.__width,eng.__height, [3]u8{255,0,0})
        }
    )
}

