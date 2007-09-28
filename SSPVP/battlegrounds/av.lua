local AV = SSPVP:NewModule("SSPVP-AV")
AV.activeIn = "av"

local L = SSPVPLocals
local abbrevByName = {}
local flavorItems = {}
local dataSent = {}
local timers = {}
local intervalAlerts = {}

function AV:Initialize()
	self:RegisterMessage("SS_QUEUEAV_REQ", "SyncQueue")
	self:RegisterMessage("SS_CANCELAV_REQ", "ClearSyncOverlay")
	self:RegisterMessage("SS_QUEUECD_DATA", "SyncOverlay")
	
	SSPVP.cmd:RegisterSlashHandler(L["sync <count> - Starts an Alterac Valley sync queue count down."], "sync (%d+)", self.StartAVSync)
	SSPVP.cmd:RegisterSlashHandler(L["cancel - Cancels a running sync count down."], "cancel", self.CancelSync)

	SSOverlay:AddCategory("av", L["Timers"], nil, AV, "PrintAllTimers")
	SSOverlay:AddCategory("avitems", L["Item Tracker"])
	
	-- Reverse it to name -> abbrev for syncing
	for abbrev, name in pairs(L["AVNodes"]) do
		abbrevByName[name] = abbrev
	end
	
	table.insert(flavorItems, {text = L["Armor Scraps"], id = 17422, type = "armor"})
	
	-- Figure out which flavor items to use
	if( UnitFactionGroup("player") == "Alliance" ) then
		table.insert(flavorItems, {text = L["Storm Crystals"], id = 17423, type = "crystal"})
		table.insert(flavorItems, {text = L["Soldiers Medal"], id = 17502, type = "medal"})
		table.insert(flavorItems, {text = L["Lieutenants Medal"], id = 17503, type = "medal"})
		table.insert(flavorItems, {text = L["Commanders Medal"], id = 17504, type = "medal"})
	else
		table.insert(flavorItems, {text = L["Soldiers Blood"], id = 17306, type = "crystal"})
		table.insert(flavorItems, {text = L["Soldiers Flesh"], id = 17326, type = "medal"})
		table.insert(flavorItems, {text = L["Lieutenants Flesh"], id = 17327, type = "medal"})
		table.insert(flavorItems, {text = L["Commanders Flesh"], id = 17328, type = "medal"})
	end
end

function AV:EnableModule()
	self:RegisterEvent("CHAT_MSG_MONSTER_YELL", "ParseYell")
	self:RegisterEvent("CHAT_MSG_BG_SYSTEM_HORDE", "ParseHorde")
	self:RegisterEvent("CHAT_MSG_BG_SYSTEM_ALLIANCE", "ParseAlliance")
	self:RegisterEvent("CHAT_MSG_PARTY", "ParseQueueMsg")
	self:RegisterEvent("CHAT_MSG_RAID", "ParseQueueMsg")

	self:RegisterMessage("SS_AVTIMERS_REQ", "ResponseDelay")
	self:RegisterMessage("SS_AVTIMERS_DATA", "ParseSync")

	PVPSync:SendMessage("AVTIMERS")
	
	for _, item in pairs(flavorItems) do
		if( SSPVP.db.profile.av[item.type] ) then
			SSOverlay:UpdateItem("avitems", item.text .. ": %d", item.id)
		end
	end
end

function AV:DisableModule()
	timers = {}
	dataSent = {}

	self:UnregisterAllMessages()
	self:UnregisterAllEvents()
	
	SSOverlay:RemoveCategory("av")
	SSOverlay:RemoveCategory("avitems")
end

function AV:Reload()
	if( SSPVP:IsPlayerIn("av") ) then
		if( not SSPVP.db.profile.av.enabled ) then
			for timerID, _ in pairs(intervalAlerts) do
				SSPVP:CancelTimer(timerID)
				intervalAlerts[timerID] = nil
			end
		end
		
		SSOverlay:RemoveCategory("avitems")

		for _, item in pairs(flavorItems) do
			if( SSPVP.db.profile.av[item.type] ) then
				SSOverlay:UpdateItem("avitems", item.text .. ": %d", item.id)
			end
		end
		
		PVPSync:SendMessage("AVTIMERS")
	end
