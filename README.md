# Kurtulus

A real-time tactics game set during the Turkish War of Independence (1919-1923), inspired by Kessen III.

## Overview

Control commanders leading squads of soldiers across historical campaigns. Experience key battles from the national liberation struggle through direct unit control and tactical gameplay.

## Campaigns

- **Isgal Donemi (1919-1920)** - The occupation begins, resistance sparks
- **Milli Direnis (1920-1921)** - The national assembly forms, first victories
- **Zafer Yolu (1922-1923)** - The great offensive, final victory

## Current Status

**Phase: Prototype Development**

Implemented:
- Main menu with audio
- Campaign selection screen
- Commander selection with 4 commander types
- Sprite assets (commander, infantry with walk/attack animations)

In Progress:
- Battle scene prototype (see `docs/gameplay.md`)

## Project Structure

```
kurtulus/
├── assets/
│   ├── sprites/
│   │   ├── ataturk/      # Commander sprites + animations
│   │   └── infantry/     # Soldier sprites + animations
│   └── *.mp3             # Menu music
├── docs/
│   ├── gameplay.md       # Battle prototype specification
│   └── unit-sprites.md   # Sprite generation guide
├── scenes/
│   ├── main_menu/
│   ├── campaign_selection/
│   ├── commander_selection/
│   └── settings/
├── scripts/
│   └── autoload/
│       ├── audio_manager.gd
│       └── game_manager.gd
└── resources/
```

## Documentation

| Document | Description |
|----------|-------------|
| [docs/gameplay.md](docs/gameplay.md) | Battle scene prototype spec - controls, formation, camera |
| [docs/unit-sprites.md](docs/unit-sprites.md) | Sprite requirements and generation guide |

## Commander Types

| Type | Focus | Key Bonuses |
|------|-------|-------------|
| Organizer | Unit coordination | +Officer slots, +Efficiency |
| Logistician | Supply management | +Supply, -Ammo consumption |
| Raider | Irregular warfare | +Recon, +Ambush damage |
| Engineer | Fortification | +Entrenchment, +Defense |

## Controls (Battle Prototype)

| Input | Action |
|-------|--------|
| WASD | Move unit |
| Q/E | Rotate camera |
| Space | Attack |

## Tech Stack

- Godot 4.2 (Forward+)
- GDScript
- 2D sprites with 4/8-directional views

## References

- Kessen III (PS2, 2005) - Gameplay inspiration
- Turkish War of Independence (1919-1923) - Historical setting
