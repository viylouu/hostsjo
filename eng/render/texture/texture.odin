package texture

import "../../core/error"
import "../../core/const"

import "core:os"
import "core:fmt"
import "core:strings"

import "vendor:OpenGL"
import "vendor:stb/image"

Texture :: struct {
    glid: u32,
    fbo: u32,
    width, height: i32,
    filter: Filter
    //get_at: proc(x,y: i32) -> [4]u8,
    //set_at: proc(x,y: i32, col: [4]u8),
    //apply: proc()
}

Filter :: enum {
    NEAREST,
    BILINEAR
}

set_filter :: proc(tex: ^Texture, filter: Filter) {
    using OpenGL

    BindTexture(TEXTURE_2D, tex^.glid)

    switch filter {
    case .NEAREST:
        TexParameteri(TEXTURE_2D, TEXTURE_MIN_FILTER, NEAREST)
        TexParameteri(TEXTURE_2D, TEXTURE_MAG_FILTER, NEAREST)
    case .BILINEAR:
        TexParameteri(TEXTURE_2D, TEXTURE_MIN_FILTER, LINEAR)
        TexParameteri(TEXTURE_2D, TEXTURE_MAG_FILTER, LINEAR)
    }

    BindTexture(TEXTURE_2D, 0)

    tex^.filter = filter
}

// all textures must be freed using texture.unload(tex)
create :: proc(width,height: i32) -> ^Texture {
    using OpenGL

    ipfbo: i32
    GetIntegerv(FRAMEBUFFER_BINDING, &ipfbo)
    pfbo := u32(ipfbo)

    fbo: u32
    GenFramebuffers(1, &fbo)
    BindFramebuffer(FRAMEBUFFER, fbo)

    glid: u32
    GenTextures(1, &glid)
    BindTexture(TEXTURE_2D, glid)

    TexParameteri(TEXTURE_2D, TEXTURE_WRAP_S, REPEAT)
    TexParameteri(TEXTURE_2D, TEXTURE_WRAP_T, REPEAT)
    TexParameteri(TEXTURE_2D, TEXTURE_MIN_FILTER, NEAREST)
    TexParameteri(TEXTURE_2D, TEXTURE_MAG_FILTER, NEAREST)

    TexImage2D(TEXTURE_2D, 0, RGBA, width,height, 0, RGBA, UNSIGNED_BYTE, nil)

    BindTexture(TEXTURE_2D, 0)

    FramebufferTexture2D(FRAMEBUFFER, COLOR_ATTACHMENT0, TEXTURE_2D, glid, 0)
    error.critical("framebuffer is not complete!", CheckFramebufferStatus(FRAMEBUFFER) != FRAMEBUFFER_COMPLETE)
    BindFramebuffer(FRAMEBUFFER, pfbo)

    tex := new(Texture)
    tex^.glid = glid
    tex^.fbo = fbo
    tex^.width = width
    tex^.height = height
    tex^.filter = .NEAREST

    return tex
}

// all textures must be freed using texture.unload(tex)
load :: proc(path: string) -> ^Texture {
    data, succ := os.read_entire_file(path)
    error.critical_conc([]string { "failed to open file '", path, "'!" }, !succ)

    tex := load_from_data(data)
    delete(data)

    return tex
}

// all textures must be freed using texture.unload(tex)
load_from_data :: proc(data: []u8) -> ^Texture {
    w,h,channels: i32
    img_data := image.load_from_memory(raw_data(data), cast(i32)len(data), &w,&h,&channels, 4)
    error.critical("failed to load texture!", img_data == nil)
    error.critical("texture does not have 4 channels!", channels != 4)

    defer image.image_free(img_data)

    using OpenGL

    fbo: u32
    GenFramebuffers(1, &fbo)
    BindFramebuffer(FRAMEBUFFER, fbo)

    glid: u32
    GenTextures(1, &glid)
    BindTexture(TEXTURE_2D, glid)

    TexParameteri(TEXTURE_2D, TEXTURE_WRAP_S, REPEAT)
    TexParameteri(TEXTURE_2D, TEXTURE_WRAP_T, REPEAT)
    TexParameteri(TEXTURE_2D, TEXTURE_MIN_FILTER, NEAREST)
    TexParameteri(TEXTURE_2D, TEXTURE_MAG_FILTER, NEAREST)

    TexImage2D(TEXTURE_2D, 0, RGBA, w,h, 0, RGBA, UNSIGNED_BYTE, img_data)

    BindTexture(TEXTURE_2D, 0)

    FramebufferTexture2D(FRAMEBUFFER, COLOR_ATTACHMENT0, TEXTURE_2D, glid, 0)
    error.critical("framebuffer is not complete!", CheckFramebufferStatus(FRAMEBUFFER) != FRAMEBUFFER_COMPLETE)
    BindFramebuffer(FRAMEBUFFER, 0)

    tex := new(Texture)
    tex^.glid = glid
    tex^.fbo = fbo
    tex^.width = w
    tex^.height = h
    tex^.filter = .NEAREST

    return tex
}

unload :: proc(tex: ^Texture) {
    using OpenGL
    DeleteTextures(1, &tex^.glid)
    free(tex)
}
