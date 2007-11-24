--[[ 
	SSPVP by Mayen Horde, Icecrown-US (PvE)
	
	1.x   Release: January 26th 2006
	2.x   Release: December 27th 2006
	3.x   Release: April 9th 2007
	SSPVP Release: November 18th 2007
]]

SSPVP = LibStub("AceAddon-3.0"):NewAddon("SSPVP", "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0")

local L = SSPVPLocals

local activeBF, activeID, joinID, joinAt, joinPriority, screenTaken, confirmLeavel

local teamTotals = {[2] = 0, [3] = 0, [5] = 0}
local statusInfo = {}
local queuedUpdates = {}
local confirmPortLeave = {}

function SSPVP:OnInitialize()
	self.defaults = {
		profile = {
			general = {
				sound = "",
				channel = "BATTLEGROUND",
			},
			priorities = {
				afk = 1,
				ratedArena = 2,
				skirmArena = 3,
				eots = 3,
				av = 3,
				ab = 3,
				wsg = 3,
				group = 4,
				instance = 5,
				none = 6,
			},
			join = {
				enabled = true,
				arena = 10,
				window = false,
				priority = "lseql",
				battleground = 10,
				afkBattleground = 10,
			},
			auto = {
				solo = true,
				group = false,
			},
			leave = {
				enabled = true,
				screen = false,
				portConfirm = true,
				leaveConfirm = false,
				delay = 10,
			},
		}
	}
	
	self.db = LibStub:GetLibrary("AceDB-3.0"):New("SSPVPDB", self.defaults)

	-- Not the funnest method, but Blizzard requires us to call this to get arena team info
	for i=1, MAX_ARENA_TEAMS do
		ArenaTeamRoster(i)
	end
end

function SSPVP:OnEnable()
	self:RegisterEvent("BATTLEFIELDS_SHOW")
	self:RegisterEvent("UPDATE_BATTLEFIELD_STATUS")
	self:RegisterEvent("PLAYER_REGEN_ENABLED")
end

function SSPVP:OnDisable()
	self:UnregisterAllEvents()
end

function SSPVP:BATTLEFIELDS_SHOW()
	local queued = 0
	
	for i=1, MAX_BATTLEFIELD_QUEUES do
		local status, map, _, _, _, isRegistered = GetBattlefieldStatus(i)
		
		if( status == "queued" or status == "confirm" ) then
			queued = queued + 1
		elseif( ( status ~= "none" and (GetBattlefieldInfo()) == map ) or isRegistered == 1 ) then
			return
		end
	end
		
	-- Max queues, don't bother trying
	if( queued == MAX_BATTLEFIELD_QUEUES ) then
		return
	end
	
	-- Auto select an option in arena queue depending on teammates
	if( IsBattlefieldArena() and GetNumPartyMembers() > 0 ) then
		for _, total in pairs(teamTotals) do
			total = 0
		end

		-- Figure out which team we're playing with
		for teamID=1, MAX_ARENA_TEAMS do
			local teamSize = select(2, GetArenaTeam(teamID))
			if( teamSize > 0 ) then
				teamTotals[teamSize] = 1

				-- Now check if we're in the same party as them
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
		
		-- Auto select!
		if( teamTotals[5] == 5 ) then
			ArenaFrame.selection = 3
		elseif( teamTotals[3] == 3 ) then
			ArenaFrame.selection = 2
		elseif( teamTotals[2] == 2 ) then
			ArenaFrame.selection = 1
		end

		ArenaFrame_Update()
	end

		
	-- Auto queue
	if( self.db.profile.auto.solo and GetNumPartyMembers() == 0 and GetNumRaidMembers() == 0 ) then
		JoinBattlefield(GetSelectedBattlefield())
	elseif( self.db.profile.auto.group and CanJoinBattlefieldAsGroup() and IsPartyLeader() ) then
		JoinBattlefield(GetSelectedBattlefield(), true)
	end
end

