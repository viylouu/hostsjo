package main

import eng "../../eng/core"
import "../../eng/core/util"
import "../../eng/core/time"
import "../../eng/core/input"
import "../../eng/render/draw"

import "vendor:glfw"

fullscreen: bool

pos_x, pos_y: f32

main :: proc() {
    using eng

    init("window example",800,600)
    defer end()

    util.vsync(true)

    loop(
        proc() /* update */ {
            using input
            using glfw
            using time

            if is_key_press(KEY_ESCAPE) do stop()

            SPEED :f32: 256

            if is_key_hold(KEY_W) do pos_y -= SPEED * delta32
            if is_key_hold(KEY_A) do pos_x -= SPEED * delta32
            if is_key_hold(KEY_S) do pos_y += SPEED * delta32
            if is_key_hold(KEY_D) do pos_x += SPEED * delta32

            if is_key_press(KEY_F) { 
                fullscreen = !fullscreen
                util.fullscreen(fullscreen) 
            }
        },
        proc() /* render */ {
            using draw
            clear(0,0,0)

            frect(pos_x, pos_y, 32,32, [3]u8{255,0,0})
        }
    )
}
