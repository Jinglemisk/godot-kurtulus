  # Battle Scene Prototype - Implementation Plan                                                        
                                                                                                      
> **Final Location:** Copy this plan to                                                               
`/Users/jinglemisk/Desktop/GODOT/kurtulus/battle-scene-plan.md`                                       
                                                                                                      
---                                                                                                   
                                                                                                      
## Context Files to Read First                                                                        
                                                                                                      
Before implementing, read these files to understand project patterns and specifications:              
                                                                                                      
### Project Structure & Patterns                                                                      
| File | Purpose |                                                                                    
|------|---------|                                                                                    
| `project.godot` | Config, autoloads, display settings - need to add input actions here |            
| `scripts/autoload/game_manager.gd` | Stores selected campaign/commander data |                      
| `scripts/autoload/audio_manager.gd` | Music playback patterns (play_music, crossfade_to) |          
                                                                                                      
### Existing Scene Patterns (reference for consistency)                                               
| File | Purpose |                                                                                    
|------|---------|                                                                                    
| `scenes/main_menu/main_menu.tscn` | CanvasLayer structure, transition pattern, styling |            
| `scenes/main_menu/main_menu.gd` | Fade animation pattern, tween usage |                             
| `scenes/commander_selection/commander_selection.gd` | **Line 235 has TODO** - wire battle scene     
here |                                                                                                
| `scenes/commander_selection/commander_selection.tscn` | UI patterns, color palette reference |      
                                                                                                      
### Design Specifications                                                                             
| File | Purpose |                                                                                    
|------|---------|                                                                                    
| `docs/gameplay.md` | Prototype spec - formation offsets, controls, camera behavior |                
| `docs/unit-sprites.md` | Sprite requirements, animation frame counts, asset status |                
                                                                                                      
### Sprite Assets                                                                                     
| Path | Contents |                                                                                   
|------|----------|                                                                                   
| `assets/sprites/ataturk/` | Commander: 4 poses + walk (3) + attack (3) |                            
| `assets/sprites/infantry/` | Soldiers: 4 poses + walk (4×4) + attack (4×4) |                        
| `assets/sprites/world/` | Environment: tree.png, house.png, oxcart.png |                            
                                                                                                      
### Key Patterns to Follow                                                                            
- **CanvasLayers**: -1 (background), 1 (UI), 10 (transitions)                                         
- **Transitions**: FadeRect with tween 0.5s in, 0.3s out                                              
- **Color palette**: Gold `#D4AF37`, cream text, dark backgrounds                                     
- **Font**: `alfabet98.ttf`                                                                           
- **Tweens**: Use `create_tween()` with EASE_OUT, TRANS_QUAD                                          
                                                                                                      
---                                                                                                   
                                                                                                      
## Overview

Build a minimal prototype battle scene with **Kessen 3-style trailing third-person camera**:
- Player unit (commander + 10 soldiers in wedge formation)
- **3D scene with billboarded 2D sprites** (pseudo-3D approach)
- Camera positioned **behind and above** commander, looking down at ~30° angle
- Commander visible in **lower-center of screen** (like Kessen 3)
- WASD movement in world space, camera follows behind
- Q/E rotates camera orbit around commander
- Space to attack (animation cascade)
- Static enemy unit with red tint

### Kessen 3 Camera Reference
The camera should feel like you're following the commander from behind:
```
        [Enemy in distance]
              ↑
    [Squad members trailing]
         [Commander] ← visible in lower screen
              |
           CAMERA (behind/above, looking down ~30°)
```

---

## Phases

Break the implementation into 7 incremental phases. Each phase produces a testable result.

### Phase 1: 3D Scene Foundation ✓ COMPLETE
**Goal:** Empty battlefield with working camera controls

- [x] Create `scenes/battle/battle_scene.tscn` with Node3D root
- [x] Add WorldEnvironment (procedural sky, ambient light)
- [x] Add DirectionalLight3D (sun with shadows)
- [x] Add Ground (PlaneMesh 100×100 with terrain shader for grass/dirt variation)
- [x] Add CameraPivot (Node3D) + Camera3D child
- [x] Implement Q/E camera orbit in `battle_scene.gd`
- [x] Add UI CanvasLayer with FadeRect
- [x] Add world objects (8 trees, 1 house, 1 oxcart as billboarded Sprite3D)
- [x] Add boundary markers (4 corner posts)
- [x] Add controls HUD overlay

