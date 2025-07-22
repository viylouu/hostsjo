/*
MP3 audio decoder. Choice of public domain or MIT-0. See license statements at the end of this file.
dr_mp3 - v0.7.0 - TBD

David Reid - mackron@gmail.com

GitHub: https://github.com/mackron/dr_libs

Based on minimp3 (https://github.com/lieff/minimp3) which is where the real work was done. See the bottom of this file for differences between minimp3 and dr_mp3.
*/
/*
Introduction
=============
dr_mp3 is a single file library. To use it, do something like the following in one .c file.

```c
#define DR_MP3_IMPLEMENTATION
#include "dr_mp3.h"
```

You can then #include this file in other parts of the program as you would with any other header file. To decode audio data, do something like the following:

```c
drmp3 mp3;
if (!drmp3_init_file(&mp3, "MySong.mp3", NULL)) {
// Failed to open file
}

...

drmp3_uint64 framesRead = drmp3_read_pcm_frames_f32(pMP3, framesToRead, pFrames);
```

The drmp3 object is transparent so you can get access to the channel count and sample rate like so:

```
drmp3_uint32 channels = mp3.channels;
drmp3_uint32 sampleRate = mp3.sampleRate;
```

The example above initializes a decoder from a file, but you can also initialize it from a block of memory and read and seek callbacks with
`drmp3_init_memory()` and `drmp3_init()` respectively.

You do not need to do any annoying memory management when reading PCM frames - this is all managed internally. You can request any number of PCM frames in each
call to `drmp3_read_pcm_frames_f32()` and it will return as many PCM frames as it can, up to the requested amount.

You can also decode an entire file in one go with `drmp3_open_and_read_pcm_frames_f32()`, `drmp3_open_memory_and_read_pcm_frames_f32()` and
`drmp3_open_file_and_read_pcm_frames_f32()`.


Build Options
=============
#define these options before including this file.

#define DR_MP3_NO_STDIO
Disable drmp3_init_file(), etc.

#define DR_MP3_NO_SIMD
Disable SIMD optimizations.
*/
package dr_mp3

when ODIN_OS == .Windows do foreign import lib "libdr_mp3.lib"
when ODIN_OS == .Linux do foreign import lib "libdr_mp3.a"

import "core:c"

_ :: c



DRMP3_VERSION_MAJOR     :: 0
DRMP3_VERSION_MINOR     :: 7
DRMP3_VERSION_REVISION  :: 0
// DRMP3_VERSION_STRING    :: #DRMP3_VERSION_MAJOR "." #DRMP3_VERSION_MINOR "." #DRMP3_VERSION_REVISION

/* Sized Types */
drmp3_int8 :: c.schar

drmp3_uint8 :: c.uchar

drmp3_int16 :: c.short

drmp3_uint16 :: c.ushort

drmp3_int32 :: c.int

drmp3_uint32 :: c.uint

drmp3_int64 :: c.longlong

drmp3_uint64 :: c.ulonglong

drmp3_uintptr :: drmp3_uint64

drmp3_bool8 :: drmp3_uint8

DRMP3_TRUE              :: 1

drmp3_bool32 :: drmp3_uint32

DRMP3_FALSE             :: 0

/* Weird shifting syntax is for VC6 compatibility. */
DRMP3_UINT64_MAX        :: (cast(drmp3_uint64)0xFFFFFFFF << 32) | cast(drmp3_uint64)0xFFFFFFFF

// DRMP3_API  :: extern

// DRMP3_PRIVATE :: static

DRMP3_SUCCESS                        :: 0

/* Result Codes */
drmp3_result :: drmp3_int32

