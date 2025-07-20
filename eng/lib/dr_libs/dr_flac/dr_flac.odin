/*
FLAC audio decoder. Choice of public domain or MIT-0. See license statements at the end of this file.
dr_flac - v0.13.0 - TBD

David Reid - mackron@gmail.com

GitHub: https://github.com/mackron/dr_libs
*/
/*
Introduction
============
dr_flac is a single file library. To use it, do something like the following in one .c file.

```c
#define DR_FLAC_IMPLEMENTATION
#include "dr_flac.h"
```

You can then #include this file in other parts of the program as you would with any other header file. To decode audio data, do something like the following:

```c
drflac* pFlac = drflac_open_file("MySong.flac", NULL);
if (pFlac == NULL) {
// Failed to open FLAC file
}

drflac_int32* pSamples = malloc(pFlac->totalPCMFrameCount * pFlac->channels * sizeof(drflac_int32));
drflac_uint64 numberOfInterleavedSamplesActuallyRead = drflac_read_pcm_frames_s32(pFlac, pFlac->totalPCMFrameCount, pSamples);
```

The drflac object represents the decoder. It is a transparent type so all the information you need, such as the number of channels and the bits per sample,
should be directly accessible - just make sure you don't change their values. Samples are always output as interleaved signed 32-bit PCM. In the example above
a native FLAC stream was opened, however dr_flac has seamless support for Ogg encapsulated FLAC streams as well.

You do not need to decode the entire stream in one go - you just specify how many samples you'd like at any given time and the decoder will give you as many
samples as it can, up to the amount requested. Later on when you need the next batch of samples, just call it again. Example:

```c
while (drflac_read_pcm_frames_s32(pFlac, chunkSizeInPCMFrames, pChunkSamples) > 0) {
do_something();
}
```

You can seek to a specific PCM frame with `drflac_seek_to_pcm_frame()`.

If you just want to quickly decode an entire FLAC file in one go you can do something like this:

```c
unsigned int channels;
unsigned int sampleRate;
drflac_uint64 totalPCMFrameCount;
drflac_int32* pSampleData = drflac_open_file_and_read_pcm_frames_s32("MySong.flac", &channels, &sampleRate, &totalPCMFrameCount, NULL);
if (pSampleData == NULL) {
// Failed to open and decode FLAC file.
}

...

drflac_free(pSampleData, NULL);
```

You can read samples as signed 16-bit integer and 32-bit floating-point PCM with the *_s16() and *_f32() family of APIs respectively, but note that these
should be considered lossy.


If you need access to metadata (album art, etc.), use `drflac_open_with_metadata()`, `drflac_open_file_with_metdata()` or `drflac_open_memory_with_metadata()`.
The rationale for keeping these APIs separate is that they're slightly slower than the normal versions and also just a little bit harder to use. dr_flac
reports metadata to the application through the use of a callback, and every metadata block is reported before `drflac_open_with_metdata()` returns.

The main opening APIs (`drflac_open()`, etc.) will fail if the header is not present. The presents a problem in certain scenarios such as broadcast style
streams or internet radio where the header may not be present because the user has started playback mid-stream. To handle this, use the relaxed APIs:

`drflac_open_relaxed()`
`drflac_open_with_metadata_relaxed()`

It is not recommended to use these APIs for file based streams because a missing header would usually indicate a corrupt or perverse file. In addition, these
APIs can take a long time to initialize because they may need to spend a lot of time finding the first frame.



Build Options
=============
#define these options before including this file.

#define DR_FLAC_NO_STDIO
Disable `drflac_open_file()` and family.

#define DR_FLAC_NO_OGG
Disables support for Ogg/FLAC streams.

#define DR_FLAC_BUFFER_SIZE <number>
Defines the size of the internal buffer to store data from onRead(). This buffer is used to reduce the number of calls back to the client for more data.
Larger values means more memory, but better performance. My tests show diminishing returns after about 4KB (which is the default). Consider reducing this if
you have a very efficient implementation of onRead(), or increase it if it's very inefficient. Must be a multiple of 8.

#define DR_FLAC_NO_CRC
Disables CRC checks. This will offer a performance boost when CRC is unnecessary. This will disable binary search seeking. When seeking, the seek table will
be used if available. Otherwise the seek will be performed using brute force.

#define DR_FLAC_NO_SIMD
Disables SIMD optimizations (SSE on x86/x64 architectures, NEON on ARM architectures). Use this if you are having compatibility issues with your compiler.

#define DR_FLAC_NO_WCHAR
Disables all functions ending with `_w`. Use this if your compiler does not provide wchar.h. Not required if DR_FLAC_NO_STDIO is also defined.



Notes
=====
- dr_flac does not support changing the sample rate nor channel count mid stream.
- dr_flac is not thread-safe, but its APIs can be called from any thread so long as you do your own synchronization.
- When using Ogg encapsulation, a corrupted metadata block will result in `drflac_open_with_metadata()` and `drflac_open()` returning inconsistent samples due
to differences in corrupted stream recorvery logic between the two APIs.
*/
package dr_flac

when ODIN_OS == .Windows {
    foreign import lib "libdr_flac.lib"
}
when ODIN_OS == .Linux {
    foreign import lib "libdr_flac.a"
}

import "core:c"

_ :: c



DR_FLAC_BUFFER_SIZE :: 4096