function SSPVP:UPDATE_BATTLEFIELD_STATUS()
	for i=1, MAX_BATTLEFIELD_QUEUES do
		local status, map, instanceID, _, _, teamSize, isRegistered = GetBattlefieldStatus(i)
		
		if( statusInfo[i] ~= status ) then
			if( status == "confirm" ) then
				local delay = 0
				local abbrev = self:GetAbbrev(map)
				if( abbrev == "arena" ) then
					delay = self.db.profile.join.arena
				elseif( UnitIsAFK("player") ) then
					delay = self.db.profile.join.afkBattleground
				else
					delay = self.db.profile.join.battleground
				end
				
				-- No queue timer going
				if( not joinID ) then
					joinID = i
					joinAt = GetTime() + delay

					local priority
					if( abbrev == "arena" and isRegistered ) then
						joinPriority = self.db.profile.priorities.ratedArena
					elseif( abbrev == "arena" and not isRegistered ) then
						joinPriority = self.db.profile.priorities.skirmArena
					else
						joinPriority = self.db.profile.priorities[abbrev]
					end
					
					self:ScheduleTimer("JoinBattlefield", delay)
					
				-- Check if priority is higher
				elseif( joinID ~= i ) then
					local priority
					if( abbrev == "arena" and isRegistered ) then
						priority = self.db.profile.priorities.ratedArena
					elseif( abbrev == "arena" and not isRegistered ) then
						priority = self.db.profile.priorities.skirmArena
					else
						priority = self.db.profile.priorities[abbrev]
					end
						
					if( ( self.db.profile.join.priority == "less" and joinPriority < priority ) or ( self.db.profile.join.priority == "lseql" and joinPriority <= priority ) ) then
						joinID = i
						joiningAt = GetTime() + delay
						joinPriority = priority
						
						self:CancelTimer("JoinBattlefield")
						self:ScheduleTimer("JoinBattlefield", delay)
						
						self:Print(string.format(L["Higher priority battlefield ready, auto joining %s in %d seconds."], map, delay))
					end
				end
				
			elseif( status == "active" and activeID ~= i and instanceID > 0 ) then
				local abbrev = self:GetAbbrev(map)
				for name, module in pairs(self.modules) do
					if( module.EnableModule and ( ( abbrev == module.activeIn ) or ( abbrev ~= "arena" and module.activeIn == "bg" ) or ( module.activeIn == "bf" ) ) ) then
						module.isActive = true
						module.EnableModule(module, abbrev)
					end
				end

				-- No sense in requesting scores if you're in arena
				if( abbrev ~= "arena" ) then
					self:ScheduleRepeatingTimer(RequestBattlefieldScoreData, 15)	
				end
				
				activeBF = map
				activeID = i
			
			elseif( status ~= "active" and activeID == i ) then
				activeID = nil
				activeBF = nil
				
			
				self:CancelTimer(RequestBattlefieldScoreData)

				for name, module in pairs(self.modules) do
					if( module.isActive ) then
						module.isActive = nil
						module.DisableModule(module)
					end
				end
				
			elseif( status == "queued" and GetBattlefieldTimeWaited(i) <= 2000 ) then
				-- Blizzards queued doesn't cover all battlefields, just arenas
				if( teamSize > 0 ) then
					if( registeredMatch ) then
						self:Print(string.format(L["You are now in the queue for %s Arena (%dvs%d)."], L["Rated"], teamSize, teamSize))
					else
						self:Print(string.format(L["You are now in the queue for %s Arena (%dvs%d)."], L["Skirmish"], teamSize, teamSize))
					end
				else
					self:Print(string.format(L["You are now in the queue for %s."], map))
				end

				-- Hide the queue window!
				if( (GetBattlefieldInfo()) == map and BattlefieldFrame:IsShown() ) then
					HideUIPanel(BattlefieldFrame)
				end
			end
		end

		-- We no longer have this battlefield as confirmation
		-- likely time ran out, we left queue or we joined it manually
		if( status ~= "confirm" and joinID == i ) then
			joinID = nil
			joinAt = nil
			joinPriority = nil
		end
		
		statusInfo[i] = status
	end
	
	-- Auto leave
	if( self.db.profile.leave.enabled and GetBattlefieldWinner() ) then
		if( self.db.profile.leave.screen ) then
			if( not screenTaken ) then
				-- It's possible to have a bug where the battlefield ends and we take
				-- a screenshot before the score frame is shown
				if( not WorldStateScoreFrame:IsVisible() ) then
					ShowUIPanel(WorldStateScoreFrame)
				end
				
				self:RegisterEvent("SCREENSHOT_SUCCEEDED", "ScreenshotTaken")
				self:RegisterEvent("SCREENSHOT_FAILED", "ScreenshotTaken")

				screenTaken = true
				Screenshot()
			end
		else
			self:ScheduleTimer("LeaveBattlefield", self.db.profile.leave.delay)
		end
	end
end

-- Actually leave the battlefield (if we can)
function SSPVP:LeaveBattlefield()
	-- We've had issues in the past if we don't specifically check this again
	-- can lead to deserter when switching battlefields
	if( not GetBattlefieldWinner() ) then
		return
	end
	
	confirmLeave = true
	LeaveBattlefield()
