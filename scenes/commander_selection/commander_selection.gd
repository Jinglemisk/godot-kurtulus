extends Control

## Commander Selection - Tab-based selection with portrait and info panels

@onready var tabs_container: HBoxContainer = $UILayer/TabsContainer
@onready var name_label: Label = $UILayer/ContentContainer/LeftPanel/NameLabel
@onready var type_label: Label = $UILayer/ContentContainer/LeftPanel/TypeLabel
@onready var position_label: Label = $UILayer/ContentContainer/LeftPanel/PositionLabel
@onready var biography_label: RichTextLabel = $UILayer/ContentContainer/LeftPanel/BiographyContainer/BiographyLabel
@onready var bonuses_label: RichTextLabel = $UILayer/ContentContainer/LeftPanel/BonusesBox/MarginContainer/BonusesLabel
@onready var portrait: TextureRect = $UILayer/ContentContainer/RightPanel/PortraitContainer/Portrait
@onready var select_button: Button = $UILayer/SelectButton
@onready var back_button: Button = $UILayer/BackButton
@onready var fade_rect: ColorRect = $TransitionLayer/FadeRect
@onready var subtitle_label: Label = $UILayer/Header/VBoxContainer/Subtitle

const COMMANDER_TYPES = {
	"organizer": {
		"name": "Organizer",
		"tooltip": "Organizers excel at coordinating large-scale operations and maintaining unit cohesion. They provide bonuses to army organization, command capacity, and recovery from disruption. Their methodical approach ensures troops fight as a unified force.",
		"bonuses": [
			"+1 Officer slot",
			"+25% Officer efficiency",
			"+15% Organization recovery"
		]
	},
	"logistician": {
		"name": "Logistician",
		"tooltip": "Logisticians are masters of supply and sustainment. They provide bonuses to supply efficiency, ammunition conservation, and march speed. An army marches on its stomach, and under a Logistician's command, your forces will never want for provisions.",
		"bonuses": [
			"+30% Supply efficiency",
			"-20% Ammunition consumption",
			"+10% March speed"
		]
	},
	"raider": {
		"name": "Raider",
		"tooltip": "Raiders specialize in irregular warfare and disruption of enemy operations. They provide bonuses to reconnaissance, ambush effectiveness, and evasion. Masters of hit-and-run tactics, they excel at harassing enemy supply lines.",
		"bonuses": [
			"+40% Reconnaissance range",
			"+25% Ambush damage",
			"+20% Evasion chance"
		]
	},
	"engineer": {
		"name": "Engineer",
		"tooltip": "Engineers are experts in fortification and siege warfare. They provide bonuses to entrenchment speed, defensive positions, and breaching enemy fortifications. They shape the battlefield itself.",
		"bonuses": [
			"+50% Entrenchment speed",
			"+20% Defensive bonus",
			"-25% Siege time"
		]
	}
}