**Test:** Run scene directly, Q/E rotates camera around empty field.

---

### Phase 2: Commander Movement ✓ COMPLETE
**Goal:** Single controllable character with camera follow

- [x] Create `scenes/battle/components/commander.tscn` (CharacterBody3D + Sprite3D)
- [x] Set Sprite3D billboard mode, pixel filtering, load `ataturk-front-rdy.png`
- [x] Implement WASD movement in `commander.gd` relative to camera basis
- [x] Camera pivot follows commander position with lerp smoothing
- [x] Add input actions to `project.godot` (already configured in Phase 1)

**Enhancements Added:**
- [x] **Momentum physics**: Acceleration (20 units/s²), deceleration (15 units/s²), turn penalty (40% speed on direction change)
- [x] **Directional sprites**: Front, back, side, and three-quarter view based on movement direction
- [x] **Boundary constraints**: Commander cannot leave arena (48-unit boundary inside posts)
- [x] **Ground shadow**: Circular shader-based shadow with radial falloff
- [x] **Dust particles**: GPUParticles3D emitted when moving at >30% speed

**Test:** WASD moves commander with momentum, camera follows, Q/E orbits around commander. Sprite changes direction based on movement. Shadow and dust effects visible.

---

### Phase 3: Squad Formation ✓ COMPLETE
**Goal:** 10 soldiers following commander in 5×2 rectangle formation

- [x] Create `scenes/battle/components/soldier.tscn` (CharacterBody3D + Sprite3D)
- [x] Load `infantry/front-rdy.png`, set billboard mode
- [x] Implement formation follow in `soldier.gd` with offset rotation
- [x] Create `scenes/battle/components/unit.tscn` (Node3D container)
- [x] `unit.gd` spawns 10 soldiers with 5×2 rectangle formation:
  ```
  Commander at front (center)
  Row 1: (-3, 0, -2.5), (-1.5, 0, -2.5), (0, 0, -2.5), (1.5, 0, -2.5), (3, 0, -2.5)
  Row 2: (-3, 0, -4.0), (-1.5, 0, -4.0), (0, 0, -4.0), (1.5, 0, -4.0), (3, 0, -4.0)
  ```

**Enhancements Added:**
- [x] **Dust particles**: Soldiers emit dust when moving (14 particles, 0.7s lifetime)
- [x] **Ground shadows**: Circular shader-based shadow per soldier
- [x] **Organic offset**: ±0.3 unit random offset per soldier, changes every 2s
- [x] **Crowding behavior**: Smooth target interpolation - back row lags naturally
  - Row 1: target_lerp_speed 5.0-6.0, follow_speed 0.85-1.0
  - Row 2: target_lerp_speed 4.0-5.0, follow_speed 0.7-0.85
- [x] **Directional sprites**: Front, back, side based on movement direction
- [x] **Idle formation tightening**: Formation scales to 70% when stopped, soldiers cluster closer
- [x] **Look-at-commander when idle**: After 1s stationary, soldiers face toward commander
- [x] **Soft collision avoidance**: Soldiers push apart if closer than 1.2 units (prevents stacking)

**Test:** Move commander, 10 soldiers follow in rectangle. Formation rotates with movement. Back row lags during turns. Stop moving - soldiers cluster and turn to face commander. Sharp turns - soldiers don't stack.

---

### Phase 4: Animations & Combat ✓ COMPLETE
**Goal:** Walk/attack animations with cascade effect

- [x] Commander: Walk animation (3 frames at 8 FPS) for left/right movement
- [x] Commander: Directional idle sprites for forward/back movement
- [x] Commander: Attack animation (3 frames at 10 FPS) on Space key
- [x] Commander: `attack_started` signal for cascade trigger
- [x] Soldier: Directional walk animations (4 directions × 4 frames at 8 FPS)
- [x] Soldier: Directional attack animations (4 directions × 4 frames at 10 FPS)
- [x] `unit.gd`: Attack cascade with 50ms stagger per soldier
- [x] Return to idle sprite when stationary

**Enhancements Added:**
- [x] Attack impact particles (dust burst at attack position)
- [x] Attack cooldown (1 second) to prevent spam

**Test:** WASD shows walk animation (left/right) or directional sprites (forward/back). Space triggers attack cascade through squad with particles and cooldown.

---

