package input

import "core:fmt"
import "core:math"

import "vendor:glfw"

keys:    [349]state
mouse:     [8]state

buttons: [16][15]state
axes:     [16][6]f32

state :: enum {
	RELEASE,
	PRESS,
    STATIC,
	HOLD
}

sided_selection :: enum {
    LEFT,
    RIGHT
}

mouse_x, mouse_y: f32
lmouse_x, lmouse_y: f32

has_controller: bool
controller: [16]bool
controller_name: [16]string

load_mappings :: proc() {
    using glfw

    maps := #load("../../../data/misc/eng/gamecontrollerdb.txt", cstring)
    UpdateGamepadMappings(maps)
}

poll :: proc(handle: glfw.WindowHandle) {
    using glfw

	for i in 0..<349 {
        lstate := keys[i]
		keys[i] = cast(state)GetKey(handle, i32(i))
        if keys[i] == .PRESS && (lstate == .PRESS || lstate == .HOLD)       do keys[i] = .HOLD
        if keys[i] == .RELEASE && (lstate == .RELEASE || lstate == .STATIC) do keys[i] = .STATIC
	}

	for i in 0..<8 {
        lstate := mouse[i]
		mouse[i] = cast(state)GetMouseButton(handle, i32(i))
        if mouse[i] == .PRESS && (lstate == .PRESS || lstate == .HOLD)       do mouse[i] = .HOLD
        if mouse[i] == .RELEASE && (lstate == .RELEASE || lstate == .STATIC) do mouse[i] = .STATIC
    }

    has_controller = false

    for j in 0..<16 {
        controller_name[j] = GetJoystickName(i32(j))
        controller[j] = JoystickIsGamepad(i32(j)) == true
        if !controller[j] do continue
        has_controller = true

        gps: GamepadState
        if !GetGamepadState(i32(j), &gps) do continue

        for i in 0..<15 {
            lstate := buttons[j][i]
            buttons[j][i] = cast(state)gps.buttons[i]
            if buttons[j][i] == .PRESS && (lstate == .PRESS || lstate == .HOLD)       do buttons[j][i] = .HOLD
            if buttons[j][i] == .RELEASE && (lstate == .RELEASE || lstate == .STATIC) do buttons[j][i] = .STATIC
        }

        for i in 0..<6 do axes[j][i] = gps.axes[i]
    }

	mouse_x64, mouse_y64 := GetCursorPos(handle)

	lmouse_x = mouse_x
	lmouse_y = mouse_y

	mouse_x = f32(mouse_x64)
	mouse_y = f32(mouse_y64)
}

get_key :: proc(key: int) -> state {
	return keys[key]
}

is_key_hold :: proc(key: int) -> bool {
    return keys[key] == .PRESS || keys[key] == .HOLD
}; is_key_press :: proc(key: int) -> bool {
    return keys[key] == .PRESS
}; is_key_release :: proc(key: int) -> bool {
    return keys[key] == .RELEASE
}

get_mouse :: proc(but: int) -> state {
	return mouse[but]
}

is_mouse_hold :: proc(but: int) -> bool {
    return mouse[but] == .PRESS || mouse[but] == .HOLD
}; is_mouse_press :: proc(but: int) -> bool {
    return mouse[but] == .PRESS
}; is_mouse_release :: proc(but: int) -> bool {
    return mouse[but] == .RELEASE
}

get_button :: proc(but: int, cont: int = 0) -> state {
    return buttons[cont][but]
}

is_button_hold :: proc(but: int, cont: int = 0) -> bool {
    return buttons[cont][but] == .PRESS || buttons[cont][but] == .HOLD
}; is_button_press :: proc(but: int, cont: int = 0) -> bool {
    return buttons[cont][but] == .PRESS
}; is_button_release :: proc(but: int, cont: int = 0) -> bool {
    return buttons[cont][but] == .RELEASE
}

get_joystick :: proc(joy: sided_selection, cont: int = 0) -> [2]f32 {
    using glfw
    if !controller[cont] do return [2]f32{0,0}
    val: [2]f32
    switch joy {
        case .LEFT: val = [2]f32{ axes[cont][GAMEPAD_AXIS_LEFT_X], axes[cont][GAMEPAD_AXIS_LEFT_Y] } // left
        case .RIGHT: val = [2]f32{ axes[cont][GAMEPAD_AXIS_RIGHT_X], axes[cont][GAMEPAD_AXIS_RIGHT_Y] } // right
    }
    if math.abs(val.x) <= 0.05 && math.abs(val.y) <= 0.05 do return [2]f32{0,0}
    return val
}

get_trigger :: proc(trig: sided_selection, cont: int = 0) -> f32 {
    using glfw
    if !controller[cont] do return 0
    val: f32
    switch trig {
        case .LEFT: val = axes[cont][GAMEPAD_AXIS_LEFT_TRIGGER]
        case .RIGHT: val = axes[cont][GAMEPAD_AXIS_RIGHT_TRIGGER]
    }
    if val <= 0.05 do return 0
    return val
}
