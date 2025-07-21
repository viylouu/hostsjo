package draw

import "core:math"

import "../texture"

import "vendor:OpenGL"


clear_rgba_arr :: proc(col: [4]u8) {
	clear_rgba(col.r,col.g,col.b,col.a)
}

clear_rgba :: proc(r,g,b,a: u8) {
    using OpenGL
	ClearColor(f32(r)/256., f32(g)/256., f32(b)/256., f32(a)/256.)
    Clear(COLOR_BUFFER_BIT)
}

clear_rgb_arr :: proc(col: [3]u8) {
	clear_rgba(col.r,col.g,col.b, 255)
}

clear_rgb :: proc(r,g,b: u8) {
	clear_rgba(r,g,b, 255)
}

clear :: proc { clear_rgba_arr, clear_rgba, clear_rgb_arr, clear_rgb }


rect_rgba :: proc(x,y,w,h: i32, col: [4]u8) {
    rect_rgba_f32(f32(x),f32(y),f32(w),f32(h), col)
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


rect_rgba_f32 :: proc(x,y,w,h: f32, col: [4]u8) {
    using OpenGL
	UseProgram(bufs.rect.prog)
	BindVertexArray(bufs.rect.vao)
	
	UniformMatrix4fv(bufs.rect.loc_proj, 1, false, transmute([^]f32)&proj)
	Uniform2f(bufs.rect.loc_pos, x,y)
	Uniform2f(bufs.rect.loc_size, w,h)
	Uniform4f(bufs.rect.loc_col, f32(col.r)/256., f32(col.g)/256., f32(col.b)/256., f32(col.a)/256.)

	DrawArrays(TRIANGLES, 0, 6)

	BindVertexArray(0)
    UseProgram(0)
}

rect_rgb_f32 :: proc(x,y,w,h: f32, col: [3]u8) {
    rect_rgba_f32(x,y,w,h, [4]u8 { col.r,col.g,col.b, 255 })
}

frect :: proc { rect_rgba_f32, rect_rgb_f32 }


texture_rgba_wh :: proc(tex: texture.texture, x,y,w,h: i32, tint: [4]u8) {
    texture_rgba_wh_f32(tex, f32(x),f32(y),f32(w),f32(h), tint)
}

texture_rgb_wh :: proc(tex: texture.texture, x,y,w,h: i32, tint: [3]u8) {
    texture_rgba_wh(tex, x,y,w,h, [4]u8 { tint.r,tint.g,tint.b, 255 })
}

texture_rgba :: proc(tex: texture.texture, x,y: i32, tint: [4]u8) {
    texture_rgba_wh(tex, x,y, tex.width,tex.height, tint)
}

texture_rgb :: proc(tex: texture.texture, x,y: i32, tint: [3]u8) {
    texture_rgb_wh(tex, x,y, tex.width,tex.height, tint)
}

texture_wh :: proc(tex: texture.texture, x,y,w,h: i32) {
    texture_rgba_wh(tex, x,y,w,h, [4]u8 { 255,255,255,255 })
}

texture_nwh :: proc(tex: texture.texture, x,y: i32) {
    texture_rgba(tex, x,y, [4]u8 { 255,255,255,255 })
}

texture :: proc { texture_rgba_wh, texture_rgb_wh, texture_rgba, texture_rgb, texture_wh, texture_nwh }


texture_rgba_wh_f32 :: proc(tex: texture.texture, x,y,w,h: f32, tint: [4]u8) {
    using OpenGL
    UseProgram(bufs.tex.prog)
    BindVertexArray(bufs.tex.vao)

    ActiveTexture(TEXTURE0)
    BindTexture(TEXTURE_2D, tex.glid)
    Uniform1i(bufs.tex.loc_tex, 0)

    UniformMatrix4fv(bufs.tex.loc_proj, 1, false, transmute([^]f32)&proj)
    Uniform2f(bufs.tex.loc_pos, x,y)
    Uniform2f(bufs.tex.loc_size, w,h)
    Uniform4f(bufs.tex.loc_tint, f32(tint.r)/256., f32(tint.g)/256., f32(tint.b)/256., f32(tint.a)/256.)

    DrawArrays(TRIANGLES, 0, 6)

    BindVertexArray(0)
    BindTexture(TEXTURE_2D, 0)
    UseProgram(0)
}

texture_rgb_wh_f32 :: proc(tex: texture.texture, x,y,w,h: f32, tint: [3]u8) {
    texture_rgba_wh_f32(tex, x,y,w,h, [4]u8 { tint.r,tint.g,tint.b, 255 })
}

texture_rgba_f32 :: proc(tex: texture.texture, x,y: f32, tint: [4]u8) {
    texture_rgba_wh_f32(tex, x,y, f32(tex.width),f32(tex.height), tint)
}

texture_rgb_f32 :: proc(tex: texture.texture, x,y: f32, tint: [3]u8) {
    texture_rgba_f32(tex, x,y, [4]u8 { tint.r,tint.g,tint.b, 255 })
}

texture_wh_f32 :: proc(tex: texture.texture, x,y,w,h: f32) {
    texture_rgba_wh_f32(tex, x,y,w,h, [4]u8 { 255,255,255,255 })
}

texture_nwh_f32 :: proc(tex: texture.texture, x,y: f32) {
    texture_rgba_f32(tex, x,y, [4]u8 { 255,255,255,255 })
}

ftexture :: proc { texture_rgba_wh_f32, texture_rgb_wh_f32, texture_rgba_f32, texture_rgb_f32, texture_wh_f32, texture_nwh_f32 }
