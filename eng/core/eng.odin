package eng // shorthand for engine

import "error"
import "callback"
import "time"
import "const"
import "input"
import "../render/draw"
import "../sound"

import "core:fmt"
import "core:strings"
import "core:strconv"

import im "../lib/imgui"
import imgl "../lib/imgui/opengl3"
import imfw "../lib/imgui/glfw"

import "vendor:OpenGL"
import "vendor:glfw"
import "vendor:stb/image"

__handle: glfw.WindowHandle

__width:  i32
__height: i32
__area_width:  i32
__area_height: i32

WF_DEFAULT :: WF_DRAW_LIB | WF_SOUND_LIB | WF_IMGUI

WF_DRAW_LIB    :: 1 << 0    // allows you to use the eng/draw stuff instead of raw opengl or whatever
WF_CONST_SCALE :: 1 << 1    // makes it so the draw area will not change
WF_RESIZABLE   :: 1 << 2    // makes the window able to be resized
WF_IMGUI       :: 1 << 3    // whether or not to initialize imgui, also for some reason eng segfaults on end without this
WF_SOUND_LIB   :: 1 << 4    // allows you to use the eng/sound stuff instead of raw openal or whatever

imgui_ver_string:  string

// flags can be specified using the consts in the format: WF_FLAG_NAME and bit-or-ing the flags together 
init :: proc(title: cstring, width,height: i32, flags: int = WF_DEFAULT) {
    using glfw

    error.critical("glfw is not being very happy >:(", !bool(Init()))

    // could be better by using log2 with variables but im too lazy to do that
    const.wflag_draw_lib    = bool(flags       & 0x1)
    const.wflag_const_scale = bool(flags >> 1  & 0x1)
    const.wflag_resizable   = bool(flags >> 2  & 0x1)
    const.wflag_imgui       = bool(flags >> 3  & 0x1)
    const.wflag_sound_lib   = bool(flags >> 4  & 0x1)

    WindowHint(RESIZABLE,             i32(const.wflag_resizable))
    WindowHint(OPENGL_FORWARD_COMPAT, TRUE)
	WindowHint(OPENGL_PROFILE,        OPENGL_CORE_PROFILE)
    WindowHint(CONTEXT_VERSION_MAJOR, const.GL_MAJOR)
    WindowHint(CONTEXT_VERSION_MINOR, const.GL_MINOR)
    WindowHint(FLOATING,              TRUE)

    __handle = CreateWindow(width,height,title, nil,nil)
    error.critical("the window is being silly, wattesigma", __handle == nil)

    MakeContextCurrent(__handle)
    SwapInterval(0)
    SetFramebufferSizeCallback(__handle, callback.__fbcb_size)

    OpenGL.load_up_to(int(const.GL_MAJOR), const.GL_MINOR, gl_set_proc_address)
    fmt.println("gl ver: ", OpenGL.GetString(OpenGL.VERSION))

    if const.wflag_imgui {
        im.CHECKVERSION()
        im.CreateContext()

        im.StyleColorsDark()

        imfw.InitForOpenGL(__handle, true)
        
        buf: [2]byte
        imgui_ver_string = strings.concatenate ([]string { 
                "#version ", 
                strconv.itoa(buf[:], const.GL_MAJOR),
                strconv.itoa(buf[:], const.GL_MINOR),
                "0 core"
            })

        imgl.Init(strings.unsafe_string_to_cstring(imgui_ver_string))
    }

    __width, __height = width, height
    __area_width  = width
    __area_height = height

    OpenGL.Viewport(0,0,__area_width,__area_height)

    SetWindowSize(__handle, width + 1, height)
    SetWindowSize(__handle, width, height)

	if const.wflag_draw_lib do draw.init(f32(__area_width),f32(__area_height))

    if const.wflag_sound_lib do sound.init()
}

loop :: proc(update,render: proc()) {
    using glfw
    using time

    lastTime: f64
    for !WindowShouldClose(__handle) {
        PollEvents()
		input.poll(__handle)

        now := GetTime()
        delta = now - lastTime
        time = now
        lastTime = now

        delta32 = f32(delta)
        time32 = f32(time)

        __width  = callback.__width
        __height = callback.__height

        if const.wflag_const_scale {
            __area_width  = __width
            __area_height = __height
        } 

        if const.wflag_draw_lib do draw.update(f32(__width),f32(__height))

        if const.wflag_imgui {
            imfw.NewFrame()
            imgl.NewFrame()
            im.NewFrame()
        }

        update()
        render()

        if const.wflag_sound_lib do sound.update()

        if const.wflag_imgui {
            im.Render()
            imgl.RenderDrawData(im.GetDrawData())
        }

        SwapBuffers(__handle)
    }
}

end :: proc() {
    using glfw

    if const.wflag_imgui {
        imgl.Shutdown()
        imfw.Shutdown()
        im.DestroyContext()

        delete(imgui_ver_string)
    }

    if const.wflag_sound_lib {
        sound.stfu()
        sound.end()
    }

    if const.wflag_draw_lib do draw.end()

    // just being safe
    glfw.SetKeyCallback(__handle, nil)
    glfw.SetCharCallback(__handle, nil)
    glfw.SetCursorPosCallback(__handle, nil)
    glfw.SetMouseButtonCallback(__handle, nil)
    glfw.SetScrollCallback(__handle, nil)
    glfw.SetWindowCloseCallback(__handle, nil)
    glfw.SetFramebufferSizeCallback(__handle, nil)

    MakeContextCurrent(nil)

    DestroyWindow(__handle)

    Terminate()
}

stop :: proc() {
    using glfw
    SetWindowShouldClose(__handle, true)
}
