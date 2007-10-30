Honest = DongleStub("Dongle-1.1"):New("Honest")

local L = HonestLocals
local bonusHonorLog
local killHonorLog

local HonorGainFrames = {}

local activeBF = -1
local crtParsedName
local startHonor
local startTime

function Honest:Enable()
	self.defaults = {
		profile = {
			days = {},
			arena = { lastWeek = 0 },
			honor = {
				totalHonor = 0,
				totalBonus = 0,
				totalKill = 0,
				totalWins = 0,
				totalLoses = 0,
				record = {},
				bonus = {},
				kill = {},
				killed = {},
			},

			lastWin = 0,
			showKilled = true,
			showActual = true,
			showEstimated = true,
			showInfo = true,
		}
	}
	
	self.db = self:InitializeDB("HonestDB", self.defaults)
	self.db:SetProfile(self.db.keys.char)
	
	-- Reset from old Honest format to new
	if( self.db.profile.yesterday or self.db.profile.today ) then
		self.db:ResetDB()
		self:Print(L["Honest upgraded, configuration reset"])
	end
	
	-- Set default day information
	if( not self.db.profile.days[1] ) then
		self.db.profile.days[1] = {}
		for k, v in pairs(self.defaults.profile.honor) do
			self.db.profile.days[1][k] = v
		end
	end

	if( not self.db.profile.days[2] ) then
		self.db.profile.days[2] = {timeOut = 0}
		for k, v in pairs(self.defaults.profile.honor) do
			self.db.profile.days[2][k] = v
		end
	end
	
	-- Slashs
	self.cmd = self:InitializeSlashCommand(L["Honest slash commands"], "Honest", "honest")
	self.cmd:RegisterSlashHandler(L["actual - Toggles showing actual honor gained for kills"], "actual", "ToggleActual")	
	self.cmd:RegisterSlashHandler(L["estimated - Toggles showing estimated honor gained for kills"], "estimated", "ToggleEstimated")	
	self.cmd:RegisterSlashHandler(L["killed - Toggles showing how many times you've killed a person"], "killed", "ToggleKilled")	
	self.cmd:RegisterSlashHandler(L["spent - Toggles showing game information once it ends"], "spent", "ToggleSpent")	
	
	-- Events
	self:RegisterEvent("ADDON_LOADED")
	self:RegisterEvent("UPDATE_BATTLEFIELD_STATUS")
	self:RegisterEvent("CHAT_MSG_COMBAT_HONOR_GAIN")

	self:RegisterEvent("PLAYER_ENTERING_WORLD", "CheckDay")
	self:RegisterEvent("PLAYER_PVP_KILLS_CHANGED", "CheckDay")
	self:RegisterEvent("PLAYER_PVP_RANK_CHANGED", "CheckDay")
	self:RegisterEvent("HONOR_CURRENCY_UPDATE", "CheckDay")

	-- Basic logs
	bonusHonorLog = string.gsub(COMBATLOG_HONORAWARD, "%%d", "([0-9]+)")
	killHonorLog = string.gsub(string.gsub(string.gsub(string.gsub(COMBATLOG_HONORGAIN , "%)", "%%)"), "%(", "%%("), "%%s", "(.+)"), "%%d", "([0-9]+)")
	
	hooksecurefunc("ChatFrame_RemoveMessageGroup", function(frame, type)
		if( type == "COMBAT_HONOR_GAIN" ) then
			HonorGainFrames[frame] = nil
		end
	end)
	
	-- Reposition it for some reason that I don't remember anymore	
	PVPHonorTodayHonor:ClearAllPoints()
	PVPHonorTodayHonor:SetPoint("CENTER", "PVPHonorTodayKills", "BOTTOM", 0, -12)

	-- Hide the "~"
	getglobal("PVPHonorToday~"):Hide()
	
	-- Update PVP frame with our new info, and check for new day
	self:CheckDay()
		
	-- Alright now hook whatevers loaded
	if( IsAddOnLoaded("Blizzard_CombatText") ) then
		self:HookFCT()
	end
	
	if( IsAddOnLoaded("sct") ) then
		self:HookSCT()
	end
