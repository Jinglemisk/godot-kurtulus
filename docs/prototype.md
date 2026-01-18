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

Break the implementation into 5 incremental phases. Each phase produces a testable result.

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

### Phase 3: Squad Formation
**Goal:** 10 soldiers following commander in an infantry block formation

- [ ] Create `scenes/battle/components/soldier.tscn` (CharacterBody3D + Sprite3D)
- [ ] Load `infantry/front-rdy.png`, set billboard mode
- [ ] Implement formation follow in `soldier.gd` with offset rotation
- [ ] Create `scenes/battle/components/unit.tscn` (Node3D container)
- [ ] `unit.gd` spawns 10 soldiers with wedge formation offsets:
  ```
  Row 1: (-1.5, 0, 2), (1.5, 0, 2)
  Row 2: (-3, 0, 4), (0, 0, 4), (3, 0, 4)
  Row 3: (-4.5, 0, 6), (-1.5, 0, 6), (1.5, 0, 6), (4.5, 0, 6)
  Row 4: (0, 0, 8)
  ```

**Test:** Move commander, 10 soldiers follow in wedge shape, formation rotates with movement direction.

---

### Phase 4: Animations & Combat
**Goal:** Walk/attack animations with cascade effect

- [ ] Commander: Load walk textures (`walk-1-rdy.png` to `walk-3-rdy.png`), cycle at 8 FPS while moving
- [ ] Commander: Load attack textures (`attack-1-rdy.png` to `attack-3-rdy.png`), play at 10 FPS on Space
- [ ] Soldier: Load walk textures (`walk/front/frame1-rdy.png` to `frame4-rdy.png`)
- [ ] Soldier: Load attack textures (`attack/front/frame1-rdy.png` to `frame4-rdy.png`)
- [ ] `unit.gd`: On commander attack, trigger soldiers with 50ms stagger
- [ ] Return to idle texture when stationary

**Test:** WASD shows walk animation, Space triggers attack cascade through squad.

---

### Phase 5: Polish & Integration
**Goal:** Complete battle scene with enemy and scene flow

- [ ] Add EnemyUnit (duplicate of unit.tscn, red modulate, rotated 180°, at z=-20)
- [x] ~~Add world objects: trees, house, oxcart (Sprite3D billboards)~~ (moved to Phase 1)
- [x] ~~Add grass texture to ground material~~ (terrain shader with grass/dirt noise)
- [x] ~~Wire `commander_selection.gd` line 235 to load battle scene~~ (done in Phase 1)
- [ ] Add AudioStreamPlayer for `battle-music.mp3`
- [ ] Use `AudioManager.crossfade_to()` for music transition
- [x] ~~Fade-in on scene ready~~ (done in Phase 1)

**Test:** Full flow: Main Menu → Campaign → Commander → Battle scene with both units, music, and working controls.

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

### battle_scene.tscn (Phase 2 - Current)
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
├── Commander (commander.tscn instance)
│   ├── Sprite3D (billboard, pixel_size=0.004, directional textures)
│   ├── Shadow (MeshInstance3D - QuadMesh with circular_shadow shader)
│   └── DustParticles (GPUParticles3D - tan/brown dust when moving)
├── CameraPivot (Node3D) - follows commander position
│   └── Camera3D (offset: 0, 8, 12 - looking down ~30°)
└── UI (CanvasLayer)
    ├── ControlsHUD (MarginContainer - bottom-left)
    │   └── VBoxContainer
    │       ├── ControlsLabel ("WASD - Move | Q/E - Rotate")
    │       └── PhaseLabel ("Phase 2: Movement")
    └── TransitionLayer (CanvasLayer layer=10)
        └── FadeRect (for transitions)
```

### battle_scene.tscn (Future Phases)
```
BattleScene (Node3D)
├── ... (Phase 1 structure above)
├── PlayerUnit (unit.tscn at Vector3(0, 0, 40))
├── EnemyUnit (unit.tscn at Vector3(0, 0, -40), modulate=red)
└── AudioStreamPlayer (battle-music.mp3, autoplay)
```

### unit.tscn
```
Unit (Node3D)
├── Commander (commander.tscn)
│   └── Sprite3D (billboard_mode = BILLBOARD_ENABLED)
└── Squad (Node3D)
    └── Soldier_0..9 (soldier.tscn × 10, each with Sprite3D billboard)
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