extends Control

## Campaign Selection - Choose from Early, Middle, or Late campaigns

@onready var campaigns_container: HBoxContainer = $UILayer/CampaignsContainer
@onready var back_button: Button = $UILayer/BackButton
@onready var fade_rect: ColorRect = $TransitionLayer/FadeRect

const CampaignCardScene = preload("res://scenes/campaign_selection/campaign_card.tscn")

const CAMPAIGNS = {
	"early": {
		"id": "early",
		"title": "İşgal Dönemi",
		"years": "1919-1920",
		"image_path": "res://assets/early-campaign.jpeg",
		"description": "The Allied powers carve up Anatolia among themselves. Greek forces land at İzmir. In the chaos of occupation, Mustafa Kemal arrives at Samsun on May 19, 1919.\n\nThe spark of national resistance is lit. Unite the scattered resistance movements and lay the foundations for the struggle ahead."
	},
	"middle": {
		"id": "middle",
		"title": "Milli Direniş",
		"years": "1920-1921",
		"image_path": "res://assets/mid-campaign.jpeg",
		"description": "The Grand National Assembly convenes in Ankara. A regular army rises from the ashes of the Ottoman military. The First and Second Battles of İnönü halt the Greek advance.\n\nThe critical Battle of Sakarya looms on the horizon. Hold the line and prepare for the decisive blow."
	},
	"late": {
		"id": "late",
		"title": "Zafer Yolu",
		"years": "1922-1923",
		"image_path": "res://assets/late-campaign.jpeg",
		"description": "The Great Offensive begins. The Battle of Dumlupınar shatters the enemy. Turkish forces sweep westward in pursuit.\n\nDrive the invaders into the sea and march triumphantly into İzmir. Victory and independence await."
	}
}

var is_transitioning: bool = false

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)

	# Setup campaign cards
	_setup_campaign_cards()

	# Fade in from black
	fade_rect.color.a = 1.0
	var tween = create_tween()
	tween.tween_property(fade_rect, "color:a", 0.0, 0.5)

	# Animate cards entrance
	_animate_cards_entrance()

func _setup_campaign_cards() -> void:
	# Clear any existing cards
	for child in campaigns_container.get_children():
		child.queue_free()

	# Create cards for each campaign
	for campaign_key in ["early", "middle", "late"]:
		var card = CampaignCardScene.instantiate()
		campaigns_container.add_child(card)
		card.setup(CAMPAIGNS[campaign_key])
		card.campaign_selected.connect(_on_campaign_selected)

func _animate_cards_entrance() -> void:
	var delay = 0.0
	for card in campaigns_container.get_children():
		card.modulate.a = 0.0
		card.position.y += 50

		var tween = create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_QUAD)
		tween.tween_property(card, "modulate:a", 1.0, 0.5).set_delay(delay)
		tween.parallel().tween_property(card, "position:y", card.position.y - 50, 0.5).set_delay(delay)
		delay += 0.15

func _on_campaign_selected(campaign_id: String) -> void:
	if is_transitioning:
		return
	is_transitioning = true

	print("Campaign selected: ", campaign_id)

	# Store campaign selection in GameManager
	GameManager.set_campaign(campaign_id, CAMPAIGNS[campaign_id])

	var tween = create_tween()
	tween.tween_property(fade_rect, "color:a", 1.0, 0.5)
	tween.tween_callback(func():
		get_tree().change_scene_to_file("res://scenes/commander_selection/commander_selection.tscn")
	)

func _on_back_pressed() -> void:
	if is_transitioning:
		return
	is_transitioning = true

	var tween = create_tween()
	tween.tween_property(fade_rect, "color:a", 1.0, 0.3)
	tween.tween_callback(func(): get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn"))
