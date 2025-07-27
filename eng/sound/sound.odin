package sound

import "../core/error"

import "core:os"
import "core:fmt"
import "core:math"
import "core:strings"

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
    global_pitch: f32,
    global_volume: f32,
    loop: bool,
    playing: bool,
    channel: ^Mixer,
    sample_rate: u32,
}

Sound_Inst :: struct {
    al_src: u32,
    pitch: f32,
    volume: f32,
    sound: ^Sound
}

Mixer :: struct {
    volume: f32,
    pitch: f32,
    parent: ^Mixer // LINKED LIST!!!!! never in my life did i think i would use this but its way more convinient here
}

File_Type :: enum {
    WAV, FLAC, MP3
}

master := Mixer {
    volume = 1,
    pitch  = 1,
    parent = nil
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

load_from_data :: proc(data: ^[]u8, type: File_Type) -> Sound {
    using dr_wav
    using dr_mp3
    using dr_flac

    samples: [^]f32
    total_samples: u64
    is_stereo: bool
    sample_rate: u32

    data_size :uint= len(data^)

    switch type {
    case .WAV:
        wav: drwav
        error.critical("failed to load audio data!", drwav_init_memory(&wav, raw_data(data[:]), data_size, nil) == 0)

        total_samples = wav.totalPCMFrameCount * u64(wav.channels)
        samples = make([^]f32, total_samples)
        sample_rate = wav.sampleRate

        drwav_read_pcm_frames_f32(&wav, wav.totalPCMFrameCount, samples)

        is_stereo = wav.channels == 2

        drwav_uninit(&wav)

    case .FLAC:
        flac := drflac_open_memory(raw_data(data[:]), data_size, nil)
        error.critical("failed to load audio data!", flac == nil)

        total_samples = flac^.totalPCMFrameCount * u64(flac^.channels)
        samples = make([^]f32, total_samples)
        sample_rate = flac^.sampleRate

        drflac_read_pcm_frames_f32(flac, flac^.totalPCMFrameCount, samples)

        is_stereo = flac^.channels == 2

        drflac_close(flac)

    case .MP3:
        mp3: drmp3
        error.critical("failed to load audio data!", drmp3_init_memory(&mp3, raw_data(data[:]), data_size, nil) == 0)

        total_samples = mp3.totalPCMFrameCount * u64(mp3.channels)
        samples = make([^]f32, total_samples)
        sample_rate = mp3.sampleRate

        drmp3_read_pcm_frames_f32(&mp3, mp3.totalPCMFrameCount, samples)

        is_stereo = mp3.channels == 2

        drmp3_uninit(&mp3)
    }

    dec := make([]i16, total_samples)

    for i in 0..<len(dec) {
        raw_float := samples[i]
        conv_float := raw_float * 32767
        dec[i] = i16(conv_float)
    }

    buf: u32
    al.gen_buffers(1, &buf)

    format := is_stereo? al.FORMAT_STEREO16 : al.FORMAT_MONO16
    al.buffer_data(buf, format, &dec[0], i32(len(dec) * size_of(i16)), i32(sample_rate))

    output := Sound {
        data = dec,
        is_stereo = is_stereo,
        al_buf = buf,
        global_pitch = 1,
        global_volume = 1,
        channel = &master,
        playing = false,
        loop = false,
        sample_rate = sample_rate
    }

    return output
}

load :: proc(path: string) -> Sound {
    type: File_Type
    if      strings.has_suffix(path, ".wav")  do type = .WAV
    else if strings.has_suffix(path, ".mp3")  do type = .MP3
    else if strings.has_suffix(path, ".flac") do type = .FLAC
    else do error.critical_conc([]string { "unrecognized file type '", path, "'!" })

    data, succ := os.read_entire_file(path)
    error.critical_conc([]string { "failed to read file data '", path, "'!" }, !succ)
    
    snd := load_from_data(&data, type)
    delete(data)

    return snd
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

        pitch  := this^.pitch
        volume := this^.volume

        pitch  *= this^.sound^.global_pitch
        volume *= this^.sound^.global_volume

        channel := this^.sound^.channel
        for channel != nil {
            pitch  *= channel^.pitch
            volume *= channel^.volume
            channel = channel^.parent
        }

        al.sourcef(this^.al_src, al.GAIN,  volume)
        al.sourcef(this^.al_src, al.PITCH, pitch)

        if state != al.PLAYING {
            // shut the fuck up
            al.source_stop(this^.al_src)

            if !this^.sound^.loop || !this^.sound^.playing {
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

play :: proc(sound: ^Sound, volume: f32 = 1, pitch: f32 = 1) {
    src: u32
    al.gen_sources(1, &src)
    al.sourcei(src, al.BUFFER, i32(sound^.al_buf))
    al.source_play(src)

    sound^.playing = true

    inst := new(Sound_Inst)
    inst^.al_src = src
    inst^.volume = volume
    inst^.pitch  = pitch
    inst^.sound  = sound

    append(&sounds, inst)
}

loop :: proc(sound: ^Sound) {
    play(sound)
    sound^.loop = true
}

stop :: proc(sound: ^Sound) {
    sound^.playing = false
}
