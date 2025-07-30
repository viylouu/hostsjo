package draw

import "../shader"

import "core:fmt"
import "core:math/linalg/glsl"

import "vendor:OpenGL"

@private
proj: glsl.mat4

max_array_size :: 65536
max_buffer_size :: max_array_size * size_of(Instance_Data)

init :: proc(w,h: f32) {
	using OpenGL
	using shader

    batch.data = make([dynamic]Instance_Data)

    //// rect
        GenVertexArrays(1, &bufs.rect.vao)
        GenBuffers(1, &bufs.rect.ssbo)
        BindBuffer(SHADER_STORAGE_BUFFER, bufs.rect.ssbo)

        BufferStorage(SHADER_STORAGE_BUFFER, max_buffer_size, nil, DYNAMIC_STORAGE_BIT)

        bufs.rect.prog = load_program_from_src(&rect_vert, &rect_frag)
        bufs.rect.loc_proj  = GetUniformLocation(bufs.rect.prog, "proj")

    //// tex
        GenVertexArrays(1, &bufs.tex.vao)
        GenBuffers(1, &bufs.tex.ssbo)
        BindBuffer(SHADER_STORAGE_BUFFER, bufs.tex.ssbo)

        BufferStorage(SHADER_STORAGE_BUFFER, max_buffer_size, nil, DYNAMIC_STORAGE_BIT)

        bufs.tex.prog = load_program_from_src(&tex_vert, &tex_frag)
        bufs.tex.loc_proj      = GetUniformLocation(bufs.tex.prog, "proj")
}

update :: proc(w,h: f32) {
    using glsl
    proj = mat4Ortho3d(0, w,h, 0, -1,1)
    reset_transform()
}

end :: proc() {
    using OpenGL

    if bufs.rect.ssbo != 0 do DeleteBuffers(1, &bufs.rect.ssbo) 
    if bufs.rect.vao != 0  do DeleteVertexArrays(1, &bufs.rect.vao) 
    if bufs.rect.prog != 0 do DeleteProgram(bufs.rect.prog)

    if bufs.tex.ssbo != 0 do DeleteBuffers(1, &bufs.tex.ssbo) 
    if bufs.tex.vao != 0  do DeleteVertexArrays(1, &bufs.tex.vao) 
    if bufs.tex.prog != 0 do DeleteProgram(bufs.tex.prog)
}
