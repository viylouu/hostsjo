package main

import eng "../../eng/core"
import "../../eng/core/util"
import "../../eng/core/input"
import "../../eng/render/draw"
import "../../eng/core/time"
import "../../eng/sound"

import "core:math"

import "vendor:glfw"

music: sound.Sound
introfade: sound.Sound

main :: proc() {
    using eng

    init("window example",800,600)
    defer end()

    util.vsync(true)

    music = sound.load("examples/sound/sound.wav")
    defer sound.unload(&music)

    introfade = sound.load("examples/sound/introfade.wav")
    defer sound.unload(&introfade)

    sound.play(&music)

    loop(
        proc() /* update */ {
            using input
            using glfw
            using time

            if is_key_press(KEY_ESCAPE) do stop()

            if is_mouse_press(MOUSE_BUTTON_LEFT) do sound.play(&introfade)

            music.pitch = math.sin(time32*32) + 1
        },
        proc() /* render */ {
            using draw
            clear(0,0,0)

            frect(input.mouse_x, input.mouse_y, 32,32, [3]u8{255,0,0})
        }
    )
}

