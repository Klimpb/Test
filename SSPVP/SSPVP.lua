--[[ 
	SSPVP By Shadowd / Amarand from Icecrown (US) PvE
	
	1.x Release: January 26th 2006
	2.x Release: December 27th 2006
	3.x Release: April 9th 2007
]]

SSPVP = DongleStub("Dongle-1.1"):New("SSPVP")
SSPVP.revision = tonumber(string.match("$Revision$", "(%d+)") or 1)

local L = SSPVPLocals

local confirmedPortLeave = {}
local activeBF = {id = -1}
local battlefieldInfo = {}
local queuedUpdates = {}
local confirmedBFLeave
local joiningBF
local joiningAt

local JoinedRaid
local LeftRaid

function SSPVP:Initialize()
	self.defaults = {
		profile = {
			general = {
				enabled = true,
				channel = "BATTLEGROUND",
				directWorld = false,
				sound = "",
				block = false,
				factBalance = true,
			},
			overlay = {
				timer = "minsec",
				locked = false,
				opacity = 1.0,
				border = { r = 0.75, g = 0.75, b = 0.75 },
				background = { r = 0, g = 0, b = 0 },
				textOpacity = 1.0,
				textColor = { r = 1, g = 1, b = 1 },
				categoryColor = { r = 0.75, g = 0.75, b = 0.75 },
				catType = "auto",
				rowPad = 0,
				catPad = 0,
				scale = 1.0,
				displayType = "down",
			},
			positions = {
				overlay = { x = 300, y = 600 },
				arena = { x = 300, y = 600 },
			},
			reformat = {
				blockSpam = true,
				autoAppend = true,
			},
			graveyard = {
				factionOnly = true,
				closetOnly = true,
			},
			mover = {
				world = true,
				score = true,
				capture = true,
				positions = {},
			},
			bf = {
				release = true,
				autoAccept = true,
				releaseSS = false,
				minimap = true,
			},
			score = {
				color = true,
				icon = false,
				level = false,
			},
			queue = {
				enabled = true,
				showEta = true,
				insideField = false,
				etaFormat = "min",
				autoSolo = true,
				autoGroup = false,
			},
			arena = {
				locked = true,
				scale = 0.90,
				petColor = { r = 0.20, g = 0.90, b = 0.20 },
				showID = true,
				showIcon = true,
				showPets = true,
				showTalents = false,
				reportChat = true,
				teamInfo = true,
				unitFrames = true,
				modify = true,
			},
			eots = {
				overlay = true,
				border = true,
				color = true,
				respawn = true,
				carriers = true,
				timeLeft = true,
				finalScore = true,
				towersWin = true,
				towersScore = true,
				captureWin = true,
				totalCaptures = true,
			},
			wsg = {
				border = true,
				color = true,
				carriers = true,
				respawn = true,
				health = true,
				flagElapsed = false,
				flagCapTime = false,
			},
			av = {
				enabled = false,
				overlay = true,
				crystal = false,
				medal = false,
				armor = false,
				interval = 60,
				speed = 0.50,
			},
			ab = {
				timers = true,
				overlay = true,
				timeLeft = true,
				finalScore = true,
				basesWin = true,
				basesScore = true,
			},
			join = {
				enabled = true,
				bgDelay = 10,
				bgAfk = 110,
				arenaDelay = 10,
				type = "less",
			},
			priority = {
				afk = 1,
				instance = 2,
				ratedArena = 3,
				skirmArena = 3,
				eots = 3,
				av = 3,
				ab = 3,
				wsg = 3,
				grouped = 4,
				none = 5,
			},
			leave = {
				enabled = true,
				queueConfirm = true,
				doneConfirm = true,
				screen = false,
				arenaDelay = 0,
				bgDelay = 0,
			},
			turnin = {
				enabled = true,
			},
			modules = {},
			quests = L["TURNQUESTS"],
		}
	}
	
	self.db = self:InitializeDB("SSPVPDB", self.defaults)

	self.cmd = self:InitializeSlashCommand(L["SSPVP commands"], "SSPVP", "sspvp")
	self.cmd:InjectDBCommands(self.db, "delete", "copy", "list", "set")
		
	SSOverlay:AddCategory("general", L["Time before start"], -1)
	SSOverlay:AddCategory("queue", L["Battlefield queues"], 1)
	
	-- For BGReformat
	JoinedRaid = string.format(ERR_RAID_MEMBER_ADDED_S, "(.+)")
	LeftRaid = string.format(ERR_RAID_MEMBER_REMOVED_S, "(.+)")

	-- Grab the list of team mates for the auto arena queue stuff
	for i=1, MAX_ARENA_TEAMS do
		ArenaTeamRoster(i)
	end