DRFLAC_VERSION_MAJOR     :: 0
DRFLAC_VERSION_MINOR     :: 13
DRFLAC_VERSION_REVISION  :: 0
// DRFLAC_VERSION_STRING    :: #DRFLAC_VERSION_MAJOR "." #DRFLAC_VERSION_MINOR "." #DRFLAC_VERSION_REVISION

/* Sized Types */
drflac_int8 :: c.schar

drflac_uint8 :: c.uchar

drflac_int16 :: c.short

drflac_uint16 :: c.ushort

drflac_int32 :: c.int

drflac_uint32 :: c.uint

drflac_int64 :: c.longlong

drflac_uint64 :: c.ulonglong

drflac_uintptr :: drflac_uint64

drflac_bool8 :: drflac_uint8

DRFLAC_TRUE             :: 1

drflac_bool32 :: drflac_uint32

DRFLAC_FALSE            :: 0

// DRFLAC_API  :: extern

// DRFLAC_PRIVATE :: static

// DRFLAC_DEPRECATED       :: _attribute__((deprecated))

/* Allocation Callbacks */
drflac_allocation_callbacks :: struct {
	pUserData: rawptr,
	onMalloc:  proc "c" (c.size_t, rawptr) -> rawptr,
	onRealloc: proc "c" (rawptr, c.size_t, rawptr) -> rawptr,
	onFree:    proc "c" (rawptr, rawptr),
}

drflac_cache_t :: drflac_uint64

/* The various metadata block types. */
DRFLAC_METADATA_BLOCK_TYPE_STREAMINFO       :: 0
DRFLAC_METADATA_BLOCK_TYPE_PADDING          :: 1
DRFLAC_METADATA_BLOCK_TYPE_APPLICATION      :: 2
DRFLAC_METADATA_BLOCK_TYPE_SEEKTABLE        :: 3
DRFLAC_METADATA_BLOCK_TYPE_VORBIS_COMMENT   :: 4
DRFLAC_METADATA_BLOCK_TYPE_CUESHEET         :: 5
DRFLAC_METADATA_BLOCK_TYPE_PICTURE          :: 6
DRFLAC_METADATA_BLOCK_TYPE_INVALID          :: 127

/* The various picture types specified in the PICTURE block. */
DRFLAC_PICTURE_TYPE_OTHER                   :: 0
DRFLAC_PICTURE_TYPE_FILE_ICON               :: 1
DRFLAC_PICTURE_TYPE_OTHER_FILE_ICON         :: 2
DRFLAC_PICTURE_TYPE_COVER_FRONT             :: 3
DRFLAC_PICTURE_TYPE_COVER_BACK              :: 4
DRFLAC_PICTURE_TYPE_LEAFLET_PAGE            :: 5
DRFLAC_PICTURE_TYPE_MEDIA                   :: 6
DRFLAC_PICTURE_TYPE_LEAD_ARTIST             :: 7
DRFLAC_PICTURE_TYPE_ARTIST                  :: 8
DRFLAC_PICTURE_TYPE_CONDUCTOR               :: 9
DRFLAC_PICTURE_TYPE_BAND                    :: 10
DRFLAC_PICTURE_TYPE_COMPOSER                :: 11
DRFLAC_PICTURE_TYPE_LYRICIST                :: 12
DRFLAC_PICTURE_TYPE_RECORDING_LOCATION      :: 13
DRFLAC_PICTURE_TYPE_DURING_RECORDING        :: 14
DRFLAC_PICTURE_TYPE_DURING_PERFORMANCE      :: 15
DRFLAC_PICTURE_TYPE_SCREEN_CAPTURE          :: 16
DRFLAC_PICTURE_TYPE_BRIGHT_COLORED_FISH     :: 17
DRFLAC_PICTURE_TYPE_ILLUSTRATION            :: 18
DRFLAC_PICTURE_TYPE_BAND_LOGOTYPE           :: 19
DRFLAC_PICTURE_TYPE_PUBLISHER_LOGOTYPE      :: 20

drflac_container :: enum c.int {
	native,
	ogg,
	unknown,
}

drflac_seek_origin :: enum c.int {
	SET,
	CUR,
	END,
}

/* The order of members in this structure is important because we map this directly to the raw data within the SEEKTABLE metadata block. */
drflac_seekpoint :: struct {
	firstPCMFrame:   drflac_uint64,
	flacFrameOffset: drflac_uint64, /* The offset from the first byte of the header of the first frame. */
	pcmFrameCount:   drflac_uint16,
}

drflac_streaminfo :: struct {
	minBlockSizeInPCMFrames: drflac_uint16,
	maxBlockSizeInPCMFrames: drflac_uint16,
	minFrameSizeInPCMFrames: drflac_uint32,
	maxFrameSizeInPCMFrames: drflac_uint32,
	sampleRate:              drflac_uint32,
	channels:                drflac_uint8,
	bitsPerSample:           drflac_uint8,
	totalPCMFrameCount:      drflac_uint64,
	md5:                     [16]drflac_uint8,
}

