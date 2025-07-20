/*
WAV audio loader and writer. Choice of public domain or MIT-0. See license statements at the end of this file.
dr_wav - v0.14.0 - TBD

David Reid - mackron@gmail.com

GitHub: https://github.com/mackron/dr_libs
*/
/*
Introduction
============
This is a single file library. To use it, do something like the following in one .c file.

```c
#define DR_WAV_IMPLEMENTATION
#include "dr_wav.h"
```

You can then #include this file in other parts of the program as you would with any other header file. Do something like the following to read audio data:

```c
drwav wav;
if (!drwav_init_file(&wav, "my_song.wav", NULL)) {
// Error opening WAV file.
}

drwav_int32* pDecodedInterleavedPCMFrames = malloc(wav.totalPCMFrameCount * wav.channels * sizeof(drwav_int32));
size_t numberOfSamplesActuallyDecoded = drwav_read_pcm_frames_s32(&wav, wav.totalPCMFrameCount, pDecodedInterleavedPCMFrames);

...

drwav_uninit(&wav);
```

If you just want to quickly open and read the audio data in a single operation you can do something like this:

```c
unsigned int channels;
unsigned int sampleRate;
drwav_uint64 totalPCMFrameCount;
float* pSampleData = drwav_open_file_and_read_pcm_frames_f32("my_song.wav", &channels, &sampleRate, &totalPCMFrameCount, NULL);
if (pSampleData == NULL) {
// Error opening and reading WAV file.
}

...

drwav_free(pSampleData, NULL);
```

The examples above use versions of the API that convert the audio data to a consistent format (32-bit signed PCM, in this case), but you can still output the
audio data in its internal format (see notes below for supported formats):

```c
size_t framesRead = drwav_read_pcm_frames(&wav, wav.totalPCMFrameCount, pDecodedInterleavedPCMFrames);
```

You can also read the raw bytes of audio data, which could be useful if dr_wav does not have native support for a particular data format:

```c
size_t bytesRead = drwav_read_raw(&wav, bytesToRead, pRawDataBuffer);
```

dr_wav can also be used to output WAV files. This does not currently support compressed formats. To use this, look at `drwav_init_write()`,
`drwav_init_file_write()`, etc. Use `drwav_write_pcm_frames()` to write samples, or `drwav_write_raw()` to write raw data in the "data" chunk.

```c
drwav_data_format format;
format.container = drwav_container_riff;     // <-- drwav_container_riff = normal WAV files, drwav_container_w64 = Sony Wave64.
format.format = DR_WAVE_FORMAT_PCM;          // <-- Any of the DR_WAVE_FORMAT_* codes.
format.channels = 2;
format.sampleRate = 44100;
format.bitsPerSample = 16;
drwav_init_file_write(&wav, "data/recording.wav", &format, NULL);

...

drwav_uint64 framesWritten = drwav_write_pcm_frames(pWav, frameCount, pSamples);
```

Note that writing to AIFF or RIFX is not supported.

dr_wav has support for decoding from a number of different encapsulation formats. See below for details.


Build Options
=============
#define these options before including this file.

#define DR_WAV_NO_CONVERSION_API
Disables conversion APIs such as `drwav_read_pcm_frames_f32()` and `drwav_s16_to_f32()`.

#define DR_WAV_NO_STDIO
Disables APIs that initialize a decoder from a file such as `drwav_init_file()`, `drwav_init_file_write()`, etc.

#define DR_WAV_NO_WCHAR
Disables all functions ending with `_w`. Use this if your compiler does not provide wchar.h. Not required if DR_WAV_NO_STDIO is also defined.


Supported Encapsulations
========================
- RIFF (Regular WAV)
- RIFX (Big-Endian)
- AIFF (Does not currently support ADPCM)
- RF64
- W64

Note that AIFF and RIFX do not support write mode, nor do they support reading of metadata.


Supported Encodings
===================
- Unsigned 8-bit PCM
- Signed 12-bit PCM
- Signed 16-bit PCM
- Signed 24-bit PCM
- Signed 32-bit PCM
- IEEE 32-bit floating point
- IEEE 64-bit floating point
- A-law and u-law
- Microsoft ADPCM
- IMA ADPCM (DVI, format code 0x11)

8-bit PCM encodings are always assumed to be unsigned. Signed 8-bit encoding can only be read with `drwav_read_raw()`.

Note that ADPCM is not currently supported with AIFF. Contributions welcome.


Notes
=====
- Samples are always interleaved.
- The default read function does not do any data conversion. Use `drwav_read_pcm_frames_f32()`, `drwav_read_pcm_frames_s32()` and `drwav_read_pcm_frames_s16()`
to read and convert audio data to 32-bit floating point, signed 32-bit integer and signed 16-bit integer samples respectively.
- dr_wav will try to read the WAV file as best it can, even if it's not strictly conformant to the WAV format.
*/

package dr_wav

when ODIN_OS == .Windows {
    foreign import lib "libdr_wav.lib"
}
when ODIN_OS == .Linux {
    foreign import lib "libdr_wav.a"
}

import "core:c"

_ :: c



DRWAV_VERSION_MAJOR     :: 0
DRWAV_VERSION_MINOR     :: 14
DRWAV_VERSION_REVISION  :: 0
// DRWAV_VERSION_STRING    :: #DRWAV_VERSION_MAJOR "." #DRWAV_VERSION_MINOR "." #DRWAV_VERSION_REVISION

/* Sized Types */
drwav_int8 :: c.schar

drwav_uint8 :: c.uchar

drwav_int16 :: c.short

drwav_uint16 :: c.ushort

drwav_int32 :: c.int

drwav_uint32 :: c.uint

drwav_int64 :: c.longlong

drwav_uint64 :: c.ulonglong

drwav_uintptr :: drwav_uint64

drwav_bool8 :: drwav_uint8

DRWAV_TRUE              :: 1

drwav_bool32 :: drwav_uint32

DRWAV_FALSE             :: 0

// DRWAV_API  :: extern

// DRWAV_PRIVATE :: static

DRWAV_SUCCESS                        :: 0

/* Result Codes */
drwav_result :: drwav_int32

DRWAV_ERROR                         :: -1   /* A generic error. */
DRWAV_INVALID_ARGS                  :: -2
DRWAV_INVALID_OPERATION             :: -3
DRWAV_OUT_OF_MEMORY                 :: -4
DRWAV_OUT_OF_RANGE                  :: -5
DRWAV_ACCESS_DENIED                 :: -6
DRWAV_DOES_NOT_EXIST                :: -7
DRWAV_ALREADY_EXISTS                :: -8
DRWAV_TOO_MANY_OPEN_FILES           :: -9
DRWAV_INVALID_FILE                  :: -10
DRWAV_TOO_BIG                       :: -11
DRWAV_PATH_TOO_LONG                 :: -12
DRWAV_NAME_TOO_LONG                 :: -13
DRWAV_NOT_DIRECTORY                 :: -14
DRWAV_IS_DIRECTORY                  :: -15
DRWAV_DIRECTORY_NOT_EMPTY           :: -16
DRWAV_END_OF_FILE                   :: -17
DRWAV_NO_SPACE                      :: -18
DRWAV_BUSY                          :: -19
DRWAV_IO_ERROR                      :: -20
DRWAV_INTERRUPT                     :: -21
DRWAV_UNAVAILABLE                   :: -22
DRWAV_ALREADY_IN_USE                :: -23
DRWAV_BAD_ADDRESS                   :: -24
DRWAV_BAD_SEEK                      :: -25
DRWAV_BAD_PIPE                      :: -26
DRWAV_DEADLOCK                      :: -27
DRWAV_TOO_MANY_LINKS                :: -28
DRWAV_NOT_IMPLEMENTED               :: -29
DRWAV_NO_MESSAGE                    :: -30
DRWAV_BAD_MESSAGE                   :: -31
DRWAV_NO_DATA_AVAILABLE             :: -32
DRWAV_INVALID_DATA                  :: -33
DRWAV_TIMEOUT                       :: -34
DRWAV_NO_NETWORK                    :: -35
DRWAV_NOT_UNIQUE                    :: -36
DRWAV_NOT_SOCKET                    :: -37
DRWAV_NO_ADDRESS                    :: -38
DRWAV_BAD_PROTOCOL                  :: -39
DRWAV_PROTOCOL_UNAVAILABLE          :: -40
DRWAV_PROTOCOL_NOT_SUPPORTED        :: -41
DRWAV_PROTOCOL_FAMILY_NOT_SUPPORTED :: -42
DRWAV_ADDRESS_FAMILY_NOT_SUPPORTED  :: -43
DRWAV_SOCKET_NOT_SUPPORTED          :: -44
DRWAV_CONNECTION_RESET              :: -45
DRWAV_ALREADY_CONNECTED             :: -46
DRWAV_NOT_CONNECTED                 :: -47
DRWAV_CONNECTION_REFUSED            :: -48
DRWAV_NO_HOST                       :: -49
DRWAV_IN_PROGRESS                   :: -50
DRWAV_CANCELLED                     :: -51
DRWAV_MEMORY_ALREADY_MAPPED         :: -52
DRWAV_AT_END                        :: -53

