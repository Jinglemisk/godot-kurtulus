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

### Phase 1: 3D Scene Foundation
**Goal:** Empty battlefield with working camera controls

- [ ] Create `scenes/battle/battle_scene.tscn` with Node3D root
- [ ] Add WorldEnvironment (procedural sky, ambient light)
- [ ] Add DirectionalLight3D (sun with shadows)
- [ ] Add Ground (PlaneMesh 100×100, green/brown color)
- [ ] Add CameraPivot (Node3D) + Camera3D child
- [ ] Implement Q/E camera orbit in `battle_scene.gd`
- [ ] Add UI CanvasLayer with FadeRect

**Test:** Run scene directly, Q/E rotates camera around empty field.

---

### Phase 2: Commander Movement
**Goal:** Single controllable character with camera follow

- [ ] Create `scenes/battle/components/commander.tscn` (CharacterBody3D + Sprite3D)
- [ ] Set Sprite3D billboard mode, pixel filtering, load `ataturk-front-rdy.png`
- [ ] Implement WASD movement in `commander.gd` relative to camera basis
- [ ] Camera pivot follows commander position with lerp smoothing
- [ ] Add input actions to `project.godot` (move_forward, move_back, move_left, move_right, camera_left, camera_right, attack)

**Test:** WASD moves commander, camera follows, Q/E orbits around commander.

---

### Phase 3: Squad Formation
**Goal:** 10 soldiers following commander in wedge formation

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
- [ ] Add world objects: trees, house, oxcart (Sprite3D billboards)
- [ ] Add grass texture to ground material (or keep solid color)
- [ ] Wire `commander_selection.gd` line 235 to load battle scene
- [ ] Add AudioStreamPlayer for `battle-music.mp3`
- [ ] Use `AudioManager.crossfade_to()` for music transition
- [ ] Fade-in on scene ready

**Test:** Full flow: Main Menu → Campaign → Commander → Battle scene with both units, music, and working controls.

---

## Files to Create

```
scenes/battle/
├── battle_scene.tscn        # Main 3D scene with camera, lighting, ground
├── battle_scene.gd          # Camera orbit, input routing
└── components/
    ├── unit.tscn            # Commander + squad container (Node3D)
    ├── unit.gd              # Formation setup, attack cascade
    ├── commander.tscn       # CharacterBody3D with Sprite3D (billboard)
    ├── commander.gd         # 3D movement, sprite facing
    ├── soldier.tscn         # CharacterBody3D with Sprite3D (billboard)
    └── soldier.gd           # Formation follow behavior
```                                                                                                   
                                                                                                      
---                                                                                                   
                                                                                                      
## Assets to Create/Add                                                                               
                                                                                                      
1. **assets/sprites/world/grass-ground.png** - Generate grass/dirt texture for arena floor            
2. **assets/battle-music.mp3** - User will provide (placeholder reference in scene)                   
                                                                                                      
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

### battle_scene.tscn
```
BattleScene (Node3D)
├── Environment (WorldEnvironment)
│   └── Sky + ambient light settings
├── DirectionalLight3D (sun-like, casting shadows)
├── Ground (MeshInstance3D - large plane with grass texture)
├── WorldObjects (Node3D)
│   ├── Tree_0..3 (Sprite3D - billboard mode, world/tree.png)
│   ├── House_0..1 (Sprite3D - billboard mode, world/house.png)
│   └── Oxcart_0 (Sprite3D - billboard mode, world/oxcart.png)
├── PlayerUnit (unit.tscn at Vector3(0, 0, 40))
├── EnemyUnit (unit.tscn at Vector3(0, 0, -40), modulate=red)
├── CameraPivot (Node3D - follows commander)
│   └── Camera3D (positioned behind/above, looking at commander)
├── AudioStreamPlayer (battle-music.mp3, autoplay)
└── UI (CanvasLayer)
    ├── HUD elements
    └── FadeRect (for transitions)
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

### Movement (commander.gd)
```gdscript
# Get WASD input as Vector2
var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")

# Convert to 3D direction relative to camera facing
var camera_basis = camera_pivot.global_transform.basis
var move_dir = (camera_basis.z * input_dir.y + camera_basis.x * input_dir.x).normalized()
move_dir.y = 0  # Keep movement on ground plane

# Apply movement
velocity = move_dir * SPEED  # SPEED = 10.0 units/sec (3D scale)
move_and_slide()

# Rotate commander sprite to face movement direction
if move_dir.length() > 0.1:
    var target_angle = atan2(move_dir.x, move_dir.z)
    # Update sprite facing based on angle
```

### Camera (battle_scene.gd)
```gdscript
@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/Camera3D

const CAMERA_ROTATION_SPEED = 2.0  # rad/sec
const CAMERA_FOLLOW_SPEED = 8.0

func _process(delta):
    # Rotate camera orbit with Q/E
    if Input.is_action_pressed("camera_left"):
        camera_pivot.rotate_y(CAMERA_ROTATION_SPEED * delta)
    if Input.is_action_pressed("camera_right"):
        camera_pivot.rotate_y(-CAMERA_ROTATION_SPEED * delta)

    # Smooth follow commander position
    var target_pos = commander.global_position
    camera_pivot.global_position = camera_pivot.global_position.lerp(
        target_pos, delta * CAMERA_FOLLOW_SPEED
    )
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
                                                                                                      
                                                                                                      
If you need specific details from before exiting plan mode (like exact code snippets, error messages, 
or content you generated), read the full transcript at: /Users/jinglemisk/.claude/projects/-Users-ji  
nglemisk-Desktop/4882016d-ea2c-40f3-90a2-293b0ad9525c.jsonl