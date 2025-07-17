package eng // shorthand for: engine

import "error"
import "callback"
import "shaders"
import "textures"
import "time"
import "draw"
import "consts"
import "input"

import gl "vendor:OpenGL"
import w "vendor:glfw"
import img "vendor:stb/image"

__handle: w.WindowHandle

__width:  i32
__height: i32

@private
_is_running: bool

init :: proc(title: cstring, width,height: i32) {
    error.critical("glfw is not being very happy >:(", !bool(w.Init()))

    w.WindowHint(w.RESIZABLE, w.FALSE)
    w.WindowHint(w.OPENGL_FORWARD_COMPAT, w.TRUE)
    w.WindowHint(w.CONTEXT_VERSION_MAJOR, consts.GL_MAJOR)
    w.WindowHint(w.CONTEXT_VERSION_MINOR, consts.GL_MINOR)
    w.WindowHint(w.OPENGL_PROFILE,w.OPENGL_CORE_PROFILE)

    __handle = w.CreateWindow(width,height,title, nil,nil)
    error.critical("the window is being silly, wattesigma", __handle == nil)

    w.MakeContextCurrent(__handle)
    w.SwapInterval(0)
    w.SetFramebufferSizeCallback(__handle, callback.__fbcb_size)

    //gl.load_up_to(consts.GL_MAJOR, consts.GL_MINOR, proc(p: rawptr, name: cstring) {
    //    (^rawptr)(p)^ = w.GetProcAddress(name)
    //})
    gl.load_up_to(int(consts.GL_MAJOR),consts.GL_MINOR,w.gl_set_proc_address)

    __width  = width
    __height = height
    gl.Viewport(0,0,__width,__height)

    img.set_flip_vertically_on_load(1)

	if !consts.GL_ONLY {
		draw.init(f32(width),f32(height))
	}
}

loop :: proc(update,render: proc()) {
    _is_running = true

    lastTime: f64
    for !w.WindowShouldClose(__handle) && _is_running {
        w.PollEvents()
		input.poll(__handle)

        time.delta = w.GetTime() - lastTime
        time.time = time.delta + lastTime
        lastTime = w.GetTime()

        __width  = callback.__width
        __height = callback.__height

        update()
        render()

        w.SwapBuffers(__handle)
    }
}

end :: proc() {
    if !consts.GL_ONLY {
        draw.end()
    }

    w.SetFramebufferSizeCallback(__handle, nil)

    w.MakeContextCurrent(nil)

    w.DestroyWindow(__handle)
    __handle = nil

    w.Terminate()
}

vsync :: proc(enabled: bool) {
    w.SwapInterval(enabled? 1 : 0)
}

stop :: proc() {
    _is_running = false
}