end

function Honest:Disable()
	self:UnregisterAllEvents()
end

-- Start times
function Honest:UPDATE_BATTLEFIELD_STATUS()
	for i=1, MAX_BATTLEFIELD_QUEUES do
		local status, map, id, _, _, teamSize, isRated = GetBattlefieldStatus(i)
		
		-- Unique name!
		local parsedName = map
		if( teamSize > 0 ) then
			if( status == "active" and teamSize > 0 ) then
				if( isRated ) then
					parsedName = map .. "R" .. teamSize
				else
					parsedName = map .. "S" .. teamSize
				end
			end
		end
				
		-- Joined a new battlefield, start-zee-timers
		if( status == "active" and i ~= activeBF ) then
			activeBF = i
			crtParsedName = parsedName
			startHonor = self.db.profile.days[1].totalHonor
			startTime = GetTime()
			
			if( not self.db.profile.days[1].record[parsedName] ) then
				self.db.profile.days[1].record[parsedName] = {win = 0, lose = 0, totalTime = 0, rated = isRated, teamSize = teamSize, map = map}
			end

		-- We left a battlefield, check end honor/total time spent and output it if need be
		elseif( status ~= "active" and i == activeBF ) then
			-- We afked out, or left in a means besides it finishing
			-- don't output anything
			if( GetBattlefieldWinner() == nil ) then
				startHonor = nil
				startTime = nil
				activeBF = nil
				crtParsedName = nil
				return
			end
			
			local endHonor = math.abs(self.db.profile.days[1].totalHonor - startHonor)
			local totalTime = math.abs(GetTime() - startTime)
			
			-- Save
			if( totalTime > 0 ) then
				self.db.profile.days[1].record[crtParsedName].totalTime = ( self.db.profile.days[1].record[crtParsedName].totalTime or 0 ) + totalTime
			end
			
			-- Print
			if( self.db.profile.showInfo and endHonor > 0 and totalTime > 0 ) then
				self:Print(string.format(L["Game over! Honor gained %d, time spent %s."], endHonor, SecondsToTime(totalTime)))
			end
			
			-- Delete
			startHonor = nil
			startTime = nil
			activeBF = nil
			crtParsedName = nil
		end
	end
end

-- Load order is screwy sometimes, and CT is LoD
function Honest:ADDON_LOADED(event, addon)
	if( addon == "sct" ) then
		self:HookSCT()
	elseif( addon == "Blizzard_CombatText" ) then
		self:HookFCT()
	end
end

-- Block honor gained messages from Blizzard_CombatText and sct
local Orig_CombatText_OnEvent;
local function FCT_CombatText_OnEvent(event, ...)
	if( event == "HONOR_GAINED" ) then
		return
	end
	
	Orig_CombatText_OnEvent(event, ...)
end

function Honest:BlizzardCombatTextEvent(event, ...)
	if( event == "HONOR_GAINED" ) then
		return
	end
	
	Honest.Orig_BlizzardCombatTextEvent(SCT, event, ...)
end

-- Hook honor gained functions for blocking
function Honest:HookSCT()
	if( SCT and SCT.BlizzardCombatTextEvent ) then
		Honest.Orig_BlizzardCombatTextEvent = SCT.BlizzardCombatTextEvent
		SCT.BlizzardCombatTextEvent = Honest.BlizzardCombatTextEvent
	end
end

function Honest:HookFCT()
	if( CombatText_OnEvent ) then
		Orig_CombatText_OnEvent = CombatText_OnEvent
		CombatText_OnEvent = FCT_CombatText_OnEvent
	end
end

