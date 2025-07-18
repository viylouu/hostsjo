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
            if get_key(w.KEY_ESCAPE) == .press { stop() }

            SPEED :f32: 256

            if get_key(w.KEY_W) == .hold { pos_y -= SPEED * time.delta32 }
            if get_key(w.KEY_A) == .hold { pos_x -= SPEED * time.delta32 }
            if get_key(w.KEY_S) == .hold { pos_y += SPEED * time.delta32 }
            if get_key(w.KEY_D) == .hold { pos_x += SPEED * time.delta32 }
        },
        proc() /* render */ {
            using draw
            clear(0,0,0)

            frect(pos_x, pos_y, 32,32, [3]u8{255,0,0})
        }
    )
}
