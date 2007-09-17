local RaidID = {}
local OptionHouse
local OHObj
local realm

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
		OHObj = OptionHouse:RegisterAddOn("RaidID", nil, nil, "r" .. (tonumber(string.match("$Revision: 604 $", "(%d+)")) or 1))
	end
end

-- Got data from login
function RaidID:UPDATE_INSTANCE_INFO()
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

function RaidID:CHAT_MSG_ADDON(prefix, msg, type, author)
	if( prefix == "RID" ) then
		local type, data = string.match(msg, "([^:]+)%:(.+)")
		
		-- Sent a specific ID
		if( type == "ID" ) then
			local instance, id, remaining = string.split(",", data)
			
			if( not RaidID_List[realm][author] ) then
				RaidID_List[realm][author] = {}
			end
			
			RaidID_List[realm][author][instance] = { id = id, remaining = remaining }
			DEFAULT_CHAT_FRAME:AddMessage("New raid ID for ".. author .. ", " .. instance .. " (" .. id .. "), seconds left " .. remaining)
		
		-- Request a specific one
		elseif( type == "REQID" ) thhen
			if( GetNumSavedInstances() == 0 ) then
				self:SendMessage("CLEARALL", "GUILD")
			else
				local name, id, remain = GetSavedInstanceInfo(tonumber(data))
				if( name ) then
					self:SendMessage("ID:" .. name .. "," .. id .. "," .. remain, "GUILD")
				end
			end
		
		-- Clear all of ours
		elseif( msg == "CLEARALL" and RaidIDD_List[realm][author] ) then
			RaidID_List[realm][author] = nil
			DEFAULT_CHAT_FRAME:AddMessage("Cleared all saved records for " .. author )
		
		-- Send all of the IDs
		elseif( msg == "REQALL" ) then
			RaidID:UPDATE_INSTANCE_INFO()
		end
	end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("CHAT_MSG_ADDON")
frame:RegisterEvent("UPDATE_INSTANCE_INFO")
frame:SetScript("OnEvent", function(self, event, ...)
	RaidID[event](RaidID, ...)
end)