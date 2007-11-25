local AB = SSPVP:NewModule("AB", "AceEvent-3.0")
AB.activeIn = "ab"

local L = SSPVPLocals

local timers = {}

local pointsSec = {[0] = 0, [1] = 0.83, [2] = 1.0, [3] = 1.66, [4] = 3.3, [5] = 30.0}
local Alliance = {}
local Horde = {}
local Lowest = {}

local playerFaction

function AB:OnEnable()
	self.defaults = {
		profile = {
			timers = true,
			bases = true,
			finalBase = false,
			matchInfo = true,
		},
	}
	
	self.db = SSPVP.db:RegisterNamespace("ab", self.defaults)

	playerFaction = select(2, UnitFactionGroup("player"))
end

function AB:EnableModule()
	if( self.db.profile.timers ) then
		self:RegisterEvent("CHAT_MSG_BG_SYSTEM_HORDE", "ParseCombat")
		self:RegisterEvent("CHAT_MSG_BG_SYSTEM_ALLIANCE", "ParseCombat")
	end
	
	if( self.db.profile.matchInfo or self.db.profile.bases ) then
		self:RegisterEvent("UPDATE_WORLD_STATES")
	end
end

function AB:DisableModule()
	self:UnregisterAllEvents()
	
	for k in pairs(timers) do
		SSOverlay:RemoveRow(k)
		timers[k] = nil
	end
	
	for k in pairs(Alliance) do
		Alliance[k] = nil
		Horde[k] = nil
	end
	
	SSOverlay:RemoveCategory("base")
	SSOverlay:RemoveCategory("match")
end

function AB:Reload()
	if( self.isActive ) then
		self:UnregisterAllEvents()
		self:EnableModule()
	end
end

function AB:PrintTimer(node, captureTime, faction)
	if( faction == "CHAT_MSG_BG_SYSTEM_HORDE" ) then
		faction = L["Horde"]
	elseif( faction == "CHAT_MSG_BG_SYSTEM_ALLIANCE" ) then
		faction = L["Alliance"]
	end
	
	SSPVP:ChannelMessage(string.format(L["[%s] %s: %s"], faction, node, SecondsToTime(captureTime - GetTime())))
end

function AB:ParseCombat(event, msg)
	if( string.match(msg, L["claims the ([^!]+)"]) ) then
		local name = string.match(msg, L["claims the ([^!]+)"])
		local node = SSPVP:ParseNode(name)
		timers[name] = GetTime() + 62
		
		SSOverlay:RegisterTimer(name, "timer", node .. ": %s", 62, SSPVP:GetFactionColor(event))
		SSOverlay:RegisterOnClick(name, self, "PrintTimer", node, timers[name], event)
				
	elseif( string.match(msg, L["has assaulted the ([^!]+)"]) ) then
		local name = string.match(msg, L["has assaulted the ([^!]+)"])
		local node = SSPVP:ParseNode(name)
		timers[name] = GetTime() + 62
		
		SSOverlay:RegisterTimer(name, "timer", node .. ": %s", 62, SSPVP:GetFactionColor(event))
		SSOverlay:RegisterOnClick(name, self, "PrintTimer", node, timers[name], event)
	elseif( string.match(msg, L["has taken the ([^!]+)"]) ) then
		local name = string.match(msg, L["has taken the ([^!]+)"])
		
		timers[name] = nil
		SSOverlay:RemoveRow(name)
	elseif( string.match(msg, L["has defended the ([^!]+)"]) ) then
		local name = string.match(msg, L["has defended the ([^!]+)"])
		
		timers[name] = nil
		SSOverlay:RemoveRow(name)
	end
end

-- Match info
function AB:UPDATE_WORLD_STATES()	
	-- Time left and final score
	local aBases, aPoints = self:GetCrtPoints("Alliance")
	local hBases, hPoints = self:GetCrtPoints("Horde")

	-- Parse error
	if( not aBases or not hBases ) then
		return
	end

	-- No change
	if( ( aBases == Alliance.bases and hBases == Horde.bases ) or ( hBases == 0 and aBases == 0 ) ) then
		return
	end

	Alliance.bases = aBases
	Alliance.points = aPoints
	Alliance.left = 2000 - aPoints
	Alliance.time = Alliance.left / pointsSec[aBases]		

	Horde.bases = hBases
	Horde.points = hPoints
	Horde.left = 2000 - hPoints
	Horde.time = Horde.left / pointsSec[hBases]

	-- Figure out time left in match
	local lowest = min(Horde.time, Alliance.time)

	-- Base final scores off of the time left in match
	Alliance.final = Alliance.points + self:GetEstPoints(lowest, Alliance.bases)
	Horde.final = Horde.points + self:GetEstPoints(lowest, Horde.bases)
	

	-- Match info
	if( self.db.profile.matchInfo ) then
		-- Show finals
		SSOverlay:RegisterText("allfin", "match", string.format(L["Final Score: %d"], Alliance.final), SSPVP:GetFactionColor("Alliance"))
		SSOverlay:RegisterText("horfin", "match", string.format(L["Final Score: %d"], Horde.final), SSPVP:GetFactionColor("Horde"))
		
		-- Show time left
		SSOverlay:RegisterTimer("time", "match", L["Time Left: %s"], lowest, SSPVP:GetFactionColor("Neutral"))
	else
		self:RemoveCategory("match")
	end

	-- Bases to win, and final base to win
	if( self.db.profile.bases and Alliance and Horde ) then
		local enemy, friendly
		if( playerFaction == "Alliance" ) then
			enemy = Horde
			friendly = Alliance
		else
			enemy = Alliance
			friendly = Horde
		end

		for i=1, 5 do
			-- Figure out time left with the base, and scores with that time
			local lowestTime = min(enemy.left / pointsSec[5 - i], friendly.left / pointsSec[i])
			local enemyFinal = enemy.points + self:GetEstPoints(lowestTime, 5 - i)
			local friendlyFinal = friendly.points + self:GetEstPoints(lowestTime, i)

			-- We win with these bases
			if( friendlyFinal >= 2000 and enemyFinal < 2000 ) then
				SSOverlay:RegisterText("win", "match", string.format(L["Bases to win: %d"], i), SSPVP:GetFactionColor("Neutral"))

				--if( self.db.profile.finalBase ) then
				--	SSOverlay:RegisterText("winfin", "match", string.format(L["Base Final: %d"], friendlyFinal), SSPVP:GetFactionColor(playerFaction))
				--end
				break
			end
		end
	else
		SSOverlay:RemoveCategory("base")
	end
end

function AB:GetEstPoints(time, bases)
	if( bases == 0 ) then
		return 0
	end
	
	return floor(((time * pointsSec[bases] + 0.5) / 10)) * 10
end

function AB:GetCrtPoints(faction)
	local text
	if( faction == "Alliance" ) then
		text = select(3, GetWorldStateUIInfo(1))
	elseif( faction == "Horde" ) then
		text = select(3, GetWorldStateUIInfo(2))
	end
	
	-- Invalid
	if( not text ) then
		return
	end

	local bases, points = string.match(text, L["Bases: ([0-9]+)  Resources: ([0-9]+)/2000"])
	points = tonumber(points)
	bases = tonumber(bases)
	
	-- Invalid match
	if( not points or not bases ) then
		return
	end
	
	return bases, points
end