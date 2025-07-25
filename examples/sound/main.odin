package main

import eng "../../eng/core"
import "../../eng/core/util"
import "../../eng/core/input"
import "../../eng/render/draw"
import "../../eng/core/time"
import au "../../eng/sound" // au -> audio

import "core:math"
import "core:math/rand"

import "vendor:glfw"

music: au.Sound
introfade: au.Sound

main :: proc() {
    using eng

    init("window example",800,600)
    defer end()

    util.vsync(true)

    music = au.load("examples/sound/sound.wav")
    defer au.unload(&music)

    introfade = au.load("examples/sound/introfade.wav")
    defer au.unload(&introfade)

    au.play(&music)

    loop(
        proc() /* update */ {
            using input
            using glfw
            using time

            if is_key_press(KEY_ESCAPE) do stop()

            if is_mouse_press(MOUSE_BUTTON_LEFT) do au.play(&introfade, 1, rand.float32_range(0.25, 2))

            music.global_volume = math.sin(time32*32) + 1
        },
        proc() /* render */ {
            using draw
            clear(0,0,0)

            frect(input.mouse_x, input.mouse_y, 32,32, [3]u8{255,0,0})
        }
    )
}