-- Rating -> Points
local pointPenalty = {[5] = 1.0, [3] = 0.88, [2] = 0.76}
local function GetPoints(rating, teamSize)
	local penalty = pointPenalty[teamSize]
	
	local points = 0
	if( rating > 1500 ) then
		points = (1511.26 / (1 + 1639.28 * math.exp(1) ^ (-0.00412 * rating))) * penalty
	else
		points = ((0.22 * rating ) + 14) * penalty
	end
	
	if( points < 0 ) then
		points = 0
	end
	
	return points
end

-- Copies a table over
local function copyTable(copyFrom)
	-- Don't copy anything!
	if( not copyFrom ) then
		return nil
	end
	
	local copyTo = {}
	for k, v in pairs(copyFrom) do
		if( type(v) == "table" ) then
			copyTo[k] = copyTable(v)
		else
			copyTo[k] = v
		end
	end
	
	return copyTo
end

-- Check if arena reset, and work out how many points we gained
function Honest:CheckArenaReset()
	local self = Honest
	
	-- Only show the message if we gained points, HOPEFULLY
	-- this will mean it only shows on reset and not when we spend points
	if( GetArenaCurrency() > self.db.profile.arena.lastWeek ) then
		local pointsTeam, pointsBracket, pointsStanding
		local teamPoints = 0
		local highestPoints = 0
		
		-- Figure out where we got the points from
		for i=1, MAX_ARENA_TEAMS do
			local teamName, teamSize, teamRating, _, _, _, _, _, _, teamStanding = GetArenaTeam(i)

			if( teamName ) then
				local teamPoints = 0
				local points = GetPoints(teamRating, teamSize)
				
				if( points > highestPoints ) then
					pointsTeam = teamName
					pointsBracket = teamSize
					pointsStanding = teamStanding
					
					highestPoints = points
				end
			end
		end
				
		-- Double check, make sure we actually got the data
		if( pointsTeam ) then
			self:Print(string.format(L["Arena has reset! You gained %d points from %s (%dvs%d), for a total of %d, standing #%d."], highestPoints, pointsTeam, pointsBracket, pointsBracket, GetArenaCurrency(), pointsStanding))
		else
			self:Print(string.format(L["Arena has reset! You gained %d points, for a total of %d."], (GetArenaCurrency() - self.db.profile.arena.lastWeek), GetArenaCurrency()))
		end
	end

	self.db.profile.arena.lastWeek = GetArenaCurrency()
end

-- Check if our day reset
function Honest:CheckDay()
	-- Check arena
	if( GetArenaCurrency() ~= self.db.profile.arena.lastWeek ) then
		for i=1, MAX_ARENA_TEAMS do
			ArenaTeamRoster(i)
		end
		
		-- Not very clean, but waiting for even firing is inaccurate
		self:ScheduleTimer("HONESTARENA", self.CheckArenaReset, 2)
	end
	
	-- Check honor
	local yestHonor = select(2, GetPVPYesterdayStats())
	if( yestHonor ~= self.db.profile.days[2].totalHonor or ( self.db.profile.days[2].timeOut > 0 and self.db.profile.days[2].timeOut <= time() ) ) then
		local todayHonor = self.db.profile.days[1].totalHonor
		local diff = math.abs(yestHonor - todayHonor)
		local diffPerc
		
		-- Figure out how much we were off by
		if( yestHonor < todayHonor ) then
			diffPerc = yestHonor / todayHonor
		else
			diffPerc = todayHonor / yestHonor
		end
		
		if( todayHonor > 0 and yestHonor > 0 ) then
			self:Print(string.format(L["Honor has reset! Estimated %d, Actual %d, Difference %d (%.2f%% off)"], todayHonor, yestHonor, diff, (100 - diffPerc * 100)))
	
			-- Shift everything down so we only have 7 days worth of data at any time
			Honest.db.profile.days[7] = copyTable(Honest.db.profile.days[6])
			Honest.db.profile.days[6] = copyTable(Honest.db.profile.days[5])
			Honest.db.profile.days[5] = copyTable(Honest.db.profile.days[4])
			Honest.db.profile.days[4] = copyTable(Honest.db.profile.days[3])
			Honest.db.profile.days[3] = copyTable(Honest.db.profile.days[2])
		end

		Honest.db.profile.days[2] = copyTable(Honest.db.profile.days[1])
				
		-- Now reset the current day
		self.db.profile.days[1] = {}
		for k, v in pairs(self.defaults.profile.honor) do
			self.db.profile.days[1][k] = v
		end
		
		-- Date that this is from, so we can show it in the dropdown
		self.db.profile.days[1].date = time()
		
		-- Reset honor automatically after 26 hours
		-- Reset time isn't 100% exact, so pad it out by 2 hours
		self.db.profile.days[2].timeOut = time() + (60 * 60 * 26)
		self.db.profile.days[2].totalHonor = yestHonor
		
		-- Update our saved honor
		PVPHonor_Update()
	end
