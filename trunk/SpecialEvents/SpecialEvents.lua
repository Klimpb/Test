local major = "SpecialEvents-Alpha0"
local minor = tonumber(string.match("$Revision: 604 $", "(%d+)") or 1)

assert(LibStub, string.format("%s requires LibStub.", major))

local SpecialEvents, oldInstance = LibStub:NewLibrary(major, minor)
if( not SpecialEvents ) then return end

local frame
local tooltip

-- Basic stuffs
local function assert(level,condition,message)
	if( not condition ) then
		error(message,level)
	end
end

local function argcheck(value, num, ...)
	if( type(num) ~= "number" ) then
		error(L["BAD_ARGUMENT"]:format(2, "argcheck", "number", type(num)), 1)
	end

	for i=1,select("#", ...) do
		if( type(value) == select(i, ...) ) then return end
	end

	local types = string.join(", ", ...)
	local name = string.match(debugstack(2,2,0), ": in function [`<](.-)['>]")
	error(L["BAD_ARGUMENT"]:format(num, name, types, type(value)), 3)
end

local function scanBuffTooltip(slot)
	tooltip:ClearLines()
	tooltip:SetInventoryItem("player", slot)
	
	for i=1, tooltip:NumLines() do
		local line = getglobal(major .. "TooltipTextLeft" .. i):GetText()
		if( line ) then
			local name = string.match(line, "^([^%(]+) %(%d+ [^%)]+%)$")
			if( name ) then
				return name
			end
		end
	end
	
	return nil
end

-- Library
function SpecialEvents:PLAYER_ENTERING_WORLD()
	self:UNIT_MODEL_CHANGED("player")
	frame:UnregisterEvent("PLAYER_ENTERING_WORLD")
end

local oldMHName, oldMHExpiration, oldOHName, oldOHExpiration
function SpecialEvents:UNIT_MODEL_CHANGED(unit)
	if( unit == "player" ) then
		local hasMH, MHExpiration, _, hasOH, OHExpiration = GetWeaponEnchantInfo()
		
		if( hasMH ) then
			local name = scanBuffTooltip(GetInventorySlotInfo("MainHandSlot"))
			
			-- Replaced buff (or new one)
			if( name ~= oldMHName ) then
			elseif( oldMHExpiration and MHExpiration > oldMHExpiration ) then
			end
			
			oldMHName = name
			oldMHExpiration = MHExpiration
			
		-- Temp MH faded
		elseif( oldMHName ) then
			oldMHName = nil
			oldMHExpiration = nil
		end
		
		if( hasOH ) then
			local name = scanBuffTooltip(GetInventorySlotInfo("SecondaryHandSlot"))

			-- Replaced the buff (or new one)
			if( name ~= oldOHName ) then
			
			-- We refreshed it with the same one
			elseif( oldOHExpiration and OHExpiration > oldOHExpiration ) then
			
			end

			oldOHName = name
			oldOHExpiration = OHExpiration

		-- Temp OH faded
		elseif( oldOHName ) then
			oldOHName = nil
			oldOHExpiration = nil
		end
	end
end

-- Upgrade
local function instanceLoaded()
	if( oldInstance ) then
		frame = oldInstance.frame or frame
		tooltip = oldInstance.tooltip or tooltip
	else
		-- Library!
		frame = CreateFrame("Frame")
		frame:RegisterEvent("PLAYER_ENTERING_WORLD")
		frame:RegisterEvent("UNIT_MODEL_CHANGED")
		frame:SetScript("OnEvent", function(self, event, ...)
			SpecialEvents[event](SpecialEvents, ...)
		end)
		
		tooltip = CreateFrame("GameTooltip", major .. "Tooltip", UIParent, "GameTooltipTemplate")
		tooltip:SetOwner(UIParent, "ANCHOR_NONE")
	end
	
	SpecialEvents.frame = frame
	SpecialEvents.tooltip = tooltip
end

instanceLoaded()