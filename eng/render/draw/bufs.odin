package draw

import "vendor:OpenGL"

@private
bufs: struct {
	rect: struct {
		vao,vbo:   u32,
		prog:      u32,
		loc_pos:   i32,
		loc_size:  i32,
		loc_col:   i32,
		loc_proj:  i32,
        loc_trans: i32
	},

    tex: struct {
        vao,vbo:       u32,
        prog:          u32,
        loc_pos:       i32,
        loc_size:      i32,
        loc_samp_pos:  i32,
        loc_samp_size: i32,
        loc_tint:      i32,
        loc_proj:      i32,
        loc_tex:       i32,
        loc_trans:     i32
    }
}
