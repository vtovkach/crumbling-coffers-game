extends Player
class_name RemotePlayer

const DASH_INFERENCE_BREAKPOINT: float = 3600.0
const AIR_MOVEMENT_INFERENCE_BREAKPOINT: float = 5.0

class PlayerPacket:
	var x:         float
	var y:         float
	var vx:        float
	var vy:        float
	var score:     int
	var timestamp: float  # timestamp is obtained by Time.get_ticks_msec() when packet was received in Game

	func _init(px: float, py: float, pvx: float, pvy: float, pscore: int, ts: float) -> void:
		x         = px
		y         = py
		vx        = pvx
		vy        = pvy
		score     = pscore
		timestamp = ts

var score: int = 0
var player_id: String
var packet_queue: Array[PlayerPacket] = []

func _ready() -> void:
	add_to_group("remote")

func init(id: String, init_x: float, init_y: float) -> void:
	player_id = id
	position.x = init_x
	position.y = init_y 
	velocity.x = 0
	velocity.y = 0
	score = 0

# Called in Game's _process() to push new player data
# Note for Nicholas — it is a rough draft, feel free to change (Array to heap/queue if needed)
# I know you might not like class PlayerPacket inside this script but feel free to change it as you want, but don't break other code
func push_data_packet(packet: PlayerPacket) -> void:
	packet_queue.push_back(packet)

# Called inside Game's _process(), gets render time
# Do interpolation/extrapolation using packet_queue and all other player's updates like score animations etc... 
func render_remote_player(render_time: float) -> void:
	while packet_queue.size() >= 2 and packet_queue[1].timestamp <= render_time:
		packet_queue.pop_front()

	if packet_queue.size() >= 2:
		var from: PlayerPacket = packet_queue[0]
		var to:   PlayerPacket = packet_queue[1]
		var alpha: float = clamp((render_time - from.timestamp) / (to.timestamp - from.timestamp), 0.0, 1.0)
		position = lerp(Vector2(from.x, from.y), Vector2(to.x, to.y), alpha)
		velocity = lerp(Vector2(from.vx, from.vy), Vector2(to.vx, to.vy), alpha)
		score = from.score
	elif packet_queue.size() == 1:
		position = Vector2(packet_queue[0].x, packet_queue[0].y)
		velocity = Vector2(packet_queue[0].vx, packet_queue[0].vy)
		score = packet_queue[0].score
		
	infer_animation()


func infer_animation() -> void:
	update_facing()
	
	if is_animation("dash") and !is_animation_concluded("dash"):
		return		

	if abs(velocity.x) > DASH_INFERENCE_BREAKPOINT:
		set_animation("dash")

	elif abs(velocity.y) < AIR_MOVEMENT_INFERENCE_BREAKPOINT:
		if velocity.x == 0:
			set_animation("idle")
		else:
			set_animation("run")
	else:
		if is_animation_concluded("jump"):
			set_animation("fall")
		elif is_animation_concluded("fall"):
			set_animation("fallLoop")
		elif velocity.y < 0:    # aka going up
			if is_animation("idle") or is_animation("run"): 
				set_animation("jump")
			else:
				set_animation("fallLoop") # this is a fallback 
		else:
			set_animation("fall")
