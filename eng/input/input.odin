package input

import fw "vendor:glfw"

keys: [349]kstate
mouse:  [8]mstate

kstate :: enum {
	nhold,
	press,
	hold
}

mstate :: enum {
	nhold,
	hold
}

mouse_x, mouse_y: f32
lmouse_x, lmouse_y: f32

poll :: proc(handle: fw.WindowHandle) {
	for i in 0..<349 {
		keys[i] = cast(kstate)fw.GetKey(handle, i32(i))
	}

	for i in 0..<8 {
		mouse[i] = cast(mstate)fw.GetMouseButton(handle, i32(i))
	}

	mouse_x64, mouse_y64 := fw.GetCursorPos(handle)

	lmouse_x = mouse_x
	lmouse_y = mouse_y

	mouse_x = f32(mouse_x64)
	mouse_y = f32(mouse_y64)
}

get_key :: proc(key: int) -> kstate {
	return keys[key]
}

get_mouse :: proc(but: int) -> mstate {
	return mouse[but]
}
