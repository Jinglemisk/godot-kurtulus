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
const ROW_1_TARGET_LERP: float = 6.0  # Faster target tracking (front row)

const ROW_2_SPEED_MIN: float = 0.7
const ROW_2_SPEED_MAX: float = 0.85
const ROW_2_TARGET_LERP: float = 5.0  # Slower target tracking (back row)

# Node references
@onready var commander: CharacterBody3D = $Commander
@onready var squad: Node3D = $Squad

# Formation scale for idle tightening
var formation_scale: float = 1.0
const FORMATION_SCALE_IDLE: float = 0.7  # Tighter when stopped
const FORMATION_SCALE_MOVING: float = 1.0
const FORMATION_SCALE_LERP: float = 2.0  # Transition speed

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
		soldier.unit = self  # For formation_scale access
		soldier.squad_members = soldiers  # For collision avoidance
		soldier.my_index = i

		# Assign crowding behavior based on row
		if i < 5:
			# Row 1 (front row) - faster target tracking
			soldier.follow_speed_multiplier = randf_range(ROW_1_SPEED_MIN, ROW_1_SPEED_MAX)
			soldier.target_lerp_speed = randf_range(5.0, ROW_1_TARGET_LERP)
		else:
			# Row 2 (back row) - slower target tracking (more lag)
			soldier.follow_speed_multiplier = randf_range(ROW_2_SPEED_MIN, ROW_2_SPEED_MAX)
			soldier.target_lerp_speed = randf_range(4.0, ROW_2_TARGET_LERP)

		# Start soldiers at their formation position
		var initial_pos: Vector3 = commander.global_position + FORMATION_OFFSETS[i]
		soldier.global_position = initial_pos


func _process(delta: float) -> void:
	# Update formation scale based on commander movement (idle tightening)
	var is_moving: bool = commander.current_speed > 1.0
	var target_scale: float = FORMATION_SCALE_MOVING if is_moving else FORMATION_SCALE_IDLE
	formation_scale = lerpf(formation_scale, target_scale, delta * FORMATION_SCALE_LERP)
