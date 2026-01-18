extends Node3D

## BattleScene - Phase 2: Commander Movement with camera follow
## WASD moves commander, camera follows, Q/E orbits around commander

@onready var camera_pivot: Node3D = $CameraPivot
@onready var commander: CharacterBody3D = $Commander
@onready var fade_rect: ColorRect = $UI/TransitionLayer/FadeRect

const CAMERA_ROTATION_SPEED: float = 2.0  # radians per second
const CAMERA_FOLLOW_SPEED: float = 8.0    # lerp smoothing factor

func _ready() -> void:
	# Wire commander's camera reference
	commander.camera_pivot = camera_pivot

	# Fade in from black (following project pattern)
	fade_rect.color.a = 1.0
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(fade_rect, "color:a", 0.0, 0.5)

func _process(delta: float) -> void:
	# Camera follow - smooth follow commander position
	var target_pos := commander.global_position
	camera_pivot.global_position = camera_pivot.global_position.lerp(
		target_pos, delta * CAMERA_FOLLOW_SPEED
	)

	# Camera rotation (Q/E)
	# Q rotates left (counter-clockwise from above = positive Y rotation)
	if Input.is_action_pressed("camera_left"):
		camera_pivot.rotate_y(CAMERA_ROTATION_SPEED * delta)

	# E rotates right (clockwise from above = negative Y rotation)
	if Input.is_action_pressed("camera_right"):
		camera_pivot.rotate_y(-CAMERA_ROTATION_SPEED * delta)
