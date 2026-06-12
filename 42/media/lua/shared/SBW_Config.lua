-- Skill Books - Writing. Copyright 2026 Leandro Ferreira. All rights reserved.
-- See LICENSE: redistribution / modpacks / reupload require written permission.
-- SkillBooksWriting — shared config & classification helpers.
-- No game state here: just static data + a couple of pure helpers used by
-- both client (menu gating) and server (write validation, SkillBook table).

SBW = SBW or {}

SBW.MODULE = "SBW"               -- network module name (sendClientCommand)
SBW.EMPTY_BOOK = "SBW.EmptySkillBook"

-- Level needed to WRITE a given tier (SPEC §4.3): 2 * tier.
function SBW.requiredLevelForTier(tier)
    return 2 * tier
end

-- Writing needs a pen/pencil in the inventory (anything tagged base:write --
-- Pen, Pencil, BluePen, RedPen...). SPEC §2.5.
function SBW.hasWritingTool(character)
    return character:getInventory():containsTagRecurse(ItemTag.WRITE)
end

-- Curated skills that have NO SkillBook in vanilla (SPEC §5), grouped by the
-- sandbox toggle that enables them. Multipliers feed the SkillBook[] entry that
-- makes *reading* give XP. Passives get bigger multipliers (SPEC §7-D): they
-- only earn XP from physical training in small, decaying increments.
SBW.booklessCategories = {
    Passive = {
        sandbox = "AllowPassiveSkillBooks",
        skills = { "Strength", "Fitness", "Sprinting", "Lightfoot", "Nimble", "Sneak" },
        multipliers = { 5, 8, 12, 16, 20 },
    },
    Combat = {
        sandbox = "AllowCombatSkillBooks",
        skills = { "Axe", "Blunt", "SmallBlunt", "SmallBlade", "Spear" },
        multipliers = { 3, 5, 8, 12, 16 },   -- same as vanilla; combat earns XP normally
    },
}

-- Perk per bookless skill. Explicit (not Perks[name]) to avoid the
-- SkillTrained-string vs perk-name mismatch the SPEC warns about (§2.1, §3.1).
SBW.perkBySkill = {
    Strength = Perks.Strength, Fitness = Perks.Fitness, Sprinting = Perks.Sprinting,
    Lightfoot = Perks.Lightfoot, Nimble = Perks.Nimble, Sneak = Perks.Sneak,
    Axe = Perks.Axe, Blunt = Perks.Blunt, SmallBlunt = Perks.SmallBlunt,
    SmallBlade = Perks.SmallBlade, Spear = Perks.Spear,
}

-- The 24 skills that DO have a vanilla SkillBook (XPSystem_SkillBook.lua). Used
-- only to classify a scanned book as vanilla vs modded for the sandbox toggles.
SBW.vanillaSkills = {}
for _, s in ipairs({
    "Aiming", "Blacksmith", "Butchering", "Carpentry", "Carving", "Cooking",
    "Electricity", "Farming", "FirstAid", "Fishing", "FlintKnapping", "Foraging",
    "Glassmaking", "Husbandry", "LongBlade", "Maintenance", "Masonry", "Mechanics",
    "MetalWelding", "Pottery", "Reloading", "Tailoring", "Tracking", "Trapping",
}) do SBW.vanillaSkills[s] = true end

-- Resolve the perk a book trains, robust across vanilla / bookless / modded:
--  1) SkillBook[skill].perk  — authoritative (vanilla Carpentry->Woodwork, Lifestyle, etc.)
--  2) SBW.perkBySkill        — our bookless skills
--  3) Perks.FromString       — modded skills whose perk name equals the SkillTrained string
-- Returns nil if it can't resolve a real perk (skill is then skipped, never crashes).
function SBW.resolvePerk(skill)
    local sb = SkillBook and SkillBook[skill]
    if sb and sb.perk then return sb.perk end
    if SBW.perkBySkill[skill] then return SBW.perkBySkill[skill] end
    local p = Perks.FromString(skill)
    if p then
        local obj = PerkFactory.getPerk(p)
        if obj and obj:getName() and obj:getName() ~= "" then return p end
    end
    return nil
end

-- Is writing a book for `skill` allowed by the current sandbox settings?
-- Used identically on client (to show the menu) and server (to validate).
function SBW.isWritingAllowed(skill)
    local sv = SandboxVars and SandboxVars.SkillBooksWriting
    if not sv then return false end
    for _, cat in pairs(SBW.booklessCategories) do
        for _, s in ipairs(cat.skills) do
            if s == skill then return sv[cat.sandbox] == true end
        end
    end
    if SBW.vanillaSkills[skill] then return sv.AllowWritingVanillaBooks == true end
    return sv.AllowWritingModdedBooks == true
end