/* Common data formats. */
DR_WAVE_FORMAT_PCM          :: 0x1
DR_WAVE_FORMAT_ADPCM        :: 0x2
DR_WAVE_FORMAT_IEEE_FLOAT   :: 0x3
DR_WAVE_FORMAT_ALAW         :: 0x6
DR_WAVE_FORMAT_MULAW        :: 0x7
DR_WAVE_FORMAT_DVI_ADPCM    :: 0x11
DR_WAVE_FORMAT_EXTENSIBLE   :: 0xFFFE

/* Flags to pass into drwav_init_ex(), etc. */
DRWAV_SEQUENTIAL            :: 0x00000001
DRWAV_WITH_METADATA         :: 0x00000002

/* Allocation Callbacks */
drwav_allocation_callbacks :: struct {
	pUserData: rawptr,
	onMalloc:  proc "c" (c.size_t, rawptr) -> rawptr,
	onRealloc: proc "c" (rawptr, c.size_t, rawptr) -> rawptr,
	onFree:    proc "c" (rawptr, rawptr),
}

/* End Allocation Callbacks */
drwav_seek_origin :: enum c.int {
	SET,
	CUR,
	END,
}

drwav_container :: enum c.int {
	riff,
	rifx,
	w64,
	rf64,
	aiff,
}

drwav_chunk_header :: struct {
	id: struct #raw_union {
		fourcc: [4]drwav_uint8,
		guid:   [16]drwav_uint8,
	},

	/* The size in bytes of the chunk. */
	sizeInBytes: drwav_uint64,

	/*
	RIFF = 2 byte alignment.
	W64  = 8 byte alignment.
	*/
	paddingSize: c.uint,
}

drwav_fmt :: struct {
	/*
	The format tag exactly as specified in the wave file's "fmt" chunk. This can be used by applications
	that require support for data formats not natively supported by dr_wav.
	*/
	formatTag: drwav_uint16,

	/* The number of channels making up the audio data. When this is set to 1 it is mono, 2 is stereo, etc. */
	channels: drwav_uint16,

	/* The sample rate. Usually set to something like 44100. */
	sampleRate: drwav_uint32,

	/* Average bytes per second. You probably don't need this, but it's left here for informational purposes. */
	avgBytesPerSec: drwav_uint32,

	/* Block align. This is equal to the number of channels * bytes per sample. */
	blockAlign: drwav_uint16,

	/* Bits per sample. */
	bitsPerSample: drwav_uint16,

	/* The size of the extended data. Only used internally for validation, but left here for informational purposes. */
	extendedSize: drwav_uint16,

	/*
	The number of valid bits per sample. When <formatTag> is equal to WAVE_FORMAT_EXTENSIBLE, <bitsPerSample>
	is always rounded up to the nearest multiple of 8. This variable contains information about exactly how
	many bits are valid per sample. Mainly used for informational purposes.
	*/
	validBitsPerSample: drwav_uint16,

	/* The channel mask. Not used at the moment. */
	channelMask: drwav_uint32,

	/* The sub-format, exactly as specified by the wave file. */
	subFormat: [16]drwav_uint8,
}

/*
Callback for when data is read. Return value is the number of bytes actually read.

pUserData   [in]  The user data that was passed to drwav_init() and family.
pBufferOut  [out] The output buffer.
bytesToRead [in]  The number of bytes to read.

Returns the number of bytes actually read.

A return value of less than bytesToRead indicates the end of the stream. Do _not_ return from this callback until
either the entire bytesToRead is filled or you have reached the end of the stream.
*/
drwav_read_proc :: proc "c" (rawptr, rawptr, c.size_t) -> c.size_t

/*
Callback for when data is written. Returns value is the number of bytes actually written.

pUserData    [in]  The user data that was passed to drwav_init_write() and family.
pData        [out] A pointer to the data to write.
bytesToWrite [in]  The number of bytes to write.

Returns the number of bytes actually written.

If the return value differs from bytesToWrite, it indicates an error.
*/
drwav_write_proc :: proc "c" (rawptr, rawptr, c.size_t) -> c.size_t

/*
Callback for when data needs to be seeked.

pUserData [in] The user data that was passed to drwav_init() and family.
offset    [in] The number of bytes to move, relative to the origin. Will never be negative.
origin    [in] The origin of the seek - the current position or the start of the stream.

Returns whether or not the seek was successful.

Whether or not it is relative to the beginning or current position is determined by the "origin" parameter which will be either DRWAV_SEEK_SET or
DRWAV_SEEK_CUR.
*/
drwav_seek_proc :: proc "c" (rawptr, c.int, drwav_seek_origin) -> drwav_bool32

/*
Callback for when the current position in the stream needs to be retrieved.

pUserData [in]  The user data that was passed to drwav_init() and family.
pCursor   [out] A pointer to a variable to receive the current position in the stream.

Returns whether or not the operation was successful.
*/
drwav_tell_proc :: proc "c" (rawptr, ^drwav_int64) -> drwav_bool32

/*
Callback for when drwav_init_ex() finds a chunk.

pChunkUserData    [in] The user data that was passed to the pChunkUserData parameter of drwav_init_ex() and family.
onRead            [in] A pointer to the function to call when reading.
onSeek            [in] A pointer to the function to call when seeking.
pReadSeekUserData [in] The user data that was passed to the pReadSeekUserData parameter of drwav_init_ex() and family.
pChunkHeader      [in] A pointer to an object containing basic header information about the chunk. Use this to identify the chunk.
container         [in] Whether or not the WAV file is a RIFF or Wave64 container. If you're unsure of the difference, assume RIFF.
pFMT              [in] A pointer to the object containing the contents of the "fmt" chunk.

Returns the number of bytes read + seeked.

To read data from the chunk, call onRead(), passing in pReadSeekUserData as the first parameter. Do the same for seeking with onSeek(). The return value must
be the total number of bytes you have read _plus_ seeked.

Use the `container` argument to discriminate the fields in `pChunkHeader->id`. If the container is `drwav_container_riff` or `drwav_container_rf64` you should
use `id.fourcc`, otherwise you should use `id.guid`.

The `pFMT` parameter can be used to determine the data format of the wave file. Use `drwav_fmt_get_format()` to get the sample format, which will be one of the
`DR_WAVE_FORMAT_*` identifiers.

The read pointer will be sitting on the first byte after the chunk's header. You must not attempt to read beyond the boundary of the chunk.
*/
drwav_chunk_proc :: proc "c" (rawptr, drwav_read_proc, drwav_seek_proc, rawptr, ^drwav_chunk_header, drwav_container, ^drwav_fmt) -> drwav_uint64

/* Structure for internal use. Only used for loaders opened with drwav_init_memory(). */
drwav__memory_stream :: struct {
	data:           ^drwav_uint8,
	dataSize:       c.size_t,
	currentReadPos: c.size_t,
}

/* Structure for internal use. Only used for writers opened with drwav_init_memory_write(). */
drwav__memory_stream_write :: struct {
	ppData:          ^rawptr,
	pDataSize:       ^c.size_t,
	dataSize:        c.size_t,
	dataCapacity:    c.size_t,
	currentWritePos: c.size_t,
}

drwav_data_format :: struct {
	container:     drwav_container, /* RIFF, W64. */
	format:        drwav_uint32,    /* DR_WAVE_FORMAT_* */
	channels:      drwav_uint32,
	sampleRate:    drwav_uint32,
	bitsPerSample: drwav_uint32,
}

