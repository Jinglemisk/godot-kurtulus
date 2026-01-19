extends CharacterBody3D

## Soldier - Formation-following unit that trails behind commander
## Uses smooth lerp to maintain formation position relative to commander
## Features: dust particles, organic offset, crowding behavior (variable speeds/delays)
## Phase 4: Directional walk and attack animations

# Formation constants
const FOLLOW_SPEED: float = 12.0  # Base follow speed
const ORGANIC_OFFSET_MAX: float = 0.3  # Max random offset in any direction
const ORGANIC_CHANGE_INTERVAL: float = 2.0  # Seconds between offset changes
const ORGANIC_LERP_SPEED: float = 2.0  # How fast to transition to new offset

# Animation constants
const WALK_FPS: float = 8.0
const ATTACK_FPS: float = 10.0

# Animation state
enum AnimState { IDLE, WALKING, ATTACKING }
var anim_state: AnimState = AnimState.IDLE
var anim_frame: int = 0
var anim_timer: float = 0.0
var current_facing: String = "front"  # Track current direction for animations

# Set by unit.gd after instantiation
var formation_offset: Vector3 = Vector3.ZERO
var commander: CharacterBody3D = null
var unit: Node3D = null  # For formation_scale access
var squad_members: Array = []  # For collision avoidance
var my_index: int = 0

# Crowding behavior - set by unit.gd (creates natural lag for back rows)
var follow_speed_multiplier: float = 1.0  # 0.7-1.0, lower = slower reaction
var target_lerp_speed: float = 4.0  # How fast smoothed target approaches real target

# Idle look-at-commander behavior
const IDLE_LOOK_DELAY: float = 1.0  # Seconds before looking at commander
var idle_timer: float = 0.0

# Soft collision avoidance
const SEPARATION_DISTANCE: float = 1.2  # Min distance between soldiers
const SEPARATION_STRENGTH: float = 3.0  # Push force

# Node references
@onready var sprite: Sprite3D = $Sprite3D
@onready var dust: GPUParticles3D = $DustParticles
@onready var attack_sound: AudioStreamPlayer3D = get_node_or_null("AttackSound")
@onready var attack_particles: GPUParticles3D = $AttackParticles

# Directional idle sprites (4 directions, use mirroring for 8)
var tex_front: Texture2D = preload("res://assets/sprites/infantry/front-rdy.png")
var tex_back: Texture2D = preload("res://assets/sprites/infantry/back-rdy.png")
var tex_side: Texture2D = preload("res://assets/sprites/infantry/left-rdy.png")

# Walk animation sprites (4 directions x 4 frames)
var tex_walk: Dictionary = {
	"front": [
		preload("res://assets/sprites/infantry/walk/front/frame1-rdy.png"),
		preload("res://assets/sprites/infantry/walk/front/frame2-rdy.png"),
		preload("res://assets/sprites/infantry/walk/front/frame3-rdy.png"),
		preload("res://assets/sprites/infantry/walk/front/frame4-rdy.png"),
	],
	"back": [
		preload("res://assets/sprites/infantry/walk/back/frame1-rdy.png"),
		preload("res://assets/sprites/infantry/walk/back/frame2-rdy.png"),
		preload("res://assets/sprites/infantry/walk/back/frame3-rdy.png"),
		preload("res://assets/sprites/infantry/walk/back/frame4-rdy.png"),
	],
	"left": [
		preload("res://assets/sprites/infantry/walk/left/frame1-rdy.png"),
		preload("res://assets/sprites/infantry/walk/left/frame2-rdy.png"),
		preload("res://assets/sprites/infantry/walk/left/frame3-rdy.png"),
		preload("res://assets/sprites/infantry/walk/left/frame4-rdy.png"),
	],
	"right": [
		preload("res://assets/sprites/infantry/walk/right/frame1-rdy.png"),
		preload("res://assets/sprites/infantry/walk/right/frame2-rdy.png"),
		preload("res://assets/sprites/infantry/walk/right/frame3-rdy.png"),
		preload("res://assets/sprites/infantry/walk/right/frame4-rdy.png"),
	],
}

