package draw

import gl "vendor:OpenGL"


clear_rgba_arr :: proc(col: [4]u8) {
	clear_rgba(col.r,col.g,col.b,col.a)
}

clear_rgba :: proc(r,g,b,a: u8) {
	gl.ClearColor(f32(r)/256., f32(g)/256., f32(b)/256., f32(a)/256.)
	gl.Clear(gl.COLOR_BUFFER_BIT)
}

clear_rgb_arr :: proc(col: [3]u8) {
	clear_rgba(col.r,col.g,col.b, 255)
}

clear_rgb :: proc(r,g,b: u8) {
	clear_rgba(r,g,b, 255)
}

clear :: proc { clear_rgba_arr, clear_rgba, clear_rgb_arr, clear_rgb }


rect_rgba :: proc(x,y,w,h: i32, col: [4]u8) {
	gl.UseProgram(bufs.rect.prog)
	gl.BindVertexArray(bufs.rect.vao)
	
	gl.UniformMatrix4fv(bufs.rect.loc_proj, 1, false, transmute([^]f32)&proj)
	gl.Uniform2f(bufs.rect.loc_pos, f32(x),f32(y))
	gl.Uniform2f(bufs.rect.loc_size, f32(w),f32(h))
	gl.Uniform4f(bufs.rect.loc_col, f32(col.r)/256., f32(col.g)/256., f32(col.b)/256., f32(col.a)/256.)

	gl.DrawArrays(gl.TRIANGLES, 0, 6)

	gl.BindVertexArray(0)
}

rect_rgb :: proc(x,y,w,h: i32, col: [3]u8) {
	rect_rgba(x,y,w,h, [4]u8 { col.r, col.g, col.b, 255 })
}

rect_rgba_int :: proc(x,y,w,h: int, col: [4]u8) {
	rect_rgba(i32(x),i32(y),i32(w),i32(h), col)
}

rect_rgb_int :: proc(x,y,w,h: int, col: [3]u8) {
	rect_rgba_int(x,y,w,h, [4]u8 { col.r, col.g, col.b, 255 })
}

rect :: proc { rect_rgba, rect_rgba_int, rect_rgb, rect_rgb_int }