drflac_metadata :: struct {
	/*
	The metadata type. Use this to know how to interpret the data below. Will be set to one of the
	DRFLAC_METADATA_BLOCK_TYPE_* tokens.
	*/
	type: drflac_uint32,

	/*
	A pointer to the raw data. This points to a temporary buffer so don't hold on to it. It's best to
	not modify the contents of this buffer. Use the structures below for more meaningful and structured
	information about the metadata. It's possible for this to be null.
	*/
	pRawData: rawptr,

	/* The size in bytes of the block and the buffer pointed to by pRawData if it's non-NULL. */
	rawDataSize: drflac_uint32,
	data: struct #raw_union {
		streaminfo: drflac_streaminfo,
		padding:    struct {
			unused: c.int,
		},
		application: struct {
			id:       drflac_uint32,
			pData:    rawptr,
			dataSize: drflac_uint32,
		},
		seektable:  struct {
			seekpointCount: drflac_uint32,
			pSeekpoints:    ^drflac_seekpoint,
		},
		vorbis_comment: struct {
			vendorLength: drflac_uint32,
			vendor:       cstring,
			commentCount: drflac_uint32,
			pComments:    rawptr,
		},
		cuesheet:   struct {
			catalog:           [128]c.char,
			leadInSampleCount: drflac_uint64,
			isCD:              drflac_bool32,
			trackCount:        drflac_uint8,
			pTrackData:        rawptr,
		},
		picture:    struct {
			type:              drflac_uint32,
			mimeLength:        drflac_uint32,
			mime:              cstring,
			descriptionLength: drflac_uint32,
			description:       cstring,
			width:             drflac_uint32,
			height:            drflac_uint32,
			colorDepth:        drflac_uint32,
			indexColorCount:   drflac_uint32,
			pictureDataSize:   drflac_uint32,
			pPictureData:      ^drflac_uint8,
		},
	},
}

/*
Callback for when data needs to be read from the client.


Parameters
----------
pUserData (in)
The user data that was passed to drflac_open() and family.

pBufferOut (out)
The output buffer.

bytesToRead (in)
The number of bytes to read.


Return Value
------------
The number of bytes actually read.


Remarks
-------
A return value of less than bytesToRead indicates the end of the stream. Do _not_ return from this callback until either the entire bytesToRead is filled or
you have reached the end of the stream.
*/
drflac_read_proc :: proc "c" (rawptr, rawptr, c.size_t) -> c.size_t

/*
Callback for when data needs to be seeked.


Parameters
----------
pUserData (in)
The user data that was passed to drflac_open() and family.

offset (in)
The number of bytes to move, relative to the origin. Will never be negative.

origin (in)
The origin of the seek - the current position, the start of the stream, or the end of the stream.


Return Value
------------
Whether or not the seek was successful.


Remarks
-------
Seeking relative to the start and the current position must always be supported. If seeking from the end of the stream is not supported, return DRFLAC_FALSE.

When seeking to a PCM frame using drflac_seek_to_pcm_frame(), dr_flac may call this with an offset beyond the end of the FLAC stream. This needs to be detected
and handled by returning DRFLAC_FALSE.
*/
drflac_seek_proc :: proc "c" (rawptr, c.int, drflac_seek_origin) -> drflac_bool32

/*
Callback for when the current position in the stream needs to be retrieved.


Parameters
----------
pUserData (in)
The user data that was passed to drflac_open() and family.

pCursor (out)
A pointer to a variable to receive the current position in the stream.


Return Value
------------
Whether or not the operation was successful.
*/
drflac_tell_proc :: proc "c" (rawptr, ^drflac_int64) -> drflac_bool32

/*
Callback for when a metadata block is read.


Parameters
----------
pUserData (in)
The user data that was passed to drflac_open() and family.

pMetadata (in)
A pointer to a structure containing the data of the metadata block.


Remarks
-------
Use pMetadata->type to determine which metadata block is being handled and how to read the data. This
will be set to one of the DRFLAC_METADATA_BLOCK_TYPE_* tokens.
*/
drflac_meta_proc :: proc "c" (rawptr, ^drflac_metadata)

/* Structure for internal use. Only used for decoders opened with drflac_open_memory. */
drflac__memory_stream :: struct {
	data:           ^drflac_uint8,
	dataSize:       c.size_t,
	currentReadPos: c.size_t,
}

/* Structure for internal use. Used for bit streaming. */
drflac_bs :: struct {
	/* The function to call when more data needs to be read. */
	onRead: drflac_read_proc,

	/* The function to call when the current read position needs to be moved. */
	onSeek: drflac_seek_proc,

	/* The function to call when the current read position needs to be retrieved. */
	onTell: drflac_tell_proc,

	/* The user data to pass around to onRead and onSeek. */
	pUserData: rawptr,

	/*
	The number of unaligned bytes in the L2 cache. This will always be 0 until the end of the stream is hit. At the end of the
	stream there will be a number of bytes that don't cleanly fit in an L1 cache line, so we use this variable to know whether
	or not the bistreamer needs to run on a slower path to read those last bytes. This will never be more than sizeof(drflac_cache_t).
	*/
	unalignedByteCount: c.size_t,

	/* The content of the unaligned bytes. */
	unalignedCache: drflac_cache_t,

	/* The index of the next valid cache line in the "L2" cache. */
	nextL2Line: drflac_uint32,

	/* The number of bits that have been consumed by the cache. This is used to determine how many valid bits are remaining. */
	consumedBits: drflac_uint32,

	/*
	The cached data which was most recently read from the client. There are two levels of cache. Data flows as such:
	Client -> L2 -> L1. The L2 -> L1 movement is aligned and runs on a fast path in just a few instructions.
	*/
	cacheL2: [512]drflac_cache_t,
	cache:                  drflac_cache_t,

	/*
	CRC-16. This is updated whenever bits are read from the bit stream. Manually set this to 0 to reset the CRC. For FLAC, this
	is reset to 0 at the beginning of each frame.
	*/
	crc16: drflac_uint16,
	crc16Cache:             drflac_cache_t, /* A cache for optimizing CRC calculations. This is filled when when the L1 cache is reloaded. */
	crc16CacheIgnoredBytes: drflac_uint32,  /* The number of bytes to ignore when updating the CRC-16 from the CRC-16 cache. */
}