end

-- Figure out where we are
function Honest:GetLocation()
	local status, map, teamSize
	for i=1, MAX_BATTLEFIELD_QUEUES do
		status, map, _, _, _, teamSize, isRated = GetBattlefieldStatus(i)
		
		if( status == "active" and teamSize > 0 ) then
			if( isRated ) then
				return map .. "R" .. teamSize, map, teamSize, isRated			
			else
				return map .. "S" .. teamSize, map, teamSize, isRated
			end
		end
	end
	
	return GetRealZoneText() or L["Unknown"]
end

function Honest:AddHonor(amount, type)
	-- Save!
	self.db.profile.days[1][type][self:GetLocation()] = (self.db.profile.days[1][type][self:GetLocation()] or 0) + amount
	
	if( type == "bonus" ) then
		self.db.profile.days[1].totalBonus = (self.db.profile.days[1].totalBonus or 0) + amount
		self.db.profile.days[1].totalHonor = self.db.profile.days[1].totalHonor + amount
	elseif( type == "kill" ) then
		self.db.profile.days[1].totalKill = (self.db.profile.days[1].totalKill or 0) + amount
		self.db.profile.days[1].totalHonor = self.db.profile.days[1].totalHonor + amount
	end
	
	-- Show it in SCT
	if( IsAddOnLoaded("sct") and SCT.db.profile.SHOWHONOR ) then
		SCT:Display_Event("SHOWHONOR", "+" .. math.floor(amount) .. " " .. HONOR)
		
	-- Show it in FCT
	elseif( IsAddOnLoaded("Blizzard_CombatText") ) then
		-- Haven't cached the movement function yet
		if( not COMBAT_TEXT_SCROLL_FUNCTION ) then
			CombatText_UpdateDisplayedMessages()
		end
		
		CombatText_AddMessage(string.format(COMBAT_TEXT_HONOR_GAINED, math.floor(amount)), COMBAT_TEXT_SCROLL_FUNCTION, COMBAT_TEXT_TYPE_INFO["HONOR_GAINED"].r, COMBAT_TEXT_TYPE_INFO["HONOR_GAINED"].g, COMBAT_TEXT_TYPE_INFO["HONOR_GAINED"].b, COMBAT_TEXT_TYPE_INFO["HONOR_GAINED"].var, COMBAT_TEXT_TYPE_INFO["HONOR_GAINED"].isStaggered)
	end
end