### Phase 5: Enemy Unit & Health System ✓ COMPLETE
**Goal:** Add enemy unit with troop-based health, attack range detection, and damage system

**Enemy Unit Setup:**
- [x] Add EnemyUnit (duplicate of unit.tscn, red modulate, rotated 180°, at z=-20)
- [x] Apply red tint via `_apply_tint_recursive()` to all Sprite3D nodes
- [x] Enemy is static (no AI - just visual presence with health)

**Audio Integration:**
- [x] Use `AudioManager.crossfade_to()` for music transition in `_ready()`
- [x] Load `battle-music.mp3` via preload

**Troop-Based Health System:**
- [x] Add `troop_count` property to `unit.gd` (represents total men, e.g., 2000)
- [x] Add `MAX_TROOP_COUNT` constant (2000)
- [x] Add `take_damage(amount: int)` method to `unit.gd`
- [x] Add `troop_count_changed` signal emitted when troops change
- [x] Add `unit_defeated` signal emitted when troop_count reaches 0

**Soldier Visibility (Troop Representation):**
- [x] 10 visible soldiers represent the total troop count proportionally
- [x] Each soldier represents `MAX_TROOP_COUNT / 10` = 200 troops
- [x] As `troop_count` decreases, soldiers disappear (back row first)
- [x] `_update_visible_soldiers()` hides soldiers based on remaining troops
- [x] No death animation yet - soldiers just become invisible

**Attack Range Detection:**
- [x] Add `ATTACK_RANGE` constant to `battle_scene.gd` (12.0 units)
- [x] Check distance between player unit and enemy unit on attack
- [x] Only deal damage when within range
- [x] Print debug messages for hit/miss feedback

**Damage Dealing:**
- [x] Connect commander's `attack_started` signal to `_on_player_attack()`
- [x] `DAMAGE_PER_ATTACK` = 250 (8 attacks to defeat enemy with 2000 troops)
- [x] Connect to enemy's `unit_defeated` signal for victory trigger

**Test:**
1. Move player unit toward enemy (WASD)
2. When close (within 12 units), press Space to attack
3. Console shows "Attack hit! Enemy troops: X/2000"
4. Enemy soldiers disappear as troops decrease (back row first)
5. After 8 attacks, enemy troop_count reaches 0
6. Commander disappears, victory popup appears

---

### Phase 6: Victory Condition & Game Loop ✓ COMPLETE
**Goal:** Victory popup when enemy defeated, restart/menu options

**Victory Detection:**
- [x] In `battle_scene.gd`, connect to enemy unit's `unit_defeated` signal
- [x] When enemy HP reaches 0, trigger victory sequence

**Victory Sequence:**
- [x] Freeze player input (disable movement and attack via `input_enabled` flag)
- [x] Show victory popup after 0.5s delay

