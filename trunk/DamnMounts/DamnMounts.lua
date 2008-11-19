local DM = {}

local loadedSetups = {}
local companions = {"critter", "mount"}
local badZones = {["Dalaran"] = true, ["Wintergrasp"] = true}
local subExceptions = {["Krasus' Landing"] = true, ["Purple Parlor"] = true, ["Underbelly"] = true}
local swapQueued, lastRan

local L = {
	["Saved flight setup."] = "Saved flight setup.",
	["Saved city setup."] = "Saved city setup.",
	["Now change to your flight setup and type /dm fly."] = "Now change to your flight setup and type /dm fly.",
	["Now change to your city setup and type /dm city."] = "Now change to your city setup and type /dm city.",
	["Compare ran, your flight and city setups should now swap based on zone. Enjoy."] = "Compare ran, your flight and city setups should now swap based on zone. Enjoy.",
	["Damn Mounts slash commands"] = "Damn Mounts slash commands",
	["/dm fly - Save your mount setup for zones you can fly in."] = "/dm fly - Save your mount setup for zones you can fly in.",
	["/dm city - Save your mount setup for zones you can ride in (Dalaran/Wintergrasp)."] = "/dm city - Save your mount setup for zones you can ride in (Dalaran/Wintergrasp).",
}

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

-- Companions don't work with GetActionInfo, so we have to use this to identify them
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
			
			if( text == DamnMountsTooltip:GetText() ) then
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

-- Save our flying mount macro
function DM:SaveFlying()
	local setup = self:SaveSetup()
	loadedSetups.flying = setup
	lastRan = "flying"
	
	self:Print(L["Saved flight setup."])

	if( loadedSetups.city ) then
		self:CompareAndSave()
	else
		self:Print(L["Now change to your city setup and type /dm city."])
	end
end

-- Save our ground mount macro
function DM:SaveCity()
	local setup = self:SaveSetup()
	loadedSetups.city = setup
	lastRan = "city"
	
	self:Print(L["Saved city setup."])

	if( loadedSetups.flying ) then
		self:CompareAndSave()
	else
		self:Print(L["Now change to your flight setup and type /dm fly."])
	end
end

-- Compares the two saved setups
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
	
	self:Print(L["Compare ran, your flight and city setups should now swap based on zone. Enjoy."])
	self:CheckStatus()
end

-- Actually move the action
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
					return
				end
			end
		elseif( type == "mount" ) then
			PickupCompanion(type, id)
			PlaceAction(actionID)
			ClearCursor()
			return
		end
	end
end

-- Swap it based on where we are
function DM:SwapSetup()
	if( DamnMountsDB.canFly ) then
		self:PlaceAction(DamnMountsDB.flying)
	else
		self:PlaceAction(DamnMountsDB.city)
	end
end

-- Check if we need to swap
function DM:CheckStatus()
	-- Make sure we can't fly in our current zone/sub zone.
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
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:SetScript("OnEvent", function(self, event, addon)
	-- Keep track of macro changes, this way we know if the mount macros saved were changed, and we need to update them
	-- really I should hook EditMacro, which I might do next.
	if( event == "ADDON_LOADED" and addon == "Blizzard_MacroUI" ) then
		local orig_MacroFrame_SaveMacro = MacroFrame_SaveMacro
		MacroFrame_SaveMacro = function(...)
			if( not MacroFrame.textChanged or not MacroFrame.selectedMacro ) then
				orig_MacroFrame_SaveMacro(...)
				return
			end
			
			-- Save the original text
			local originalText = DM:CompressText(select(3, GetMacroInfo(MacroFrame.selectedMacro)))

			-- Now call it so it modifies the macro with the new text
			orig_MacroFrame_SaveMacro(...)
			
			-- Annd now search for the macro to see if we had this one added
			for profileType, list in pairs(DamnMountsDB) do
				if( type(list) == "table" ) then
					for actionID, data in pairs(list) do
						local type, id, text = string.split(":", data)
						if( type == "macro" ) then
							if( text == originalText ) then
								-- Get the new text
								text = DM:CompressText(MacroFrameText:GetText())
								DamnMountsDB[profileType][actionID] = string.format("%s:%s:%s", type, id, text)
							end
						end
					end
				end	
			end
		end
	
	-- If we have a swap queued, do it now
	elseif( event ==  "PLAYER_REGEN_ENABLED" ) then
		if( swapQueued ) then
			DM:SwapSetup()
			swapQueued = nil
		end
	
	-- Check if we need to swap
	elseif( event == "ZONE_CHANGED" or event == "PLAYER_ENTERING_WORLD" ) then
		DM:CheckStatus()
	end
end)

-- Slash commands
SLASH_DAMNMOUNTS1 = "/dm"
SLASH_DAMNMOUNTS2 = "/damnmounts"
SlashCmdList["DAMNMOUNTS"] = function(msg)
	if( msg == "city" ) then
		DM:SaveCity()
	elseif( msg == "fly" ) then
		DM:SaveFlying()
	else
		DEFAULT_CHAT_FRAME:AddMessage(L["Damn Mounts slash commands"])
		DEFAULT_CHAT_FRAME:AddMessage(L["/dm fly - Save your mount setup for zones you can fly in."])
		DEFAULT_CHAT_FRAME:AddMessage(L["/dm city - Save your mount setup for zones you can ride in (Dalaran/Wintergrasp)."])
	end
end