local major = "DongleStub"
local minor = tonumber(string.match("$Revision: 431 $", "(%d+)") or 1)

local g = getfenv(0)

if not g.DongleStub or g.DongleStub:IsNewerVersion(major, minor) then
	local lib = setmetatable({}, {
		__call = function(t,k) 
			if type(t.versions) == "table" and t.versions[k] then 
				return t.versions[k].instance
			else
				error("Cannot find a library with name '"..tostring(k).."'", 2)
			end
		end
	})

	function lib:IsNewerVersion(major, minor)
		local versionData = self.versions and self.versions[major]

		-- If DongleStub versions have differing major version names
		-- such as DongleStub-Beta0 and DongleStub-1.0-RC2 then a second
		-- instance will be loaded, with older logic.  This code attempts
		-- to compensate for that by matching the major version against
		-- "^DongleStub", and handling the version check correctly.

		if major:match("^DongleStub") then
			local oldmajor,oldminor = self:GetVersion()
			if self.versions and self.versions[oldmajor] then
				return minor > oldminor
			else
				return true
			end
		end

		if not versionData then return true end
		local oldmajor,oldminor = versionData.instance:GetVersion()
		return minor > oldminor
	end
	
	local function NilCopyTable(src, dest)
		for k,v in pairs(dest) do dest[k] = nil end
		for k,v in pairs(src) do dest[k] = v end
	end

	function lib:Register(newInstance, activate, deactivate)
		assert(type(newInstance.GetVersion) == "function",
			"Attempt to register a library with DongleStub that does not have a 'GetVersion' method.")

		local major,minor = newInstance:GetVersion()
		assert(type(major) == "string",
			"Attempt to register a library with DongleStub that does not have a proper major version.")
		assert(type(minor) == "number",
			"Attempt to register a library with DongleStub that does not have a proper minor version.")

		-- Generate a log of all library registrations
		if not self.log then self.log = {} end
		table.insert(self.log, string.format("Register: %s, %s", major, minor))

		if not self:IsNewerVersion(major, minor) then return false end
		if not self.versions then self.versions = {} end

		local versionData = self.versions[major]
		if not versionData then
			-- New major version
			versionData = {
				["instance"] = newInstance,
				["deactivate"] = deactivate,
			}
			
			self.versions[major] = versionData
			if type(activate) == "function" then
				table.insert(self.log, string.format("Activate: %s, %s", major, minor))
				activate(newInstance)
			end
			return newInstance
		end
		
		local oldDeactivate = versionData.deactivate
		local oldInstance = versionData.instance
		
		versionData.deactivate = deactivate
		
		local skipCopy
		if type(activate) == "function" then
			table.insert(self.log, string.format("Activate: %s, %s", major, minor))
			skipCopy = activate(newInstance, oldInstance)
		end

		-- Deactivate the old libary if necessary
		if type(oldDeactivate) == "function" then
			local major, minor = oldInstance:GetVersion()
			table.insert(self.log, string.format("Deactivate: %s, %s", major, minor))
			oldDeactivate(oldInstance, newInstance)
		end

		-- Re-use the old table, and discard the new one
		if not skipCopy then
			NilCopyTable(newInstance, oldInstance)
		end
		return oldInstance
	end

	function lib:GetVersion() return major,minor end

	local function Activate(new, old)
		-- This code ensures that we'll move the versions table even
		-- if the major version names are different, in the case of 
		-- DongleStub
		if not old then old = g.DongleStub end

		if old then
			new.versions = old.versions
			new.log = old.log
		end
		g.DongleStub = new
	end
	
	-- Actually trigger libary activation here
	local stub = g.DongleStub or lib
	lib = stub:Register(lib, Activate)
end

--[[-------------------------------------------------------------------------
  Begin Library Implementation
---------------------------------------------------------------------------]]

local major = "OptionHouse-Alpha0.2"
local minor = tonumber(string.match("$Revision: 431 $", "(%d+)") or 1)

assert(DongleStub, string.format("%s requires DongleStub.", major))

local L = {
	["BAD_ARGUMENT"] = "bad argument #%d to '%s' (%s expected, got %s)",
	["MUST_CALL"] = "You must call '%s' from an OptionHouse addon object.",
	["ADDON_ALREADYREG"] = "The addon '%s' is already registered with OptionHouse.",
	["CATEGORY_ALREADYREG"] = "A category named '%s' already exists in '%s'",
	["NO_PARENTCAT"] = "No parent category named '%s' exists in %s'",
	["SUBCATEGORY_ALREADYREG"] = "The sub-category named '%s' already exists in the category '%s' for '%s'",
	["OPTION_HOUSE"] = "Option House",
	["ENTERED_COMBAT"] = "|cFF33FF99Option House|r Configuration window closed due to entering combat.",
	["SEARCH"] = "Search...",
	["LOAD"] = "Load",
	["RELOAD_UI"] = "Reload UI",
	["ENABLE_ALL"] = "Enable All",
	["DISABLE_ALL"] = "Disable All",
	["MANAGEMENT_TITLE"] = "%s\nBy: %s\nVersion: %s",
	["DISABLED_AT_RELOAD"] = "Disabled on UI Reload",
	["LOAD_ON_DEMAND"] = "Loadable on Demand",
	["MEMORY"] = "Memory",
	["MEMSEC"] = "Memory/Sec",
	["CPU"] = "CPU",
	["CPUSEC"] = "CPU/Sec",
	["ENABLE_CPU"] = "Enable CPU",
	["DISABLE_CPU"] = "Disable CPU",
	["ADDON_PERFORMANCE"] = "AddOn Performance",
	["ADDON_MANAGEMENT"] = "AddOn Management",
	["ADDON_OPTIONS"] = "AddOn Configuration",
	["NAME"] = "Name",
}

local function assert(level,condition,message)
	if not condition then
		error(message,level)
	end
end

local function argcheck(value, num, ...)
	if type(num) ~= "number" then
		error(L["BAD_ARGUMENT"]:format(2, "argcheck", "number", type(num)), 1)
	end

	for i=1,select("#", ...) do
		if type(value) == select(i, ...) then return end
	end

	local types = strjoin(", ", ...)
	local name = string.match(debugstack(2,2,0), ": in function [`<](.-)['>]")
	error(L["BAD_ARGUMENT"]:format(num, name, types, type(value)), 3)