end

function SSPVP:Enable()
	self:RegisterEvent("GOSSIP_SHOW")
	self:RegisterEvent("PLAYER_DEAD")
	self:RegisterEvent("CORPSE_IN_RANGE")
	self:RegisterEvent("BATTLEFIELDS_SHOW")
	self:RegisterEvent("CORPSE_OUT_OF_RANGE")
	self:RegisterEvent("PLAYER_REGEN_ENABLED")
	self:RegisterEvent("UPDATE_BATTLEFIELD_STATUS")
	self:RegisterEvent("CHAT_MSG_BG_SYSTEM_NEUTRAL")
	self:RegisterEvent("SCREENSHOT_SUCCEEDED", "ScreenshotTaken")
	self:RegisterEvent("SCREENSHOT_FAILED", "ScreenshotTaken")
	
	-- Enable any "passive" modules
	for name, module in SSPVP:IterateModules() do
		if( not self.db.profile.modules[name] and not module.activeIn and module.EnableModule ) then
			module.moduleEnabled = true
			module.EnableModule(module)
		end
	end
end

function SSPVP:Disable()
	self:DisableAllModules()

	self:UnregisterAllEvents()
	self:UnregisterAllMessages()
	self:UnregisterAllTimers()
	
	SSOverlay:RemoveCategory("general")
	SSOverlay:RemoveCategory("queue")

	confirmBF = {}
	battlefieldInfo = {}
	
	activeBF.id = -1
	joiningBF = nil
	joiningAt = nil
end

function SSPVP:Reload()
	SSPVP:UPDATE_BATTLEFIELD_STATUS()
end

function SSPVP:Message(msg, color)
	if( not color ) then
		DEFAULT_CHAT_FRAME:AddMessage(msg)
	else
		DEFAULT_CHAT_FRAME:AddMessage(msg, color.r, color.g, color.b)
	end
end

-- Block the joined queue message because will show it ourself
local Orig_UIErrorsFrame_OnEvent = UIErrorsFrame_OnEvent
function UIErrorsFrame_OnEvent(event, message, ...)
	if( string.match(message, L["Your group has joined the queue for"]) ) then
		return
	end

	return Orig_UIErrorsFrame_OnEvent(event, message, ...)
end

-- Blocking messages that start with [SS]
local Orig_ChatFrame_MessageEventHandler = ChatFrame_MessageEventHandler
function ChatFrame_MessageEventHandler(event, ...)
	if( SSPVP.db.profile.general.block and ( event == "CHAT_MSG_RAID" or event == "CHAT_MSG_RAID_LEADER" or event == "CHAT_MSG_PARTY" or event == "CHAT_MSG_BATTLEGROUND" or event == "CHAT_MSG_BATTLEGROUND_LEADER" ) ) then
		if( string.sub(arg1, 0, 4) == "[SS]" ) then
			return false
		end
	end
	
	return Orig_ChatFrame_MessageEventHandler(event, ...)
end

-- Confirmation for leaving battlefield queues
local Orig_AcceptBattlefieldPort = AcceptBattlefieldPort
function AcceptBattlefieldPort(id, flag, ...)
	if( not flag and not confirmedPortLeave[id] and SSPVP.db.profile.leave.queueConfirm ) then
		local _, map, _, _, _, teamSize = GetBattlefieldStatus(id)
		if( teamSize > 0 ) then
			StaticPopupDialogs["CONFIRM_PORT_LEAVE"].text = string.format(L["You are about to leave the active or queued arena %s (%dvs%d), are you sure?"], map, teamSize, teamSize)
		else
			StaticPopupDialogs["CONFIRM_PORT_LEAVE"].text = string.format(L["You are about to leave the active or queued battlefield %s, are you sure?"], map)
		end
		
		local popup = StaticPopup_Show("CONFIRM_PORT_LEAVE")
		if( popup ) then
			popup.data = id
		end
		return
	end
	
	confirmedPortLeave[id] = nil
	StaticPopup_Hide("CONFIRM_PORT_LEAVE", id)

	Orig_AcceptBattlefieldPort(id, flag, ...)
end