drwav_metadata_type :: enum c.int {
	none                     = 0,

	/*
	Unknown simply means a chunk that drwav does not handle specifically. You can still ask to
	receive these chunks as metadata objects. It is then up to you to interpret the chunk's data.
	You can also write unknown metadata to a wav file. Be careful writing unknown chunks if you
	have also edited the audio data. The unknown chunks could represent offsets/sizes that no
	longer correctly correspond to the audio data.
	*/
	unknown = 1,

	/* Only 1 of each of these metadata items are allowed in a wav file. */
	smpl = 2,

	/* Only 1 of each of these metadata items are allowed in a wav file. */
	inst = 4,

	/* Only 1 of each of these metadata items are allowed in a wav file. */
	cue = 8,

	/* Only 1 of each of these metadata items are allowed in a wav file. */
	acid = 16,

	/* Only 1 of each of these metadata items are allowed in a wav file. */
	bext = 32,

	/*
	Wav files often have a LIST chunk. This is a chunk that contains a set of subchunks. For this
	higher-level metadata API, we don't make a distinction between a regular chunk and a LIST
	subchunk. Instead, they are all just 'metadata' items.
	
	There can be multiple of these metadata items in a wav file.
	*/
	list_label = 64,

	/*
	Wav files often have a LIST chunk. This is a chunk that contains a set of subchunks. For this
	higher-level metadata API, we don't make a distinction between a regular chunk and a LIST
	subchunk. Instead, they are all just 'metadata' items.
	
	There can be multiple of these metadata items in a wav file.
	*/
	list_note = 128,

	/*
	Wav files often have a LIST chunk. This is a chunk that contains a set of subchunks. For this
	higher-level metadata API, we don't make a distinction between a regular chunk and a LIST
	subchunk. Instead, they are all just 'metadata' items.
	
	There can be multiple of these metadata items in a wav file.
	*/
	list_labelled_cue_region = 256,

	/*
	Wav files often have a LIST chunk. This is a chunk that contains a set of subchunks. For this
	higher-level metadata API, we don't make a distinction between a regular chunk and a LIST
	subchunk. Instead, they are all just 'metadata' items.
	
	There can be multiple of these metadata items in a wav file.
	*/
	list_info_software = 512,

	/*
	Wav files often have a LIST chunk. This is a chunk that contains a set of subchunks. For this
	higher-level metadata API, we don't make a distinction between a regular chunk and a LIST
	subchunk. Instead, they are all just 'metadata' items.
	
	There can be multiple of these metadata items in a wav file.
	*/
	list_info_copyright = 1024,

	/*
	Wav files often have a LIST chunk. This is a chunk that contains a set of subchunks. For this
	higher-level metadata API, we don't make a distinction between a regular chunk and a LIST
	subchunk. Instead, they are all just 'metadata' items.
	
	There can be multiple of these metadata items in a wav file.
	*/
	list_info_title = 2048,

	/*
	Wav files often have a LIST chunk. This is a chunk that contains a set of subchunks. For this
	higher-level metadata API, we don't make a distinction between a regular chunk and a LIST
	subchunk. Instead, they are all just 'metadata' items.
	
	There can be multiple of these metadata items in a wav file.
	*/
	list_info_artist = 4096,

	/*
	Wav files often have a LIST chunk. This is a chunk that contains a set of subchunks. For this
	higher-level metadata API, we don't make a distinction between a regular chunk and a LIST
	subchunk. Instead, they are all just 'metadata' items.
	
	There can be multiple of these metadata items in a wav file.
	*/
	list_info_comment = 8192,

	/*
	Wav files often have a LIST chunk. This is a chunk that contains a set of subchunks. For this
	higher-level metadata API, we don't make a distinction between a regular chunk and a LIST
	subchunk. Instead, they are all just 'metadata' items.
	
	There can be multiple of these metadata items in a wav file.
	*/
	list_info_date = 16384,

	/*
	Wav files often have a LIST chunk. This is a chunk that contains a set of subchunks. For this
	higher-level metadata API, we don't make a distinction between a regular chunk and a LIST
	subchunk. Instead, they are all just 'metadata' items.
	
	There can be multiple of these metadata items in a wav file.
	*/
	list_info_genre = 32768,

	/*
	Wav files often have a LIST chunk. This is a chunk that contains a set of subchunks. For this
	higher-level metadata API, we don't make a distinction between a regular chunk and a LIST
	subchunk. Instead, they are all just 'metadata' items.
	
	There can be multiple of these metadata items in a wav file.
	*/
	list_info_album = 65536,

	/*
	Wav files often have a LIST chunk. This is a chunk that contains a set of subchunks. For this
	higher-level metadata API, we don't make a distinction between a regular chunk and a LIST
	subchunk. Instead, they are all just 'metadata' items.
	
	There can be multiple of these metadata items in a wav file.
	*/
	list_info_tracknumber = 131072,

	/*
	Wav files often have a LIST chunk. This is a chunk that contains a set of subchunks. For this
	higher-level metadata API, we don't make a distinction between a regular chunk and a LIST
	subchunk. Instead, they are all just 'metadata' items.
	
	There can be multiple of these metadata items in a wav file.
	*/
	list_info_location = 262144,

	/*
	Wav files often have a LIST chunk. This is a chunk that contains a set of subchunks. For this
	higher-level metadata API, we don't make a distinction between a regular chunk and a LIST
	subchunk. Instead, they are all just 'metadata' items.
	
	There can be multiple of these metadata items in a wav file.
	*/
	list_info_organization = 524288,

	/*
	Wav files often have a LIST chunk. This is a chunk that contains a set of subchunks. For this
	higher-level metadata API, we don't make a distinction between a regular chunk and a LIST
	subchunk. Instead, they are all just 'metadata' items.
	
	There can be multiple of these metadata items in a wav file.
	*/
	list_info_keywords = 1048576,

	/*
	Wav files often have a LIST chunk. This is a chunk that contains a set of subchunks. For this
	higher-level metadata API, we don't make a distinction between a regular chunk and a LIST
	subchunk. Instead, they are all just 'metadata' items.
	
	There can be multiple of these metadata items in a wav file.
	*/
	list_info_medium = 2097152,

	/*
	Wav files often have a LIST chunk. This is a chunk that contains a set of subchunks. For this
	higher-level metadata API, we don't make a distinction between a regular chunk and a LIST
	subchunk. Instead, they are all just 'metadata' items.
	
	There can be multiple of these metadata items in a wav file.
	*/
	list_info_description = 4194304,

	/* Other type constants for convenience. */
	list_all_info_strings = 8388096,

	/* Other type constants for convenience. */
	list_all_adtl = 448,
	all                      = -2, /*0xFFFFFFFF & ~drwav_metadata_type_unknown,*/
	all_including_unknown    = -1, /*0xFFFFFFFF,*/
}

/*
Sampler Metadata

The sampler chunk contains information about how a sound should be played in the context of a whole
audio production, and when used in a sampler. See https://en.wikipedia.org/wiki/Sample-based_synthesis.
*/
drwav_smpl_loop_type :: enum c.int {
	forward  = 0,
	pingpong = 1,
	backward = 2,
}

drwav_smpl_loop :: struct {
	/* The ID of the associated cue point, see drwav_cue and drwav_cue_point. As with all cue point IDs, this can correspond to a label chunk to give this loop a name, see drwav_list_label_or_note. */
	cuePointId: drwav_uint32,

	/* See drwav_smpl_loop_type. */
	type: drwav_uint32,

	/* The offset of the first sample to be played in the loop. */
	firstSampleOffset: drwav_uint32,

	/* The offset into the audio data of the last sample to be played in the loop. */
	lastSampleOffset: drwav_uint32,

	/* A value to represent that playback should occur at a point between samples. This value ranges from 0 to UINT32_MAX. Where a value of 0 means no fraction, and a value of (UINT32_MAX / 2) would mean half a sample. */
	sampleFraction: drwav_uint32,

	/* Number of times to play the loop. 0 means loop infinitely. */
	playCount: drwav_uint32,
}