DRMP3_ERROR                         :: -1   /* A generic error. */
DRMP3_INVALID_ARGS                  :: -2
DRMP3_INVALID_OPERATION             :: -3
DRMP3_OUT_OF_MEMORY                 :: -4
DRMP3_OUT_OF_RANGE                  :: -5
DRMP3_ACCESS_DENIED                 :: -6
DRMP3_DOES_NOT_EXIST                :: -7
DRMP3_ALREADY_EXISTS                :: -8
DRMP3_TOO_MANY_OPEN_FILES           :: -9
DRMP3_INVALID_FILE                  :: -10
DRMP3_TOO_BIG                       :: -11
DRMP3_PATH_TOO_LONG                 :: -12
DRMP3_NAME_TOO_LONG                 :: -13
DRMP3_NOT_DIRECTORY                 :: -14
DRMP3_IS_DIRECTORY                  :: -15
DRMP3_DIRECTORY_NOT_EMPTY           :: -16
DRMP3_END_OF_FILE                   :: -17
DRMP3_NO_SPACE                      :: -18
DRMP3_BUSY                          :: -19
DRMP3_IO_ERROR                      :: -20
DRMP3_INTERRUPT                     :: -21
DRMP3_UNAVAILABLE                   :: -22
DRMP3_ALREADY_IN_USE                :: -23
DRMP3_BAD_ADDRESS                   :: -24
DRMP3_BAD_SEEK                      :: -25
DRMP3_BAD_PIPE                      :: -26
DRMP3_DEADLOCK                      :: -27
DRMP3_TOO_MANY_LINKS                :: -28
DRMP3_NOT_IMPLEMENTED               :: -29
DRMP3_NO_MESSAGE                    :: -30
DRMP3_BAD_MESSAGE                   :: -31
DRMP3_NO_DATA_AVAILABLE             :: -32
DRMP3_INVALID_DATA                  :: -33
DRMP3_TIMEOUT                       :: -34
DRMP3_NO_NETWORK                    :: -35
DRMP3_NOT_UNIQUE                    :: -36
DRMP3_NOT_SOCKET                    :: -37
DRMP3_NO_ADDRESS                    :: -38
DRMP3_BAD_PROTOCOL                  :: -39
DRMP3_PROTOCOL_UNAVAILABLE          :: -40
DRMP3_PROTOCOL_NOT_SUPPORTED        :: -41
DRMP3_PROTOCOL_FAMILY_NOT_SUPPORTED :: -42
DRMP3_ADDRESS_FAMILY_NOT_SUPPORTED  :: -43
DRMP3_SOCKET_NOT_SUPPORTED          :: -44
DRMP3_CONNECTION_RESET              :: -45
DRMP3_ALREADY_CONNECTED             :: -46
DRMP3_NOT_CONNECTED                 :: -47
DRMP3_CONNECTION_REFUSED            :: -48
DRMP3_NO_HOST                       :: -49
DRMP3_IN_PROGRESS                   :: -50
DRMP3_CANCELLED                     :: -51
DRMP3_MEMORY_ALREADY_MAPPED         :: -52
DRMP3_AT_END                        :: -53

/* End Result Codes */
DRMP3_MAX_PCM_FRAMES_PER_MP3_FRAME  :: 1152
DRMP3_MAX_SAMPLES_PER_FRAME         :: DRMP3_MAX_PCM_FRAMES_PER_MP3_FRAME*2

// DRMP3_INLINE :: DRMP3_GNUC_INLINE_HINT _attribute__((always_inline))

// DRMP3_GNUC_INLINE_HINT :: inline

/* Allocation Callbacks */
drmp3_allocation_callbacks :: struct {
	pUserData: rawptr,
	onMalloc:  proc "c" (c.size_t, rawptr) -> rawptr,
	onRealloc: proc "c" (rawptr, c.size_t, rawptr) -> rawptr,
	onFree:    proc "c" (rawptr, rawptr),
}

/*
Low Level Push API
==================
*/
drmp3dec_frame_info :: struct {
	frame_bytes, channels, sample_rate, layer, bitrate_kbps: c.int,
}

