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

# HP bar UI elements
@onready var player_hp_panel: MarginContainer = $UI/PlayerHPPanel
@onready var player_health_bar: ProgressBar = $UI/PlayerHPPanel/OrnateFrame/VBoxContainer/HealthBarContainer/HealthBar
@onready var player_troop_label: Label = $UI/PlayerHPPanel/OrnateFrame/VBoxContainer/HealthBarContainer/TroopCountLabel

@onready var enemy_hp_panel: MarginContainer = $UI/EnemyHPPanel
@onready var enemy_health_bar: ProgressBar = $UI/EnemyHPPanel/OrnateFrame/VBoxContainer/HealthBarContainer/HealthBar
@onready var enemy_troop_label: Label = $UI/EnemyHPPanel/OrnateFrame/VBoxContainer/HealthBarContainer/TroopCountLabel

@onready var mute_button: Button = $UI/MuteButton

# Discovery popup and damage numbers
@onready var discovery_popup: CenterContainer = $UI/DiscoveryPopup
@onready var discovery_label: Label = $UI/DiscoveryPopup/Panel/DiscoveryLabel
@onready var damage_numbers_container: Control = $UI/DamageNumbersContainer
@onready var camera: Camera3D = $CameraPivot/Camera3D

const CAMERA_ROTATION_SPEED: float = 2.0  # radians per second
const CAMERA_FOLLOW_SPEED: float = 8.0    # lerp smoothing factor
const ENEMY_TINT: Color = Color(1.0, 0.5, 0.5, 1.0)  # Red tint for enemy

# Combat settings
const ATTACK_RANGE: float = 12.0  # Units must be within this distance to deal damage
const DAMAGE_PER_ATTACK: int = 250  # Damage dealt per attack cascade (8 attacks = defeat)

# Audio settings
const BATTLE_VOLUME_DB: float = -6.0  # 50% reduction from normal

# HP bar style references (set in _ready)
var hp_fill_player_normal: StyleBoxFlat
var hp_fill_enemy_normal: StyleBoxFlat
var hp_fill_critical: StyleBoxFlat

# Low HP threshold (20%)
const LOW_HP_THRESHOLD: float = 0.2

# State
var input_enabled: bool = true
var is_muted: bool = false
var enemy_discovered: bool = false

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
	unit.troop_count_changed.connect(_on_player_troop_count_changed)

	# Store original HP bar styles and create critical style
	hp_fill_player_normal = player_health_bar.get_theme_stylebox("fill").duplicate()
	hp_fill_enemy_normal = enemy_health_bar.get_theme_stylebox("fill").duplicate()
	hp_fill_critical = StyleBoxFlat.new()
	hp_fill_critical.bg_color = Color(0.8, 0.15, 0.15, 1.0)  # Bright red for critical HP
	hp_fill_critical.corner_radius_top_left = 2
	hp_fill_critical.corner_radius_top_right = 2
	hp_fill_critical.corner_radius_bottom_left = 2
	hp_fill_critical.corner_radius_bottom_right = 2

	# Initialize health bars with unit data
	player_health_bar.max_value = unit.MAX_TROOP_COUNT
	player_health_bar.value = unit.troop_count
	player_troop_label.text = "%d/%d" % [unit.troop_count, unit.MAX_TROOP_COUNT]

	enemy_health_bar.max_value = enemy_unit.MAX_TROOP_COUNT
	enemy_health_bar.value = enemy_unit.troop_count
	enemy_troop_label.text = "%d/%d" % [enemy_unit.troop_count, enemy_unit.MAX_TROOP_COUNT]

	# Connect mute button
	mute_button.pressed.connect(_on_mute_pressed)

	# Connect victory popup buttons
	play_again_btn.pressed.connect(_on_play_again)
	main_menu_btn.pressed.connect(_on_main_menu)

	# Crossfade to battle music
	AudioManager.crossfade_to(battle_music)

	# Reduce volume after crossfade completes (crossfade takes 2s by default)
	_set_battle_volume_after_crossfade()

	# Fade in from black (following project pattern)
	fade_rect.color.a = 1.0
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(fade_rect, "color:a", 0.0, 0.5)


