package error

import "core:fmt"
import "core:os"

critical :: proc(do_if: bool, msg: string) {
    if !do_if { return }
    fmt.eprintln(msg)
    os.exit(1)
}