-- Confirmation for leaving a battlefield
local Orig_LeaveBattlefield = LeaveBattlefield
function LeaveBattlefield(...)
	if( not confirmedBFLeave and SSPVP.db.profile.leave.doneConfirm and this:GetName() ~= "WorldStateScoreFrameLeaveButton" ) then
		-- Find an active battlefield
		local map, status, teamSize
		for i=1, MAX_BATTLEFIELD_QUEUES do
			status, map, _, _, _, teamSize = GetBattlefieldStatus( i )
			if( status == "active" ) then
				break
			end
		end
		
		if( teamSize > 0 ) then
			StaticPopupDialogs["CONFIRM_BATTLEFIELD_LEAVE"].text = string.format(L["You are about to leave the active or queued arena %s (%dvs%d), are you sure?"], map, teamSize, teamSize)
		else
			StaticPopupDialogs["CONFIRM_BATTLEFIELD_LEAVE"].text = string.format(L["You are about to leave the active or queued battlefield %s, are you sure?"], map)
		end
		
		StaticPopup_Show("CONFIRM_BATTLEFIELD_LEAVE")
		return
	end
	
	confirmedBFLeave = nil
	Orig_LeaveBattlefield( ... )
end

-- Block raid join/leaves
local Orig_ChatFrame_SystemEventHandler = ChatFrame_SystemEventHandler
function ChatFrame_SystemEventHandler(event, ...)
	if( activeBF.id > 0 and arg1 and SSPVP.db.profile.reformat.blockSpam and (string.match(arg1, JoinedRaid) or string.match(arg1, LeftRaid) ) ) then
		return true
	end
	
	return Orig_ChatFrame_SystemEventHandler(event, ...)
end

-- Auto append server name
local Orig_SendChatMessage = SendChatMessage
function SendChatMessage(text, type, language, target, ...)
	if( activeBF.id > 0 and target and SSPVP.db.profile.reformat.autoAppend and type == "WHISPER" and not string.match(target, "-") ) then
		local foundName
		local foundPlayers = 0
				
		target = string.lower(target)
		
		for i=1, GetNumBattlefieldScores() do
			local name = GetBattlefieldScore(i)
			
			if( string.match(string.lower(name), "^" .. target) ) then
				foundPlayers = foundPlayers + 1
				foundName = name
			end
		end
		
		-- Nothing found in battlefield scores, scan raid
		if( foundPlayers == 0 ) then
			for i=1, GetNumRaidMembers() do
				local name, server = UnitName( "raid" .. i )
				
				if( server and string.lower(name) == target ) then
					foundName = target .. "-" .. select(2, UnitName("raid" .. i))
					foundPlayers = foundPlayers + 1
				end
			end
		end
		
		-- If we only found one match, set the new name, otherwise discard it
		if( foundPlayers == 1 ) then
			target = foundName
		end
	end
	
	return Orig_SendChatMessage(text, type, language, target, ...)
end

-- Battlefield start time
function SSPVP:CHAT_MSG_BG_SYSTEM_NEUTRAL(event, msg)
	if( string.match(msg, L["2 minute"]) ) then
		SSOverlay:UpdateTimer("general", L["Starting In: %s"], 121)

	elseif( string.match(msg, L["1 minute"]) or string.match(msg, L["One minute until"]) ) then
		SSOverlay:UpdateTimer("general", L["Starting In: %s"], 61)

	elseif( string.match(msg, L["30 seconds"]) or string.match(msg, L["Thirty seconds until"]) ) then
		SSOverlay:UpdateTimer("general", L["Starting In: %s"], 31)

	elseif( string.match(msg, L["Fifteen seconds until"]) ) then
		SSOverlay:UpdateTimer("general", L["Starting In: %s"], 15)
	end
end

-- Auto queue
function SSPVP:BATTLEFIELDS_SHOW()
	local queued = 0
	local shownField = GetBattlefieldInfo()

	for i=1, MAX_BATTLEFIELD_QUEUES do
		local status, map, _, _, _, registeredMatch = GetBattlefieldStatus( i )
		if( status == "queued" or status == "confirm" ) then
			queued = queued + 1
		
		-- We're queued for a registered match already, or queued for this already
		elseif( ( status ~= "none" and shownField == map ) or registeredMatch == 1 ) then
			return
		end
	end
	
	-- Auto select an option in arena queue depending on team mates
	if( shownField == L["All Arenas"] ) then
		if( ( ( GetNumPartyMembers() > 0 ) or ( GetNumRaidMembers() > 0 ) ) and IsPartyLeader() ) then
			local teamTotals = { [2] = 0, [3] = 0, [5] = 0 }
			
			-- Figure out which team we're playing with
			for teamID=1, MAX_ARENA_TEAMS do
				local _, teamSize = GetArenaTeam(teamID)
				if( teamSize > 0 ) then
					teamTotals[teamSize] = 1

					for memberID=1, GetNumArenaTeamMembers(teamID, 1) do
						local playerName = GetArenaTeamRosterInfo(teamID, memberID)

						for partyID=1, GetNumPartyMembers() do
							if( UnitName("party" .. partyID) == playerName ) then
								teamTotals[teamSize] = teamTotals[teamSize] + 1
							end
						end
					end
				end
			end
			
			-- Choose something!
			if( teamTotals[5] == 5 ) then
				ArenaFrame.selection = 3
			elseif( teamTotals[3] == 3 ) then
				ArenaFrame.selection = 2
			elseif( teamTotals[2] == 2 ) then
				ArenaFrame.selection = 1
			end

			ArenaFrame_Update()
		end
	end

	
	-- Max queues, don't bother trying
	if( queued == MAX_BATTLEFIELD_QUEUES ) then
		return
	end
	
	-- Auto 
	if( self.db.profile.queue.autoSolo and GetNumPartyMembers() == 0 and GetNumRaidMembers() == 0 ) then
		JoinBattlefield( GetSelectedBattlefield() )
	elseif( self.db.profile.queue.autoGroup and CanJoinBattlefieldAsGroup() and IsPartyLeader() ) then
		JoinBattlefield( GetSelectedBattlefield(), true )
	end
