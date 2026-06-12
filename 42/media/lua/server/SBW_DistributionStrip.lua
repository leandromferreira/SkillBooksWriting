-- Skill Books - Writing. Copyright 2026 Leandro Ferreira. All rights reserved.
-- See LICENSE: redistribution / modpacks / reupload require written permission.
-- SkillBooksWriting — remove skill books from loot (SPEC §3).
-- One recursive pass over the merged distribution tables after OnPostDistributionMerge.
-- Cost is paid once at boot; runtime loot has zero overhead (books simply gone).

require "SBW_Config"
require "SBW_Data"

-- Walk any distribution table, deleting (itemName, weight) pairs from every
-- `.items` array whose name is a removable skill book. Covers ProceduralDistributions,
-- SuburbsDistributions and VehicleDistributions in one shape-agnostic pass.
local function stripTable(t, removable, seen)
    if type(t) ~= "table" or seen[t] then return end
    seen[t] = true
    local items = rawget(t, "items")
    if type(items) == "table" then
        for i = #items - 1, 1, -2 do          -- i = item name, i+1 = weight
            if type(items[i]) == "string" and removable(items[i]) then
                table.remove(items, i + 1)
                table.remove(items, i)
            end
        end
    end
    for _, v in pairs(t) do
        if type(v) == "table" then stripTable(v, removable, seen) end
    end
end

local function stripSkillBooks()
    local sv = SandboxVars and SandboxVars.SkillBooksWriting
    if sv and sv.DisableSkillBookSpawn == false then return end
    SBW.ensureScanned()

    local vanillaOnly = sv and sv.SpawnRemovalScope == 2   -- 1=All, 2=VanillaOnly
    local function removable(name)
        -- Distribution entries may be a short name ("BookCarpentry1", vanilla) or a
        -- full type ("Lifestyle.BookMusic1", some mods). Normalise to the short name.
        local short = name:match("([^.]+)$") or name
        if not SBW.lootBookSet[short] then return false end
        if vanillaOnly and SBW.bookModule[short] ~= "Base" then return false end
        return true
    end

    local seen = {}
    if ProceduralDistributions and ProceduralDistributions.list then
        stripTable(ProceduralDistributions.list, removable, seen)
    end
    if SuburbsDistributions then stripTable(SuburbsDistributions, removable, seen) end
    if VehicleDistributions then stripTable(VehicleDistributions, removable, seen) end
end

-- Single pass at the distribution merge. This catches vanilla skill books (and any
-- mod that adds at/before the merge). Mods that inject their books LATER, on
-- OnInitGlobalModData (e.g. Lifestyle), are intentionally NOT stripped -- their
-- books stay in loot. (A second, deferred pass used to remove those; removed by
-- request so modded books like Lifestyle keep spawning.)
Events.OnPostDistributionMerge.Add(stripSkillBooks)
