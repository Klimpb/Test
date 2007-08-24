local frame = CreateFrame("Frame")

local HouseBuild = {}
local tables = {}

function HouseBuild:Set(key, val)
	tables[key] = val
end

function HouseBuild:Get(key)
	return tables[key]
end

function HouseBuild:Check(val)
	return tonumber(val)
end

function HouseBuild:CreateUI()
	local config = {
		{	type = "dropdown",
			text = "Testing List",
			default = "foo",
			var = "selection",
			help = "This is some help information regarding how to use this feature in.",
			list = {{ "foo", "Foo" },
				{ "apple", "Apple" },
				{ "cat", "Cat" }}
		},
		{	type = "input",
			text = "Input Thing",
			default = 50,
			var = "val",
			realTime = true,
			help = "Super special input, OMGHAIMIKMA",
			validate = "Check",
			error = "Error, \"%s\" is not a valid input",
		},
	};
	
	local HouseAuthority = DongleStub("HousingAuthority-1.0")
	
	return HouseAuthority:CreateConfiguration(config, { handler = self, set = "Set", get = "Get" } )
end

function HouseBuild:Load()
	local OptionHouse = DongleStub("OptionHouse-1.0")
	local OHObj = OptionHouse:RegisterAddOn("HouseBuilder")
	
	OHObj:RegisterCategory("Test", self, "CreateUI")
end


local function onEvent(self, event, addon)
	if( addon == "OptionHouse" or IsAddOnLoaded("OptionHouse") ) then
		frame:SetScript("OnEvent", nil)
		frame:UnregisterEvent("ADDON_LOADED")

		HouseBuild.Load(HouseBuild)
	end
end

frame:SetScript("OnEvent", onEvent)
frame:RegisterEvent("ADDON_LOADED")