end

-- Auto skip gossip
function SSPVP:GOSSIP_SHOW()
	if( GossipFrame.buttonIndex ) then
		for i=1, GossipFrame.buttonIndex do
			local gossipText = getglobal("GossipTitleButton" .. i):GetText()
			
			if( gossipText == L["I would like to go to the battleground."] or gossipText == L["I would like to fight in an arena."] or gossipText == L["I wish to join the battle!"] ) then
				getglobal("GossipTitleButton" .. i):Click()	
			end
		end
	end
end

-- Enable any module that needs to be active in a battlefield/bg
function SSPVP:EnableModules(activeBattlefield)
	for name, module in SSPVP:IterateModules() do
		if( not self.db.profile.modules[name] and module.activeIn and not module.moduleEnabled ) then
			-- A battleground refers to WSG, AB, EoTS, AV, while a battlefield refers to WSG, AB, EoTS, AV, Arenas.
			if( module.activeIn == "bf" or ( module.activeIn == "bg" and activeBattlefield ~= "arena" ) or module.activeIn == activeBattlefield ) then
				module.moduleEnabled = true
				module.EnableModule(module)
			end
		end
	end
end

-- Disable all active modules
function SSPVP:DisableAllModules()
	for name, module in SSPVP:IterateModules() do
		if( module.DisableModule and module.moduleEnabled ) then
			module.moduleEnabled = nil
			module.DisableModule(module)
		end
	end
end