function Honest:CHAT_MSG_COMBAT_HONOR_GAIN(event, msg)
	self:CheckDay()
	
	if( string.match(msg, killHonorLog) ) then
		local name, _, honor = string.match(msg, killHonorLog)
		local actualHonor = 0
		
		if( self.db.profile.days[1].killed[name] ) then
			-- We have killed them at least once, so apply diminishing
			if( self.db.profile.days[1].killed[name] < 10 ) then
				actualHonor = honor * (1.0 - ((self.db.profile.days[1].killed[name] - 1) / 10))
			end
						
			self.db.profile.days[1].killed[name] = self.db.profile.days[1].killed[name] + 1
		else
			-- Haven't killed them yet, so estimated is our actual
			actualHonor = honor
			self.db.profile.days[1].killed[name] = 1
		end
		
		-- Figure out if we should use short names or long
		local optionsEnabled = 0
		if( self.db.profile.showKilled ) then optionsEnabled = optionsEnabled + 1 end
		if( self.db.profile.showEstimated ) then optionsEnabled = optionsEnabled + 1 end
		if( self.db.profile.showActual ) then optionsEnabled = optionsEnabled + 1 end
		
				
		local options = {}
		
		-- Show total honor without diminishing returns
		if( self.db.profile.showEstimated ) then
			if( optionsEnabled > 2 ) then
				table.insert(options, string.format(L["Estimated: %d"], honor))
			else
				table.insert(options, string.format(L["Estimated Honor Points: %d"], honor))
			end
		end
		
		-- Show actual honor with diminishing returns
		if( self.db.profile.showActual ) then
			if( optionsEnabled > 2 ) then
				table.insert(options, string.format(L["Actual: %d"], honor))
			else
				table.insert(options, string.format(L["Actual Honor Points: %d"], math.floor(actualHonor)))
			end
		end
		
		-- Kill honor
		if( self.db.profile.showKilled ) then
			table.insert(options, string.format(L["Killed: %d"],  self.db.profile.days[1].killed[name]))
		end
				
		-- If you have no options enabled, just show he died
		if( optionsEnabled > 0 ) then
			msg = string.format(L["%s dies, honorable kill (%s)"], name, table.concat(options, ", "))
		else
			msg = string.format(L["%s dies, honorable kill"], name)
		end
		
		-- Record honor
		self:AddHonor(actualHonor, "kill")
		
		-- Display it in all registered frames
		for frame, _ in pairs(HonorGainFrames) do
			frame:AddMessage(msg, ChatTypeInfo["COMBAT_HONOR_GAIN"].r, ChatTypeInfo["COMBAT_HONOR_GAIN"].g, ChatTypeInfo["COMBAT_HONOR_GAIN"].b)
		end
	
	-- Bonus honor
	elseif( string.match(msg, bonusHonorLog) ) then
		local honor = string.match(msg, bonusHonorLog)
		
		-- Record honor
		self:AddHonor(honor, "bonus")
		
		-- Display it in all registered frames
		for frame, _ in pairs(HonorGainFrames) do
			frame:AddMessage(msg, ChatTypeInfo["COMBAT_HONOR_GAIN"].r, ChatTypeInfo["COMBAT_HONOR_GAIN"].g, ChatTypeInfo["COMBAT_HONOR_GAIN"].b)
		end
	end
end

-- Record win/loses
local Orig_WorldStateScoreFrame_Update = WorldStateScoreFrame_Update
function WorldStateScoreFrame_Update(...)
	Orig_WorldStateScoreFrame_Update(...)
	
	-- Make sure we've won, and that we aren't at the threshold of 2 minutes
	if( not GetBattlefieldWinner() or ( Honest.db.profile.lastWin > 0 and Honest.db.profile.lastWin > GetTime() ) ) then
		return
	end
	
	-- Shhh, nobodies allowed to win in 2 minutes >_> <_< >_>
	Honest.db.profile.lastWin = GetTime() + 120
	
	-- Figure out player faction so we know if they won or lost
	local playerTeam
	for i=1, GetNumBattlefieldScores() do
		local name, _, _, _, _, faction = GetBattlefieldScore(i)
		
		if( name == UnitName("player") ) then
			playerTeam = faction
			break
		end
	end
	
	local location, unparsedMap, teamSize, isRegistered = Honest:GetLocation()

	-- No record found for this battleground yet
	if( not Honest.db.profile.days[1].record[location] ) then
		Honest.db.profile.days[1].record[location] = {win = 0, lose = 0, totalTime = 0, rated = isRegistered, teamSize = teamSize, map = unparsedMap}
	end
	
	if( playerTeam == GetBattlefieldWinner() ) then
		Honest.db.profile.days[1].totalWins = Honest.db.profile.days[1].totalWins + 1
		Honest.db.profile.days[1].record[location].win = Honest.db.profile.days[1].record[location].win + 1
	else
		Honest.db.profile.days[1].totalLoses = Honest.db.profile.days[1].totalLoses + 1
		Honest.db.profile.days[1].record[location].lose = Honest.db.profile.days[1].record[location].lose + 1
	end