end

-- Screenshot taken
function SSPVP:ScreenshotTaken()
	screenTaken = nil
	
	local name = "WoWScrnShot_" .. date("%m%d%y_%H%M%S") .. "."
	local format = GetCVar("screenshotFormat")
	if( format == "tga" ) then
		name = anme .. "tga"
	elseif( format == "jpeg" ) then
		name = name .. "jpg"
	elseif( format == "png" ) then
		name = name .. "png"
	end
	
	self:Print(string.format(L["Screenshot saved as %s."], name))

	self:UnregisterEvent("SCREENSHOT_SUCCEDED")
	self:UnregisterEvent("SCREENSHOT_FAILED")
	self:ScheduleTimer("LeaveBattlefield", self.db.profile.leave.delay)
end

-- Now check priorities before we join the battlefield
function SSPVP:JoinBattlefield()
	if( not joinID or not self.db.profile.join.enabled ) then
		return
	end
	
	-- Disable auto join if the windows hidden
	if( self.db.profile.join.window and not StaticPopup_FindVisible("CONFIRM_BATTLEFIELD_ENTRY", joinID) ) then
		joinID = nil
		joinAt = nil
		joinPriority = nil
		return
	end
	
	local priority
	local instance, type = IsInInstance()
	

	if( UnitIsAFK("player" ) ) then
		priority = self.db.profile.priorities.afk
	elseif( activeBF and type == "arena" ) then
		if( select(2, IsActiveBattlefieldArena()) ) then
			priority = self.db.profile.priorities.ratedArena
		else
			priority = self.db.profile.priorities.skirmArena
		end
	elseif( activeBF and type == "pvp" ) then
		priority = self.db.profile.priorities[self:GetAbbrev(activeBF)]
	elseif( instance ) then
		priority = self.db.profile.priorities.instance
	elseif( GetNumPartyMembers() > 0 or GetNumRaidMembers() > 0 ) then
		priority = self.db.profile.priorities.group
	else			
		priority = self.db.profile.priorities.none
	end
	
	-- Make sure we can auto join
	if( ( self.db.profile.join.priority == "less" and priority < joinPriority ) or ( self.db.profile.join.priority == "lseql" and priority <= joinPriority ) ) then
		self:Print(string.format(L["You're current activity is a higher priority then %s, not auto joining."], select(2, GetBattlefieldStatus(joinID))))
	else
		AcceptBattlefieldPort(joinID, true)
	end

	joinID = nil
	joinAt = nil
	joinPriority = nil
end

function SSPVP:GetAutoJoin()
	return joinID, joinAt
end

function SSPVP:GetAbbrev(map)
	if( map == L["Warsong Gulch"] ) then
		return "wsg"
	elseif( map == L["Arathi Basin"] ) then
		return "ab"
	elseif( map == L["Alterac Valley"] ) then
		return "av"
	elseif( map == L["Eye of the Storm"] ) then
		return "eots"
	elseif( map == L["Blade's Edge Arena"] or map == L["Nagrand Arena"] or map == L["Ruins of Lordaeron"] ) then
		return "arena"
	end
	
	return ""
end

function SSPVP:ParseNode(node)
	node = string.gsub(node, "^" .. L["The"], "")
	node = string.trim(node)
	
	-- Mostly for looks
	if( GetLocale() == "enUS" ) then
		node = string.upper(string.sub(node, 0, 1)) .. string.sub(node, 2)
	end

	return node
end

function SSPVP:GetFactionColor(faction)
	if( faction == "Alliance" or faction == "CHAT_MSG_BG_SYSTEM_ALLIANCE" ) then
		return ChatTypeInfo["BG_SYSTEM_ALLIANCE"]
	elseif( faction == "Horde" or faction == "CHAT_MSG_BG_SYSTEM_HORDE" ) then
		return ChatTypeInfo["BG_SYSTEM_HORDE"]
	end
	
	return ChatTypeInfo["BG_SYSTEM_NEUTRAL"]
end

function SSPVP:Echo(msg, color)
	if( color ) then
		DEFAULT_CHAT_FRAME:AddMessage(msg, color.r, color.g, color.b)	

	else
		DEFAULT_CHAT_FRAME:AddMessage(msg)
	end
end

function SSPVP:Print(msg)
	DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99SSPVP|r: " .. msg)
end