-- Battlefield info!
function SSPVP:UPDATE_BATTLEFIELD_STATUS()
	SSOverlay:RemoveCategory("queue")
	for i=1, MAX_BATTLEFIELD_QUEUES do
		local status, map, id, _, _, teamSize, registeredMatch = GetBattlefieldStatus(i)
		
		-- Queue popped
		if( status == "confirm" and battlefieldInfo[map .. teamSize] ~= "confirm" ) then
			battlefieldInfo[map .. teamSize] = status

			self:QueueReady(i, map)
			self:PlaySound()
		
		-- Just joined the queue for a battlefield
		elseif( status == "queued" and battlefieldInfo[map .. teamSize] ~= "queued" ) then
			battlefieldInfo[map .. teamSize] = status

			if( GetBattlefieldTimeWaited(i) <= 1000 ) then
				if( teamSize > 0 ) then
					if( registeredMatch ) then
						self:Print(string.format(L["You are now in the queue for %s Arena (%dvs%d)."], L["Rated"], teamSize, teamSize))
					else
						self:Print(string.format(L["You are now in the queue for %s Arena (%dvs%d)."], L["Skirmish"], teamSize, teamSize))
					end
				else
					self:Print(string.format(L["You are now in the queue for %s."], map))
				end
				
				if( (GetBattlefieldInfo()) == map and BattlefieldFrame:IsShown() ) then
					HideUIPanel(BattlefieldFrame)
				end
			end
		
		-- Just joined a battlefield
		elseif( status == "active" and i ~= activeBF.id ) then
			battlefieldInfo[map .. teamSize] = status
			
			-- Grab data now so we aren't waiting 15 seconds
			RequestBattlefieldScoreData()
			
			-- Basic data
			activeBF.id = i
			activeBF.map = map
			activeBF.teamSize = teamSize
			activeBF.isRegistered = registeredMatch
			activeBF.abbrev = SSPVP:GetBattlefieldAbbrev(map)
			
			-- Unregister our queue to join incase we joined
			-- manually instead of automatically
			if( joiningBF == i ) then
				self:CancelTimer("SSAUTOJOIN")
				
				joiningBF = nil
				joiningAt = nil
			end
			
			-- Joined, get modules/sound finished up/ready
			self:StopSound()
			self:DisableAllModules()
			self:EnableModules(activeBF.abbrev)
			
			-- Pop the battlefield minimap
			if( activeBF.abbrev ~= "arena" ) then
				if( SSPVP.db.profile.bf.minimap ) then
					BattlefieldMinimap_LoadUI()

					if( IsAddOnLoaded("Blizzard_BattlefieldMinimap") ) then
						BattlefieldMinimap:Show()
						BattlefieldMinimap_Update()
					end
				elseif( IsAddOnLoaded("Blizzard_BattlefieldMinimap") ) then
					BattlefieldMinimap:Hide()
				end
			
			-- Don't need it open, hide then!
			elseif( IsAddOnLoaded("Blizzard_BattlefieldMinimap") ) then
				BattlefieldMinimap:Hide()
			end
		
		-- We left the battlefield
		elseif( status ~= "active" and i == activeBF.id ) then
			activeBF.id = -1

			self:DisableAllModules()
			SSOverlay:RemoveRow("timer", "general", L["Starting In: %s"])

			if( IsAddOnLoaded("Blizzard_BattlefieldMinimap") ) then
				BattlefieldMinimap:Hide()
			end
		end
		
		-- No longer a confirmation, so clear out config/joining
		if( status ~= "confirm" and map ) then
			if( id == joiningBF ) then
				joiningBF = nil
				joiningAt = nil
			end
		end
		
		-- Deal with the queue overlay
		if( status ~= "none" and SSPVP.db.profile.queue.enabled and ( activeBF.id == -1 or SSPVP.db.profile.queue.insideField ) ) then
			SSPVP:UpdateQueueOverlay(i)
		end	
	end
	
	-- Do we need to queue auto leave or take a screenshot?
	if( activeBF.id > 0 ) then
		if( not SSPVP.db.profile.queue.insideField ) then
			SSOverlay:RemoveCategory( "queue" )
		end

		if( GetBattlefieldWinner() ) then
			if( self.db.profile.leave.screen and not activeBF.screenShot ) then
				activeBF.screenShot = true
				Screenshot()

			elseif( not self.db.profile.leave.screen and self.db.profile.leave.enabled ) then
				self:QueueBattlefieldLeave()
			end
		end
	end
end

function SSPVP:UpdateQueueOverlay(id)
	local status, map, instanceID, _, _, teamSize, registeredMatch = GetBattlefieldStatus(id)

	if( teamSize > 0 ) then
		local allArena
		
		-- We need to make a copy of all arenas so we can remove the old message
		-- when switching from queue -> confirmation
		if( registeredMatch ) then
			allArena = string.format( L["%s [%s] (%dvs%d)"], L["All Arenas"], L["R"], teamSize, teamSize)
			map = string.format(L["%s [%s] (%dvs%d)"], map, L["R"], teamSize, teamSize )
		else
			allArena = string.format( L["%s [%s] (%dvs%d)"], L["All Arenas"], L["S"], teamSize, teamSize)
			map = string.format(L["%s [%s] (%dvs%d)"], map, L["S"], teamSize, teamSize)
		end
		
		SSOverlay:RemoveRow(nil, "queue", allArena)
	end
	
	SSOverlay:RemoveRow(nil, "queue", map)
	
	if( status == "confirm" ) then
		if( joiningBF == id and joiningAt ) then
			SSOverlay:UpdateTimer("queue", map .. ": " .. L["Joining"] .. " %s", joiningAt - GetTime())
		else
			SSOverlay:UpdateTimer("queue", map .. ": %s", GetBattlefieldPortExpiration(id) / 1000)
		end
	elseif( status == "active" ) then
		local runTime = GetBattlefieldInstanceRunTime()
		if( runTime > 0 ) then
			SSOverlay:UpdateElapsed("queue", map .. ": %s (#%d)", runTime, instanceID)
		else
			SSOverlay:UpdateText("queue", map .. ": #%s", instanceID)
		end
	elseif( status == "queued" ) then
		local etaTime = GetBattlefieldEstimatedWaitTime(id) / 1000
		
		-- Average time before joining a game
		if( SSPVP.db.profile.queue.showEta and etaTime > 0 ) then
			SSOverlay:UpdateElapsed("queue", map .. ": %s (%s)", GetBattlefieldTimeWaited(id) / 1000, SSOverlay:FormatTime(GetBattlefieldEstimatedWaitTime(id) / 1000, SSPVP.db.profile.queue.etaFormat))
		
		-- Nobody has played a game yet so no ETA given
		elseif( SSPVP.db.profile.queue.showEta ) then
			SSOverlay:UpdateElapsed("queue", map .. ": %s (%s)", GetBattlefieldTimeWaited(id) / 1000, L["Unavailable"])
		
		-- Just show time spent in queue
		else
			SSOverlay:UpdateElapsed("queue", map .. ": %s", GetBattlefieldTimeWaited(id) / 1000)
		end
	end
