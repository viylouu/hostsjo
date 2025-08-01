package draw

import "../texture"
import "../../core/helpioverrided"
import "../../core/error"

import "core:fmt"
import "core:math"
import "core:math/linalg/glsl"

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

clear :: proc { 
    clear_rgba_arr, 
    clear_rgba, 
    clear_rgb_arr, 
    clear_rgb,
}


to_texture :: proc(tex: ^texture.Texture, func: proc()) {
    using OpenGL

    ipfbo: i32
    GetIntegerv(FRAMEBUFFER_BINDING, &ipfbo)
    pfbo := u32(ipfbo)

    viewport: [4]i32
    GetIntegerv(VIEWPORT, raw_data(viewport[:]))
    old_w := viewport[2]
    old_h := viewport[3]

    flush()
    update(f32(tex^.width), f32(tex^.height))

    BindFramebuffer(FRAMEBUFFER, tex^.fbo)
    Viewport(0,0,tex^.width,tex^.height)

    func()
    flush()

    BindFramebuffer(FRAMEBUFFER, pfbo)

    Viewport(0,0,old_w,old_h)
    update(f32(old_w),f32(old_h))
}


flush :: proc() {
    using OpenGL

    if len(batch.data) == 0 do return

    switch batch.type {
    case .RECT:
        UseProgram(bufs.rect.prog)
        BindVertexArray(bufs.rect.vao)

        BindBuffer(SHADER_STORAGE_BUFFER, bufs.rect.ssbo)
        BufferSubData(SHADER_STORAGE_BUFFER, 0, len(batch.data) * size_of(Instance_Data), raw_data(batch.data[:]))
        BindBufferBase(SHADER_STORAGE_BUFFER, 0, bufs.rect.ssbo)
        
        UniformMatrix4fv(bufs.rect.loc_proj, 1, false, transmute([^]f32)&proj)

        DrawArrays(TRIANGLES, 0, 6 * cast(i32)len(batch.data))

        BindVertexArray(0)
        UseProgram(0)
    case .TEXTURE:
        UseProgram(bufs.tex.prog)
        BindVertexArray(bufs.tex.vao)

        BindBuffer(SHADER_STORAGE_BUFFER, bufs.tex.ssbo)
        BufferSubData(SHADER_STORAGE_BUFFER, 0, len(batch.data) * size_of(Instance_Data), raw_data(batch.data[:]))
        BindBufferBase(SHADER_STORAGE_BUFFER, 0, bufs.tex.ssbo)

        ActiveTexture(TEXTURE0)
        BindTexture(TEXTURE_2D, batch.tex^.glid)
        Uniform1i(bufs.tex.loc_tex, 0)

        UniformMatrix4fv(bufs.tex.loc_proj, 1, false, transmute([^]f32)&proj)
        
        DrawArrays(TRIANGLES, 0, 6 * cast(i32)len(batch.data))

        BindVertexArray(0)
        BindTexture(TEXTURE_2D, 0)
        UseProgram(0)
    }

    helpioverrided.hclear(&batch.data)
}


reset_transform :: proc() { using glsl ;; trans = identity(mat4) }
transform :: proc(mat: glsl.mat4) { trans *= mat }
translate :: proc(x,y: f32) { using glsl ;; trans *= mat4Translate(vec3{ x,y, 0 }) }
rotate :: proc(rads: f32) { using glsl ;; trans *= mat4Rotate(vec3{0,0,1}, rads) }
scale :: proc(x,y: f32) { using glsl ;; trans *= mat4Scale(vec3{x,y, 1}) }


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

rect :: proc { 
    rect_rgba, 
    rect_rgba_int, 
    rect_rgb, 
    rect_rgb_int,
}


rect_rgba_f32 :: proc(x,y,w,h: f32, col: [4]u8) {
    if batch.was_used {
        if batch.type != .RECT do flush()
        if len(batch.data) >= max_array_size do flush()
    } else do batch.was_used = true

    batch.type = .RECT
    append(&batch.data, Instance_Data{
        trans = trans,
        pos = glsl.vec2{x,y},
        size = glsl.vec2{w,h},
        col = glsl.vec4{f32(col.r)/256., f32(col.g)/256., f32(col.b)/256., f32(col.a)/256.}
    })
}

