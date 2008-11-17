DM = {}

local loadedSetups = {}
local lastRan = ""
local companions = {"critter", "mount"}
local badZones = {["Dalaran"] = true, ["Wintergrasp"] = true}
local subExceptions = {["Krasus' Landing"] = true}
local swapQueued

function DM:Print(msg)
	DEFAULT_CHAT_FRAME:AddMessage(string.format("|cff33ff99Damn Mounts|r: %s", msg))
end

-- Text "compression" so it can be stored in our format fine
function DM:CompressText(text)
	text = string.gsub(text, "\n", "/n")
	text = string.gsub(text, "/n$", "")
	text = string.gsub(text, "||", "/124")
	
	return string.trim(text)
end

function DM:UncompressText(text)
	text = string.gsub(text, "/n", "\n")
	text = string.gsub(text, "/124", "|")
	
	return string.trim(text)
end

function DM:GetCompanionInfo(id)
	if( not self.tooltip ) then
		self.tooltip = CreateFrame("GameTooltip", "DamnMountsTooltip", UIParent, "GameTooltipTemplate")
		self.tooltip:SetOwner(UIParent, "ANCHOR_NONE")
	end
	
	self.tooltip:SetAction(id)
	
	local text = DamnMountsTooltip:GetText()
	if( not text ) then
		return
	end
	
	for _, type in pairs(companions) do
		for i=1, GetNumCompanions(type) do
			local id, name, spellID, icon, isActive = GetCompanionInfo(type, i)
			self.tooltip:SetHyperlink(string.format("spell:%d", spellID))
			
			if( text == ABSTooltipTextLeft1:GetText() ) then
				return type, i, text
			end
		end
	end
end

-- Restore a saved profile
function DM:SaveSetup()
	local setup = {}
	
	for id=1, 120 do
		local type, actionID = GetActionInfo(id)
		if( type and actionID ) then
			
			-- actionID == 0 = companion
			if( type == "spell" and actionID == 0 ) then
				local newType, newID, newName = self:GetCompanionInfo(id)
				if( newType ) then
					setup[id] = string.format("%s:%s:%s", newType, newID, newName)
				end
			elseif( type == "macro" ) then
				local name, icon, macro = GetMacroInfo(actionID)
				if( name and icon and macro ) then
					setup[id] = string.format("macro::%s", self:CompressText(macro))
				end
			end
		end
	end
	
	return setup
end

function DM:SaveFlying()
	local setup = self:SaveSetup()
	loadedSetups.flying = setup
	lastRan = "flying"
	self:Print("Saved flying setup.")

	if( loadedSetups.city ) then
		self:CompareAndSave()
		return
	end
end

function DM:SaveCity()
	local setup = self:SaveSetup()
	loadedSetups.city = setup
	lastRan = "city"
	
	self:Print("Saved city setup.")

	if( loadedSetups.flying ) then
		self:CompareAndSave()
		return
	end
end

function DM:CompareAndSave()
	if( not loadedSetups.city or not loadedSetups.flying ) then
		return
	end
	
	-- Reset our saved info
	DamnMountsDB = DamnMountsDB or {flying = {}, city = {}}
	for id, data in pairs(DamnMountsDB.flying) do
		DamnMountsDB.flying[id] = nil
	end
	for id, data in pairs(DamnMountsDB.city) do
		DamnMountsDB.city[id] = nil
	end
	
	-- Now find the differences
	local otherType = lastRan == "city" and "flying" or "city"
	
	for id, actionID in pairs(loadedSetups[lastRan]) do
		if( loadedSetups[otherType][id] ~= actionID ) then
			DamnMountsDB[lastRan][id] = actionID
			DamnMountsDB[otherType][id] = loadedSetups[otherType][id]
		end
	end
		
	-- Reset now
	loadedSetups = {}
	
	self:Print("Ran compare, good to go.")
end

function DM:PlaceAction(list)
	for actionID, data in pairs(list) do
		local type, id, name = string.split(":", data)
		if( type == "macro" ) then
			for i=1, 54 do
				local macro = select(3, GetMacroInfo(i))
				macro = macro and self:CompressText(macro) or nil

				if( name == macro ) then
					PickupMacro(i)
					PlaceAction(actionID)
					ClearCursor()
				end
			end
		elseif( type == "mount" or type == "critter" ) then
			PickupCompanion(type, id)
			PlaceAction(actionID)
			ClearCursor()
		end
	end
end

function DM:SwapSetup()
	if( DamnMountsDB.canFly ) then
		self:PlaceAction(DamnMountsDB.flying)
	else
		self:PlaceAction(DamnMountsDB.city)
	end
end

function DM:CheckStatus()
	local canFly = IsFlyableArea()
	if( badZones[GetRealZoneText()] and not subExceptions[GetSubZoneText()] ) then
		canFly = false
	end
	
	-- Our state changed, either swap our bars or queue it for when we drop combat
	if( DamnMountsDB.canFly ~= canFly ) then
		DamnMountsDB.canFly = canFly

		if( not InCombatLockdown() ) then
			DM:SwapSetup()
		else
			swapQueued = true
		end
	end
end

-- Check if we need to swap anything
local frame = CreateFrame("Frame")
frame:RegisterEvent("ZONE_CHANGED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:SetScript("OnEvent", function(self, event)
	if( event ==  "PLAYER_REGEN_ENABLED" ) then
		if( swapQueued ) then
			DM:SwapSetup()
			swapQueued = nil
		end
		return
	end
	
	DM:CheckStatus()
end)

-- Slash commands
SLASH_DM1 = "/dm"
SlashCmdList["DM"] = function(msg)
	if( msg == "city" ) then
		DM:SaveCity()
	elseif( msg == "flying" ) then
		DM:SaveFlying()
	elseif( msg == "compare" ) then
		DM:CompareAndSave()
	end
end