drflac_subframe :: struct {
	/* The type of the subframe: SUBFRAME_CONSTANT, SUBFRAME_VERBATIM, SUBFRAME_FIXED or SUBFRAME_LPC. */
	subframeType: drflac_uint8,

	/* The number of wasted bits per sample as specified by the sub-frame header. */
	wastedBitsPerSample: drflac_uint8,

	/* The order to use for the prediction stage for SUBFRAME_FIXED and SUBFRAME_LPC. */
	lpcOrder: drflac_uint8,

	/* A pointer to the buffer containing the decoded samples in the subframe. This pointer is an offset from drflac::pExtraData. */
	pSamplesS32: ^drflac_int32,
}

drflac_frame_header :: struct {
	/*
	If the stream uses variable block sizes, this will be set to the index of the first PCM frame. If fixed block sizes are used, this will
	always be set to 0. This is 64-bit because the decoded PCM frame number will be 36 bits.
	*/
	pcmFrameNumber: drflac_uint64,

	/*
	If the stream uses fixed block sizes, this will be set to the frame number. If variable block sizes are used, this will always be 0. This
	is 32-bit because in fixed block sizes, the maximum frame number will be 31 bits.
	*/
	flacFrameNumber: drflac_uint32,

	/* The sample rate of this frame. */
	sampleRate: drflac_uint32,

	/* The number of PCM frames in each sub-frame within this frame. */
	blockSizeInPCMFrames: drflac_uint16,

	/*
	The channel assignment of this frame. This is not always set to the channel count. If interchannel decorrelation is being used this
	will be set to DRFLAC_CHANNEL_ASSIGNMENT_LEFT_SIDE, DRFLAC_CHANNEL_ASSIGNMENT_RIGHT_SIDE or DRFLAC_CHANNEL_ASSIGNMENT_MID_SIDE.
	*/
	channelAssignment: drflac_uint8,

	/* The number of bits per sample within this frame. */
	bitsPerSample: drflac_uint8,

	/* The frame's CRC. */
	crc8: drflac_uint8,
}

drflac_frame :: struct {
	/* The header. */
	header: drflac_frame_header,

	/*
	The number of PCM frames left to be read in this FLAC frame. This is initially set to the block size. As PCM frames are read,
	this will be decremented. When it reaches 0, the decoder will see this frame as fully consumed and load the next frame.
	*/
	pcmFramesRemaining: drflac_uint32,

	/* The list of sub-frames within the frame. There is one sub-frame for each channel, and there's a maximum of 8 channels. */
	subframes: [8]drflac_subframe,
}

drflac :: struct {
	/* The function to call when a metadata block is read. */
	onMeta: drflac_meta_proc,

	/* The user data posted to the metadata callback function. */
	pUserDataMD: rawptr,

	/* Memory allocation callbacks. */
	allocationCallbacks: drflac_allocation_callbacks,

	/* The sample rate. Will be set to something like 44100. */
	sampleRate: drflac_uint32,

	/*
	The number of channels. This will be set to 1 for monaural streams, 2 for stereo, etc. Maximum 8. This is set based on the
	value specified in the STREAMINFO block.
	*/
	channels: drflac_uint8,

	/* The bits per sample. Will be set to something like 16, 24, etc. */
	bitsPerSample: drflac_uint8,

	/* The maximum block size, in samples. This number represents the number of samples in each channel (not combined). */
	maxBlockSizeInPCMFrames: drflac_uint16,

	/*
	The total number of PCM Frames making up the stream. Can be 0 in which case it's still a valid stream, but just means
	the total PCM frame count is unknown. Likely the case with streams like internet radio.
	*/
	totalPCMFrameCount: drflac_uint64,

	/* The container type. This is set based on whether or not the decoder was opened from a native or Ogg stream. */
	container: drflac_container,

	/* The number of seekpoints in the seektable. */
	seekpointCount: drflac_uint32,

	/* Information about the frame the decoder is currently sitting on. */
	currentFLACFrame: drflac_frame,

	/* The index of the PCM frame the decoder is currently sitting on. This is only used for seeking. */
	currentPCMFrame: drflac_uint64,

	/* The position of the first FLAC frame in the stream. This is only ever used for seeking. */
	firstFLACFramePosInBytes: drflac_uint64,

	/* A hack to avoid a malloc() when opening a decoder with drflac_open_memory(). */
	memoryStream: drflac__memory_stream,

	/* A pointer to the decoded sample data. This is an offset of pExtraData. */
	pDecodedSamples: ^drflac_int32,

	/* A pointer to the seek table. This is an offset of pExtraData, or NULL if there is no seek table. */
	pSeekpoints: ^drflac_seekpoint,

	/* Internal use only. Only used with Ogg containers. Points to a drflac_oggbs object. This is an offset of pExtraData. */
	_oggbs: rawptr,

	/* Internal use only. Used for profiling and testing different seeking modes. */
	_noSeekTableSeek: drflac_bool32,
	_noBinarySearchSeek: drflac_bool32,
	_noBruteForceSeek:   drflac_bool32,

	/* The bit streamer. The raw FLAC data is fed through this object. */
	bs: drflac_bs,

	/* Variable length extra data. We attach this to the end of the object so we can avoid unnecessary mallocs. */
	pExtraData: [1]drflac_uint8,
}