end

-- OptionHouse
local OptionHouse = {}
local tabfunctions = {}
local methods = {"RegisterCategory", "RegisterSubCategory"}
local addons = {}
local evtFrame
local frame
local scriptProfiling

local function tabOnClick(id)
	if( type( id ) ~= "number" ) then
		id = this:GetID()
	end
	
	PanelTemplates_SetTab(frame, id)

	-- Configuration
	if( id == 1 ) then
		OptionHouseFrameTopLeft:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Browse-TopLeft")
		OptionHouseFrameTop:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Browse-Top")
		OptionHouseFrameTopRight:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Browse-TopRight")
		OptionHouseFrameBotLeft:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Browse-BotLeft")
		OptionHouseFrameBot:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Browse-Bot")
		OptionHouseFrameBotRight:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Browse-BotRight")
 		
 		tabfunctions[3](true)
 		tabfunctions[2](true)
 		tabfunctions[1]()
 		
 	-- Management
	elseif( id == 2 ) then
		OptionHouseFrameTopLeft:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Bid-TopLeft")
		OptionHouseFrameTop:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Bid-Top")
		OptionHouseFrameTopRight:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Bid-TopRight")
		OptionHouseFrameBotLeft:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Bid-BotLeft")
		OptionHouseFrameBot:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Bid-Bot")
		OptionHouseFrameBotRight:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Bid-BotRight")

 		tabfunctions[3](true)
 		tabfunctions[1](true)
 		tabfunctions[2]()
 	
 	-- Performance
	elseif( id == 3 ) then
		OptionHouseFrameTopLeft:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Bid-TopLeft")
		OptionHouseFrameTop:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Bid-Top")
		OptionHouseFrameTopRight:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Bid-TopRight")
		OptionHouseFrameBotLeft:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Bid-BotLeft")
		OptionHouseFrameBot:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Bid-Bot")
		OptionHouseFrameBotRight:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Bid-BotRight")

 		tabfunctions[2](true)
 		tabfunctions[1](true)
 		tabfunctions[3]()
	end
end

local function createOHFrame()
	local name = "OptionHouseFrame"

	if( getglobal(name) ) then
		return
	end
	
	table.insert(UISpecialFrames, name)

	frame = CreateFrame("Frame", name, UIParent)
	frame:EnableMouse(true)
	frame:CreateTitleRegion()
	frame:SetClampedToScreen(true)
	frame:SetToplevel(true)
	frame:SetWidth(832)
	frame:SetHeight(447)
	frame:SetPoint("TOPLEFT", 0, -104)

	local title = frame:GetTitleRegion()
	title:SetWidth(757)
	title:SetHeight(20)
	title:SetPoint("TOPLEFT", 75, -15)
	
	local texture = frame:CreateTexture(name.."PortraitTexture", "OVERLAY")
	texture:SetWidth(128)
	texture:SetHeight(128)
	texture:SetPoint("TOPLEFT", 8, -2)
	texture:SetTexture("Interface\\AddOns\\OptionHouse\\GnomePortrait")

	local texture = frame:CreateTexture(name.."TopLeft", "ARTWORK")
	texture:SetWidth(256)
	texture:SetHeight(256)
	texture:SetPoint("TOPLEFT", 0, 0)
	texture:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Browse-TopLeft")

	local texture = frame:CreateTexture(name.."Top", "ARTWORK")
	texture:SetWidth(320)
	texture:SetHeight(256)
	texture:SetPoint("TOPLEFT", 256, 0)
	texture:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Browse-Top")

	local texture = frame:CreateTexture(name.."TopRight", "ARTWORK")
	texture:SetWidth(256)
	texture:SetHeight(256)
	texture:SetPoint("TOPLEFT", name.."Top", "TOPRIGHT", 0, 0)
	texture:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Browse-TopRight")
	
	local texture = frame:CreateTexture(name.."BotLeft", "ARTWORK")
	texture:SetWidth(256)
	texture:SetHeight(256)
	texture:SetPoint("TOPLEFT", 0, -256)
	texture:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Browse-BotLeft")

	local texture = frame:CreateTexture(name.."Bot", "ARTWORK")
	texture:SetWidth(320)
	texture:SetHeight(256)
	texture:SetPoint("TOPLEFT", 256, -256)
	texture:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Browse-Bot")

	local texture = frame:CreateTexture(name.."BotRight", "ARTWORK")
	texture:SetWidth(256)
	texture:SetHeight(256)
	texture:SetPoint("TOPLEFT", name.."Bot", "TOPRIGHT", 0, 0)
	texture:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Browse-BotRight")

	local tab = CreateFrame("Button", name.."Tab1", frame, "CharacterFrameTabButtonTemplate")
	tab:SetID( 1 )
	tab:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 15, 11)
	tab:SetText(L["ADDON_OPTIONS"])
	tab:SetScript("OnClick", tabOnClick)

	PanelTemplates_TabResize(0, tab)
	PanelTemplates_SetNumTabs(frame, 3)

	local tab = CreateFrame("Button", name.."Tab2", frame, "CharacterFrameTabButtonTemplate")
	tab:SetID( 2 )
	tab:SetPoint("TOPLEFT", name.."Tab1", "TOPRIGHT", -8, 0)
	tab:SetText(L["ADDON_MANAGEMENT"])
	tab:SetScript("OnClick", tabOnClick)

	PanelTemplates_TabResize(0, tab)

	local tab = CreateFrame("Button", name.."Tab3", frame, "CharacterFrameTabButtonTemplate")
	tab:SetID( 3 )
	tab:SetPoint("TOPLEFT", name.."Tab2", "TOPRIGHT", -8, 0)
	tab:SetText(L["ADDON_PERFORMANCE"])
	tab:SetScript("OnClick", tabOnClick)

	PanelTemplates_TabResize(0, tab)
	
	local button = CreateFrame("Button", name.."CloseButton", frame, "UIPanelCloseButton")
	button:SetPoint("TOPRIGHT", 3, -8)
	button:SetScript("OnClick", function()
		HideUIPanel(frame)
	end )
end

local function focusGained()
	if( this.searchText ) then
		this.searchText = nil
		this:SetText("")
		this:SetTextColor(1, 1, 1, 1)
	end
end

