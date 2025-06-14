package callback

import gl "vendor:OpenGL"
import fw "vendor:glfw"

__width:  i32 = 0
__height: i32 = 0

// overridable
__fbcb_size := proc "c" (window: fw.WindowHandle, width,height: i32) {
    gl.Viewport(0,0,width,height)
    __width  = width
    __height = height
}
