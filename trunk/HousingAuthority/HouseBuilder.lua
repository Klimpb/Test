local frame = CreateFrame("Frame")

local HouseBuild = {}
local tables = {}

function HouseBuild:Set(key, val)
	tables[key] = val
end

function HouseBuild:Get(key)
	return tables[key]
end

function HouseBuild:Check(var, val)
	return tonumber(val)
end

function HouseBuild:ButtonClicked(key)
	DEFAULT_CHAT_FRAME:AddMessage( "Button with a key of " .. key .. " was pressed" )
end

function HouseBuild:CreateUI()
	local config = {
		{	group = "Main Group",
			type = "dropdown",
			text = "Testing List",
			default = "foo",
			var = "selection",
			help = "This is some help information regarding how to use this feature in.",
			list = {{ "foo", "Foo" },
				{ "apple", "Apple" },
				{ "cat", "Cat" }}
		},
		{	group = "Main Group",
			type = "color",
			text = "Colorize your stuff",
			default = { r = 1, g = 1, b = 1 },
			var = "background",
			help = "Background color",
		},
		{	group = "Main Group",
			type = "input",
			text = "Input Thing",
			default = 50,
			var = "val",
			realTime = true,
			numeric = false,
			help = "Super special input, OMGHAIMIKMA",
			validate = "Check",
			error = "Error, \"%s\" is not a valid input",
		},
		{	group = "Secondary Group",
			type = "slider",
			format = "Background opacity: %.2f",
			help = "K, Thks, Bai", 
			var = "opacity",
			default = 1.0,
			step = 0.01,
			minText = "0%",
			maxText = "200%",
			min = 0.0,
			max = 2.0,
		},
		{	group = "Secondary Group",
			type = "check",
			text = "Enable a mod",
			help = "FOR PONY",
			default = true,
			var = "enable",
		},
		{	group = "Secondary Group",
			type = "button",
			text = "Enable something",
			var = "foo",
			set = "ButtonClicked",
		},
	};
	
	local HouseAuthority = LibStub:GetLibrary("HousingAuthority-1.1")
	
	return HouseAuthority:CreateConfiguration(config, { handler = self, set = "Set", get = "Get", columns = 2 } )
end

function HouseBuild:Load()
	local OptionHouse = LibStub:GetLibrary("OptionHouse-1.1")
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