function SSPVP:ChannelMessage(msg)
	if( GetNumRaidMembers() == 0 and GetNumPartyMembers() == 0 ) then
		return
	end
	
	SendChatMessage("[SS] " .. msg, self.db.profile.general.channel)
end

-- Quick access to whatever combat text mod is being used
function SSPVP:CombatText(text, color)	
	-- SCT
	if( IsAddOnLoaded("sct") ) then
		SCT:DisplayText(text, color, nil, "event", 1)
	
	-- MSBT
	elseif( IsAddOnLoaded("MikScrollingBattleText") ) then
		MikSBT:DisplayMessage(text, MikSBT.DISPLAYTYPE_NOTIFICATION, false, color.r, color.g, color.b)		
	
	-- Blizzard custom text
	elseif( IsAddOnLoaded("Blizzard_CombatText") ) then
		-- Haven't cached the movement function yet
		if( not COMBAT_TEXT_SCROLL_FUNCTION ) then
			CombatText_UpdateDisplayedMessages()
		end
		
		CombatText_AddMessage(text, COMBAT_TEXT_SCROLL_FUNCTION, color.r, color.g, color.b)
	end
end

-- Queuing things to run when we leave combat
function SSPVP:PLAYER_REGEN_ENABLED()
	for i=#(queuedUpdates), 1, -1 do
		local row = queuedUpdates[i]
		if( row.handler ) then
			row.handler[row.func](row.handler, unpack(row))
		elseif( type(row.func) == "function" ) then
			row.func(unpack(row))
		end
		
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

function SSPVP.RegisterOOCUpdate(self, func, ...)
	if( type(func) == "string" ) then
		table.insert(queuedUpdates, {func = func, handler = self, ...})
	else
		table.insert(queuedUpdates, {func = func, ...})
	end
end

-- Hooks for confirmations on leaving
-- "Leave Battlefield" button confirmation
local Orig_LeaveBattlefield = LeaveBattlefield
function LeaveBattlefield(...)
	if( SSPVP.db.profile.leave.leaveConfirm and not confirmLeave and this:GetName() ~= "WorldStateScoreFrameLeaveButton" ) then
		local map, status, teamSize
		for i=1, MAX_BATTLEFIELD_QUEUES do
			status, map, _, _, _, teamSize = GetBattlefieldStatus(i)
			if( status == "active" ) then
				break
			end
		end
		
		if( teamSize > 0 ) then
			StaticPopupDialogs["CONFIRM_BATTLEFIELD_LEAVE"].text = string.format(L["You are about to leave the active or queued arena %s (%dvs%d), are you sure?"], map, teamSize, teamSize)
		else
			StaticPopupDialogs["CONFIRM_BATTLEFIELD_LEAVE"].text = string.format(L["You are about to leave the active or queued battleground %s, are you sure?"], map)
		end
		
		StaticPopup_Show("CONFIRM_BATTLEFIELD_LEAVE")
		return
	end
	
	confirmLeave = nil
	Orig_LeaveBattlefield(...)
end

-- Leaving queues, or hitting leave battlefield through minimap
local Orig_AcceptBattlefieldPort = AcceptBattlefieldPort
function AcceptBattlefieldPort(id, accept, ...)
	if( not accept and SSPVP.db.profile.leave.portConfirm and not confirmPortLeave[id] ) then
		local _, map, _, _, _, teamSize = GetBattlefieldStatus(id)
		if( teamSize > 0 ) then
			StaticPopupDialogs["CONFIRM_PORT_LEAVE"].text = string.format(L["You are about to leave the active or queued arena %s (%dvs%d), are you sure?"], map, teamSize, teamSize)
		else
			StaticPopupDialogs["CONFIRM_PORT_LEAVE"].text = string.format(L["You are about to leave the active or queued battleground %s, are you sure?"], map)
		end
		
		local dialog = StaticPopup_Show("CONFIRM_PORT_LEAVE")
		if( dialog ) then
			dialog.data = id
		end
		return
	end
	
	confirmPortLeave[id] = nil
	StaticPopup_Hide("CONFIRM_PORT_LEAVE", id)
	
	Orig_AcceptBattlefieldPort(id, accept, ...)
end


-- Confirmation popups
StaticPopupDialogs["CONFIRM_PORT_LEAVE"] = {
	text = "",
	button1 = TEXT(YES),
	button2 = TEXT(NO),
	OnAccept = function(id)
		confirmPortLeave[id] = true
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
		confirmLeave = true
		LeaveBattlefield()
	end,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 1,
	multiple = 1,
}