## Async helper to set volume after crossfade completes
func _set_battle_volume_after_crossfade() -> void:
	await get_tree().create_timer(2.1).timeout
	if not is_muted:  # Don't override mute if user already muted
		AudioManager.set_volume(BATTLE_VOLUME_DB)


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

	# Show/hide enemy HP panel based on proximity (within attack range)
	var in_range := _is_in_attack_range()
	enemy_hp_panel.visible = in_range

	# Show discovery popup when enemy first spotted
	if in_range and not enemy_discovered:
		enemy_discovered = true
		_show_discovery_popup()


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
		# Spawn floating damage number at enemy position
		_spawn_damage_number(enemy_commander.global_position, DAMAGE_PER_ATTACK)
		print("Attack hit! Enemy troops: %d/%d" % [enemy_unit.troop_count, enemy_unit.MAX_TROOP_COUNT])
	else:
		print("Attack missed - enemy out of range (distance: %.1f, range: %.1f)" % [
			distance,
			ATTACK_RANGE
		])


## Handle player troop count changes - update HP bar with smooth tween
func _on_player_troop_count_changed(current: int, maximum: int) -> void:
	var tween := create_tween()
	tween.tween_property(player_health_bar, "value", current, 0.3)
	player_troop_label.text = "%d/%d" % [current, maximum]

	# Change color to red at low HP (20%)
	var hp_percent := float(current) / float(maximum)
	if hp_percent <= LOW_HP_THRESHOLD:
		player_health_bar.add_theme_stylebox_override("fill", hp_fill_critical)
	else:
		player_health_bar.add_theme_stylebox_override("fill", hp_fill_player_normal)


## Handle enemy troop count changes - update HP bar with smooth tween
func _on_enemy_troop_count_changed(current: int, maximum: int) -> void:
	var tween := create_tween()
	tween.tween_property(enemy_health_bar, "value", current, 0.3)
	enemy_troop_label.text = "%d/%d" % [current, maximum]

	# Change color to bright red at low HP (20%)
	var hp_percent := float(current) / float(maximum)
	if hp_percent <= LOW_HP_THRESHOLD:
		enemy_health_bar.add_theme_stylebox_override("fill", hp_fill_critical)
	else:
		enemy_health_bar.add_theme_stylebox_override("fill", hp_fill_enemy_normal)


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


## Toggle mute on/off
func _on_mute_pressed() -> void:
	is_muted = !is_muted
	if is_muted:
		AudioManager.set_volume(-80.0)  # Effectively mute
		mute_button.text = "🔇"
	else:
		AudioManager.set_volume(BATTLE_VOLUME_DB)
		mute_button.text = "🔊"


## Show discovery popup with slide-up animation
func _show_discovery_popup() -> void:
	discovery_label.text = "Şemsettin has spotted Yorgos!"
	discovery_popup.visible = true
	discovery_popup.modulate.a = 0.0

	# Slide up and fade in
	var start_offset := discovery_popup.offset_top
	discovery_popup.offset_top = start_offset + 30  # Start lower

	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(discovery_popup, "modulate:a", 1.0, 0.4)
	tween.tween_property(discovery_popup, "offset_top", start_offset, 0.4)

	# Auto-hide after 3 seconds
	await get_tree().create_timer(3.0).timeout
	var fade_tween := create_tween()
	fade_tween.tween_property(discovery_popup, "modulate:a", 0.0, 0.5)
	fade_tween.tween_callback(func(): discovery_popup.visible = false)


## Spawn a floating damage number at world position
func _spawn_damage_number(world_pos: Vector3, damage: int) -> void:
	# Convert 3D position to 2D screen position
	var screen_pos := camera.unproject_position(world_pos)

	# Create damage label
	var label := Label.new()
	label.text = "-%d" % damage
	label.add_theme_font_override("font", preload("res://assets/alfabet98.ttf"))
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3, 1.0))  # Red color
	label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
	label.add_theme_constant_override("outline_size", 3)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = screen_pos - Vector2(30, 20)  # Center roughly
	label.z_index = 100  # Above other UI

	damage_numbers_container.add_child(label)

	# Animate: float up and fade out
	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(label, "position:y", label.position.y - 60, 1.0)  # Float up
	tween.tween_property(label, "modulate:a", 0.0, 1.0).set_delay(0.3)  # Fade after 0.3s

	# Clean up after animation
	tween.chain().tween_callback(label.queue_free)
