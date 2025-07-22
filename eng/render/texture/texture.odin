package texture

import "../../core/error"

import "core:strings"

import "vendor:OpenGL"
import "vendor:stb/image"

Texture :: struct {
    glid: u32,
    width, height: i32
    //get_at: proc(x,y: i32) -> [4]u8,
    //set_at: proc(x,y: i32, col: [4]u8),
    //apply: proc()
}

// all textures must be freed using texture.free(tex)
load :: proc(path: string) -> Texture {
    w,h,channels: i32
    cpath := strings.unsafe_string_to_cstring(path)
    data := image.load(cpath, &w,&h,&channels, 4)
    error.critical_conc([]string{ "failed to load texture! '", path, "'" }, data == nil)
    error.critical_conc([]string{ "texture does not have 4 channels! '", path, "'" }, channels != 4)

    defer image.image_free(data)

    using OpenGL

    glid: u32
    GenTextures(1, &glid)
    BindTexture(TEXTURE_2D, glid)

    TexParameteri(TEXTURE_2D, TEXTURE_WRAP_S, REPEAT)
    TexParameteri(TEXTURE_2D, TEXTURE_WRAP_T, REPEAT)
    TexParameteri(TEXTURE_2D, TEXTURE_MIN_FILTER, NEAREST)
    TexParameteri(TEXTURE_2D, TEXTURE_MAG_FILTER, NEAREST)

    TexImage2D(TEXTURE_2D, 0, RGBA, w,h, 0, RGBA, UNSIGNED_BYTE, data)

    BindTexture(TEXTURE_2D, 0)

    return Texture{ glid = glid, width = w, height = h }
}

unload :: proc(tex: ^Texture) {
    using OpenGL
    DeleteTextures(1, &tex^.glid)
    tex^.glid   = 0
    tex^.width  = 0
    tex^.height = 0
}
