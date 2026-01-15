extends Control

## Settings - Placeholder screen

@onready var back_button: Button = $ContentContainer/Panel/VBoxContainer/BackButton
@onready var fade_rect: ColorRect = $TransitionLayer/FadeRect

var is_transitioning: bool = false

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)

	# Fade in from black
	fade_rect.color.a = 1.0
	var tween = create_tween()
	tween.tween_property(fade_rect, "color:a", 0.0, 0.3)

func _on_back_pressed() -> void:
	if is_transitioning:
		return
	is_transitioning = true

	var tween = create_tween()
	tween.tween_property(fade_rect, "color:a", 1.0, 0.3)
	tween.tween_callback(func(): get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn"))
