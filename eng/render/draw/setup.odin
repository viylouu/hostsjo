package draw

import "../shader"

import sl "core:math/linalg/glsl"

import "vendor:OpenGL"

@private
proj: sl.mat4

init :: proc(w,h: f32) {
	proj = sl.mat4Ortho3d(0, w,h, 0, -1,1)

	using OpenGL
	using shader

    //// rect
        GenVertexArrays(1, &bufs.rect.vao)
        BindVertexArray(bufs.rect.vao)

        GenBuffers(1, &bufs.rect.vbo)
        BindBuffer(ARRAY_BUFFER, bufs.rect.vbo)
        BufferData(ARRAY_BUFFER, len(rect_vertices) * size_of(f32), &rect_vertices, STATIC_DRAW)

        VertexAttribPointer(0, 2, FLOAT, FALSE, 2 * size_of(f32), cast(uintptr)0)
        EnableVertexAttribArray(0)

        BindBuffer(ARRAY_BUFFER, 0)
        BindVertexArray(0)

        bufs.rect.prog = load_program_from_src(&rect_vert, &rect_frag)

        bufs.rect.loc_pos  = GetUniformLocation(bufs.rect.prog, "pos")
        bufs.rect.loc_size = GetUniformLocation(bufs.rect.prog, "size")
        bufs.rect.loc_col  = GetUniformLocation(bufs.rect.prog, "col")
        bufs.rect.loc_proj = GetUniformLocation(bufs.rect.prog, "proj")

    //// tex
        GenVertexArrays(1, &bufs.tex.vao)
        BindVertexArray(bufs.tex.vao)

        GenBuffers(1, &bufs.tex.vbo)
        BindBuffer(ARRAY_BUFFER, bufs.tex.vbo)
        BufferData(ARRAY_BUFFER, len(rect_vertices) * size_of(f32), &rect_vertices, STATIC_DRAW)

        VertexAttribPointer(0, 2, FLOAT, FALSE, 2 * size_of(f32), cast(uintptr)0)
        EnableVertexAttribArray(0)

        BindBuffer(ARRAY_BUFFER, 0)
        BindVertexArray(0)

        bufs.tex.prog = load_program_from_src(&tex_vert, &tex_frag)

        bufs.tex.loc_pos       = GetUniformLocation(bufs.tex.prog, "pos")
        bufs.tex.loc_size      = GetUniformLocation(bufs.tex.prog, "size")
        bufs.tex.loc_samp_pos  = GetUniformLocation(bufs.tex.prog, "samp_pos")
        bufs.tex.loc_samp_size = GetUniformLocation(bufs.tex.prog, "samp_size")
        bufs.tex.loc_tint      = GetUniformLocation(bufs.tex.prog, "tint")
        bufs.tex.loc_proj      = GetUniformLocation(bufs.tex.prog, "proj")
        bufs.tex.loc_tex       = GetUniformLocation(bufs.tex.prog, "tex")
}

update :: proc(w,h: f32) {
    proj = sl.mat4Ortho3d(0, w,h, 0, -1,1)
}

end :: proc() {
    using OpenGL

    if bufs.rect.vbo != 0  do DeleteBuffers(1, &bufs.rect.vbo) 
    if bufs.rect.vao != 0  do DeleteVertexArrays(1, &bufs.rect.vao) 
    if bufs.rect.prog != 0 do DeleteProgram(bufs.rect.prog)

    if bufs.tex.vbo != 0   do DeleteBuffers(1, &bufs.tex.vbo) 
    if bufs.tex.vao != 0   do DeleteVertexArrays(1, &bufs.tex.vao) 
    if bufs.tex.prog != 0  do DeleteProgram(bufs.tex.prog)
}