local function focusLost()
	if( not this.searchText and string.trim(this:GetText()) == "" ) then
		this.searchText = true
		this:SetText(L["SEARCH"])
		this:SetTextColor(0.90, 0.90, 0.90, 0.80)
	end
end

local function createSearchInput( frame, onChange )
	local input = CreateFrame("EditBox", frame:GetName() .. "Search", frame, "InputBoxTemplate") 
	input:SetHeight(19)
	input:SetWidth(150)
	input:SetAutoFocus(false)
	input:ClearAllPoints()
	input:SetPoint("CENTER", frame, "BOTTOMLEFT", 100, 25)

	input.searchText = true
	input:SetText(L["SEARCH"])
	input:SetTextColor(0.90, 0.90, 0.90, 0.80)
	input:SetScript("OnTextChanged", onChange)
	input:SetScript("OnEditFocusGained", focusGained)
	input:SetScript("OnEditFocusLost", focusLost)
	
	return input
end

-- ADDON PERFORMANCE PANEL
local function sortPerformanceList( a, b )
	if( not b ) then
		return false
	end

	if( OptionHousePerformanceFrame.sortOrder ) then
		if( OptionHousePerformanceFrame.sortType == "name" ) then
			return ( a.name < b.name )
		elseif( OptionHousePerformanceFrame.sortType == "memory" ) then
			return ( a.memory < b.memory )
		elseif( OptionHousePerformanceFrame.sortType == "cpu" ) then
			return ( a.cpu < b.cpu )
		elseif( OptionHousePerformanceFrame.sortType == "mir" ) then
			if( a.mir == 0 and b.mir == 0 ) then
				return ( a.name < b.name )
			end

			return ( a.mir < b.mir )

		elseif( OptionHousePerformanceFrame.sortType == "cir" ) then
			if( a.mir == 0 and b.mir == 0 ) then
				return ( a.name < b.name )
			end

			return ( a.cir < b.cir )
		end

		return ( a.memory < b.memory )

	else
		if( OptionHousePerformanceFrame.sortType == "name" ) then
			return ( a.name > b.name )
		elseif( OptionHousePerformanceFrame.sortType == "memory" ) then
			return ( a.memory > b.memory )
		elseif( OptionHousePerformanceFrame.sortType == "cpu" ) then
			return ( a.cpu > b.cpu )
		elseif( OptionHousePerformanceFrame.sortType == "mir" ) then
			if( a.mir == 0 and b.mir == 0 ) then
				return ( a.name > b.name )
			end

			return ( a.mir > b.mir )

		elseif( OptionHousePerformanceFrame.sortType == "cir" ) then
			if( a.mir == 0 and b.mir == 0 ) then
				return ( a.name > b.name )
			end

			return ( a.cir > b.cir )
		end

		return ( a.memory > b.memory )
	end
end

local function updateAddonPerformance()
	UpdateAddOnMemoryUsage()
	UpdateAddOnCPUUsage()

	local totalMemory = 0
	local totalCPU = 0
	local frame = OptionHousePerformanceFrame

	for id, addon in pairs(frame.addons) do
		memory = GetAddOnMemoryUsage(addon.name)
		cpu = GetAddOnCPUUsage(addon.name)

		totalMemory = totalMemory + memory
		totalCPU = totalCPU + cpu

		frame.addons[id].mir = abs(addon.memory - memory)
		frame.addons[id].cir = abs(addon.cpu - cpu)
		frame.addons[id].memory = memory
		frame.addons[id].cpu = cpu
	end

	for id, addon in pairs(frame.addons) do
		frame.addons[id].cpuPerct = frame.addons[id].cpu / totalCPU * 100
		frame.addons[id].memPerct = frame.addons[id].memory / totalMemory * 100
	end
end

