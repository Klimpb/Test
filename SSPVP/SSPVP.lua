--[[ 
	SSPVP By Shadowd / Amarand from US-Icecrown PvE
	
	1.x Release: January 26th 2006
	2.x Release: December 27th 2006
	3.x Release: April 9th 2007
]]

SSPVP = DongleStub("Dongle-1.0"):New( "SSPVP" )

local L = SSPVPLocals

local activeBF = { id = -1 }
local battlefieldInfo = {}
local joiningBF
local queuedUpdates = {}
local confirmedPortLeave = {}
local confirmedBFLeave

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
				target = true,
				modify = true,
				showSpec = true,
				background = { r = 0, g = 0, b = 0 },
				border = { r = 0.75, g = 0.75, b = 0.75 },
				scale = 0.90,
				opacity = 1.0,
				deadOpacity = 0.75,
				enemyNum = true,
				petColor = { r = 0.20, g = 0.90, b = 0.20 },
				showIcon = true,
				showPets = true,
				showHealth = true,
				showTalents = false,
				chatInfo = true,
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
				confirm = true,
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
	
	self.db = self:InitializeDB( "SSPVPDB", self.defaults )

	self.cmd = self:InitializeSlashCommand( L["SSPVP commands"], "SSPVP", "sspvp" )
	self.cmd:InjectDBCommands( self.db, "delete", "copy", "list", "set" )
		
	SSOverlay:AddCategory( "general", L["Time before start"], -1 )
	SSOverlay:AddCategory( "queue", L["Battlefield queues"], 1 )
	
	-- Grab the list of team mates
	for i=1, MAX_ARENA_TEAMS do
		ArenaTeamRoster(i)
	end

	-- "Upgrade", we removed arena and added ratedARena/skirmArena instead
	self.db.profile.priority.arena = nil
end

function SSPVP:Enable()
	self:RegisterEvent( "UPDATE_BATTLEFIELD_STATUS" )
	self:RegisterEvent( "PLAYER_REGEN_ENABLED" )
	self:RegisterEvent( "CHAT_MSG_BG_SYSTEM_NEUTRAL" )
	self:RegisterEvent( "BATTLEFIELDS_SHOW" )
	self:RegisterEvent( "GOSSIP_SHOW" )
	self:RegisterEvent( "SCREENSHOT_SUCCEEDED", "ScreenshotTaken" )
	self:RegisterEvent( "SCREENSHOT_FAILED", "ScreenshotTaken" )
	
	for name, module in SSPVP:IterateModules() do
		if( not self.db.profile.modules[ name ] and not module.activeIn and module.EnableModule ) then
			module.moduleEnabled = true
			module.EnableModule(module)
		end
	end
end

function SSPVP:Disable()
	self:DisableModules()

	self:UnregisterAllEvents()
	self:UnregisterAllMessages()
	self:UnregisterAllTimers()
	
	SSOverlay:RemoveCategory( "general" )
	SSOverlay:RemoveCategory( "queue" )

	if( activeBF.id > 0 ) then
		confirmBF = {}
		activeBF = { id = -1 }
		joiningBF = nil
	end
end

function SSPVP:Reload()
	SSPVP:UPDATE_BATTLEFIELD_STATUS()
end

function SSPVP:Message( msg, color )
	if( not color ) then
		DEFAULT_CHAT_FRAME:AddMessage( msg )
	else
		DEFAULT_CHAT_FRAME:AddMessage( msg, color.r, color.g, color.b )
	end
end

local Orig_UIErrorsFrame_OnEvent = UIErrorsFrame_OnEvent
function UIErrorsFrame_OnEvent( event, message, ... )
	if( string.match( message, L["Your group has joined the queue for"] ) ) then
		return
	end

	return Orig_UIErrorsFrame_OnEvent( event, message, ... )
end