const COMMANDERS = {
	"semseddin": {
		"id": "semseddin",
		"name": "Şemsettin (Taner)",
		"type": "organizer",
		"position": "Chief of Staff, 1st Army",
		"portrait_path": "res://assets/taner.jpeg",
		"is_locked": false,
		"backstory": """Şemseddin's family arrived in Anatolia during the great muhacir exodus of 1878, when his grandfather led their clan from the mountains of Albania after the Congress of Berlin redrew the Balkans. They settled in Bursa, where three generations established themselves as respected members of the community.

Born in 1886, young Şemseddin showed an aptitude for mathematics and systematic thinking that earned him a place at the Harbiye Military Academy in Istanbul. There, he distinguished himself through meticulous attention to detail and his ability to coordinate complex operations during staff exercises.

The Balkan Wars tested his abilities under fire. While others sought glory in cavalry charges, Şemseddin worked tirelessly in headquarters, ensuring units received orders on time, supplies reached the front, and reinforcements arrived where needed. His superiors noted his calm demeanor during the chaos of retreat.

Now serving as Chief of Staff of the 1st Army, Şemseddin Bey brings order to chaos. His gift lies not in leading charges but in ensuring that when charges are ordered, every unit knows its role, every supply wagon reaches its destination, and every soldier understands their place in the greater design."""
	},
	"fevzi": {
		"id": "fevzi",
		"name": "Fevzi (Çakmak)",
		"type": "logistician",
		"position": "Quartermaster General, Western Front",
		"portrait_path": "res://assets/locked.jpeg",
		"is_locked": true,
		"backstory": """The son of a merchant family from Konya, Fevzi learned the art of logistics long before he learned the art of war. His father's caravans crossed Anatolia carrying grain, cloth, and ironware, and young Fevzi accompanied them, learning which mountain passes remained open in winter, which villages had surplus grain, and which routes avoided bandit territory.

Military service called him to the Quartermaster Corps during the Great War, where the Empire's crumbling supply lines presented an impossible challenge. While armies starved in the Caucasus and Palestine, Fevzi performed miracles with meager resources, improvising supply networks from local sources when official channels failed.

He witnessed firsthand the collapse that comes when soldiers have no bread, no bullets, no boots. The bitter lessons of those years forged an unshakeable conviction: logistics wins wars as surely as tactics, and a hungry army cannot fight no matter how brave its soldiers.

As Quartermaster General of the Western Front, Fevzi Efendi has rebuilt the supply apparatus from nothing. His knowledge of Anatolian geography, his network of contacts among merchants and farmers, and his tireless attention to mundane details ensure the national forces never suffer the deprivations that doomed the Ottoman armies."""
	},
	"yusuf": {
		"id": "yusuf",
		"name": "Yusuf (Efe)",
		"type": "raider",
		"position": "Commander, Kuva-yi Seyyare",
		"portrait_path": "res://assets/locked.jpeg",
		"is_locked": true,
		"backstory": """In the wild country between Kastamonu and the Black Sea coast, Yusuf Kahya's name was known long before the war began. The youngest son of a village aga, he had spent his youth hunting bandits in the mountain passes - sometimes as a gendarme, sometimes merely as a man who understood that the mountains belonged to those who knew them best.

When the Greeks landed at İzmir and the Sultan's government did nothing, Yusuf gathered the men who had ridden with him through the years - shepherds who knew every goat track, hunters who could move through forests without sound, former soldiers who had learned guerrilla tactics fighting against Bulgarian komitadjis.

His band struck without warning and vanished like smoke. Supply convoys disappeared. Outposts were overrun in night raids. Collaborators received visits they did not survive. The occupation forces learned to fear the shadows of the Anatolian hills.

Now commanding the Kuva-yi Seyyare mobile forces, Yusuf Kahya wages a different kind of war. He does not seek pitched battles but bleeding wounds - a hundred small cuts that drain the enemy's strength. His riders appear where least expected, strike hard, and melt away before pursuit can organize."""
	},
	"ihsan": {
		"id": "ihsan",
		"name": "İhsan (Sabis)",
		"type": "engineer",
		"position": "Chief of Military Engineering",
		"portrait_path": "res://assets/locked.jpeg",
		"is_locked": true,
		"backstory": """İhsan's path to war began in the classrooms of the Imperial School of Military Engineering in Constantinople, where he studied the great fortifications of history - from Vauban's star forts to the modern entrenchments of the Russo-Japanese War. His professors recognized a student who understood that battles are won not just by courage but by the ground on which they are fought.

The Great War sent him to Gallipoli, where he supervised the construction of the trench networks that turned the peninsula into an impregnable fortress. He learned to read terrain the way a scholar reads books, understanding instinctively where to place a machine gun nest, how to site artillery to cover dead ground, where attackers would seek cover and how to deny it to them.

At the Dardanelles, he watched waves of enemy soldiers break against defenses he had designed. The experience left him with no illusions about the cost of attacking prepared positions - or the value of proper fortification.

Now Chief of Military Engineering for the Grand National Assembly forces, İhsan Bey transforms the Anatolian landscape into a weapon. His defensive lines channel enemy attacks into killing grounds. His field fortifications turn ordinary hills into fortresses. He teaches that the shovel is as mighty as the rifle."""
	}
}

const COMMANDER_ORDER = ["semseddin", "fevzi", "yusuf", "ihsan"]

