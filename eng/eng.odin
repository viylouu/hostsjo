package eng // shorthand for: engine

import err "error"
import cb "callback"

import gl "vendor:OpenGL"
import fw "vendor:glfw"

GL_MAJOR :: 4
GL_MINOR :: 6

__handle: fw.WindowHandle

__width:  i32
__height: i32

init :: proc(width,height: i32, title: cstring) {
    err.critical("glfw is not being very happy >:(", !bool(fw.Init()))

    __handle = fw.CreateWindow(width,height,title, nil,nil)
    err.critical("the window is being silly, wattesigma", __handle == nil)

    fw.MakeContextCurrent(__handle)
    fw.SetFramebufferSizeCallback(__handle, cb.__fbcb_size)

    gl.load_up_to(GL_MAJOR, GL_MINOR, proc(p: rawptr, name: cstring) {
        (^rawptr)(p)^ = fw.GetProcAddress(name)
    })

    __width  = width
    __height = height
    gl.Viewport(0,0,__width,__height)
}

loop :: proc(update,render: proc()) {
    for !fw.WindowShouldClose(__handle) {
        fw.PollEvents()

        __width  = cb.__width
        __height = cb.__height

        update()
        render()

        fw.SwapBuffers(__handle)
    }
}

end :: proc() {
    fw.DestroyWindow(__handle)
    fw.Terminate()
}

vsync :: proc(enabled: bool) {
    fw.SwapInterval(enabled? 1 : 0)
}
