# Rocket Component System — how the old app gamified the rocket

Source: legacy **"5 Core Life"** app (predecessor to Moore Momentum).
- Frontend: React Native — `5corelife-mobile/.../src`
- Backend: Django REST — `5corelife-api/5corelife-master/src`

This documents #2 of your two goals: *how the developer used different rocket components to make it feel like a game.* (Asset/graphics inventory is in `ASSET_MAP.md`.)

---

## 1. The rocket is a layered composite, not one image

`components/Rocket/index.tsx` stacks absolutely-positioned layers to build one rocket:

```
 Layer order (back → front):
   1. WINGS   — <Image> tinted at runtime by a DuoTone color filter
   2. BODY    — the rocket "armor"/skin image (color variant)
   3. TURBINE — the engine image
   4. FLAMES  — 1..5 animated flame sprites, positioned per turbine tier
```

Key idea: **three swappable slots** drive the look, fed by three helper getters:

```tsx
const wingsAssetObject   = getImprovementsWings(wings ?? 'default', false).image;
const rocketAssetObject  = getImprovementsColors(skinColor ?? 'default', false);
const turbineAssetObject = getImprovementsTurbines(turbines ?? 'default', false);
```

- **Wings** → a PNG **+ a `color` hex**. The color is applied to the wings image via
  `react-native-color-matrix-image-filters` `DuoTone` — so one wing shape is re-tinted per rarity instead of shipping N colored PNGs.
- **Armor (skinColor)** → the body PNG + its own `color`. `'default'` uses a different position/size (`styles.rocket` vs `styles.rocket2`).
- **Turbine** → a PNG **+ a `flames` count** (1/2/3/5). The component branches on `flames` and renders that many flame sprites at hard-coded offsets (`duoLeft`, `duoRight`, `flame_principal`, `duoLeftExtra`…). More flames = visibly more powerful engine.

## 2. Flame intensity is driven by a live "momentum" score

`helpers/flame.ts` swaps the flame GIF by the user's momentum number:

```ts
export const typeFlame = (momentum = 0) => {
  if (momentum < 36)              return require('.../cores/Thruster_Low.gif');
  if (momentum > 35 && momentum < 71) return require('.../cores/Thruster_Mid.gif');
  if (momentum > 70)              return require('.../cores/Thruster_High.gif');
}
```

So the rocket's flame literally reflects how well you're doing (low/mid/high momentum).
There is also a Lottie version (`getPowerFlameAnimation` → `FireLo/FireMi/FireHi.json`) that
the code currently has commented out in favor of the GIFs.

> NOTE for our app: the rocket has TWO "power" signals conflated — `flamePower` prop (1..3, Lottie)
> and the turbine `flames` tier (cosmetic, from the equipped part). The shipping code uses a
> hard-coded `78` momentum for the GIF, i.e. the live-momentum wiring was stubbed. Worth doing
> properly if we reuse this.

## 3. The three slots = the "Improvements" store (rocket tuning UI)

`modules/configuration/Improvements/` is the hub screen: shows the assembled rocket in a
"cockpit window" frame and three round buttons → **Armors / Wings / Thrusters**. Each opens a
dedicated screen (`ImprovementArmors`, `ImprovementWings`, `ImprovementTurbines`) that:

- lists the buyable variants for that slot as circular buttons (icon + cost, or "IN USE"),
- live-previews the rocket with the highlighted part swapped in,
- shows the part's gameplay bonus (e.g. `+{bonus_core_cap} Core Cap`),
- Buy → Equip flow against the backend.

The user's currently-equipped part per slot is found by:
```tsx
userImprovements.find(x => x.type === 'THRUSTER' && x.isActive)?.name ?? 'Base Thruster'
// same pattern for WINGS -> 'Base Wings', ARMOR -> 'Base Armor'
```

## 4. Rarity tiers → assets + stats

Variants are keyed by **rarity name** (not ids), which maps to a PNG and a property:

| Slot     | Tier names (getter switch)                              | Extra property per tier |
|----------|---------------------------------------------------------|-------------------------|
| Wings    | Common, Uncommon, Rare, Very Rare, Epic (+ default)     | `color` hex for DuoTone tint |
| Turbines | Rare(2), Very Rare(3), Epic(5), Star Jump Engine(5), default(1) | `flames` count |
| Armor    | (see `getImprovementsColors` / `…Colors2`)              | body `color` + skin PNG |

Asset filenames encode an old credit price: `rocket5 / rocket25 / rocket50 / rocket100 / rocket1000`.
Each tier also carries `iconButton` (store icon) and `titleButton`.

## 5. Backend economy (Django `improvements` app)

**`Improvement` model** — the catalog. Fields that make it a game, not a skin picker:
```py
cost                    # credits to buy
probability_reward      # % chance to DROP as a reward (0 = never drops, buy-only)
destination (FK)        # tie an unlock to reaching a planet/space-station
improvement_type        # ARMOR | WINGS | THRUSTER
order                   # tier ordering
bonus_core_cap          # PERMANENT stat: raises your core cap when equipped
core_power_multiplier   # PERMANENT stat: multiplies core power
```

**`ImprovementUser`** — ownership: `(user, improvement, equipped)`.

**Endpoints** (`improvements/views.py`):
- `GET improvements/` — catalog (ordered by `order`)
- `GET improvements/user/` — what this user owns + equipped flags
- `POST improvements/buy/` — spend credits
- `POST improvements/equip/` — equip one, auto-unequip same slot

**Buy logic** (`BuyImprovementSerializer`): rejects if already owned, or if
`improvement.cost > user.user_profile.credits`; else **deducts credits** and creates the row.

**Equip logic** (`EquipImprovementSerializer`):
```py
# unequip all others of the same type, equip the chosen one
ImprovementUser.objects.filter(user, improvement__improvement_type=type).exclude(pk).update(equipped=False)
ImprovementUser.objects.filter(user, improvement=this).update(equipped=True)
# WINGS with a bonus grant a PERMANENT stat boost:
if improvement_type == 'WINGS' and bonus_core_cap > 0:
    user.user_profile.core_cap += bonus_core_cap
```

## 6. The full game loop around the rocket

```
 do daily habit checks  ─► earn momentum (flame intensity) + credits
 travel through space    ─► reach destinations, parts can DROP (probability_reward)
 spend credits in store  ─► BUY rocket parts (armor/wings/thruster)
 EQUIP parts             ─► rocket visually reconfigures  +  permanent stat boosts
                            (bonus_core_cap, core_power_multiplier)  →  play better
```

The rocket is the **progression avatar**: cosmetic identity (tiers/rarity, tint, flame count)
*and* a stat sheet (core cap / power). That dual role — vanity + mechanical payoff — is the
core trick that makes upgrading feel worthwhile.

---

### Reuse notes for Moore Momentum
- The **layered-composite + DuoTone tint** approach ports cleanly to Flutter (Stack of
  positioned Images; use a `ColorFiltered`/matrix for the tint instead of shipping colored PNGs).
- The **flame-by-momentum** mapping is a clean, ready gamification hook for our momentum score.
- The **buy/equip/drop + permanent-stat** economy is a complete, minimal design we can mirror
  (credits, owned/equipped, rarity tiers, stat bonuses).
- Actual rocket-part PNGs/animations to reuse are catalogued in `ASSET_MAP.md`.
