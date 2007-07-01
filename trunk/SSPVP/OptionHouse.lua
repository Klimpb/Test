-- TECHNICALLY
-- We're suppose to embed DongleStub, but since we make sure to load Dongle.lua
-- before OptionHouse it'll exist anyway

local major = "OptionHouse-1.0"
local minor = tonumber(string.match("$Revision: 475 $", "(%d+)") or 1)

assert(DongleStub, string.format("%s requires DongleStub.", major))

if not DongleStub:IsNewerVersion(major, minor) then return end

local L = {
	["IS_PRIVATEAPI"] = "You are trying to call a private api from a non-OptionHouse module.",
	["BAD_ARGUMENT"] = "bad argument #%d to '%s' (%s expected, got %s)",
	["MUST_CALL"] = "You must call '%s' from an OptionHouse addon object.",
	["ADDON_ALREADYREG"] = "The addon '%s' is already registered with OptionHouse.",
	["UNKNOWN_TAB"] = "No tap with the id %d exists, only %d tabs are registered.",
	["CATEGORY_ALREADYREG"] = "A category named '%s' already exists in '%s'",
	["NO_CATEGORYEXISTS"] = "No category named '%s' in '%s' exists.",
	["NO_SUBCATEXISTS"] = "No sub-category '%s' exists in '%s' for the addon '%s'.",
	["NO_PARENTCAT"] = "No parent category named '%s' exists in %s'",
	["SUBCATEGORY_ALREADYREG"] = "The sub-category named '%s' already exists in the category '%s' for '%s'",
	["OPTION_HOUSE"] = "Option House",
	["ENTERED_COMBAT"] = "|cFF33FF99Option House|r: Configuration window closed due to entering combat.",
	["SEARCH"] = "Search...",
	["ADDON_OPTIONS"] = "Addons",
	["VERSION"] = "Version: %s",
	["AUTHOR"] = "Author: %s",
	["TOTAL_CATEGORIES"] = "Categories: %d",
	["TOTAL_SUBCATEGORIES"] = "Sub Categories: %d",
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
local methods = {"RegisterCategory", "RegisterSubCategory", "RemoveCategory", "RemoveSubCategory"}
local addons = {}
local evtFrame
local frame

local function tabOnClick(self)
	local id
	if( type(self) ~= "number" ) then
		id = self:GetID()
	else
		id = self
	end

	PanelTemplates_SetTab(frame, id)

	for tabID, tab in pairs( tabfunctions ) do
		if( tabID == id ) then
			if( type( tab.func ) == "function" ) then
				tab.func()
			else
				tab.handler[tab.func](tab.handler)
			end

			if( tab.type == "browse" ) then
				OptionHouseFrameTopLeft:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Browse-TopLeft")
				OptionHouseFrameTop:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Browse-Top")
				OptionHouseFrameTopRight:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Browse-TopRight")
				OptionHouseFrameBotLeft:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Browse-BotLeft")
				OptionHouseFrameBot:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Browse-Bot")
				OptionHouseFrameBotRight:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Browse-BotRight")
			elseif( tab.type == "bid" ) then
				OptionHouseFrameTopLeft:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Bid-TopLeft")
				OptionHouseFrameTop:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Bid-Top")
				OptionHouseFrameTopRight:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Bid-TopRight")
				OptionHouseFrameBotLeft:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Bid-BotLeft")
				OptionHouseFrameBot:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Bid-Bot")
				OptionHouseFrameBotRight:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Bid-BotRight")
			end

		elseif( type( tab.func ) == "function" ) then
			tab.func(true)
		else
			tab.handler[tab.func](tab.handler, true)
		end
	end
end

local function createTab( text, id )
	local tab = CreateFrame("Button", "OptionHouseFrameTab" .. id, frame, "CharacterFrameTabButtonTemplate" )
	tab:SetID(id)
	tab:SetScript("OnClick", tabOnClick)
	tab:SetText(text)

	PanelTemplates_TabResize(0, tab)
	PanelTemplates_SetNumTabs(frame, id)

	if( id == 1 ) then
		tab:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 15, 11)
	else
		tab:SetPoint("TOPLEFT", "OptionHouseFrameTab" .. id-1, "TOPRIGHT", -8, 0 )
	end
end

