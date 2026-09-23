# Old App Source — REFERENCE ONLY

Client-provided source of a previous version of the app. Pasted here **for reference only**.

## Purpose
- Reuse some **old graphics** (images, animations).
- Study the **logic / game mechanics** — how the developer assembled different **rocket components** to make it feel like a game.

## Rules
- **Do NOT** build, compile, import, or wire any of this into the live Flutter app.
- Nothing here is part of the app's dependency graph or build.
- Treat as read-only inspiration + asset donor.

## What's here
- `5corelife-mobile/` — React Native app (graphics + rocket game logic)
- `5corelife-api/`    — Django REST backend (game economy/rules)

## Notes (read these first)
- `notes/ROCKET_SYSTEM.md` — how the rocket is composed from swappable parts + its buy/equip economy
- `notes/ASSET_MAP.md`     — every asset folder → what it was used for + reuse priority
- `notes/GAME_LOOP.md`     — full backend economy & daily/travel loop (momentum, destinations, drops)
