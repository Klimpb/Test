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
			numeric = false,
			help = "Super special input, OMGHAIMIKMA",
			validate = "Check",
			error = "Error, \"%s\" is not a valid input",
		},
		{	type = "string",
			text = "This is an example string",
			color = { r = 1, g = 1, b = 1 },
		},
		{	type = "color",
			text = "Colorize your stuff",
			default = { r = 1, g = 1, b = 1 },
			var = "background",
			help = "Background color",
		},
		{	type = "slider",
			format = "Background opacity: %.2f",
			default = 1.0,
			step = 0.01,
			minText = "0%",
			maxText = "200%",
			min = 0.0,
			max = 2.0,
		},
		{	type = "check",
			text = "Enable a mod",
			default = true,
			var = "enable",
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