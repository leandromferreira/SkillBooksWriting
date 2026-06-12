-- Skill Books - Writing. Copyright 2026 Leandro Ferreira. All rights reserved.
-- See LICENSE: redistribution / modpacks / reupload require written permission.
-- SkillBooksWriting — "Write skill book" context menu on the Empty Skill Book
-- (SPEC §4.3). Built at runtime from the boot scan + SkillBook[] + sandbox, so it
-- offers vanilla, modded (Lifestyle), curated bookless and admin-listed scriptless
-- skills alike.

require "TimedActions/ISWriteSkillBook"
require "SBW_Data"

local function startWrite(player, book, skill, tier, bookType, perkName, perk)
    ISTimedActionQueue.add(ISWriteSkillBook:new(player, book, skill, tier, bookType, perkName, perk))
end

-- Iterate the right-clicked entries (InventoryItem or stack) and run fn(item).
local function eachItem(items, fn)
    for _, v in ipairs(items) do
        local it = (instanceof(v, "InventoryItem") and v) or (v.items and v.items[1])
        if it then fn(it) end
    end
end

-- First Empty Skill Book among the right-clicked items, or nil.
local function findEmptyBook(items)
    local found
    eachItem(items, function(it)
        if not found and it:getFullType() == SBW.EMPTY_BOOK then found = it end
    end)
    return found
end

-- Skills with at least one writable tier for this player, sorted by display name.
local function gatherWritable(player)
    local out = {}
    for skill, tiers in pairs(SBW.bookBySkillTier) do
        local perk = SBW.resolvePerk(skill)
        if perk and SBW.isWritingAllowed(skill) then
            local level = player:getPerkLevel(perk)
            local writable = {}
            for tier = 1, 5 do
                if tiers[tier] and level >= SBW.requiredLevelForTier(tier) then
                    writable[#writable + 1] = { tier = tier, bookType = tiers[tier] }
                end
            end
            if #writable > 0 then
                out[#out + 1] = { skill = skill, perk = perk,
                    perkName = PerkFactory.getPerk(perk):getName(), tiers = writable }
            end
        end
    end
    table.sort(out, function(a, b) return a.perkName < b.perkName end)
    return out
end

local function onFillMenu(playerNum, context, items)
    local book = findEmptyBook(items)
    if not book then return end
    local player = getSpecificPlayer(playerNum)
    if not player then return end

    local root = context:addOption(getText("IGUI_SBW_WriteSkillBook"), nil, nil)

    if not SBW.hasWritingTool(player) then
        root.notAvailable = true
        root.toolTip = ISInventoryPaneContextMenu.addToolTip()
        root.toolTip.description = getText("IGUI_SBW_NeedPen")
        return
    end

    local writable = gatherWritable(player)
    if #writable == 0 then
        root.notAvailable = true
        root.toolTip = ISInventoryPaneContextMenu.addToolTip()
        root.toolTip.description = getText("IGUI_SBW_NothingWritable")
        return
    end

    local skillMenu = ISContextMenu:getNew(context)
    context:addSubMenu(root, skillMenu)
    for _, entry in ipairs(writable) do
        local skillOpt = skillMenu:addOption(entry.perkName, nil, nil)
        local tierMenu = ISContextMenu:getNew(skillMenu)
        skillMenu:addSubMenu(skillOpt, tierMenu)
        for _, t in ipairs(entry.tiers) do
            tierMenu:addOption(
                getText("IGUI_SBW_WriteBook_Entry", entry.perkName, t.tier),
                player, startWrite, book, entry.skill, t.tier, t.bookType, entry.perkName, entry.perk)
        end
    end
end

Events.OnFillInventoryObjectContextMenu.Add(onFillMenu)
