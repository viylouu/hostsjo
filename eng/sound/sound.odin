package sound

import "core:fmt"
import "core:math"
import "core:strings"

import "../core/error"
import "../lib/OpenAL/alc"
import "../lib/OpenAL/al"
import "../lib/dr_libs/dr_wav"
import "../lib/dr_libs/dr_flac"
import "../lib/dr_libs/dr_mp3"

sounds: [dynamic]^Sound_Inst

Sound :: struct {
    data: []i16,
    is_stereo: bool,
    al_buf: u32,
    pitch: f32,
    volume: f32,
    sample_rate: u32
}

Sound_Inst :: struct {
    al_src: u32,
    looping: bool,
    sound: ^Sound
}

device: alc.Device
ctx:    alc.Context

init :: proc() {
    device = alc.open_device(nil)
    error.critical("failed to open OpenAL device!", device == nil)
    
    ctx = alc.create_context(device, nil)
    error.critical("failed to create OpenAL context!", ctx == nil)

    alc.make_context_current(ctx)
}

end :: proc() {
    alc.make_context_current(nil)
    alc.destroy_context(ctx)
    alc.close_device(device)
}

load :: proc(path: string) -> Sound {
    using dr_wav
    using dr_mp3
    using dr_flac

    samples: [^]f32
    total_samples: u64
    is_stereo: bool
    sample_rate: u32

    if strings.has_suffix(path, ".wav") {
        wav: drwav
        error.critical("failed to open file!", drwav_init_file(&wav, strings.unsafe_string_to_cstring(path), nil) == 0)

        total_samples = wav.totalPCMFrameCount * u64(wav.channels)
        samples = make([^]f32, total_samples)
        sample_rate = wav.sampleRate

        drwav_read_pcm_frames_f32(&wav, wav.totalPCMFrameCount, samples)

        is_stereo = wav.channels == 2

        drwav_uninit(&wav)
    } else if strings.has_suffix(path, ".flac") {
        // why is this one different ????
        flac := drflac_open_file(strings.unsafe_string_to_cstring(path), nil)
        error.critical("failed to open file!", flac == nil)

        total_samples = flac^.totalPCMFrameCount * u64(flac^.channels)
        samples = make([^]f32, total_samples)
        sample_rate = flac^.sampleRate

        drflac_read_pcm_frames_f32(flac, flac^.totalPCMFrameCount, samples)

        is_stereo = flac^.channels == 2

        drflac_close(flac)
    } else if strings.has_suffix(path, ".mp3") {
        mp3: drmp3
        error.critical("failed to open file!", drmp3_init_file(&mp3, strings.unsafe_string_to_cstring(path), nil) == 0)

        total_samples = mp3.totalPCMFrameCount * u64(mp3.channels)
        samples = make([^]f32, total_samples)
        sample_rate = mp3.sampleRate

        drmp3_read_pcm_frames_f32(&mp3, mp3.totalPCMFrameCount, samples)

        is_stereo = mp3.channels == 2

        drmp3_uninit(&mp3)
    } else do error.critical_conc([]string { "unsupported audio file format! '", path, "'" })

    data := make([]i16, total_samples)

    for i in 0..<len(data) {
        raw_float := samples[i]
        conv_float := raw_float * 32767
        data[i] = i16(conv_float)
    }

    buf: u32
    al.gen_buffers(1, &buf)

    format := is_stereo? al.FORMAT_STEREO16 : al.FORMAT_MONO16
    al.buffer_data(buf, format, &data[0], i32(len(data) * size_of(i16)), i32(sample_rate))

    output := Sound {
        data = data,
        is_stereo = is_stereo,
        al_buf = buf,
        volume = 1,
        pitch = 1,
        sample_rate = sample_rate
    }

    return output
}

unload :: proc(sound: ^Sound) {
    al.delete_buffers(1, &sound^.al_buf)
    delete(sound^.data)
}

update :: proc() {
    for i := 0; i < len(sounds); i += 1 {
        this := sounds[i]

        state: i32
        al.get_sourcei(this^.al_src, al.SOURCE_STATE, &state)

        al.sourcef(this^.al_src, al.GAIN, this^.sound^.volume)
        al.sourcef(this^.al_src, al.PITCH, this^.sound^.pitch)

        if state != al.PLAYING {
            // shut the fuck up
            al.source_stop(this^.al_src)

            if !this^.looping {
                al.delete_sources(1, &this^.al_src)

                unordered_remove(&sounds, i)
                i -= 1
            } else do al.source_play(this^.al_src)
        }
    }
}

stfu :: proc() {
    for i in 0..<len(sounds) {
        al.source_stop(sounds[i]^.al_src)

        al.delete_sources(1, &sounds[i]^.al_src)
    }
}

play :: proc(sound: ^Sound) {
    src: u32
    al.gen_sources(1, &src)
    al.sourcei(src, al.BUFFER, i32(sound^.al_buf))
    al.source_play(src)

    inst := new(Sound_Inst)
    inst^.al_src = src
    inst^.looping = false
    inst^.sound = sound

    append(&sounds, inst)
}
