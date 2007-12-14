local AVSync = SSPVP:NewModule("AVSync", "AceEvent-3.0", "AceTimer-3.0", "AceConsole-3.0")

local L = SSPVPLocals

local avStatus
local playerTotals = {}
local windowStatus = {}
local totalAlready = {}
local totalNotReady = {}
local skipStinky

function AVSync:OnInitialize()
	self.defaults = {
		profile = {
			enabled = true,
			monitor = true,
			forceQueue = false,
		},
	}

	self.db = SSPVP.db:RegisterNamespace("avsync", self.defaults)

	-- Slash commands for conversions
	self:RegisterChatCommand("av", function(input)
		if( not self.db.profile.enabled ) then
			SSPVP:Print(L["You do not have Alterac Valley syncing enabled, and cannot use any of the slash commands yourself."])
			return
		end
		
		-- Starts sync count down
		if( string.match(input, "sync ([0-9]+)") ) then
			if( not self:CheckPermissions() ) then
				return
			end
			
			local seconds = string.match(input, "sync ([0-9]+)")
			seconds = tonumber(seconds)
			if( not seconds or seconds >= 60 ) then
				SSPVP:Print(L["Invalid number entered for sync queue."])
				return
			end
			
			-- Make sure we aren't queuing instantly
			if( seconds > 0 ) then
				self:Message(seconds)
				for i=seconds - 1, 1, -1 do
					self:ScheduleTimer("Message", seconds - i, i)
				end
			end
			
			self:ScheduleTimer("SendQueue", seconds)

			SSOverlay:RemoveCategory("avsync")
			playerTotals = {}

			
		-- Cancels a count down
		elseif( input == "cancel" ) then
			self:CancelTimers()
			self:SendMessage(L["Alterac Valley queue stopped."])
			
		-- Drops all confirmed and queued AVs
		elseif( input == "drop" ) then
			if( self:CheckPermissions() ) then
				SSOverlay:RemoveCategory("avsync")
				playerTotals = {}

				self:SendMessage(L["Dropping Alterac Valley queues."])
				self:SendAddonMessage("DROP")
				
				-- StinkyQueue support
				SendAddonMessage("StinkyQ", "LeaveQueue", "RAID")
			end
		
		-- Forces a status update
		elseif( input == "update" ) then
			if( self:CheckPermissions() and avStatus ~= "active" ) then
				playerTotals = {}
				
				self:UpdateOverlay()
				self:SendAddonMessage("UPDATE")
			end
		
		-- Ready check
		elseif( input == "window" ) then
			for k in pairs(windowStatus) do
				windowStatus[k] = nil
			end
			
			self:SendMessage(L["Battlemaster ready check started, you have 10 seconds to get the window open."])
			
			-- Send request in 10 seconds, check results in 15
			self:CancelTimer("SendAddonMessage")
			self:CancelTimer("CheckResults")
			self:ScheduleTimer("SendAddonMessage", 10, "WINDOW")
			self:ScheduleTimer("CheckResults", 15, "WINDOW")
			
		else
			DEFAULT_CHAT_FRAME:AddMessage(L["SSPVP Alterac Valley slash commands"])
			DEFAULT_CHAT_FRAME:AddMessage(L[" - sync <seconds> - Starts a count down for an Alterac Valley sync queue."])
			DEFAULT_CHAT_FRAME:AddMessage(L[" - cancel - Cancels a running sync."])
			DEFAULT_CHAT_FRAME:AddMessage(L[" - drop - Drops all Alterac Valley queues."])
			DEFAULT_CHAT_FRAME:AddMessage(L[" - ready - Does a check to see who has the battlemaster window open and is ready to queue."])
			DEFAULT_CHAT_FRAME:AddMessage(L[" - update - Forces a status update on everyones Alterac Valley queues."])
		end
	end)
end

function AVSync:OnEnable()
	if( self.db.profile.enabled ) then
		self:RegisterEvent("CHAT_MSG_ADDON")
		self:RegisterEvent("UPDATE_BATTLEFIELD_STATUS")
	else
		self.db.profile.forceQueue = nil
	end
end

function AVSync:OnDisable()
	self:RemoveCategory("avsync")
	self:UnregisterAllEvents()
	self:CancelAllTimers()
end

function AVSync:Reload()
	self:OnDisable()
	self:OnEnable()
end