local function focusGained(self)
	if( self.searchText ) then
		self.searchText = nil
		self:SetText("")
		self:SetTextColor(1, 1, 1, 1)
	end
end

local function focusLost(self)
	if( not self.searchText and string.trim(self:GetText()) == "" ) then
		self.searchText = true
		self:SetText(L["SEARCH"])
		self:SetTextColor(0.90, 0.90, 0.90, 0.80)
	end
end

local function createSearchInput(frame, onChange)
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

-- ADDON CONFIGURATION
local function sortConfigList(a, b)
	if( not b ) then
		return false
	end

	return ( a.name > b.name )
end

local function showTooltip(self)
	if( self.tooltip ) then
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(self.tooltip, nil, nil, nil, nil, 1)
	end
end

local function hideTooltip()
	GameTooltip:Hide()
end

local function createConfigList()
	local frame = OptionHouseOptionsFrame
	frame.addons = {}

	for addonName, addon in pairs(addons) do
		addon.name = addonName
		table.insert(frame.addons, addon)
	end

	table.sort(frame.addons, sortConfigList)
end


local expandedCategories = {}
local function createExpandList()
	local frame = OptionHouseOptionsFrame
	for k, _ in pairs(expandedCategories) do
		expandedCategories[k] = nil
	end

	local searchBy = string.trim(string.lower(OptionHouseOptionsFrameSearch:GetText()))
	if( searchBy == "" or OptionHouseOptionsFrameSearch.searchText ) then
		searchBy = nil
	end

	-- [1] = Row name, [2] = Row type, [3] = Is selected, [4] = data, [5] = isLast
	for _, addon in pairs( frame.addons ) do
		-- Valid search, or no search used
		if( ( searchBy and string.find(string.lower(addon.name), searchBy) ) or not searchBy ) then
			local tooltip = addon.title or addon.name
			if( addon.version ) then
				tooltip = tooltip .. "\n" .. string.format(L["VERSION"], addon.version)
			end
			if( addon.author ) then
				tooltip = tooltip .. "\n" .. string.format(L["AUTHOR"], addon.author)
			end

			-- Show categories/sub categories if selected
			if( frame.selectedAddon == addon.name ) then
				-- Do we have more then one category or any sub categories
				if( addon.totalCats > 1 or addon.totalSubs > 0 ) then
					table.insert(expandedCategories, {text = addon.name, type = "addon", highlighted = true, tooltip = tooltip})

					for catName, category in pairs(addon.categories) do
						-- Valid search, or no search used
						if( ( searchBy and string.find( string.lower( catName ), searchBy ) ) or not searchBy ) then
							category.parentCat = catName

							local tooltip
							if( category.totalSubs > 0 ) then
								tooltip = string.format( L["TOTAL_SUBCATEGORIES"], category.totalSubs )
							end

							if( frame.selectedCategory == catName ) then
								table.insert(expandedCategories, {text = catName, type = "category", highlighted = true, data = category, tooltip = tooltip})

								for subCatName, subCat in pairs(category.sub) do
									subCat.parentCat = catName

									if( frame.selectedSubCat == subCatName ) then
										table.insert(expandedCategories, {text = subCatName, type = "subcat", highlighted = true, data = subCat})
									else
										table.insert(expandedCategories, {text = subCatName, type = "subcat", data = subCat})
									end
								end

								-- Cheat so we don't have to track row # in the sub loop
								if( category.totalSubs > 0 ) then
									expandedCategories[#(expandedCategories)].last = true
								end
							else
								table.insert(expandedCategories, {text = catName, type = "category", data = category, tooltip = tooltip})
							end
						end
					end

				-- Make the addon row call the only categories handler/func/frame then
				elseif( addon.totalCats == 1 ) then
					for catName, category in pairs(addon.categories) do
						category.parentCat = catName
						table.insert(expandedCategories, {text = addon.name, type = "addon", tooltip = tooltip, highlighted = true, data = category})
						break
					end
				end

			-- More then one category or sub category
			elseif( addon.totalCats > 1 or addon.totalSubs > 0 ) then
				table.insert(expandedCategories, {text = addon.name, type = "addon", tooltip = tooltip})

			-- Make the addon row call the only categories handler/func/frame then
			elseif( addon.totalCats == 1 ) then
				for catName, category in pairs(addon.categories) do
					category.parentCat = catName
					table.insert(expandedCategories, {text = addon.name, type = "addon", tooltip = tooltip, data = category})
					break
				end
			end
		end
	end
end

local function updateConfigList()
	local frame = OptionHouseOptionsFrame
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

			if( row.highlighted ) then
				button:LockHighlight()
			else
				button:UnlockHighlight()
			end

			if( row.type == "addon" ) then
				button:SetText(row.text)
				button:GetFontString():SetPoint("LEFT", button, "LEFT", 4, 0)
				button:GetNormalTexture():SetAlpha(1.0)
				line:Hide()

			elseif( row.type == "category" ) then
				button:SetText(HIGHLIGHT_FONT_COLOR_CODE..row.text..FONT_COLOR_CODE_CLOSE)
				button:GetFontString():SetPoint("LEFT", button, "LEFT", 12, 0)
				button:GetNormalTexture():SetAlpha(0.4)
				line:Hide()

			elseif( row.type == "subcat" ) then
				button:SetText(HIGHLIGHT_FONT_COLOR_CODE..row.text..FONT_COLOR_CODE_CLOSE)
				button:GetFontString():SetPoint("LEFT", button, "LEFT", 20, 0)
				button:GetNormalTexture():SetAlpha(0.0)
				line:Show()

				if( row.last ) then
					line:SetTexCoord(0.4375, 0.875, 0, 0.625)
				else
					line:SetTexCoord(0, 0.4375, 0, 0.625)
				end
			end

			button.tooltip = row.tooltip
			button.data = row.data
			button.type = row.type
			button.catText = row.text
			button:Show()
		else
			button:Hide()
		end
	end
end

local function openConfigFrame( data )
	local frame = OptionHouseOptionsFrame

	-- Clicking on an addon with multiple categories or sub categories will cause no data
	if( not data ) then
		-- Make sure the frames hidden when only the addon button is selected
		if( frame.shownFrame ) then
			frame.shownFrame:Hide()
		end
		return
	end

	if( data.handler or data.func ) then
		data.frame = nil

		-- So you know what category/sub cat is shown for frame recycling
		if( type(data.func) == "string" ) then
			data.frame = data.handler[data.func](data.handler, data.parentCat or frame.selectedCategory, frame.selectedSubCat)
		elseif( type(data.handler) == "function" ) then
			data.frame = data.handler(data.parentCat or frame.selectedCategory, frame.selectedSubCat)
		end

		-- Validate location/width/height and force parent
		if( data.frame ) then
			if( not data.frame:GetPoint() ) then
				data.frame:SetPoint("TOPLEFT", frame, "TOPLEFT", 190, -103)
			end

			if( data.frame:GetWidth() > 630 or data.frame:GetWidth() == 0 ) then
				data.frame:SetWidth(630)
			end

			if( data.frame:GetHeight() > 305 or data.frame:GetHeight() == 0 ) then
				data.frame:SetHeight(305)
			end

			data.frame:SetParent(frame)
			data.frame:SetFrameStrata("HIGH")
		end

		if( not data.noCache and data.frame ) then
			local category

			-- Figure out which category we're modifying
			if( frame.selectedSubCat ~= "" ) then
				category = addons[frame.selectedAddon].categories[frame.selectedCategory].sub[frame.selectedSubCat]
			elseif( frame.selectedCategory ~= "" ) then
				category = addons[frame.selectedAddon].categories[frame.selectedCategory]
			elseif( frame.selectedAddon ~= "" ) then
				for catName, _ in pairs(addons[frame.selectedAddon].categories) do
					category = addons[frame.selectedAddon].categories[catName]
				end
			end

			-- Remove the handler/func and save the frame for next time
			if( category ) then
				data.frame.time = GetTime()
				category.handler = nil
				category.func = nil
				category.frame = data.frame
			end
		end
	end

	if( frame.shownFrame ) then
		frame.shownFrame:Hide()
	end

	-- Now show the current one
	if( data.frame and frame.selectedAddon ~= "" ) then
		data.frame:Show()
		frame.shownFrame = data.frame
	end
end

local function expandConfigList(self)
	local frame = OptionHouseOptionsFrame

	if( self.type == "addon" ) then
		if( frame.selectedAddon == self.catText ) then
			frame.selectedAddon = ""
		else
			frame.selectedAddon = self.catText
		end

		frame.selectedCategory = ""
		frame.selectedSubCat = ""

	elseif( self.type == "category" ) then
		if( frame.selectedCategory == self.catText ) then
			frame.selectedCategory = ""
			self.data = nil
		else
			frame.selectedCategory = self.catText
		end

		frame.selectedSubCat = ""

	elseif( self.type == "subcat" ) then
		if( frame.selectedSubCat == self.catText ) then
			frame.selectedSubCat = ""

			-- Make sure the frame gets hidden when deselecting
			self.data = addons[frame.selectedAddon].categories[frame.selectedCategory]
		else
			frame.selectedSubCat = self.catText
		end
	end

	openConfigFrame(self.data)
	createExpandList()
	updateConfigList()
end


local function addonConfigTab( hide )
	local name = "OptionHouseOptionsFrame"
	local frame = getglobal(name)

	if( frame and hide ) then
		frame:Hide()
		return
	elseif( hide ) then
		return
	elseif( not frame ) then
		frame = CreateFrame("Frame", name, OptionHouseFrame)
		frame:SetFrameStrata("MEDIUM")
		frame:SetAllPoints(OptionHouseFrame)

		frame.buttons = {}
		frame.lines = {}
		for i=1, 15 do
			local button = CreateFrame("Button", name.."FilterButton"..i, frame)
			frame.buttons[i] = button

			button:SetHighlightFontObject(GameFontHighlightSmall)
			button:SetTextFontObject(GameFontNormalSmall)
			button:SetScript("OnClick", expandConfigList)
			button:SetScript("OnEnter", showTooltip)
			button:SetScript("OnLeave", hideTooltip)
			button:SetWidth(140)
			button:SetHeight(20)

			button:SetNormalTexture("Interface\\AuctionFrame\\UI-AuctionFrame-FilterBG")
			button:GetNormalTexture():SetTexCoord(0, 0.53125, 0, 0.625)

			button:SetHighlightTexture("Interface\\PaperDollInfoFrame\\UI-Character-Tab-Highlight")
			button:GetHighlightTexture():SetBlendMode("ADD")

			-- For sub categories only
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

		createSearchInput(frame, function()
			createExpandList()
			updateConfigList()
		end )

		-- Create/sort addon list
		createConfigList()
	end

	-- Reset selection
	frame.selectedAddon = ""
	frame.selectedCategory = ""
	frame.selectedSubCat = ""

	-- Hide the open config frame
	if( frame.shownFrame ) then
		frame.shownFrame:Hide()
	end

	createExpandList()
	updateConfigList()
	frame:Show()
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
	frame:SetFrameStrata("MEDIUM")
	frame:SetWidth(832)
	frame:SetHeight(447)
	frame:SetPoint("TOPLEFT", 0, -104)

	local title = frame:GetTitleRegion()
	title:SetWidth(757)
	title:SetHeight(20)
	title:SetPoint("TOPLEFT", 75, -15)

	-- Embedded version wont include the icon cause authors are more whiny then users
	if( not IsAddOnLoaded("OptionHouse") ) then
		local texture = frame:CreateTexture(name.."PortraitTexture", "OVERLAY")
		texture:SetWidth(57)
		texture:SetHeight(57)
		texture:SetPoint("TOPLEFT", 9, -7)
		SetPortraitTexture(texture, "player")
	else
		local texture = frame:CreateTexture(name.."PortraitTexture", "OVERLAY")
		texture:SetWidth(128)
		texture:SetHeight(128)
		texture:SetPoint("TOPLEFT", 9, -2)
		texture:SetTexture("Interface\\AddOns\\OptionHouse\\GnomePortrait")
	end

	local title = frame:CreateFontString(name.."Title", "OVERLAY")
	title:SetFontObject(GameFontNormal)
	title:SetPoint("TOP", 0, -18)
	title:SetText(L["OPTION_HOUSE"])

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

	local tabs = {{func = addonConfigTab, text = L["ADDON_OPTIONS"], type = "browse"}}
	createTab(L["ADDON_OPTIONS"], 1)

	for id, tab in pairs(tabfunctions) do
		table.insert(tabs, tab)
		createTab(tab.text, id + 1)
	end

	tabfunctions = tabs


	local button = CreateFrame("Button", name.."CloseButton", frame, "UIPanelCloseButton")
	button:SetPoint("TOPRIGHT", 3, -8)
	button:SetScript("OnClick", function()
		HideUIPanel(frame)
	end)
end

function OptionHouse:TaintFix() self.TaintFix = nil end

-- PRIVATE API's
-- These are only to be used for the standalone OptionHouse modules
function OptionHouse:CreateSearchInput(frame, onChange)
	assert(3, select(2, issecurevariable(frame:GetName())) == "OptionHouse", L["IS_PRIVATEAPI"])
	return createSearchInput(frame, onChange)
end

function OptionHouse.RegisterTab( self, text, func, type )
	assert(3, select(2, issecurevariable(self, "RegisterTab")) == "OptionHouse", L["IS_PRIVATEAPI"])
	table.insert(tabfunctions, {func = func, handler = self, text = text, type = type})

	-- Will create all the queued frames if needed
	if( not frame ) then
		return
	end

	createTab(text, #(tabfunctions))
end

function OptionHouse.GetAddOnData(self, name)
	assert(3, select(2, issecurevariable(self, "GetAddOnData")) == "OptionHouse", L["IS_PRIVATEAPI"])
	return addons[name]
end

-- PUBLIC API's
function OptionHouse:Open(addonName, parentCat, childCat)
	argcheck(addonName, 1, "string", "nil")
	argcheck(parentCat, 2, "string", "nil")
	argcheck(childCat, 3, "string", "nil")

	createOHFrame()
	tabOnClick(1)

	if( not addonName ) then
		frame:Show()
		return
	end

	-- Cleanest method for getting the func/handler/ect
	-- to auto open to a page
	for name, addon in pairs(addons) do
		if( name == addonName ) then
			OptionHouseOptionsFrame.selectedAddon = addonName
			for catName, cat in pairs(addon.categories) do
				if( catName == parentCat ) then
					OptionHouseOptionsFrame.selectedCategory = catName
					-- Searching for a sub cat
					if( subCat and cat.totalSubs > 0 ) then
						for subCatName, subCat in pairs(cat.sub) do
							-- Found sub cat, open it
							if( subCatName == childCat ) then
								OptionHouseOptionsFrame.selectedSubCat = subCatName
								openConfigFrame(subCat)
								break
							end
						end

					-- Searching for a category not a sub cat
					elseif( not subCat ) then
						openConfigFrame(cat)
					end
					break
				end
			end
			break
		end
	end

	-- Now expand anything that was selected
	createExpandList()
	updateConfigList()
	frame:Show()
end

function OptionHouse:OpenTab(id)
	argcheck(id, 1, "number")
	assert(3, #(tabfunctions) <= id, string.format(L["UNKNOWN_TAB"], id, #(tabfunctions)))	

	tabOnClick(id)
	createOHFrame()
	frame:Show()
end

function OptionHouse:RegisterAddOn( name, title, author, version )
	argcheck(name, 1, "string")
	argcheck(title, 2, "string", "nil")
	argcheck(author, 3, "string", "nil")
	argcheck(version, 4, "string", "number", "nil")
	assert(3, not addons[name], string.format(L["ADDON_ALREADYREG"], name))

	addons[name] = {title = title, author = author, version = version, totalCats = 0, totalSubs = 0, categories = {}}
	addons[name].obj = {name = name}

	-- So we can upgrade the function pointer if a newer rev is found
	for id, method in pairs(methods) do
		addons[name].obj[method] = OptionHouse[method]
	end

	if( OptionHouseOptionsFrame and OptionHouseOptionsFrame:IsShown() ) then
		createConfigList()
		createExpandList()
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

	-- Category numbers are required so we know when to skip it because only one category/sub cat exists
	addons[addon.name].totalCats = addons[addon.name].totalCats + 1
	addons[addon.name].categories[name] = {func = func, handler = handler, noCache = noCache, sub = {}, totalSubs = 0}

	if( OptionHouseOptionsFrame and OptionHouseOptionsFrame:IsShown() ) then
		createExpandList()
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
	assert(3, not addons[addon.name].categories[parentCat].sub[name], string.format(L["SUBCATEGORY_ALREADYREG"], name, parentCat, addon.name))

	addons[addon.name].totalSubs = addons[addon.name].totalSubs + 1
	addons[addon.name].categories[parentCat].totalSubs = addons[addon.name].categories[parentCat].totalSubs + 1
	addons[addon.name].categories[parentCat].sub[name] = {handler = handler, func = func, noCache = noCache}

	if( OptionHouseOptionsFrame and OptionHouseOptionsFrame:IsShown() ) then
		createExpandList()
		updateConfigList()
	end
end

function OptionHouse.RemoveCategory( addon, name )
	argcheck(name, 2, "string")
	assert(3, addons[addon.name], string.format(L["MUST_CALL"], addon.name))
	assert(3, not addons[addon.name].categories[name], string.format(L["NO_CATEGORYEXISTS"], name, addon.name))

	addons[addon.name].totalCats = addons[addon.name].totalCats - 1
	addons[addon.name].categories[name] = nil

	if( OptionHouseOptionsFrame and OptionHouseOptionsFrame:IsShown() ) then
		createExpandList()
		updateConfigList()
	end
end

function OptionHouse.RemoveSubCategory( addon, parentCat, name )
	argcheck(parentCat, 2, "string")
	argcheck(name, 2, "string")
	assert(3, addons[addon.name], string.format(L["MUST_CALL"], addon.name))
	assert(3, addons[addon.name].categories[parentCat], string.format(L["NO_PARENTCAT"], name, addon.name))
	assert(3, addons[addon.name].categories[parentCat].sub[name], string.format(L["NO_SUBCATEXISTS"], name, parentCat, addon.name))

	addons[addon.name].totalSubs = addons[addon.name].totalSubs - 1
	addons[addon.name].categories[parentCat].totalSubs = addons[addon.name].categories[parentCat].totalSubs - 1
	addons[addon.name].categories[parentCat].sub[name] = nil

	if( OptionHouseOptionsFrame and OptionHouseOptionsFrame:IsShown() ) then
		createExpandList()
		updateConfigList()
	end
end

function OptionHouse:GetVersion() return major, minor end


local function Activate(self, old)
	if( old ) then
		addons = old.addons or addons
		evtFrame = old.evtFrame or evtFrame
		tabfunctions = old.tabfunctions or tabfunctions
	else
		-- Secure headers are supported so don't want the window stuck open in combat
		evtFrame = CreateFrame("Frame")
		evtFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
		evtFrame:SetScript("OnEvent",function()
			if( frame and frame:IsShown() ) then
				frame:Hide()
				DEFAULT_CHAT_FRAME:AddMessage(L["ENTERED_COMBAT"])
			end
		end )

		-- Make sure it hasn't been created already.
		-- don't have to upgrade the referance because it just uses the slash command
		if( not GameMenuButtonOptionHouse ) then
			local menubutton = CreateFrame("Button", "GameMenuButtonOptionHouse", GameMenuFrame, "GameMenuButtonTemplate")
			menubutton:SetText(L["OPTION_HOUSE"])
			menubutton:SetScript("OnClick", function()
				PlaySound("igMainMenuOption")
				HideUIPanel(GameMenuFrame)
				SlashCmdList["OPTHOUSE"]()
			end)

			-- Position below Interface Options
			local a1, fr, a2, x, y = GameMenuButtonKeybindings:GetPoint()
			menubutton:SetPoint(a1, fr, a2, x, y)

			GameMenuButtonKeybindings:SetPoint(a1, menubutton, a2, x, y)
			GameMenuFrame:SetHeight(GameMenuFrame:GetHeight() + 25)
		end
	end

	self.addons = addons
	self.evtFrame = evtFrame
	self.tabfunctions = tabfunctions

	-- Upgrade functions to point towards the latest revision
	for name, addon in pairs(addons) do
		for _, method in pairs(methods) do
			addon.obj[method] = OptionHouse[method]
		end
	end

	SLASH_OPTHOUSE1 = "/opthouse"
	SLASH_OPTHOUSE2 = "/oh"
	SlashCmdList["OPTHOUSE"] = OptionHouse.Open
	
	-- Problems with issecurevariable if we odn't do this
	self:TaintFix()
end

OptionHouse = DongleStub:Register(OptionHouse, Activate)