local Orig_ChatFrame_MessageEventHandler = ChatFrame_MessageEventHandler
function ChatFrame_MessageEventHandler( event, ... )
	if( SSPVP.db.profile.general.block and ( event == "CHAT_MSG_RAID" or event == "CHAT_MSG_RAID_LEADER" or event == "CHAT_MSG_PARTY" or event == "CHAT_MSG_BATTLEGROUND" or event == "CHAT_MSG_BATTLEGROUND_LEADER" ) ) then
		if( string.sub( arg1, 0, 4 ) == "[SS]" ) then
			return false
		end
	end
	
	return Orig_ChatFrame_MessageEventHandler( event, ... )
end

local Orig_AcceptBattlefieldPort = AcceptBattlefieldPort
function AcceptBattlefieldPort( id, flag, ... )
	if( not flag and not confirmedPortLeave[ id ] and SSPVP.db.profile.leave.confirm ) then
		local _, map, _, _, _, teamSize = GetBattlefieldStatus( id )
		if( teamSize > 0 ) then
			StaticPopupDialogs["CONFIRM_PORT_LEAVE"].text = string.format( L["You are about to leave the active or queued arena %s (%dvs%d), are you sure?"], map, teamSize, teamSize )
		else
			StaticPopupDialogs["CONFIRM_PORT_LEAVE"].text = string.format( L["You are about to leave the active or queued battlefield %s, are you sure?"], map )
		end
		
		local popup = StaticPopup_Show( "CONFIRM_PORT_LEAVE", nil, nil, id )
		if( popup ) then
			popup.data = id
		end
		return
	end
	
	confirmedPortLeave[ id ] = nil
	
	StaticPopup_Hide( "CONFIRM_PORT_LEAVE", id )
	Orig_AcceptBattlefieldPort( id, flag, ... )
end

local Orig_LeaveBattlefield = LeaveBattlefield
function LeaveBattlefield( ... )
	if( not confirmedBFLeave and SSPVP.db.profile.leave.confirm and this:GetName() ~= "WorldStateScoreFrameLeaveButton" ) then
		-- Find an active battlefield
		local map, status, teamSize
		for i=1, MAX_BATTLEFIELD_QUEUES do
			status, map, _, _, _, teamSize = GetBattlefieldStatus( i )
			if( status == "active" ) then
				break
			end
		end
		
		if( teamSize > 0 ) then
			StaticPopupDialogs["CONFIRM_BATTLEFIELD_LEAVE"].text = string.format( L["You are about to leave the active or queued arena %s (%dvs%d), are you sure?"], map, teamSize, teamSize )
		else
			StaticPopupDialogs["CONFIRM_BATTLEFIELD_LEAVE"].text = string.format( L["You are about to leave the active or queued battlefield %s, are you sure?"], map )
		end
		
		StaticPopup_Show( "CONFIRM_BATTLEFIELD_LEAVE" )
		return
	end
	
	confirmedBFLeave = nil
	Orig_LeaveBattlefield( ... )
end

function SSPVP:CHAT_MSG_BG_SYSTEM_NEUTRAL( event, msg )
	if( string.find( msg, L["2 minute"] ) ) then
		SSOverlay:UpdateTimer( "general", L["Starting In: %s"], 121 )

	elseif( string.find( msg, L["1 minute"] ) or string.find( msg, L["One minute until"] ) ) then
		SSOverlay:UpdateTimer( "general", L["Starting In: %s"], 61 )

	elseif( string.find( msg, L["30 seconds"] ) or string.find( msg, L["Thirty seconds until"] ) ) then
		SSOverlay:UpdateTimer( "general", L["Starting In: %s"], 31 )

	elseif( string.find( msg, L["Fifteen seconds until"] ) ) then
		SSOverlay:UpdateTimer( "general", L["Starting In: %s"], 15 )
	end
end

