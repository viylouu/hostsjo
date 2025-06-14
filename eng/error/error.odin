package error

import "core:fmt"
import "core:os"
import "core:strings"

critical :: proc(do_if: bool = true, msg: string) {
    if !do_if { return }
    fmt.eprintln(msg)
    os.exit(1)
}

critical_conc :: proc(do_if: bool = true, msg: []string) {
    critical(do_if, strings.concatenate(msg))
}

critical_proc :: proc(do_if: bool = true, msg: proc() -> string) {
    if !do_if { return }
    fmt.eprintln(msg())
    os.exit(1)
}

critical_proc_conc :: proc(do_if: bool = true, msg: proc() -> []string) {
    if !do_if { return }
    fmt.eprintln(strings.concatenate(msg()))
    os.exit(1)
}
