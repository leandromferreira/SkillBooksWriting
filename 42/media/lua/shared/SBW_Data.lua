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

-- The "slipcase" set items (BookCarpentrySet, ...) unpack into the 5 volumes and
-- DO spawn in loot, but carry NO SkillTrained, so a SkillTrained-only scan misses
-- them. We can't key on DisplayCategory == "SkillBook" alone: mods miscategorise
-- recipe magazines / schematics under it (KI5 vehicle manuals, DAMN library
-- SchematicsBox) and even inject them into vanilla loot, so that would wrongly
-- strip them. The precise, mod-safe signal is the vanilla unpack recipe every real
-- book set uses -- and only book sets use -- combined with the SkillBook category.
local SKILLBOOK_CATEGORY = "SkillBook"
local BOOK_SET_RECIPE    = "UnpackSetOfBooks"

-- A loot entry is a removable skill book when it is shelved as a SkillBook AND
-- either it grants reading XP (SkillTrained) OR it is a boxed set that unpacks
-- into the volumes (DoubleClickRecipe = UnpackSetOfBooks). Requiring the SkillBook
-- category keeps modded recipe magazines / schematics that reuse that category
-- (KI5 vehicle manuals, DAMN SchematicsBox) out of the removal set.
local function isRemovableBookItem(item, hasSkill)
    if item:getDisplayCategory() ~= SKILLBOOK_CATEGORY then return false end
    return hasSkill or item:getDoubleClickRecipe() == BOOK_SET_RECIPE
end

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
        -- Loot removal: SkillBook-categorised AND (real skill book OR boxed set).
        if isRemovableBookItem(item, hasSkill) then
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

-- Is distribution loot removal on? (sandbox DisableSkillBookSpawn) -- gates the
-- distribution strip (containers/vehicles).
function SBW.lootRemovalEnabled()
    local sv = SandboxVars and SandboxVars.SkillBooksWriting
    return not (sv and sv.DisableSkillBookSpawn == false)
end

-- Is foraging removal on? (sandbox RemoveForageableSkillBooks) -- gates the forage
-- strip INDEPENDENTLY of the distribution option, so an admin can remove foraged
-- skill books even while leaving them in container loot, or vice versa.
function SBW.forageRemovalEnabled()
    local sv = SandboxVars and SandboxVars.SkillBooksWriting
    return not (sv and sv.RemoveForageableSkillBooks == false)
end

-- Is `name` a removable skill book, honoring SpawnRemovalScope? Accepts a short
-- name ("BookCarpentry1") or a full type ("Base.BookCarpentry1"). Used by both
-- the distribution strip and the forage strip so they classify identically.
function SBW.isRemovableBook(name)
    if not name then return false end
    local short = name:match("([^.]+)$") or name
    if not SBW.lootBookSet[short] then return false end
    local sv = SandboxVars and SandboxVars.SkillBooksWriting
    if sv and sv.SpawnRemovalScope == 2 and SBW.bookModule[short] ~= "Base" then
        return false                                   -- vanilla-only scope
    end
    return true
end

-- Scan after every mod's items are registered (SPEC §10.4).
Events.OnGameBoot.Add(SBW.ensureScanned)
