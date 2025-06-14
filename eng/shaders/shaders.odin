package shaders

import "core:fmt"
import "core:os"
import "core:strings"

import gl "vendor:OpenGL"
import fw "vendor:glfw"

// note that errors, when using includes, the line number is offset by the total line count of the included files in the order given, so just subtract the total line count of them and you can get the actual line number
load_shader :: proc(type: u32, path: string, include: []string = nil) -> (u32, bool) {
    src, src_succ := load_shader_src(path, include)
    if !src_succ { fmt.eprintf("failed to load shader source! (%s)\n", path); return 0, false }

    shad: u32
    shad = gl.CreateShader(type)
    gl.ShaderSource(shad, 1, &src, nil)
    gl.CompileShader(shad)

    succ: i32
    gl.GetShaderiv(shad, gl.COMPILE_STATUS, &succ)
    if !bool(succ) {
        fmt.eprintf("shader compilation failed! (%s)\n", path)
        log: [512]u8
        gl.GetShaderInfoLog(shad, 512, nil, &log[0])
        fmt.eprintln(string(log[:]))
        return 0, false
    }

    return shad, true
}

load_shader_src :: proc(path: string, includes: []string = nil) -> (cstring, bool) {
    data, ok := os.read_entire_file(path)
    if !ok {
        fmt.eprintf("failed to load shader! (%s)", path)
        return "", false
    } defer delete(data)

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
            ssrc, s_succ := load_shader_src(includes[i])
            if !s_succ { fmt.eprintf("failed to load include shader! (%s)\n", includes[i]); return "", false }
            append(&toconc, cast(string)ssrc)
        }

        toincl := strings.concatenate(toconc[:])

        str = strings.concatenate([]string {ver, toincl, ostr})
    }

    return strings.clone_to_cstring(str), true
}