end

-- Print all timers to chat
function AV:PrintAllTimers()
	for name, timer in pairs(timers) do
		SSPVP:MessageTimer(name, timer.endTime, timer.faction)
	end
end

-- Sync queue message
function AV:SyncOverlay(event, seconds)
	SSOverlay:UpdateTimer("av", L["Sync Queueing: %s"], seconds)
end

-- Canceled sync queue
function AV:ClearSyncOverlay()
	if( SSPVP.db.profile.av.blocked ) then
		SSPVP:Print(L["Alterac Valley sync queue has been canceled!"])
	end
	
	SSOverlay:RemoveRow("timer", "av", L["Sync Queueing: %s"])
end

-- Sync queue!
function AV:SyncQueue()
	if( (GetBattlefieldInfo()) == L["Alterac Valley"] ) then
		SSPVP:Print(string.format(L["You have been queued for Alterac Valley by %s."], arg4))

		JoinBattlefield(0)
		HideUIPanel(BattlefieldFrame)
	end
end

-- Send capture timers
function AV:SendTimers()
	local send = {}
	local currentTime = GetTime()

	for name, timer in pairs(timers) do
		-- We've already seen the data sent, ignore it.
		if( not dataSent[name] ) then
			local faction
			if( timer.faction == "Alliance" ) then
				faction = "A"
			elseif( timer.faction == "Horde" ) then
				faction = "H"
			end
			
			local seconds = math.floor(timer.endTime - currentTime)
			if( seconds > 0 ) then
				table.insert(send, abbrevByName[name] .. ":" .. faction .. ":" .. seconds)
			end
		end
	end
	
	if( #(send) > 0 ) then
		PVPSync:SendMessage( "AVTIMERS:TIME:T:0," .. table.concat(send, ","))
	end
end

-- Send timers within 1-5 seconds
function AV:ResponseDelay()
	if( not SSPVP.db.profile.av.timers ) then
		return
	end

	dataSent = {}
	SSPVP:ScheduleTimer("SSAVTIMERS", self.SendTimers, math.random(5))
end

-- Parse sync
function AV:ParseSync(event, ...)
	if( not SSPVP.db.profile.av.timers ) then
		return
	end
	
	for i=1, select("#", ...) do
		local abbrev, factionAbbrev, seconds = string.split(":", (select(i, ...)))
	
		seconds = tonumber(seconds)
		
		-- Invalid data sent, stop parsing
		if( not abbrev or not factionAbbrev or not seconds or seconds < 0 ) then
			return
		end
		
		-- Originally we used GetTime() to resync the timers
		-- This was removed due to constitancies issues with GetTime()
		-- between users
		if( i > 1 ) then
			local name = L["AVNodes"][abbrev]
			-- Invalid abbrev or time received, stop parsing.
			if( not name ) then
				return
			end
						
			-- We've seen the data sent, ignore it if we ever send it ourself
			dataSent[name] = true
			
			-- We don't have an active timer, so it's okay to add a new one
			if( not timers[name] ) then
				local faction
				if( factionAbbrev == "A" ) then
					faction = "Alliance"	
				elseif( factionAbbrev == "H" ) then
					faction = "Horde"	
				end
				
				-- Gods have specific text that we don't store, so check for them quickly
				if(abbrev == "IVUS") then
					SSOverlay:UpdateTimer("av", L["Ivus the Forest Lord Moving: %s"], seconds, SSOverlay:GetFactionColor(faction))
				elseif(abbrev == "LOKH" ) then
					SSOverlay:UpdateTimer("av", L["Lokholar the Ice Lord Moving: %s"], seconds, SSOverlay:GetFactionColor(faction))
				else
					SSOverlay:UpdateTimer("av", name .. ": %s", seconds, SSOverlay:GetFactionColor(faction))
					self:StartIntervalAlerts(name, faction, seconds)
				end

				SSOverlay:AddOnClick("timer", "av", name .. ": %s", SSPVP, "PrintTimer", name, GetTime() + seconds, faction)
				timers[ name ] = {faction = faction, endTime = GetTime() + seconds}
			end
		end
	end
end

-- Block the annoying status messages, or change them into useful ones
-- Also reformat Herald yells into consitantly colored ones like EOTS/AB/WSG
local Orig_ChatFrame_OnEvent = ChatFrame_OnEvent
function ChatFrame_OnEvent(event, ...)
	if( event == "CHAT_MSG_MONSTER_YELL" ) then
		if( arg2 == L["Herald"] ) then
			if( string.match(arg1, L["Alliance"]) ) then
				SSPVP:Message(arg1, SSOverlay:GetFactionColor("Alliance"))
				return
				
			elseif( string.match(arg1, L["Horde"]) ) then
				SSPVP:Message(arg1, SSOverlay:GetFactionColor("Horde"))
				return
			end
			
		elseif( arg2 == L["Vanndar Stormpike"] ) then
			if( string.match(arg1, L["Soldiers of Stormpike, your General is under attack"]) ) then
				SSPVP:Message(L["The Horde have engaged Vanndar Stormpike."], SSOverlay:GetFactionColor("Horde") )
				return
			
			elseif( string.match(arg1, L["Why don't ya try again"]) ) then
				SSPVP:Message(L["The Horde have reset Vanndar Stormpike."], SSOverlay:GetFactionColor("Horde") )
				return

			elseif( string.match(arg1, L["You'll never get me out of me"]) ) then
				return
			end
		
		elseif( arg2 == L["Drek'Thar"] ) then
			if( string.match(arg1, L["Stormpike filth!"]) ) then
				SSPVP:Message(L["The Alliance have engaged Drek'Thar."], SSOverlay:GetFactionColor("Alliance"))
				return
				
			elseif( string.match(arg1, L["You seek to draw the General of the Frostwolf"]) ) then
				SSPVP:Message(L["The Alliance have reset Drek'Thar."], SSOverlay:GetFactionColor("Alliance"))
				return

			elseif( string.match(arg1, L["Stormpike weaklings"]) ) then
				return
			end
			
		elseif( arg2 == L["Captain Balinda Stonehearth"] ) then
			if( string.match(arg1, L["Begone, uncouth scum!"]) ) then
				SSPVP:Message(L["The Horde have engaged Captain Balinda Stonehearth."], SSOverlay:GetFactionColor("Horde"))
				return
			
			elseif( string.match(arg1, L["Filthy Frostwolf cowards"]) ) then
				SSPVP:Message(L["The Horde have reset Captain Balinda Stonehearth."], SSOverlay:GetFactionColor("Horde"))
				return
			end
		
		elseif( arg2 == L["Captain Galvangar"] ) then
			if( string.match(arg1, L["Your kind has no place in Alterac Valley"]) ) then
				SSPVP:Message(L["The Alliance have engaged Captain Galvangar."], SSOverlay:GetFactionColor("Alliance"))
				return
				
			elseif( string.match(arg1, L["I'll never fall for that, fool!"]) ) then
				SSPVP:Message(L["The Alliance have reset Captain Galvangar."], SSOverlay:GetFactionColor("Alliance"))
				return
			end
		
		elseif( string.match(arg2, L["(.+) Warmaster"]) or string.match(arg2, L["(.+) Marshal"]) ) then
			return
		end
	end
	
	return Orig_ChatFrame_OnEvent(event, ...)
end

-- Start the "X seconds until Blah is captured" messages
function AV:StartIntervalAlerts(name, faction, secondsLeft)
	if( not SSPVP.db.profile.av.enabled or SSPVP.db.profile.av.interval < 30 ) then
		return
	end
	
	secondsLeft = math.floor(secondsLeft)
	
	-- We're only allowed one timer with the same name
	-- so need to make a name based off this info
	local timerID = name .. faction .. secondsLeft
	intervalAlerts[timerID] = true

	for seconds=1, secondsLeft - 1 do
		local interval
		if( seconds <= 120 and SSPVP.db.profile.av.speed > 0 ) then
			interval = math.floor(SSPVP.db.profile.av.interval * SSPVP.db.profile.av.speed)
		else
			interval = SSPVP.db.profile.av.interval
		end

		if( mod(seconds, interval) == 0 ) then
			SSPVP:ScheduleTimer(timerID, self.IntervalMessage, secondsLeft - seconds, name, faction, seconds)
		end
	end
end

-- Print the message
function AV:IntervalMessage(name, faction, seconds)
	if( timers[name] ) then
		SSPVP:Message(string.format(L["%s will be captured by the %s in %s!"], name, L[faction], string.trim(string.lower(SecondsToTime(seconds)))), SSOverlay:GetFactionColor(faction))
	end
end

-- Check for the queueing/cancel messages so we can
-- show them on the overlay
function AV:ParseQueueMsg(event, msg, from)
	if( string.sub(msg, 0, 4) ~= "[SS]" ) then
		return
	end
	
	if( string.match(msg, L["Queueing for Alterac Valley in ([0-9]+) seconds"])) then
		local _, _, seconds = string.match(msg, L["Queueing for Alterac Valley in ([0-9]+) seconds"])
		
		self:SyncOverlay(event, tonumber(seconds))
	elseif( string.match(msg, L["Sync queue count down has been"])) then
		self:ClearSyncOverlay()
	end
end

-- Parse the yell since we can't use the battlefield ones for AV
function AV:ParseYell(event, msg, from)
	if( not SSPVP.db.profile.av.timers ) then
		return
	end
	
	if( from == L["Herald"] ) then
		local faction
		if( string.match(msg, L["Alliance"]) ) then
			faction = "Alliance"
		elseif( string.match(msg, L["Horde"]) ) then
			faction = "Horde"
		end

		-- Node assaulted
		if( string.match(msg, L["(.+) is under attack!"]) ) then
			local name = string.match(msg, L["(.+) is under attack!"])
			name = string.gsub(name, "^" .. L["The"], "")
			name = string.trim(name)
			
			timers[name] = {faction = faction, endTime = GetTime() + 300}
			self:StartIntervalAlerts(name, faction, 300)

			SSOverlay:UpdateTimer("av", name .. ": %s", 300, SSOverlay:GetFactionColor(faction))
			SSOverlay:AddOnClick("timer", "av", name .. ": %s", SSPVP, "PrintTimer", name, GetTime() + 300, faction)
		
		-- Node successfully assaulted
		elseif( string.match(msg, L["(.+) was taken by the"]) ) then
			local name = string.match(msg, L["(.+) was taken by the"])
			name = string.gsub(name, "^" .. L["The"], "")
			name = string.trim(name)
			
			timers[name] = nil
			SSOverlay:RemoveRow("timer", "av", name)
		
		-- Node successfully destroyed
		elseif( string.match(msg, L["(.+) was destroyed by the"]) ) then
			local name = string.match(msg, L["(.+) was destroyed by the"])
			name = string.gsub(name, "^" .. L["The"], "")
			name = string.trim(name)
			
			timers[name] = nil
			SSOverlay:RemoveRow("timer", "av", name)
		end
	
	-- Ivus the Forest Lord was summoned successfully
	elseif( from == L["Ivus the Forest Lord"] and string.match(arg1, L["Wicked, wicked, mortals"]) ) then
		timers[L["Ivus the Forest Lord"]] = {faction = "Alliance", endTime = GetTime() + 600}

		SSOverlay:UpdateTimer("av", "timer", L["Ivus the Forest Lord Moving: %s"], 600, SSOverlay:GetFactionColor("Horde"))
		SSOverlay:AddOnClick("timer", "av", L["Ivus the Forest Lord Moving: %s"], SSPVP, "PrintTimer", name, GetTime() + 600, faction)
	
	-- Lokholar the Ice Lord was summoned successfully
	elseif( from == L["Lokholar the Ice Lord"] and string.match(arg1, L["WHO DARES SUMMON LOKHOLA"]) ) then
		timers[L["Lokholar the Ice Lord"]] = {faction = "Horde", endTime = GetTime() + 600}

		SSOverlay:UpdateTimer("av", "timer", L["Lokholar the Ice Lord Moving: %s"], 600, SSOverlay:GetFactionColor("Horde"))
		SSOverlay:AddOnClick("timer", "av", L["Lokholar the Ice Lord Moving: %s"], SSPVP, "PrintTimer", name, GetTime() + 600, faction)
	end
end

-- Parse the claim messages at the start of AV
function AV:ParseHorde(event, msg)
	if( string.match(msg, L["claims the (.+) graveyard!"]) ) then
		SSOverlay:UpdateTimer("av", L["Snowfall Graveyard"] .. ": %s", 300, SSOverlay:GetFactionColor("Horde"))
		SSOverlay:AddOnClick("timer", "av", L["Snowfall Graveyard"] .. ": %s", SSPVP, "PrintTimer", name, GetTime() + 600, "Horde")

		self:StartIntervalAlerts(L["Snowfall Graveyard"], "Horde", 300)
	end
end

function AV:ParseAlliance(event, msg)
	if( string.match(msg, L["claims the (.+) graveyard!"]) ) then
		SSOverlay:UpdateTimer("av", L["Snowfall Graveyard"] .. ": %s", 300, SSOverlay:GetFactionColor("Alliance"))
		SSOverlay:AddOnClick("timer", "av", L["Snowfall Graveyard"] .. ": %s", SSPVP, "PrintTimer", name, GetTime() + 300, "Alliance")

		self:StartIntervalAlerts(L["Snowfall Graveyard"], "Alliance", 300)
	end
end

-- Slash Commands
-- Timer done, queue for AV!
function AV:QueueAV()
	SSPVP:AutoMessage(L["Queued for Alterac Valley!"])
	PVPSync:SendMessage("QUEUEAV", "RAID")

	-- For SSPVP 2.x.x
	SendAddonMessage("SSAV", "QUEUEAV", "RAID")
end

-- Cancel running timer
local syncTime = 0
function AV:CancelSync()
	if( ( GetNumRaidMembers() == 0 and not IsPartyLeader() ) or ( GetNumRaidMembers() > 0 and not IsRaidLeader() ) ) then
		SSPVP:Print(L["You must be party or raid leader to perform this action."])
		return
	end

	SSPVP:AutoMessage(L["Alterac Valley sync queue has been canceled!"])
	SSPVP:CancelTimer("SSQUEUEAV")

	-- Have to use unique timer names
	for i=1, syncTime do
		SSPVP:CancelTimer("SSAUTOMESSAGE" .. i)
	end
	
	PVPSync:SendMessage("CANCELAV", "RAID")
end

-- Start a sync timer
function AV.StartAVSync(seconds)
	if( ( GetNumRaidMembers() == 0 and not IsPartyLeader() ) or ( GetNumRaidMembers() > 0 and not IsRaidLeader() ) ) then
		SSPVP:Print(L["You must be party or raid leader to perform this action."])
		return
	end
	
	SSPVP:AutoMessage(string.format(L["Queue for Alterac Valley in %d seconds."], seconds))
		
	for i=seconds - 1, 1, -1 do
		SSPVP:ScheduleTimer("SSAUTOMESSAGE" .. i, SSPVP.AutoMessage, seconds - i, string.format(L["Queueing in %d second(s)."], i))
	end
		
	SSPVP:ScheduleTimer("SSQUEUEAV", AV.QueueAv, seconds)
	PVPSync:SendMessage("QUEUECD:" .. seconds, "RAID")

	syncTime = seconds
end