drwav_smpl :: struct {
	/* IDs for a particular MIDI manufacturer. 0 if not used. */
	manufacturerId: drwav_uint32,
	productId:            drwav_uint32,

	/* The period of 1 sample in nanoseconds. */
	samplePeriodNanoseconds: drwav_uint32,

	/* The MIDI root note of this file. 0 to 127. */
	midiUnityNote: drwav_uint32,

	/* The fraction of a semitone up from the given MIDI note. This is a value from 0 to UINT32_MAX, where 0 means no change and (UINT32_MAX / 2) is half a semitone (AKA 50 cents). */
	midiPitchFraction: drwav_uint32,

	/* Data relating to SMPTE standards which are used for syncing audio and video. 0 if not used. */
	smpteFormat: drwav_uint32,
	smpteOffset:          drwav_uint32,

	/* drwav_smpl_loop loops. */
	sampleLoopCount: drwav_uint32,

	/* Optional sampler-specific data. */
	samplerSpecificDataSizeInBytes: drwav_uint32,
	pLoops:               ^drwav_smpl_loop,
	pSamplerSpecificData: ^drwav_uint8,
}

/*
Instrument Metadata

The inst metadata contains data about how a sound should be played as part of an instrument. This
commonly read by samplers. See https://en.wikipedia.org/wiki/Sample-based_synthesis.
*/
drwav_inst :: struct {
	midiUnityNote: drwav_int8, /* The root note of the audio as a MIDI note number. 0 to 127. */
	fineTuneCents: drwav_int8, /* -50 to +50 */
	gainDecibels:  drwav_int8, /* -64 to +64 */
	lowNote:       drwav_int8, /* 0 to 127 */
	highNote:      drwav_int8, /* 0 to 127 */
	lowVelocity:   drwav_int8, /* 1 to 127 */
	highVelocity:  drwav_int8, /* 1 to 127 */
}

/*
Cue Metadata

Cue points are markers at specific points in the audio. They often come with an associated piece of
drwav_list_label_or_note metadata which contains the text for the marker.
*/
drwav_cue_point :: struct {
	/* Unique identification value. */
	id: drwav_uint32,

	/* Set to 0. This is only relevant if there is a 'playlist' chunk - which is not supported by dr_wav. */
	playOrderPosition: drwav_uint32,

	/* Should always be "data". This represents the fourcc value of the chunk that this cue point corresponds to. dr_wav only supports a single data chunk so this should always be "data". */
	dataChunkId: [4]drwav_uint8,

	/* Set to 0. This is only relevant if there is a wave list chunk. dr_wav, like lots of readers/writers, do not support this. */
	chunkStart: drwav_uint32,

	/* Set to 0 for uncompressed formats. Else the last byte in compressed wave data where decompression can begin to find the value of the corresponding sample value. */
	blockStart: drwav_uint32,

	/* For uncompressed formats this is the offset of the cue point into the audio data. For compressed formats this is relative to the block specified with blockStart. */
	sampleOffset: drwav_uint32,
}

drwav_cue :: struct {
	cuePointCount: drwav_uint32,
	pCuePoints:    ^drwav_cue_point,
}

/*
Acid Metadata

This chunk contains some information about the time signature and the tempo of the audio.
*/
drwav_acid_flag :: enum c.int {
	one_shot      = 1,  /* If this is not set, then it is a loop instead of a one-shot. */
	root_note_set = 2,
	stretch       = 4,
	disk_based    = 8,
	acidizer      = 16, /* Not sure what this means. */
}

drwav_acid :: struct {
	/* A bit-field, see drwav_acid_flag. */
	flags: drwav_uint32,

	/* Valid if flags contains drwav_acid_flag_root_note_set. It represents the MIDI root note the file - a value from 0 to 127. */
	midiUnityNote: drwav_uint16,

	/* Reserved values that should probably be ignored. reserved1 seems to often be 128 and reserved2 is 0. */
	reserved1: drwav_uint16,
	reserved2:      f32,

	/* Number of beats. */
	numBeats: drwav_uint32,

	/* The time signature of the audio. */
	meterDenominator: drwav_uint16,
	meterNumerator: drwav_uint16,

	/* Beats per minute of the track. Setting a value of 0 suggests that there is no tempo. */
	tempo: f32,
}

/*
Cue Label or Note metadata

These are 2 different types of metadata, but they have the exact same format. Labels tend to be the
more common and represent a short name for a cue point. Notes might be used to represent a longer
comment.
*/
drwav_list_label_or_note :: struct {
	/* The ID of a cue point that this label or note corresponds to. */
	cuePointId: drwav_uint32,

	/* Size of the string not including any null terminator. */
	stringLength: drwav_uint32,

	/* The string. The *init_with_metadata functions null terminate this for convenience. */
	pString: cstring,
}

/*
BEXT metadata, also known as Broadcast Wave Format (BWF)

This metadata adds some extra description to an audio file. You must check the version field to
determine if the UMID or the loudness fields are valid.
*/
drwav_bext :: struct {
	pDescription:         cstring,      /* Can be NULL or a null-terminated string, must be <= 256 characters. */
	pOriginatorName:      cstring,      /* Can be NULL or a null-terminated string, must be <= 32 characters. */
	pOriginatorReference: cstring,      /* Can be NULL or a null-terminated string, must be <= 32 characters. */
	pOriginationDate:     [10]c.char,   /* ASCII "yyyy:mm:dd". */
	pOriginationTime:     [8]c.char,    /* ASCII "hh:mm:ss". */
	timeReference:        drwav_uint64, /* First sample count since midnight. */
	version:              drwav_uint16, /* Version of the BWF, check this to see if the fields below are valid. */

	/*
	Unrestricted ASCII characters containing a collection of strings terminated by CR/LF. Each
	string shall contain a description of a coding process applied to the audio data.
	*/
	pCodingHistory: cstring,
	codingHistorySize:    drwav_uint32,
	pUMID:                ^drwav_uint8, /* Exactly 64 bytes of SMPTE UMID */
	loudnessValue:        drwav_uint16, /* Integrated Loudness Value of the file in LUFS (multiplied by 100). */
	loudnessRange:        drwav_uint16, /* Loudness Range of the file in LU (multiplied by 100). */
	maxTruePeakLevel:     drwav_uint16, /* Maximum True Peak Level of the file expressed as dBTP (multiplied by 100). */
	maxMomentaryLoudness: drwav_uint16, /* Highest value of the Momentary Loudness Level of the file in LUFS (multiplied by 100). */
	maxShortTermLoudness: drwav_uint16, /* Highest value of the Short-Term Loudness Level of the file in LUFS (multiplied by 100). */
}

/*
Info Text Metadata

There a many different types of information text that can be saved in this format. This is where
things like the album name, the artists, the year it was produced, etc are saved. See
drwav_metadata_type for the full list of types that dr_wav supports.
*/
drwav_list_info_text :: struct {
	/* Size of the string not including any null terminator. */
	stringLength: drwav_uint32,

	/* The string. The *init_with_metadata functions null terminate this for convenience. */
	pString: cstring,
}

/*
Labelled Cue Region Metadata

The labelled cue region metadata is used to associate some region of audio with text. The region
starts at a cue point, and extends for the given number of samples.
*/
drwav_list_labelled_cue_region :: struct {
	/* The ID of a cue point that this object corresponds to. */
	cuePointId: drwav_uint32,

	/* The number of samples from the cue point forwards that should be considered this region */
	sampleLength: drwav_uint32,

	/* Four characters used to say what the purpose of this region is. */
	purposeId: [4]drwav_uint8,

	/* Unsure of the exact meanings of these. It appears to be acceptable to set them all to 0. */
	country: drwav_uint16,
	language: drwav_uint16,
	dialect:  drwav_uint16,
	codePage: drwav_uint16,

	/* Size of the string not including any null terminator. */
	stringLength: drwav_uint32,

	/* The string. The *init_with_metadata functions null terminate this for convenience. */
	pString: cstring,
}

/*
Unknown Metadata

This chunk just represents a type of chunk that dr_wav does not understand.

Unknown metadata has a location attached to it. This is because wav files can have a LIST chunk
that contains subchunks. These LIST chunks can be one of two types. An adtl list, or an INFO
list. This enum is used to specify the location of a chunk that dr_wav currently doesn't support.
*/
drwav_metadata_location :: enum c.int {
	invalid,
	top_level,
	inside_info_list,
	inside_adtl_list,
}

drwav_unknown_metadata :: struct {
	id:              [4]drwav_uint8,
	chunkLocation:   drwav_metadata_location,
	dataSizeInBytes: drwav_uint32,
	pData:           ^drwav_uint8,
}

