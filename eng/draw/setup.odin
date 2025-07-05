package draw

import sl "core:math/linalg/glsl"

import "../shaders"
import "../consts"

import "vendor:OpenGL"

@private
proj: sl.mat4

init :: proc(w,h: f32) {
	proj = sl.mat4Ortho3d(0, w,h, 0, -1,1)

	using OpenGL
	using shaders

	GenVertexArrays(1, &bufs.rect.vao)
	BindVertexArray(bufs.rect.vao)

	GenBuffers(1, &bufs.rect.vbo)
	BindBuffer(ARRAY_BUFFER, bufs.rect.vbo)
	BufferData(ARRAY_BUFFER, len(rect_vertices) * size_of(f32), &rect_vertices, STATIC_DRAW)

	VertexAttribPointer(0, 2, FLOAT, FALSE, 2 * size_of(f32), cast(uintptr)0)
	EnableVertexAttribArray(0)

	BindBuffer(ARRAY_BUFFER, 0)
	BindVertexArray(0)

	bufs.rect.prog = load_program("data/shaders/eng/rect.vert", "data/shaders/eng/rect.frag")

	bufs.rect.loc_pos = GetUniformLocation(bufs.rect.prog, "pos")
	bufs.rect.loc_size = GetUniformLocation(bufs.rect.prog, "size")
	bufs.rect.loc_col = GetUniformLocation(bufs.rect.prog, "col")
	bufs.rect.loc_proj = GetUniformLocation(bufs.rect.prog, "proj")
}