/* Structure representing an iterator for vorbis comments in a VORBIS_COMMENT metadata block. */
drflac_vorbis_comment_iterator :: struct {
	countRemaining: drflac_uint32,
	pRunningData:   cstring,
}

/* Structure representing an iterator for cuesheet tracks in a CUESHEET metadata block. */
drflac_cuesheet_track_iterator :: struct {
	countRemaining: drflac_uint32,
	pRunningData:   cstring,
}

/* The order of members here is important because we map this directly to the raw data within the CUESHEET metadata block. */
drflac_cuesheet_track_index :: struct {
	offset:   drflac_uint64,
	index:    drflac_uint8,
	reserved: [3]drflac_uint8,
}

drflac_cuesheet_track :: struct {
	offset:       drflac_uint64,
	trackNumber:  drflac_uint8,
	ISRC:         [12]c.char,
	isAudio:      drflac_bool8,
	preEmphasis:  drflac_bool8,
	indexCount:   drflac_uint8,
	pIndexPoints: ^drflac_cuesheet_track_index,
}

@(default_calling_convention="c", link_prefix="")
foreign lib {
	drflac_version        :: proc(pMajor: ^drflac_uint32, pMinor: ^drflac_uint32, pRevision: ^drflac_uint32) ---
	drflac_version_string :: proc() -> cstring ---

	/*
	Opens a FLAC decoder.
	
	
	Parameters
	----------
	onRead (in)
	The function to call when data needs to be read from the client.
	
	onSeek (in)
	The function to call when the read position of the client data needs to move.
	
	pUserData (in, optional)
	A pointer to application defined data that will be passed to onRead and onSeek.
	
	pAllocationCallbacks (in, optional)
	A pointer to application defined callbacks for managing memory allocations.
	
	
	Return Value
	------------
	Returns a pointer to an object representing the decoder.
	
	
	Remarks
	-------
	Close the decoder with `drflac_close()`.
	
	`pAllocationCallbacks` can be NULL in which case it will use `DRFLAC_MALLOC`, `DRFLAC_REALLOC` and `DRFLAC_FREE`.
	
	This function will automatically detect whether or not you are attempting to open a native or Ogg encapsulated FLAC, both of which should work seamlessly
	without any manual intervention. Ogg encapsulation also works with multiplexed streams which basically means it can play FLAC encoded audio tracks in videos.
	
	This is the lowest level function for opening a FLAC stream. You can also use `drflac_open_file()` and `drflac_open_memory()` to open the stream from a file or
	from a block of memory respectively.
	
	The STREAMINFO block must be present for this to succeed. Use `drflac_open_relaxed()` to open a FLAC stream where the header may not be present.
	
	Use `drflac_open_with_metadata()` if you need access to metadata.
	
	
	Seek Also
	---------
	drflac_open_file()
	drflac_open_memory()
	drflac_open_with_metadata()
	drflac_close()
	*/
	drflac_open :: proc(onRead: drflac_read_proc, onSeek: drflac_seek_proc, onTell: drflac_tell_proc, pUserData: rawptr, pAllocationCallbacks: ^drflac_allocation_callbacks) -> ^drflac ---

	/*
	Opens a FLAC stream with relaxed validation of the header block.
	
	
	Parameters
	----------
	onRead (in)
	The function to call when data needs to be read from the client.
	
	onSeek (in)
	The function to call when the read position of the client data needs to move.
	
	container (in)
	Whether or not the FLAC stream is encapsulated using standard FLAC encapsulation or Ogg encapsulation.
	
	pUserData (in, optional)
	A pointer to application defined data that will be passed to onRead and onSeek.
	
	pAllocationCallbacks (in, optional)
	A pointer to application defined callbacks for managing memory allocations.
	
	
	Return Value
	------------
	A pointer to an object representing the decoder.
	
	
	Remarks
	-------
	The same as drflac_open(), except attempts to open the stream even when a header block is not present.
	
	Because the header is not necessarily available, the caller must explicitly define the container (Native or Ogg). Do not set this to `drflac_container_unknown`
	as that is for internal use only.
	
	Opening in relaxed mode will continue reading data from onRead until it finds a valid frame. If a frame is never found it will continue forever. To abort,
	force your `onRead` callback to return 0, which dr_flac will use as an indicator that the end of the stream was found.
	
	Use `drflac_open_with_metadata_relaxed()` if you need access to metadata.
	*/
	drflac_open_relaxed :: proc(onRead: drflac_read_proc, onSeek: drflac_seek_proc, onTell: drflac_tell_proc, container: drflac_container, pUserData: rawptr, pAllocationCallbacks: ^drflac_allocation_callbacks) -> ^drflac ---

	/*
	Opens a FLAC decoder and notifies the caller of the metadata chunks (album art, etc.).
	
	
	Parameters
	----------
	onRead (in)
	The function to call when data needs to be read from the client.
	
	onSeek (in)
	The function to call when the read position of the client data needs to move.
	
	onMeta (in)
	The function to call for every metadata block.
	
	pUserData (in, optional)
	A pointer to application defined data that will be passed to onRead, onSeek and onMeta.
	
	pAllocationCallbacks (in, optional)
	A pointer to application defined callbacks for managing memory allocations.
	
	
	Return Value
	------------
	A pointer to an object representing the decoder.
	
	
	Remarks
	-------
	Close the decoder with `drflac_close()`.
	
	`pAllocationCallbacks` can be NULL in which case it will use `DRFLAC_MALLOC`, `DRFLAC_REALLOC` and `DRFLAC_FREE`.
	
	This is slower than `drflac_open()`, so avoid this one if you don't need metadata. Internally, this will allocate and free memory on the heap for every
	metadata block except for STREAMINFO and PADDING blocks.
	
	The caller is notified of the metadata via the `onMeta` callback. All metadata blocks will be handled before the function returns. This callback takes a
	pointer to a `drflac_metadata` object which is a union containing the data of all relevant metadata blocks. Use the `type` member to discriminate against
	the different metadata types.
	
	The STREAMINFO block must be present for this to succeed. Use `drflac_open_with_metadata_relaxed()` to open a FLAC stream where the header may not be present.
	
	Note that this will behave inconsistently with `drflac_open()` if the stream is an Ogg encapsulated stream and a metadata block is corrupted. This is due to
	the way the Ogg stream recovers from corrupted pages. When `drflac_open_with_metadata()` is being used, the open routine will try to read the contents of the
	metadata block, whereas `drflac_open()` will simply seek past it (for the sake of efficiency). This inconsistency can result in different samples being
	returned depending on whether or not the stream is being opened with metadata.
	
	
	Seek Also
	---------
	drflac_open_file_with_metadata()
	drflac_open_memory_with_metadata()
	drflac_open()
	drflac_close()
	*/
	drflac_open_with_metadata :: proc(onRead: drflac_read_proc, onSeek: drflac_seek_proc, onTell: drflac_tell_proc, onMeta: drflac_meta_proc, pUserData: rawptr, pAllocationCallbacks: ^drflac_allocation_callbacks) -> ^drflac ---

	/*
	The same as drflac_open_with_metadata(), except attempts to open the stream even when a header block is not present.
	
	See Also
	--------
	drflac_open_with_metadata()
	drflac_open_relaxed()
	*/
	drflac_open_with_metadata_relaxed :: proc(onRead: drflac_read_proc, onSeek: drflac_seek_proc, onTell: drflac_tell_proc, onMeta: drflac_meta_proc, container: drflac_container, pUserData: rawptr, pAllocationCallbacks: ^drflac_allocation_callbacks) -> ^drflac ---

	/*
	Closes the given FLAC decoder.
	
	
	Parameters
	----------
	pFlac (in)
	The decoder to close.
	
	
	Remarks
	-------
	This will destroy the decoder object.
	
	
	See Also
	--------
	drflac_open()
	drflac_open_with_metadata()
	drflac_open_file()
	drflac_open_file_w()
	drflac_open_file_with_metadata()
	drflac_open_file_with_metadata_w()
	drflac_open_memory()
	drflac_open_memory_with_metadata()
	*/
	drflac_close :: proc(pFlac: ^drflac) ---

	/*
	Reads sample data from the given FLAC decoder, output as interleaved signed 32-bit PCM.
	
	
	Parameters
	----------
	pFlac (in)
	The decoder.
	
	framesToRead (in)
	The number of PCM frames to read.
	
	pBufferOut (out, optional)
	A pointer to the buffer that will receive the decoded samples.
	
	
	Return Value
	------------
	Returns the number of PCM frames actually read. If the return value is less than `framesToRead` it has reached the end.
	
	
	Remarks
	-------
	pBufferOut can be null, in which case the call will act as a seek, and the return value will be the number of frames seeked.
	*/
	drflac_read_pcm_frames_s32 :: proc(pFlac: ^drflac, framesToRead: drflac_uint64, pBufferOut: ^drflac_int32) -> drflac_uint64 ---

	/*
	Reads sample data from the given FLAC decoder, output as interleaved signed 16-bit PCM.
	
	
	Parameters
	----------
	pFlac (in)
	The decoder.
	
	framesToRead (in)
	The number of PCM frames to read.
	
	pBufferOut (out, optional)
	A pointer to the buffer that will receive the decoded samples.
	
	
	Return Value
	------------
	Returns the number of PCM frames actually read. If the return value is less than `framesToRead` it has reached the end.
	
	
	Remarks
	-------
	pBufferOut can be null, in which case the call will act as a seek, and the return value will be the number of frames seeked.
	
	Note that this is lossy for streams where the bits per sample is larger than 16.
	*/
	drflac_read_pcm_frames_s16 :: proc(pFlac: ^drflac, framesToRead: drflac_uint64, pBufferOut: ^drflac_int16) -> drflac_uint64 ---

	/*
	Reads sample data from the given FLAC decoder, output as interleaved 32-bit floating point PCM.
	
	
	Parameters
	----------
	pFlac (in)
	The decoder.
	
	framesToRead (in)
	The number of PCM frames to read.
	
	pBufferOut (out, optional)
	A pointer to the buffer that will receive the decoded samples.
	
	
	Return Value
	------------
	Returns the number of PCM frames actually read. If the return value is less than `framesToRead` it has reached the end.
	
	
	Remarks
	-------
	pBufferOut can be null, in which case the call will act as a seek, and the return value will be the number of frames seeked.
	
	Note that this should be considered lossy due to the nature of floating point numbers not being able to exactly represent every possible number.
	*/
	drflac_read_pcm_frames_f32 :: proc(pFlac: ^drflac, framesToRead: drflac_uint64, pBufferOut: ^f32) -> drflac_uint64 ---

	/*
	Seeks to the PCM frame at the given index.
	
	
	Parameters
	----------
	pFlac (in)
	The decoder.
	
	pcmFrameIndex (in)
	The index of the PCM frame to seek to. See notes below.
	
	
	Return Value
	-------------
	`DRFLAC_TRUE` if successful; `DRFLAC_FALSE` otherwise.
	*/
	drflac_seek_to_pcm_frame :: proc(pFlac: ^drflac, pcmFrameIndex: drflac_uint64) -> drflac_bool32 ---

	/*
	Opens a FLAC decoder from the file at the given path.
	
	
	Parameters
	----------
	pFileName (in)
	The path of the file to open, either absolute or relative to the current directory.
	
	pAllocationCallbacks (in, optional)
	A pointer to application defined callbacks for managing memory allocations.
	
	
	Return Value
	------------
	A pointer to an object representing the decoder.
	
	
	Remarks
	-------
	Close the decoder with drflac_close().
	
	
	Remarks
	-------
	This will hold a handle to the file until the decoder is closed with drflac_close(). Some platforms will restrict the number of files a process can have open
	at any given time, so keep this mind if you have many decoders open at the same time.
	
	
	See Also
	--------
	drflac_open_file_with_metadata()
	drflac_open()
	drflac_close()
	*/
	drflac_open_file   :: proc(pFileName: cstring, pAllocationCallbacks: ^drflac_allocation_callbacks) -> ^drflac ---
	drflac_open_file_w :: proc(pFileName: ^c.wchar_t, pAllocationCallbacks: ^drflac_allocation_callbacks) -> ^drflac ---

	/*
	Opens a FLAC decoder from the file at the given path and notifies the caller of the metadata chunks (album art, etc.)
	
	
	Parameters
	----------
	pFileName (in)
	The path of the file to open, either absolute or relative to the current directory.
	
	pAllocationCallbacks (in, optional)
	A pointer to application defined callbacks for managing memory allocations.
	
	onMeta (in)
	The callback to fire for each metadata block.
	
	pUserData (in)
	A pointer to the user data to pass to the metadata callback.
	
	pAllocationCallbacks (in)
	A pointer to application defined callbacks for managing memory allocations.
	
	
	Remarks
	-------
	Look at the documentation for drflac_open_with_metadata() for more information on how metadata is handled.
	
	
	See Also
	--------
	drflac_open_with_metadata()
	drflac_open()
	drflac_close()
	*/
	drflac_open_file_with_metadata   :: proc(pFileName: cstring, onMeta: drflac_meta_proc, pUserData: rawptr, pAllocationCallbacks: ^drflac_allocation_callbacks) -> ^drflac ---
	drflac_open_file_with_metadata_w :: proc(pFileName: ^c.wchar_t, onMeta: drflac_meta_proc, pUserData: rawptr, pAllocationCallbacks: ^drflac_allocation_callbacks) -> ^drflac ---

	/*
	Opens a FLAC decoder from a pre-allocated block of memory
	
	
	Parameters
	----------
	pData (in)
	A pointer to the raw encoded FLAC data.
	
	dataSize (in)
	The size in bytes of `data`.
	
	pAllocationCallbacks (in)
	A pointer to application defined callbacks for managing memory allocations.
	
	
	Return Value
	------------
	A pointer to an object representing the decoder.
	
	
	Remarks
	-------
	This does not create a copy of the data. It is up to the application to ensure the buffer remains valid for the lifetime of the decoder.
	
	
	See Also
	--------
	drflac_open()
	drflac_close()
	*/
	drflac_open_memory :: proc(pData: rawptr, dataSize: c.size_t, pAllocationCallbacks: ^drflac_allocation_callbacks) -> ^drflac ---

	/*
	Opens a FLAC decoder from a pre-allocated block of memory and notifies the caller of the metadata chunks (album art, etc.)
	
	
	Parameters
	----------
	pData (in)
	A pointer to the raw encoded FLAC data.
	
	dataSize (in)
	The size in bytes of `data`.
	
	onMeta (in)
	The callback to fire for each metadata block.
	
	pUserData (in)
	A pointer to the user data to pass to the metadata callback.
	
	pAllocationCallbacks (in)
	A pointer to application defined callbacks for managing memory allocations.
	
	
	Remarks
	-------
	Look at the documentation for drflac_open_with_metadata() for more information on how metadata is handled.
	
	
	See Also
	-------
	drflac_open_with_metadata()
	drflac_open()
	drflac_close()
	*/
	drflac_open_memory_with_metadata :: proc(pData: rawptr, dataSize: c.size_t, onMeta: drflac_meta_proc, pUserData: rawptr, pAllocationCallbacks: ^drflac_allocation_callbacks) -> ^drflac ---

	/*
	Opens a FLAC stream from the given callbacks and fully decodes it in a single operation. The return value is a
	pointer to the sample data as interleaved signed 32-bit PCM. The returned data must be freed with drflac_free().
	
	You can pass in custom memory allocation callbacks via the pAllocationCallbacks parameter. This can be NULL in which
	case it will use DRFLAC_MALLOC, DRFLAC_REALLOC and DRFLAC_FREE.
	
	Sometimes a FLAC file won't keep track of the total sample count. In this situation the function will continuously
	read samples into a dynamically sized buffer on the heap until no samples are left.
	
	Do not call this function on a broadcast type of stream (like internet radio streams and whatnot).
	*/
	drflac_open_and_read_pcm_frames_s32 :: proc(onRead: drflac_read_proc, onSeek: drflac_seek_proc, onTell: drflac_tell_proc, pUserData: rawptr, channels: ^c.uint, sampleRate: ^c.uint, totalPCMFrameCount: ^drflac_uint64, pAllocationCallbacks: ^drflac_allocation_callbacks) -> ^drflac_int32 ---

	/* Same as drflac_open_and_read_pcm_frames_s32(), except returns signed 16-bit integer samples. */
	drflac_open_and_read_pcm_frames_s16 :: proc(onRead: drflac_read_proc, onSeek: drflac_seek_proc, onTell: drflac_tell_proc, pUserData: rawptr, channels: ^c.uint, sampleRate: ^c.uint, totalPCMFrameCount: ^drflac_uint64, pAllocationCallbacks: ^drflac_allocation_callbacks) -> ^drflac_int16 ---

	/* Same as drflac_open_and_read_pcm_frames_s32(), except returns 32-bit floating-point samples. */
	drflac_open_and_read_pcm_frames_f32 :: proc(onRead: drflac_read_proc, onSeek: drflac_seek_proc, onTell: drflac_tell_proc, pUserData: rawptr, channels: ^c.uint, sampleRate: ^c.uint, totalPCMFrameCount: ^drflac_uint64, pAllocationCallbacks: ^drflac_allocation_callbacks) -> ^f32 ---

	/* Same as drflac_open_and_read_pcm_frames_s32() except opens the decoder from a file. */
	drflac_open_file_and_read_pcm_frames_s32 :: proc(filename: cstring, channels: ^c.uint, sampleRate: ^c.uint, totalPCMFrameCount: ^drflac_uint64, pAllocationCallbacks: ^drflac_allocation_callbacks) -> ^drflac_int32 ---

	/* Same as drflac_open_file_and_read_pcm_frames_s32(), except returns signed 16-bit integer samples. */
	drflac_open_file_and_read_pcm_frames_s16 :: proc(filename: cstring, channels: ^c.uint, sampleRate: ^c.uint, totalPCMFrameCount: ^drflac_uint64, pAllocationCallbacks: ^drflac_allocation_callbacks) -> ^drflac_int16 ---

	/* Same as drflac_open_file_and_read_pcm_frames_s32(), except returns 32-bit floating-point samples. */
	drflac_open_file_and_read_pcm_frames_f32 :: proc(filename: cstring, channels: ^c.uint, sampleRate: ^c.uint, totalPCMFrameCount: ^drflac_uint64, pAllocationCallbacks: ^drflac_allocation_callbacks) -> ^f32 ---

	/* Same as drflac_open_and_read_pcm_frames_s32() except opens the decoder from a block of memory. */
	drflac_open_memory_and_read_pcm_frames_s32 :: proc(data: rawptr, dataSize: c.size_t, channels: ^c.uint, sampleRate: ^c.uint, totalPCMFrameCount: ^drflac_uint64, pAllocationCallbacks: ^drflac_allocation_callbacks) -> ^drflac_int32 ---

	/* Same as drflac_open_memory_and_read_pcm_frames_s32(), except returns signed 16-bit integer samples. */
	drflac_open_memory_and_read_pcm_frames_s16 :: proc(data: rawptr, dataSize: c.size_t, channels: ^c.uint, sampleRate: ^c.uint, totalPCMFrameCount: ^drflac_uint64, pAllocationCallbacks: ^drflac_allocation_callbacks) -> ^drflac_int16 ---

	/* Same as drflac_open_memory_and_read_pcm_frames_s32(), except returns 32-bit floating-point samples. */
	drflac_open_memory_and_read_pcm_frames_f32 :: proc(data: rawptr, dataSize: c.size_t, channels: ^c.uint, sampleRate: ^c.uint, totalPCMFrameCount: ^drflac_uint64, pAllocationCallbacks: ^drflac_allocation_callbacks) -> ^f32 ---

	/*
	Frees memory that was allocated internally by dr_flac.
	
	Set pAllocationCallbacks to the same object that was passed to drflac_open_*_and_read_pcm_frames_*(). If you originally passed in NULL, pass in NULL for this.
	*/
	drflac_free :: proc(p: rawptr, pAllocationCallbacks: ^drflac_allocation_callbacks) ---

	/*
	Initializes a vorbis comment iterator. This can be used for iterating over the vorbis comments in a VORBIS_COMMENT
	metadata block.
	*/
	drflac_init_vorbis_comment_iterator :: proc(pIter: ^drflac_vorbis_comment_iterator, commentCount: drflac_uint32, pComments: rawptr) ---

	/*
	Goes to the next vorbis comment in the given iterator. If null is returned it means there are no more comments. The
	returned string is NOT null terminated.
	*/
	drflac_next_vorbis_comment :: proc(pIter: ^drflac_vorbis_comment_iterator, pCommentLengthOut: ^drflac_uint32) -> cstring ---

	/*
	Initializes a cuesheet track iterator. This can be used for iterating over the cuesheet tracks in a CUESHEET metadata
	block.
	*/
	drflac_init_cuesheet_track_iterator :: proc(pIter: ^drflac_cuesheet_track_iterator, trackCount: drflac_uint32, pTrackData: rawptr) ---

	/* Goes to the next cuesheet track in the given iterator. If DRFLAC_FALSE is returned it means there are no more comments. */
	drflac_next_cuesheet_track :: proc(pIter: ^drflac_cuesheet_track_iterator, pCuesheetTrack: ^drflac_cuesheet_track) -> drflac_bool32 ---
}
