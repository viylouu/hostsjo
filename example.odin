package main

import "eng"
import err "eng/error"

import gl "vendor:OpenGL"

main :: proc() {
    eng.init(800,600,"hi :)")
    defer eng.end()

    eng.vsync(true)

    eng.loop(
        proc() /* update */ {
            
        },
        proc() /* render */ {
            gl.ClearColor(1,1,1,1)
            gl.Clear(gl.COLOR_BUFFER_BIT)
        }
    )
}
