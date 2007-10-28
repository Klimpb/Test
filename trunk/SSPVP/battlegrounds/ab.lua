local AB = SSPVP:NewModule("SSPVP-AB")
AB.activeIn = "ab"

local L = SSPVPLocals
local baseInfo = {[0] = 0, [1] = 0.83, [2] = 1.0, [3] = 1.66, [4] = 3.3, [5] = 30.0}

local Alliance = {}
local Horde = {}

local timers = {}
local dataSent = {}

local lowest
local playerFaction

function AB:EnableModule()
	self:RegisterEvent("UPDATE_WORLD_STATES", "UpdateOverlay")
	self:RegisterEvent("CHAT_MSG_BG_SYSTEM_HORDE", "HordeMessage")
	self:RegisterEvent("CHAT_MSG_BG_SYSTEM_ALLIANCE", "AllianceMessage")

	self:RegisterMessage("SS_ABTIMERS_REQ", "ResponseDelay")
	self:RegisterMessage("SS_ABTIMERS_DATA", "ParseSync")
	
	SSOverlay:AddCategory("ab", L["Timers"], nil, AB, "PrintAllTimers")
	SSOverlay:AddCategory("abinfo", L["Battlefield Info"], nil, AB, "PrintMatchInfo")

	PVPSync:SendMessage("ABTIMERS")
	
	playerFaction = UnitFactionGroup("player")
end

function AB:DisableModule()
	self:UnregisterAllMessages()
	self:UnregisterAllEvents()

	for k, v in pairs(timers) do
		timers[k] = nil
	end
	for k, v in pairs(dataSent) do
		dataSent[k] = nil
	end
	
	
	SSOverlay:RemoveCategory("abinfo")
	SSOverlay:RemoveCategory("ab")
end

function AB:Reload()
	if( not SSPVP.db.profile.timers ) then
		SSOverlay:RemoveCategory("ab")
	elseif( SSPVP:IsPlayerIn("ab") ) then
		PVPSync:SendMessage("ABTIMERS")
	end
	
	if( not SSPVP.db.profile.overlay ) then
		SSOverlay:RemoveCategory("abinfo")
	end
end

-- Print match info
function AB:PrintMatchInfo()
	SSPVP:ChannelMessage(string.format(L["Time Left: %s / Bases to win: %d (A:%d/H:%d)"], SSOverlay:FormatTime(lowest, "minsec"), Alliance.basesWin, Alliance.baseScore, Horde.baseScore))
	SSPVP:ChannelMessage(string.format(L["Final Score (Alliance): %d / Final Score (Horde): %d"], Alliance.final, Horde.final))
end

-- Print all timers!
function AB:PrintAllTimers()
	for name, timer in pairs(timers) do
		SSPVP:PrintTimer(name, timer.endTime, timer.faction)
	end
end

