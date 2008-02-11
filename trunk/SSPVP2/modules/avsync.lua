local AVSync = SSPVP:NewModule("AVSync", "AceEvent-3.0", "AceTimer-3.0", "AceConsole-3.0")
AVSync.activeIn = "bf"

local L = SSPVPLocals

local playerStatus = {}
local avStatus, skipStinky

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
			local seconds = 0
			if( input ~= "sync" ) then
				seconds = string.match(input, "sync ([0-9]+)")
				seconds = tonumber(seconds)
				if( not seconds or seconds >= 60 ) then
					SSPVP:Print(L["Invalid number entered for sync queue."])
					return
				end
			end

			self:StartCountdown(seconds)
			
		-- Cancels a count down
		elseif( input == "cancel" ) then
			self:CancelAllTimers()
			self:SendMessage(L["Alterac Valley queue stopped."])
			
		-- Drops all confirmed and queued AVs
		elseif( input == "drop" ) then
			self:SendDropQueue()
			
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
			self:ReadyCheck()
			
		-- Show status UI of everyone
		elseif( input == "status" ) then
			if( GetNumPartyMembers() == 0 and GetNumRaidMembers() == 0 ) then
				SSPVP:Print(L["You must be in a raid or party to do this."])
				return
			end
			
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
		self:RegisterEvent("RAID_ROSTER_UPDATE", "UpdateGroup")
		
		-- So we don't have to do polling of window status
		if( not BattlefieldFrame.SSHooked ) then
			BattlefieldFrame.SSHooked = true
			BattlefieldFrame:HookScript("OnShow", function()
				if( ( GetNumPartyMembers() > 0 or GetNumRaidMembers() > 0 ) and (GetBattlefieldInfo()) == L["Alterac Valley"] ) then
					AVSync:SendAddonMessage("READY")
				end
			end)
			BattlefieldFrame:HookScript("OnHide", function()
				if( ( GetNumPartyMembers() > 0 or GetNumRaidMembers() > 0 ) and (GetBattlefieldInfo()) == L["Alterac Valley"] ) then
					AVSync:SendAddonMessage("NOTREADY")
				end
			end)
		end
	end
end

function AVSync:OnDisable()
	if( self.frame ) then
		self.frame:Hide()

	end
	

	self:UnregisterAllEvents()
	self:CancelAllTimers()
end

function AVSync:EnableModule()
	self:UnregisterEvent("RAID_ROSTER_UPDATE")
end

function AVSync:DisableModule()
	if( self.db.profile.enabled ) then

		self:RegisterEvent("RAID_ROSTER_UPDATE", "UpdateGroup")
		
		-- Reset our table
		for i=#(playerStatus), 1, -1 do
			table.remove(playerStatus, i)
		end
	end
end

function AVSync:Reload()
	self:OnDisable()
	self:OnEnable()
end

-- Start the check
function AVSync:ReadyCheck()
	-- Reset window status
	for _, v in pairs(playerStatus) do
		v.windowStatus = nil
	end
	
	if( self.frame and self.frame:IsVisible() ) then
		self:UpdateGUI()
	end

	self:SendMessage(L["Battlemaster window ready check started, you have 10 seconds to get the window open."])

	-- Send request in 10 seconds, check results in 15
	self:CancelTimer("SendAddonMessage", true)
	self:CancelTimer("CheckResults", true)
	
	self:ScheduleTimer("SendAddonMessage", 10, "WINDOW")
	self:ScheduleTimer("CheckResults", 15, "WINDOW")
end

