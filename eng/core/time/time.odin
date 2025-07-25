package ihavenoideawhatconflictswiththepackagenametimesoiamjustgoingtousethislongassname

act_delta: f64
act_time: f64
act_delta32: f32
act_time32: f32

delta: f64
time: f64
delta32: f32
time32: f32

@private
speed: f64 = 1

// paused is just zero
set_timescale   :: proc(scale: f64) { speed = scale }
set_timescale32 :: proc(scale: f32) { speed = f64(scale) }

get_timescale   :: proc() -> f64 { return speed }
get_timescale32 :: proc() -> f32 { return f32(speed) }
