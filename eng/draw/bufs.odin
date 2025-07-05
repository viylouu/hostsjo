package draw

import "vendor:OpenGL"

@private
bufs: struct {
	rect: struct {
		vao,vbo: u32,
		prog: u32,
		loc_pos: i32,
		loc_size: i32,
		loc_col: i32,
		loc_proj: i32
	}
}
