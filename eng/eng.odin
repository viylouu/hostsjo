package eng // shorthand for: engine

import "error"
import "callback"
import "shaders"
import "textures"
import "time"
import "draw"
import "consts"
import "input"

import "core:strings"
import "core:strconv"

import im "lib/imgui"
import imgl "lib/imgui/opengl3"
import imfw "lib/imgui/glfw"

import gl "vendor:OpenGL"
import w "vendor:glfw"
import img "vendor:stb/image"

__handle: w.WindowHandle

__width:  i32
__height: i32
__area_width:  i32
__area_height: i32

@private
_is_running: bool

WF_DEFAULT :: WF_DRAW_LIB

WF_DRAW_LIB    :: 1 << 0    // allows you to use the eng/draw stuff instead of raw opengl
WF_CONST_SCALE :: 1 << 1    // makes it so the draw area will not change
WF_RESIZABLE   :: 1 << 2    // makes the window able to be resized
WF_IMGUI       :: 1 << 3    // whether or not to initialize imgui

imgui_ver_string:  string

// flags can be specified using the consts in the format: WF_FLAG_NAME and bit-or-ing the flags together 
init :: proc(title: cstring, width,height: i32, flags: int = WF_DEFAULT) {
    error.critical("glfw is not being very happy >:(", !bool(w.Init()))

    // could be better by using log2 with variables but im too lazy to do that
    consts.wflag_draw_lib    = bool(flags       & 0x1)
    consts.wflag_const_scale = bool(flags >> 1  & 0x1)
    consts.wflag_resizable   = bool(flags >> 2  & 0x1)
    consts.wflag_imgui       = bool(flags >> 3  & 0x1)

    w.WindowHint(w.RESIZABLE,             i32(consts.wflag_resizable))
    w.WindowHint(w.OPENGL_FORWARD_COMPAT, w.TRUE)
	w.WindowHint(w.OPENGL_PROFILE,        w.OPENGL_CORE_PROFILE)
    w.WindowHint(w.OPENGL_FORWARD_COMPAT, w.TRUE)
    w.WindowHint(w.CONTEXT_VERSION_MAJOR, consts.GL_MAJOR)
    w.WindowHint(w.CONTEXT_VERSION_MINOR, consts.GL_MINOR)
    w.WindowHint(w.FLOATING,              w.TRUE)

    __handle = w.CreateWindow(width,height,title, nil,nil)
    error.critical("the window is being silly, wattesigma", __handle == nil)

    w.MakeContextCurrent(__handle)
    w.SwapInterval(0)
    w.SetFramebufferSizeCallback(__handle, callback.__fbcb_size)

    gl.load_up_to(int(consts.GL_MAJOR),consts.GL_MINOR,w.gl_set_proc_address)

    if consts.wflag_imgui {
        im.CHECKVERSION()
        im.CreateContext()

        im.StyleColorsDark()

        imfw.InitForOpenGL(__handle, true)
        
        buf: [2]byte
        imgui_ver_string = strings.concatenate ([]string { 
                "#version ", 
                strconv.itoa(buf[:], consts.GL_MAJOR),
                strconv.itoa(buf[:], consts.GL_MINOR*10)
            })

        imgl.Init(strings.unsafe_string_to_cstring(imgui_ver_string))
    }

    __width       = width
    __height      = height
    __area_width  = width
    __area_height = height

    gl.Viewport(0,0,__area_width,__area_height)

    img.set_flip_vertically_on_load(1)

	if consts.wflag_draw_lib {
		draw.init(f32(__area_width),f32(__area_height))
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

        if consts.wflag_const_scale {
            __area_width  = __width
            __area_height = __height
        } 

        draw.update(f32(__width),f32(__height))

        if consts.wflag_imgui {
            imfw.NewFrame()
            imgl.NewFrame()
            im.NewFrame()
        }

        update()
        render()

        if consts.wflag_imgui {
            im.Render()

            imgl.RenderDrawData(im.GetDrawData())
        }

        w.SwapBuffers(__handle)
    }
}

end :: proc() {
    if consts.wflag_imgui {
        imgl.Shutdown()
        imfw.Shutdown()
        im.DestroyContext()

        delete(imgui_ver_string)
    }

    if !consts.wflag_draw_lib {
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
