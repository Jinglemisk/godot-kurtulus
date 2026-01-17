# Kurtulus - Prototype Gameplay Specification

Version: 0.1 (Prototype Scene)

**Related Documentation:**
- [unit-sprites.md](unit-sprites.md) - Sprite requirements and generation guide

## Overview

This document specifies a minimal prototype scene to validate core Kessen III-style mechanics:
- Commander + squad movement as a single unit
- Formation behavior (soldiers follow commander)
- Camera controls
- Basic attack action
- Enemy unit with visual distinction

---

## Scene Setup

### Arena
- Flat terrain (no obstacles for prototype)
- Size: ~100x100 units
- Ground texture: simple grass/dirt plane

### Entities
1. **Player Unit** - Commander + 8-12 soldiers
2. **Enemy Unit** - Same structure, positioned ~40 units away, red tint applied

---

## Unit Structure

### Hierarchy
```
Unit (Node2D)
├── Commander (CharacterBody2D)
│   ├── Sprite2D (commander sprite)
│   ├── CollisionShape2D
│   └── AnimationPlayer
├── Squad (Node2D)
│   ├── Soldier_0 (CharacterBody2D)
│   ├── Soldier_1 (CharacterBody2D)
│   └── ... (8-12 total)
└── FormationController (script)
```

### Commander
- Directly controlled by player input
- Sprite: `assets/sprites/ataturk/` or officer variant
- Movement speed: 200 units/sec
- Size: 64x64 sprite

### Soldiers (Peons)
- Follow commander using formation offsets
- Sprite: `assets/sprites/infantry/`
- Size: 48x48 sprite (slightly smaller than commander)
- Count: 8-12 per unit

---

## Formation System

### Formation Shape: Wedge/V-Formation
Soldiers maintain positions relative to commander's facing direction.

```
        [C]           <- Commander (front)
      /     \
    [S]     [S]       <- Row 1 (2 soldiers)
   /   \   /   \
 [S]   [S] [S]   [S]  <- Row 2 (4 soldiers)
       ...            <- Row 3+ as needed
```

### Formation Offsets (relative to commander)
```gdscript
const FORMATION_OFFSETS = [
    # Row 1
    Vector2(-40, 50),   # back-left
    Vector2(40, 50),    # back-right
    # Row 2
    Vector2(-80, 100),
    Vector2(-25, 100),
    Vector2(25, 100),
    Vector2(80, 100),
    # Row 3
    Vector2(-60, 150),
    Vector2(0, 150),
    Vector2(60, 150),
    # Row 4
    Vector2(-40, 200),
    Vector2(40, 200),
]
```

### Following Behavior
- Soldiers smoothly interpolate toward their formation position
- Follow speed: slightly faster than commander (220 units/sec) to catch up
- Smoothing: `lerp()` with delta * 5.0 for responsive but not instant snapping
- Rotation: soldiers face the same direction as commander

---

## Controls

