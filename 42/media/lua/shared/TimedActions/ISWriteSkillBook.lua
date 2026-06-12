-- Skill Books - Writing. Copyright 2026 Leandro Ferreira. All rights reserved.
-- See LICENSE: redistribution / modpacks / reupload require written permission.
-- SkillBooksWriting — step 2: write the chosen skill book (SPEC §4.3, §4.4).
-- Plays the read anim while writing; on completion it does NOT create the item
-- itself — it asks the server to (authoritative, anti-cheat). Duration scales
-- with tier via sandbox.

require "TimedActions/ISBaseTimedAction"
require "SBW_Config"

ISWriteSkillBook = ISBaseTimedAction:derive("ISWriteSkillBook")

function ISWriteSkillBook:isValid()
    return self.character:getInventory():contains(self.item)
        and SBW.isWritingAllowed(self.skill)
        and SBW.hasWritingTool(self.character)
end

function ISWriteSkillBook:update()
    self.item:setJobDelta(self:getJobDelta())
end

function ISWriteSkillBook:start()
    self.item:setJobType(getText("IGUI_SBW_Writing", self.perkName))
    self.item:setJobDelta(0.0)
    self:setActionAnim(CharacterActionAnims.Read)
    self:setOverrideHandModels(nil, self.item)
end

function ISWriteSkillBook:stop()
    self.item:setJobDelta(0.0)
    ISBaseTimedAction.stop(self)
end

function ISWriteSkillBook:perform()
    self.item:setJobDelta(0.0)
    -- Server-authoritative: request the write; the server validates + creates + syncs
    -- (SBW_WriteServer). In single-player there's no OnClientCommand, so call directly.
    local args = { skill = self.skill, tier = self.tier, bookType = self.bookType }
    if isClient() then
        sendClientCommand(self.character, SBW.MODULE, "Write", args)
    else
        SBW.writeBook(self.character, args)
    end
    ISBaseTimedAction.perform(self)
end

function ISWriteSkillBook:new(character, item, skill, tier, bookType, perkName, perk)
    local o = ISBaseTimedAction.new(self, character)
    o.item = item
    o.skill = skill
    o.tier = tier
    o.bookType = bookType
    o.perkName = perkName
    o.perk = perk
    o.stopOnWalk = true
    o.stopOnRun = true

    local sv = SandboxVars and SandboxVars.SkillBooksWriting
    local base = (sv and sv.BaseWriteTime) or 1200
    local mult = (sv and sv.TierTimeMultiplier) or 1.6
    o.maxTime = base * (mult ^ ((tier or 1) - 1))
    if character:isTimedActionInstant() then o.maxTime = 1 end
    return o
end
