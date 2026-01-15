extends PanelContainer
class_name CommanderCard

## Commander Card - Displays a commander option with hover effects and tooltip

signal commander_selected(commander_id: String)

@onready var portrait: TextureRect = $VBoxContainer/PortraitContainer/Portrait
@onready var name_label: Label = $VBoxContainer/NameLabel
@onready var type_label: Label = $VBoxContainer/TypeContainer/TypeLabel
@onready var position_label: Label = $VBoxContainer/PositionLabel
@onready var backstory_label: RichTextLabel = $VBoxContainer/BackstoryContainer/BackstoryLabel
@onready var select_button: Button = $VBoxContainer/SelectButton

var commander_id: String = ""
var is_locked: bool = false

const LOCKED_TINT = Color(0.5, 0.5, 0.5, 1.0)
const NORMAL_TINT = Color(1.0, 1.0, 1.0, 1.0)

func _ready() -> void:
	select_button.pressed.connect(_on_select_pressed)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func setup(data: Dictionary, type_tooltips: Dictionary) -> void:
	commander_id = data.get("id", "")
	is_locked = data.get("is_locked", false)

	name_label.text = data.get("name", "Unknown Commander")
	position_label.text = data.get("position", "")

	# Setup type with tooltip
	var type_key = data.get("type", "")
	if type_tooltips.has(type_key):
		var type_data = type_tooltips[type_key]
		type_label.text = type_data.get("name", type_key.capitalize())
		type_label.tooltip_text = type_data.get("tooltip", "")
	else:
		type_label.text = type_key.capitalize()

	# Backstory - show first paragraph or mystery text if locked
	if is_locked:
		backstory_label.text = "[i]This commander's history remains shrouded in mystery...[/i]"
	else:
		var full_backstory = data.get("backstory", "")
		var paragraphs = full_backstory.split("\n\n")
		backstory_label.text = paragraphs[0] if paragraphs.size() > 0 else ""

	# Portrait
	var portrait_path = data.get("portrait_path", "")
	if portrait_path != "" and ResourceLoader.exists(portrait_path):
		portrait.texture = load(portrait_path)

	# Locked state styling
	if is_locked:
		select_button.text = "Locked"
		select_button.disabled = true
		modulate = LOCKED_TINT
	else:
		select_button.text = "Select"
		select_button.disabled = false
		modulate = NORMAL_TINT

func _on_select_pressed() -> void:
	if not is_locked:
		commander_selected.emit(commander_id)

func _on_mouse_entered() -> void:
	if is_locked:
		return

	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(self, "scale", Vector2(1.02, 1.02), 0.2)
	tween.parallel().tween_property(self, "modulate", Color(1.1, 1.1, 1.1, 1.0), 0.2)

func _on_mouse_exited() -> void:
	if is_locked:
		return

	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.2)
	tween.parallel().tween_property(self, "modulate", NORMAL_TINT, 0.2)
