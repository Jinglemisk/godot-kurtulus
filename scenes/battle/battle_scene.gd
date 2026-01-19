extends Node3D

## BattleScene - Phase 5: Enemy Unit & Integration
## WASD moves commander, camera follows, Q/E orbits around commander
## Enemy unit positioned across the arena with red tint
## Attacks deal damage when in range, enemy soldiers disappear as HP drops

@onready var camera_pivot: Node3D = $CameraPivot
@onready var unit: Node3D = $Unit
@onready var enemy_unit: Node3D = $EnemyUnit
@onready var commander: CharacterBody3D = $Unit/Commander
@onready var fade_rect: ColorRect = $UI/TransitionLayer/FadeRect
@onready var victory_popup: CenterContainer = $UI/VictoryPopup
@onready var play_again_btn: Button = $UI/VictoryPopup/Panel/VBox/Buttons/PlayAgainButton
@onready var main_menu_btn: Button = $UI/VictoryPopup/Panel/VBox/Buttons/MainMenuButton

const CAMERA_ROTATION_SPEED: float = 2.0  # radians per second
const CAMERA_FOLLOW_SPEED: float = 8.0    # lerp smoothing factor
const ENEMY_TINT: Color = Color(1.0, 0.5, 0.5, 1.0)  # Red tint for enemy

# Combat settings
const ATTACK_RANGE: float = 12.0  # Units must be within this distance to deal damage
const DAMAGE_PER_ATTACK: int = 250  # Damage dealt per attack cascade (8 attacks = defeat)

# State
var input_enabled: bool = true

# Battle music
var battle_music: AudioStream = preload("res://assets/battle-music.mp3")

func _ready() -> void:
	# Wire unit's camera reference (unit passes it to commander)
	unit.camera_pivot = camera_pivot

	# Apply red tint to enemy unit sprites
	_apply_tint_recursive(enemy_unit, ENEMY_TINT)

	# Connect combat signals
	commander.attack_started.connect(_on_player_attack)
	enemy_unit.unit_defeated.connect(_on_enemy_defeated)
	enemy_unit.troop_count_changed.connect(_on_enemy_troop_count_changed)

	# Connect victory popup buttons
	play_again_btn.pressed.connect(_on_play_again)
	main_menu_btn.pressed.connect(_on_main_menu)

	# Crossfade to battle music
	AudioManager.crossfade_to(battle_music)

	# Fade in from black (following project pattern)
	fade_rect.color.a = 1.0
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(fade_rect, "color:a", 0.0, 0.5)


## Recursively apply modulate tint to all Sprite3D nodes
func _apply_tint_recursive(node: Node, tint: Color) -> void:
	if node is Sprite3D:
		node.modulate = tint
	for child in node.get_children():
		_apply_tint_recursive(child, tint)

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


## Check if player unit is within attack range of enemy
func _is_in_attack_range() -> bool:
	# Use commander position (the moving character), not the static Unit node
	var player_pos: Vector3 = commander.global_position
	var enemy_commander: Node3D = enemy_unit.get_node("Commander")
	var distance: float = player_pos.distance_to(enemy_commander.global_position)
	return distance <= ATTACK_RANGE


## Handle player attack - deal damage to enemy if in range
func _on_player_attack() -> void:
	if not input_enabled:
		return

	var enemy_commander: Node3D = enemy_unit.get_node("Commander")
	var distance: float = commander.global_position.distance_to(enemy_commander.global_position)

	if _is_in_attack_range():
		enemy_unit.take_damage(DAMAGE_PER_ATTACK)
		print("Attack hit! Enemy troops: %d/%d" % [enemy_unit.troop_count, enemy_unit.MAX_TROOP_COUNT])
	else:
		print("Attack missed - enemy out of range (distance: %.1f, range: %.1f)" % [
			distance,
			ATTACK_RANGE
		])


## Handle enemy troop count changes (for future UI updates)
func _on_enemy_troop_count_changed(current: int, maximum: int) -> void:
	# Could update a health bar UI here in the future
	pass


## Handle enemy defeat - trigger victory
func _on_enemy_defeated() -> void:
	print("VICTORY! Enemy unit defeated!")
	input_enabled = false

	# Show victory popup with animation after short delay
	await get_tree().create_timer(0.5).timeout
	_show_victory_popup()


## Display victory popup with scale animation
func _show_victory_popup() -> void:
	victory_popup.visible = true
	victory_popup.scale = Vector2.ZERO
	victory_popup.modulate.a = 0.0

	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(victory_popup, "scale", Vector2.ONE, 0.4)
	tween.tween_property(victory_popup, "modulate:a", 1.0, 0.3)


## Restart the battle
func _on_play_again() -> void:
	get_tree().reload_current_scene()


## Return to main menu
func _on_main_menu() -> void:
	# Fade out then change scene
	var tween := create_tween()
	tween.tween_property(fade_rect, "color:a", 1.0, 0.3)
	tween.tween_callback(func(): get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn"))