drmp3dec :: struct {
	mdct_overlap:              [2][288]f32,
	qmf_state:                 [960]f32,
	reserv, free_format_bytes: c.int,
	header:                    [4]drmp3_uint8,
	reserv_buf:                [511]drmp3_uint8,
}

/*
Main API (Pull API)
===================
*/
drmp3_seek_origin :: enum c.int {
	SET,
	CUR,
	END,
}

drmp3_seek_point :: struct {
	seekPosInBytes:     drmp3_uint64, /* Points to the first byte of an MP3 frame. */
	pcmFrameIndex:      drmp3_uint64, /* The index of the PCM frame this seek point targets. */
	mp3FramesToDiscard: drmp3_uint16, /* The number of whole MP3 frames to be discarded before pcmFramesToDiscard. */
	pcmFramesToDiscard: drmp3_uint16, /* The number of leading samples to read and discard. These are discarded after mp3FramesToDiscard. */
}

drmp3_metadata_type :: enum c.int {
	ID3V1,
	ID3V2,
	APE,
	XING,
	VBRI,
}

drmp3_metadata :: struct {
	type:        drmp3_metadata_type,
	pRawData:    rawptr, /* A pointer to the raw data. */
	rawDataSize: c.size_t,
}

/*
Callback for when data is read. Return value is the number of bytes actually read.

pUserData   [in]  The user data that was passed to drmp3_init(), and family.
pBufferOut  [out] The output buffer.
bytesToRead [in]  The number of bytes to read.

Returns the number of bytes actually read.

A return value of less than bytesToRead indicates the end of the stream. Do _not_ return from this callback until
either the entire bytesToRead is filled or you have reached the end of the stream.
*/
drmp3_read_proc :: proc "c" (rawptr, rawptr, c.size_t) -> c.size_t

/*
Callback for when data needs to be seeked.

pUserData [in] The user data that was passed to drmp3_init(), and family.
offset    [in] The number of bytes to move, relative to the origin. Can be negative.
origin    [in] The origin of the seek.

Returns whether or not the seek was successful.
*/
drmp3_seek_proc :: proc "c" (rawptr, c.int, drmp3_seek_origin) -> drmp3_bool32

/*
Callback for retrieving the current cursor position.

pUserData [in]  The user data that was passed to drmp3_init(), and family.
pCursor   [out] The cursor position in bytes from the start of the stream.

Returns whether or not the cursor position was successfully retrieved.
*/
drmp3_tell_proc :: proc "c" (rawptr, ^drmp3_int64) -> drmp3_bool32

/*
Callback for when metadata is read.

Only the raw data is provided. The client is responsible for parsing the contents of the data themsevles.
*/
drmp3_meta_proc :: proc "c" (rawptr, ^drmp3_metadata)

drmp3_config :: struct {
	channels:   drmp3_uint32,
	sampleRate: drmp3_uint32,
}

