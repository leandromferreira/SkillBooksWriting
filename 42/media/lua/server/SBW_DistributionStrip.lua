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
-- Returns the number of (name, weight) pairs removed (for the boot log).
local function stripTable(t, seen)
    if type(t) ~= "table" or seen[t] then return 0 end
    seen[t] = true
    local removed = 0
    local items = rawget(t, "items")
    if type(items) == "table" then
        for i = #items - 1, 1, -2 do          -- i = item name, i+1 = weight
            if type(items[i]) == "string" and SBW.isRemovableBook(items[i]) then
                table.remove(items, i + 1)
                table.remove(items, i)
                removed = removed + 1
            end
        end
    end
    for _, v in pairs(t) do
        if type(v) == "table" then removed = removed + stripTable(v, seen) end
    end
    return removed
end

local function stripSkillBooks()
    if not SBW.lootRemovalEnabled() then return end
    SBW.ensureScanned()

    local seen, removed = {}, 0
    if ProceduralDistributions and ProceduralDistributions.list then
        removed = removed + stripTable(ProceduralDistributions.list, seen)
    end
    if SuburbsDistributions then removed = removed + stripTable(SuburbsDistributions, seen) end
    if VehicleDistributions then removed = removed + stripTable(VehicleDistributions, seen) end
    print(string.format("[SBW] loot strip: removed %d skill-book entries from distribution tables", removed))
end

-- Single pass at the distribution merge. This catches vanilla skill books (and any
-- mod that adds at/before the merge). Mods that inject their books LATER, on
-- OnInitGlobalModData (e.g. Lifestyle), are intentionally NOT stripped -- their
-- books stay in loot. (A second, deferred pass used to remove those; removed by
-- request so modded books like Lifestyle keep spawning.)
Events.OnPostDistributionMerge.Add(stripSkillBooks)
