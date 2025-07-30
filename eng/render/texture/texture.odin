package texture

import "../../core/error"

import "core:os"
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

    glid: u32
    GenTextures(1, &glid)
    BindTexture(TEXTURE_2D, glid)

    TexParameteri(TEXTURE_2D, TEXTURE_WRAP_S, REPEAT)
    TexParameteri(TEXTURE_2D, TEXTURE_WRAP_T, REPEAT)
    TexParameteri(TEXTURE_2D, TEXTURE_MIN_FILTER, NEAREST)
    TexParameteri(TEXTURE_2D, TEXTURE_MAG_FILTER, NEAREST)

    TexImage2D(TEXTURE_2D, 0, RGBA, w,h, 0, RGBA, UNSIGNED_BYTE, img_data)

    BindTexture(TEXTURE_2D, 0)

    tex := new(Texture)
    tex^.glid = glid
    tex^.width = w
    tex^.height = h

    return tex
}

unload :: proc(tex: ^Texture) {
    using OpenGL
    DeleteTextures(1, &tex^.glid)
    free(tex)
}
