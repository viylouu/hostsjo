package main

import "../../eng"
import "../../eng/input"
import "../../eng/draw"

import im "../../eng/lib/imgui"

import "core:fmt"

import w "vendor:glfw"

val_int:   i32
val_float: f32
val_col:   [3]f32

main :: proc() {
    using eng

    init("imgui example",800,600, WF_DRAW_LIB | WF_IMGUI)
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

            // starts an imgui window
            if im.Begin("hi") { 
                im.Text("text")

                im.SliderInt("snappy slidey", &val_int, -10, 10)
                im.SliderFloat("smooth slidey", &val_float, -1, 1)

                im.InputInt("snappy setty", &val_int)

                smooth_setty_step :f32= 0.1
                im.InputFloat("smooth setty", &val_float, smooth_setty_step)

                if im.Button("print hi to the console") {
                    fmt.println("hi :)")
                }
                
                if im.TreeNode("dropdown") {
                    im.ColorPicker3("rainbow", &val_col)

                    // same situation as end
                    im.TreePop()
                }

                // must be called at end of imgui window if
                im.End() 
            }
        }
    )
}
