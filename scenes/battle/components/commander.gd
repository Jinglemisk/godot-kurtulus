extends CharacterBody3D

## Commander - Player-controlled character with camera-relative movement
## Features: momentum physics, directional sprites, boundary constraints, visual effects

# Movement constants
const MAX_SPEED: float = 10.0
const ACCELERATION: float = 20.0       # Units/sec² - reaches max in 0.5s
const DECELERATION: float = 15.0       # Units/sec² - stops in ~0.67s
const TURN_PENALTY: float = 0.4        # Speed multiplier when changing direction
const TURN_THRESHOLD: float = 0.7      # Dot product threshold for "turning"
const ARENA_BOUND: float = 48.0        # Slightly inside the 50-unit posts

# Set by battle_scene.gd after instantiation
var camera_pivot: Node3D = null

# Directional sprites
var tex_front: Texture2D = preload("res://assets/sprites/ataturk/ataturk-front-rdy.png")
var tex_back: Texture2D = preload("res://assets/sprites/ataturk/ataturk-back-rdy.png")
var tex_side: Texture2D = preload("res://assets/sprites/ataturk/ataturk-side-left-rdy.png")
var tex_three_quarter: Texture2D = preload("res://assets/sprites/ataturk/ataturk-three-quarter-rdy.png")
var tex_three_quarter_back: Texture2D = preload("res://assets/sprites/ataturk/ataturk-three-quarter-back-rdy.png")

# Node references
@onready var sprite: Sprite3D = $Sprite3D
@onready var dust: GPUParticles3D = $DustParticles

# Momentum state
var current_speed: float = 0.0
var current_direction: Vector3 = Vector3.FORWARD
var last_input_dir: Vector2 = Vector2.ZERO


func _physics_process(delta: float) -> void:
	if camera_pivot == null:
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
	else:
		# No input - decelerate
		current_speed = maxf(current_speed - DECELERATION * delta, 0.0)

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
		# Diagonal movement
		if input_dir.y < 0:
			# Forward diagonal (W+A or W+D) - moving away, show back three-quarter
			sprite.texture = tex_three_quarter_back
			sprite.flip_h = input_dir.x < 0  # Flip for left diagonal
		else:
			# Backward diagonal (S+A or S+D) - moving toward camera, show front three-quarter
			sprite.texture = tex_three_quarter
			sprite.flip_h = input_dir.x > 0  # Flip for right diagonal
	elif abs_y > abs_x:
		# Moving primarily forward/backward
		if input_dir.y < 0:
			# W pressed = moving forward = show back
			sprite.texture = tex_back
		else:
			# S pressed = moving backward = show front
			sprite.texture = tex_front
		sprite.flip_h = false
	else:
		# Moving primarily left/right
		sprite.texture = tex_side
		sprite.flip_h = input_dir.x > 0  # Flip for right

func is_moving() -> bool:
	return current_speed > 0.1

func get_speed_ratio() -> float:
	return current_speed / MAX_SPEED
