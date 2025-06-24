package shaders

import "core:fmt"
import "core:os"
import "core:strings"

import "../error"

import gl "vendor:OpenGL"

__stuff_to_free: [dynamic]^cstring

// note that errors, when using includes, the line number is offset by the total line count of the included files in the order given, so just subtract the total line count of them and you can get the actual line number
load_program :: proc(vertex_path: string, fragment_path: string, vertex_include: []string = nil, fragment_include: []string = nil) -> u32 {
    vsh := load_shader(gl.VERTEX_SHADER,   vertex_path,   vertex_include)
    fsh := load_shader(gl.FRAGMENT_SHADER, fragment_path, fragment_include)

    s_succ: i32

    s_prog: u32
    s_prog = gl.CreateProgram()

    gl.AttachShader(s_prog, vsh)
    gl.AttachShader(s_prog, fsh)
    gl.LinkProgram(s_prog)

    gl.DeleteShader(vsh)
    gl.DeleteShader(fsh)

    gl.GetProgramiv(s_prog, gl.LINK_STATUS, &s_succ)
    if !bool(s_succ) { // this could be err.critical_proc_conc but its too long
        fmt.eprintln("failed to link shader program!")
        log: [512]u8
        gl.GetProgramInfoLog(s_prog, 512, nil, &log[0])
        error.critical(string(log[:]))
    }

    return s_prog
}

// note that errors, when using includes, the line number is offset by the total line count of the included files in the order given, so just subtract the total line count of them and you can get the actual line number
load_shader :: proc(type: u32, path: string, include: []string = nil) -> u32 {
    src := load_shader_src(path, include)

    shad: u32
    shad = gl.CreateShader(type)
    gl.ShaderSource(shad, 1, &src, nil)
    gl.CompileShader(shad)

    succ: i32
    gl.GetShaderiv(shad, gl.COMPILE_STATUS, &succ)
    if !bool(succ) { // this could be err.critical_proc_conc but its too long
        fmt.eprintf("shader compilation failed! (%s)\n", path)
        log: [512]u8
        gl.GetShaderInfoLog(shad, 512, nil, &log[0])
        error.critical(string(log[:]))
    }

    return shad
}

load_shader_src :: proc(path: string, includes: []string = nil) -> cstring {
    data, ok := os.read_entire_file(path)
    error.critical_conc([]string { "failed to load shader! (", path, ")" }, !ok)

    defer delete(data)

    str := string(data)

    if includes != nil {
        ver := ""
        arrostr: [dynamic]string

        for line in strings.split_lines_iterator(&str) {
            if ver != "" {
                append(&arrostr, line)
                append(&arrostr, "\n")
                continue
            }   ver = line
        }

        ostr := strings.concatenate(arrostr[:])

        toconc: [dynamic]string

        for i in 0..<len(includes) {
            ssrc := load_shader_src(includes[i])
            append(&toconc, cast(string)ssrc)
            //free(&ssrc)
        }

        toincl := strings.concatenate(toconc[:])

        str = strings.concatenate([]string {ver, toincl, ostr})

        free(&ostr)
        free(&toincl)
    }

    res := strings.clone_to_cstring(str)
    append(&__stuff_to_free, &res)

    if includes != nil { free(&str) }

    return res
}
