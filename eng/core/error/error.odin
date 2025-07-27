package error

import "core:os"
import "core:fmt"
import "core:strings"

import "vendor:OpenGL"

critical :: proc(msg: string, do_if: bool = true) {
    if !do_if do return
    fmt.eprintln(msg)
    os.exit(1)
}

critical_conc :: proc(msg: []string, do_if: bool = true) {
    if !do_if do return
    critical(strings.concatenate(msg))
}

critical_proc :: proc(msg: proc() -> string, do_if: bool = true) {
    if !do_if do return
    critical(msg())
}

critical_proc_conc :: proc(msg: proc() -> []string, do_if: bool = true) {
    if !do_if do return
    critical(strings.concatenate(msg()))
}