drmp3 :: struct {
	decoder:                      drmp3dec,
	channels:                     drmp3_uint32,
	sampleRate:                   drmp3_uint32,
	onRead:                       drmp3_read_proc,
	onSeek:                       drmp3_seek_proc,
	onMeta:                       drmp3_meta_proc,
	pUserData:                    rawptr,
	pUserDataMeta:                rawptr,
	allocationCallbacks:          drmp3_allocation_callbacks,
	mp3FrameChannels:             drmp3_uint32,                                                                                        /* The number of channels in the currently loaded MP3 frame. Internal use only. */
	mp3FrameSampleRate:           drmp3_uint32,                                                                                        /* The sample rate of the currently loaded MP3 frame. Internal use only. */
	pcmFramesConsumedInMP3Frame:  drmp3_uint32,
	pcmFramesRemainingInMP3Frame: drmp3_uint32,
	pcmFrames:                    [9216]drmp3_uint8,                                                                                   /* <-- Multipled by sizeof(float) to ensure there's enough room for DR_MP3_FLOAT_OUTPUT. */
	currentPCMFrame:              drmp3_uint64,                                                                                        /* The current PCM frame, globally. */
	streamCursor:                 drmp3_uint64,                                                                                        /* The current byte the decoder is sitting on in the raw stream. */
	streamLength:                 drmp3_uint64,                                                                                        /* The length of the stream in bytes. dr_mp3 will not read beyond this. If a ID3v1 or APE tag is present, this will be set to the first byte of the tag. */
	streamStartOffset:            drmp3_uint64,                                                                                        /* The offset of the start of the MP3 data. This is used for skipping ID3v2 and VBR tags. */
	pSeekPoints:                  ^drmp3_seek_point,                                                                                   /* NULL by default. Set with drmp3_bind_seek_table(). Memory is owned by the client. dr_mp3 will never attempt to free this pointer. */
	seekPointCount:               drmp3_uint32,                                                                                        /* The number of items in pSeekPoints. When set to 0 assumes to no seek table. Defaults to zero. */
	delayInPCMFrames:             drmp3_uint32,
	paddingInPCMFrames:           drmp3_uint32,
	totalPCMFrameCount:           drmp3_uint64,                                                                                        /* Set to DRMP3_UINT64_MAX if the length is unknown. Includes delay and padding. */
	isVBR:                        drmp3_bool32,
	isCBR:                        drmp3_bool32,
	dataSize:                     c.size_t,
	dataCapacity:                 c.size_t,
	dataConsumed:                 c.size_t,
	pData:                        ^drmp3_uint8,
	atEnd:                        drmp3_bool32,
	memory:                       struct {
		pData:          ^drmp3_uint8,
		dataSize:       c.size_t,
		currentReadPos: c.size_t,
	}, /* Only used for decoders that were opened against a block of memory. */
}