rect_rgb_f32 :: proc(x,y,w,h: f32, col: [3]u8) {
    rect_rgba_f32(x,y,w,h, [4]u8 { col.r,col.g,col.b, 255 })
}

frect :: proc { 
    rect_rgba_f32, 
    rect_rgb_f32,
}


texture_rgba_wh_samp :: proc(tex: ^texture.Texture, x,y,w,h: i32, samp_x,samp_y,samp_w,samp_h: i32, tint: [4]u8) {
    texture_rgba_wh_samp_f32(tex, f32(x),f32(y),f32(w),f32(h), f32(samp_x),f32(samp_y),f32(samp_w),f32(samp_h), tint)
}

texture_rgb_wh_samp :: proc(tex: ^texture.Texture, x,y,w,h: i32, samp_x,samp_y,samp_w,samp_h: i32, tint: [3]u8) {
    texture_rgba_wh_samp(tex, x,y,w,h, samp_x,samp_y,samp_w,samp_h, [4]u8 { tint.r,tint.g,tint.b, 255 })
}

texture_rgba_wh :: proc(tex: ^texture.Texture, x,y,w,h: i32, tint: [4]u8) {
    texture_rgba_wh_f32(tex, f32(x),f32(y),f32(w),f32(h), tint)
}

texture_rgb_wh :: proc(tex: ^texture.Texture, x,y,w,h: i32, tint: [3]u8) {
    texture_rgba_wh(tex, x,y,w,h, [4]u8 { tint.r,tint.g,tint.b, 255 })
}

texture_rgba_samp :: proc(tex: ^texture.Texture, x,y: i32, samp_x,samp_y,samp_w,samp_h: i32, tint: [4]u8) {
    texture_rgba_wh_samp(tex, x,y, samp_w,samp_h, samp_x,samp_y,samp_w,samp_h, tint)
}

texture_rgb_samp :: proc(tex: ^texture.Texture, x,y: i32, samp_x,samp_y,samp_w,samp_h: i32, tint: [3]u8) {
    texture_rgb_wh_samp(tex, x,y, samp_w,samp_h, samp_x,samp_y,samp_w,samp_h, tint)
}

texture_rgba :: proc(tex: ^texture.Texture, x,y: i32, tint: [4]u8) {
    texture_rgba_wh(tex, x,y, tex.width,tex.height, tint)
}

texture_rgb :: proc(tex: ^texture.Texture, x,y: i32, tint: [3]u8) {
    texture_rgb_wh(tex, x,y, tex.width,tex.height, tint)
}

texture_wh_samp :: proc(tex: ^texture.Texture, x,y,w,h: i32, samp_x,samp_y,samp_w,samp_h: i32) {
    texture_rgba_wh_samp(tex, x,y,w,h, samp_x,samp_y,samp_w,samp_h, [4]u8 { 255,255,255,255 })
}

texture_nwh_samp :: proc(tex: ^texture.Texture, x,y: i32, samp_x,samp_y,samp_w,samp_h: i32) {
    texture_rgba_samp(tex, x,y, samp_x,samp_y,samp_w,samp_h, [4]u8 { 255,255,255,255 })
}

texture_wh :: proc(tex: ^texture.Texture, x,y,w,h: i32) {
    texture_rgba_wh(tex, x,y,w,h, [4]u8 { 255,255,255,255 })
}

texture_nwh :: proc(tex: ^texture.Texture, x,y: i32) {
    texture_rgba(tex, x,y, [4]u8 { 255,255,255,255 })
}

texture_rgba_wh_samp_int :: proc(tex: ^texture.Texture, x,y,w,h: int, samp_x,samp_y,samp_w,samp_h: int, tint: [4]u8) {
    texture_rgba_wh_samp_f32(tex, f32(x),f32(y),f32(w),f32(h), f32(samp_x),f32(samp_y),f32(samp_w),f32(samp_h), tint)
}