-- Send timers for syncing
function AB:SendTimers()
	local send = {}
	local currentTime = GetTime()
	local faction, seconds

	-- Send data off
	for name, timer in pairs(timers) do
		-- We've already seen the data sent, ignore it.
		if( not dataSent[name] ) then
			seconds = math.floor(timer.endTime - currentTime)
			if( seconds > 0 ) then
				table.insert(send, name .. ":" .. timer.faction .. ":" .. seconds)
			end
		end
	end
	
	-- Reset our saved timers
	timers = {}
	
	if( #(send) > 0 ) then
		PVPSync:SendMessage("ABTIMERS:TIME:T:0," .. table.concat( send, "," ), "BATTLEGROUND")
	end
end

-- Send timers within 1-5 seconds
function AB:ResponseDelay()
	if( not SSPVP.db.profile.ab.timers ) then
		return
	end

	dataSent = {}
	SSPVP:ScheduleTimer("SSABTIMERS", self.SendTimers, math.random(5))
end

-- Parse sync message
function AB:ParseSync(event, ...)
	if( not SSPVP.db.profile.ab.timers ) then
		return
	end
	
	for i=1, select("#", ...) do
		local name, faction, seconds = string.split(":", (select(i, ...)))
		seconds = tonumber(seconds)
		
		-- The first argument was the time it was sent
		-- this was originally used to sync them
		-- so if it took 2-3 before parsing it would be more accurate
		-- but, because of inconsistancies with GetTime() it was removed
		if( i > 1 ) then
			dataSent[name] = true

			-- Not an active timer, fine to remove it.
			if( not timers[name] ) then
				timers[name] = {faction = faction, endTime = GetTime() + seconds}
			
				-- This is mostly for style, uppercase the first letter
				-- farm -> Farm, blacksmith -> Blacksmith and so on
				if( GetLocale() == "enUS" ) then
					name = string.upper(string.sub(name, 0, 1)) .. string.sub(name, 2)
				end
				
				-- Update/display!
				SSOverlay:UpdateTimer("ab", name .. ": %s", seconds, SSOverlay:GetFactionColor(faction))
				SSOverlay:AddOnClick("timer", "ab", name .. ": %s", SSPVP, "PrintTimer", name, GetTime() + seconds, faction)
			end
		end
	end
end

-- Horde event message
function AB:HordeMessage(event, msg)
	self:ParseMessage(msg, "Horde")
end

function AB:AllianceMessage(event, msg)
	self:ParseMessage(msg, "Alliance")
end

-- Parse the event message
function AB:ParseMessage(msg, faction)
	if( not SSPVP.db.profile.ab.timers ) then
		return
	end
	
	-- Someone took an already controlled node
	if( string.match(msg, L["has assaulted the ([^!]+)"]) ) then
		local name = string.match(msg, L["has assaulted the ([^!]+)"])
		timers[name] = {faction = faction, endTime = GetTime() + 62}
		
		-- Uppercase the first letter
		if( GetLocale() == "enUS" ) then
			name = string.upper(string.sub(name, 0, 1)) .. string.sub(name, 2)
		end
		
		SSOverlay:UpdateTimer("ab", name .. ": %s", 62, SSOverlay:GetFactionColor(faction))
		SSOverlay:AddOnClick("timer", "ab", name .. ": %s", SSPVP, "PrintTimer", name, GetTime() + 62, faction)
	
	-- Someone took an uncontrolled node
	elseif( string.match( msg, L["(.+) claims the ([^!]+)"] ) ) then
		local _, name = string.match( msg, L["(.+) claims the ([^!]+)"])
		timers[name] = {faction = faction, endTime = GetTime() + 62}
		
		-- Uppercase the first letter
		if( GetLocale() == "enUS" ) then
			name = string.upper(string.sub(name, 0, 1)) .. string.sub(name, 2)
		end
		
		SSOverlay:UpdateTimer("ab", name .. ": %s", 62, SSOverlay:GetFactionColor(faction))
		SSOverlay:AddOnClick("timer", "ab", name .. ": %s", SSPVP, "PrintTimer", name, GetTime() + 62, faction)
		
	-- Node was taken
	elseif( string.match(msg, L["has taken the ([^!]+)"]) ) then
		local name = string.match(msg, L["has taken the ([^!]+)"])
	
		SSOverlay:RemoveRow("timer", "ab", name .. ": %s")
		timers[name] = nil

	-- Node was defended before it could be captured
	elseif( string.match(msg, L["has defended the ([^!]+)"]) ) then
		local name = string.match(msg, L["has defended the ([^!]+)"])
		
		SSOverlay:RemoveRow("timer", "ab", name .. ": %s")
		timers[name] = nil
	end
end

-- Update match info overlay
function AB:UpdateOverlay()
	SSOverlay:RemoveCategory("abinfo")

	if( not SSPVP.db.profile.ab.overlay ) then
		return
	end
	
	-- Grab info
	local _, _, allianceText = GetWorldStateUIInfo(1)
	local _, _, hordeText = GetWorldStateUIInfo(2)
	
	-- Parse alliance info
	local bases, points = string.match(allianceText, L["Bases: ([0-9]+)  Resources: ([0-9]+)/2000"])
	Alliance.bases = tonumber( bases )
	Alliance.points = tonumber( points )
	Alliance.left = 2000 - points

	Alliance.time = Alliance.left / baseInfo[ Alliance.bases ]
	Alliance.basesWin = 0
	
	-- Now parse horde info
	bases, points = string.match(hordeText, L["Bases: ([0-9]+)  Resources: ([0-9]+)/2000"])
	Horde.bases = tonumber(bases)
	Horde.points = tonumber(points)
	Horde.left = 2000 - points
	Horde.time = Horde.left / baseInfo[Horde.bases]
	Horde.basesWin = 0
	
	-- Game hasn't started yet, just return
	if( Horde.points == 0 and Alliance.points == 0 ) then
		return
	end
	
	-- Find out which side is going to win
	if( Alliance.time < Horde.time ) then
		lowest = Alliance.time
	else
		lowest = Horde.time
	end
	
	-- Add time left
	if( SSPVP.db.profile.ab.timeLeft ) then
		SSOverlay:UpdateTimer("abinfo", L["Time Left: %s"], lowest, SSOverlay:GetFactionColor())
	end
	
	-- Calculate final scores
	Alliance.final = floor((Alliance.points + (lowest * baseInfo[Alliance.bases] + 0.5)) / 10) * 10
	Horde.final = floor((Horde.points + (lowest * baseInfo[Horde.bases] + 0.5)) / 10) * 10
	
	-- Display them
	if( SSPVP.db.profile.ab.finalScore ) then
		SSOverlay:UpdateText("abinfo", L["Final Score: %d"], SSOverlay:GetFactionColor("Alliance"), Alliance.final)
		SSOverlay:UpdateText("abinfo", L["Final Score: %d"], SSOverlay:GetFactionColor("Horde"), Horde.final)
	end
	
	-- Figure out bases to win information
	local enemy, friendly
	if( playerFaction == "Alliance" ) then
		enemy = Horde
		friendly = Alliance
	else
		enemy = Alliance
		friendly = Horde
	end
	
	local baseLowest
	
	for i=1, 5 do
		-- Calculate time left using the base info
		local enemyTime = enemy.left / baseInfo[5 - i]
		local friendlyTime = friendly.left / baseInfo[i]
		if( friendlyTime < enemyTime ) then
			baseLowest = friendlyTime
		else
			baseLowest = enemyTime
		end
		
		-- Calculate final scores using base info
		local enemyFinal = floor((enemy.points + floor(baseLowest * baseInfo[ 5 - i ] + 0.5 )) / 10) * 10
		local friendlyFinal = floor((friendly.points + floor(baseLowest * baseInfo[ i ] + 0.5)) / 10) * 10
		
		-- Will win!
		if( friendlyFinal >= 2000 and enemyFinal < 2000 ) then
			-- Store this for printing match info
			Alliance.basesWin = i
			Horde.basesWin = i
			
			local allianceScore, hordeScore
			if( playerFaction == "Alliance" ) then
				Alliance.baseScore = friendlyFinal
				Horde.baseScore = enemyFinal
			else
				Alliance.baseScore = enemyFinal
				Horde.baseScore = friendlyFinal
			end

			-- Make sure we want to displays it!
			if( SSPVP.db.profile.ab.basesWin ) then
				-- Just show bases to win
				if( not SSPVP.db.profile.ab.basesScore ) then
					SSOverlay:UpdateText("abinfo", L["Bases to win: %d"], SSOverlay:GetFactionColor(), i)
				
				-- Show bases to win + score with those bases
				else
					SSOverlay:UpdateText("abinfo", L["Bases to win: %d (A:%d/H:%d)"], SSOverlay:GetFactionColor(), i, Alliance.baseScore, Horde.baseScore)
				end
			end
			
			break
		end
	end
end