-- Window ready check
function AVSync:CheckResults()
	for i=#(totalAlready), 1, -1 do
		table.remove(totalAlready, i)
	end
	
	for i=#(totalNotReady), 1, -1 do
		table.remove(totalNotReady, i)
	end
	
	-- 0 = Not ready, 1 = Ready, 2 = Already AV queued
	for author, status in pairs(windowStatus) do
		if( status == 0 ) then
			table.insert(totalNotReady, author)
		elseif( status == 2 ) then
			table.insert(totalAlready, author)
		end
	end
	
	if( #(totalNotReady) == 0 and #(totalAlready) == 0 ) then
		self:SendMessage(L["Everyone is ready to go!"])
		return
	end
	

	if( #(totalNotReady) > 0 ) then
		self:SendMessage(string.format(L["Following are not ready: %s"], table.concat(totalNotReady, ", ")))
	end
	
	if( #(totalAlready) > 0 ) then
		self:SendMessage(string.format(L["Following are queued/inside Alterac Valley: %s"], table.concat(totalAlready, ", ")))
	end
end

-- Verifies if the player can perform the slash command actions
function AVSync:CheckPermissions()
	if( GetNumRaidMembers() == 0 and GetNumPartyMembers() == 0 ) then
		SSPVP:Print(L["You must be in a raid or party to do this."])
		return nil
	

	elseif( not IsPartyLeader() and not IsRaidLeader() and not IsRaidOfficer() ) then
		SSPVP:Print(L["You must be group leader, or assist to do this."])
		return nil
	end
	
	return true
end

-- Verifies if the author of the CHAT_MSG_ADDON event has permissions
function AVSync:CheckUserPermissions(verifyName)
	if( UnitName("player") == verifyName ) then
		return true

	end
	
	-- Scan party
	for i=1, GetNumPartyMembers() do
		local unit = "party" .. i
		if( UnitName(unit) == verifyName and UnitIsPartyLeader(unit) ) then
			return true
		end
	end
	
	-- Scan raid
	for i=1, GetNumRaidMembers() do
		local name, rank = GetRaidRosterInfo(i)
		if( name == verifyName and rank > 0 ) then
			return true
		end
	end
	
	return nil
end

-- Actually queue functions
function AVSync:Message(seconds)
	if( seconds > 1 ) then
		self:SendMessage(string.format(L["Queuing for Alterac Valley in %d seconds."], seconds))
	else
		self:SendMessage(string.format(L["Queuing for Alterac Valley in %d second."], seconds))
	end
end

function AVSync:SendQueue()
	self:SendMessage(L["Queue for Alterac Valley!"])
	self:SendAddonMessage("QUEUE")
	

	-- StinkyQueue support
	SendAddonMessage("StinkyQ", "Queue", "RAID")
end

-- Managing queue
function AVSync:Queue(author)
	self.db.profile.forceQueue = true
	
	SSPVP:Print(string.format(L["You have been queued for Alterac Valley by %s."], author))
	JoinBattlefield(0)
end

function AVSync:DropQueue(author)
	self.db.profile.forceQueue = nil
	avStatus = nil

	
	for i=1, MAX_BATTLEFIELD_QUEUES do
		local status, map = GetBattlefieldStatus(i)
		if( map == L["Alterac Valley"] and (status == "queued" or status == "confirm") ) then
			StaticPopupDialogs["CONFIRM_PORT_LEAVE"].OnAccept(i)
			SSPVP:Print(string.format(L["Alterac Valley queue has been dropped by %s."], author))
			
			self:SendAddonMessage("STATUPDATE:none,0")
			break
		end
	end
end

-- Update overlay
-- This will need more optimization later, but painkillers don't contribute to constructive thinking
local statusTotals, instanceTotals = {}, {}
function AVSync:UpdateStatus(type, instanceID, author)
	-- Not force queued, so don't try and monitor it
	if( not self.db.profile.forceQueue or avStatus == "active" ) then
		SSOverlay:RemoveCategory("avsync")

		return
	end
	

	-- Store our instance # and status
	if( not playerTotals[author] ) then
		playerTotals[author] = {}

	end
	

	playerTotals[author].id = tonumber(instanceID) or 0
	playerTotals[author].status = type
	
	self:UpdateOverlay()
end

function AVSync:UpdateOverlay()
	-- Now figure out what to display
	for k in pairs(statusTotals) do
		statusTotals[k] = nil
	end
	
	for id, v in pairs(instanceTotals) do
		SSOverlay:RemoveRow(id)
		v.total = 0
		v.type = nil
	end
	
	local totalPlayers = 0
	for _, row in pairs(playerTotals) do
		totalPlayers = totalPlayers + 1
		statusTotals[row.status] = (statusTotals[row.status] or 0) + 1
		
		if( row.id > 0 ) then
			local id = row.id .. row.status
			if( not instanceTotals[id] ) then
				instanceTotals[id] = {}
			end
			
			instanceTotals[id].total = (instanceTotals[id].total or 0) + 1
			instanceTotals[id].instance = row.id
			instanceTotals[id].type = row.status
		end
	end
	
	-- Show the exact confirm/active if we have more then 1 with it, or we have less then 5 people
	local totalMisc = 0
	for id, row in pairs(instanceTotals) do
		if( row.total > 1 or totalPlayers <= 5 ) then
			if( row.type == "confirm" ) then
				SSOverlay:RegisterText("confirm" .. id, "avsync", string.format(L["Confirm #%d: %d"], row.instance, row.total))
			elseif( row.type == "active" ) then
				SSOverlay:RegisterText("active" .. id, "avsync", string.format(L["Active #%d: %d"], row.instance, row.total))
			end
			
		elseif( row.type == "confirm" ) then
			totalMisc = totalMisc + 1
		end
	end
	
	if( totalMisc > 0 ) then
		SSOverlay:RegisterText("totalmisc", "avsync", string.format(L["Confirm Misc: %d"], totalMisc))
	else
		SSOverlay:RemoveRow("totalmisc")
	end
	
	-- Now show stats
	if( statusTotals.queued ) then
		SSOverlay:RegisterText("totalqueued", "avsync", string.format(L["Queued: %d"], statusTotals.queued))
	else
		SSOverlay:RemoveRow("totalqueued")
	end
end

-- for updating our current status in AV queue
function AVSync:UPDATE_BATTLEFIELD_STATUS()
	if( not self.db.profile.forceQueue ) then
		return

	end
	

	for i=1, MAX_BATTLEFIELD_QUEUES do
		local status, map, instanceID = GetBattlefieldStatus(i)
		if( map == L["Alterac Valley"] and status ~= avStatus ) then
			self:SendAddonMessage("STATUPDATE:" .. status .. "," .. instanceID)
			avStatus = status
			
			-- No longer force queued if it's none
			if( status == "none" ) then
				self.db.profile.forceQueue = nil
			end
		end
	end
	
	-- We couldn't find an AV queue, but we're still listed as force queue
	if( self.db.profile.forceQueue and not avStatus ) then
		self.db.profile.forceQueue = nil
	end
end

function AVSync:CHAT_MSG_ADDON(event, prefix, msg, type, author)
	if( prefix == "SSAV" ) then
		local dataType, data = string.match(msg, "([^:]+)%:(.+)")
		if( not dataType ) then
			dataType = msg
		end
		
		-- Queue sync
		if( (dataType == "QUEUEAV" or dataType == "QUEUE") and BattlefieldFrame:IsVisible() and (GetBattlefieldInfo()) == L["Alterac Valley"] and self:CheckUserPermissions(author) ) then
			skipStinky = true
			self:Queue(author)
			
		-- Force a status update
		elseif( dataType == "UPDATE" and self:CheckUserPermissions(author) ) then
			avStatus = nil
			self:UPDATE_BATTLEFIELD_STATUS()
		
		-- Drop our confirmed or queued AV
		elseif( dataType == "DROP" and self:CheckUserPermissions(author) ) then
			skipStinky = true
			self:DropQueue(author)
					
		-- Are we ready to queue (Can auto queue)
		elseif( dataType == "WINDOW" ) then
			-- Make sure we aren't queued already
			for i=1, MAX_BATTLEFIELD_QUEUES do
				local status, map = GetBattlefieldStatus(i)
				if( map == L["Alterac Valley"] and status ~= "none" ) then
					self:SendAddonMessage("ALRDQUEUED")
					return
				end
			end
			
			-- Check if window is open!
			if( BattlefieldFrame:IsVisible() and (GetBattlefieldInfo()) == L["Alterac Valley"] ) then
				self:SendAddonMessage("READY")
			else
				self:SendAddonMessage("NOTREADY")
			end
					
		-- Already queued for AV
		elseif( dataType == "ALRDQUEUED" ) then
			windowStatus[author] = 2

		-- Window open
		elseif( dataType == "READY" ) then
			windowStatus[author] = 1
		
		-- Window not open
		elseif( dataType == "NOTREADY" ) then
			windowStatus[author] = 0

		-- Queue updates
		elseif( dataType == "STATUPDATE" and self.db.profile.monitor ) then
			local type, instanceID = string.split(",", data)
			self:UpdateStatus(type, instanceID, author)
		end
	

	-- Support queues sent from StinkyQueue
	elseif( prefix == "StinkyQ" and self:CheckUserPermissions(author) ) then
		-- Don't want to try queuing twice
		if( skipStinky ) then
			skipStinky = nil
			return
		end
		
		if( msg == "Queue" and (GetBattlefieldInfo()) == L["Alterac Valley"] and BattlefieldFrame:IsVisible() ) then
			self:Queue(author)
		elseif( msg == "LeaveQueue" ) then
			self:DropQueue(author)
		end
	end
end

-- Make our lifes easier
function AVSync:SendMessage(msg)
	local type = "PARTY"
	if( GetNumRaidMembers() > 0 ) then
	--	type = "RAID"
	end
	
	SendChatMessage(msg, type)
end

function AVSync:SendAddonMessage(msg)
	SendAddonMessage("SSAV", msg, "RAID")
end
