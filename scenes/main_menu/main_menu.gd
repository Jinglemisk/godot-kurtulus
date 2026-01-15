extends Control

## Main Menu - Handles navigation and the cinematic transition to campaign selection

@onready var background: TextureRect = $BackgroundLayer/MapContainer/Background
@onready var title_label: Label = $UILayer/TitleContainer/Title
@onready var menu_container: VBoxContainer = $UILayer/MenuContainer
@onready var new_game_button: Button = $UILayer/MenuContainer/NewGameButton
@onready var settings_button: Button = $UILayer/MenuContainer/SettingsButton
@onready var fade_rect: ColorRect = $TransitionLayer/FadeRect

const MENU_THEME_PATH = "res://assets/menu-theme.mp3"

var is_transitioning: bool = false

func _ready() -> void:
	# Start background music
	var menu_music = load(MENU_THEME_PATH)
	AudioManager.play_music(menu_music, 2.0)

	# Connect button signals
	new_game_button.pressed.connect(_on_new_game_pressed)
	settings_button.pressed.connect(_on_settings_pressed)

	# Setup button hover effects
	_setup_button_effects(new_game_button)
	_setup_button_effects(settings_button)

	# Fade in from black on scene load
	fade_rect.color.a = 1.0
	var fade_tween = create_tween()
	fade_tween.tween_property(fade_rect, "color:a", 0.0, 0.5)

	# Animate menu items entrance
	_animate_menu_entrance()

func _setup_button_effects(button: Button) -> void:
	button.mouse_entered.connect(func(): _on_button_hover(button, true))
	button.mouse_exited.connect(func(): _on_button_hover(button, false))

func _on_button_hover(button: Button, hovered: bool) -> void:
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUAD)

	if hovered:
		tween.tween_property(button, "scale", Vector2(1.05, 1.05), 0.15)
	else:
		tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.15)

func _animate_menu_entrance() -> void:
	# Start with elements invisible and offset
	title_label.modulate.a = 0.0
	title_label.position.y -= 30

	for child in menu_container.get_children():
		child.modulate.a = 0.0
		child.position.x -= 50

	# Animate title
	var title_tween = create_tween()
	title_tween.set_ease(Tween.EASE_OUT)
	title_tween.set_trans(Tween.TRANS_QUAD)
	title_tween.tween_property(title_label, "modulate:a", 1.0, 0.8)
	title_tween.parallel().tween_property(title_label, "position:y", title_label.position.y + 30, 0.8)

	# Animate menu items with stagger
	await get_tree().create_timer(0.3).timeout
	var delay = 0.0
	for child in menu_container.get_children():
		var item_tween = create_tween()
		item_tween.set_ease(Tween.EASE_OUT)
		item_tween.set_trans(Tween.TRANS_QUAD)
		item_tween.tween_property(child, "modulate:a", 1.0, 0.5).set_delay(delay)
		item_tween.parallel().tween_property(child, "position:x", child.position.x + 50, 0.5).set_delay(delay)
		delay += 0.1

func _on_new_game_pressed() -> void:
	if is_transitioning:
		return
	is_transitioning = true

	# Disable buttons during transition
	new_game_button.disabled = true
	settings_button.disabled = true

	_animate_new_game_transition()

func _animate_new_game_transition() -> void:
	# Get viewport size for pivot calculation
	var viewport_size = get_viewport().get_visible_rect().size
	background.pivot_offset = viewport_size / 2.0

	# Create main transition tween
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_QUAD)

	# Phase 1: Fade out UI elements (0.3s)
	tween.tween_property(title_label, "modulate:a", 0.0, 0.3)
	tween.parallel().tween_property(menu_container, "modulate:a", 0.0, 0.3)

	# Phase 2: Zoom and rotate map (1.5s) - run in parallel
	tween.set_parallel(true)
	tween.tween_property(background, "scale", Vector2(1.8, 1.8), 1.5)
	tween.tween_property(background, "rotation_degrees", 7.0, 1.5)

	# Phase 3: Fade to black (starts after 1.0s of zoom, overlaps)
	tween.set_parallel(false)
	tween.tween_interval(0.5)  # Wait a bit into the zoom
	tween.tween_property(fade_rect, "color:a", 1.0, 0.5).set_ease(Tween.EASE_IN)

	# Phase 4: Change scene on completion
	tween.tween_callback(_load_campaign_selection)

func _load_campaign_selection() -> void:
	get_tree().change_scene_to_file("res://scenes/campaign_selection/campaign_selection.tscn")

func _on_settings_pressed() -> void:
	if is_transitioning:
		return
	is_transitioning = true

	# Simple fade to settings
	var tween = create_tween()
	tween.tween_property(fade_rect, "color:a", 1.0, 0.3)
	tween.tween_callback(func(): get_tree().change_scene_to_file("res://scenes/settings/settings.tscn"))