var current_commander_id: String = ""
var tab_buttons: Dictionary = {}
var is_transitioning: bool = false

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	select_button.pressed.connect(_on_select_pressed)

	_setup_subtitle()
	_setup_tabs()
	_select_commander(COMMANDER_ORDER[0])

	# Fade in from black
	fade_rect.color.a = 1.0
	var tween = create_tween()
	tween.tween_property(fade_rect, "color:a", 0.0, 0.5)

func _setup_subtitle() -> void:
	var campaign_title = GameManager.get_campaign_title()
	var campaign_years = GameManager.get_campaign_years()

	if campaign_title != "" and campaign_years != "":
		subtitle_label.text = "%s - %s" % [campaign_title, campaign_years]
	else:
		subtitle_label.text = "Select your leader"

func _setup_tabs() -> void:
	# Clear existing tabs
	for child in tabs_container.get_children():
		child.queue_free()

	# Create tab button for each commander
	for commander_id in COMMANDER_ORDER:
		var data = COMMANDERS[commander_id]
		var btn = Button.new()
		btn.text = data.name
		btn.toggle_mode = true
		btn.flat = true
		btn.add_theme_font_size_override("font_size", 22)
		btn.add_theme_color_override("font_color", Color(1, 0.992157, 0.815686, 0.6))
		btn.add_theme_color_override("font_hover_color", Color(1, 0.992157, 0.815686, 1))
		btn.add_theme_color_override("font_pressed_color", Color(0.831373, 0.686275, 0.215686, 1))
		btn.add_theme_color_override("font_focus_color", Color(0.831373, 0.686275, 0.215686, 1))
		btn.custom_minimum_size = Vector2(180, 40)

		if data.is_locked:
			btn.text = data.name + " [Locked]"
			btn.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 0.6))
			btn.add_theme_color_override("font_hover_color", Color(0.6, 0.6, 0.6, 0.8))

		btn.pressed.connect(_on_tab_pressed.bind(commander_id))
		tabs_container.add_child(btn)
		tab_buttons[commander_id] = btn

func _on_tab_pressed(commander_id: String) -> void:
	_select_commander(commander_id)

func _select_commander(commander_id: String) -> void:
	current_commander_id = commander_id
	var data = COMMANDERS[commander_id]
	var type_data = COMMANDER_TYPES[data.type]

	# Update tab button states
	for cmd_id in tab_buttons:
		tab_buttons[cmd_id].button_pressed = (cmd_id == commander_id)

	# Update info panel
	name_label.text = data.name
	type_label.text = type_data.name
	type_label.tooltip_text = type_data.tooltip
	position_label.text = data.position

	# Biography - show mystery text if locked
	if data.is_locked:
		biography_label.text = "[i]This commander's history remains shrouded in mystery. Complete previous campaigns to unlock.[/i]"
	else:
		biography_label.text = data.backstory

	# Bonuses
	var bonuses_text = "[b]Commander Bonuses[/b]\n"
	for bonus in type_data.bonuses:
		bonuses_text += bonus + "\n"
	bonuses_label.text = bonuses_text.strip_edges()

	# Portrait
	var portrait_path = data.portrait_path
	if portrait_path != "" and ResourceLoader.exists(portrait_path):
		portrait.texture = load(portrait_path)
	else:
		portrait.texture = null

	# Update select button
	if data.is_locked:
		select_button.text = "Locked"
		select_button.disabled = true
	else:
		select_button.text = "Select"
		select_button.disabled = false

func _on_select_pressed() -> void:
	if is_transitioning:
		return

	var data = COMMANDERS[current_commander_id]
	if data.is_locked:
		return

	is_transitioning = true
	print("Commander selected: ", current_commander_id)
	GameManager.set_commander(current_commander_id, data)

	var tween = create_tween()
	tween.tween_property(fade_rect, "color:a", 1.0, 0.5)
	tween.tween_callback(func():
		# TODO: Load game scene
		print("Starting game with commander: ", data.name)
		print("Campaign: ", GameManager.selected_campaign_id)
	)

func _on_back_pressed() -> void:
	if is_transitioning:
		return
	is_transitioning = true

	var tween = create_tween()
	tween.tween_property(fade_rect, "color:a", 1.0, 0.3)
	tween.tween_callback(func():
		get_tree().change_scene_to_file("res://scenes/campaign_selection/campaign_selection.tscn")
	)
