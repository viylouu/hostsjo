package main

import "../../eng"
import "../../eng/input"
import "../../eng/draw"

    import "core:fmt"
    import "core:math"

    import "../../eng/error"
    import "../../eng/lib/OpenAL/alc"
    import "../../eng/lib/OpenAL/al"
    import wt "../../eng/lib/wav_tools"

import "vendor:glfw"

main :: proc() {
    device := alc.open_device(nil)
    error.critical("failed to open OpenAL device!", device == nil)
    defer alc.close_device(device)
    
    ctx := alc.create_context(device, nil)
    error.critical("failed to create OpenAL context!", ctx == nil)
    defer alc.destroy_context(ctx)

    alc.make_context_current(ctx)
    defer alc.make_context_current(nil)

    using eng

    init("window example",800,600)
    defer end()

    vsync(true)

    //play_sound_bad("/media/storage/projects/hostsjo/examples/sound/sound.wav")

    loop(
        proc() /* update */ {
            using input
            using glfw

            if is_key_press(KEY_ESCAPE) { stop() }

            if is_mouse_press(MOUSE_BUTTON_LEFT) { play_sound_bad("examples/sound/sound.wav") }

            stfu_all_who_need_be_stfud()
        },
        proc() /* render */ {
            using draw
            clear(0,0,0)

            frect(input.mouse_x, input.mouse_y, 32,32, [3]u8{255,0,0})
        }
    )

    stfu_all_who_need_be_stfud_and_all_who_needent_be_stfud()

    //state: i32
    //al.get_sourcei(src, al.SOURCE_STATE, &state)
    //for state == al.PLAYING { al.get_sourcei(src, al.SOURCE_STATE, &state) }
}

/*gen_sine_wave :: proc(freq, sample_rate: i32, duration: f32) -> []i16 {
    samples := i32(f32(sample_rate) * duration)
    data := make([]i16, samples)
    for i in 0..<samples {
        data[i] = i16(32760 * math.sin_f32((2. * math.PI * f32(freq) * f32(i)) / f32(sample_rate)))
    }
    return data
}*/

bufs, srcs: [dynamic]^u32

stfu_all_who_need_be_stfud :: proc() {
    for i := 0; i < len(srcs); i += 1 {
        state: i32
        al.get_sourcei(srcs[i]^, al.SOURCE_STATE, &state)

        if state != al.PLAYING {
            // shut the fuck up
            al.delete_sources(1, srcs[i])
            al.delete_buffers(1, bufs[i])

            unordered_remove(&srcs, i)
            unordered_remove(&bufs, i)
            i -= 1
        }
    }
}

stfu_all_who_need_be_stfud_and_all_who_needent_be_stfud :: proc() {
    for i in 0..<len(srcs) {
        al.source_stop(srcs[i]^)

        al.delete_sources(1, srcs[i])
        al.delete_buffers(1, bufs[i])
    }

    delete(srcs)
    delete(bufs)
}

play_sound_bad :: proc(path: string) {
    buf, src: u32
    al.gen_buffers(1, &buf)//; defer al.delete_buffers(1, &buf)
    al.gen_sources(1, &src)//; defer al.delete_sources(1, &src)

    // why the fuck is it like this
    wav_data, err := wt.wav_load_file(path, ""/*"sound.wav", "/media/storage/projects/hostsjo/examples/sound/"*/)

    // jank shit
    error.critical_conc([]string { "failed to load wav file! ", err.(wt.Error).description }, err.(wt.Error).description != "File correctly loaded.")

    channels, buf_left, buf_right := wt.get_buffer_d32_normalized(&wav_data)

    data := make([]i16, len(buf_left)*2)

    for i := 0; i < len(data); i += 2 {
        left := buf_left[i/2]
        right: f32

        if channels == 2 {
            right = buf_right[i/2]
        } else {
            right = left
        }

        left  *= 32767
        right *= 32767

        conv_left  := i16(left)
        conv_right := i16(right)

        data[i+0] = conv_left
        data[i+1] = conv_right
    }

    al.buffer_data(buf, al.FORMAT_STEREO16, &data[0], i32(len(data) * size_of(i16)), 44100)

    al.sourcei(src, al.BUFFER, i32(buf))

    al.source_play(src)

    append(&bufs, &buf)
    append(&srcs, &src)
}
