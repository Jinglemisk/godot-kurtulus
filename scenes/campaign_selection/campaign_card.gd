extends PanelContainer
class_name CampaignCard

## Campaign Card - Reusable component for displaying a campaign option

signal campaign_selected(campaign_id: String)

@onready var campaign_image: TextureRect = $VBoxContainer/ImageContainer/CampaignImage
@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var year_label: Label = $VBoxContainer/YearLabel
@onready var description_label: RichTextLabel = $VBoxContainer/DescriptionLabel
@onready var select_button: Button = $VBoxContainer/SelectButton

var campaign_id: String = ""

func _ready() -> void:
	select_button.pressed.connect(_on_select_pressed)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func setup(data: Dictionary) -> void:
	campaign_id = data.get("id", "")
	title_label.text = data.get("title", "Unknown Campaign")
	year_label.text = data.get("years", "")
	description_label.text = data.get("description", "")

	var image_path = data.get("image_path", "")
	if image_path != "" and ResourceLoader.exists(image_path):
		campaign_image.texture = load(image_path)

func _on_select_pressed() -> void:
	campaign_selected.emit(campaign_id)

func _on_mouse_entered() -> void:
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(self, "scale", Vector2(1.02, 1.02), 0.2)
	tween.parallel().tween_property(self, "modulate", Color(1.1, 1.1, 1.1, 1.0), 0.2)

func _on_mouse_exited() -> void:
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.2)
	tween.parallel().tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.2)
