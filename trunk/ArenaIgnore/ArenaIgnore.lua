--[[ 
	Arena Ignore by Mayen (Horde) from Icecrown (US) PvE
]]

ArenaIgnore = DongleStub("Dongle-1.1"):New("ArenaIgnore")

local L = ArenaIgnoreLocals

local activeBF = -1
local activeInstance = 0
local maxPlayers = "0"
local seenEnemies = {}

local OptionHouse
local HouseAuthority

local ignoreRemoved
local addedIgnore
local alreadyIgnore

local ignoreQueue = {}
local removeQueue = {}
local ignoresRemoved = {}
local sentIgnores = {}

local tempBlock
local scanRunning
local scanStart
local ignoreResults = 0
local sentBatch = 0
local totalRemoves = 0

function ArenaIgnore:Initialize()
	self.defaults = {
		profile = {
			perSend = 5,
			cutOff = 24,
			startStop = true,
			enableCutoff = true,
			sameBracket = true,
			showFound = true,
			classes = {["ALL"] = true},
		}
	}
	
	self.db = self:InitializeDB("ArenaIgnoreDB", self.defaults)
	
	-- DB for storing players
	if( not AI_Players ) then
		AI_Players = {}
	end

	-- Register with OptionHouse
	OptionHouse = LibStub("OptionHouse-1.1")
	HouseAuthority = LibStub("HousingAuthority-1.2")
	
	local OHObj = OptionHouse:RegisterAddOn("Arena Ignore", nil, "Amarand", "r" .. tonumber(string.match("$Revision$", "(%d+)") or 1))
	OHObj:RegisterCategory(L["General"], self, "CreateUI", nil, 1)
	
	-- Localizations
	ignoreRemoved = string.gsub(ERR_IGNORE_REMOVED_S, "%%s", "(.+)")
	ignoreAdded = string.gsub(ERR_IGNORE_ADDED_S, "%%s", "(.+)")
	alreadyIgnore = string.gsub(ERR_IGNORE_ALREADY_S, "%%s", "(.+)")

	-- Open OptionHouse panel
	SLASH_ARENAIGNORE1 = "/ai"
	SLASH_ARENAIGNORE2 = "/arenai"
	SLASH_ARENAIGNORE3 = "/arenaignore"
	
	SlashCmdList["ARENAIGNORE"] = function()
		OptionHouse:Open("Arena Ignore")
	end
	
	-- Are we close to the limit?
	if( ( GetNumIgnores() + (self.db.profile.perSend * 2)) > MAX_IGNORE ) then
		self:Print(string.format(L["WARNING: You have %d people ignored, you need %d total slots and an extra %d to be safe."], GetNumIgnores(), self.db.profile.perSend, self.db.profile.perSend))
	end
	
	self:RegisterEvent("UPDATE_BATTLEFIELD_STATUS")
end

function ArenaIgnore:JoinedArena()
	self:RegisterEvent("PLAYER_FOCUS_CHANGED")
	self:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
	self:RegisterEvent("PLAYER_TARGET_CHANGED")
	self:RegisterEvent("CHAT_MSG_BG_SYSTEM_NEUTRAL")
	
	self:ScheduleTimer("AISTARTSCAN", self.StartScan, 20)
end

function ArenaIgnore:LeftArena()
	self:UnregisterAllEvents()
	self:RegisterEvent("UPDATE_BATTLEFIELD_STATUS")
	
	self:StopScan(true)
	self:CancelTimer("AISTARTSCAN")
end

function ArenaIgnore:CHAT_MSG_BG_SYSTEM_NEUTRAL(event, msg)
	if( string.match(msg, L["The Arena battle has begun!"]) ) then
		self:StopScan(true)
	end
end


local function ignoreBlocked()
	ArenaIgnore:Print(L["Adding or removing players from ignore is disabled during a scan."])
end

local function removeBlock()
	tempBlock = nil
end

