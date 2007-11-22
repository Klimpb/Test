local AB = SSPVP:NewModule("AB", "AceEvent-3.0")
AB.activeIn = "ab"

local L = SSPVPLocals

local timers = {}

--function SSOverlay:RegisterText(id, category, text, color)
--function SSOverlay:RegisterTimer(id, category, text, seconds, color)
--function SSOverlay:RegisterElapsed(id, category, text, seconds, color)

function AB:OnEnable()
	self.defaults = {
		profile = {
			bases = true,
			finalBase = false,
			matchInfo = true,
		},
	}
	
	self.db = SSPVP.db:RegisterNamespace("ab", self.defaults)
end

function AB:EnableModule()
	self:RegisterEvent("CHAT_MSG_BG_SYSTEM_HORDE", "ParseCombat")
	self:RegisterEvent("CHAT_MSG_BG_SYSTEM_ALLIANCE", "ParseCombat")
end

function AB:DisableModule()
	self:UnregisterAllEvents()
end

function AB:PrintTimer(node, captureTime, faction)
	if( faction == "CHAT_MSG_BG_SYSTEM_HORDE" ) then
		faction = L["Horde"]
	elseif( faction == "CHAT_MSG_BG_SYSTEM_ALLIANCE" ) then
		faction = L["Alliance"]
	end
	
	Debug(string.format(L["[%s] %s: %s"], faction, node, SecondsToTime(captureTime - GetTime())))
end

function AB:ParseCombat(event, msg)
	if( string.match(msg, L["claims the ([^!]+)"]) ) then
		local name = string.match(msg, L["claims the ([^!]+)"])
		local node = SSPVP:ParseNode(name)
		SSOverlay:RegisterTimer(name, "timer", node .. ": %s", 62, SSPVP:GetFactionColor(event))
		SSOverlay:RegisterOnClick(name, self, "PrintTimer", node, GetTime() + 62, event)
	elseif( string.match(msg, L["has assaulted the ([^!]+)"]) ) then
		local name = string.match(msg, L["has assaulted the ([^!]+)"])
		local node = SSPVP:ParseNode(name)
		SSOverlay:RegisterTimer(name, "timer", node .. ": %s", 62, SSPVP:GetFactionColor(event))
		SSOverlay:RegisterOnClick(name, self, "PrintTimer", node, GetTime() + 62, event)
	elseif( string.match(msg, L["has taken the ([^!]+)"]) ) then
		SSOverlay:RemoveRow(string.match(msg, L["has taken the ([^!]+)"]))
	elseif( string.match(msg, L["has defended the ([^!]+)"]) ) then
		SSOverlay:RemoveRow(string.match(msg, L["has defended the ([^!]+)"]))
	end
end