--[[ 
	Beat The System by Mayen (Horde) from Icecrown (US) PvE
]]

BTS = DongleStub("Dongle-1.1"):New("BTS")

local L = BTSLocals

function BTS:Initialize()
	self.defaults = {
		profile = {
		}
	}
	
	self.db = self:InitializeDB("BTSDB", self.defaults)
	
	-- Register with OptionHouse
	OptionHouse = LibStub("OptionHouse-1.1")
	HouseAuthority = LibStub("HousingAuthority-1.2")
	
	--local OHObj = OptionHouse:RegisterAddOn("Beat The System", nil, "Mayen", "r" .. tonumber(string.match("$Revision: 371 $", "(%d+)") or 1))
	--OHObj:RegisterCategory(L["General"], self, "CreateUI", nil, 1)
	
end