end

-- Theres delay issues if we don't check leaving battlefield before this.
function SSPVP:LeaveBattlefield()
	if( GetBattlefieldWinner() ) then
		local self = SSPVP
		if( self.db.profile.arena.teamInfo and (IsActiveBattlefieldArena()) and select(2, IsActiveBattlefieldArena()) ) then
			local winName, winRating, winPoints
			local loseName, loseRating, losePoints
			local oldRating
			
			for i=0, 1 do
				if( GetBattlefieldWinner() == i ) then
					winName, oldRating, winRating = GetBattlefieldTeamInfo(i)
					winPoints = winRating - oldRating
				else
					loseName, oldRating, loseRating = GetBattlefieldTeamInfo(i)
					losePoints = loseRating - oldRating
				end
			end
			
			if( winName and loseName ) then
				self:Print(string.format(L["%s %d points (%d rating) / %s %d points (%d rating)"], winName, winPoints, winRating, loseName, losePoints, loseRating))
			end
		end
		
		confirmedBFLeave = true
		LeaveBattlefield()
	end
end

-- If the auto leave happens before the screenshots finished then you get a nice
-- screenshot of the loading screen
function SSPVP:ScreenshotTaken()
	if( activeBF.screenShot and self.db.profile.leave.screen ) then
		activeBF.screenShot = nil
		self:QueueBattlefieldLeave()
	end
end

-- Queue battlefield leave
-- Make sure we don't have a battlefield thats ready to be joined
function SSPVP:QueueBattlefieldLeave()
	local active = 0
	local abbrev
	
	for i=1, MAX_BATTLEFIELD_QUEUES do
		local status, map = GetBattlefieldStatus( i )
		
		if( status == "active" ) then
			active = active + 1
			abbrev = self:GetBattlefieldAbbrev(map)
		elseif( status == "confirm" ) then
			SSPVP:Print( string.format( L["The battlefield %s is ready to join, auto leave has been disabled."], map ) )
			return
		end
	end
	
	if( active == 1 ) then
		local delay
		if( abbrev == "arena" ) then
			delay = self.db.profile.leave.arenaDelay
		else
			delay = self.db.profile.leave.bgDelay
		end
		
		
		self:ScheduleTimer("SSAUTOLEAVE", self.LeaveBattlefield, delay)
	end
end

-- Simplifies checks
function SSPVP:GetBattlefieldAbbrev( map )
	if( map == L["Warsong Gulch"] ) then
		return "wsg"
	elseif( map == L["Arathi Basin"]  ) then
		return "ab"
	elseif( map == L["Alterac Valley"] ) then
		return "av"
	elseif( map == L["Eye of the Storm"] ) then
		return "eots"
	elseif( map == L["Blade's Edge Arena"] or map == L["Nagrand Arena"] or map == L["Ruins of Lordaeron"] ) then
		return "arena"
	end
	
	return "none"
end

function SSPVP:MaxBattlefieldPlayers()
	if( activeBF.map == L["Blade's Edge Arena"] or activeBF.map == L["Nagrand Arena"] or activeBF.map == L["Ruins of Lordaeron"] ) then
		return activeBF.teamSize
	elseif( activeBF.map == L["Warsong Gulch"] ) then
		return 10
	elseif( activeBF.map == L["Eye of the Storm"] or activeBF.map == L["Arathi Basin"] ) then
		return 15
	elseif( activeBF.map == L["Alterac Valley"] ) then
		return 40
		
	end
	
	return 0
end