**Victory Popup UI:**
- [x] Create `VictoryPopup` (CenterContainer in UI CanvasLayer)
- [x] Panel with gold border (`StyleBoxFlat_victory` with #D4AF37 border)
- [x] "VICTORY!" title in large alfabet98 font (48px, gold)
- [x] "Enemy Defeated" subtitle (24px, cream)
- [x] Two buttons: "Play Again" and "Main Menu"

**Button Actions:**
- [x] "Play Again": Reload battle scene (`get_tree().reload_current_scene()`)
- [x] "Main Menu": Fade out transition to main menu

**Popup Animation:**
- [x] Scale from 0 to 1 with bounce (EASE_OUT, TRANS_BACK, 0.4s)
- [x] Fade in alpha (0.3s)

**Scene Structure Addition:**
```
UI (CanvasLayer)
├── ControlsHUD
├── TransitionLayer
│   └── FadeRect
└── VictoryPopup (CenterContainer, initially hidden)
    └── Panel (StyleBoxFlat with gold border)
        └── VBox
            ├── Title (Label - "VICTORY!")
            ├── Subtitle (Label - "Enemy Defeated")
            └── Buttons (HBoxContainer)
                ├── PlayAgainButton
                └── MainMenuButton
```

**Test:** Full victory flow:
1. Main Menu → Campaign → Commander → Battle
2. Move to enemy, attack 8 times (250 damage each, 2000 total HP)
3. Enemy soldiers disappear as HP drops, commander disappears at 0
4. Victory popup scales in with bounce animation
5. "Play Again" restarts battle
6. "Main Menu" fades out and returns to main menu

---

### Phase 7: STITCHING UP
**Goal:** Implement death animations for units

**Death Animation:**
- [ ] Create death animation sequence for soldiers and commander
- [ ] Retrofit death animation to dying units (currently sprites just disappear)
- [ ] Add death animation trigger when unit health reaches 0
- [ ] Ensure smooth transition from current state to death animation
- [ ] Optional: Add death particles/effects for visual feedback

**Test:** When a unit dies, it plays the death animation instead of instantly disappearing.

---

### Phase 5 & 6 Files Summary

| File | Changes |
|------|---------|
| `scenes/battle/battle_scene.tscn` | EnemyUnit ✓, VictoryPopup UI ✓, StyleBoxFlat_victory ✓ |
| `scenes/battle/battle_scene.gd` | Attack range ✓, damage routing ✓, victory popup ✓, button handlers ✓ |
| `scenes/battle/components/unit.tscn` | (no changes) |
| `scenes/battle/components/unit.gd` | troop_count ✓, take_damage() ✓, signals ✓, soldier visibility ✓, commander death ✓ |

---

### Troop-Based Health System Code Reference

**unit.gd additions:**
```gdscript
signal troop_count_changed(current: int, maximum: int)
signal unit_defeated

const MAX_TROOP_COUNT: int = 2000  # Total men in unit
var troop_count: int = MAX_TROOP_COUNT

func take_damage(amount: int) -> void:
    troop_count = maxi(troop_count - amount, 0)
    troop_count_changed.emit(troop_count, MAX_TROOP_COUNT)
    _update_visible_soldiers()
    if troop_count <= 0:
        unit_defeated.emit()

func _update_visible_soldiers() -> void:
    # Each of 10 soldiers represents 200 troops
    # Hide from back row first as troops decrease
    var soldiers := squad.get_children()
    var troops_per_soldier := MAX_TROOP_COUNT / soldiers.size()
    var soldiers_alive := ceili(float(troop_count) / float(troops_per_soldier))
    for i in range(soldiers.size()):
        var reverse_index := soldiers.size() - 1 - i
        soldiers[reverse_index].visible = (reverse_index < soldiers_alive)
```

**battle_scene.gd damage routing:**
```gdscript
const ATTACK_RANGE: float = 12.0  # Units must be this close to hit
const DAMAGE_PER_ATTACK: int = 250  # 8 attacks to defeat (2000 / 250 = 8)

var input_enabled: bool = true

func _ready() -> void:
    # ... existing code ...
    commander.attack_started.connect(_on_player_attack)
    enemy_unit.unit_defeated.connect(_on_enemy_defeated)

func _on_player_attack() -> void:
    if not input_enabled:
        return
    if _is_in_attack_range():
        enemy_unit.take_damage(DAMAGE_PER_ATTACK)

func _on_enemy_defeated() -> void:
    print("VICTORY!")
    input_enabled = false
    # TODO Phase 6: Show victory popup
```

---

## Files to Create

```
scenes/battle/
├── battle_scene.tscn        # Main 3D scene with camera, lighting, ground ✓
├── battle_scene.gd          # Camera orbit, input routing, camera follow ✓
└── components/
    ├── unit.tscn            # Commander + squad container (Node3D)
    ├── unit.gd              # Formation setup, attack cascade
    ├── commander.tscn       # CharacterBody3D with Sprite3D, shadow, dust ✓
    ├── commander.gd         # Momentum movement, directional sprites ✓
    ├── soldier.tscn         # CharacterBody3D with Sprite3D (billboard)
    └── soldier.gd           # Formation follow behavior

assets/shaders/
├── ground_terrain.gdshader  # Terrain shader with grass/dirt noise blending ✓
└── circular_shadow.gdshader # Radial falloff shadow for commander ✓
```                                                                                                   
                                                                                                      
---                                                                                                   
                                                                                                      
## Assets to Create/Add

1. ~~**assets/sprites/world/grass-ground.png**~~ - Using existing `grass-ground-rdy.png` with terrain shader
2. **assets/battle-music.mp3** - User will provide (placeholder reference in scene)

### Terrain Shader (`ground_terrain.gdshader`)
Uses procedural noise to blend between original dirt texture and green-tinted grass:
- `grass_tint`: Green color applied to grass areas (default: 0.4, 0.6, 0.3)
- `noise_scale`: Size of grass/dirt patches (default: 2.0)
- `grass_threshold`: Balance of grass vs dirt (default: 0.5)
- `blend_softness`: Smoothness of transitions (default: 0.1)

### Circular Shadow Shader (`circular_shadow.gdshader`)
Spatial shader for commander ground shadow with radial falloff:
- `shadow_color`: Color with alpha (default: black at 0.4 alpha)
- `falloff`: Controls edge softness (default: 1.5, range 0.1-3.0)
- Render mode: `unshaded, cull_disabled, depth_draw_never, shadows_disabled`
- Discards pixels outside unit circle for clean circular shape

### Dust Particles (GPUParticles3D)
Commander emits dust when moving at >30% max speed:
- Amount: 12 particles
- Lifetime: 0.6 seconds
- Direction: Upward with gravity pulling down
- Color: Tan/brown (0.6, 0.5, 0.35) with transparency
- Mesh: Small boxes (0.15 units)                   
                                                                                                      
## Files to Modify                                                                                    
                                                                                                      
1. **project.godot** - Add input actions:                                                             
- `move_forward`: W, Up                                                                               
- `move_backward`: S, Down                                                                            
- `move_left`: A, Left                                                                                
- `move_right`: D, Right                                                                              
- `camera_left`: Q                                                                                    
- `camera_right`: E                                                                                   
- `attack`: Space, LMB                                                                                
                                                                                                      
2. **scenes/commander_selection/commander_selection.gd** (line 235) - Wire scene transition:          
```gdscript                                                                                           
get_tree().change_scene_to_file("res://scenes/battle/battle_scene.tscn")                              
```                                                                                                   
                                                                                                      
---                                                                                                   
                                                                                                      
## Scene Hierarchy (3D with Billboarded Sprites)

### battle_scene.tscn (Phase 4 - Current)
```
BattleScene (Node3D)
├── Environment (WorldEnvironment)
│   └── ProceduralSky + ambient light settings
├── Sun (DirectionalLight3D - casting shadows)
├── Ground (MeshInstance3D - PlaneMesh 100×100 with terrain shader)
├── WorldObjects (Node3D)
│   ├── Tree_0..7 (Sprite3D × 8, billboard, pixel_size=0.01)
│   ├── House_0 (Sprite3D, billboard, pixel_size=0.008)
│   └── Oxcart_0 (Sprite3D, billboard, pixel_size=0.006)
├── Boundaries (Node3D)
│   └── Post_NW, Post_NE, Post_SW, Post_SE (CylinderMesh corner markers)
├── Unit (unit.tscn - player squad)
│   ├── Commander (commander.tscn)
│   └── Squad (10 soldiers in 5×2 formation)
├── CameraPivot (Node3D) - follows commander position
│   └── Camera3D (offset: 0, 8, 12 - looking down ~30°)
└── UI (CanvasLayer)
    ├── ControlsHUD (MarginContainer - bottom-left)
    └── TransitionLayer (CanvasLayer layer=10)
        └── FadeRect (for transitions)
```

### battle_scene.tscn (Phase 5 - Future)
```
BattleScene (Node3D)
├── ... (Phase 4 structure above)
├── EnemyUnit (unit.tscn at z=-20, red modulate, rotated 180°)
└── AudioStreamPlayer (battle-music.mp3, autoplay)
```

### unit.tscn
```
Unit (Node3D)
├── Commander (commander.tscn)
└── Squad (Node3D)
    └── Soldier_0..9 (soldier.tscn × 10, 5×2 rectangle formation)
```

### commander.tscn
```
Commander (CharacterBody3D)
├── Sprite3D (billboard, pixel_size=0.004, walk/attack animations)
├── Shadow (MeshInstance3D - QuadMesh with circular_shadow shader)
├── DustParticles (GPUParticles3D - tan/brown dust when moving)
└── AttackParticles (GPUParticles3D - burst on attack, one-shot)
```

### soldier.tscn
```
Soldier (CharacterBody3D)
├── Sprite3D (billboard, pixel_size=0.003, directional walk/attack)
├── Shadow (MeshInstance3D - QuadMesh with circular_shadow shader)
├── DustParticles (GPUParticles3D - dust when moving)
└── AttackParticles (GPUParticles3D - burst on attack, one-shot)
```

### Camera Setup (Kessen 3 Style)
```
CameraPivot (Node3D) - position follows commander
│   - Rotates around Y axis with Q/E input
└── Camera3D
    - local position: Vector3(0, 8, 12)  # 8 units up, 12 units back
    - rotation: looking at origin (-30° pitch approximately)
    - FOV: 60°
```                                                                                                   
                                                                                                      
---                                                                                                   
                                                                                                      
## Core Logic (3D Implementation)

### Movement (commander.gd) - Implemented
```gdscript
# Constants for momentum physics
const MAX_SPEED: float = 10.0
const ACCELERATION: float = 20.0       # Units/sec² - reaches max in 0.5s
const DECELERATION: float = 15.0       # Units/sec² - stops in ~0.67s
const TURN_PENALTY: float = 0.4        # Speed multiplier when changing direction
const TURN_THRESHOLD: float = 0.7      # Dot product threshold for "turning"
const ARENA_BOUND: float = 48.0        # Boundary constraint

# Get WASD input as Vector2
var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")

# Convert to 3D direction relative to camera facing
var camera_basis = camera_pivot.global_transform.basis
var desired_dir = (camera_basis.z * input_dir.y + camera_basis.x * input_dir.x)
desired_dir.y = 0
desired_dir = desired_dir.normalized()

# Apply momentum physics (acceleration, deceleration, turn penalty)
if desired_dir.length_squared() > 0.01:
    if current_speed > 0.1 and current_direction.dot(desired_dir) < TURN_THRESHOLD:
        current_speed *= TURN_PENALTY  # Slow down when turning
    current_direction = desired_dir
    current_speed = minf(current_speed + ACCELERATION * delta, MAX_SPEED)
    update_sprite_facing(input_dir)  # Change sprite based on direction
else:
    current_speed = maxf(current_speed - DECELERATION * delta, 0.0)

velocity = current_direction * current_speed
move_and_slide()

# Enforce boundary constraints
global_position.x = clampf(global_position.x, -ARENA_BOUND, ARENA_BOUND)
global_position.z = clampf(global_position.z, -ARENA_BOUND, ARENA_BOUND)
```

### Directional Sprites (commander.gd) - Implemented
```gdscript
# Preloaded directional textures (6 sprites, mirrored for 8 directions)
var tex_front: Texture2D = preload("res://assets/sprites/ataturk/ataturk-front-rdy.png")
var tex_back: Texture2D = preload("res://assets/sprites/ataturk/ataturk-back-rdy.png")
var tex_side: Texture2D = preload("res://assets/sprites/ataturk/ataturk-side-left-rdy.png")
var tex_three_quarter: Texture2D = preload("res://assets/sprites/ataturk/ataturk-three-quarter-rdy.png")
var tex_three_quarter_back: Texture2D = preload("res://assets/sprites/ataturk/ataturk-three-quarter-back-rdy.png")

func update_sprite_facing(input_dir: Vector2) -> void:
    var abs_x := absf(input_dir.x)
    var abs_y := absf(input_dir.y)
    var is_diagonal := abs_x > 0.5 and abs_y > 0.5

    if is_diagonal:
        if input_dir.y < 0:  # Forward diagonal (W+A/W+D) - show back 3/4
            sprite.texture = tex_three_quarter_back
            sprite.flip_h = input_dir.x < 0  # Flip for left
        else:  # Backward diagonal (S+A/S+D) - show front 3/4
            sprite.texture = tex_three_quarter
            sprite.flip_h = input_dir.x > 0  # Flip for right
    elif abs_y > abs_x:  # Primarily forward/backward
        sprite.texture = tex_back if input_dir.y < 0 else tex_front
    else:  # Primarily left/right
        sprite.texture = tex_side
        sprite.flip_h = input_dir.x > 0
```

### 8-Direction Sprite Mapping
| Input | Direction | Sprite | Mirrored |
|-------|-----------|--------|----------|
| W | forward | back | no |
| S | backward | front | no |
| A | left | side-left | no |
| D | right | side-left | yes |
| W+A | forward-left | 3/4 back | yes |
| W+D | forward-right | 3/4 back | no |
| S+A | backward-left | 3/4 front | no |
| S+D | backward-right | 3/4 front | yes |

### Camera (battle_scene.gd) - Implemented
```gdscript
@onready var camera_pivot: Node3D = $CameraPivot
@onready var commander: CharacterBody3D = $Commander

const CAMERA_ROTATION_SPEED = 2.0  # rad/sec
const CAMERA_FOLLOW_SPEED = 8.0

func _ready() -> void:
    commander.camera_pivot = camera_pivot  # Wire camera reference

func _process(delta):
    # Smooth follow commander position
    var target_pos = commander.global_position
    camera_pivot.global_position = camera_pivot.global_position.lerp(
        target_pos, delta * CAMERA_FOLLOW_SPEED
    )

    # Rotate camera orbit with Q/E
    if Input.is_action_pressed("camera_left"):
        camera_pivot.rotate_y(CAMERA_ROTATION_SPEED * delta)
    if Input.is_action_pressed("camera_right"):
        camera_pivot.rotate_y(-CAMERA_ROTATION_SPEED * delta)
```

### Formation (soldier.gd)
```gdscript
# Each soldier has a fixed offset (wedge shape behind commander)
var formation_offset: Vector3  # e.g., Vector3(-2, 0, 3) = left-back

func _process(delta):
    # Rotate offset based on commander's facing direction
    var rotated_offset = formation_offset.rotated(Vector3.UP, commander.rotation.y)
    var target_pos = commander.global_position + rotated_offset

    # Smooth follow
    global_position = global_position.lerp(target_pos, delta * FOLLOW_SPEED)
```

### Sprite Billboard Setup
All character sprites use Sprite3D with billboard mode:
```gdscript
# In _ready() or set in editor
sprite_3d.billboard = BaseMaterial3D.BILLBOARD_ENABLED
sprite_3d.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST  # Pixel art
sprite_3d.no_depth_test = false  # Proper depth sorting
```                                                                 
                                                                                                      
### Attack Cascade (unit.gd)                                                                          
- Commander plays attack animation                                                                    
- Soldiers trigger attack with 50ms stagger each                                                      
                                                                                                      
---                                                                                                   
                                                                                                      
## Sprite Animations (AnimatedSprite2D + SpriteFrames)                                                
                                                                                                      
### Commander                                                                                         
| Animation | Frames | FPS | Loop |                                                                   
|-----------|--------|-----|------|                                                                   
| idle | ataturk-front.png | - | Yes |                                                                
| walk | walk-1,2,3.png | 8 | Yes |                                                                   
| attack | attack-1,2,3.png | 10 | No |                                                               
                                                                                                      
### Soldier                                                                                           
| Animation | Frames | FPS | Loop |                                                                   
|-----------|--------|-----|------|                                                                   
| idle | infantry/front.png | - | Yes |                                                               
| walk | walk/front/frame1-4.png | 8 | Yes |                                                          
| attack | attack/front/frame1-4.png | 10 | No |                                                      
                                                                                                      
---                                                                                                   
                                                                                                      
## Enemy Unit                                                                                         
- Same structure as player unit                                                                       
- Apply `modulate = Color(1.0, 0.5, 0.5)` for red tint                                                
- Rotate 180° to face player                                                                          
- No AI (static for prototype)                                                                        
                                                                                                      
---                                                                                                   
                                                                                                      
## Implementation Order                                                                               
                                                                                                      
1. **Setup**: Create folders, add input map to project.godot                                          
2. **Ground**: Generate grass/dirt texture, set up tiled background                                   
3. **World Objects**: Place trees, house, oxcart around arena                                         
4. **Commander**: Create scene with sprite, write movement script                                     
5. **Camera**: Add to battle_scene, implement follow + rotation                                       
6. **Soldiers**: Create scene, write formation follow logic                                           
7. **Unit**: Combine commander + 10 soldiers, assign offsets                                          
8. **Animations**: Set up SpriteFrames, wire idle/walk/attack                                         
9. **Enemy**: Duplicate unit with red modulate                                                        
10. **Audio**: Add AudioStreamPlayer for battle-music.mp3                                             
11. **Integration**: Wire commander_selection.gd to load scene                                        
12. **Test**: Full flow Main Menu → Campaign → Commander → Battle                                     
                                                                                                      
---                                                                                                   
                                                                                                      
## Verification                                                                                       
                                                                                                      
1. Run project, select any campaign and commander                                                     
2. Battle scene loads with fade-in                                                                    
3. WASD moves unit (soldiers follow in formation)                                                     
4. Q/E rotates camera view                                                                            
5. Movement stays relative to camera angle                                                            
6. Space triggers attack animation cascade                                                            
7. Enemy unit visible with red tint across arena