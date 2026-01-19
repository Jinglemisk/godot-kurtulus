extends CharacterBody3D

## Commander - Player-controlled character with camera-relative movement
## Features: momentum physics, directional sprites, boundary constraints, visual effects
## Phase 4: Walk and attack animations

# Movement constants
const MAX_SPEED: float = 10.0
const ACCELERATION: float = 20.0       # Units/sec² - reaches max in 0.5s
const DECELERATION: float = 15.0       # Units/sec² - stops in ~0.67s
const TURN_PENALTY: float = 0.4        # Speed multiplier when changing direction
const TURN_THRESHOLD: float = 0.7      # Dot product threshold for "turning"
const ARENA_BOUND: float = 48.0        # Slightly inside the 50-unit posts

# Animation constants
const WALK_FPS: float = 8.0
const ATTACK_FPS: float = 10.0

# Attack cooldown
const ATTACK_COOLDOWN: float = 1.0  # 1 second between attacks
var attack_cooldown_timer: float = 0.0

# Animation state
enum AnimState { IDLE, WALKING, ATTACKING }
var anim_state: AnimState = AnimState.IDLE
var anim_frame: int = 0
var anim_timer: float = 0.0

# Signal for attack cascade
signal attack_started

# Set by battle_scene.gd after instantiation
var camera_pivot: Node3D = null

# Directional idle sprites
var tex_front: Texture2D = preload("res://assets/sprites/ataturk/ataturk-front-rdy.png")
var tex_back: Texture2D = preload("res://assets/sprites/ataturk/ataturk-back-rdy.png")
var tex_side: Texture2D = preload("res://assets/sprites/ataturk/ataturk-side-left-rdy.png")
var tex_three_quarter: Texture2D = preload("res://assets/sprites/ataturk/ataturk-three-quarter-rdy.png")
var tex_three_quarter_back: Texture2D = preload("res://assets/sprites/ataturk/ataturk-three-quarter-back-rdy.png")

# Walk animation sprites (3 frames)
var tex_walk: Array[Texture2D] = [
	preload("res://assets/sprites/ataturk/walk-1-rdy.png"),
	preload("res://assets/sprites/ataturk/walk-2-rdy.png"),
	preload("res://assets/sprites/ataturk/walk-3-rdy.png"),
]

# Attack animation sprites (3 frames)
var tex_attack: Array[Texture2D] = [
	preload("res://assets/sprites/ataturk/attack-1-rdy.png"),
	preload("res://assets/sprites/ataturk/attack-2-rdy.png"),
	preload("res://assets/sprites/ataturk/attack-3-rdy.png"),
]

# Node references
@onready var sprite: Sprite3D = $Sprite3D
@onready var dust: GPUParticles3D = $DustParticles
@onready var attack_sound: AudioStreamPlayer3D = get_node_or_null("AttackSound")
@onready var attack_particles: GPUParticles3D = $AttackParticles

# Momentum state
var current_speed: float = 0.0
var current_direction: Vector3 = Vector3.FORWARD
var last_input_dir: Vector2 = Vector2.ZERO
var current_facing: String = "front"  # Track direction for walk animation logic


func _physics_process(delta: float) -> void:
	if camera_pivot == null:
		return

	# Update attack cooldown timer
	if attack_cooldown_timer > 0.0:
		attack_cooldown_timer -= delta

	# Handle attack input (can trigger from any state except attacking, with cooldown)
	if Input.is_action_just_pressed("attack") and anim_state != AnimState.ATTACKING and attack_cooldown_timer <= 0.0:
		start_attack()

	# Block movement during attack
	if anim_state == AnimState.ATTACKING:
		update_attack_animation(delta)
		# Decelerate while attacking
		current_speed = maxf(current_speed - DECELERATION * delta, 0.0)
		velocity = current_direction * current_speed
		move_and_slide()
		return

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")

	# Get camera's horizontal basis vectors
	var camera_basis := camera_pivot.global_transform.basis

	# Calculate desired movement direction relative to camera facing
	var desired_dir := Vector3.ZERO
	if input_dir.length_squared() > 0.01:
		desired_dir = (camera_basis.z * input_dir.y + camera_basis.x * input_dir.x)
		desired_dir.y = 0.0
		desired_dir = desired_dir.normalized()

	# Apply momentum physics
	if desired_dir.length_squared() > 0.01:
		# Player is pressing movement keys
		if current_speed > 0.1:
			# Check if changing direction significantly
			var dot := current_direction.dot(desired_dir)
			if dot < TURN_THRESHOLD:
				# Turning - apply penalty (reduce speed)
				current_speed *= TURN_PENALTY

		# Update direction and accelerate
		current_direction = desired_dir
		current_speed = minf(current_speed + ACCELERATION * delta, MAX_SPEED)

		# Update sprite facing
		update_sprite_facing(input_dir)
		last_input_dir = input_dir

		# Switch to walking state and update walk animation
		anim_state = AnimState.WALKING
		update_walk_animation(delta)
	else:
		# No input - decelerate
		current_speed = maxf(current_speed - DECELERATION * delta, 0.0)

		# Switch to idle when stopped
		if current_speed < 0.1:
			anim_state = AnimState.IDLE
			update_idle_sprite()
		else:
			# Still moving (momentum) - keep walk animation
			update_walk_animation(delta)

	# Apply velocity
	velocity = current_direction * current_speed
	move_and_slide()

	# Enforce boundary constraints
	global_position.x = clampf(global_position.x, -ARENA_BOUND, ARENA_BOUND)
	global_position.z = clampf(global_position.z, -ARENA_BOUND, ARENA_BOUND)

	# Control dust particles
	if dust:
		dust.emitting = current_speed > MAX_SPEED * 0.3

