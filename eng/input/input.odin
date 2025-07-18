package input

import fw "vendor:glfw"

keys: [349]state
mouse:  [8]state

state :: enum {
	nhold,
	press,
	hold
}

mouse_x, mouse_y: f32
lmouse_x, lmouse_y: f32

poll :: proc(handle: fw.WindowHandle) {
	for i in 0..<349 {
        was_press := keys[i] == .press
		keys[i] = cast(state)fw.GetKey(handle, i32(i))
        if keys[i] == .press && was_press { keys[i] = .hold }
	}

	for i in 0..<8 {
        was_press := mouse[i] == .press
		mouse[i] = cast(state)fw.GetMouseButton(handle, i32(i))
        if mouse[i] == .press && was_press { mouse[i] = .hold }
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

get_mouse :: proc(but: int) -> state {
	return mouse[but]
}