# Attack animation sprites (4 directions x 4 frames)
var tex_attack: Dictionary = {
	"front": [
		preload("res://assets/sprites/infantry/attack/front/frame1-rdy.png"),
		preload("res://assets/sprites/infantry/attack/front/frame2-rdy.png"),
		preload("res://assets/sprites/infantry/attack/front/frame3-rdy.png"),
		preload("res://assets/sprites/infantry/attack/front/frame4-rdy.png"),
	],
	"back": [
		preload("res://assets/sprites/infantry/attack/back/frame1-rdy.png"),
		preload("res://assets/sprites/infantry/attack/back/frame2-rdy.png"),
		preload("res://assets/sprites/infantry/attack/back/frame3-rdy.png"),
		preload("res://assets/sprites/infantry/attack/back/frame4-rdy.png"),
	],
	"left": [
		preload("res://assets/sprites/infantry/attack/left/frame1-rdy.png"),
		preload("res://assets/sprites/infantry/attack/left/frame2-rdy.png"),
		preload("res://assets/sprites/infantry/attack/left/frame3-rdy.png"),
		preload("res://assets/sprites/infantry/attack/left/frame4-rdy.png"),
	],
	"right": [
		preload("res://assets/sprites/infantry/attack/right/frame1-rdy.png"),
		preload("res://assets/sprites/infantry/attack/right/frame2-rdy.png"),
		preload("res://assets/sprites/infantry/attack/right/frame3-rdy.png"),
		preload("res://assets/sprites/infantry/attack/right/frame4-rdy.png"),
	],
}

# Track previous position for direction calculation and speed
var last_position: Vector3 = Vector3.ZERO

# Organic offset for natural formation feel
var organic_offset: Vector3 = Vector3.ZERO
var target_organic_offset: Vector3 = Vector3.ZERO
var organic_timer: float = 0.0

# Smooth target interpolation (prevents "wait then teleport" behavior)
var smoothed_target_pos: Vector3 = Vector3.ZERO
var initialized: bool = false


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

	# Handle attack animation (blocks other behavior)
	if anim_state == AnimState.ATTACKING:
		update_attack_animation(delta)
		return

	# Update organic offset timer
	organic_timer += delta
	if organic_timer >= ORGANIC_CHANGE_INTERVAL:
		organic_timer = 0.0
		randomize_organic_offset()

	# Smoothly transition organic offset
	organic_offset = organic_offset.lerp(target_organic_offset, delta * ORGANIC_LERP_SPEED)

	# Calculate real target position (where soldier SHOULD be)
	var real_target_pos: Vector3 = calculate_formation_position()

	# Initialize on first frame
	if not initialized:
		smoothed_target_pos = real_target_pos
		global_position = real_target_pos
		initialized = true
		last_position = global_position
		return

	# Smoothed target gradually approaches real target (creates natural lag)
	smoothed_target_pos = smoothed_target_pos.lerp(real_target_pos, delta * target_lerp_speed)

	# Calculate separation offset for collision avoidance
	var separation: Vector3 = calculate_separation_offset()

	# Soldier position lerps towards smoothed target + separation
	var effective_speed: float = FOLLOW_SPEED * follow_speed_multiplier
	var target_with_separation: Vector3 = smoothed_target_pos + separation * delta
	global_position = global_position.lerp(target_with_separation, delta * effective_speed)

	# Calculate movement speed for dust and sprite
	var move_dir: Vector3 = global_position - last_position
	var move_speed: float = move_dir.length() / delta if delta > 0 else 0.0

	# Control dust particles based on movement speed
	if dust:
		dust.emitting = move_speed > 3.0  # Emit dust when moving fast enough

	# Track idle state for look-at-commander behavior
	if move_speed < 0.5:
		idle_timer += delta
	else:
		idle_timer = 0.0

	# Update sprite facing and animation state
	if idle_timer >= IDLE_LOOK_DELAY:
		# Idle - look at commander
		anim_state = AnimState.IDLE
		look_at_commander()
	elif move_dir.length_squared() > 0.001:
		# Moving - update facing and walk animation
		update_sprite_facing(move_dir)
		anim_state = AnimState.WALKING
		update_walk_animation(delta)
	else:
		# Transitioning to idle
		anim_state = AnimState.IDLE
		show_idle_sprite()

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

	# Apply formation scale for idle tightening
	var formation_scale_factor: float = unit.formation_scale if unit else 1.0
	var scaled_offset: Vector3 = rotated_offset * formation_scale_factor

	# Add organic offset for natural feel
	return commander.global_position + scaled_offset + organic_offset


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
			current_facing = "front"
			sprite.flip_h = false
		else:
			current_facing = "back"
			sprite.flip_h = false
	else:
		# Moving primarily left/right
		if move_dir.x > 0:
			current_facing = "right"
			sprite.flip_h = false
		else:
			current_facing = "left"
			sprite.flip_h = false


