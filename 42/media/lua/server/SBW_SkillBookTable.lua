-- Skill Books - Writing. Copyright 2026 Leandro Ferreira. All rights reserved.
-- See LICENSE: redistribution / modpacks / reupload require written permission.
-- SkillBooksWriting — register SkillBook[] entries for the bookless skills so
-- READING those books gives XP, and so vanilla's ISInventoryPaneContextMenu (which
-- does SkillBook[item:getSkillTrained()].perk WITHOUT a nil-check) never crashes
-- on one of our books.
--
-- MUST be lua/server + TOP-LEVEL (not OnGameBoot), exactly like vanilla
-- XPSystem_SkillBook.lua and Lifestyle. The server-lua phase does `SkillBook = {}`
-- (reset) when it loads; entries registered earlier (e.g. a shared OnGameBoot) get
-- wiped. Registering here, in the same phase, after the reset, makes them stick --
-- and lua/server still loads on dedicated clients (that's how vanilla's table is
-- present client-side at all).
--
-- UNCONDITIONAL (not gated by sandbox): the item always carries SkillTrained, so
-- the table entry must always exist. The sandbox category only gates the WRITE
-- menu. Skip if another mod already owns the skill (SPEC §10.3) -> never overwrite.

require "SBW_Config"

SkillBook = SkillBook or {}

for _, cat in pairs(SBW.booklessCategories) do
    local m = cat.multipliers
    for _, skill in ipairs(cat.skills) do
        local perk = SBW.perkBySkill[skill]
        if perk and SkillBook[skill] == nil then
            SkillBook[skill] = {
                perk = perk,
                maxMultiplier1 = m[1], maxMultiplier2 = m[2],
                maxMultiplier3 = m[3], maxMultiplier4 = m[4],
                maxMultiplier5 = m[5],
            }
        end
    end
end