local function updatePerformanceList()
	local frame = OptionHousePerformanceFrame
	if( not frame:IsShown() ) then
		return
	end
	
	table.sort(frame.addons, sortPerformanceList)
	
	FauxScrollFrame_Update(frame.scroll, #(frame.addons), 15, 20)
	local offset = FauxScrollFrame_GetOffset(frame.scroll)

	for i=1, 15 do
		local index = offset + i
		local column1, column2, column3, column4, column5 = unpack(frame.columns[i])

		if( index <= #(frame.addons) ) then
			local addon = frame.addons[index]
			column1:SetText(addon.name)

			if( addon.memory > 1000 ) then
				column2:SetText(string.format("%.3f MB (%.2f%%)", addon.memory / 1000, addon.memPerct))
			else
				column2:SetText(string.format("%.3f KB (%.2f%%)", addon.memory, addon.memPerct))
			end

			if( addon.mir > 1000 ) then
				column3:SetText(string.format("%.3f MiB/s", addon.mir / 1000))
			else
				column3:SetText(string.format("%.3f KiB/s", addon.mir))
			end

			if( scriptProfiling ) then
				column4:SetText(string.format("%.3f (%.2f%%)", addon.cpu, addon.cpuPerct))
			
				if( addon.cir > 1000 ) then
					column5:SetText(string.format("%.3f MiB/s", addon.cir / 1000))
				else
					column5:SetText(string.format("%.3f KiB/s", addon.cir))
				end
			else
				column4:SetText("----")
				column5:SetText("----")
			end

			column1:Show()
			column2:Show()
			column3:Show()
			column4:Show()
			column5:Show()
		else
			column1:Hide()
			column2:Hide()
			column3:Hide()
			column4:Hide()
			column5:Hide()
		end
	end
end

local elapsed = 0
local function performanceOnUpdate()
	elapsed = elapsed + arg1

	if( elapsed >= 1 ) then
		elapsed = 0

		updateAddonPerformance()
		updatePerformanceList()
	end
end

local function sortOnClick()
	if( this.sortType ) then
		if( this.sortType ~= OptionHousePerformanceFrame.sortType ) then
			OptionHousePerformanceFrame.sortOrder = false
			OptionHousePerformanceFrame.sortType = this.sortType
		else
			OptionHousePerformanceFrame.sortOrder = not OptionHousePerformanceFrame.sortOrder
		end

		updatePerformanceList()
	end
end

local function updateAddonPerfList()
	if( OptionHousePerformanceFrame:IsShown() ) then
		local searchBy = string.trim(string.lower(OptionHousePerformanceFrameSearch:GetText()))
		if( searchBy == "" or OptionHousePerformanceFrameSearch.searchText ) then
			searchBy = nil
		end
		
		OptionHousePerformanceFrame.addons = {}
		for i=1, GetNumAddOns() do
			local name = GetAddOnInfo(i)
			if( IsAddOnLoaded(i) and ( ( searchBy and string.find(string.lower(name), searchBy)) or not searchBy ) ) then
				table.insert(OptionHousePerformanceFrame.addons, {name = name, mir = 0, cir = 0, cpu = 0, memory = 0})
			end
		end
	end
end

tabfunctions[3] = function( hide )
	local name = "OptionHousePerformanceFrame"
	local frame = getglobal(name)
	
	if( frame and hide ) then
		frame:Hide()
		return
	elseif( hide ) then
		return
	elseif( not frame ) then
		frame = CreateFrame("Frame", name, OptionHouseFrame)
		frame:SetToplevel(true)
		frame:SetAllPoints(OptionHouseFrame)
		frame.sortOrder = nil
		frame.sortType = "name"
	
		local toggleCPU = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
		toggleCPU:SetWidth(80)
		toggleCPU:SetHeight(22)
		toggleCPU:SetPoint("BOTTOMRIGHT", OptionHouseFrame, "BOTTOMRIGHT", -8, 14)
		toggleCPU:SetScript("OnClick", function()
			if( GetCVar("scriptProfile") == "1" ) then
				this:SetText(L["ENABLE_CPU"])
				SetCVar("scriptProfile", "0", 1)
			else
				this:SetText(L["DISABLE_CPU"])
				SetCVar("scriptProfile", "1", 1)
			end
		end)

		if( GetCVar( "scriptProfile" ) == "1" ) then
			scriptProfiling = true
			toggleCPU:SetText(L["DISABLE_CPU"])
		else
			toggleCPU:SetText(L["ENABLE_CPU"])
		end

		local reloadUI = CreateFrame("Button", nil, frame, "UIPanelButtonGrayTemplate")
		reloadUI:SetWidth(80)
		reloadUI:SetHeight(22)
		reloadUI:SetPoint("RIGHT", toggleCPU, "LEFT")
		reloadUI:SetText(L["RELOAD_UI"])
		reloadUI:SetScript("OnClick", ReloadUI)

		local button
		for i=1, 5 do
			button = CreateFrame("Button", name .. "SortButton" .. i, frame)
			button:SetScript( "OnClick", sortOnClick)
			button:SetHeight(20)
			button:SetWidth(75)
			button:SetTextFontObject(GameFontNormal)
		end

		local button = OptionHousePerformanceFrameSortButton1
		button.sortType = "name"
		button:SetText(L["NAME"])
		button:SetWidth(button:GetFontString():GetStringWidth() + 3)
		button:SetPoint("TOPLEFT", frame, "TOPLEFT", 25, -75)
		button:Show()

		button = OptionHousePerformanceFrameSortButton2
		button.sortType = "memory"
		button:SetText(L["MEMORY"])
		button:SetWidth(button:GetFontString():GetStringWidth() + 3)
		button:SetPoint("TOPLEFT", OptionHousePerformanceFrameSortButton1, "TOPLEFT", 210, 0)
		button:Show()

		button = OptionHousePerformanceFrameSortButton3
		button.sortType = "mir"
		button:SetText(L["MEMSEC"])
		button:SetWidth(button:GetFontString():GetStringWidth() + 3)
		button:SetPoint("TOPLEFT", OptionHousePerformanceFrameSortButton2, "TOPLEFT", 180, 0)
		button:Show()

		button = OptionHousePerformanceFrameSortButton4
		button.sortType = "cpu"
		button:SetText(L["CPU"])
		button:SetWidth(button:GetFontString():GetStringWidth() + 3)
		button:SetPoint("TOPLEFT", OptionHousePerformanceFrameSortButton3, "TOPLEFT", 140, 0)
		button:Show()

		button = OptionHousePerformanceFrameSortButton5
		button.sortType = "cir"
		button:SetText(L["CPUSEC"])
		button:SetWidth(button:GetFontString():GetStringWidth() + 3 )
		button:SetPoint("TOPLEFT", OptionHousePerformanceFrameSortButton4, "TOPLEFT", 140, 0)
		button:Show()

		frame.columns = {}
		for i=1, 15 do
			frame.columns[i] = {}
			for j=1, 5 do
				text = frame:CreateFontString(name .. "SortRow" .. i .. "Column" .. j, frame)
				text:SetFont((GameFontNormalSmall:GetFont()), 10 )
				text:SetTextColor(1, 1, 1)
				text:Hide()
				frame.columns[i][j] = text

				if( i > 1 ) then
					text:SetPoint("TOPLEFT", name .. "SortRow" .. i - 1 .. "Column" .. j, "TOPLEFT", 0, -20)
				else
					text:SetPoint("TOPLEFT", name .. "SortButton" .. j, "TOPLEFT", 2, -28)
				end
			end
		end
		
		frame.scroll = CreateFrame("ScrollFrame", name.."Scroll", frame, "FauxScrollFrameTemplate")
		frame.scroll:SetPoint("TOPLEFT", frame, "TOPLEFT", 25, -76)
		frame.scroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -35, 38)
		frame.scroll:SetScript("OnVerticalScroll", function()
			FauxScrollFrame_OnVerticalScroll(22, updatePerformanceList)
		end)
			
		local texture = frame.scroll:CreateTexture(nil, "BACKGROUND")
		texture:SetWidth(31)
		texture:SetHeight(256)
		texture:SetPoint("TOPLEFT", frame.scroll, "TOPRIGHT", -2, 5)
		texture:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-ScrollBar")
		texture:SetTexCoord(0, 0.484375, 0, 1.0)

		local texture = frame.scroll:CreateTexture(nil, "BACKGROUND")
		texture:SetWidth(31)
		texture:SetHeight(106)
		texture:SetPoint("BOTTOMLEFT", frame.scroll, "BOTTOMRIGHT", -2, -2 )
		texture:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-ScrollBar")
		texture:SetTexCoord(0.515625, 1.0, 0, 0.4140625)

		frame:SetScript("OnUpdate", performanceOnUpdate)
		frame:SetScript("OnEvent", performanceUpdateList)
		frame:RegisterEvent("ADDON_LOADED")

		createSearchInput(frame, function()
			updateAddonPerfList()
			updateAddonPerformance()
			updatePerformanceList()
		end )
	end

	updateAddonPerfList()
	updateAddonPerformance()
	updatePerformanceList()
	
	frame:Show()
end

-- ADDON MANAGEMENT PANEL
local function updateManageList()
	local frame = OptionHouseManageFrame
	if( not frame:IsShown() ) then
		return
	end
	
	local searchBy = string.trim(string.lower(OptionHouseManageFrameSearch:GetText()))
	if( searchBy == "" or OptionHouseManageFrameSearch.searchText ) then
		searchBy = nil
	end
	
	local addons = {}
	for i=1, GetNumAddOns() do
		if( not searchBy or ( searchBy and string.find((GetAddOnInfo(i)), searchBy) ) ) then
			local name, title, notes, enabled, loadable, reason, security = GetAddOnInfo(i)
			local isLoaded = IsAddOnLoaded(i)
			local isLoD = IsAddOnLoadOnDemand(i)
			local author = GetAddOnMetadata(i, "Author")
			local version = GetAddOnMetadata(i, "Version")
			
			if( addons[name] and addons[name].title ) then
				title = addons[name].title
			end
			
			if( addons[name] and addons[name].version ) then
				version = addons[name].version
			elseif( type(version) == "string" ) then
				version = string.gsub(version, "%$Revision: (%d+) %$", "%1")
				version = string.gsub(version, "%$Rev: (%d+) %$", "%1")
				version = string.gsub(version, "%$LastChangedRevision: (%d+) %$", "%1")
				version = string.trim(version)
			else
				version = nil
			end
			
			if( addons[name] and addons[name].author ) then
				author = addons[name].author
			elseif( type(author) ~= "string" ) then
				author = nil
			end
			
			if( reason == "DISABLED" ) then
				name = "|cff9d9d9d"..name.. "|r"
				isLoD = nil
			elseif( reason == "NOT_DEMAND_LOADED" ) then
				name = "|cffff8000"..name.."|r"
			elseif( loadable and isLoD and not isLoaded and enabled ) then
				reason = "|cff1eff00"..L["LOAD_ON_DEMAND"] .. "|r"
				name = "|cff1eff00"..name.."|r"
			elseif( isLoaded and not enabled ) then
				reason = "|cffa335ee"..L["DISABLED_AT_RELOAD"].."|r"
				isLoD = nil
			
			elseif( isLoD and isLoaded and enabled ) then
				reason = nil
				isLoD = nil
			end
			
			table.insert(addons, {name = name, id = i, title = title, author = author, version = version, reason = reason, isEnabled = enabled, isLoD = isLoD})
		end
	end

	FauxScrollFrame_Update(frame.scroll, #(addons), 15, 22)

	for i=1,15 do
		local row = frame.rows[i]
		local offset = i + FauxScrollFrame_GetOffset(frame.scroll)
		local addon = addons[offset]
		
		if( addon ) then
			-- This could be changed to just add the data depending on what we have
			if( addon.title and addon.author and addon.version ) then
				row.enabled.text = string.format(L["MANAGEMENT_TITLE"], addon.title, addon.author, addon.version)
			else
				row.enabled.text = nil
			end
			
			row.title:SetText(addon.name)
			row.title:Show()

			row.enabled.addon = addon.id
			row.enabled:SetChecked(addon.isEnabled)
			row.enabled:Show()
			
			if( addon.reason ) then
				row.reason:SetText(addon.reason)
				row.reason:Show()
			else
				row.reason:Hide()
			end
			
			if( not addon.isLoD ) then
				row.button:Hide()
			else
				row.button.addon = addon.id
				row.button:Show()
			end
		else
			row.enabled:Hide()
			row.title:Hide()
			row.button:Hide()
			row.reason:Hide()
		end
	end
end

local function loadAddon()
	LoadAddOn(this.addon)
	updateManageList()
end

local function toggleAddOnStatus()
	if( select(4, GetAddOnInfo(this.addon)) ) then
		PlaySound("igMainMenuOptionCheckBoxOff")
		DisableAddOn(this.addon)
	else
		PlaySound("igMainMenuOptionCheckBoxOn")
		EnableAddOn(this.addon)
	end
	
	updateManageList()
end

local function showTooltip()
	if( this.text ) then
		GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
		GameTooltip:SetText(this.text, nil, nil, nil, nil, 1)
	end
end

local function hideTooltip()
	GameTooltip:Hide()
end

tabfunctions[2] = function(hide)
	local name = "OptionHouseManageFrame"
	local frame = getglobal(name)

	if( frame and hide ) then
		frame:Hide()
		return
	elseif( hide ) then
		return
	elseif( not frame ) then
		frame = CreateFrame("Frame", name, OptionHouseFrame)
		frame:SetToplevel(true)
		frame:SetAllPoints(OptionHouseFrame)
		frame:SetScript("OnEvent", updateManageList)
		frame:RegisterEvent("ADDON_LOADED")
				
		createSearchInput(frame, updateManageList)

		local disableAll = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
		disableAll:SetWidth(80)
		disableAll:SetHeight(22)
		disableAll:SetPoint("BOTTOMRIGHT", OptionHouseFrame, "BOTTOMRIGHT", -8, 14)
		disableAll:SetText(L["DISABLE_ALL"])
		disableAll:SetScript("OnClick", function()
			DisableAllAddOns()
			updateManageList()
		end)

		local enableAll = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
		enableAll:SetWidth(80)
		enableAll:SetHeight(22)
		enableAll:SetPoint("RIGHT", disableAll, "LEFT")
		enableAll:SetText(L["ENABLE_ALL"])
		enableAll:SetScript("OnClick", function()
			EnableAllAddOns()
			updateManageList()
		end)

		local reloadUI = CreateFrame("Button", nil, frame, "UIPanelButtonGrayTemplate")
		reloadUI:SetWidth(80)
		reloadUI:SetHeight(22)
		reloadUI:SetPoint("RIGHT", enableAll, "LEFT")
		reloadUI:SetText(L["RELOAD_UI"])
		reloadUI:SetScript("OnClick", ReloadUI)

		frame.rows = {}
		for i=1,15 do
			local row = {}
			frame.rows[i] = row
			row.enabled = CreateFrame("CheckButton", nil, frame, "OptionsCheckButtonTemplate")
			row.enabled:SetWidth(22)
			row.enabled:SetHeight(22)
			row.enabled:SetPoint("TOPLEFT", frame, "TOPLEFT", 25, - (55 + 22 * i))
			row.enabled:SetScript("OnClick", toggleAddOnStatus)
			row.enabled:SetScript("OnEnter", showTooltip)
			row.enabled:SetScript("OnLeave", hideTooltip)

			row.button = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
			row.button:SetWidth(50)
			row.button:SetHeight(22)
			row.button:SetPoint("RIGHT", row.enabled, "RIGHT", 746, 0)
			row.button:SetText(L["LOAD"])
			row.button:SetScript("OnClick", loadAddon)
			
			row.reason = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
			row.reason:SetPoint("RIGHT", row.button, "LEFT", -5, 0)
			
			row.title = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
			row.title:SetPoint("LEFT", row.enabled, "RIGHT", 5, 0)
			row.title:SetPoint("RIGHT", row.reason, "LEFT", -10, 0)
			row.title:SetHeight(22)
			row.title:SetJustifyH("LEFT")
			row.title:SetNonSpaceWrap(false)
		end

		frame.scroll = CreateFrame("ScrollFrame", name.."Scroll", frame, "FauxScrollFrameTemplate")
		frame.scroll:SetPoint("TOPLEFT", frame, "TOPLEFT", 25, -76)
		frame.scroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -35, 38)
		frame.scroll:SetScript("OnVerticalScroll", function() FauxScrollFrame_OnVerticalScroll(22, updateManageList) end)

		local texture = frame.scroll:CreateTexture(nil, "BACKGROUND")
		texture:SetWidth(31)
		texture:SetHeight(256)
		texture:SetPoint("TOPLEFT", frame.scroll, "TOPRIGHT", -2, 5)
		texture:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-ScrollBar")
		texture:SetTexCoord(0, 0.484375, 0, 1.0)

		local texture = frame.scroll:CreateTexture(nil, "BACKGROUND")
		texture:SetWidth(31)
		texture:SetHeight(106)
		texture:SetPoint("BOTTOMLEFT", frame.scroll, "BOTTOMRIGHT", -2, -2 )
		texture:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-ScrollBar")
		texture:SetTexCoord(0.515625, 1.0, 0, 0.4140625)
	end

	updateManageList()
	frame:Show()
end

-- ADDON CONFIGURATION FRAME
local function sortConfigList()
	if( not b ) then
		return false
	end
	
	return ( a.name > b.name )
end

local function updateConfigList()
	local expandedCategories = {}
	local sortedAddons = {}
	local frame = OptionHouseOptionsFrame
	
	local searchBy = string.trim(string.lower(OptionHouseOptionsFrameSearch:GetText()))
	if( searchBy == "" or OptionHouseOptionsFrameSearch.searchText ) then
		searchBy = nil
	end
	
	for addonName, addon in pairs(addons) do
		addon.name = addonName
		table.insert(sortedAddons, addon)
	end
	
	table.sort(sortedAddons, sortConfigList)

	-- [1] = Row name, [2] = Row type, [3] = Is selected, [4] = cat info, [5] = isLast
	for _, addon in pairs( sortedAddons ) do
		 if( ( searchBy and string.find(string.lower(addon.name), searchBy) ) or not searchBy ) then
			if( frame.selectedAddon == addon.name ) then
				if( addon.totalCats > 1 or addon.totalSubs > 0 ) then
					table.insert(expandedCategories, {addon.name, "addon", true})

					for catName, category in pairs(addon.categories) do
						if( ( searchBy and string.find( string.lower( catName ), searchBy ) ) or not searchBy ) then
							if( frame.selectedCategory == catName ) then
								table.insert(expandedCategories, {catName, "category", true, category})

								for subCatName, subCat in pairs( category.sub ) do
									if( frame.selectedSubCat == subCatName ) then
										table.insert(expandedCategories, {subCatName, "subcat", true, subCat})
									else
										table.insert(expandedCategories, {subCatName, "subcat", nil, subCat})
									end
								end

								if( category.totalSubs > 0 ) then
									expandedCategories[#(expandedCategories)][5] = true
								end
							else
								table.insert(expandedCategories, {catName, "category", nil, category})
							end
						end
					end

				elseif( addon.totalCats == 1 ) then
					for catName, category in pairs(addon.categories) do
						if( ( searchBy and string.find( string.lower( catName ), searchBy ) ) or not searchBy ) then
							table.insert(expandedCategories, {addon.name, "addon", true, category})
						end
					end
				end

			elseif( addon.totalCats > 1 or addon.totalSubs > 0 ) then
				table.insert(expandedCategories, {addon.name, "addon"})

			elseif( addon.totalCats == 1 ) then
				for catName, category in pairs(addon.categories) do
					table.insert(expandedCategories, {addon.name, "addon", nil, category})
				end
			end
		end
	end
	
	FauxScrollFrame_Update(frame.scroll, #(expandedCategories), 15, 20)

	local offset = FauxScrollFrame_GetOffset(frame.scroll)
	local line, index, row
	local frame = OptionHouseOptionsFrame

	for i=1, 15 do
		local button = frame.buttons[i]

		if( #(expandedCategories) > 15 ) then
			button:SetWidth(140)
		else
			button:SetWidth(156)
		end

		index = offset + i

		if( index <= #(expandedCategories) ) then
			local row = expandedCategories[index]
			local line = frame.lines[i]

			if( row[3] ) then
				button:LockHighlight()
			else
				button:UnlockHighlight()
			end

			if( row[2] == "addon" ) then
				button:SetText(row[1])
				button:GetFontString():SetPoint("LEFT", button, "LEFT", 4, 0)
				button:GetNormalTexture():SetAlpha(1.0)
				line:Hide()

			elseif( row[2] == "category" ) then
				button:SetText(HIGHLIGHT_FONT_COLOR_CODE..row[1]..FONT_COLOR_CODE_CLOSE)
				button:GetFontString():SetPoint("LEFT", button, "LEFT", 12, 0)
				button:GetNormalTexture():SetAlpha(0.4)
				line:Hide()

			elseif( row[2] == "subcat" ) then
				button:SetText(HIGHLIGHT_FONT_COLOR_CODE..row[1]..FONT_COLOR_CODE_CLOSE)
				button:GetFontString():SetPoint("LEFT", button, "LEFT", 20, 0)
				button:GetNormalTexture():SetAlpha(0.0)
				line:Show()

				if( row[5] ) then
					line:SetTexCoord(0.4375, 0.875, 0, 0.625)
				else
					line:SetTexCoord(0, 0.4375, 0, 0.625)
				end
			end

			if( row[4] ) then
				button.catHandler = row[4].handler
				button.catFunc = row[4].func
				button.catFrame = row[4].frame
				button.catNoCache = row[4].noCache
			end

			button.type = row[2]
			button.catText = row[1]
			button:Show()
		else
			button:Hide()
		end
	end
end

local function expandConfigList()
	local frame = OptionHouseOptionsFrame
	
	if( this.type == "addon" ) then
		if( frame.selectedAddon == this.catText ) then
			frame.selectedAddon = ""
			this.catFrame = nil
		else
			frame.selectedAddon = this.catText
		end

		frame.selectedCategory = ""
		frame.selectedSubCat = ""

	elseif( this.type == "category" ) then
		if( frame.selectedCategory == this.catText ) then
			frame.selectedCategory = ""
			this.catFrame = nil
		else
			frame.selectedCategory = this.catText
		end

		frame.selectedSubCat = ""

	elseif( this.type == "subcat" ) then
		if( frame.selectedSubCat == this.catText ) then
			frame.selectedSubCat = ""

			this.catFrame = addons[frame.selectedAddon].categories[frame.selectedCategory].frame
			this.catHandler = addons[frame.selectedAddon].categories[frame.selectedCategory].handler
			this.catFunc = addons[frame.selectedAddon].categories[frame.selectedCategory].func
		else
			frame.selectedSubCat = this.catText
		end
	end

	if( this.catHandler or this.catFunc ) then
		this.catFrame = nil
		if( type(this.catFunc) == "string" ) then
			this.catFrame = this.catHandler[this.catFunc](this.catHandler)
		elseif( type(this.catHandler) == "function" ) then
			this.catFrame = this.catHandler()
		end
		
		if( this.catFrame ) then
			if( not this.catFrame:GetPoint() ) then
				this.catFrame:SetPoint("TOPLEFT", 190, -103)
			end
			
			if( this.catFrame:GetHeight() > 630 or this.catFrame:GetHeight() == 0 ) then
				this.catFrame:SetHeight(630)
			end
			
			
			if( this.catFrame:GetWidth() > 305 or this.catFrame:GetWidth() == 0 ) then
				this.catFrame:SetWidth(305)
			end
		end

		if( not this.catNoCache and this.catFrame ) then
			local category

			if( frame.selectedSubCat ~= "" ) then
				category = addons[frame.selectedAddon].categories[frame.selectedCategory].sub[frame.selectedSubCat]
			elseif( frame.selectedCategory ~= "" ) then
				category = addons[frame.selectedAddon].categories[frame.selectedCategory]
			elseif( frame.selectedAddon ~= "" ) then
				for catName, _ in pairs(addons[frame.selectedAddon].categories) do
					category = addons[frame.selectedAddon].categories[catName]
				end
			end

			if( category ) then
				category.handler = nil
				category.func = nil
				category.frame = this.catFrame
			end
		end
	end


	if( frame.shownFrame ) then
		frame.shownFrame:Hide()
	end

	if( this.catFrame ) then
		this.catFrame:Show()
		frame.shownFrame = this.catFrame
	end

	updateConfigList()
end

tabfunctions[1] = function(hide)
	local name = "OptionHouseOptionsFrame"
	local frame = getglobal(name)
	
	if( frame and hide ) then
		frame:Hide()
		return
	elseif( hide ) then
		return
	elseif( not frame ) then
		frame = CreateFrame("Frame", name, OptionHouseFrame)
		frame:SetToplevel(true)
		frame:SetAllPoints(OptionHouseFrame)

		frame.buttons = {}
		frame.lines = {}
		for i=1, 15 do
			local button = CreateFrame("Button", name.."FilterButton"..i, frame)
			frame.buttons[i] = button

			button:SetHighlightFontObject(GameFontHighlightSmall)
			button:SetTextFontObject(GameFontNormalSmall)
			button:SetScript("OnClick", expandConfigList)
			button:SetWidth(140)
			button:SetHeight(20)

			button:SetNormalTexture("Interface\\AuctionFrame\\UI-AuctionFrame-FilterBG")
			button:GetNormalTexture():SetTexCoord(0, 0.53125, 0, 0.625)

			button:SetHighlightTexture("Interface\\PaperDollInfoFrame\\UI-Character-Tab-Highlight")
			button:GetHighlightTexture():SetBlendMode("ADD")

			local line = button:CreateTexture(name.."FilterButton"..i.."Line", "BACKGROUND")
			frame.lines[i] = line

			line:SetWidth(7)
			line:SetHeight(20)
			line:SetPoint("LEFT", 13, 0)
			line:SetTexture( "Interface\\AuctionFrame\\UI-AuctionFrame-FilterLines" )
			line:SetTexCoord(0, 0.4375, 0, 0.625)

			if( i > 1 ) then
				button:SetPoint("TOPLEFT", name.."FilterButton"..i - 1, "BOTTOMLEFT", 0, 0)
			else
				button:SetPoint("TOPLEFT", 23, -105)
			end
		end

		frame.scroll = CreateFrame("ScrollFrame", name.."FilterScrollFrame", frame, "FauxScrollFrameTemplate")
		frame.scroll:SetWidth(160)
		frame.scroll:SetHeight(305)
		frame.scroll:SetPoint("TOPRIGHT", frame, "TOPLEFT", 158, -105)
		frame.scroll:SetScript("OnVerticalScroll", function()
			FauxScrollFrame_OnVerticalScroll(20, updateConfigList)
		end )

		local texture = frame.scroll:CreateTexture(name.."FilterScrollFrameScrollUp", "ARTWORK")
		texture:SetWidth(31)
		texture:SetHeight(256)
		texture:SetPoint("TOPLEFT", frame.scroll, "TOPRIGHT", -2, 5 )
		texture:SetTexCoord(0, 0.484375, 0, 1.0)

		local texture = frame.scroll:CreateTexture(name.."FilterScrollFrameScrollDown", "ARTWORK")
		texture:SetWidth(31)
		texture:SetHeight(256)
		texture:SetPoint("BOTTOMLEFT", frame.scroll, "BOTTOMRIGHT", -2, -2 )
		texture:SetTexCoord(0.515625, 1.0, 0, 0.4140625)

		createSearchInput(frame, updateConfigList)
	end

	frame.selectedAddon = ""
	frame.selectedCategory = ""
	frame.selectedSubCat = ""
	frame:Show()

	updateConfigList()
end

function OptionHouse.Open( self, addon, category, subcategory )
	argcheck(addon, 2, "string", "nil")
	argcheck(category, 3, "string", "nil")
	argcheck(subcategory, 4, "string", "nil")

	createOHFrame()
	tabOnClick(1)
	
	if( addon ) then OptionHouseOptionsFrame.selectedAddon = addon end
	if( category ) then OptionHouseOptionsFrame.selectedCategory = category end
	if( subcategory ) then OptionHouseOptionsFrame.selectedSubCat = subcategory end
	
	if( addon or category or subcategory ) then
		updateConfigList()
	end
	
	frame:Show()
end

-- 1 = Configuration / 2 = Management / 3 = Performance
function OptionHouse:OpenTab( id )
	argcheck(id, 1, "number")
	
	tabOnClick(id)
	createOHFrame()
	frame:Show()
end

function OptionHouse:RegisterAddOn( name, title, author, version )
	argcheck(name, 1, "string")
	argcheck(title, 2, "string", "nil")
	argcheck(author, 3, "string", "nil")
	argcheck(version, 4, "string", "nil")
	
	if( addons[name] ) then
		error(string.format(L["ADDON_ALREADYREG"], name), 3)
	end

	addons[name] = {title = title, author = author, version = version, totalCats = 0, totalSubs = 0, categories = {}}
	addons[name].obj = { name = name }
	for id, method in pairs(methods) do
		addons[name].obj[ method ]= OptionHouse[method]
	end

	if( OptionHouseOptionsFrame and OptionHouseOptionsFrame:IsShown() ) then
		updateConfigList()
	end

	return addons[name].obj
end

function OptionHouse.RegisterCategory( addon, name, handler, func, noCache )
	argcheck(name, 2, "string")
	argcheck(handler, 3, "string", "function", "table")
	argcheck(func, 4, "string", "function", "nil")
	argcheck(noCache, 5, "boolean", "number", "nil")
	assert(3, addons[addon.name], string.format(L["MUST_CALL"], addon.name))
	assert(3, addons[addon.name].categories, string.format(L["CATEGORY_ALREADYREG"], name, addon.name))

	addons[addon.name].totalCats = addons[addon.name].totalCats + 1
	addons[addon.name].categories[name] = {func = func, handler = handler, noCache = noCache, sub = {}, totalSubs = 0}

	if( OptionHouseOptionsFrame and OptionHouseOptionsFrame:IsShown() ) then
		updateConfigList()
	end
end

function OptionHouse.RegisterSubCategory( addon, parentCat, name, handler, func, noCache )
	argcheck(parentCat, 2, "string")
	argcheck(name, 3, "string")
	argcheck(handler, 4, "string", "function", "table")
	argcheck(func, 5, "string", "function", "nil")
	argcheck(noCache, 6, "boolean", "number", "nil")
	assert(3, addons[addon.name], string.format(L["MUST_CALL"], addon.name))
	assert(3, addons[addon.name].categories[parentCat], string.format(L["NO_PARENTCAT"], parentCat, addon.name))
	assert(3, addons[addon.name].categories[parentCat].sub[name], string.format(L["SUBCATEGORY_ALREADYREG"], name, parentCat, addon.name))

	addons[addon.name].totalSubs = addons[addon.name].totalSubs + 1
	addons[addon.name].categories[parentCat].totalSubs = addons[addon.name].categories[parentCat].totalSubs + 1
	addons[addon.name].categories[parentCat].sub[name] = {handler = handler, func = func, noCache = noCache}
	
	if( OptionHouseOptionsFrame and OptionHouseOptionsFrame:IsShown() ) then
		updateConfigList()
	end
end

function OptionHouse:GetVersion() return major, minor end


local function Activate(self, old)
	if( old ) then
		addons = old.addons or addons
		evtFrame = old.evtFrame or evtFrame

		--[[
		No reason for this I suppose, will add it if something changes
		GameMenuButtonOptionHouse:SetScript("OnClick", function()
			PlaySound("igMainMenuOption")
			HideUIPanel(GameMenuFrame)
			SlashCmdList["OPTHOUSE"]()
		end)
		]]
	else
		evtFrame = CreateFrame("Frame")
		evtFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
		evtFrame:SetScript("OnEvent",function()
			if( frame and frame:IsShown() ) then
				frame:Hide()
				DEFAULT_CHAT_FRAME:AddMessage(L["ENTERED_COMBAT"])
			end
		end )
		
		local menubutton = CreateFrame("Button", "GameMenuButtonOptionHouse", GameMenuFrame, "GameMenuButtonTemplate")
		menubutton:SetText(L["OPTION_HOUSE"])
		menubutton:SetScript("OnClick", function()
			PlaySound("igMainMenuOption")
			HideUIPanel(GameMenuFrame)
			SlashCmdList["OPTHOUSE"]()
		end)

		local a1, fr, a2, x, y = GameMenuButtonKeybindings:GetPoint()
		menubutton:SetPoint(a1, fr, a2, x, y)

		GameMenuButtonKeybindings:SetPoint(a1, menubutton, a2, x, y)
		GameMenuFrame:SetHeight(GameMenuFrame:GetHeight() + 25)
	end
	
	for name, addon in pairs(addons) do
		for _, method in pairs(methods) do
			addon.obj[method] = OptionHouse[method]
		end
	end

	SLASH_OPTHOUSE1 = "/opthouse"
	SLASH_OPTHOUSE2 = "/oh"
	SlashCmdList["OPTHOUSE"] = OptionHouse.Open
end

OptionHouse = DongleStub:Register(OptionHouse, Activate)