local AVSync = SSPVP:NewModule("AVSync", "AceEvent-3.0", "AceTimer-3.0", "AceConsole-3.0")

local L = SSPVPLocals

function AVSync:OnInitialize()
	-- Slash commands for conversions
	self:RegisterChatCommand("av", function(input)
		if( string.match(input, "sync ([0-9]+)") ) then
			if( GetNumRaidMembers() == 0 and GetNumPartyMembers() == 0 ) then
			--	self:Print(L["You must be in a raid or party to do this."])
			--	return
			end

			local seconds = string.match(input, "sync ([0-9]+)")
			seconds = tonumber(seconds)
			if( not seconds or seconds >= 60 ) then
				self:Print(L["Invalid number entered for sync queue."])
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
				
		elseif( input == "cancel" ) then
			if( GetNumRaidMembers() == 0 and GetNumPartyMembers() == 0 ) then
				self:Print(L["You must be in a raid or party to do this."])
				return
			end
		
			SendChatMessage(L["Alterac Valley queue stopped."], "RAID")
		else
			DEFAULT_CHAT_FRAME:AddMessage(L["SSPVP Alterac Valley slash commands"])
			DEFAULT_CHAT_FRAME:AddMessage(L[" - sync <seconds> - Starts a count down for an Alterac Valley sync queue."])
			DEFAULT_CHAT_FRAME:AddMessage(L[" - cancel - Cancels a running sync."])
		end
	end)
end

function AVSync:OnEnable()
	self:RegisterEvent("CHAT_MSG_ADDON")
end

function AVSync:OnDisable()
	self:UnregisterAllEvents()
end

function AVSync:Message(seconds)
	local type = "PARTY"
	if( GetNumRaidMembers() > 0 ) then
		type = "RAID"
	end

	if( seconds > 1 ) then
		SendChatMessage(string.format(L["Queuing for Alterac Valley in %d seconds."], seconds), type)
	else
		SendChatMessage(string.format(L["Queuing for Alterac Valley in %d second."], seconds), type)
	end
end

function AVSync:SendQueue()
	local type = "PARTY"
	if( GetNumRaidMembers() > 0 ) then
		type = "RAID"
	end
	
	SendChatMessage(L["Queue for Alterac Valley!"], type)
	SendAddonMessage("SSPVP", "QUEUEAV", "RAID")
end

function AVSync:Queue(author)
	-- Make sure we're on the AV battlemaster before queuing
	if( (GetBattlefieldInfo()) == L["Alterac Valley"] ) then
		SSPVP:Print(string.format(L["You have been queued for Alterac Valley by %s."], author))
		JoinBattlefield(0)
	end
end

function AVSync:CHAT_MSG_ADDON(event, prefix, msg, type, author)
	if( ( prefix == "SSPVP" or prefix == "SSAV" ) and msg == "QUEUEAV" ) then
		self:Queue(author)
	end
end