local Orig_AddIgnore
local Orig_DelIgnore
function ArenaIgnore:StartScan()
	local self = ArenaIgnore
	
	scanRunning = true
	scanStart = GetTime()
	
	self:RegisterEvent("CHAT_MSG_SYSTEM")
	
	-- Block the functions from being called for now
	Orig_AddIgnore = AddIgnore
	Orig_DelIgnore = DelIgnore

	AddIgnore = ignoreBlocked
	DelIgnore = ignoreBlocked
	
	local totalPlayers = 0
	local cutOff = time() - ( 60 * 60 * self.db.profile.cutOff )
	
	for player, data in pairs(AI_Players) do
		local name, server, race, class, classToken, timeSeen, two, three, five = string.split(":", data)
		timeSeen = tonumber(timeSeen) or 0
		
		-- Class matches (or any class)
		--if( self.db.profile.classes[classToken] or self.db.profile.classes.ALL ) then
			-- Same bracket, or any bracket
		--	if( ( self.db.profile.sameBracket and ( two == maxPlayers or three == maxPlayers or five == maxPlayers ) ) or not self.db.profile.sameBracket ) then
				-- Cut off (or no cutoff)
		--		if( ( self.db.profile.enableCutoff and timeSeen >= cutOff ) or not self.db.profile.enableCutoff ) then
					ignoreQueue[player] = true
					totalPlayers = totalPlayers + 1
		--		end
		--	end		
		--end
	end
	
	-- Can't find anyone, exit quickly.
	if( totalPlayers == 0 ) then
		self:Print(L["Nobody matches the filters given in the configuration, no scan done."])
		self:StopScan(true)
		return
	end

	
	-- ETA is just total sends * 0.5 seconds
	if( self.db.profile.startStop ) then
		local eta = SecondsToTime((totalPlayers / self.db.profile.perSend) * 0.5)
		if( not eta or eta == "" ) then
			eta = L["<1 second"]
		end
		
		self:Print(string.format(L["Scan starting, %d players to check ETA %s."], totalPlayers, eta))
	end
	
	-- Start us off
	self:SendIgnoreBatch()
end

function ArenaIgnore:StopScan(suppress)
	if( not scanRunning ) then
		return
	end
	
	-- Stop monitoring so we can send out new batches
	self:UnregisterEvent("CHAT_MSG_SYSTEM")
	
	-- Clear out the queue
	for player in pairs(ignoreQueue) do
		ignoresRemoved[player] = true
		ignoreQueue[player] = nil
		sentIgnores[player] = nil

		Orig_DelIgnore(player)
	end
	
	for player in pairs(sentIgnores) do
		ignoresRemoved[player] = true
		sentIgnores[player] = nil
			
		Orig_DelIgnore(player)
	end
	
	-- Output time spent scanning
	if( not suppress and self.db.profile.startStop ) then
		local timeTaken = SecondsToTime(GetTime() - scanStart)
		if( not timeTaken or timeTaken == "" ) then
			timeTaken = L["<1 second"]
		end
		
		self:Print(string.format(L["Scan done took %s."], timeTaken))
	end
	
	scanStart = nil
	scanRunning = nil
	tempBlock = true
	
	-- This is mostly safety code, will continue blocking everything for 2 seconds after disabling incase any lag is going on
	self:ScheduleTimer("AIBLOCKTEMP", removeBlock, 2)

	-- Reset functions to the old ones
	AddIgnore = Orig_AddIgnore
	DelIgnore = Orig_DelIgnore
	
	Orig_AddIgnore = nil
	Orig_DelIgnore = nil
end

function ArenaIgnore:SendIgnoreBatch()
	-- Remove people we just checked
	for player in pairs(removeQueue) do
		ignoresRemoved[player] = true
		sentIgnores[player] = nil
		removeQueue[player] = nil
		
		totalRemoves = totalRemoves + 1
		
		Orig_DelIgnore(player)
	end
	
	-- Figure out who we're sending off now	
	sentBatch = 0
	ignoreResults = 0
	
	local sent = 0
	for player in pairs(ignoreQueue) do
		-- Limit hit, done!
		if( sent >= self.db.profile.perSend ) then
			break
		end
		
		sent = sent + 1
		sentBatch = sentBatch + 1
		
		sentIgnores[player] = true
		removeQueue[player] = true
		ignoreQueue[player] = nil
		
		Orig_AddIgnore(player)
	end
	
	-- Nobody else to send, done!
	if( sent == 0 ) then
		self:StopScan()
	end
