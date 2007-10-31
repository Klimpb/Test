--[[ 
	Arena Ignore by Mayen (Horde) from Icecrown (US) PvE
]]

ArenaIgnore = DongleStub("Dongle-1.1"):New("ArenaIgnore")

local L = ArenaIgnoreLocals

local activeBF = -1
local maxPlayers = 0
local seenEnemies = {}

local OptionHouse
local HouseAuthority

function ArenaIgnore:Initialize()
	self.defaults = {
		profile = {
			
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
	
	local OHObj = OptionHouse:RegisterAddOn("Arena Ignore", nil, "Amarand", "r" .. tonumber(string.match("$Revision: 252 $", "(%d+)") or 1))
	OHObj:RegisterCategory(L["General"], self, "CreateUI", nil, 1)

	-- Open OptionHouse panel
	SLASH_ARENAIGNORE1 = "/ai"
	SLASH_ARENAIGNORE2 = "/arenai"
	SLASH_ARENAIGNORE3 = "/arenaignore"
	
	SlashCmdList["ARENAIGNORE"] = function()
		OptionHouse:Open("Arena Ignore")
	end
end

function ArenaIgnore:JoinedArena()
	self:RegisterEvent("PLAYER_FOCUS_CHANGED")
	self:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
	self:RegisterEvent("PLAYER_TARGET_CHANGED")
end

function ArenaIgnore:LeftArena()
	self:UnregisterAllEvents()
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
		if( teamSize > 0 and status == "active" and i ~= activeBF ) then
			activeBF = i
			maxPlayers = tostring(teamSize)
			self:JoinedArena()
		
		-- Left arena
		elseif( teamSize > 0 and status ~= "active" and i == activeBF ) then
			activeBF = -1
			maxPlayers = nil
			self:LeftArena()
			
			for k in pairs(seenEnemies) do
				seenEnemies[k] = nil
			end
		end
	end
end

function ArenaIgnore:ChannelMessage(msg)
	SendChatMessage("[SS] " .. msg, "BATTLEGROUND")
end

-- Quick code for syncing
function ArenaIgnore:SendMessage(msg, type)
	SendAddonMessage("SSAF", msg, "BATTLEGROUND")
end

-- GUI
function ArenaIgnore:Set(var, value)
	self.db.profile[var] = value
end

function ArenaIgnore:Get(var)
	return self.db.profile[var]
end

function ArenaIgnore:CreateUI()
	local config = {
		{ group = L["General"], type = "groupOrder", order = 1 },

		--{ group = L["General"], order = 1, text = L["Report enemies to battleground chat"], help = L["Sends name, server, class, race and guild to battleground chat when you mouse over or target an enemy."], type = "check", var = "reportEnemies"},
	}

	-- Update the dropdown incase any new textures were added
	return HouseAuthority:CreateConfiguration(config, {set = "Set", get = "Get", onSet = "Reload", handler = self})
end