-- Make sure we can actually auto join still
function SSPVP:AutoJoinBattlefield()
	local self = SSPVP
	if( not joiningBF or not self.db.profile.join.enabled ) then
		return		
	end
	
	local currentType, queuedType, priority
	local isInstance, type = IsInInstance()

	-- Figure out our current status
	if( UnitIsAFK("player") ) then
		currentType = "afk"
	elseif( activeBF.id > 0 and activeBF.abbrev == "arena" ) then
		if( activeBF.isRegistered ) then
			currentType = "ratedArena"
		else
			currentType = "skirmArena"
		end
	elseif( activeBF.id > 0 and activeBF.abbrev ) then
		currentType = activeBF.abbrev
	elseif( isInstance and type ~= "pvp" ) then
		currentType = "instance"
	elseif( GetNumPartyMembers() > 0 or GetNumRaidMembers() > 0 ) then
		currentType = "grouped"
	else
		currentType = "none"
	end
	
	local _, joinMap, _, _, _, teamSize, isRated = GetBattlefieldStatus( joiningBF )
	local joinAbbrev = SSPVP:GetBattlefieldAbbrev( joinMap )
	
	if( joinAbbrev == "arena" ) then
		if( isRated ) then
			joinAbbrev = "ratedArena"
		else
			joinAbbrev = "skirmArena"
		end
	end
	
	-- Don't bother trying to auto join if we're already inside
	if( joinAbbrev == activeBF.abbrev ) then
		joiningBF = nil
		joiningAt = nil
		return
	end

	-- Yes, we could compress this down to a single if statement
	-- but it's rather ugly/harder to debug
	local newPriority = self.db.profile.priority[joinAbbrev]
	local currentPriority = self.db.profile.priority[currentType]

	-- This allows us to have two priority modes, one only overrides priorities that are less then the current
	-- the other only overrides ones that are less then or equal, 
	if( ( self.db.profile.join.type == "less" and currentPriority < newPriority ) or ( self.db.profile.join.type == "lseql" and currentPriority <= newPriority ) ) then
		joiningBF = nil
		joiningAt = nil

		SSPVP:Print(string.format(L["You're currently inside/doing something that is a higher priority then %s, auto join disabled." ], joinMap))
		return
	end
	
	AcceptBattlefieldPort(joiningBF, true)
	joiningBF = nil
	joiningAt = nil
end

-- Queues ready, check if we need to queue a timer for it
function SSPVP:QueueReady(id, map)
	local delayType
	if( SSPVP:GetBattlefieldAbbrev(map) == "arena" ) then
		delayType = "arenaDelay"
	else
		if( UnitIsAFK( "player" ) ) then
			delayType = "bgAfk"
		else
			delayType = "bgDelay"
		end
	end
	
	-- Not joining anything else, just register the auto join
	if( not joiningBF ) then
		joiningBF = id
		joiningAt = GetTime() + self.db.profile.join[delayType]

		self:ScheduleTimer("SSAUTOJOIN", self.AutoJoinBattlefield, self.db.profile.join[delayType])

	elseif( joiningBF ~= id ) then
		-- Check if we have a higher priority queue
		local _, joinMap, _, _, _, registeredMatch = GetBattlefieldStatus(id)
		
		-- Yes, we could compress this down to a single if statement
		-- but it's rather ugly/harder to debug
		local newPriority = self.db.profile.priority[SSPVP:GetBattlefieldAbbrev(map)]
		local currentPriority = self.db.profile.priority[SSPVP:GetBattlefieldAbbrev(joinMap)]
		
		if( currentPriority == "arena" ) then
			if( registeredMatch ) then
				currentPriority = "ratedArena"
			else
				currentPriority = "skirmArena"
			end
		end
		
		-- Can't have a higher priority queue if we're already in the same one
		if( currentPriority == newPriority ) then
			return
		end
		
		-- This allows us to have two priority modes, one only overrides priorities that are less then the current
		-- the other only overrides ones that are less then or equal, 
		if( ( self.db.profile.join.type == "less" and currentPriority < newPriority ) or ( self.db.profile.join.type == "lseql" and currentPriority <= newPriority ) ) then
			joiningBF = id
			joiningAt = GetTime() + self.db.profile.join[delayType]
			
			self:ScheduleTimer("SSAUTOJOIN", self.AutoJoinBattlefield, self.db.profile.join[delayType])
			self:Print(string.format(L["Higher priority battlefield found, auto joining %s in %d seconds."], map, self.db.profile.join[delayType]))
		end
	end
	
	SSPVP:UpdateQueueOverlay(id)
end

-- For modules
function SSPVP:IsPlayerIn(type)
	return ( activeBF.abbrev == type )
end

-- Basic channel messages
function SSPVP:ChannelMessage(msg, skipPrefix)
	if( not skipPrefix ) then
		msg = "[SS] " .. msg
	end
	
	if( GetNumRaidMembers() == 0 and GetNumPartyMembers() == 0 ) then
		return
	end
	
	SendChatMessage( msg, self.db.profile.general.channel )
end