texture_rgb_wh_samp_int :: proc(tex: ^texture.Texture, x,y,w,h: int, samp_x,samp_y,samp_w,samp_h: int, tint: [3]u8) {
    texture_rgba_wh_samp_int(tex, x,y,w,h, samp_x,samp_y,samp_w,samp_h, [4]u8 { tint.r,tint.g,tint.b, 255 })
}

texture_rgba_wh_int :: proc(tex: ^texture.Texture, x,y,w,h: int, tint: [4]u8) {
    texture_rgba_wh_f32(tex, f32(x),f32(y),f32(w),f32(h), tint)
}

texture_rgb_wh_int :: proc(tex: ^texture.Texture, x,y,w,h: int, tint: [3]u8) {
    texture_rgba_wh_int(tex, x,y,w,h, [4]u8 { tint.r,tint.g,tint.b, 255 })
}

texture_rgba_samp_int :: proc(tex: ^texture.Texture, x,y: int, samp_x,samp_y,samp_w,samp_h: int, tint: [4]u8) {
    texture_rgba_wh_samp_int(tex, x,y, samp_w,samp_h, samp_x,samp_y,samp_w,samp_h, tint)
}

texture_rgb_samp_int :: proc(tex: ^texture.Texture, x,y: int, samp_x,samp_y,samp_w,samp_h: int, tint: [3]u8) {
    texture_rgb_wh_samp_int(tex, x,y, samp_w,samp_h, samp_x,samp_y,samp_w,samp_h, tint)
}

texture_rgba_int :: proc(tex: ^texture.Texture, x,y: int, tint: [4]u8) {
    texture_rgba_wh_int(tex, x,y, int(tex.width),int(tex.height), tint)
}

texture_rgb_int :: proc(tex: ^texture.Texture, x,y: int, tint: [3]u8) {
    texture_rgb_wh_int(tex, x,y, int(tex.width),int(tex.height), tint)
}

texture_wh_samp_int :: proc(tex: ^texture.Texture, x,y,w,h: int, samp_x,samp_y,samp_w,samp_h: int) {
    texture_rgba_wh_samp_int(tex, x,y,w,h, samp_x,samp_y,samp_w,samp_h, [4]u8 { 255,255,255,255 })
}

texture_nwh_samp_int :: proc(tex: ^texture.Texture, x,y: int, samp_x,samp_y,samp_w,samp_h: int) {
    texture_rgba_samp_int(tex, x,y, samp_x,samp_y,samp_w,samp_h, [4]u8 { 255,255,255,255 })
}

texture_wh_int :: proc(tex: ^texture.Texture, x,y,w,h: int) {
    texture_rgba_wh_int(tex, x,y,w,h, [4]u8 { 255,255,255,255 })
}

texture_nwh_int :: proc(tex: ^texture.Texture, x,y: int) {
    texture_rgba_int(tex, x,y, [4]u8 { 255,255,255,255 })
}

texture :: proc { 
    texture_rgba_wh_samp,
    texture_rgb_wh_samp,
    texture_rgba_wh, 
    texture_rgb_wh, 
    texture_rgba, 
    texture_rgb, 
    texture_wh_samp,
    texture_nwh_samp,
    texture_wh, 
    texture_nwh,
    texture_rgba_wh_samp_int,
    texture_rgb_wh_samp_int,
    texture_rgba_wh_int, 
    texture_rgb_wh_int, 
    texture_rgba_int,
    texture_rgb_int,
    texture_wh_samp_int,
    texture_nwh_samp_int,
    texture_wh_int, 
    texture_nwh_int,
}

