# Unit Sprite Generation Guide
## Based on Kessen III Visual & Gameplay Reference

---

## Overview

This document serves as a reference for generating 2D infantry sprites for a tactical/strategy game set during the Turkish War of Independence (1919-1923). The visual and gameplay philosophy is inspired by Kessen III's approach to unit-based real-time tactics.

**Related Documentation:**
- [gameplay.md](gameplay.md) - Battle prototype specification (controls, formation, camera)

---

## Kessen III Visual Summary

### Unit Representation
- **Units are groups, not individuals** — Each "unit" represents an officer leading dozens of soldiers
- **Officer is visually distinct** — Stands out from regular troops (different armor, colors, positioning)
- **Troops move as a cohesive mass** — Soldiers cluster around their commanding officer

### Camera & Perspective
- Third-person view from behind/above the controlled unit
- Player sees their officer + surrounding troops as a single controllable entity
- Multiple units visible on battlefield simultaneously

### Visual Hierarchy
1. **Officer/General** — Largest, most detailed, center of unit
2. **Elite troops** — Slightly more detailed, closer to officer
3. **Regular troops** — Simpler sprites, fill out the unit mass

### Animation States (from Kessen III)
- **Idle/Standing** — Troops at rest, weapons ready
- **Marching/Moving** — Walking formation
- **Attacking** — Melee strikes, weapon swings
- **Charging** — Running toward enemy (cavalry especially)
- **Defending/Blocking** — Braced stance
- **Dying/Defeated** — Death animations, ragdoll
- **Special/Skill** — Magic effects, special attacks

---

## Sprite Requirements for Turkish Infantry

### Historical Period: 1919-1923 (Kurtuluş Savaşı)

### Authentic Visual Elements
- **Headwear:** Kalpak (traditional fur hat) or enveriye cap
- **Uniform:** Ottoman-era military tunic transitioning to simpler nationalist uniforms
- **Colors:** Khaki, olive drab, earth tones (resource-scarce period)
- **Weapons:** Mauser rifles, bayonets, limited ammunition pouches
- **Footwear:** Leather boots or çarık (traditional footwear)
- **Equipment:** Leather belts, cartridge bandoliers, canteens

### Visual Condition (Period-Appropriate)
- Worn, weathered uniforms (supply shortages were common)
- Mix of Ottoman remnants and improvised gear
- Determined, resilient posture despite hardship
- Mustaches common among soldiers of the era

---

## Sprite Directions Needed

### 8-Direction System (Recommended)
```
     N (Back)
  NW    NE
W (Left)  E (Right)
  SW    SE
     S (Front)
```

### File Naming Convention
```
infantry-front.png      (S - facing camera)
infantry-front-left.png (SW)
infantry-left.png       (W)
infantry-back-left.png  (NW)
infantry-back.png       (N - facing away)
infantry-back-right.png (NE)
infantry-right.png      (E)
infantry-front-right.png(SE)
```

### Minimum 4-Direction System
```
infantry-front.png
infantry-back.png
infantry-left.png
infantry-right.png
```

---

## Animation Frames Per State

### Essential Animations
| State | Frames | Loop |
|-------|--------|------|
| Idle | 2-4 | Yes |
| Walk | 4-8 | Yes |
| Attack (melee) | 3-6 | No |
| Attack (shoot) | 3-5 | No |
| Death | 4-6 | No |
| Hit/Hurt | 2-3 | No |

### Optional Animations
| State | Frames | Loop |
|-------|--------|------|
| Run/Charge | 6-8 | Yes |
| Reload | 4-6 | No |
| Victory/Celebrate | 4-6 | No |
| Crouch/Cover | 2-3 | No |

---

## Sprite Specifications

### Recommended Dimensions
- **Commander/Officer sprite:** 64x64 pixels
- **Soldier/Troop sprites:** 48x48 pixels
- **Consistent canvas size** across all directions and states

> Note: These sizes are aligned with the battle prototype spec in [gameplay.md](gameplay.md)

### Art Style Options
1. **Pixel Art** — Retro feel, efficient, clear silhouettes
2. **Hand-Painted 2D** — More detail, warmer aesthetic
3. **Clean Vector** — Scalable, modern look

### Color Palette (Turkish Nationalist Forces)
- Primary: Khaki (#C3B091), Olive (#808000)
- Secondary: Brown leather (#8B4513), Dark gray (#404040)
- Accents: Brass/gold buttons, red/white national elements
- Skin tones: Mediterranean range

---

## Kessen III Gameplay Elements to Consider

### Troop Types to Create
Based on Kessen III's variety:

1. **Regular Infantry (Piyade)** — Rifle + bayonet, standard uniform
2. **Cavalry (Süvari)** — Mounted, saber + carbine
3. **Artillery crew (Topçu)** — Operating field guns
4. **Officers (Subay)** — Distinct uniform, pistol + saber
5. **Militia/Irregular (Kuvâ-yi Milliye)** — Civilian clothes + weapons

### Visual Feedback (from Kessen III)
- **Health = Troop count** — Show fewer soldiers as unit takes damage
- **Morale indicators** — Posture changes (confident vs demoralized)
- **Status effects** — Visual cues for buffs/debuffs

---

## Generation Prompts Template

When generating sprites, use prompts like:

```
"2D game sprite, Turkish infantry soldier 1920s,
wearing kalpak fur hat and khaki military uniform,
holding Mauser rifle, [DIRECTION] view,
[ACTION STATE], pixel art style,
transparent background, 64x64 pixels"
```

Replace:
- `[DIRECTION]`: front-facing / side view left / back view / three-quarter view
- `[ACTION STATE]`: standing idle / walking / aiming rifle / bayonet charge / falling wounded

---

## Checklist for Complete Unit Sprite Set

- [ ] Front view (all animation states)
- [ ] Back view (all animation states)
- [ ] Left view (all animation states)
- [ ] Right view (all animation states)
- [ ] Diagonal views (optional, 8-dir)
- [ ] Officer variant (more detailed)
- [ ] Wounded/death sprites
- [ ] Consistent lighting direction
- [ ] Transparent backgrounds
- [ ] Spritesheet compilation

---

## Current Asset Status

Located in `assets/sprites/`:

### Commander (ataturk/)
- [x] Front view
- [x] Back view
- [x] Side left view
- [x] Three-quarter front view
- [x] Three-quarter back view
- [x] Walk animation (3 frames)
- [x] Attack animation (3 frames)

### Infantry (infantry/)
- [x] Front, back, left, right static views
- [x] Walk animation - front (4 frames)
- [x] Walk animation - back (4 frames)
- [x] Walk animation - left (4 frames)
- [x] Walk animation - right (4 frames)
- [x] Attack animation - front (4 frames)
- [x] Attack animation - left (4 frames)
- [ ] Attack animation - back (pending)
- [ ] Attack animation - right (pending)

---

## References

- Kessen III (PS2, 2005) — Unit-based tactics, troop visualization
- Turkish War of Independence photographs (1919-1923)
- Ottoman military uniform references
- Mustafa Kemal Atatürk era military imagery
- [gameplay.md](gameplay.md) — Battle scene implementation spec
