DamnTargetBuffs = DongleStub("Dongle-1.1"):New("DTB")

local OptionHouse
local HouseAuthority

function DamnTargetBuffs:Initialize()
	self.defaults = {
		profile = {
		}
	}
	
	self.db = self:InitializeDB("DTBDB", self.defaults)

	--OptionHouse = LibStub("OptionHouse-1.1")
	--HouseAuthority = LibStub("HousingAuthority-1.2")
		
	--local OHObj = OptionHouse:RegisterAddOn("Bishop", nil, "Amarand", "r" .. tonumber(string.match("$Revision: 300 $", "(%d+)") or 1))
	--OHObj:RegisterCategory(L["General"], self, "CreateUI", nil, 1)
end