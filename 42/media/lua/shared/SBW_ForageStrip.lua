-- Skill Books - Writing. Copyright 2026 Leandro Ferreira. All rights reserved.
-- See LICENSE: redistribution / modpacks / reupload require written permission.
-- SkillBooksWriting — remove skill books from the FORAGING system (SPEC §3).
--
-- Foraging is a separate loot system from the distribution tables handled by
-- SBW_DistributionStrip: items are registered into `forageSystem.forageDefinitions`
-- (base game: media/lua/shared/Foraging/Categories/Junk.lua registers the vanilla
-- skill books in the "Junk" category, findable in Forest / FarmLand / TownZone...).
-- The distribution strip never touches this, so without this pass a player could
-- still forage skill books.
--
-- Timing: the category files populate forageDefinitions at load; forageSystem.init()
-- reads it (populateItemDefs -> generateLootTable) later, on OnLoadedMapZones. We
-- prune forageDefinitions at OnGameBoot -- after the definitions exist, before init
-- builds the spawn table -- so the books are simply never findable. clearTables()
-- only resets the derived itemDefs, not forageDefinitions, so this holds for the
-- session. Honors the same DisableSkillBookSpawn / SpawnRemovalScope as the strip.

require "SBW_Config"
require "SBW_Data"

local function stripForageBooks()
    if not SBW.forageRemovalEnabled() then return end
    if not (forageSystem and forageSystem.forageDefinitions) then return end
    SBW.ensureScanned()

    local defs = forageSystem.forageDefinitions
    local removed = 0
    for key, def in pairs(defs) do
        local fullType = (type(def) == "table" and def.type) or key
        if SBW.isRemovableBook(fullType) then
            defs[key] = nil                      -- removing current key mid-pairs is safe in Lua
            removed = removed + 1
        end
    end
    print(string.format("[SBW] forage strip: removed %d skill-book entries from forage definitions", removed))
end

-- OnGameBoot fires after all Lua (incl. the foraging category files) has loaded
-- and before OnLoadedMapZones runs forageSystem.init().
Events.OnGameBoot.Add(stripForageBooks)
