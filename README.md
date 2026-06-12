# Skill Books — Writing (`SkillBooksWriting`)

Project Zomboid **Build 42** mod. Built for large dedicated / multiplayer servers:
heavy work happens once at boot, runtime loot has zero overhead.

Instead of *finding* skill books as loot, players **write** them from their own
knowledge. Three behaviours:

1. **Skill books don't spawn as loot** (vanilla ones). Books from other mods keep
   spawning (see Compatibility).
2. **Write skill books** from your own skill level, in two steps (craft a blank
   book, then write the chosen skill into it).
3. **Books for skills that have none in vanilla** — Strength, Fitness and the
   melee skills — opt-in per category.

The mod never changes how *reading* a book gives XP — it uses the vanilla
`SkillBook` / `ISReadABook` system, only removing the loot and adding a way to
produce books.

## How to write a book

1. **Craft an Empty Skill Book** (`MakeEmptySkillBook`) — any survivor, from the
   start, on a surface. Inputs: a notebook/journal/diary/notepad + glue + leather
   strips + thread (twine/fishing line/dental floss…).
2. **Right-click the Empty Skill Book → Write skill book** → pick a skill → pick a
   volume. You need a **pen or pencil** in your inventory.
   - A skill/volume only appears if your level meets the gate: **level ≥ 2 × tier**
     (Vol. 1 needs level 2, Vol. 3 needs 6, Vol. 5 needs 10).
   - Writing time scales per tier (sandbox). The server validates level + tool +
     blank book before creating the written book (multiplayer-safe).

You write books mainly **for lower-level players to read** — by the level you can
write Vol. 1, it's already obsolete for you (vanilla reading rules are untouched).

## Sandbox options (page *Skill Books — Writing*)

| Option | Type | Default | Effect |
|---|---|---|---|
| `DisableSkillBookSpawn` | bool | true | Remove (vanilla) skill books from loot. |
| `SpawnRemovalScope` | enum | All | `All` vs `Vanilla only` for the loot removal. |
| `AllowWritingVanillaBooks` | bool | true | Allow writing the 24 vanilla skill books. |
| `AllowWritingModdedBooks` | bool | true | Allow writing books added by other mods (e.g. Lifestyle, Darts). |
| `AllowPassiveSkillBooks` | bool | false | Add + allow writing books for Strength, Fitness, Sprinting, Lightfooted, Nimble, Sneaking. |
| `AllowCombatSkillBooks` | bool | false | Add + allow writing books for Axe, Long Blunt, Short Blunt, Short Blade, Spear. |
| `BaseWriteTime` | double | 1200 | Action time (tenths of a sec) for a tier-1 book. |
| `TierTimeMultiplier` | double | 1.6 | Writing time = `BaseWriteTime × multiplier^(tier-1)`. |

## Compatibility

- **Writing** — convention-following modded books (Lifestyle: Cleaning/Music/Dancing;
  Darts; …) are **writable automatically**. The mod scans every item with a
  `SkillTrained` field at boot, so it covers them without hard dependencies.
  Toggle: `AllowWritingModdedBooks`.
- **Loot removal also covers modded books — with one limit.** Modded skill books
  that register into the loot tables the normal (vanilla) way **can** be stripped
  from loot together with the vanilla ones when `SpawnRemovalScope = All`. But mods
  that inject and **re-bake** their own loot a different way *after* the
  distribution merge — e.g. **Lifestyle** (it calls `ItemPickerJava.Parse()` itself
  on `OnInitGlobalModData`, after our single merge-time pass) — are **not affected**:
  their books keep spawning. Set `SpawnRemovalScope = Vanilla only` to strip just
  base-game books.

## File layout

```
SkillBooksWriting/
  mod.info                 # pzversion=42.0
  42/
    mod.info               # identical
    media/
      sandbox-options.txt
      scripts/             # EmptySkillBook item, recipe, generated bookless books
      lua/
        shared/  SBW_Config.lua, SBW_Data.lua (boot scan), TimedActions/ISWriteSkillBook.lua
        server/  SBW_SkillBookTable.lua (read-XP table), SBW_DistributionStrip.lua, SBW_WriteServer.lua
        client/  SBW_ContextMenu.lua
        shared/Translate/{EN,PTBR}/  ItemName, Recipes, Sandbox, IG_UI (.json)
  tools/gen_bookless.py    # regenerates the bookless book items + their names
```

Regenerate the bookless books: `python3 tools/gen_bookless.py`

## Notes for server admins

- Costs are paid once at boot (item scan + a single loot-table pass). No per-tick
  or per-loot overhead.
- Book creation is server-authoritative (`OnClientCommand`); inventory changes are
  synced with `sendAdd/RemoveItemFromContainer`. Single-player calls the same core
  directly.
- `SkillBook[]` entries for the bookless skills are registered server-side at
  top-level so they're present on clients too (reading gives XP, no crashes).

## Permissions for Modders

**Ask for permission.**

This mod may **not** be included in modpacks, collections distributed as a single
download, or any form of redistribution without the express permission of the
original creator. Extensions and patches are also subject to this restriction.
Having received permission, credit must be given to the original creator both
within the mod files and wherever the mod is published online.

## Copyright

**Copyright 2026 Leandro Ferreira.** This item is not authorized for posting on
Steam, except under the Steam account named leozimmelo.

All rights reserved. This mod may not be reuploaded, mirrored, or included in
modpacks or collections distributed as a single download without the express
written permission of the original creator.