func look_at_commander() -> void:
	# Face toward commander when idle
	var dir_to_commander: Vector3 = commander.global_position - global_position
	dir_to_commander.y = 0
	if dir_to_commander.length_squared() < 0.01:
		return

	dir_to_commander = dir_to_commander.normalized()
	var abs_x: float = absf(dir_to_commander.x)
	var abs_z: float = absf(dir_to_commander.z)

	if abs_z > abs_x:
		if dir_to_commander.z > 0:
			current_facing = "front"
			sprite.texture = tex_front
		else:
			current_facing = "back"
			sprite.texture = tex_back
		sprite.flip_h = false
	else:
		if dir_to_commander.x > 0:
			current_facing = "right"
			sprite.texture = tex_side
			sprite.flip_h = true  # Flip left sprite for right facing
		else:
			current_facing = "left"
			sprite.texture = tex_side
			sprite.flip_h = false


func calculate_separation_offset() -> Vector3:
	# Soft collision avoidance - push away from nearby soldiers
	var separation: Vector3 = Vector3.ZERO
	for i in range(squad_members.size()):
		if i == my_index:
			continue
		var other: CharacterBody3D = squad_members[i]
		var diff: Vector3 = global_position - other.global_position
		diff.y = 0
		var dist: float = diff.length()
		if dist < SEPARATION_DISTANCE and dist > 0.01:
			# Push away proportional to overlap
			var overlap: float = SEPARATION_DISTANCE - dist
			separation += diff.normalized() * overlap * SEPARATION_STRENGTH
	return separation


# Animation functions

func show_idle_sprite() -> void:
	# Show idle sprite for current facing direction
	match current_facing:
		"front":
			sprite.texture = tex_front
			sprite.flip_h = false
		"back":
			sprite.texture = tex_back
			sprite.flip_h = false
		"left":
			sprite.texture = tex_side
			sprite.flip_h = false
		"right":
			sprite.texture = tex_side
			sprite.flip_h = true


func update_walk_animation(delta: float) -> void:
	anim_timer += delta
	var frame_duration := 1.0 / WALK_FPS
	if anim_timer >= frame_duration:
		anim_timer -= frame_duration
		anim_frame = (anim_frame + 1) % 4  # 4 walk frames

	var frames: Array = tex_walk.get(current_facing, tex_walk["front"])
	sprite.texture = frames[anim_frame]
	sprite.flip_h = false  # We have separate left/right sprites, no mirroring needed


func update_attack_animation(delta: float) -> void:
	anim_timer += delta
	var frame_duration := 1.0 / ATTACK_FPS
	if anim_timer >= frame_duration:
		anim_timer -= frame_duration
		anim_frame += 1
		if anim_frame >= 4:  # 4 attack frames
			# Attack finished - return to idle
			anim_state = AnimState.IDLE
			anim_frame = 0
			anim_timer = 0.0
			show_idle_sprite()
			return

	var frames: Array = tex_attack.get(current_facing, tex_attack["front"])
	sprite.texture = frames[anim_frame]
	sprite.flip_h = false  # We have separate left/right sprites, no mirroring needed


func trigger_attack() -> void:
	# Called by unit.gd to start attack animation
	if anim_state == AnimState.ATTACKING:
		return  # Already attacking
	anim_state = AnimState.ATTACKING
	anim_frame = 0
	anim_timer = 0.0
	var frames: Array = tex_attack.get(current_facing, tex_attack["front"])
	sprite.texture = frames[0]
	sprite.flip_h = false  # We have separate left/right sprites, no mirroring needed

	# Play attack sound with pitch variation (lower volume, varied pitch for ensemble feel)
	if attack_sound:
		attack_sound.pitch_scale = randf_range(0.85, 1.15)  # Wider pitch variation for soldiers
		attack_sound.play()

	# Trigger attack impact particles
	if attack_particles:
		attack_particles.restart()
		attack_particles.emitting = true
