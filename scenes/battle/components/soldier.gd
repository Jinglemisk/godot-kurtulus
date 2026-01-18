extends CharacterBody3D

## Soldier - Formation-following unit that trails behind commander
## Uses smooth lerp to maintain formation position relative to commander
## Features: dust particles, organic offset, crowding behavior (variable speeds/delays)

# Formation constants
const FOLLOW_SPEED: float = 12.0  # Base follow speed
const ORGANIC_OFFSET_MAX: float = 0.3  # Max random offset in any direction
const ORGANIC_CHANGE_INTERVAL: float = 2.0  # Seconds between offset changes
const ORGANIC_LERP_SPEED: float = 2.0  # How fast to transition to new offset

# Set by unit.gd after instantiation
var formation_offset: Vector3 = Vector3.ZERO
var commander: CharacterBody3D = null

# Crowding behavior - set by unit.gd (creates natural lag for back rows)
var follow_speed_multiplier: float = 1.0  # 0.7-1.0, lower = slower reaction
var reaction_delay: float = 0.0  # Seconds before responding to new target

# Node references
@onready var sprite: Sprite3D = $Sprite3D
@onready var dust: GPUParticles3D = $DustParticles

# Directional sprites (4 directions, use mirroring for 8)
var tex_front: Texture2D = preload("res://assets/sprites/infantry/front-rdy.png")
var tex_back: Texture2D = preload("res://assets/sprites/infantry/back-rdy.png")
var tex_side: Texture2D = preload("res://assets/sprites/infantry/left-rdy.png")

# Track previous position for direction calculation and speed
var last_position: Vector3 = Vector3.ZERO

# Organic offset for natural formation feel
var organic_offset: Vector3 = Vector3.ZERO
var target_organic_offset: Vector3 = Vector3.ZERO
var organic_timer: float = 0.0

# Crowding: cached target position and delay timer
var cached_target_pos: Vector3 = Vector3.ZERO
var target_update_timer: float = 0.0
var has_initial_target: bool = false


func _ready() -> void:
	last_position = global_position
	# Initialize with random organic offset
	randomize_organic_offset()
	organic_offset = target_organic_offset
	# Stagger organic timer so soldiers don't all update at same time
	organic_timer = randf() * ORGANIC_CHANGE_INTERVAL


func _process(delta: float) -> void:
	if commander == null:
		return

	# Update organic offset timer
	organic_timer += delta
	if organic_timer >= ORGANIC_CHANGE_INTERVAL:
		organic_timer = 0.0
		randomize_organic_offset()

	# Smoothly transition organic offset
	organic_offset = organic_offset.lerp(target_organic_offset, delta * ORGANIC_LERP_SPEED)

	# Calculate new target position
	var new_target_pos: Vector3 = calculate_formation_position()

	# Crowding: delay target updates for back-row soldiers
	if not has_initial_target:
		# First frame - set target immediately
		cached_target_pos = new_target_pos
		has_initial_target = true
	elif reaction_delay > 0.0:
		# Check if target changed significantly (commander turned)
		var target_diff: float = (new_target_pos - cached_target_pos).length()
		if target_diff > 0.5:
			# Target changed - start delay timer
			target_update_timer += delta
			if target_update_timer >= reaction_delay:
				# Delay complete - update cached target
				cached_target_pos = new_target_pos
				target_update_timer = 0.0
		else:
			# Target is similar - update immediately (small movements)
			cached_target_pos = new_target_pos
			target_update_timer = 0.0
	else:
		# No delay - update target immediately
		cached_target_pos = new_target_pos

	# Smooth follow to cached target position with variable speed
	var effective_speed: float = FOLLOW_SPEED * follow_speed_multiplier
	global_position = global_position.lerp(cached_target_pos, delta * effective_speed)

	# Calculate movement speed for dust and sprite
	var move_dir: Vector3 = global_position - last_position
	var move_speed: float = move_dir.length() / delta if delta > 0 else 0.0

	# Control dust particles based on movement speed
	if dust:
		dust.emitting = move_speed > 3.0  # Emit dust when moving fast enough

	# Update sprite based on movement direction
	if move_dir.length_squared() > 0.001:
		update_sprite_facing(move_dir)

	last_position = global_position


func randomize_organic_offset() -> void:
	target_organic_offset = Vector3(
		randf_range(-ORGANIC_OFFSET_MAX, ORGANIC_OFFSET_MAX),
		0.0,
		randf_range(-ORGANIC_OFFSET_MAX, ORGANIC_OFFSET_MAX)
	)


func calculate_formation_position() -> Vector3:
	# Get commander's movement direction (or use forward if stationary)
	var cmd_dir: Vector3 = commander.current_direction
	if cmd_dir.length_squared() < 0.01:
		cmd_dir = Vector3.FORWARD

	# Rotate formation offset around Y axis based on commander's facing
	var angle: float = atan2(cmd_dir.x, cmd_dir.z)
	var rotated_offset: Vector3 = formation_offset.rotated(Vector3.UP, angle)

	# Add organic offset for natural feel
	return commander.global_position + rotated_offset + organic_offset


func update_sprite_facing(move_dir: Vector3) -> void:
	# Normalize for direction check
	move_dir = move_dir.normalized()

	# Convert 3D direction to facing angle relative to camera
	# Positive Z = toward camera (front), Negative Z = away (back)
	var abs_x: float = absf(move_dir.x)
	var abs_z: float = absf(move_dir.z)

	if abs_z > abs_x:
		# Moving primarily forward/backward
		if move_dir.z > 0:
			sprite.texture = tex_front  # Moving toward camera
		else:
			sprite.texture = tex_back   # Moving away from camera
		sprite.flip_h = false
	else:
		# Moving primarily left/right
		sprite.texture = tex_side
		sprite.flip_h = move_dir.x > 0  # Flip for right movement