function SSPVP:BATTLEFIELDS_SHOW()
	local status, map, registeredMatch
	local queued = 0
	local shownField = GetBattlefieldInfo()

	for i=1, MAX_BATTLEFIELD_QUEUES do
		status, map, _, _, _, registeredMatch = GetBattlefieldStatus( i )
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
	
	if( self.db.profile.queue.autoSolo and GetNumPartyMembers() == 0 and GetNumRaidMembers() == 0 ) then
		JoinBattlefield( GetSelectedBattlefield() )
	elseif( self.db.profile.queue.autoGroup and CanJoinBattlefieldAsGroup() and IsPartyLeader() ) then
		JoinBattlefield( GetSelectedBattlefield(), true )
	end
end

function SSPVP:GOSSIP_SHOW()
	if( GossipFrame.buttonIndex ) then
		for i=1, GossipFrame.buttonIndex do
			local gossipText = getglobal( "GossipTitleButton" .. i ):GetText()
			
			if( gossipText == L["I would like to go to the battleground."] or gossipText == L["I would like to fight in an arena."] or gossipText == L["I wish to join the battle!"] ) then
				getglobal( "GossipTitleButton" .. i ):Click()	
			end
		end
	end
end

function SSPVP:EnableModules( activeBattlefield )
	for name, module in SSPVP:IterateModules() do
		if( not self.db.profile.modules[ name ] and module.activeIn and not module.moduleEnabled ) then
			-- A battleground refers to WSG, AB, EoTS, AV, while a battlefield refers to WSG, AB, EoTS, AV, Arenas.
			if( module.activeIn == "bf" or ( module.activeIn == "bg" and activeBattlefield ~= "arena" ) or module.activeIn == activeBattlefield ) then
				module.moduleEnabled = true
				module.EnableModule(module)
			end
		end
	end
end

function SSPVP:DisableModules()
	for name, module in SSPVP:IterateModules() do
		if( module.DisableModule and module.moduleEnabled ) then
			module.moduleEnabled = nil
			module.DisableModule(module)
		end
	end
end