/*
Metadata is saved as a union of all the supported types.
*/
drwav_metadata :: struct {
	/* Determines which item in the union is valid. */
	type: drwav_metadata_type,
	data: struct #raw_union {
		cue:               drwav_cue,
		smpl:              drwav_smpl,
		acid:              drwav_acid,
		inst:              drwav_inst,
		bext:              drwav_bext,
		labelOrNote:       drwav_list_label_or_note, /* List label or list note. */
		labelledCueRegion: drwav_list_labelled_cue_region,
		infoText:          drwav_list_info_text,     /* Any of the list info types. */
		unknown:           drwav_unknown_metadata,
	},
}

drwav :: struct {
	/* A pointer to the function to call when more data is needed. */
	onRead: drwav_read_proc,

	/* A pointer to the function to call when data needs to be written. Only used when the drwav object is opened in write mode. */
	onWrite: drwav_write_proc,

	/* A pointer to the function to call when the wav file needs to be seeked. */
	onSeek: drwav_seek_proc,

	/* A pointer to the function to call when the position of the stream needs to be retrieved. */
	onTell: drwav_tell_proc,

	/* The user data to pass to callbacks. */
	pUserData: rawptr,

	/* Allocation callbacks. */
	allocationCallbacks: drwav_allocation_callbacks,

	/* Whether or not the WAV file is formatted as a standard RIFF file or W64. */
	container: drwav_container,

	/* Structure containing format information exactly as specified by the wav file. */
	fmt: drwav_fmt,

	/* The sample rate. Will be set to something like 44100. */
	sampleRate: drwav_uint32,

	/* The number of channels. This will be set to 1 for monaural streams, 2 for stereo, etc. */
	channels: drwav_uint16,

	/* The bits per sample. Will be set to something like 16, 24, etc. */
	bitsPerSample: drwav_uint16,

	/* Equal to fmt.formatTag, or the value specified by fmt.subFormat if fmt.formatTag is equal to 65534 (WAVE_FORMAT_EXTENSIBLE). */
	translatedFormatTag: drwav_uint16,

	/* The total number of PCM frames making up the audio data. */
	totalPCMFrameCount: drwav_uint64,

	/* The size in bytes of the data chunk. */
	dataChunkDataSize: drwav_uint64,

	/* The position in the stream of the first data byte of the data chunk. This is used for seeking. */
	dataChunkDataPos: drwav_uint64,

	/* The number of bytes remaining in the data chunk. */
	bytesRemaining: drwav_uint64,

	/* The current read position in PCM frames. */
	readCursorInPCMFrames: drwav_uint64,

	/*
	Only used in sequential write mode. Keeps track of the desired size of the "data" chunk at the point of initialization time. Always
	set to 0 for non-sequential writes and when the drwav object is opened in read mode. Used for validation.
	*/
	dataChunkDataSizeTargetWrite: drwav_uint64,

	/* Keeps track of whether or not the wav writer was initialized in sequential mode. */
	isSequentialWrite: drwav_bool32,

	/* A array of metadata. This is valid after the *init_with_metadata call returns. It will be valid until drwav_uninit() is called. You can take ownership of this data with drwav_take_ownership_of_metadata(). */
	pMetadata: ^drwav_metadata,
	metadataCount:     drwav_uint32,

	/* A hack to avoid a DRWAV_MALLOC() when opening a decoder with drwav_init_memory(). */
	memoryStream: drwav__memory_stream,
	memoryStreamWrite: drwav__memory_stream_write,

	/* Microsoft ADPCM specific data. */
	msadpcm:           struct {
		bytesRemainingInBlock: drwav_uint32,
		predictor:             [2]drwav_uint16,
		delta:                 [2]drwav_int32,
		cachedFrames:          [4]drwav_int32,    /* Samples are stored in this cache during decoding. */
		cachedFrameCount:      drwav_uint32,
		prevFrames:            [2][2]drwav_int32, /* The previous 2 samples for each channel (2 channels at most). */
	},

	/* IMA ADPCM specific data. */
	ima:               struct {
		bytesRemainingInBlock: drwav_uint32,
		predictor:             [2]drwav_int32,
		stepIndex:             [2]drwav_int32,
		cachedFrames:          [16]drwav_int32, /* Samples are stored in this cache during decoding. */
		cachedFrameCount:      drwav_uint32,
	},

	/* AIFF specific data. */
	aiff:              struct {
		isLE:       drwav_bool8, /* Will be set to true if the audio data is little-endian encoded. */
		isUnsigned: drwav_bool8, /* Only used for 8-bit samples. When set to true, will be treated as unsigned. */
	},
}

