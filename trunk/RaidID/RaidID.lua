local version = (tonumber(string.match("$Revision$", "(%d+)")) or 1)
local frame = CreateFrame("Frame")

RaidID = {}
local instanceList = {}
local versionList = {}
local OptionHouse
local OHObj
local realm

local L = {
	["HELP1"] = "/syncid - Open the OptionHouse panel to list all raid ids.",
	["HELP2"] = "/syncid resync - Requests new raid ids from everyone online.",
	["HELP3"] = "/syncid reset - Resets all saved raid ids.",
	["RESET_DATA"] = "All saved data has been reset.",
	["RESYNCING"] = "Requesting saved instances from all online guild members, this may take a minute.",
}

function RaidID:ScanInstanceList(list)
	for name, _ in pairs(list) do
		-- Add a new category if need be
		if( not instanceList[name] ) then
			instanceList[name] = true
			OHObj:RegisterCategory(name, self, "CreateUI", true)
		end
	end
end

function RaidID:ADDON_LOADED(addon)
	if( addon == "RaidID" ) then
		realm = GetRealmName()
		
		if( not RaidID_List ) then
			RaidID_List = {}
		end
		
		if( not RaidID_List[realm] ) then
			RaidID_List[realm] = {}
		end
		
		RequestRaidInfo()

		OptionHouse = LibStub:GetLibrary("OptionHouse-1.1")
		OHObj = OptionHouse:RegisterAddOn("RaidID", nil, "Amarand", "r" .. version)
		OHObj:RegisterCategory("Version List", self, "CreatePingUI", true)
	
		-- Add all the instances we have currently
		for _, instances in pairs(RaidID_List[realm]) do
			self:ScanInstanceList(instances)
		end
	end
end

