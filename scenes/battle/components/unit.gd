extends Node3D

## Unit - Container for commander + squad of soldiers
## Manages formation setup and provides external access to commander
## Assigns crowding behavior (variable speeds/delays) for natural movement

# 5x2 rectangle formation: 2 rows of 5 soldiers behind commander
# Row 1 at z=-2.5, Row 2 at z=-4.0 (negative Z = behind when facing forward)
# X positions: -3, -1.5, 0, +1.5, +3 (1.5 unit spacing, centered)
const FORMATION_OFFSETS: Array[Vector3] = [
	# Row 1 (closest to commander) - indices 0-4
	Vector3(-3.0, 0.0, -2.5),
	Vector3(-1.5, 0.0, -2.5),
	Vector3(0.0, 0.0, -2.5),
	Vector3(1.5, 0.0, -2.5),
	Vector3(3.0, 0.0, -2.5),
	# Row 2 (further back) - indices 5-9
	Vector3(-3.0, 0.0, -4.0),
	Vector3(-1.5, 0.0, -4.0),
	Vector3(0.0, 0.0, -4.0),
	Vector3(1.5, 0.0, -4.0),
	Vector3(3.0, 0.0, -4.0),
]

# Crowding behavior settings per row
const ROW_1_SPEED_MIN: float = 0.85
const ROW_1_SPEED_MAX: float = 1.0
const ROW_1_DELAY: float = 0.15

const ROW_2_SPEED_MIN: float = 0.7
const ROW_2_SPEED_MAX: float = 0.85
const ROW_2_DELAY: float = 0.3

# Node references
@onready var commander: CharacterBody3D = $Commander
@onready var squad: Node3D = $Squad

# Set by battle_scene.gd - passed to commander
var camera_pivot: Node3D = null:
	set(value):
		camera_pivot = value
		if commander:
			commander.camera_pivot = value


func _ready() -> void:
	# Wire up each soldier with their formation offset, commander reference, and crowding settings
	var soldiers := squad.get_children()
	for i in range(mini(soldiers.size(), FORMATION_OFFSETS.size())):
		var soldier = soldiers[i]
		soldier.formation_offset = FORMATION_OFFSETS[i]
		soldier.commander = commander

		# Assign crowding behavior based on row
		if i < 5:
			# Row 1 (front row) - faster reaction, no delay
			soldier.follow_speed_multiplier = randf_range(ROW_1_SPEED_MIN, ROW_1_SPEED_MAX)
			soldier.reaction_delay = ROW_1_DELAY
		else:
			# Row 2 (back row) - slower reaction, slight delay
			soldier.follow_speed_multiplier = randf_range(ROW_2_SPEED_MIN, ROW_2_SPEED_MAX)
			soldier.reaction_delay = ROW_2_DELAY

		# Start soldiers at their formation position
		var initial_pos: Vector3 = commander.global_position + FORMATION_OFFSETS[i]
		soldier.global_position = initial_pos
