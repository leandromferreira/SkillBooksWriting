-- Skill Books - Writing. Copyright 2026 Leandro Ferreira. All rights reserved.
-- See LICENSE: redistribution / modpacks / reupload require written permission.
-- SkillBooksWriting — authoritative write (SPEC §4.3, §7-B).
-- The client only REQUESTS; the server validates with its own data and creates
-- the book. The fix vs the first attempt: after Remove/AddItem we call the
-- sendRemove/sendAddItemToContainer transmit helpers, so the change reaches the
-- client live (without them the new book only showed up after a relog).
-- Runs in SP too (server lua loads); transmit is guarded by isServer().

require "SBW_Config"
require "SBW_Data"

-- args = { skill = "Strength", tier = 3, bookType = "SBW.BookStrength3" }
function SBW.writeBook(player, args)
    if not (player and args and args.skill and args.tier and args.bookType) then return end
    local skill, tier, bookType = args.skill, tonumber(args.tier), args.bookType
    if not tier or tier < 1 or tier > 5 then return end

    -- sandbox / category gate + writing tool
    if not SBW.isWritingAllowed(skill) then return end
    if not SBW.hasWritingTool(player) then return end

    -- requested book really is this skill's tier book (anti-spoof)
    SBW.ensureScanned()
    local byTier = SBW.bookBySkillTier[skill]
    if not byTier or byTier[tier] ~= bookType then return end

    -- level gate, resolved + checked against the SERVER's perk data (not the client's)
    local perk = SBW.resolvePerk(skill)
    if not perk then return end
    if player:getPerkLevel(perk) < SBW.requiredLevelForTier(tier) then return end

    -- consume one blank book, create the written one, and sync both to the client
    local inv = player:getInventory()
    local empty = inv:getFirstTypeRecurse("EmptySkillBook")
    if not empty then return end
    local cont = empty:getContainer() or inv
    cont:Remove(empty)
    if isServer() then sendRemoveItemFromContainer(cont, empty) end

    local book = inv:AddItem(bookType)
    if isServer() then sendAddItemToContainer(inv, book) end
end

Events.OnClientCommand.Add(function(module, command, player, args)
    if module ~= SBW.MODULE or command ~= "Write" then return end
    local ok, err = pcall(SBW.writeBook, player, args or {})
    if not ok then print("[SBW] write handler error: " .. tostring(err)) end
end)