end

function ArenaIgnore:CHAT_MSG_SYSTEM(event, msg)
	-- Didn't find them, increment ignore results
	if( string.match(msg, ERR_IGNORE_NOT_FOUND) ) then
		ignoreResults = ignoreResults + 1
		
	-- Found them!
	elseif( string.match(msg, ignoreAdded) ) then
		local name = string.match(msg, ignoreAdded)
		self:FoundEnemy(name)
		
		ignoreResults = ignoreResults + 1
	end
		
	-- Hit our limit that we needed, send off the next one
	if( ignoreResults == sentBatch ) then
		self:SendIgnoreBatch()
	end	
end

-- Block ignore types of messages
local Orig_ChatFrame_OnEvent = ChatFrame_OnEvent
function ChatFrame_OnEvent(event, ...)
	if( arg1 ) then
		if( scanRunning or tempBlock ) then
			if( string.match(arg1, ERR_IGNORE_NOT_FOUND) or string.match(arg1, ERR_FRIEND_NOT_FOUND) or string.match(arg1, ignoreRemoved) or string.match(arg1, ignoreAdded) or string.match(arg1, alreadyIgnore) ) then
				return
			end
		end

		if( string.match(arg1, ignoreRemoved) ) then
			local name = string.match(arg1, ignoreRemoved)
			if( ignoresRemoved[name] ) then
				ignoresRemoved[name] = nil
				totalRemoves = totalRemoves - 1
				
				return
			end
		end
	end
	
	return Orig_ChatFrame_OnEvent(event, ...)
end

-- Found a player
function ArenaIgnore:FoundEnemy(name)
	-- Just incase
	if( not AI_Players[name] or UnitInRaid(name) or UnitInParty(name) ) then
		return
	end
	
	local name, server, race, class, classToken = string.split(":", AI_Players[name])
	
	if( self.db.profile.showFound ) then
		self:Print(string.format(L["Enemy %s from %s, %s %s."], name, server, class, race))
	end
	
	self:SendMessage("ENEMY:" .. name .. "," .. server .. "," .. race .. "," .. classToken)
end

-- Quick redirects!
function ArenaIgnore:PLAYER_TARGET_CHANGED()
	self:ScanUnit("target")
end

function ArenaIgnore:UPDATE_MOUSEOVER_UNIT()
	self:ScanUnit("mouseover")
end

function ArenaIgnore:PLAYER_FOCUS_CHANGED()
	self:ScanUnit("focus")
end

-- Scan unit, see if they're valid as an enemy or enemy pet
local brackets = {}
function ArenaIgnore:ScanUnit(unit)
	local name, server = UnitName(unit)
	if( not name ) then
		return
	end

	server = server or GetRealmName()
	local id = name .. "-" .. server
		
	-- Already seen them, Unknown player, not an enemy, or arena hasn't started yet
	if( seenEnemies[id] or name == UNKNOWNOBJECT or not UnitIsPlayer(unit) or not UnitIsEnemy("player", unit) or GetPlayerBuffTexture(L["Arena Preparation"]) ) then
		return
	end
	
	
	if( AI_Players[id] ) then
		-- We haven't gotten them for this bracket yet, or we need to update time
		local _, _, _, _, _, _, two, three, five = string.split(":", AI_Players[id])

		brackets[two] = two
		brackets[three] = three
		brackets[five] = five
	end

	brackets[maxPlayers] = maxPlayers

	-- Race/class info!
	local race = UnitRace(unit)
	local class, classToken = UnitClass(unit)

	-- Store
	AI_Players[id] = table.concat({name, server, race, class, classToken, time(), brackets["2"] or "", brackets["3"] or "", brackets["5"] or ""},":")

	-- Sync for AF mods
	self:TriggerMessage("SS_ENEMY_DATA", name, server, race, classToken)
	self:SendMessage("ENEMY:" .. name .. "," .. server .. "," .. race .. "," .. classToken)

	-- Recycle
	brackets[""] = nil
	brackets["2"] = nil
	brackets["3"] = nil
	brackets["5"] = nil
	
	-- Don't try and update them twice in the same arena
	seenEnemies[id] = true
