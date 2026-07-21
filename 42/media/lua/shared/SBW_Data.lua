-- Skill Books - Writing. Copyright 2026 Leandro Ferreira. All rights reserved.
-- See LICENSE: redistribution / modpacks / reupload require written permission.
-- SkillBooksWriting — boot scan of every skill book in the game.
-- Builds, once, the maps that drive loot removal and the write menu WITHOUT
-- hardcoding item IDs, so vanilla + Lifestyle + any convention-following mod are
-- all covered (SPEC §3.1, §4.3, §10).

require "SBW_Config"

SBW = SBW or {}
SBW.lootBookSet = {}       -- [shortName]   = true        (loot tables use short names)
SBW.bookModule  = {}       -- [shortName]   = "Base"|...   (for SpawnRemovalScope)
SBW.bookBySkillTier = {}   -- [skill][tier] = "Module.Item" (full type for AddItem)

-- Skill-book category tag. Vanilla (and convention-following mods) put readable
-- skill books AND the "slipcase" set items in this DisplayCategory. The set items
-- (BookCarpentrySet, ...) unpack into the 5 volumes and DO spawn in loot, but they
-- carry NO SkillTrained, so a SkillTrained-only scan misses them and they keep
-- spawning. We treat any SkillBook-category item as removable loot.
local SKILLBOOK_CATEGORY = "SkillBook"

-- vanilla tiers are LvlSkillTrained 1,3,5,7,9 -> tier 1..5
local function tierFromLvl(lvl)
    if lvl and lvl >= 1 then return math.floor((lvl + 1) / 2) end
    return nil
end

function SBW.scanItems()
    SBW.lootBookSet, SBW.bookModule, SBW.bookBySkillTier = {}, {}, {}
    local items = getScriptManager():getAllItems()
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        local skill = item:getSkillTrained()
        local hasSkill = skill and skill ~= ""
        -- Removable from loot if it's a real skill book (SkillTrained) OR a
        -- SkillBook-category item without a skill (the slipcase "set" items).
        if hasSkill or item:getDisplayCategory() == SKILLBOOK_CATEGORY then
            local short = item:getName()
            SBW.lootBookSet[short] = true
            SBW.bookModule[short] = item:getModuleName()
        end
        -- Only real skill books (skill + tier) feed the write menu.
        if hasSkill then
            local tier = tierFromLvl(item:getLevelSkillTrained())
            if tier then
                SBW.bookBySkillTier[skill] = SBW.bookBySkillTier[skill] or {}
                SBW.bookBySkillTier[skill][tier] = item:getFullName()
            end
        end
    end
    SBW.scanned = true
end

-- Idempotent: callers (boot, loot merge, write handler) just call this.
function SBW.ensureScanned()
    if not SBW.scanned then SBW.scanItems() end
end

-- Scan after every mod's items are registered (SPEC §10.4).
Events.OnGameBoot.Add(SBW.ensureScanned)