@(default_calling_convention="c", link_prefix="")
foreign lib {
	drwav_version        :: proc(pMajor: ^drwav_uint32, pMinor: ^drwav_uint32, pRevision: ^drwav_uint32) ---
	drwav_version_string :: proc() -> cstring ---
	drwav_fmt_get_format :: proc(pFMT: ^drwav_fmt) -> drwav_uint16 ---

	/*
	Initializes a pre-allocated drwav object for reading.
	
	pWav                         [out]          A pointer to the drwav object being initialized.
	onRead                       [in]           The function to call when data needs to be read from the client.
	onSeek                       [in]           The function to call when the read position of the client data needs to move.
	onChunk                      [in, optional] The function to call when a chunk is enumerated at initialized time.
	pUserData, pReadSeekUserData [in, optional] A pointer to application defined data that will be passed to onRead and onSeek.
	pChunkUserData               [in, optional] A pointer to application defined data that will be passed to onChunk.
	flags                        [in, optional] A set of flags for controlling how things are loaded.
	
	Returns true if successful; false otherwise.
	
	Close the loader with drwav_uninit().
	
	This is the lowest level function for initializing a WAV file. You can also use drwav_init_file() and drwav_init_memory()
	to open the stream from a file or from a block of memory respectively.
	
	Possible values for flags:
	DRWAV_SEQUENTIAL: Never perform a backwards seek while loading. This disables the chunk callback and will cause this function
	to return as soon as the data chunk is found. Any chunks after the data chunk will be ignored.
	
	drwav_init() is equivalent to "drwav_init_ex(pWav, onRead, onSeek, NULL, pUserData, NULL, 0);".
	
	The onChunk callback is not called for the WAVE or FMT chunks. The contents of the FMT chunk can be read from pWav->fmt
	after the function returns.
	
	See also: drwav_init_file(), drwav_init_memory(), drwav_uninit()
	*/
	drwav_init               :: proc(pWav: ^drwav, onRead: drwav_read_proc, onSeek: drwav_seek_proc, onTell: drwav_tell_proc, pUserData: rawptr, pAllocationCallbacks: ^drwav_allocation_callbacks) -> drwav_bool32 ---
	drwav_init_ex            :: proc(pWav: ^drwav, onRead: drwav_read_proc, onSeek: drwav_seek_proc, onTell: drwav_tell_proc, onChunk: drwav_chunk_proc, pReadSeekTellUserData: rawptr, pChunkUserData: rawptr, flags: drwav_uint32, pAllocationCallbacks: ^drwav_allocation_callbacks) -> drwav_bool32 ---
	drwav_init_with_metadata :: proc(pWav: ^drwav, onRead: drwav_read_proc, onSeek: drwav_seek_proc, onTell: drwav_tell_proc, pUserData: rawptr, flags: drwav_uint32, pAllocationCallbacks: ^drwav_allocation_callbacks) -> drwav_bool32 ---

	/*
	Initializes a pre-allocated drwav object for writing.
	
	onWrite               [in]           The function to call when data needs to be written.
	onSeek                [in]           The function to call when the write position needs to move.
	pUserData             [in, optional] A pointer to application defined data that will be passed to onWrite and onSeek.
	metadata, numMetadata [in, optional] An array of metadata objects that should be written to the file. The array is not edited. You are responsible for this metadata memory and it must maintain valid until drwav_uninit() is called.
	
	Returns true if successful; false otherwise.
	
	Close the writer with drwav_uninit().
	
	This is the lowest level function for initializing a WAV file. You can also use drwav_init_file_write() and drwav_init_memory_write()
	to open the stream from a file or from a block of memory respectively.
	
	If the total sample count is known, you can use drwav_init_write_sequential(). This avoids the need for dr_wav to perform
	a post-processing step for storing the total sample count and the size of the data chunk which requires a backwards seek.
	
	See also: drwav_init_file_write(), drwav_init_memory_write(), drwav_uninit()
	*/
	drwav_init_write                       :: proc(pWav: ^drwav, pFormat: ^drwav_data_format, onWrite: drwav_write_proc, onSeek: drwav_seek_proc, pUserData: rawptr, pAllocationCallbacks: ^drwav_allocation_callbacks) -> drwav_bool32 ---
	drwav_init_write_sequential            :: proc(pWav: ^drwav, pFormat: ^drwav_data_format, totalSampleCount: drwav_uint64, onWrite: drwav_write_proc, pUserData: rawptr, pAllocationCallbacks: ^drwav_allocation_callbacks) -> drwav_bool32 ---
	drwav_init_write_sequential_pcm_frames :: proc(pWav: ^drwav, pFormat: ^drwav_data_format, totalPCMFrameCount: drwav_uint64, onWrite: drwav_write_proc, pUserData: rawptr, pAllocationCallbacks: ^drwav_allocation_callbacks) -> drwav_bool32 ---
	drwav_init_write_with_metadata         :: proc(pWav: ^drwav, pFormat: ^drwav_data_format, onWrite: drwav_write_proc, onSeek: drwav_seek_proc, pUserData: rawptr, pAllocationCallbacks: ^drwav_allocation_callbacks, pMetadata: ^drwav_metadata, metadataCount: drwav_uint32) -> drwav_bool32 ---

	/*
	Utility function to determine the target size of the entire data to be written (including all headers and chunks).
	
	Returns the target size in bytes.
	
	The metadata argument can be NULL meaning no metadata exists.
	
	Useful if the application needs to know the size to allocate.
	
	Only writing to the RIFF chunk and one data chunk is currently supported.
	
	See also: drwav_init_write(), drwav_init_file_write(), drwav_init_memory_write()
	*/
	drwav_target_write_size_bytes :: proc(pFormat: ^drwav_data_format, totalFrameCount: drwav_uint64, pMetadata: ^drwav_metadata, metadataCount: drwav_uint32) -> drwav_uint64 ---

	/*
	Take ownership of the metadata objects that were allocated via one of the init_with_metadata() function calls. The init_with_metdata functions perform a single heap allocation for this metadata.
	
	Useful if you want the data to persist beyond the lifetime of the drwav object.
	
	You must free the data returned from this function using drwav_free().
	*/
	drwav_take_ownership_of_metadata :: proc(pWav: ^drwav) -> ^drwav_metadata ---

	/*
	Uninitializes the given drwav object.
	
	Use this only for objects initialized with drwav_init*() functions (drwav_init(), drwav_init_ex(), drwav_init_write(), drwav_init_write_sequential()).
	*/
	drwav_uninit :: proc(pWav: ^drwav) -> drwav_result ---

	/*
	Reads raw audio data.
	
	This is the lowest level function for reading audio data. It simply reads the given number of
	bytes of the raw internal sample data.
	
	Consider using drwav_read_pcm_frames_s16(), drwav_read_pcm_frames_s32() or drwav_read_pcm_frames_f32() for
	reading sample data in a consistent format.
	
	pBufferOut can be NULL in which case a seek will be performed.
	
	Returns the number of bytes actually read.
	*/
	drwav_read_raw :: proc(pWav: ^drwav, bytesToRead: c.size_t, pBufferOut: rawptr) -> c.size_t ---

	/*
	Reads up to the specified number of PCM frames from the WAV file.
	
	The output data will be in the file's internal format, converted to native-endian byte order. Use
	drwav_read_pcm_frames_s16/f32/s32() to read data in a specific format.
	
	If the return value is less than <framesToRead> it means the end of the file has been reached or
	you have requested more PCM frames than can possibly fit in the output buffer.
	
	This function will only work when sample data is of a fixed size and uncompressed. If you are
	using a compressed format consider using drwav_read_raw() or drwav_read_pcm_frames_s16/s32/f32().
	
	pBufferOut can be NULL in which case a seek will be performed.
	*/
	drwav_read_pcm_frames    :: proc(pWav: ^drwav, framesToRead: drwav_uint64, pBufferOut: rawptr) -> drwav_uint64 ---
	drwav_read_pcm_frames_le :: proc(pWav: ^drwav, framesToRead: drwav_uint64, pBufferOut: rawptr) -> drwav_uint64 ---
	drwav_read_pcm_frames_be :: proc(pWav: ^drwav, framesToRead: drwav_uint64, pBufferOut: rawptr) -> drwav_uint64 ---

	/*
	Seeks to the given PCM frame.
	
	Returns true if successful; false otherwise.
	*/
	drwav_seek_to_pcm_frame :: proc(pWav: ^drwav, targetFrameIndex: drwav_uint64) -> drwav_bool32 ---

	/*
	Retrieves the current read position in pcm frames.
	*/
	drwav_get_cursor_in_pcm_frames :: proc(pWav: ^drwav, pCursor: ^drwav_uint64) -> drwav_result ---

	/*
	Retrieves the length of the file.
	*/
	drwav_get_length_in_pcm_frames :: proc(pWav: ^drwav, pLength: ^drwav_uint64) -> drwav_result ---

	/*
	Writes raw audio data.
	
	Returns the number of bytes actually written. If this differs from bytesToWrite, it indicates an error.
	*/
	drwav_write_raw :: proc(pWav: ^drwav, bytesToWrite: c.size_t, pData: rawptr) -> c.size_t ---

	/*
	Writes PCM frames.
	
	Returns the number of PCM frames written.
	
	Input samples need to be in native-endian byte order. On big-endian architectures the input data will be converted to
	little-endian. Use drwav_write_raw() to write raw audio data without performing any conversion.
	*/
	drwav_write_pcm_frames    :: proc(pWav: ^drwav, framesToWrite: drwav_uint64, pData: rawptr) -> drwav_uint64 ---
	drwav_write_pcm_frames_le :: proc(pWav: ^drwav, framesToWrite: drwav_uint64, pData: rawptr) -> drwav_uint64 ---
	drwav_write_pcm_frames_be :: proc(pWav: ^drwav, framesToWrite: drwav_uint64, pData: rawptr) -> drwav_uint64 ---

	/*
	Reads a chunk of audio data and converts it to signed 16-bit PCM samples.
	
	pBufferOut can be NULL in which case a seek will be performed.
	
	Returns the number of PCM frames actually read.
	
	If the return value is less than <framesToRead> it means the end of the file has been reached.
	*/
	drwav_read_pcm_frames_s16   :: proc(pWav: ^drwav, framesToRead: drwav_uint64, pBufferOut: ^drwav_int16) -> drwav_uint64 ---
	drwav_read_pcm_frames_s16le :: proc(pWav: ^drwav, framesToRead: drwav_uint64, pBufferOut: ^drwav_int16) -> drwav_uint64 ---
	drwav_read_pcm_frames_s16be :: proc(pWav: ^drwav, framesToRead: drwav_uint64, pBufferOut: ^drwav_int16) -> drwav_uint64 ---

	/* Low-level function for converting unsigned 8-bit PCM samples to signed 16-bit PCM samples. */
	drwav_u8_to_s16 :: proc(pOut: ^drwav_int16, pIn: ^drwav_uint8, sampleCount: c.size_t) ---

	/* Low-level function for converting signed 24-bit PCM samples to signed 16-bit PCM samples. */
	drwav_s24_to_s16 :: proc(pOut: ^drwav_int16, pIn: ^drwav_uint8, sampleCount: c.size_t) ---

	/* Low-level function for converting signed 32-bit PCM samples to signed 16-bit PCM samples. */
	drwav_s32_to_s16 :: proc(pOut: ^drwav_int16, pIn: ^drwav_int32, sampleCount: c.size_t) ---

	/* Low-level function for converting IEEE 32-bit floating point samples to signed 16-bit PCM samples. */
	drwav_f32_to_s16 :: proc(pOut: ^drwav_int16, pIn: ^f32, sampleCount: c.size_t) ---

	/* Low-level function for converting IEEE 64-bit floating point samples to signed 16-bit PCM samples. */
	drwav_f64_to_s16 :: proc(pOut: ^drwav_int16, pIn: ^f64, sampleCount: c.size_t) ---

	/* Low-level function for converting A-law samples to signed 16-bit PCM samples. */
	drwav_alaw_to_s16 :: proc(pOut: ^drwav_int16, pIn: ^drwav_uint8, sampleCount: c.size_t) ---

	/* Low-level function for converting u-law samples to signed 16-bit PCM samples. */
	drwav_mulaw_to_s16 :: proc(pOut: ^drwav_int16, pIn: ^drwav_uint8, sampleCount: c.size_t) ---

	/*
	Reads a chunk of audio data and converts it to IEEE 32-bit floating point samples.
	
	pBufferOut can be NULL in which case a seek will be performed.
	
	Returns the number of PCM frames actually read.
	
	If the return value is less than <framesToRead> it means the end of the file has been reached.
	*/
	drwav_read_pcm_frames_f32   :: proc(pWav: ^drwav, framesToRead: drwav_uint64, pBufferOut: ^f32) -> drwav_uint64 ---
	drwav_read_pcm_frames_f32le :: proc(pWav: ^drwav, framesToRead: drwav_uint64, pBufferOut: ^f32) -> drwav_uint64 ---
	drwav_read_pcm_frames_f32be :: proc(pWav: ^drwav, framesToRead: drwav_uint64, pBufferOut: ^f32) -> drwav_uint64 ---

	/* Low-level function for converting unsigned 8-bit PCM samples to IEEE 32-bit floating point samples. */
	drwav_u8_to_f32 :: proc(pOut: ^f32, pIn: ^drwav_uint8, sampleCount: c.size_t) ---

	/* Low-level function for converting signed 16-bit PCM samples to IEEE 32-bit floating point samples. */
	drwav_s16_to_f32 :: proc(pOut: ^f32, pIn: ^drwav_int16, sampleCount: c.size_t) ---

	/* Low-level function for converting signed 24-bit PCM samples to IEEE 32-bit floating point samples. */
	drwav_s24_to_f32 :: proc(pOut: ^f32, pIn: ^drwav_uint8, sampleCount: c.size_t) ---

	/* Low-level function for converting signed 32-bit PCM samples to IEEE 32-bit floating point samples. */
	drwav_s32_to_f32 :: proc(pOut: ^f32, pIn: ^drwav_int32, sampleCount: c.size_t) ---

	/* Low-level function for converting IEEE 64-bit floating point samples to IEEE 32-bit floating point samples. */
	drwav_f64_to_f32 :: proc(pOut: ^f32, pIn: ^f64, sampleCount: c.size_t) ---

	/* Low-level function for converting A-law samples to IEEE 32-bit floating point samples. */
	drwav_alaw_to_f32 :: proc(pOut: ^f32, pIn: ^drwav_uint8, sampleCount: c.size_t) ---

	/* Low-level function for converting u-law samples to IEEE 32-bit floating point samples. */
	drwav_mulaw_to_f32 :: proc(pOut: ^f32, pIn: ^drwav_uint8, sampleCount: c.size_t) ---

	/*
	Reads a chunk of audio data and converts it to signed 32-bit PCM samples.
	
	pBufferOut can be NULL in which case a seek will be performed.
	
	Returns the number of PCM frames actually read.
	
	If the return value is less than <framesToRead> it means the end of the file has been reached.
	*/
	drwav_read_pcm_frames_s32   :: proc(pWav: ^drwav, framesToRead: drwav_uint64, pBufferOut: ^drwav_int32) -> drwav_uint64 ---
	drwav_read_pcm_frames_s32le :: proc(pWav: ^drwav, framesToRead: drwav_uint64, pBufferOut: ^drwav_int32) -> drwav_uint64 ---
	drwav_read_pcm_frames_s32be :: proc(pWav: ^drwav, framesToRead: drwav_uint64, pBufferOut: ^drwav_int32) -> drwav_uint64 ---

	/* Low-level function for converting unsigned 8-bit PCM samples to signed 32-bit PCM samples. */
	drwav_u8_to_s32 :: proc(pOut: ^drwav_int32, pIn: ^drwav_uint8, sampleCount: c.size_t) ---

	/* Low-level function for converting signed 16-bit PCM samples to signed 32-bit PCM samples. */
	drwav_s16_to_s32 :: proc(pOut: ^drwav_int32, pIn: ^drwav_int16, sampleCount: c.size_t) ---

	/* Low-level function for converting signed 24-bit PCM samples to signed 32-bit PCM samples. */
	drwav_s24_to_s32 :: proc(pOut: ^drwav_int32, pIn: ^drwav_uint8, sampleCount: c.size_t) ---

	/* Low-level function for converting IEEE 32-bit floating point samples to signed 32-bit PCM samples. */
	drwav_f32_to_s32 :: proc(pOut: ^drwav_int32, pIn: ^f32, sampleCount: c.size_t) ---

	/* Low-level function for converting IEEE 64-bit floating point samples to signed 32-bit PCM samples. */
	drwav_f64_to_s32 :: proc(pOut: ^drwav_int32, pIn: ^f64, sampleCount: c.size_t) ---

	/* Low-level function for converting A-law samples to signed 32-bit PCM samples. */
	drwav_alaw_to_s32 :: proc(pOut: ^drwav_int32, pIn: ^drwav_uint8, sampleCount: c.size_t) ---

	/* Low-level function for converting u-law samples to signed 32-bit PCM samples. */
	drwav_mulaw_to_s32 :: proc(pOut: ^drwav_int32, pIn: ^drwav_uint8, sampleCount: c.size_t) ---

	/*
	Helper for initializing a wave file for reading using stdio.
	
	This holds the internal FILE object until drwav_uninit() is called. Keep this in mind if you're caching drwav
	objects because the operating system may restrict the number of file handles an application can have open at
	any given time.
	*/
	drwav_init_file                 :: proc(pWav: ^drwav, filename: cstring, pAllocationCallbacks: ^drwav_allocation_callbacks) -> drwav_bool32 ---
	drwav_init_file_ex              :: proc(pWav: ^drwav, filename: cstring, onChunk: drwav_chunk_proc, pChunkUserData: rawptr, flags: drwav_uint32, pAllocationCallbacks: ^drwav_allocation_callbacks) -> drwav_bool32 ---
	drwav_init_file_w               :: proc(pWav: ^drwav, filename: ^c.wchar_t, pAllocationCallbacks: ^drwav_allocation_callbacks) -> drwav_bool32 ---
	drwav_init_file_ex_w            :: proc(pWav: ^drwav, filename: ^c.wchar_t, onChunk: drwav_chunk_proc, pChunkUserData: rawptr, flags: drwav_uint32, pAllocationCallbacks: ^drwav_allocation_callbacks) -> drwav_bool32 ---
	drwav_init_file_with_metadata   :: proc(pWav: ^drwav, filename: cstring, flags: drwav_uint32, pAllocationCallbacks: ^drwav_allocation_callbacks) -> drwav_bool32 ---
	drwav_init_file_with_metadata_w :: proc(pWav: ^drwav, filename: ^c.wchar_t, flags: drwav_uint32, pAllocationCallbacks: ^drwav_allocation_callbacks) -> drwav_bool32 ---

	/*
	Helper for initializing a wave file for writing using stdio.
	
	This holds the internal FILE object until drwav_uninit() is called. Keep this in mind if you're caching drwav
	objects because the operating system may restrict the number of file handles an application can have open at
	any given time.
	*/
	drwav_init_file_write                         :: proc(pWav: ^drwav, filename: cstring, pFormat: ^drwav_data_format, pAllocationCallbacks: ^drwav_allocation_callbacks) -> drwav_bool32 ---
	drwav_init_file_write_sequential              :: proc(pWav: ^drwav, filename: cstring, pFormat: ^drwav_data_format, totalSampleCount: drwav_uint64, pAllocationCallbacks: ^drwav_allocation_callbacks) -> drwav_bool32 ---
	drwav_init_file_write_sequential_pcm_frames   :: proc(pWav: ^drwav, filename: cstring, pFormat: ^drwav_data_format, totalPCMFrameCount: drwav_uint64, pAllocationCallbacks: ^drwav_allocation_callbacks) -> drwav_bool32 ---
	drwav_init_file_write_w                       :: proc(pWav: ^drwav, filename: ^c.wchar_t, pFormat: ^drwav_data_format, pAllocationCallbacks: ^drwav_allocation_callbacks) -> drwav_bool32 ---
	drwav_init_file_write_sequential_w            :: proc(pWav: ^drwav, filename: ^c.wchar_t, pFormat: ^drwav_data_format, totalSampleCount: drwav_uint64, pAllocationCallbacks: ^drwav_allocation_callbacks) -> drwav_bool32 ---
	drwav_init_file_write_sequential_pcm_frames_w :: proc(pWav: ^drwav, filename: ^c.wchar_t, pFormat: ^drwav_data_format, totalPCMFrameCount: drwav_uint64, pAllocationCallbacks: ^drwav_allocation_callbacks) -> drwav_bool32 ---

	/*
	Helper for initializing a loader from a pre-allocated memory buffer.
	
	This does not create a copy of the data. It is up to the application to ensure the buffer remains valid for
	the lifetime of the drwav object.
	
	The buffer should contain the contents of the entire wave file, not just the sample data.
	*/
	drwav_init_memory               :: proc(pWav: ^drwav, data: rawptr, dataSize: c.size_t, pAllocationCallbacks: ^drwav_allocation_callbacks) -> drwav_bool32 ---
	drwav_init_memory_ex            :: proc(pWav: ^drwav, data: rawptr, dataSize: c.size_t, onChunk: drwav_chunk_proc, pChunkUserData: rawptr, flags: drwav_uint32, pAllocationCallbacks: ^drwav_allocation_callbacks) -> drwav_bool32 ---
	drwav_init_memory_with_metadata :: proc(pWav: ^drwav, data: rawptr, dataSize: c.size_t, flags: drwav_uint32, pAllocationCallbacks: ^drwav_allocation_callbacks) -> drwav_bool32 ---

	/*
	Helper for initializing a writer which outputs data to a memory buffer.
	
	dr_wav will manage the memory allocations, however it is up to the caller to free the data with drwav_free().
	
	The buffer will remain allocated even after drwav_uninit() is called. The buffer should not be considered valid
	until after drwav_uninit() has been called.
	*/
	drwav_init_memory_write                       :: proc(pWav: ^drwav, ppData: ^rawptr, pDataSize: ^c.size_t, pFormat: ^drwav_data_format, pAllocationCallbacks: ^drwav_allocation_callbacks) -> drwav_bool32 ---
	drwav_init_memory_write_sequential            :: proc(pWav: ^drwav, ppData: ^rawptr, pDataSize: ^c.size_t, pFormat: ^drwav_data_format, totalSampleCount: drwav_uint64, pAllocationCallbacks: ^drwav_allocation_callbacks) -> drwav_bool32 ---
	drwav_init_memory_write_sequential_pcm_frames :: proc(pWav: ^drwav, ppData: ^rawptr, pDataSize: ^c.size_t, pFormat: ^drwav_data_format, totalPCMFrameCount: drwav_uint64, pAllocationCallbacks: ^drwav_allocation_callbacks) -> drwav_bool32 ---

	/*
	Opens and reads an entire wav file in a single operation.
	
	The return value is a heap-allocated buffer containing the audio data. Use drwav_free() to free the buffer.
	*/
	drwav_open_and_read_pcm_frames_s16 :: proc(onRead: drwav_read_proc, onSeek: drwav_seek_proc, onTell: drwav_tell_proc, pUserData: rawptr, channelsOut: ^c.uint, sampleRateOut: ^c.uint, totalFrameCountOut: ^drwav_uint64, pAllocationCallbacks: ^drwav_allocation_callbacks) -> ^drwav_int16 ---
	drwav_open_and_read_pcm_frames_f32 :: proc(onRead: drwav_read_proc, onSeek: drwav_seek_proc, onTell: drwav_tell_proc, pUserData: rawptr, channelsOut: ^c.uint, sampleRateOut: ^c.uint, totalFrameCountOut: ^drwav_uint64, pAllocationCallbacks: ^drwav_allocation_callbacks) -> ^f32 ---
	drwav_open_and_read_pcm_frames_s32 :: proc(onRead: drwav_read_proc, onSeek: drwav_seek_proc, onTell: drwav_tell_proc, pUserData: rawptr, channelsOut: ^c.uint, sampleRateOut: ^c.uint, totalFrameCountOut: ^drwav_uint64, pAllocationCallbacks: ^drwav_allocation_callbacks) -> ^drwav_int32 ---

	/*
	Opens and decodes an entire wav file in a single operation.
	
	The return value is a heap-allocated buffer containing the audio data. Use drwav_free() to free the buffer.
	*/
	drwav_open_file_and_read_pcm_frames_s16   :: proc(filename: cstring, channelsOut: ^c.uint, sampleRateOut: ^c.uint, totalFrameCountOut: ^drwav_uint64, pAllocationCallbacks: ^drwav_allocation_callbacks) -> ^drwav_int16 ---
	drwav_open_file_and_read_pcm_frames_f32   :: proc(filename: cstring, channelsOut: ^c.uint, sampleRateOut: ^c.uint, totalFrameCountOut: ^drwav_uint64, pAllocationCallbacks: ^drwav_allocation_callbacks) -> ^f32 ---
	drwav_open_file_and_read_pcm_frames_s32   :: proc(filename: cstring, channelsOut: ^c.uint, sampleRateOut: ^c.uint, totalFrameCountOut: ^drwav_uint64, pAllocationCallbacks: ^drwav_allocation_callbacks) -> ^drwav_int32 ---
	drwav_open_file_and_read_pcm_frames_s16_w :: proc(filename: ^c.wchar_t, channelsOut: ^c.uint, sampleRateOut: ^c.uint, totalFrameCountOut: ^drwav_uint64, pAllocationCallbacks: ^drwav_allocation_callbacks) -> ^drwav_int16 ---
	drwav_open_file_and_read_pcm_frames_f32_w :: proc(filename: ^c.wchar_t, channelsOut: ^c.uint, sampleRateOut: ^c.uint, totalFrameCountOut: ^drwav_uint64, pAllocationCallbacks: ^drwav_allocation_callbacks) -> ^f32 ---
	drwav_open_file_and_read_pcm_frames_s32_w :: proc(filename: ^c.wchar_t, channelsOut: ^c.uint, sampleRateOut: ^c.uint, totalFrameCountOut: ^drwav_uint64, pAllocationCallbacks: ^drwav_allocation_callbacks) -> ^drwav_int32 ---

	/*
	Opens and decodes an entire wav file from a block of memory in a single operation.
	
	The return value is a heap-allocated buffer containing the audio data. Use drwav_free() to free the buffer.
	*/
	drwav_open_memory_and_read_pcm_frames_s16 :: proc(data: rawptr, dataSize: c.size_t, channelsOut: ^c.uint, sampleRateOut: ^c.uint, totalFrameCountOut: ^drwav_uint64, pAllocationCallbacks: ^drwav_allocation_callbacks) -> ^drwav_int16 ---
	drwav_open_memory_and_read_pcm_frames_f32 :: proc(data: rawptr, dataSize: c.size_t, channelsOut: ^c.uint, sampleRateOut: ^c.uint, totalFrameCountOut: ^drwav_uint64, pAllocationCallbacks: ^drwav_allocation_callbacks) -> ^f32 ---
	drwav_open_memory_and_read_pcm_frames_s32 :: proc(data: rawptr, dataSize: c.size_t, channelsOut: ^c.uint, sampleRateOut: ^c.uint, totalFrameCountOut: ^drwav_uint64, pAllocationCallbacks: ^drwav_allocation_callbacks) -> ^drwav_int32 ---

	/* Frees data that was allocated internally by dr_wav. */
	drwav_free :: proc(p: rawptr, pAllocationCallbacks: ^drwav_allocation_callbacks) ---

	/* Converts bytes from a wav stream to a sized type of native endian. */
	drwav_bytes_to_u16 :: proc(data: ^drwav_uint8) -> drwav_uint16 ---
	drwav_bytes_to_s16 :: proc(data: ^drwav_uint8) -> drwav_int16 ---
	drwav_bytes_to_u32 :: proc(data: ^drwav_uint8) -> drwav_uint32 ---
	drwav_bytes_to_s32 :: proc(data: ^drwav_uint8) -> drwav_int32 ---
	drwav_bytes_to_u64 :: proc(data: ^drwav_uint8) -> drwav_uint64 ---
	drwav_bytes_to_s64 :: proc(data: ^drwav_uint8) -> drwav_int64 ---
	drwav_bytes_to_f32 :: proc(data: ^drwav_uint8) -> f32 ---

	/* Compares a GUID for the purpose of checking the type of a Wave64 chunk. */
	drwav_guid_equal :: proc(a: ^drwav_uint8, b: ^drwav_uint8) -> drwav_bool32 ---

	/* Compares a four-character-code for the purpose of checking the type of a RIFF chunk. */
	drwav_fourcc_equal :: proc(a: ^drwav_uint8, b: cstring) -> drwav_bool32 ---
}