texture_rgba_wh_samp_f32 :: proc(tex: ^texture.Texture, x,y,w,h: f32, samp_x,samp_y,samp_w,samp_h: f32, tint: [4]u8) {
    if batch.was_used {
        if batch.type != .TEXTURE || batch.tex != tex do flush()
        if len(batch.data) >= max_array_size do flush()
    } else do batch.was_used = true

    batch.type = .TEXTURE
    batch.tex = tex
    append(&batch.data, Instance_Data{
        trans = trans,
        pos = glsl.vec2{x,y},
        size = glsl.vec2{w,h},
        col = glsl.vec4{f32(tint.r)/256., f32(tint.g)/256., f32(tint.b)/256., f32(tint.a)/256.},
        samp_pos = glsl.vec2{samp_x/f32(tex.width),samp_y/f32(tex.height)},
        samp_size = glsl.vec2{samp_w/f32(tex.width),samp_h/f32(tex.height)}
    })
}

texture_rgb_wh_samp_f32 :: proc(tex: ^texture.Texture, x,y,w,h: f32, samp_x,samp_y,samp_w,samp_h: f32, tint: [3]u8) {
    texture_rgba_wh_samp_f32(tex,x,y,w,h,samp_x,samp_y,samp_w,samp_h, [4]u8 { tint.r,tint.g,tint.b, 255 })
}

texture_rgba_wh_f32 :: proc(tex: ^texture.Texture, x,y,w,h: f32, tint: [4]u8) {
    texture_rgba_wh_samp_f32(tex, x,y,w,h, 0,0,f32(tex.width),f32(tex.height), tint)
}

texture_rgb_wh_f32 :: proc(tex: ^texture.Texture, x,y,w,h: f32, tint: [3]u8) {
    texture_rgba_wh_f32(tex, x,y,w,h, [4]u8 { tint.r,tint.g,tint.b, 255 })
}

texture_rgba_samp_f32 :: proc(tex: ^texture.Texture, x,y: f32, samp_x,samp_y,samp_w,samp_h: f32, tint: [4]u8) {
    texture_rgba_wh_samp_f32(tex, x,y, samp_w,samp_h, samp_x,samp_y,samp_w,samp_h, tint)
}

texture_rgb_samp_f32 :: proc(tex: ^texture.Texture, x,y: f32, samp_x,samp_y,samp_w,samp_h: f32, tint: [3]u8) {
    texture_rgb_wh_samp_f32(tex, x,y, samp_w,samp_h, samp_x,samp_y,samp_w,samp_h, tint)
}

texture_rgba_f32 :: proc(tex: ^texture.Texture, x,y: f32, tint: [4]u8) {
    texture_rgba_wh_f32(tex, x,y, f32(tex.width),f32(tex.height), tint)
}

texture_rgb_f32 :: proc(tex: ^texture.Texture, x,y: f32, tint: [3]u8) {
    texture_rgba_f32(tex, x,y, [4]u8 { tint.r,tint.g,tint.b, 255 })
}

texture_wh_samp_f32 :: proc(tex: ^texture.Texture, x,y,w,h: f32, samp_x,samp_y,samp_w,samp_h: f32) {
    texture_rgba_wh_samp_f32(tex, x,y,w,h, samp_x,samp_y,samp_w,samp_h, [4]u8 { 255,255,255,255 })
}

texture_nwh_samp_f32 :: proc(tex: ^texture.Texture, x,y: f32, samp_x,samp_y,samp_w,samp_h: f32) {
    texture_wh_samp_f32(tex, x,y, samp_w,samp_h, samp_x,samp_y,samp_w,samp_h)
}

texture_wh_f32 :: proc(tex: ^texture.Texture, x,y,w,h: f32) {
    texture_rgba_wh_f32(tex, x,y,w,h, [4]u8 { 255,255,255,255 })
}

texture_nwh_f32 :: proc(tex: ^texture.Texture, x,y: f32) {
    texture_rgba_f32(tex, x,y, [4]u8 { 255,255,255,255 })
}

ftexture :: proc { 
    texture_rgba_wh_samp_f32, 
    texture_rgb_wh_samp_f32,
    texture_rgba_wh_f32, 
    texture_rgb_wh_f32, 
    texture_rgba_samp_f32,
    texture_rgb_samp_f32,
    texture_rgba_f32, 
    texture_rgb_f32, 
    texture_wh_samp_f32,
    texture_nwh_samp_f32,
    texture_wh_f32, 
    texture_nwh_f32,
}