function SSPVP:UPDATE_BATTLEFIELD_STATUS()
	SSOverlay:RemoveCategory( "queue" )
	
	local status, map, id, teamSize

	for i=1, MAX_BATTLEFIELD_QUEUES do
		status, map, id, _, _, teamSize, registeredMatch = GetBattlefieldStatus( i )
		
		if( status == "confirm" and battlefieldInfo[ map .. teamSize ] ~= "confirm" ) then
			battlefieldInfo[ map .. ":" .. teamSize ] = status

			self:QueueReady( i, map )
			self:PlaySound()
		
		elseif( status == "queued" and battlefieldInfo[ map .. teamSize ] ~= "queued" ) then
			battlefieldInfo[ map .. teamSize ] = status

			if( GetBattlefieldTimeWaited( i ) <= 1000 ) then
				if( teamSize > 0 ) then
					if( registeredMatch ) then
						self:Print( string.format( L["You are now in the queue for %s Arena (%dvs%d)."], L["Rated"], teamSize, teamSize ) )
					else
						self:Print( string.format( L["You are now in the queue for %s Arena (%dvs%d)."], L["Skirmish"], teamSize, teamSize ) )
					end
				else
					self:Print( string.format( L["You are now in the queue for %s."], map ) )
				end
				
				if( ( GetBattlefieldInfo() ) == map and BattlefieldFrame:IsShown() ) then
					HideUIPanel( BattlefieldFrame )
				end
			end
			
		elseif( status == "active" and i ~= activeBF.id ) then
			RequestBattlefieldScoreData()
			battlefieldInfo[ map .. teamSize ] = status

			activeBF.id = i
			activeBF.map = map
			activeBF.teamSize = teamSize
			activeBF.isRegistered = registeredMatch
			activeBF.abbrev = SSPVP:GetBattlefieldAbbrev( map )
			
			self:StopSound()
			self:DisableModules()
			self:EnableModules( activeBF.abbrev )
			
			if( activeBF.abbrev ~= "arena" ) then
				if( SSPVP.db.profile.bf.minimap ) then
					BattlefieldMinimap_LoadUI()

					if( BattlefieldMinimap ) then
						BattlefieldMinimap:Show()
						BattlefieldMinimap_Update()
					end

				elseif( BattlefieldMinimap ) then
					BattlefieldMinimap:Hide()
				end

			elseif( BattlefieldMinimap ) then
				BattlefieldMinimap:Hide()
			end

		elseif( status ~= "active" and i == activeBF.id ) then
			self:DisableModules()
			SSOverlay:RemoveRow("timer", "general", L["Starting In: %s"])
			
			battlefieldInfo[ map .. teamSize ] = status
			activeBF = { id = -1 }

			if( IsAddOnLoaded( "Blizzard_BattlefieldMinimap" ) ) then
				BattlefieldMinimap:Hide()
			end
		end
		
		-- No longer a confirmation, so clear out config/joining
		if( status ~= "confirm" and map ) then
			battlefieldInfo[ map .. teamSize ] = nil
			
			if( id == joiningBF ) then
				joiningBF = nil
			end
		end
		
		-- Deal with the queue overlay
		if( status ~= "none" and SSPVP.db.profile.queue.enabled and ( activeBF.id == -1 or SSPVP.db.profile.queue.insideField ) ) then
			if( teamSize > 0 ) then
				if( registeredMatch ) then
					map = string.format( L["%s [%s] (%dvs%d)"], map, L["R"], teamSize, teamSize )
				else
					map = string.format( L["%s [%s] (%dvs%d)"], map, L["S"], teamSize, teamSize )
				end
			end
			
			if( status == "confirm" ) then
				SSOverlay:UpdateTimer( "queue", map .. ": %s", GetBattlefieldPortExpiration( i ) / 1000 )

			elseif( status == "active" ) then
				SSOverlay:UpdateText( "queue", map .. ": #" .. id )

			elseif( status == "queued" ) then
				if( SSPVP.db.profile.queue.showEta and GetBattlefieldEstimatedWaitTime( i ) > 0 ) then
					SSOverlay:UpdateElapsed( "queue", map .. ": %s (" .. SSOverlay:FormatTime( GetBattlefieldEstimatedWaitTime( i ) / 1000, SSPVP.db.profile.queue.etaFormat ) .. ")", GetBattlefieldTimeWaited( i ) / 1000 )
				else
					SSOverlay:UpdateElapsed( "queue", map .. ": %s", GetBattlefieldTimeWaited( i ) / 1000 )
				end
			end
		end		
	end
	
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

-- Theres delay issues if we don't check leaving battlefield before this.
function SSPVP:LeaveBattlefield()
	if( GetBattlefieldWinner() ) then
		if( SSPVP.db.profile.arena.chatInfo and (IsActiveBattlefieldArena()) and select(2, IsActiveBattlefieldArena()) ) then
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
				SSPVP:Print(string.format(L["%s %d points (%d rating) / %s %d points (%d rating)"], winName, winPoints, winRating, loseName, losePoints, loseRating))
			end
		end
		
		confirmedBFLeave = true
		LeaveBattlefield()
	end
end

function SSPVP:ScreenshotTaken()
	if( activeBF.screenShot and self.db.profile.leave.screen ) then
		self:QueueBattlefieldLeave()
	end
end

function SSPVP:QueueBattlefieldLeave()
	-- Make sure we don't have a battlefield thats ready to be joined
	local active = 0
	local status, map, abbrev
	
	for i=1, MAX_BATTLEFIELD_QUEUES do
		status, map = GetBattlefieldStatus( i )
		
		if( status == "active" ) then
			active = active + 1
			abbrev = self:GetBattlefieldAbbrev(map)
		elseif( status == "confirm" ) then
			SSPVP:Print( string.format( L["The battlefield %s is ready to join, auto leave has been disabled."], map ) )
			return
		end
	end
	
	if( active == 1 ) then
		if( abbrev == "arena" ) then
			self:RegisterTimer( self, "LeaveBattlefield", self.db.profile.leave.arenaDelay )
		else
			self:RegisterTimer( self, "LeaveBattlefield", self.db.profile.leave.bgDelay )
		end
	end
end

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

