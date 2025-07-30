package draw

import tx "../texture"

import "core:math/linalg/glsl"

@private
rect_vertices := [?]f32 {
		0,0,
		0,1,
		1,1,
		1,1,
		1,0,
		0,0
	}

@private
rect_vert := #load("../../../data/shaders/eng/rect.vert", cstring)
@private
rect_frag := #load("../../../data/shaders/eng/rect.frag", cstring)

@private
tex_vert := #load("../../../data/shaders/eng/tex.vert", cstring)
@private
tex_frag := #load("../../../data/shaders/eng/tex.frag", cstring)

@private
trans: glsl.mat4

@private
batch: Assembled

@private
Assembled :: struct {
    type: Batch_Type,
    tex: ^tx.Texture,
    data: [dynamic]Instance_Data,
    was_used: bool
}

@private
Instance_Data :: struct #packed {
    trans: matrix[4,4]f32, 
    pos: [2]f32, 
    size: [2]f32,
    samp_pos: [2]f32,
    samp_size: [2]f32,
    col: [4]f32
}

@private
Batch_Type :: enum i32 {
    RECT,
    TEXTURE
}
