local Graveyard = SSPVP:NewModule("SSPVP-Res")
Graveyard.activeIn = "bg"

local L = SSPVPLocals

function Graveyard:EnableModule()
	SSOverlay:AddCategory("gy", L["Graveyards"], 1)

	self:RegisterEvent("CHAT_MSG_BG_SYSTEM_NEUTRAL")
	self:RegisterEvent("CHAT_MSG_MONSTER_YELL")
	self:RegisterEvent("CHAT_MSG_BG_SYSTEM_HORDE")
	self:RegisterEvent("CHAT_MSG_BG_SYSTEM_ALLIANCE")	
end

function Graveyard:DisableModule()
	self:UnregisterAllEvents()
	SSOverlay:RemoveCategory("gy")
end

function Graveyard:CHAT_MSG_BG_SYSTEM_HORDE(event, msg)
	self:ParseMessage(msg, "Horde")
end

function Graveyard:CHAT_MSG_BG_SYSTEM_ALLIANCE(event, msg)
	self:ParseMessage(msg, "Alliance")
end

function Graveyard:CHAT_MSG_BG_SYSTEM_NEUTRAL(event, msg)
	if( string.match(msg, L["The battle for"]) or string.match(msg, L["battle has begun"]) ) then
	end
end

-- Alterac Valley
function Graveyard:CHAT_MSG_MONSTER_YELL(event, msg, from)
	if( from ~= L["Herald"] ) then
		return
	end

	if( string.match(msg, L["(.+) is under attack!"]) ) then
		local name = string.match(msg, L["(.+) is under attack!"])

	elseif( string.match(msg, L["(.+) was taken by the"]) ) then
		local name = string.match(msg, L["(.+) was taken by the"])
	end
end

function Graveyard:ParseMessage(msg, faction)
	-- Arathi Basin
	if( SSPVP:IsPlayerIn("ab") ) then
		if( string.match(msg, L["has assaulted the ([^!]+)"]) ) then
			local name = string.match(msg, L["has assaulted the ([^!]+)"])

		elseif( string.match(msg, L["has taken the ([^!]+)"]) ) then
			local name = string.match(msg, L["has taken the ([^!]+)"])

		end
	
	-- Eye of the Storm
	elseif( SSPVP:IsPlayerIn("eots") ) then
		if( string.match(msg, L["has lost control of the (.+)!"]) ) then
			local name = string.match( msg, L["has lost control of the (.+)!"])
			
		elseif( string.match(msg, L["has taken control of the (.+)!"]  ) then
			local name = string.match(msg, L["has taken control of the (.+)!"])
		end
	end
end