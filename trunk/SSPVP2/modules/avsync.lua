local AVSync = SSPVP:NewModule("AVSync", "AceEvent-3.0", "AceTimer-3.0", "AceConsole-3.0")

local L = SSPVPLocals

local avStatus
local playerStatus = {}
local totalRecords = 0
local skipStinky

function AVSync:OnInitialize()
	self.defaults = {
		profile = {
			enabled = true,
			monitor = true,
			forceJoin = true,
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
		if( input == "sync" or string.match(input, "sync ([0-9]+)") ) then
			if( not self:CheckPermissions() ) then
				return
			end
			
			local seconds = 0
			if( input ~= "sync" ) then
				seconds = string.match(input, "sync ([0-9]+)")
				seconds = tonumber(seconds)
				if( not seconds or seconds >= 60 ) then
					SSPVP:Print(L["Invalid number entered for sync queue."])
					return
				end
			end
			
			-- Make sure we aren't queuing instantly
			if( seconds > 0 ) then
				-- Show queue count down every 5 seconds, or every second if count down is <= 5 seconds
				for i=seconds - 1, 1, -1 do
					if( ( i > 5 and mod(i, 5) == 0 ) or i <= 5 ) then
						self:ScheduleTimer("Message", seconds - i, i)
					end
				end
			end
			
			self:ScheduleTimer("SendQueue", seconds)

			playerStatus = {}
			if( self.frame and self.frame:IsVisible() ) then
				self:UpdateGUI()
			end
			
		-- Cancels a count down
		elseif( input == "cancel" ) then
			self:CancelTimers()
			self:SendMessage(L["Alterac Valley queue stopped."])
			
		-- Drops all confirmed and queued AVs
		elseif( input == "drop" ) then
			if( self:CheckPermissions() ) then
				self:SendMessage(L["Dropping Alterac Valley queues."])
				self:SendAddonMessage("DROP")
				
				-- StinkyQueue support
				SendAddonMessage("StinkyQ", "LeaveQueue", "RAID")
			end
		
		-- Forces a status update
		elseif( input == "update" ) then
			if( self:CheckPermissions() and avStatus ~= "active" ) then
				self:UpdateOverlay()
				self:SendAddonMessage("UPDATE")
			end
		
		elseif( string.match(input, "join ([0-9]+)") ) then
			local instanceID = string.match(input, "join ([0-9]+)")
			instanceID = tonumber(instanceID)
			
			-- Make sure it's valid
			if( not instanceID ) then
				SSPVP:Print(L["You provided an invalid instance ID to join."])
				return
			end
			
			self:SendMessage(string.format(L["Forcing join on instance #%d."], instanceID))
			self:SendAddonMessage("JOIN:" .. instanceID)
		
		-- Ready check
		elseif( input == "ready" ) then
			for _, v in pairs(playerStatus) do
				v.windowStatus = nil
			end
			
			self:SendMessage(L["Battlemaster ready check started, you have 10 seconds to get the window open."])
			
			-- Send request in 10 seconds, check results in 15
			self:CancelTimer("SendAddonMessage")
			self:CancelTimer("CheckResults")
			self:ScheduleTimer("SendAddonMessage", 10, "WINDOW")
			self:ScheduleTimer("CheckResults", 15, "WINDOW")
		
		-- Show status UI of everyone
		elseif( input == "status" ) then
			self:CreateGUI()
			self.frame:Show()
		else
			DEFAULT_CHAT_FRAME:AddMessage(L["SSPVP Alterac Valley slash commands"])
			DEFAULT_CHAT_FRAME:AddMessage(L[" - sync <seconds> - Starts a count down for an Alterac Valley sync queue."])
			DEFAULT_CHAT_FRAME:AddMessage(L[" - cancel - Cancels a running sync."])
			DEFAULT_CHAT_FRAME:AddMessage(L[" - drop - Drops all Alterac Valley queues."])
			DEFAULT_CHAT_FRAME:AddMessage(L[" - ready - Does a check to see who has the battlemaster window open and is ready to queue."])
			DEFAULT_CHAT_FRAME:AddMessage(L[" - update - Forces a status update on everyones Alterac Valley queues."])
			DEFAULT_CHAT_FRAME:AddMessage(L[" - status - Shows the status list of everyone regarding queue or window."])
			DEFAULT_CHAT_FRAME:AddMessage(L[" - join <instanceID> - Forces everyone with the specified instance id to join Alterac Valley."])
		end
	end)
end

function AVSync:OnEnable()
	if( self.db.profile.enabled ) then
		self:RegisterEvent("CHAT_MSG_ADDON")
		self:RegisterEvent("UPDATE_BATTLEFIELD_STATUS")
		self:RegisterEvent("RAID_ROSTER_UPDATE")
	end
end

function AVSync:OnDisable()
	if( self.frame ) then
		self.frame:Hide()

	end
	

	self:UnregisterAllEvents()
	self:CancelAllTimers()
end

function AVSync:Reload()
	self:OnDisable()
	self:OnEnable()
end

-- Window ready check
function AVSync:CheckResults()
	local totalAlready = {}
	local totalNotReady = {}
	
	-- 0 = Not ready, 1 = Ready, 2 = Already AV queued
	for name, data in pairs(playerStatus) do
		if( data.windowStatus == 0 ) then
			table.insert(totalNotReady, author)
		elseif( data.windowStatus == 2 ) then
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
	SSPVP:Print(string.format(L["You have been queued for Alterac Valley by %s."], author))
	JoinBattlefield(0)
end

function AVSync:DropQueue(author)
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
function AVSync:UpdateStatus(type, instanceID, author)
	-- Not force queued, so don't try and monitor it
	if( avStatus == "active" ) then
		return
	end
	
	-- Store our instance # and status
	if( not playerStatus[author] ) then
		playerStatus[author] = {}
		totalRecords = totalRecords + 1
	end

	playerStatus[author].id = tonumber(instanceID) or 0
	playerStatus[author].status = type
	
	if( self.frame and self.frame:IsVisible() ) then
		self:UpdateGUI()
	end
end

-- Maintain a list of everyone
function AVSync:UpdateMemberStatus(unit)
	local name, server = UnitName(unit)
	-- Don't care about people when we're in a battlefield
	if( server ~= "" or server ) then
		return
	end
	
	if( not playerStatus[name] ) then
		playerStatus[name] = {}
		totalRecords = totalRecords + 1
	end
	
	playerStatus[name].class = select(2, UnitClass(unit))
end

function AVSync:RAID_ROSTER_UPDATE()
	self:UpdateMemberStatus("player")
	

	for i=1, GetNumPartyMembers() do
		self:UpdateMemberStatus("party" .. i)
	end
	
	for i=1, GetNumRaidMembers() do
		self:UpdateMemberStatus("raid" .. i)
	end
	
	-- We left group
	if( GetNumPartyMembers() == 0 and GetNumRaidMembers() == 0 ) then
		playerStatus = {}
		totalRecords = 0
	end
	
	if( self.frame and self.frame:IsVisible() ) then
		self:UpdateGUI()
	end
end

-- for updating our current status in AV queue
function AVSync:UPDATE_BATTLEFIELD_STATUS()
	if( GetNumPartyMembers() == 0 and GetNumRaidMembers() == 0 ) then
		return

	end
	

	for i=1, MAX_BATTLEFIELD_QUEUES do
		local status, map, instanceID = GetBattlefieldStatus(i)
		if( map == L["Alterac Valley"] and status ~= avStatus ) then
			self:SendAddonMessage("STATUPDATE:" .. status .. "," .. instanceID)
			avStatus = status
		end
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
				
		-- Version request (for when we add a GUI version)
		elseif( dataType == "PING" and self:CheckUserPermissions(author) ) then
			self:SendAddonMessage("PONG:" .. SSPVP.revision)
		
		-- Store version
		elseif( dataType == "PONG" ) then
			if( not playerStatus[author] ) then
				playerStatus[author] = {}
				totalRecords = totalRecords + 1
			end
			
			playerStatus[author].version = data
			
			if( self.frame and self.frame:IsVisible() ) then
				self:UpdateGUI()
			end
		
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
			
			-- Check if window is open
			if( BattlefieldFrame:IsVisible() and (GetBattlefieldInfo()) == L["Alterac Valley"] ) then
				self:SendAddonMessage("READY")
			else
				self:SendAddonMessage("NOTREADY")
			end
		
		-- Force join
		elseif( dataType == "JOIN" ) then
			-- Make sure we don't have any monkey business going on
			local instanceID = tonumber(data)
			if( not instanceID ) then
				return
			end
			
			for i=1, MAX_BATTLEFIELD_QUEUES do
				local status, map, instance = GetBattlefieldStatus(i)
				if( map == L["Alterac Valley"] and status == "confirm" and instance == instanceID ) then
					if( self.db.profile.forceJoin ) then
						SSPVP:Print(string.format(L["Joining Alterac Valley #%d at the request of %s"], instanceID, author))
						AcceptBattlefieldPort(i, true)
					else
						SSPVP:Print(string.format(L["%s has requested you join Alterac Valley #%d."], author, instanceID))
					end
					break
				end
			end
			
		-- Already queued for AV
		elseif( dataType == "ALRDQUEUED" ) then
			if( not playerStatus[author] ) then
				playerStatus[author] = {}
				totalRecords = totalRecords + 1
			end

			playerStatus[author].windowStatus = 2

			if( self.frame and self.frame:IsVisible() ) then
				self:UpdateGUI()
			end
			
		-- Window open
		elseif( dataType == "READY" ) then
			if( not playerStatus[author] ) then
				playerStatus[author] = {}
				totalRecords = totalRecords + 1
			end

			playerStatus[author].windowStatus = 1

			if( self.frame and self.frame:IsVisible() ) then
				self:UpdateGUI()
			end
		
		-- Window not open
		elseif( dataType == "NOTREADY" ) then
			if( not playerStatus[author] ) then
				playerStatus[author] = {}
				totalRecords = totalRecords + 1
			end

			playerStatus[author].windowStatus = 0

			if( self.frame and self.frame:IsVisible() ) then
				self:UpdateGUI()
			end

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

-- GUI
local function sortColumns(self)
	if( self.type ) then
		if( self.type ~= AVSync.frame.sortType ) then
			AVSync.frame.sortOrder = false
			AVSync.frame.sortType = self.type
		else
			AVSync.frame.sortOrder = not AVSync.frame.sortOrder
		end

		AVSync:UpdateGUI()
	end
end

function AVSync:CreateGUI()
	if( self.frame ) then
		return
	end
	
	-- Container frame
	self.frame = CreateFrame("Frame", "SSAVSyncFrame", UIParent)
	self.frame:SetWidth(600)
	self.frame:SetHeight(325)
	self.frame:SetMovable(true)
	self.frame:EnableMouse(true)
	self.frame:SetClampedToScreen(true)
	self.frame:Hide()
	
	self.frame:SetBackdrop({
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		tile = true,
		tileSize = 32,
		edgeSize = 32,
		insets = {left = 10, right = 10, top = 10, bottom = 10},
	})
	
	self.timeLeft = 0
	self.frame:SetScript("OnShow", function(self)
		-- Immeditially do a window status check
		self.windowLeft = 0
		self.pingLeft = 0
	

		AVSync:RAID_ROSTER_UPDATE()
		AVSync:UpdateGUI()

	end)
	
	-- New window status every 10 seconds, new ping every 60 seconds
	self.frame:SetScript("OnUpdate", function(self, timeElapsed)
		self.windowLeft = self.windowLeft - timeElapsed
		self.pingLeft = self.pingLeft - timeElapsed
		
		if( self.windowLeft <= 0 ) then
			self.windowLeft = 10
			AVSync:SendAddonMessage("WINDOW")
		end
		
		if( self.pingLeft <= 0 ) then
			self.pingLeft = 60
			AVSync:SendAddonMessage("PING")
		end
	end)
	
	-- Location
	AVSync.frame:SetPoint("CENTER")
	SSPVP.modules.Move:RestorePosition("avsync", self.frame)
	
	-- Create the title/movy thing
	local texture = self.frame:CreateTexture(nil, "ARTWORK")
	texture:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
	texture:SetPoint("TOP", 0, 12)
	texture:SetWidth(200)
	texture:SetHeight(60)
	
	local title = CreateFrame("Button", nil, self.frame)
	title:SetPoint("TOP", 0, 4)
	title:SetText(L["Queue Status"])
	title:SetPushedTextOffset(0, 0)

	title:SetTextFontObject(GameFontNormal)
	title:SetHeight(20)
	title:SetWidth(200)
	title:RegisterForDrag("LeftButton")
	title:SetScript("OnDragStart", function(self)
		self.isMoving = true
		AVSync.frame:StartMoving()
	end)
	
	title:SetScript("OnDragStop", function(self)
		if( self.isMoving ) then
			AVSync.frame:StopMovingOrSizing()
			SSPVP.modules.Move:SavePosition("avsync", AVSync.frame)
		end
	end)
	
	-- Close button
	local button = CreateFrame("Button", nil, self.frame, "UIPanelCloseButton")
	button:SetPoint("TOPRIGHT", -4, -4)
	button:SetScript("OnClick", function()
		HideUIPanel(AVSync.frame)
	end)
	
	-- Create our headers
	local nameHeader = CreateFrame("Button", nil, self.frame)
	nameHeader:SetPoint("TOPLEFT", 15, -20)
	nameHeader:SetScript("OnClick", sortColumns)
	nameHeader:SetTextFontObject(GameFontNormal)
	nameHeader:SetText(L["Name"])
	nameHeader:SetHeight(20)
	nameHeader:SetWidth(nameHeader:GetFontString():GetStringWidth() + 2)
	nameHeader.type = "name"

	local queueHeader = CreateFrame("Button", nil, self.frame)
	queueHeader:SetPoint("TOPLEFT", 150, -20)
	queueHeader:SetScript("OnClick", sortColumns)
	queueHeader:SetTextFontObject(GameFontNormal)
	queueHeader:SetText(L["Queue"])
	queueHeader:SetHeight(20)
	queueHeader:SetWidth(queueHeader:GetFontString():GetStringWidth() + 2)
	queueHeader.type = "queue"

	local statusHeader = CreateFrame("Button", nil, self.frame)
	statusHeader:SetPoint("TOPLEFT", 275, -20)
	statusHeader:SetScript("OnClick", sortColumns)
	statusHeader:SetTextFontObject(GameFontNormal)
	statusHeader:SetText(L["Status"])
	statusHeader:SetHeight(22)
	statusHeader:SetWidth(statusHeader:GetFontString():GetStringWidth() + 2)
	statusHeader.type = "status"

	local versionHeader = CreateFrame("Button", nil, self.frame)
	versionHeader:SetPoint("TOPLEFT", 375, -20)
	versionHeader:SetScript("OnClick", sortColumns)
	versionHeader:SetTextFontObject(GameFontNormal)
	versionHeader:SetText(L["Version"])
	versionHeader:SetHeight(22)
	versionHeader:SetWidth(versionHeader:GetFontString():GetStringWidth() + 2)
	versionHeader.type = "version"
	
	-- Our GUI rows
	self.rows = {}
	
	for i=1, 15 do
		local name = self.frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		local queue = self.frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		local status = self.frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		local version = self.frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		
		if( i > 1 ) then
			name:SetPoint("TOPLEFT", self.rows[i - 1], "TOPLEFT", 0, -18)
			queue:SetPoint("TOPLEFT", self.rows[i - 1].queue, "TOPLEFT", 0, -18)
			status:SetPoint("TOPLEFT", self.rows[i - 1].status, "TOPLEFT", 0, -18)
			version:SetPoint("TOPLEFT", self.rows[i - 1].version, "TOPLEFT", 0, -18)
		else
			name:SetPoint("TOPLEFT", nameHeader, "TOPLEFT", 1, -25)
			queue:SetPoint("TOPLEFT", queueHeader, "TOPLEFT", 2, -25)
			status:SetPoint("TOPLEFT", statusHeader, "TOPLEFT", 2, -25)
			version:SetPoint("TOPLEFT", versionHeader, "TOPLEFT", 2, -25)
		end
		
		name:Hide()
		queue:Hide()
		status:Hide()
		version:Hide()

		self.rows[i] = name
		self.rows[i].queue = queue
		self.rows[i].status = status
		self.rows[i].version = version
	end

	-- Scroll frame
	self.frame.scroll = CreateFrame("ScrollFrame", "SSAVSyncScrollFrame", self.frame, "FauxScrollFrameTemplate")
	self.frame.scroll:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 25, -30)
	self.frame.scroll:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", -35, 10)
	self.frame.scroll:SetScript("OnVerticalScroll", function() FauxScrollFrame_OnVerticalScroll(22, self.UpdateGUI) end)
		
	-- Make it act like a real frame
	self.frame:SetAttribute("UIPanelLayout-defined", true)
	self.frame:SetAttribute("UIPanelLayout-enabled", true)
 	self.frame:SetAttribute("UIPanelLayout-area", "doublewide")
	self.frame:SetAttribute("UIPanelLayout-whileDead", true)
	table.insert(UISpecialFrames, "SSAVSyncFrame")
	
	-- Now make the two container backdrops for style
	self.rowFrame = CreateFrame("Frame", nil, self.frame)
	self.rowFrame:SetFrameStrata("LOW")
	self.rowFrame:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 10, -20)
	self.rowFrame:SetHeight(295)
	self.rowFrame:SetWidth(420)
	
	self.rowFrame:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
				edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
				tile = true,
				tileSize = 9,
				edgeSize = 9,
				insets = { left = 2, right = 2, top = 2, bottom = 2 }})	
	self.rowFrame:SetBackdropColor(0, 0, 0, 1)
	self.rowFrame:SetBackdropBorderColor(1, 1, 1, 1)

	-- Stat frame
	self.statFrame = CreateFrame("Frame", nil, self.frame)
	self.statFrame:SetFrameStrata("LOW")
	self.statFrame:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", -35, -20)
	self.statFrame:SetHeight(295)
	self.statFrame:SetWidth(130)
	
	self.statFrame:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
				edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
				tile = true,
				tileSize = 9,
				edgeSize = 9,
				insets = { left = 2, right = 2, top = 2, bottom = 2 }})	
	self.statFrame:SetBackdropColor(0, 0, 0, 1.0)
	self.statFrame:SetBackdropBorderColor(1, 1, 1, 1)

	-- Add our stat infos
	-- TOTAL PLAYERS
	self.totalPlayersText = self.frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	self.totalPlayersText:SetPoint("TOPLEFT", self.statFrame, "TOPLEFT", 8, -5)
	self.totalPlayersText:SetText(L["Total Players"])

	self.totalPlayers = self.frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	self.totalPlayers:SetPoint("TOPRIGHT", self.statFrame, "TOPRIGHT", -8, -5)

	-- TOTAL READY
	self.totalReadyText = self.frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	self.totalReadyText:SetPoint("TOPLEFT", self.statFrame, "TOPLEFT", 8, -25)
	self.totalReadyText:SetText(L["Ready"])

	self.totalReady = self.frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	self.totalReady:SetPoint("TOPRIGHT", self.statFrame, "TOPRIGHT", -8, -25)

	-- TOTAL NOT READY
	self.totalNotreadyText = self.frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	self.totalNotreadyText:SetPoint("TOPLEFT", self.statFrame, "TOPLEFT", 8, -45)
	self.totalNotreadyText:SetText(L["Not Ready"])
	
	self.totalNotready = self.frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	self.totalNotready:SetPoint("TOPRIGHT", self.statFrame, "TOPRIGHT", -8, -45)

	-- TOTAL UNKNOWN
	self.totalUnknownText = self.frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	self.totalUnknownText:SetPoint("TOPLEFT", self.statFrame, "TOPLEFT", 8, -65)
	self.totalUnknownText:SetText(L["Unknown"])

	self.totalUnknown = self.frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	self.totalUnknown:SetPoint("TOPRIGHT", self.statFrame, "TOPRIGHT", -8, -65)
