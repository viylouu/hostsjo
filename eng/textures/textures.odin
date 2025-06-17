package textures

import gl "vendor:OpenGL"
import stbi "vendor:stb/image"

load_texture :: proc(path: cstring, tex_num: u32 = gl.TEXTURE0) -> u32 {
    w,h,channels: i32    
    tex_data := stbi.load(path, &w,&h,&channels, 4)
    
    tex: u32
    gl.GenTextures(1, &tex)
    gl.ActiveTexture(tex_num)
    gl.BindTexture(gl.TEXTURE_2D, tex)

    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT);
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT);

    gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGBA, w,h, 0, gl.RGBA, gl.UNSIGNED_BYTE, &tex_data[0])

    stbi.image_free(tex_data)

    return tex
}

