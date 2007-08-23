local frame = CreateFrame("Frame")

local HouseBuild = {}
local tables = {}

function HouseBuild:Set(key, val)
	Debug( "SET [" .. tostring(key) .. "] [" .. tostring(val) .. "]" );
	tables[key] = val
end

function HouseBuild:Get(key)
	Debug( "GET [" .. tostring(tables[key]) .. "]" );
	return tables[key]
end

function HouseBuild:CreateUI()
	local config = {
		{	type = "dropdown",
			text = "Testing List",
			default = "foo",
			var = "selection",
			list = {{ "foo", "Foo" },
				{ "apple", "Apple" },
				{ "cat", "Cat" }}
		}
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