end

-- Block all honor gain messages
local Orig_ChatFrame_MessageEventHandler = ChatFrame_MessageEventHandler
function ChatFrame_MessageEventHandler(event, ...)
	if( event == "CHAT_MSG_COMBAT_HONOR_GAIN" ) then
		HonorGainFrames[this] = true
		return true
	end
	
	return Orig_ChatFrame_MessageEventHandler(event, ...)
end

-- Hide our frame when the PVP team info one is shown
local Orig_PVPTeamDetails_OnShow = PVPTeamDetails_OnShow
function PVPTeamDetails_OnShow(...)
	Orig_PVPTeamDetails_OnShow(...)

	if( PVPFrame:IsShown() and Honest.frame ) then
		Honest.frame:Show()
	end
end

local Orig_PVPTeamDetails_OnHide = PVPTeamDetails_OnHide
function PVPTeamDetails_OnHide(...)
	Orig_PVPTeamDetails_OnHide(...)

	if( Honest.frame ) then
		Honest.frame:Hide()
	end
end

-- Change Blizzard estimated honor to our estimated honor
local Orig_PVPHonor_Update = PVPHonor_Update
function PVPHonor_Update(...)
	Orig_PVPHonor_Update(...)
	
	PVPHonorTodayHonor:SetText(math.floor(Honest.db.profile.days[1].totalHonor + 0.5))	
	PVPHonorTodayHonor:SetWidth(PVPHonorTodayHonor:GetStringWidth() + 15)
	
	-- Show blizzards estimation in the tooltip
	if( not PVPHonorTodayHonorFrame.isHooked ) then
		PVPHonorTodayHonorFrame.isHooked = true
		PVPHonorTodayHonorFrame:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText(string.format(L["Blizzard Estimation: %d"], select(2, GetPVPSessionStats())) , nil, nil, nil, nil, 1)
			GameTooltip:Show()
		end)
	end
end

-- Slash commands
function Honest:ToggleSpent()
	self.db.profile.showInfo = not self.db.profile.showInfo
	
	if( self.db.profile.showInfo ) then
		self:Print(string.format(L["Showing total honor gained and time spent is now %s"], L["on"]))
	else
		self:Print(string.format(L["Showing total honor gained and time spent is now %s"], L["off"]))	
	end
end

function Honest:ToggleActual()
	self.db.profile.showActual = not self.db.profile.showActual
	
	if( self.db.profile.showActual ) then
		self:Print(string.format(L["Actual honor gains is now %s"], L["on"]))
	else
		self:Print(string.format(L["Actual honor gains is now %s"], L["off"]))	
	end
end

function Honest:ToggleEstimated()
	self.db.profile.showEstimated = not self.db.profile.showEstimated
	
	if( self.db.profile.showEstimated ) then
		self:Print(string.format(L["Estimated honor gains is now %s"], L["on"]))
	else
		self:Print(string.format(L["Estimated honor gains is now %s"], L["off"]))	
	end
end

function Honest:ToggleKilled()
	self.db.profile.showKilled = not self.db.profile.showKilled
	
	if( self.db.profile.showKilled ) then
		self:Print(string.format(L["Total times killed is now %s"], L["on"]))
	else
		self:Print(string.format(L["Total times killed is now %s"], L["off"]))	
	end
end
