package shader

import "../../core/error"

import "core:os"
import "core:fmt"
import "core:strings"

import gl "vendor:OpenGL"

// note that errors, when using includes, the line number is offset by the total line count of the included files in the order given, so just subtract the total line count of them and you can get the actual line number
load_program :: proc(vertex_path, fragment_path: string, vertex_include: []string = nil, fragment_include: []string = nil) -> u32 {
    vsrc := load_shader_src(vertex_path, vertex_include)
    fsrc := load_shader_src(fragment_path, fragment_include)
    
    defer delete(vsrc)
    defer delete(fsrc)

    return load_program_from_src(&vsrc, &fsrc)
}

// this will not delete your shaders
compile_program :: proc (shaders: []u32) -> u32 {
    s_succ: i32

    s_prog: u32
    s_prog = gl.CreateProgram()

    for sh in shaders do gl.AttachShader(s_prog, sh)
    gl.LinkProgram(s_prog)

    gl.GetProgramiv(s_prog, gl.LINK_STATUS, &s_succ)
    if !bool(s_succ) {
        fmt.eprintln("failed to link shader program!")
        log: [512]u8
        gl.GetProgramInfoLog(s_prog, 512, nil, &log[0])
        error.critical(string(log[:]))
    }

    return s_prog

}

// this will not delete your source code, so you have to do that yourself bozo, also haha cstring
load_program_from_src :: proc(vertex_source, fragment_source: ^cstring) -> u32 {
    vsh := load_shader_from_src(gl.VERTEX_SHADER,   vertex_source)
    fsh := load_shader_from_src(gl.FRAGMENT_SHADER, fragment_source)

    s_prog := compile_program([]u32{vsh, fsh})

    gl.DeleteShader(vsh)
    gl.DeleteShader(fsh)

    return s_prog
}

// note that errors, when using includes, the line number is offset by the total line count of the included files in the order given, so just subtract the total line count of them and you can get the actual line number
load_shader :: proc(type: u32, path: string, include: []string = nil) -> u32 {
    src := load_shader_src(path, include)
    defer delete(src)
    return load_shader_from_src(type, &src)
}

// this will not delete your source code, so you have to do that yourself bozo, also haha cstring
load_shader_from_src :: proc(type: u32, source: ^cstring) -> u32 {
    shad: u32
    shad = gl.CreateShader(type)
    gl.ShaderSource(shad, 1, source, nil)
    gl.CompileShader(shad)

    succ: i32
    gl.GetShaderiv(shad, gl.COMPILE_STATUS, &succ)
    if !bool(succ) {
        fmt.eprintln("shader compilation failed!")
        log: [512]u8
        gl.GetShaderInfoLog(shad, 512, nil, &log[0])
        error.critical(string(log[:]))
    }

    return shad
}

// output string must be deleted at some point
load_shader_src :: proc(path: string, includes: []string = nil) -> cstring {
    data, ok := os.read_entire_file(path)
    error.critical_conc([]string { "failed to load shader! (", path, ")" }, !ok)

    defer delete(data)

    str := string(data)

    if includes != nil {
        ver := ""
        no_ver, _ := strings.builder_make()

        for line in strings.split_lines_iterator(&str) {
            if ver != "" {
                strings.write_string(&no_ver, line)
                strings.write_rune(&no_ver, '\n')
                continue
            }   ver = line
        }

        nv := strings.clone(strings.to_string(no_ver))

        to_incl := strings.builder_make()

        for i in 0..<len(includes) {
            ssrc := load_shader_src(includes[i])
            strings.write_string(&to_incl, cast(string)ssrc)
            delete(ssrc)
        }

        ti := strings.clone(strings.to_string(to_incl))

        str = strings.concatenate([]string {ver, ti, nv})

        delete(nv)
        delete(ti)
        strings.builder_destroy(&no_ver)
        strings.builder_destroy(&to_incl)
    }

    res := strings.clone_to_cstring(str)

    if includes != nil { delete(str) }

    return res
}
