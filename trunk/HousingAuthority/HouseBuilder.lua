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
		{	type = "input",
			text = "Foo Bar",
			var = "test",
			default = "test",
		},
		{	type = "check",
			text = "Check Thingy",
			var = "cow",
			default = true,
		},
		{	type = "color",
			text = "Color mabomb",
			var = "apple",
			default = { r = 0.50, g = 0.50, b = 0.50 },
		},
		{	type = "slider",
			format = "Foo: %.2f",
			var = "opacity",
			default = 0.50,
		},
		{	type = "input",
			text = "Foo Bar",
			var = "test",
			default = "test",
		},
		{	type = "check",
			text = "Check Thingy",
			var = "cow",
			default = true,
		},
		{	type = "color",
			text = "Color mabomb",
			var = "apple",
			default = { r = 0.50, g = 0.50, b = 0.50 },
		},
		{	type = "slider",
			format = "Foo: %.2f",
			var = "opacity",
			default = 0.50,
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