end

-- Are we inside an arena?
function ArenaIgnore:UPDATE_BATTLEFIELD_STATUS()
	for i=1, MAX_BATTLEFIELD_QUEUES do
		local status, map, id, _, _, teamSize = GetBattlefieldStatus(i)
		
		-- Joined arena
		if( teamSize > 0 and status == "active" and i ~= activeBF and id ~= activeInstance ) then
			activeBF = i
			activeInstance = id
			maxPlayers = tostring(teamSize)
			self:JoinedArena()
		
		-- Left arena
		elseif( teamSize > 0 and status ~= "active" and i == activeBF and id ~= activeInstance ) then
			activeBF = -1
			activeInstance = id
			maxPlayers = nil
			self:LeftArena()
			
			for k in pairs(seenEnemies) do
				seenEnemies[k] = nil
			end
		end
	end
end

-- Quick code for syncing
function ArenaIgnore:SendMessage(msg)
	SendAddonMessage("ARNIG", msg, "BATTLEGROUND")

	-- SSAF will automatically discord data we send yourself, so manually trigger the data message
	self:TriggerMessage("SS_ENEMY_DATA", string.split(",", string.sub(msg, 7)))
end

-- GUI
function ArenaIgnore:Set(var, value)
	self.db.profile[var] = value
end

function ArenaIgnore:Get(var)
	return self.db.profile[var]
end

function ArenaIgnore:CreateUI()
	local classes = {{"ALL", L["All"]}}
	for key, text in pairs(L["CLASSES"]) do
		table.insert(classes, {key, text})
	end
	
	local config = {
		{ group = L["General"], type = "groupOrder", order = 1 },

		{ order = 1, group = L["General"], text = L["Print out found enemies"], help = L["Prints out the player, server, race and class that are found to be in the same arena (if any)."], type = "check", var = "perSend"},
		{ order = 2, group = L["General"], text = L["Only check for classes"], help = L["Classes to check to see if you're against."], default = "ALL", list = classes, multi = true, type = "dropdown", var = "classes"},
		{ order = 3, group = L["General"], text = L["Only check people you've seen in the same bracket"], help = L["Will restrict people searched to those you've seen in the same arena. If you've only seen \"FooBar\" in 2vs2 an 3vs3, he wont be scanned when you're playing in 5vs5."], type = "check", default = true, var = "sameBracket"},
		{ order = 4, group = L["General"], text = L["Show scan starting and stopping."], help = L["Alerts you when a scan has been started, how many people are being scanned and ETA, along with when the scan is over."], type = "check", default = true, var = "startStop"},
		{ order = 5, group = L["General"], text = L["Enable cut off"], help = L["Restricts people scanned to those you've seen recently within the last X hours, where you set X below."], type = "check", var = "enableCutoff"},
		{ order = 6, group = L["General"], text = L["Hour cut off"], help = L["How many hours ago you've had to seen someone for them to be filtered."], type = "input", numeric = true, default = 5, width = 30, var = "cutOff"},
		{ order = 7, group = L["General"], text = L["How many ignores to send per a run"], help = L["If you have 50 players to check, and you're sending 5 ignores per a run then it'll take 10 runs for it to finish. You MUST have at per run * 2 ignore slots open or you'll run into issues."], type = "input", default = 5, numeric = true, width = 30, var = "perSend"},
	}

	-- Update the dropdown incase any new textures were added
	return HouseAuthority:CreateConfiguration(config, {set = "Set", get = "Get", handler = self})
end