-- Formats/cleans up a timer before sending it out
function SSPVP:PrintTimer(name, endTime, faction)
	local secondsLeft = endTime - GetTime()

	if( secondsLeft > 0 and name ) then
		SSPVP:ChannelMessage( string.format( L["[%s] %s: %s"], L[ faction ], name, string.trim( SecondsToTime( secondsLeft ) ) ) )
	end
end

-- Automatic messages SSPVP sends out
function SSPVP:AutoMessage(msg, skipPrefix)
	if( not skipPrefix ) then
		msg = "[SS] " .. msg
	end
	
	if( GetNumRaidMembers() > 0 ) then
		SendChatMessage(msg, "RAID")
	elseif( GetNumPartyMembers() > 0 ) then
		SendChatMessage(msg, "PARTY")
	end
end

-- Sound
function SSPVP:PlaySound()
	if( SSPVP.db.profile.general.sound == "" ) then
		return
	end
	
	SSPVP:StopSound()
	
	if( string.find(SSPVP.db.profile.general.sound, "mp3$") ) then
		PlayMusic("Interface\\AddOns\\SSPVP\\" .. SSPVP.db.profile.general.sound)
	else
		PlaySoundFile("Interface\\AddOns\\SSPVP\\" .. SSPVP.db.profile.general.sound)
	end
end

function SSPVP:StopSound()
	if( string.find( SSPVP.db.profile.general.sound, "mp3$" ) ) then
		StopMusic()
	else
		local old = GetCVar("Sound_EnableAllSound")
		SetCVar("Sound_EnableAllSound", 0)
		SetCVar("Sound_EnableAllSound", old)
	end
end

-- Auto release/accept
function SSPVP:CORPSE_OUT_OF_RANGE()
	SSPVP:CancelTimer("SSAUTO_RELEASE")
end

function SSPVP:CORPSE_IN_RANGE()
	if( activeBF.id > 0 and SSPVP.db.profile.bf.autoAccept and GetCorpseRecoveryDelay() ~= nil and GetCorpseRecoveryDelay() > 0 ) then
		self:ScheduleTimer("SSAUTO_RELEASE", RetrieveCorpse, GetCorpseRecoveryDelay() + 1)
	end
end

function SSPVP:PLAYER_DEAD()
	if( activeBF.id > 0 and SSPVP.db.profile.bf.release ) then
		if( not HasSoulstone() and SSPVP.db.profile.bf.release ) then
			StaticPopupDialogs["DEATH"].text = L["Releasing..."]
			RepopMe()	
			
		elseif( HasSoulstone() and SSPVP.db.profile.bf.releaseSS ) then
			StaticPopupDialogs["DEATH"].text = string.format(L["Using %s..."], HasSoulstone())
			UseSoulstone()		
		else
			StaticPopupDialogs["DEATH"].text = HasSoulstone()	
		end
	else
		StaticPopupDialogs["DEATH"].text = TEXT(DEATH_RELEASE_TIMER)
	end
end

-- I'm sure i'll have to extend this at some point to add argument passing.
function SSPVP:PLAYER_REGEN_ENABLED(event)
	for _, row in pairs(queuedUpdates) do
		if( row.handler ) then
			row.handler[row.func](row.handler)
		elseif( type(row.func) == "string" ) then
			getglobal(row.func)()
		elseif( type(row.func) == "function" ) then
			row.func()
		end
	end
	
	for i=#(queuedUpdates), 1, -1 do
		table.remove(queuedUpdates, i)
	end
	
end

function SSPVP:UnregisterOOCUpdate(func)
	for i=#(queuedUpdates), 1, -1 do
		if( queuedUpdates[i].func == func ) then
			table.remove(queuedUpdates, i)
		end
	end
end

function SSPVP:RegisterOOCUpdate(handler, func)
	if( type(handler) == "table" and type(func) == "string" ) then
		table.insert(queuedUpdates, {func = func, handler = handler})
	elseif( type(handler) == "function" or type(handler) == "string" ) then
		table.insert(queuedUpdates, {func = handler})
	end
end

-- Confirmation popups
StaticPopupDialogs["CONFIRM_PORT_LEAVE"] = {
	text = "",
	button1 = TEXT(YES),
	button2 = TEXT(NO),
	OnAccept = function(id)
		confirmedPortLeave[id] = true
		AcceptBattlefieldPort(id, nil)
	end,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 1,
	multiple = 1,
}

StaticPopupDialogs["CONFIRM_BATTLEFIELD_LEAVE"] = {
	text = "",
	button1 = TEXT(YES),
	button2 = TEXT(NO),
	OnAccept = function()
		confirmedBFLeave = true
		LeaveBattlefield()
	end,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 1,
	multiple = 1,
}