@(default_calling_convention="c", link_prefix="")
foreign lib {
	/* End Inline */
	drmp3_version        :: proc(pMajor: ^drmp3_uint32, pMinor: ^drmp3_uint32, pRevision: ^drmp3_uint32) ---
	drmp3_version_string :: proc() -> cstring ---

	/* Initializes a low level decoder. */
	drmp3dec_init :: proc(dec: ^drmp3dec) ---

	/* Reads a frame from a low level decoder. */
	drmp3dec_decode_frame :: proc(dec: ^drmp3dec, mp3: ^drmp3_uint8, mp3_bytes: c.int, pcm: rawptr, info: ^drmp3dec_frame_info) -> c.int ---

	/* Helper for converting between f32 and s16. */
	drmp3dec_f32_to_s16 :: proc(_in: ^f32, out: ^drmp3_int16, num_samples: c.size_t) ---

	/*
	Initializes an MP3 decoder.
	
	onRead    [in]           The function to call when data needs to be read from the client.
	onSeek    [in]           The function to call when the read position of the client data needs to move.
	onTell    [in]           The function to call when the read position of the client data needs to be retrieved.
	pUserData [in, optional] A pointer to application defined data that will be passed to onRead and onSeek.
	
	Returns true if successful; false otherwise.
	
	Close the loader with drmp3_uninit().
	
	See also: drmp3_init_file(), drmp3_init_memory(), drmp3_uninit()
	*/
	drmp3_init :: proc(pMP3: ^drmp3, onRead: drmp3_read_proc, onSeek: drmp3_seek_proc, onTell: drmp3_tell_proc, onMeta: drmp3_meta_proc, pUserData: rawptr, pAllocationCallbacks: ^drmp3_allocation_callbacks) -> drmp3_bool32 ---

	/*
	Initializes an MP3 decoder from a block of memory.
	
	This does not create a copy of the data. It is up to the application to ensure the buffer remains valid for
	the lifetime of the drmp3 object.
	
	The buffer should contain the contents of the entire MP3 file.
	*/
	drmp3_init_memory_with_metadata :: proc(pMP3: ^drmp3, pData: rawptr, dataSize: c.size_t, onMeta: drmp3_meta_proc, pUserDataMeta: rawptr, pAllocationCallbacks: ^drmp3_allocation_callbacks) -> drmp3_bool32 ---
	drmp3_init_memory               :: proc(pMP3: ^drmp3, pData: rawptr, dataSize: c.size_t, pAllocationCallbacks: ^drmp3_allocation_callbacks) -> drmp3_bool32 ---

	/*
	Initializes an MP3 decoder from a file.
	
	This holds the internal FILE object until drmp3_uninit() is called. Keep this in mind if you're caching drmp3
	objects because the operating system may restrict the number of file handles an application can have open at
	any given time.
	*/
	drmp3_init_file_with_metadata   :: proc(pMP3: ^drmp3, pFilePath: cstring, onMeta: drmp3_meta_proc, pUserDataMeta: rawptr, pAllocationCallbacks: ^drmp3_allocation_callbacks) -> drmp3_bool32 ---
	drmp3_init_file_with_metadata_w :: proc(pMP3: ^drmp3, pFilePath: ^c.wchar_t, onMeta: drmp3_meta_proc, pUserDataMeta: rawptr, pAllocationCallbacks: ^drmp3_allocation_callbacks) -> drmp3_bool32 ---
	drmp3_init_file                 :: proc(pMP3: ^drmp3, pFilePath: cstring, pAllocationCallbacks: ^drmp3_allocation_callbacks) -> drmp3_bool32 ---
	drmp3_init_file_w               :: proc(pMP3: ^drmp3, pFilePath: ^c.wchar_t, pAllocationCallbacks: ^drmp3_allocation_callbacks) -> drmp3_bool32 ---

	/*
	Uninitializes an MP3 decoder.
	*/
	drmp3_uninit :: proc(pMP3: ^drmp3) ---

	/*
	Reads PCM frames as interleaved 32-bit IEEE floating point PCM.
	
	Note that framesToRead specifies the number of PCM frames to read, _not_ the number of MP3 frames.
	*/
	drmp3_read_pcm_frames_f32 :: proc(pMP3: ^drmp3, framesToRead: drmp3_uint64, pBufferOut: ^f32) -> drmp3_uint64 ---

	/*
	Reads PCM frames as interleaved signed 16-bit integer PCM.
	
	Note that framesToRead specifies the number of PCM frames to read, _not_ the number of MP3 frames.
	*/
	drmp3_read_pcm_frames_s16 :: proc(pMP3: ^drmp3, framesToRead: drmp3_uint64, pBufferOut: ^drmp3_int16) -> drmp3_uint64 ---

	/*
	Seeks to a specific frame.
	
	Note that this is _not_ an MP3 frame, but rather a PCM frame.
	*/
	drmp3_seek_to_pcm_frame :: proc(pMP3: ^drmp3, frameIndex: drmp3_uint64) -> drmp3_bool32 ---

	/*
	Calculates the total number of PCM frames in the MP3 stream. Cannot be used for infinite streams such as internet
	radio. Runs in linear time. Returns 0 on error.
	*/
	drmp3_get_pcm_frame_count :: proc(pMP3: ^drmp3) -> drmp3_uint64 ---

	/*
	Calculates the total number of MP3 frames in the MP3 stream. Cannot be used for infinite streams such as internet
	radio. Runs in linear time. Returns 0 on error.
	*/
	drmp3_get_mp3_frame_count :: proc(pMP3: ^drmp3) -> drmp3_uint64 ---

	/*
	Calculates the total number of MP3 and PCM frames in the MP3 stream. Cannot be used for infinite streams such as internet
	radio. Runs in linear time. Returns 0 on error.
	
	This is equivalent to calling drmp3_get_mp3_frame_count() and drmp3_get_pcm_frame_count() except that it's more efficient.
	*/
	drmp3_get_mp3_and_pcm_frame_count :: proc(pMP3: ^drmp3, pMP3FrameCount: ^drmp3_uint64, pPCMFrameCount: ^drmp3_uint64) -> drmp3_bool32 ---

	/*
	Calculates the seekpoints based on PCM frames. This is slow.
	
	pSeekpoint count is a pointer to a uint32 containing the seekpoint count. On input it contains the desired count.
	On output it contains the actual count. The reason for this design is that the client may request too many
	seekpoints, in which case dr_mp3 will return a corrected count.
	
	Note that seektable seeking is not quite sample exact when the MP3 stream contains inconsistent sample rates.
	*/
	drmp3_calculate_seek_points :: proc(pMP3: ^drmp3, pSeekPointCount: ^drmp3_uint32, pSeekPoints: ^drmp3_seek_point) -> drmp3_bool32 ---

	/*
	Binds a seek table to the decoder.
	
	This does _not_ make a copy of pSeekPoints - it only references it. It is up to the application to ensure this
	remains valid while it is bound to the decoder.
	
	Use drmp3_calculate_seek_points() to calculate the seek points.
	*/
	drmp3_bind_seek_table :: proc(pMP3: ^drmp3, seekPointCount: drmp3_uint32, pSeekPoints: ^drmp3_seek_point) -> drmp3_bool32 ---

	/*
	Opens an decodes an entire MP3 stream as a single operation.
	
	On output pConfig will receive the channel count and sample rate of the stream.
	
	Free the returned pointer with drmp3_free().
	*/
	drmp3_open_and_read_pcm_frames_f32        :: proc(onRead: drmp3_read_proc, onSeek: drmp3_seek_proc, onTell: drmp3_tell_proc, pUserData: rawptr, pConfig: ^drmp3_config, pTotalFrameCount: ^drmp3_uint64, pAllocationCallbacks: ^drmp3_allocation_callbacks) -> ^f32 ---
	drmp3_open_and_read_pcm_frames_s16        :: proc(onRead: drmp3_read_proc, onSeek: drmp3_seek_proc, onTell: drmp3_tell_proc, pUserData: rawptr, pConfig: ^drmp3_config, pTotalFrameCount: ^drmp3_uint64, pAllocationCallbacks: ^drmp3_allocation_callbacks) -> ^drmp3_int16 ---
	drmp3_open_memory_and_read_pcm_frames_f32 :: proc(pData: rawptr, dataSize: c.size_t, pConfig: ^drmp3_config, pTotalFrameCount: ^drmp3_uint64, pAllocationCallbacks: ^drmp3_allocation_callbacks) -> ^f32 ---
	drmp3_open_memory_and_read_pcm_frames_s16 :: proc(pData: rawptr, dataSize: c.size_t, pConfig: ^drmp3_config, pTotalFrameCount: ^drmp3_uint64, pAllocationCallbacks: ^drmp3_allocation_callbacks) -> ^drmp3_int16 ---
	drmp3_open_file_and_read_pcm_frames_f32   :: proc(filePath: cstring, pConfig: ^drmp3_config, pTotalFrameCount: ^drmp3_uint64, pAllocationCallbacks: ^drmp3_allocation_callbacks) -> ^f32 ---
	drmp3_open_file_and_read_pcm_frames_s16   :: proc(filePath: cstring, pConfig: ^drmp3_config, pTotalFrameCount: ^drmp3_uint64, pAllocationCallbacks: ^drmp3_allocation_callbacks) -> ^drmp3_int16 ---

	/*
	Allocates a block of memory on the heap.
	*/
	drmp3_malloc :: proc(sz: c.size_t, pAllocationCallbacks: ^drmp3_allocation_callbacks) -> rawptr ---

	/*
	Frees any memory that was allocated by a public drmp3 API.
	*/
	drmp3_free :: proc(p: rawptr, pAllocationCallbacks: ^drmp3_allocation_callbacks) ---
}