function SSPVP:AutoJoinBattlefield()
	if( not joiningBF or not SSPVP.db.profile.join.enabled ) then
		return		
	end
	
	local currentType, queuedType, priority
	local isInstance, type = IsInInstance()

	-- Figure out our current status
	if( UnitIsAFK( "player" ) ) then
		currentType = "afk"
	elseif( activeBF.id > 0 ) then
		if( activeBF.abbrev == "arena" ) then
			if( activeBF.isRegistered ) then
				currentType = "ratedArena"
			else
				currentType = "skirmArena"
			end
		else
			currentType = activeBF.abbrev
		end
		
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
		return
	end
	
	-- This allows us to have two priority modes, one only overrides priorities that are less then the current
	-- the other only overrides ones that are less then or equal, 
	if( ( self.db.profile.join.type == "less" and self.db.profile.priority[ currentType ] < self.db.profile.priority[ joinAbbrev ] ) or
	( self.db.profile.join.type == "lseql" and self.db.profile.priority[ currentType ] <= self.db.profile.priority[ joinAbbrev ] ) ) then
		SSPVP:Print( string.format( L["You're currently inside/doing something that is a higher priority then %s, auto join disabled." ], joinMap ) )
		return
	end
	
	AcceptBattlefieldPort( joiningBF, true )
	joiningBF = nil
end

function SSPVP:QueueReady( id, map )
	local delayType
	if( SSPVP:GetBattlefieldAbbrev( map ) == "arena" ) then
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
		self:RegisterTimer( self, "AutoJoinBattlefield", self.db.profile.join[ delayType ] )

	elseif( joiningBF ~= id ) then
		-- Check if we have a higher priority queue
		local _, joinMap = GetBattlefieldStatus( joiningBF )
		-- This allows us to have two priority modes, one only overrides priorities that are less then the current
		-- the other only overrides ones that are less then or equal, 
		if( ( self.db.profile.join.type == "less" and self.db.profile.priority[ SSPVP:GetBattlefieldAbbrev( map ) ] < self.db.profile.priority[ SSPVP:GetBattlefieldAbbrev( joinMap ) ] ) or
		( self.db.profile.join.type == "lseql" and self.db.profile.priority[ SSPVP:GetBattlefieldAbbrev( map ) ] <= self.db.profile.priority[ SSPVP:GetBattlefieldAbbrev( joinMap ) ] ) ) then
			joiningBF = id
			
			self:UnregisterTimer( "AutoJoinBattlefield" )
			self:RegisterTimer( self, "AutoJoinBattlefield", self.db.profile.join[ delayType ] )
			self:Print( string.format( L["Higher priority battlefield found, auto joining %s in %d seconds."], map, self.db.profile.join[ delayType ] ) )
		end
	end
end

function SSPVP:IsPlayerIn( type )
	return ( activeBF.abbrev == type )
end

function SSPVP:ChannelMessage( msg, skipPrefix )
	if( not skipPrefix ) then
		msg = "[SS] " .. msg
	end
	
	if( GetNumRaidMembers() == 0 and GetNumPartyMembers() == 0 ) then
		return
	end
	
	SendChatMessage( msg, self.db.profile.general.channel )
end

function SSPVP:PrintTimer( name, endTime, faction )
	local secondsLeft = endTime - GetTime()

	if( secondsLeft > 0 and name ) then
		SSPVP:ChannelMessage( string.format( L["[%s] %s: %s"], L[ faction ], name, string.trim( SecondsToTime( secondsLeft ) ) ) )
	end
end

function SSPVP:AutoMessage( msg, skipPrefix )
	if( not skipPrefix ) then
		msg = "[SS] " .. msg
	end
	
	if( GetNumRaidMembers() > 0 ) then
		SendChatMessage( msg, "RAID" )
	elseif( GetNumPartyMembers() > 0 ) then
		SendChatMessage( msg, "PARTY" )
	end
end

