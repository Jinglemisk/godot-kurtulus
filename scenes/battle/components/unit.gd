extends Node3D

## Unit - Container for commander + squad of soldiers
## Manages formation setup and provides external access to commander
## Assigns crowding behavior (variable speeds/delays) for natural movement
## Phase 4: Attack cascade with 50ms stagger per soldier
## Phase 5: Troop-based health system - soldiers disappear as HP drops

# Signals for health system
signal troop_count_changed(current: int, maximum: int)
signal unit_defeated

# Troop count (HP) - represents total men in unit (e.g., 2000 men)
# Visible soldiers are proportional representation of this count
const MAX_TROOP_COUNT: int = 2000
var troop_count: int = MAX_TROOP_COUNT

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

# Attack cascade settings
const ATTACK_STAGGER_MS: float = 50.0  # 50ms between each soldier

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
	# Connect to commander's attack signal for cascade
	commander.attack_started.connect(_on_commander_attack)

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


func _on_commander_attack() -> void:
	# Trigger attack cascade: each soldier attacks with 50ms stagger
	# Only trigger for visible (alive) soldiers
	var soldiers := squad.get_children()
	for i in range(soldiers.size()):
		var soldier = soldiers[i]
		if not soldier.visible:
			continue  # Skip dead soldiers
		var delay_sec: float = (i + 1) * ATTACK_STAGGER_MS / 1000.0
		# Use tween for precise timing
		var tween := create_tween()
		tween.tween_callback(soldier.trigger_attack).set_delay(delay_sec)


## Take damage and update visible soldiers accordingly
## Each soldier represents MAX_TROOP_COUNT / num_soldiers troops
func take_damage(amount: int) -> void:
	troop_count = maxi(troop_count - amount, 0)
	troop_count_changed.emit(troop_count, MAX_TROOP_COUNT)
	_update_visible_soldiers()

	if troop_count <= 0:
		# Hide commander when unit is fully defeated
		commander.visible = false
		unit_defeated.emit()


## Update which soldiers are visible based on current troop count
## Soldiers disappear from back row first (indices 9, 8, 7... down to 0)
func _update_visible_soldiers() -> void:
	var soldiers := squad.get_children()
	var num_soldiers := soldiers.size()
	if num_soldiers == 0:
		return

	# Calculate how many soldiers should be visible
	# Each soldier represents an equal portion of total troops
	var troops_per_soldier := MAX_TROOP_COUNT / num_soldiers
	var soldiers_alive := ceili(float(troop_count) / float(troops_per_soldier))
	soldiers_alive = clampi(soldiers_alive, 0, num_soldiers)

	# Hide soldiers from the back (higher indices first)
	for i in range(num_soldiers):
		var reverse_index := num_soldiers - 1 - i
		soldiers[reverse_index].visible = (reverse_index < soldiers_alive)


## Get the number of currently visible (alive) soldiers
func get_alive_soldier_count() -> int:
	var count := 0
	for soldier in squad.get_children():
		if soldier.visible:
			count += 1
	return count


## Check if unit is defeated
func is_defeated() -> bool:
	return troop_count <= 0
