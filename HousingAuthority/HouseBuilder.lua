local frame = CreateFrame("Frame")

local HouseBuild = {}
local tables = {}

function HouseBuild:Set(key, val)
	--Debug( "Set [" .. tostring(key) .. "] [" .. tostring(val) .. "]" )
	tables[key] = val
end

function HouseBuild:Get(key)
	--Debug( "Get [" .. tostring(key) .. "]" )
	return tables[key]
end

function HouseBuild:Check(var, val)
	--Debug( "Check [" .. tostring(var) .. "] [" .. tostring(val) .. "]" )
	return tonumber(val)
end

function HouseBuild:ButtonClicked(key)
	--DEFAULT_CHAT_FRAME:AddMessage( "Button with a key of " .. tostring(key) .. " was pressed" )
end

-- NO GROUPS SINGLE COLUMN
function HouseBuild:NoGroupSingleCol()
	local config = {
		{	type = "dropdown",
			text = "Testing List",
			default = "cat",
			var = "selection",
			help = "This is some help information regarding how to use this feature in.",
			list = {{ "foo", "Foo" },
				{ "apple", "Apple" },
				{ "cat", "Cat" }}
		},
		{	type = "dropdown",
			text = "Testing List 2",
			var = "foobared",
			default = "apple",
			help = "This is some help information regarding how to use this feature in.",
			list = {{ "Foo", "Foo" },
				{ "Apple", "Apple" },
				{ "Cat", "Cat" }}
		},
		{	type = "color",
			text = "Colorize your stuff",
			default = { r = 1, g = 1, b = 1 },
			var = "background",
			help = "Background color",
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
		{	type = "slider",
			manualInput = true,
			format = "Background opacity: %d%%",
			help = "K, Thks, Bai", 
			var = "opacity",
			default = 1.0,
			step = 0.01,
			minText = "0%",
			maxText = "200%",
			min = 0.0,
			max = 2.0,
		},
		{	type = "check",
			text = "Enable a mod",
			help = "FOR PONY",
			default = true,
			var = "enable",
		},
		{	type = "button",
			text = "Enable something",
			var = "foo",
			set = "ButtonClicked",
		},
	};
	
	local HouseAuthority = LibStub:GetLibrary("HousingAuthority-1.2")
	
	return HouseAuthority:CreateConfiguration(config, { handler = self, set = "Set", get = "Get", columns = 1 } )
end

-- GROUPS USED SINGLE COLUMN
function HouseBuild:GroupSingleCol()
	local config = {
		{	group = "Main Group",
			type = "dropdown",
			text = "Testing List",
			default = "cat",
			var = "selection",
			help = "This is some help information regarding how to use this feature in.",
			list = {{ "foo", "Foo" },
				{ "apple", "Apple" },
				{ "cat", "Cat" }}
		},
		{	group = "Main Group",
			type = "dropdown",
			text = "Testing List 2",
			var = "foobared",
			default = "apple",
			help = "This is some help information regarding how to use this feature in.",
			list = {{ "Foo", "Foo" },
				{ "Apple", "Apple" },
				{ "Cat", "Cat" }}
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
			manualInput = true,
			format = "Background opacity: %d%%",
			help = "K, Thks, Bai", 
			var = "opacity",
			default = 1.0,
			step = 0.01,
			minText = "0%",
			maxText = "200%",
			min = 0.0,
			max = 2.0,
		},
		{	group = "Main Group",
			type = "slider",
			manualInput = true,
			format = "Background opacity: %d%%",
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
	
	local HouseAuthority = LibStub:GetLibrary("HousingAuthority-1.2")
	
	return HouseAuthority:CreateConfiguration(config, { handler = self, set = "Set", get = "Get", columns = 1 } )
end

-- NO GROUPS 2 COLUMN VIEW USED
function HouseBuild:NoGroupTwoCol()
	local config = {
		{	type = "dropdown",
			text = "Testing List",
			default = "cat",
			var = "selection",
			help = "This is some help information regarding how to use this feature in.",
			list = {{ "foo", "Foo" },
				{ "apple", "Apple" },
				{ "cat", "Cat" }}
		},
		{	type = "dropdown",
			text = "Testing List 2",
			var = "foobared",
			default = "apple",
			help = "This is some help information regarding how to use this feature in.",
			list = {{ "Foo", "Foo" },
				{ "Apple", "Apple" },
				{ "Cat", "Cat" }}
		},
		{	type = "color",
			text = "Colorize your stuff",
			default = { r = 1, g = 1, b = 1 },
			var = "background",
			help = "Background color",
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
		{	type = "slider",
			manualInput = true,
			format = "Background opacity: %d%%",
			help = "K, Thks, Bai", 
			var = "opacity",
			default = 1.0,
			step = 0.01,
			minText = "0%",
			maxText = "200%",
			min = 0.0,
			max = 2.0,
		},
		{	type = "check",
			text = "Enable a mod",
			help = "FOR PONY",
			default = true,
			var = "enable",
		},
		{	type = "button",
			text = "Enable something",
			var = "foo",
			set = "ButtonClicked",
		},
	};
	
	local HouseAuthority = LibStub:GetLibrary("HousingAuthority-1.2")
	
	return HouseAuthority:CreateConfiguration(config, { handler = self, set = "Set", get = "Get", columns = 2 } )
end

-- GROUPS AND 2 COLUMN VIEW USED
function HouseBuild:GroupTwoCol()
	local config = {
		{	group = "Main Group",
			type = "dropdown",
			text = "Testing List",
			default = "cat",
			var = "selection",
			help = "This is some help information regarding how to use this feature in.",
			list = {{ "foo", "Foo" },
				{ "apple", "Apple" },
				{ "cat", "Cat" }}
		},
		{	group = "Main Group",
			type = "dropdown",
			text = "Testing List 2",
			var = "foobared",
			default = "apple",
			help = "This is some help information regarding how to use this feature in.",
			list = {{ "Foo", "Foo" },
				{ "Apple", "Apple" },
				{ "Cat", "Cat" }}
		},
		{	group = "Main Group",
			type = "color",
			text = "Colorize your stuff",
			default = { r = 1, g = 1, b = 1 },
			var = "background",
			help = "Background color",
		},
		{	group = "Main Group",
			type = "slider",
			manualInput = true,
			format = "Background opacity: %d%%",
			help = "K, Thks, Bai", 
			var = "opacity",
			default = 1.0,
			step = 0.01,
			minText = "0%",
			maxText = "200%",
			min = 0.0,
			max = 2.0,
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
			manualInput = true,
			format = "Background opacity: %d%%",
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
	
	local HouseAuthority = LibStub:GetLibrary("HousingAuthority-1.2")
	
	return HouseAuthority:CreateConfiguration(config, { handler = self, set = "Set", get = "Get", columns = 2 } )
end

function HouseBuild:Load()
	local OptionHouse = LibStub:GetLibrary("OptionHouse-1.1")
	local OHObj = OptionHouse:RegisterAddOn("HouseBuilder")
	
	OHObj:RegisterCategory("Groups 2 Col", self, "GroupTwoCol")
	OHObj:RegisterCategory("Group Single Col", self, "GroupSingleCol")
	OHObj:RegisterCategory("No Group 2 Col", self, "NoGroupTwoCol")
	OHObj:RegisterCategory("No Group Single Col", self, "NoGroupSingleCol")
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