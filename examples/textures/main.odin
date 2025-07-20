package main

import "../../eng"
import "../../eng/input"
import "../../eng/draw"
import "../../eng/error"
import "../../eng/texture"

import "core:strings"

import "vendor:OpenGL"
import w "vendor:glfw"
import stbi "vendor:stb/image"

tex: texture.texture

main :: proc() {
    using eng

    init("window example",800,600)
    defer end()

    vsync(true)

    tex = texture.load("examples/textures/tex.png")

    loop(
        proc() /* update */ {
            using input
            if is_key_press(w.KEY_ESCAPE) { stop() }
        },
        proc() /* render */ {
            using draw
            clear(0,0,0)

            texture(tex, 0,0, 800,600, [3]u8{255,0,0})
        }
    )
}