end

function AVSync:UpdateGUI()
	local self = AVSync
	self:CreateGUI()	
	
	FauxScrollFrame_Update(self.frame.scroll, totalRecords, 15, 22)
		
	local i = 0
	local usedRows = 0
	local totalReady = 0
	local totalNotready = 0
	local totalUnknown = 0
	
	for name, data in pairs(playerStatus) do
		i = i + 1
		-- Start displaying once we've passed the offset
		if( i >= FauxScrollFrame_GetOffset(self.frame.scroll) and usedRows < 15 ) then
			usedRows = usedRows + 1
			local row = self.rows[usedRows]
			
			-- Set name/color by class
			row:SetText(name)
			if( data.class and RAID_CLASS_COLORS[data.class] ) then
				row:SetVertexColor(RAID_CLASS_COLORS[data.class].r, RAID_CLASS_COLORS[data.class].g, RAID_CLASS_COLORS[data.class].b)
			else
				row:SetVertexColor(0.50, 0.50, 0.50)
			end
			
			-- Show queue status
			if( data.id and data.status ) then
				-- Queued for AV
				if( data.status == "queued" ) then
					if( data.id == 0 ) then
						row.queue:SetText(L["Queued Any"])
					else
						row.queue:SetFormattedText(L["Queued #%d"], data.id)
					end
					
					row.queue:SetVertexColor(0, 1, 0)
				
				-- Ready to join
				elseif( data.status == "confirm" ) then
					row.queue:SetFormattedText(L["Confirm #%d"], data.id)
					row.queue:SetVertexColor(0, 1, 0)
				
				-- Inside
				elseif( data.status == "active" ) then
					row.queue:SetFormattedText(L["Inside #%d"], data.id)
					row.queue:SetVertexColor(1, 1, 1)
				
				-- Not queued, something is broken
				else
					row.queue:SetText(L["Not queued"])
					row.queue:SetVertexColor(1, 1, 1)
				end
			
			-- No data found, or bad data sent
			else
				row.queue:SetText(L["Unknown"])
				row.queue:SetVertexColor(1, 0, 0)
			end
			
			-- Actual status
			if( not UnitIsConnected(name) ) then
				row.status:SetText(L["Offline"])
				row.status:SetVertexColor(0.50, 0.50, 0.50)
			elseif( UnitIsAFK(name) ) then
				row.status:SetText(L["AFK"])
				row.status:SetVertexColor(1, 0, 0)
			elseif( data.windowStatus == 0 ) then
				row.status:SetText(L["Not ready"])
				row.status:SetVertexColor(1, 0, 0)
			elseif( data.windowStatus == 1 ) then
				row.status:SetText(L["Ready"])
				row.status:SetVertexColor(0, 1, 0)
			else
				row.status:SetText(L["Online"])
				row.status:SetVertexColor(0, 1, 0)
			end
			
			-- Version
			if( data.version ) then
				row.version:SetText(data.version)
				row.version:SetVertexColor(0, 1, 0)
			else
				row.version:SetText("----")
				row.version:SetVertexColor(0.50, 0.50, 0.50)
			end
			
			
			row:Show()
			row.queue:Show()
			row.status:Show()
			row.version:Show()
		end
		
		-- Update stats
		if( data.windowStatus == 1 ) then
			totalReady = totalReady + 1
		elseif( data.windowStatus == 0 ) then
			totalNotready = totalNotready + 1
		else
			totalUnknown = totalUnknown + 1
		end
	end

	-- Set stats
	self.totalPlayers:SetText(totalRecords)
	self.totalReady:SetText(totalReady)
	self.totalNotready:SetText(totalNotready)
	self.totalUnknown:SetText(totalUnknown)
	
	-- Hide unused rows
	for i=usedRows + 1, 15 do
		self.rows[i]:Hide()
		self.rows[i].queue:Hide()
		self.rows[i].status:Hide()
		self.rows[i].version:Hide()
	end
end

-- Make our lifes easier
function AVSync:SendMessage(msg)
	local type = "PARTY"
	if( GetNumRaidMembers() > 0 ) then
		type = "RAID"
	end
	
	SendChatMessage(msg, type)
end

function AVSync:SendAddonMessage(msg)
	SendAddonMessage("SSAV", msg, "RAID")
end
