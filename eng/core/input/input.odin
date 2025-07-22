package input

import fw "vendor:glfw"

keys: [349]state
mouse:  [8]state

state :: enum {
	release,
	press,
    static,
	hold
}

mouse_x, mouse_y: f32
lmouse_x, lmouse_y: f32

poll :: proc(handle: fw.WindowHandle) {
	for i in 0..<349 {
        lstate := keys[i]
		keys[i] = cast(state)fw.GetKey(handle, i32(i))
        if keys[i] == .press && (lstate == .press || lstate == .hold)       do keys[i] = .hold
        if keys[i] == .release && (lstate == .release || lstate == .static) do keys[i] = .static
	}

	for i in 0..<8 {
        lstate := mouse[i]
		mouse[i] = cast(state)fw.GetMouseButton(handle, i32(i))
        if mouse[i] == .press && (lstate == .press || lstate == .hold)       do mouse[i] = .hold
        if mouse[i] == .release && (lstate == .release || lstate == .static) do mouse[i] = .static
    }

	mouse_x64, mouse_y64 := fw.GetCursorPos(handle)

	lmouse_x = mouse_x
	lmouse_y = mouse_y

	mouse_x = f32(mouse_x64)
	mouse_y = f32(mouse_y64)
}

get_key :: proc(key: int) -> state {
	return keys[key]
}

is_key_hold :: proc(key: int) -> bool {
    return keys[key] == .press || keys[key] == .hold
}; is_key_press :: proc(key: int) -> bool {
    return keys[key] == .press
}; is_key_release :: proc(key: int) -> bool {
    return keys[key] == .release
}

get_mouse :: proc(but: int) -> state {
	return mouse[but]
}

is_mouse_hold :: proc(but: int) -> bool {
    return mouse[but] == .press || mouse[but] == .hold
}; is_mouse_press :: proc(but: int) -> bool {
    return mouse[but] == .press
}; is_mouse_release :: proc(but: int) -> bool {
    return mouse[but] == .release
}
