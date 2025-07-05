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
import fw "vendor:glfw"
import stbi "vendor:stb/image"

__handle: fw.WindowHandle

__width:  i32
__height: i32

init :: proc(title: cstring, width,height: i32) {
    error.critical("glfw is not being very happy >:(", !bool(fw.Init()))

    fw.WindowHint(fw.RESIZABLE, fw.TRUE)
    fw.WindowHint(fw.OPENGL_FORWARD_COMPAT, fw.TRUE)
    fw.WindowHint(fw.CONTEXT_VERSION_MAJOR, consts.GL_MAJOR)
    fw.WindowHint(fw.CONTEXT_VERSION_MINOR, consts.GL_MINOR)
    fw.WindowHint(fw.OPENGL_PROFILE,fw.OPENGL_CORE_PROFILE)

    __handle = fw.CreateWindow(width,height,title, nil,nil)
    error.critical("the window is being silly, wattesigma", __handle == nil)

    fw.MakeContextCurrent(__handle)
    fw.SetFramebufferSizeCallback(__handle, callback.__fbcb_size)

    gl.load_up_to(consts.GL_MAJOR, consts.GL_MINOR, proc(p: rawptr, name: cstring) {
        (^rawptr)(p)^ = fw.GetProcAddress(name)
    })

    __width  = width
    __height = height
    gl.Viewport(0,0,__width,__height)

    stbi.set_flip_vertically_on_load(1)

	if !consts.GL_ONLY {
		draw.init(f32(width),f32(height))
	}
}

loop :: proc(update,render: proc()) {
    lastTime: f64
    for !fw.WindowShouldClose(__handle) {
        fw.PollEvents()
		input.poll(__handle)

        time.delta = fw.GetTime() - lastTime
        time.time = time.delta + lastTime
        lastTime = fw.GetTime()

        __width  = callback.__width
        __height = callback.__height

        update()
        render()

        fw.SwapBuffers(__handle)
    }
}

end :: proc() {
    for item in shaders.__stuff_to_free { free(item) }

    delete(shaders.__stuff_to_free)

    fw.DestroyWindow(__handle)
    fw.Terminate()
}

vsync :: proc(enabled: bool) {
    fw.SwapInterval(enabled? 1 : 0)
}
