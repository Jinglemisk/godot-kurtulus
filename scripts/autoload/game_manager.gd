extends Node

## GameManager - Stores game state across scenes

var selected_campaign_id: String = ""
var selected_campaign_data: Dictionary = {}
var selected_commander_id: String = ""
var selected_commander_data: Dictionary = {}

func set_campaign(id: String, data: Dictionary) -> void:
	selected_campaign_id = id
	selected_campaign_data = data

func set_commander(id: String, data: Dictionary) -> void:
	selected_commander_id = id
	selected_commander_data = data

func clear_selection() -> void:
	selected_campaign_id = ""
	selected_campaign_data = {}
	selected_commander_id = ""
	selected_commander_data = {}

func get_campaign_title() -> String:
	return selected_campaign_data.get("title", "")

func get_campaign_years() -> String:
	return selected_campaign_data.get("years", "")