### Movement (WASD / Arrow Keys)
| Input | Action |
|-------|--------|
| W / Up | Move forward (commander's facing direction) |
| S / Down | Move backward |
| A / Left | Strafe left |
| D / Right | Strafe right |

### Camera (Q/E or Mouse)
| Input | Action |
|-------|--------|
| Q | Rotate camera left (counter-clockwise) |
| E | Rotate camera right (clockwise) |
| Mouse at screen edge | Optional: rotate camera |

Camera rotates around the commander (pivot point).

### Attack (Space / Left Click)
| Input | Action |
|-------|--------|
| Space / LMB | Commander performs attack animation |

For prototype: attack is a simple animation trigger. No damage calculation yet.

---

## Camera System

### Type: Third-Person Follow Camera

```
Camera Settings:
- Zoom: Fixed at 0.5 (shows commander + full squad + some surroundings)
- Follow target: Commander position
- Rotation: Player-controlled around commander
- Smoothing: Position lerp with delta * 8.0
```

### Implementation
```gdscript
# Camera follows commander with rotation
var camera_angle: float = 0.0  # radians
const CAMERA_DISTANCE = 300  # pixels from commander
const CAMERA_ROTATION_SPEED = 2.0  # radians/sec

func _process(delta):
    # Rotate camera
    if Input.is_action_pressed("camera_left"):
        camera_angle -= CAMERA_ROTATION_SPEED * delta
    if Input.is_action_pressed("camera_right"):
        camera_angle += CAMERA_ROTATION_SPEED * delta

    # Position camera
    var offset = Vector2(0, CAMERA_DISTANCE).rotated(camera_angle)
    camera.global_position = commander.global_position + offset
    camera.rotation = camera_angle
```

Note: For 2D top-down, "camera rotation" means rotating the world view, so movement directions should be relative to camera angle.

---

## Animation States

### Commander
| State | Trigger | Animation |
|-------|---------|-----------|
| Idle | No input | `ataturk-front` (static or subtle idle) |
| Walk | Movement input | `walk-1` → `walk-2` → `walk-3` cycle |
| Attack | Attack input | `attack-1` → `attack-2` → `attack-3` |

### Soldiers
| State | Trigger | Animation |
|-------|---------|-----------|
| Idle | Formation position reached | `infantry/front` |
| Walk | Moving to formation position | `infantry/walk/front/frame1-4` |
| Attack | Commander attacks | `infantry/attack/front/frame1-4` (slight delay) |

Soldiers mirror commander's animation state with 0.1-0.2 sec stagger for organic feel.

---

## Enemy Unit

### Visual Distinction
Apply red tint via shader or modulate:
```gdscript
# Simple approach: modulate
enemy_unit.modulate = Color(1.0, 0.5, 0.5, 1.0)  # reddish tint

# Or per-sprite:
for soldier in enemy_squad.get_children():
    soldier.sprite.modulate = Color(1.2, 0.6, 0.6)
```

### Behavior (Prototype)
- **Static**: Enemy unit stands in place, facing player
- No AI movement or combat for initial prototype
- Future: Add patrol, chase, and attack behaviors

### Positioning
- Start position: `Vector2(0, -800)` or similar (40+ units from player spawn)
- Player starts at: `Vector2(0, 0)` or center of arena

---

## Input Map (project.godot)

Add these input actions:
```
[input]
move_forward = Key W, Key Up
move_backward = Key S, Key Down
move_left = Key A, Key Left
move_right = Key D, Key Right
camera_left = Key Q
camera_right = Key E
attack = Key Space, Mouse Button 1
```

---

## File Structure

```
scenes/
└── battle/
    ├── battle_scene.tscn      # Main prototype scene
    ├── battle_scene.gd        # Scene controller
    └── components/
        ├── unit.tscn          # Reusable unit (commander + squad)
        ├── unit.gd            # Unit controller
        ├── commander.tscn     # Commander entity
        ├── commander.gd       # Commander controls
        ├── soldier.tscn       # Single soldier entity
        ├── soldier.gd         # Soldier follow behavior
        └── formation.gd       # Formation offset calculations
```

---

## Implementation Checklist

### Phase 1: Static Scene
- [ ] Create `battle_scene.tscn` with ground plane
- [ ] Create `commander.tscn` with sprite and collision
- [ ] Add basic WASD movement to commander
- [ ] Add camera that follows commander

### Phase 2: Formation
- [ ] Create `soldier.tscn` with sprite
- [ ] Create `unit.tscn` combining commander + soldiers
- [ ] Implement formation offsets in `formation.gd`
- [ ] Soldiers follow their formation positions smoothly

### Phase 3: Camera Rotation
- [ ] Add Q/E camera rotation controls
- [ ] Make movement relative to camera angle
- [ ] Test: rotating camera should change "forward" direction

### Phase 4: Animation
- [ ] Wire up commander walk animation
- [ ] Wire up soldier walk animation
- [ ] Add attack animation on Space press
- [ ] Soldiers attack with slight delay after commander

### Phase 5: Enemy Unit
- [ ] Duplicate unit with red modulate
- [ ] Position enemy unit across the arena
- [ ] Enemy faces player (static for now)

---

## Future Iterations (Out of Scope for Prototype)

These features are NOT in the prototype but documented for reference:

1. **Combat Resolution** - Hitboxes, damage, health/troop count
2. **Squad AI** - Enemy movement, chase, engage states
3. **Morale System** - Flee behavior at low health
4. **Rock-Paper-Scissors** - Unit type advantages
5. **Special Abilities** - Charge, Rally, Artillery
6. **Minimap & HUD** - Health bars, formation indicator
7. **Terrain** - NavMesh, obstacles, height advantage