function SSPVP:PlaySound()
	if( SSPVP.db.profile.general.sound == "" ) then
		return
	end
	
	SSPVP:StopSound()
	
	if( string.find( SSPVP.db.profile.general.sound, "mp3$" ) ) then
		PlayMusic( "Interface\\AddOns\\SSPVP\\" .. SSPVP.db.profile.general.sound )
	else
		PlaySoundFile( "Interface\\AddOns\\SSPVP\\" .. SSPVP.db.profile.general.sound )
	end
end

function SSPVP:StopSound()
	if( string.find( SSPVP.db.profile.general.sound, "mp3$" ) ) then
		StopMusic()
	else
		local old = GetCVar( "MasterSoundEffects" )
		SetCVar( "MasterSoundEffects", 0 )
		SetCVar( "MasterSoundEffects", old )
	end
end

-- I'm sure i'll have to extend this at some point to add argument passing.
function SSPVP:PLAYER_REGEN_ENABLED( event )
	for func, handler in pairs( queuedUpdates ) do
		if( type( handler ) == "table" ) then
			handler[ func ]( handler )
		elseif( type( func ) == "function" ) then
			func()
		elseif( type( func ) == "string" ) then
			getglobal( func )()
		end
		
		queuedUpdates[ func ] = nil
	end
end

function SSPVP:UnregisterOOCUpdate( func )
	queuedUpdates[ func ] = nil
end

function SSPVP:RegisterOOCUpdate( handler, func )
	if( type( handler ) == "table" and type( func ) == "string" ) then
		queuedUpdates[ func ] = handler
	elseif( type( handler ) == "function" or type( handler ) == "string" ) then
		queuedUpdates[ handler ] = true
	end
end


-- Timers
local timers = {}
function SSPVP:RegisterTimer( addon, func, delay, ... )
	if( not SSPVP.frame ) then
		SSPVP.frame = CreateFrame( "Frame" )
		SSPVP.frame:SetScript( "OnUpdate", SSPVP.OnUpdate )
	end
	
	-- God knows why RetrieveCorpse is being bitchy, i'll deal with it later.
	if( not delay ) then
		return
	end
	
	table.insert( timers, { handler = type( func ) == "string" and addon, func = func, runAt = GetTime() + delay, ... } )
end

function SSPVP:UnregisterAllTimers()
	timers = {}
end

function SSPVP:UnregisterTimer( func )
	for i=#( timers ), 1, -1 do
		if( timers[i].func == func ) then
			table.remove( timers, i )
		end
	end
end

local elapsed = 0
local scoreElapsed = 0
function SSPVP:OnUpdate()
	elapsed = elapsed + arg1
	scoreElapsed = scoreElapsed + arg1
	
	if( elapsed > 0.10 ) then
		local crttime = GetTime()
		
		for i=#( timers ), 1, -1 do
			if( timers[ i ].runAt <= crttime ) then
				if( timers[ i ].handler ) then
					timers[ i ].handler[ timers[ i ].func ]( timers[ i ].handler, unpack( timers[ i ] ) )
				
				elseif( type( timers[ i ].func ) == "string" ) then
					getglobal( timers[ i ].func )( unpack( timers[ i ] ) )
				end
				
				table.remove( timers, i )
			end
		end
	end
	
	if( activeBF.id > 0 and scoreElapsed > 15 ) then
		scoreElapsed = 0
		RequestBattlefieldScoreData()
	end
end


StaticPopupDialogs["CONFIRM_PORT_LEAVE"] = {
	text = "",
	button1 = TEXT( YES ),
	button2 = TEXT( NO ),
	OnAccept = function( id )
		confirmedPortLeave[ id ] = true
		AcceptBattlefieldPort( id, nil )
	end,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 1,
	multiple = 1,
}

StaticPopupDialogs["CONFIRM_BATTLEFIELD_LEAVE"] = {
	text = "",
	button1 = TEXT( YES ),
	button2 = TEXT( NO ),
	OnAccept = function()
		confirmedBFLeave = true
		LeaveBattlefield()
	end,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 1,
	multiple = 1,
}
