package main

import "../../eng"
import "../../eng/input"
import "../../eng/time"
import "../../eng/draw"

import w "vendor:glfw"

pos_x, pos_y: f32

main :: proc() {
    using eng

    init("window example",800,600)
    defer end()

    vsync(true)

    loop(
        proc() /* update */ {
            using input
            if is_key_press(w.KEY_ESCAPE) { stop() }

            SPEED :f32: 256

            if is_key_hold(w.KEY_W) { pos_y -= SPEED * time.delta32 }
            if is_key_hold(w.KEY_A) { pos_x -= SPEED * time.delta32 }
            if is_key_hold(w.KEY_S) { pos_y += SPEED * time.delta32 }
            if is_key_hold(w.KEY_D) { pos_x += SPEED * time.delta32 }
        },
        proc() /* render */ {
            using draw
            clear(0,0,0)

            frect(pos_x, pos_y, 32,32, [3]u8{255,0,0})
        }
    )
}
