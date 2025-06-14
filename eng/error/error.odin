package error

import "core:fmt"
import "core:os"
import "core:strings"

critical :: proc(msg: string, do_if: bool = true) {
    if !do_if { return }
    fmt.eprintln(msg)
    os.exit(1)
}

critical_conc :: proc(msg: []string, do_if: bool = true) {
    critical(strings.concatenate(msg), do_if)
}

critical_proc :: proc(msg: proc() -> string, do_if: bool = true) {
    if !do_if { return }
    fmt.eprintln(msg())
    os.exit(1)
}

critical_proc_conc :: proc(msg: proc() -> []string, do_if: bool = true) {
    if !do_if { return }
    fmt.eprintln(strings.concatenate(msg()))
    os.exit(1)
}
