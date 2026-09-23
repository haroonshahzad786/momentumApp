# graphics/ — cleaned ⭐ reuse assets

Extracted from the old **5 Core Life** app for potential reuse in Moore Momentum.
This is a **curated copy** — the originals stay untouched under `../5corelife-mobile/.../src/assets/`.

- Only the ⭐ "directly reusable" assets from `../notes/ASSET_MAP.md` are here.
- For each image, the **highest-res** retina variant was picked (`@3x` → `@2x` → base) and
  renamed to a clean base name (no `@2x`/`@3x` suffixes). Use these as source; downscale as needed.
- **166 files · ~41 MB** (png / json Lottie / gif / mp4 / mp3).

> ⚠️ These are the old app's brand assets. The space *art & mechanics* reuse cleanly, but
> re-skin anything carrying old 5 Core Life branding/palette before shipping.

## Structure

```
rocket/
  body/            rocket armor/body skins (01–05-rocket-armor, default, rocket5..1000)
  wings/           wing skins (tinted at runtime via a color filter)
  turbines/        engine/thruster skins (+ empty_space flame anchor)
  dashboard/       small body/wings/turbines variants for the cockpit view
  store_icons/     shop tier icons, prefixed by slot (body_/wings_/turbine_)
  flames/
    lottie/        FireHi/Mi/Lo.json  — flame by power tier
    gif/           Thruster_Low/Mid/High.gif — flame by live momentum (<36 / 36–70 / >70)
cores/
  tanks/           5 core "fuel tank" bodies: {core}_on/_off/_mask.png
  liquid/          {red,blue,pink,purple,green}_liquid.json — liquid-fill masked into each tank
  icons/           core icons (iconMindset/Emotional/Relationships/Physical/Career + Favorites)
  backgrounds/     per-core habit-screen backgrounds
journey/
  planets/         17 planet/station PNGs (earth, moon, mars … eris, station1-3)
  obstacles/       Asteroids.gif, UFOs.gif + statics, UFOs.json
  map_backgrounds/ solar-system map backdrops (lifetime/background_*)
  aliens/          01–04 alien sprites + fondo backgrounds
cinematics/        launch/landing MP4s + SpaceBG2 animated backdrop (the wired "_copy" set)
sounds/            ambience, UI FX, win jingle, alien voice
shared/            starfields, Rocket-ok.gif, leavingplanet.gif, rocketCopy2.png
splash/            Logo.json, LogoLights.json, LiquidLoad.json (boot/splash)
```

## How these map to logic
- Rocket compositing + tint + buy/equip economy → `../notes/ROCKET_SYSTEM.md`
- Full game loop (momentum, 16-destination travel, drops, trophies) → `../notes/GAME_LOOP.md`
- Every folder's original role + reuse rating → `../notes/ASSET_MAP.md`

### Core color key (for tinting)
MINDSET #AC2912 · EMOTIONAL_HEALTH #1B51A1 · RELATIONSHIPS #C8348C · PHYSICAL_HEALTH #7D2C7D · CAREER_FINANCES #6E9A30