-- This is hackish because we recreate the entire thing everytime you review it
-- need to change some core ways HousingAuthority works to fix that
local config = {}
function RaidID:CreateUI(instance)
	local currentTime = time()

	-- Recycle
	for i=#(config), 1, -1 do
		table.remove(config, i)
	end
		
	-- List all players that are saved to the listed instance
	for player, instances in pairs(RaidID_List[realm]) do
		for saved, data in pairs(instances) do
			if( saved == instance and data.resetDate > currentTime ) then
				table.insert(config, {type = "label", xPos = 5, yPos = 0, font = GameFontNormalSmall, group = "#" .. data.id, text = player})
				table.insert(config, {type = "label", xPos = 0, yPos = 0, font = GameFontNormalSmall, group = "#" .. data.id, text = date("%x %I:%M:%S %p", data.resetDate)})
			end
		end
	end
	
	-- All the things expired
	if( #(config) == 0 ) then
		OHObj:RemoveCategory(instance)
		return frame
	end
	
	return LibStub:GetLibrary("HousingAuthority-1.2"):CreateConfiguration(config, { columns = 2 })
end

-- Ping UI
local function sortPings(a, b)
	if( not b ) then
		return false
	end
	
	return (a.version > b.version)
end

function RaidID:CreatePingUI()
	table.sort(versionList, sortPings)
	local config = {}
	for _, player in pairs(versionList) do
		table.insert(config, {type = "label", xPos = 5, yPos = 0, font = GameFontNormalSmall, group = "r" .. player.version, text = player.name})
	end
	
	return LibStub:GetLibrary("HousingAuthority-1.2"):CreateConfiguration(config)
end

function RaidID:UpdatePing()
	local frame = OptionHouse:GetFrame("main")
	frame.selectedAddon = ""
	frame.selectedCategory = ""
	OptionHouse:Open("RaidID", "Version Info")
end

-- Got data from login
function RaidID:UPDATE_INSTANCE_INFO()
	if( not (GetGuildInfo("player")) ) then
	
	self:SendMessage("CLEARALL", "GUILD")
	
	for i=1, GetNumSavedInstances() do
		local name, id, remain = GetSavedInstanceInfo(i)
		self:SendMessage("ID:" .. name .. "," .. id .. "," .. remain, "GUILD")
	end
end

-- Saved to something new? Okay, resend them all then
function RaidID:CHAT_MSG_SYSTEM(msg)
	if( msg == INSTANCE_SAVED ) then
		RaidID:UPDATE_INSTANCE_INFO()
	end
end

-- Deal with syncing
function RaidID:SendMessage(msg, type, target)
	SendAddonMessage("RID", msg, type, target)
end

function RaidID:Fake()
	RaidID:SendMessage("ID:Karazhan,13469,84600", "GUILD")
	RaidID:SendMessage("ID:Tempest Keep,62346,90000", "GUILD")
end

function RaidID:CHAT_MSG_ADDON(prefix, msg, type, author)
	if( prefix == "RID" ) then
		local type, data = string.match(msg, "([^:]+)%:(.+)")
		
		-- Sent a specific ID
		if( type == "ID" ) then
			local instance, id, remaining = string.split(",", data)
			
			remaining = tonumber(remaining)
			id = tonumber(id)
			
			if( not remaining or not instance or not id ) then
				return
			end
			
			if( not RaidID_List[realm][author] ) then
				RaidID_List[realm][author] = {}
			end
			
			RaidID_List[realm][author][instance] = { id = id, remaining = remaining, resetDate = remaining + time() }
			self:ScanInstanceList(RaidID_List[realm][author])
			
			--DEFAULT_CHAT_FRAME:AddMessage("New raid ID for ".. author .. ", " .. instance .. " (" .. id .. "), seconds left " .. remaining)
		
		-- Request a specific one
		elseif( type == "REQID" ) then
			if( GetNumSavedInstances() == 0 ) then
				self:SendMessage("CLEARALL", "GUILD")
			else
				local name, id, remain = GetSavedInstanceInfo(tonumber(data))
				if( name ) then
					self:SendMessage("ID:" .. name .. "," .. id .. "," .. remain, "GUILD")
				end
			end
	
		-- Ping response
		elseif( type == "PONG" ) then
			for id, player in pairs(versionList) do
				if( player.name == author ) then
					versionList[id].version = tostring(data)
					RaidID:UpdatePing()
					return
				end
			end
			
			table.insert(versionList, { name = author, version = tostring(data) })
			RaidID:UpdatePing()
	
		-- Clear all of ours
		elseif( msg == "CLEARALL" and RaidID_List[realm][author] ) then
			RaidID_List[realm][author] = nil
			--DEFAULT_CHAT_FRAME:AddMessage("Cleared all saved records for " .. author )
			
		-- Ping request
		elseif( msg == "PING" ) then
			self:SendMessage("PONG:" .. version, type, author)
		
		-- Send all of the IDs
		elseif( msg == "REQALL" ) then
			RaidID:UPDATE_INSTANCE_INFO()
		end
	end
end

frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("CHAT_MSG_ADDON")
frame:RegisterEvent("UPDATE_INSTANCE_INFO")
frame:SetScript("OnEvent", function(self, event, ...)
	RaidID[event](RaidID, ...)
end)


SLASH_RAIDID1 = "/syncid"
SLASH_RAIDID2 = "/getrid"
SLASH_RAIDID3 = "/raidid"
SlashCmdList["RAIDID"] = function(msg)
	msg = string.lower(msg or "")
	if( msg == "" ) then
		OptionHouse:Open("RaidID")
	elseif( msg == "ping" ) then
		DEFAULT_CHAT_FRAME:AddMessage(L["PINGING"])
		RaidID:SendMessage("PING", "GUILD")
		OptionHouse:Open("RaidID", "Version Info")
	
	elseif( msg == "resync" ) then
		DEFAULT_CHAT_FRAME:AddMessage(L["RESYNCING"])
		RaidID:SendMessage("REQALL", "GUILD")
		
	elseif( msg == "reset" ) then
		DEFAULT_CHAT_FRAME:AddMessage(L["RESET_DATA"])
		RaidID_List[realm] = {}
	elseif( msg == "help" ) then
		DEFAULT_CHAT_FRAME:AddMessage(L["HELP1"])
		DEFAULT_CHAT_FRAME:AddMessage(L["HELP2"])
		DEFAULT_CHAT_FRAME:AddMessage(L["HELP3"])
		DEFAULT_CHAT_FRAME:AddMessage(L["HELP4"])
	end
end