-- Window ready check
function AVSync:CheckResults()
	local totalNotReady = {}
	
	for _, data in pairs(playerStatus) do
		if( data.windowStatus == "notready" or data.windowStatus == "already" ) then
			table.insert(totalNotReady, data.name)
		end
	end
		
	if( #(totalNotReady) == 0 ) then
		self:SendMessage(L["Everyone is ready to go!"])
	else
		self:SendMessage(string.format(L["Not Ready: %s"], table.concat(totalNotReady, ", ")))
	end
end

-- Send drop queue
function AVSync:SendDropQueue()
	if( self:CheckPermissions() ) then
		self:SendMessage(L["Leaving Alterac Valley queues."])
		self:SendAddonMessage("DROP")

		-- StinkyQueue support
		SendAddonMessage("StinkyQ", "LeaveQueue", "RAID")
	end
end

-- Start a queue count down
function AVSync:StartCountdown(seconds)
	if( not self:CheckPermissions() ) then
		return
	end

	-- Make sure we aren't queuing instantly
	if( seconds > 0 ) then
		seconds = seconds + 1
		
		-- Show queue count down every 5 seconds, or every second if count down is <= 5 seconds
		for i=seconds - 1, 1, -1 do
			if( ( i > 5 and mod(i, 5) == 0 ) or i <= 5 ) then
				self:ScheduleTimer("Message", seconds - i, i)
			end
		end
	end

	self:ScheduleTimer("SendQueue", seconds)
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
		self:SendMessage(string.format(L["Queuing %d seconds."], seconds))
	else
		self:SendMessage(string.format(L["Queuing %d second."], seconds))
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
			SSPVP:Print(string.format(L["Alterac Valley queue has been dropped by %s."], author))
			StaticPopupDialogs["CONFIRM_PORT_LEAVE"].OnAccept(i)
			break
		end
	end
end

-- Save us from having to redo the code 5000 times
-- I'll improve this a little later
function AVSync:UpdateRecord(name, field1, value1, field2, value2, field3, value3)
	for _, data in pairs(playerStatus) do
		if( data.name == name ) then
			data.hide = nil
			data[field1] = value1
			
			if( field2 ) then
				data[field2] = value2

				if( field3 ) then
					data[field3] = value3
				end
			end

			-- Update display
			if( self.frame and self.frame:IsVisible() ) then
				self:UpdateGUI()
			end
			return
		end

	end
	
	local data = {version = -1, queueSort = "", name = name, [field1] = value1}
	
	if( field2 ) then
		data[field2] = value2

		if( field3 ) then
			data[field3] = field3
		end
	end
	
	table.insert(playerStatus, data)

	-- Update display
	if( self.frame and self.frame:IsVisible() ) then
		self:UpdateGUI()
	end
end

function AVSync:UpdateGroup()
	-- We left group
	if( GetNumPartyMembers() == 0 and GetNumRaidMembers() == 0 ) then
		return
	end
	
	-- If someone left, we don't want to show them so flag everyone as hidden
	for _, data in pairs(playerStatus) do
		data.hide = true
	end

	-- Update player status
	self:UpdateRecord(UnitName("player"), "class", select(2, UnitClass("player")), "online", UnitIsConnected("player"), "afk", UnitIsAFK("player"))
	

	-- Update party status
	for i=1, GetNumPartyMembers() do
		local unit = "party" .. i
		local name, server = UnitName(unit)
		if( not server or server == "" ) then
			self:UpdateRecord(name, "class", select(2, UnitClass(unit)), "online", UnitIsConnected(unit), "afk", UnitIsAFK(unit))
		end
	end
	
	-- Update raid status
	for i=1, GetNumRaidMembers() do
		local unit = "raid" .. i
		local name, server = UnitName(unit)
		if( not server or server == "" ) then
			self:UpdateRecord(name, "class", select(2, UnitClass(unit)), "online", UnitIsConnected(unit), "afk", UnitIsAFK(unit))
		end
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
			data = tonumber(data) or 0
			self:UpdateRecord(author, "version", data)
			
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
			self:UpdateRecord(author, "windowStatus", "already")
			
		-- Window open
		elseif( dataType == "READY" ) then
			self:UpdateRecord(author, "windowStatus", "ready")
		
		-- Window not open
		elseif( dataType == "NOTREADY" ) then
			self:UpdateRecord(author, "windowStatus", "notready")

		-- Queue updates
		elseif( dataType == "STATUPDATE" ) then
			local type, instanceID = string.split(",", data)
			self:UpdateRecord(author, "id", tonumber(instanceID) or 0, "status", type, "queueSort", type .. instanceID)
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
		type = "RAID"
	end
	
	SendChatMessage(msg, type)
end

function AVSync:SendAddonMessage(msg)
	if( self.db.profile.enabled ) then
		SendAddonMessage("SSAV", msg, "RAID")
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

-- I'm not thrilled with this method, but it's the simplest way because
-- we have multiple fields we need to check
local function getSortID(data)
	local id = 0
	if( not data.online ) then
		id = 4
	elseif( data.afk ) then
		id = 3
	elseif( data.windowStatus == "notready" or data.windowStatus == "already" ) then
		id = 2
	elseif( data.windowStatus == "ready" ) then
		id = 1
	end
	
	return id
end

local function sortList(a, b)
	if( not a ) then
		return true

	elseif( not b ) then
		return false
	end
		
	if( AVSync.frame.sortOrder ) then
		if( AVSync.frame.sortType == "queue" ) then
			return a.queueSort < b.queueSort
		elseif( AVSync.frame.sortType == "status" ) then
			return getSortID(a) < getSortID(b)
		elseif( AVSync.frame.sortType == "version" ) then
			return a.version < b.version
		end
	
		return a.name < b.name
	else
		if( AVSync.frame.sortType == "queue" ) then
			return a.queueSort > b.queueSort
		elseif( AVSync.frame.sortType == "status" ) then
			return getSortID(a) > getSortID(b)
		elseif( AVSync.frame.sortType == "version" ) then
			return a.version > b.version
		end
		
		return a.name > b.name
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
	self.frame.sortType = "name"
	self.frame.sortOrder = true
	self.frame:Hide()
	
	self.frame:SetBackdrop({
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		tile = true,
		tileSize = 32,
		edgeSize = 32,
		insets = {left = 10, right = 10, top = 10, bottom = 10},
	})
	
	self.frame:SetScript("OnShow", function(self)
		-- Immeditially do a window status check
		self.statusLeft = 0
		self.pingLeft = 0
	

		AVSync:UpdateGroup()
		AVSync:UpdateGUI()

	end)
	
	-- POLING R EFICIENT
	self.frame:SetScript("OnUpdate", function(self, timeElapsed)
		self.statusLeft = self.statusLeft - timeElapsed
		self.pingLeft = self.pingLeft - timeElapsed
		
		-- We actually care about afk/online/offline status
		if( self.statusLeft <= 0 ) then
			self.statusLeft = 9.9
			AVSync:UpdateGroup()
		end
		
		-- Window and pings aren't that important, so only do it once a minute
		if( self.pingLeft <= 0 ) then
			self.pingLeft = 60
			AVSync:SendAddonMessage("PING")
			AVSync:SendAddonMessage("WINDOW")
		end

		AVSync.nextUpdate:SetFormattedText("%.1f", self.statusLeft)
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
	
	local backdrop = {bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = true,
			tileSize = 9,
			edgeSize = 9,
			insets = { left = 2, right = 2, top = 2, bottom = 2 }}
	
	-- Now make the two container backdrops for style
	self.leftContainer = CreateFrame("Frame", nil, self.frame)
	self.leftContainer:SetFrameStrata("LOW")
	self.leftContainer:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 10, -20)
	self.leftContainer:SetHeight(295)
	self.leftContainer:SetWidth(420)
	
	self.leftContainer:SetBackdrop(backdrop)	
	self.leftContainer:SetBackdropColor(0, 0, 0, 1)
	self.leftContainer:SetBackdropBorderColor(0.75, 0.75, 0.75, 1)

	-- Stat frame
	self.rightContainer = CreateFrame("Frame", nil, self.frame)
	self.rightContainer:SetFrameStrata("LOW")
	self.rightContainer:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", -35, -20)
	self.rightContainer:SetHeight(295)
	self.rightContainer:SetWidth(130)
	
	self.rightContainer:SetBackdrop(backdrop)	
	self.rightContainer:SetBackdropColor(0, 0, 0, 1)
	self.rightContainer:SetBackdropBorderColor(0.75, 0.75, 0.75, 1)

	-- Add our stat infos
	-- PLAYERS
	local text = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	text:SetPoint("TOPLEFT", self.rightContainer, "TOPLEFT", 8, -5)
	text:SetText(L["Total Players"])

	self.totalPlayers = self.frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	self.totalPlayers:SetPoint("TOPLEFT", self.rightContainer, "TOPLEFT", 105, -5)

	-- READY
	local text = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	text:SetPoint("TOPLEFT", self.rightContainer, "TOPLEFT", 8, -25)
	text:SetText(L["Ready"])

	self.totalReady = self.frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	self.totalReady:SetPoint("TOPLEFT", self.rightContainer, "TOPLEFT", 105, -25)
	self.totalReady:SetText(0)

	-- NOT READY
	local text = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	text:SetPoint("TOPLEFT", self.rightContainer, "TOPLEFT", 8, -45)
	text:SetText(L["Not Ready"])
	
	self.totalNotready = self.frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	self.totalNotready:SetPoint("TOPLEFT", self.rightContainer, "TOPLEFT", 105, -45)
	self.totalNotready:SetText(0)

	-- UNKNOWN
	local text = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	text:SetPoint("TOPLEFT", self.rightContainer, "TOPLEFT", 8, -65)
	text:SetText(L["Unknown"])

	self.totalUnknown = self.frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	self.totalUnknown:SetPoint("TOPLEFT", self.rightContainer, "TOPLEFT", 105, -65)
	self.totalUnknown:SetText(0)
	
	-- NEXT UPDATE
	local text = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	text:SetPoint("TOPLEFT", self.rightContainer, "TOPLEFT", 8, -95)
	text:SetText(L["Next Update"])

	self.nextUpdate = self.frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	self.nextUpdate:SetPoint("TOPLEFT", self.rightContainer, "TOPLEFT", 105, -95)
	self.nextUpdate:SetText("--")

	-- NEW VERSION
	self.newVersion = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	self.newVersion:SetPoint("TOPLEFT", self.rightContainer, "TOPLEFT", 8, -150)
	self.newVersion:SetText(L["New version available!"])
	self.newVersion:SetTextColor(1, 0, 0)
	self.newVersion:Hide()
	
	-- DROP QUEUE
	self.dropQueue = CreateFrame("Button", nil, self.rightContainer, "UIPanelButtonGrayTemplate")
	self.dropQueue:SetFrameStrata("MEDIUM")
	self.dropQueue:SetPoint("BOTTOMLEFT", self.rightContainer, "BOTTOMLEFT", 4, 5)
	self.dropQueue:SetScript("OnClick", function()
		StaticPopup_Show("CONFIRM_QUEUE_DROP")

	end)
	self.dropQueue:SetText(L["Drop Queue"])
	self.dropQueue:SetWidth(125)
	self.dropQueue:SetHeight(16)
	
	-- SYNC QUEUE
	self.syncQueue = CreateFrame("Button", nil, self.rightContainer, "UIPanelButtonGrayTemplate")
	self.syncQueue:SetFrameStrata("MEDIUM")
	self.syncQueue:SetPoint("BOTTOMLEFT", self.rightContainer, "BOTTOMLEFT", 4, 25)
	self.syncQueue:SetScript("OnClick", function()
		AVSync:StartCountdown(3)
	end)
	self.syncQueue:SetText(L["Sync Queue"])
	self.syncQueue:SetWidth(125)
	self.syncQueue:SetHeight(16)
	
	-- READY CHECK
	self.readyQueue = CreateFrame("Button", nil, self.rightContainer, "UIPanelButtonGrayTemplate")
	self.readyQueue:SetFrameStrata("MEDIUM")
	self.readyQueue:SetPoint("BOTTOMLEFT", self.rightContainer, "BOTTOMLEFT", 4, 45)
	self.readyQueue:SetScript("OnClick", function()
		AVSync:ReadyCheck()
		AVSync:UpdateGUI()

	end)
	self.readyQueue:SetText(L["Ready Check"])
	self.readyQueue:SetWidth(125)
	self.readyQueue:SetHeight(16)
end

function AVSync:UpdateGUI()
	self:CreateGUI()	
	
	table.sort(playerStatus, sortList)
	FauxScrollFrame_Update(self.frame.scroll, #(playerStatus), 15, 22)
		
	local usedRows = 0
	for id, data in pairs(playerStatus) do
		if( not data.hide and id >= FauxScrollFrame_GetOffset(self.frame.scroll) and usedRows <= 15 ) then
			usedRows = usedRows + 1
			
			local row = self.rows[usedRows]
		
			-- Set name/color by class
			row:SetText(data.name)
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
			if( not data.online ) then
				row.status:SetText(L["Offline"])
				row.status:SetVertexColor(0.50, 0.50, 0.50)
			elseif( data.afk ) then
				row.status:SetText(L["AFK"])
				row.status:SetVertexColor(1, 0, 0)
			elseif( data.windowStatus == "notready" or data.windowStatus == "already" ) then
				row.status:SetText(L["Not ready"])
				row.status:SetVertexColor(1, 0, 0)
			elseif( data.windowStatus == "ready" ) then
				row.status:SetText(L["Ready"])
				row.status:SetVertexColor(0, 1, 0)
			else
				row.status:SetText(L["Online"])
				row.status:SetVertexColor(0, 1, 0)
			end
			
			-- Version
			if( data.version > 0 ) then
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
	end
	
	-- Hide unused
	for i=usedRows + 1, 15 do
		local row = self.rows[i]
		row:Hide()
		row.queue:Hide()
		row.status:Hide()
		row.version:Hide()
	end
	
	-- Figure out stats
	local totalPlayers = 0
	local totalReady = 0
	local totalNotready = 0
	local totalUnknown = 0
	for _, data in pairs(playerStatus) do
		if( not data.hide ) then
			if( data.windowStatus == "ready" ) then
				totalReady = totalReady + 1
			elseif( data.windowStatus == "notready" or data.windowStatus == "already" ) then
				totalNotready = totalNotready + 1
			else
				totalUnknown = totalUnknown + 1
			end
			
			totalPlayers = totalPlayers + 1
		end
		
		-- New version available
		if( data.version > SSPVP.revision ) then
			self.newVersion:Show()
		end
	end

	self.totalPlayers:SetText(totalPlayers)
	self.totalReady:SetText(totalReady)
	self.totalNotready:SetText(totalNotready)
	self.totalUnknown:SetText(totalUnknown)
	
	-- Disable/enable our quick buttons
	if( IsPartyLeader() or IsRaidLeader() or IsRaidOfficer() ) then
		self.dropQueue:Enable()
		self.syncQueue:Enable()
		self.readyQueue:Enable()
	else
		self.dropQueue:Disable()
		self.syncQueue:Disable()
		self.readyQueue:Disable()
	end
end

-- Make sure you want to drop queue through GUI
StaticPopupDialogs["CONFIRM_QUEUE_DROP"] = {
	text = L["You are about to send a queue drop request, are you sure?"],
	button1 = TEXT(YES),
	button2 = TEXT(NO),
	OnAccept = function()
		AVSync:SendDropQueue()
	end,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 1,
	multiple = 0,
}
