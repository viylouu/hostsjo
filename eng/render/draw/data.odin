package draw

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