func update_sprite_facing(input_dir: Vector2) -> void:
	# input_dir from get_vector: x = left(-)/right(+), y = forward(-)/backward(+)
	var abs_x := absf(input_dir.x)
	var abs_y := absf(input_dir.y)

	# Check for diagonal movement - both axes have significant input
	var is_diagonal := abs_x > 0.5 and abs_y > 0.5

	if is_diagonal:
		# Diagonal movement - treat as forward/back for facing
		if input_dir.y < 0:
			current_facing = "back"
			sprite.texture = tex_three_quarter_back
			sprite.flip_h = input_dir.x < 0  # Flip for left diagonal
		else:
			current_facing = "front"
			sprite.texture = tex_three_quarter
			sprite.flip_h = input_dir.x > 0  # Flip for right diagonal
	elif abs_y > abs_x:
		# Moving primarily forward/backward
		if input_dir.y < 0:
			current_facing = "back"
			sprite.texture = tex_back
		else:
			current_facing = "front"
			sprite.texture = tex_front
		sprite.flip_h = false
	else:
		# Moving primarily left/right
		if input_dir.x > 0:
			current_facing = "right"
		else:
			current_facing = "left"
		sprite.texture = tex_side
		sprite.flip_h = input_dir.x > 0  # Flip for right

func is_moving() -> bool:
	return current_speed > 0.1

func get_speed_ratio() -> float:
	return current_speed / MAX_SPEED

func is_attacking() -> bool:
	return anim_state == AnimState.ATTACKING


# Animation functions

func update_walk_animation(delta: float) -> void:
	# Walk sprites are side-view only - only use for left/right movement
	# For forward/back, the directional sprite is already set by update_sprite_facing
	if current_facing != "left" and current_facing != "right":
		return  # Keep the directional sprite set by update_sprite_facing

	anim_timer += delta
	var frame_duration := 1.0 / WALK_FPS
	if anim_timer >= frame_duration:
		anim_timer -= frame_duration
		anim_frame = (anim_frame + 1) % tex_walk.size()
	sprite.texture = tex_walk[anim_frame]
	# flip_h is already set by update_sprite_facing for left/right


func update_attack_animation(delta: float) -> void:
	anim_timer += delta
	var frame_duration := 1.0 / ATTACK_FPS
	if anim_timer >= frame_duration:
		anim_timer -= frame_duration
		anim_frame += 1
		if anim_frame >= tex_attack.size():
			# Attack finished - return to idle
			anim_state = AnimState.IDLE
			anim_frame = 0
			anim_timer = 0.0
			update_idle_sprite()
			return
	sprite.texture = tex_attack[anim_frame]


func start_attack() -> void:
	anim_state = AnimState.ATTACKING
	anim_frame = 0
	anim_timer = 0.0
	attack_cooldown_timer = ATTACK_COOLDOWN
	sprite.texture = tex_attack[0]

	# Play attack sound
	if attack_sound:
		attack_sound.pitch_scale = randf_range(0.95, 1.05)  # Slight pitch variation
		attack_sound.play()

	# Trigger attack impact particles
	if attack_particles:
		attack_particles.restart()
		attack_particles.emitting = true

	attack_started.emit()


func update_idle_sprite() -> void:
	# Show directional idle sprite based on last input direction
	if last_input_dir.length_squared() < 0.01:
		sprite.texture = tex_front
		return
	update_sprite_facing(last_input_dir)
