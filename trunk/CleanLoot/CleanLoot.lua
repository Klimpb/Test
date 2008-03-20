CleanLoot = LibStub("AceAddon-3.0"):NewAddon("CleanLoot", "AceEvent-3.0")

local L = CleanLootLocals

function CleanLoot:OnInitialize()
end

function CleanLoot:OnEnable()
end

function CleanLoot:OnDisable()
	self:UnregisterAllEvents()
end