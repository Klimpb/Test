--[[-------------------------------------------------------------------------
  Copyright (c) 2006-2007, Dongle Development Team
  All rights reserved.

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are
  met:

      * Redistributions of source code must retain the above copyright
        notice, this list of conditions and the following disclaimer.
      * Redistributions in binary form must reproduce the above
        copyright notice, this list of conditions and the following
        disclaimer in the documentation and/or other materials provided
        with the distribution.
      * Neither the name of the Dongle Development Team nor the names of
        its contributors may be used to endorse or promote products derived
        from this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
  A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
  OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
  THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
---------------------------------------------------------------------------]]
local major = "DongleStub"
local minor = tonumber(string.match("$Revision: 313 $", "(%d+)") or 1)

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
local major = "OptionHouse-1.0"
local minor = tonumber(string.match("$Revision: 570 $", "(%d+)") or 1)

assert(DongleStub, string.format("%s requires DongleStub.", major))

if not DongleStub:IsNewerVersion(major, minor) then return end

local L = {
	["ERROR_NO_FRAME"] = "No frame returned for the addon \"%s\", category \"%s\", sub category \"%s\".",
	["NO_FUNC_PASSED"] = "You must associate a function with a category.",
	["IS_PRIVATEAPI"] = "You are trying to call a private api from a non-OptionHouse module.",
	["BAD_ARGUMENT"] = "bad argument #%d to '%s' (%s expected, got %s)",
	["MUST_CALL"] = "You must call '%s' from an OptionHouse addon object.",
	["ADDON_ALREADYREG"] = "The addon '%s' is already registered with OptionHouse.",
	["UNKNOWN_TAB"] = "No tab with the id %d exists, only %d tabs are registered.",
	["CATEGORY_ALREADYREG"] = "A category named '%s' already exists in '%s'",
	["NO_CATEGORYEXISTS"] = "No category named '%s' in '%s' exists.",
	["NO_SUBCATEXISTS"] = "No sub-category '%s' exists in '%s' for the addon '%s'.",
	["FRAME_DRAGGING"] = "Left Click + Drag to move.\nRight click to reset position.",
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
	["TAB_MANAGEMENT"] = "Management",
	["TAB_PERFORMANCE"] = "Performance",
	["UNKNOWN_FRAMETYPE"] = "Unknown frame type requested '%s', only 'main', 'perf', 'addon', 'config' are supported.",
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
local regFrames = {}
local evtFrame
local frame

local function resizeTab(tab)
	local textWidth = tab:GetFontString():GetWidth()
	
	tab.middleActive:SetWidth(textWidth)
	tab.middleInactive:SetWidth(textWidth)
	
	tab:SetWidth((2 * tab.leftActive:GetWidth()) + textWidth)
	tab.highlightTexture:SetWidth(textWidth + 20)
end

local function tabSelected(tab)
	tab:SetTextColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)
	tab.highlightTexture:Hide()
	
	tab.leftActive:Show()
	tab.middleActive:Show()
	tab.rightActive:Show()
	
	tab.leftInactive:Hide()
	tab.middleInactive:Hide()
	tab.rightInactive:Hide()
end

local function tabDeselected(tab)
	tab:SetTextColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b)
	tab.highlightTexture:Show()
	
	tab.leftInactive:Show()
	tab.middleInactive:Show()
	tab.rightInactive:Show()

	tab.leftActive:Hide()
	tab.middleActive:Hide()
	tab.rightActive:Hide()
end

local function setTab(id)
	if( frame.selectedTab ) then
		tabDeselected(frame.tabs[frame.selectedTab])
	end
	
	frame.selectedTab = id
	tabSelected(frame.tabs[id])
end

local function tabOnClick(self)
	local id
	if( type(self) ~= "number" ) then
		id = self:GetID()
	else
		id = self
	end

	setTab(id)

	for tabID, tab in pairs(tabfunctions) do
		if( tabID == id ) then
			if( type(tab.func) == "function" ) then
				tab.func()
			else
				tab.handler[tab.func](tab.handler)
			end

			if( tab.type == "browse" ) then
				frame.topLeft:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Browse-TopLeft")
				frame.top:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Browse-Top")
				frame.topRight:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Browse-TopRight")
				frame.bottomLeft:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Browse-BotLeft")
				frame.bottom:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Browse-Bot")
				frame.bottomRight:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Browse-BotRight")
			elseif( tab.type == "bid" ) then
				frame.topLeft:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Bid-TopLeft")
				frame.top:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Bid-Top")
				frame.topRight:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Bid-TopRight")
				frame.bottomLeft:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Bid-BotLeft")
				frame.bottom:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Bid-Bot")
				frame.bottomRight:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Bid-BotRight")
			end

		elseif( type(tab.func) == "function" ) then
			tab.func(true)
		else
			tab.handler[tab.func](tab.handler, true)
		end
	end
end

local function createTab(text, id)
	local tab = frame.tabs[id]
	if( not tab ) then
		tab = CreateFrame("Button", nil, frame)
		tab:SetHighlightFontObject(GameFontHighlightSmall)
		tab:SetTextFontObject(GameFontNormalSmall)
		tab:SetHighlightTexture("Interface\\PaperDollInfoFrame\\UI-Character-Tab-Highlight")
		tab:SetText(text)
		tab:SetWidth(115)
		tab:SetHeight(32)
		tab:GetFontString():SetPoint("CENTER", 0, 2)
		
		tab.highlightTexture = tab:GetHighlightTexture()
		tab.highlightTexture:ClearAllPoints()
		tab.highlightTexture:SetPoint("CENTER", tab:GetFontString(), 0, 0)
		tab.highlightTexture:SetBlendMode("ADD")
		
		-- TAB SELECTED TEXTURES
		tab.leftActive = tab:CreateTexture(nil, "ARTWORK")
		tab.leftActive:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-ActiveTab")
		tab.leftActive:SetHeight(32)
		tab.leftActive:SetWidth(20)
		tab.leftActive:SetPoint("TOPLEFT", tab, "TOPLEFT")
		tab.leftActive:SetTexCoord(0, 0.15625, 0, 1.0)

		tab.middleActive = tab:CreateTexture(nil, "ARTWORK")
		tab.middleActive:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-ActiveTab")
		tab.middleActive:SetHeight(32)
		tab.middleActive:SetWidth(20)
		tab.middleActive:SetPoint("LEFT", tab.leftActive, "RIGHT")
		tab.middleActive:SetTexCoord(0.15625, 0.84375, 0, 1.0)

		tab.rightActive = tab:CreateTexture(nil, "ARTWORK")
		tab.rightActive:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-ActiveTab")
		tab.rightActive:SetHeight(32)
		tab.rightActive:SetWidth(20)
		tab.rightActive:SetPoint("LEFT", tab.middleActive, "RIGHT")
		tab.rightActive:SetTexCoord(0.84375, 1.0, 0, 1.0)
		
		-- TAB DESELECTED TEXTURES
		tab.leftInactive = tab:CreateTexture(nil, "ARTWORK")
		tab.leftInactive:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-InActiveTab")
		tab.leftInactive:SetHeight(32)
		tab.leftInactive:SetWidth(20)
		tab.leftInactive:SetPoint("TOPLEFT", tab, "TOPLEFT")
		tab.leftInactive:SetTexCoord(0, 0.15625, 0, 1.0)

		tab.middleInactive = tab:CreateTexture(nil, "ARTWORK")
		tab.middleInactive:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-InActiveTab")
		tab.middleInactive:SetHeight(32)
		tab.middleInactive:SetWidth(20)
		tab.middleInactive:SetPoint("LEFT", tab.leftInactive, "RIGHT")
		tab.middleInactive:SetTexCoord(0.15625, 0.84375, 0, 1.0)

		tab.rightInactive = tab:CreateTexture(nil, "ARTWORK")
		tab.rightInactive:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-InActiveTab")
		tab.rightInactive:SetHeight(32)
		tab.rightInactive:SetWidth(20)
		tab.rightInactive:SetPoint("LEFT", tab.middleInactive, "RIGHT")
		tab.rightInactive:SetTexCoord(0.84375, 1.0, 0, 1.0)

		frame.totalTabs = frame.totalTabs + 1
		frame.tabs[id] = tab
	end

	tab:SetID(id)
	tab:SetScript("OnClick", tabOnClick)
	tab:SetText(text)
	tab:Show()
	
	tabDeselected(tab)
	resizeTab(tab)
	
	if( id == 1 ) then
		tab:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 15, 11)
	else
		tab:SetPoint("TOPLEFT", frame.tabs[id - 1], "TOPRIGHT", -8, 0)
	end
end

-- SCROLL FRAME
local function onVerticalScroll(self, offset)
	offset = ceil(offset)

	self.bar:SetValue(offset)
	self.offset = ceil((offset / self.displayNum))
	
	if( self.offset < 0 ) then
		self.offset = 0
	end

	local min, max = self.bar:GetMinMaxValues()

	if( min == offset ) then
		self.up:Disable()
	else
		self.up:Enable()
	end

	if( max == offset ) then
		self.down:Disable()
	else
		self.down:Enable()	
	end

	self.updateFunc()
end

local function onMouseWheel(self, offset)
	if( offset > 0 ) then
		self.bar:SetValue(self.bar:GetValue() - (self.bar:GetHeight() / 2))
	else
		self.bar:SetValue(self.bar:GetValue() + (self.bar:GetHeight() / 2))
	end
end

local function onParentMouseWheel(self, offset)
	onMouseWheel(self.scroll, offset)
end

local function updateScroll(scroll, totalRows)
	local max = (totalRows - scroll.displayNum) * scroll.displayNum
	if( max < 0 ) then
		max = 0
	end
	scroll.bar:SetMinMaxValues(0, max)

	if( totalRows > scroll.displayNum ) then
		scroll:Show()
		scroll.bar:Show()
		scroll.up:Show()
		scroll.down:Show()
		scroll.bar:GetThumbTexture():Show()
	else
		scroll:Hide()
		scroll.bar:Hide()
		scroll.up:Hide()
		scroll.down:Hide()
		scroll.bar:GetThumbTexture():Hide()
	end
end

local function createScrollFrame(frame, displayNum, onScroll)
	frame:EnableMouseWheel(true)
	frame:SetScript("OnMouseWheel", onParentMouseWheel)
	
	frame.scroll = CreateFrame("ScrollFrame", nil, frame)
	frame.scroll:EnableMouseWheel(true)
	frame.scroll:SetWidth(16)
	frame.scroll:SetHeight(270)
	frame.scroll:SetScript("OnVerticalScroll", onVerticalScroll)
	frame.scroll:SetScript("OnMouseWheel", onMouseWheel)

	frame.scroll.offset = 0
	frame.scroll.displayNum = displayNum
	frame.scroll.updateFunc = onScroll
	
	-- Actual bar for scrolling
	frame.scroll.bar = CreateFrame("Slider", nil, frame.scroll)
	frame.scroll.bar:SetValueStep(frame.scroll.displayNum)
	frame.scroll.bar:SetMinMaxValues(0, 0)
	frame.scroll.bar:SetValue(0)
	frame.scroll.bar:SetWidth(16)
	frame.scroll.bar:SetScript("OnValueChanged", function(self, offset)
		self:GetParent():SetVerticalScroll(offset)
	end)
	frame.scroll.bar:SetPoint("TOPLEFT", frame.scroll, "TOPRIGHT", 6, -16)
	frame.scroll.bar:SetPoint("BOTTOMLEFT", frame.scroll, "BOTTOMRIGHT", 6, -16)

	-- Up/Down buttons
	frame.scroll.up = CreateFrame("Button", nil, frame.scroll.bar, "UIPanelScrollUpButtonTemplate")
	frame.scroll.up:ClearAllPoints()
	frame.scroll.up:SetPoint( "BOTTOM", frame.scroll.bar, "TOP" )
	frame.scroll.up:SetScript("OnClick", function(self)
		local parent = self:GetParent()
		parent:SetValue(parent:GetValue() - (parent:GetHeight() / 2))
		PlaySound("UChatScrollButton")
	end)

	frame.scroll.down = CreateFrame("Button", nil, frame.scroll.bar, "UIPanelScrollDownButtonTemplate")
	frame.scroll.down:ClearAllPoints()
	frame.scroll.down:SetPoint( "TOP", frame.scroll.bar, "BOTTOM" )
	frame.scroll.down:SetScript("OnClick", function(self)
		local parent = self:GetParent()
		parent:SetValue(parent:GetValue() + (parent:GetHeight() / 2))
		PlaySound("UChatScrollButton")
	end)
	
	-- That square thingy that shows where the bar is
	frame.scroll.bar:SetThumbTexture("Interface\\Buttons\\UI-ScrollBar-Knob")
	local thumb = frame.scroll.bar:GetThumbTexture()

	thumb:SetHeight(16)
	thumb:SetWidth(16)
	thumb:SetTexCoord(0.25, 0.75, 0.25, 0.75)

	-- Border graphic
	local texture = frame.scroll:CreateTexture(nil, "BACKGROUND")
	texture:SetWidth(31)
	texture:SetHeight(256)
	texture:SetPoint("TOPLEFT", frame.scroll.up, "TOPLEFT", -7, 5)
	texture:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-ScrollBar")
	texture:SetTexCoord(0, 0.484375, 0, 1.0)

	local texture = frame.scroll:CreateTexture(nil, "BACKGROUND")
	texture:SetWidth(31)
	texture:SetHeight(106)
	texture:SetPoint("BOTTOMLEFT", frame.scroll.down, "BOTTOMLEFT", -7, -3)
	texture:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-ScrollBar")
	texture:SetTexCoord(0.515625, 1.0, 0, 0.4140625)
end

-- SEARCH INPUt
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
	frame.search = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
	frame.search:SetHeight(19)
	frame.search:SetWidth(150)
	frame.search:SetAutoFocus(false)
	frame.search:ClearAllPoints()
	frame.search:SetPoint("CENTER", frame, "BOTTOMLEFT", 100, 25)

	frame.search.searchText = true
	frame.search:SetText(L["SEARCH"])
	frame.search:SetTextColor(0.90, 0.90, 0.90, 0.80)
	frame.search:SetScript("OnTextChanged", onChange)
	frame.search:SetScript("OnEditFocusGained", focusGained)
	frame.search:SetScript("OnEditFocusLost", focusLost)
end

-- ADDON CONFIGURATION
local function showTooltip(self)
	if( self.tooltip ) then
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(self.tooltip, nil, nil, nil, nil, 1)
	end
end

local function hideTooltip()
	GameTooltip:Hide()
end

local function sortCategories(a, b)
	if( not b ) then
		return false
	end

	return ( a.name < b.name )
end

-- Adds the actual row, will attempt to reuse the current row if able to
local function addCategoryRow(type, name, tooltip, data, parent, addon)
	local frame = regFrames.addon
	for i=1, #(frame.categories) do
		-- Match type/name first
		if( frame.categories[i].type == type and frame.categories[i].name == name ) then
			-- Then make sure it's correct addons parent, if it's a category
			if( (parent and frame.categories[i].parent and frame.categories[i].parent == parent) or (not parent and not frame.categories[i].parent) ) then
				-- Now make sure it's the correct addon if it's a sub category
				if( (addon and frame.categories[i].addon and frame.categories[i].addon == addon) or (not addon and not frame.categories[i].addon) ) then
					frame.categories[i].tooltip = tooltip
					frame.categories[i].data = data
					return
				end
			end
		end
	end

	table.insert(frame.categories, {name = name, type = type, tooltip = tooltip, data = data, parent = parent, addon = addon} )
	frame.resortList = true
end

-- Remove a specific category and/or sub category listing
-- without needing to recreate the entire list
local function removeCategoryListing(addon, name)
	local frame = regFrames.addon
	for i=1, #(frame.categories) do
		-- Remove the category requested
		if( frame.categories[i].type == "category" and frame.categories[i].name == name and frame.categories[i].addon == addon ) then
			table.remove(frame.categories, i)

		-- Remove all of it's sub categories
		elseif( frame.categories[i].type == "subcat" and frame.categories[i].parent == name and frame.categories[i].addon == addon ) then
			table.remove(frame.categories, i)
		end
	end
end

local function removeSubCategoryListing(addon, parentCat, name)
	local categories = regFrames.addon.categories
	for i=1, #(categories) do
		local cat = categories[i]
		-- Remove the specific sub category
		if( cat and cat.type == "subcat" and cat.name == name and cat.parent == parentCat and cat.addon == addon ) then
			table.remove(categories, i)
			i = i - 1
		end
	end
end

-- We have a seperate function for adding addons
-- so we can update a single addon out of the entire list
-- if it's categories/sub categories get changed, or a new ones added
local function addCategoryListing(name, addon)
	local tooltip = "|cffffffff" .. (addon.title or name) .. "|r"
	local data

	if( addon.version ) then
		tooltip = tooltip .. "\n" .. string.format(L["VERSION"], addon.version)
	end

	if( addon.author ) then
		tooltip = tooltip .. "\n" .. string.format(L["AUTHOR"], addon.author)
	end

	-- One category, make clicking the addon open that category
	if( addon.totalCats == 1 and addon.totalSubs == 0 ) then
		for catName, cat in pairs(addon.categories) do
			data = cat
			data.parentCat = catName
			break
		end

	-- Multiple categories, or sub categories
	else
		for catName, cat in pairs(addon.categories) do
			cat.parentCat = catName
			addCategoryRow("category", catName, cat.totalSubs > 0 and string.format(L["TOTAL_SUBCATEGORIES"], cat.totalSubs), cat, name)

			for subCatName, subCat in pairs(cat.sub) do
				subCat.parentCat = catName
				addCategoryRow("subcat", subCatName, nil, subCat, catName, name)
			end
		end
	end

	if( not data ) then
		data = {}
	end

	data.orderID = string.lower(name)

	addCategoryRow("addon", name, (addon.version or addon.author) and tooltip, data)
end

-- Recreates the entire listing
local function createCategoryListing()
	regFrames.addon.categories = {}

	for name, addon in pairs(addons) do
		addCategoryListing(name, addon)
	end
end

-- Displays the actual button
local function displayCategoryRow(type, text, data, tooltip, highlighted)
	local frame = regFrames.addon
	
	-- We have to let this run completely
	-- so we know how many rows we have total
	frame.totalRows = frame.totalRows + 1
	if( frame.totalRows <= frame.offset or frame.rowID >= 15 ) then
		return
	end
	
	frame.rowID = frame.rowID + 1

	local button = frame.buttons[frame.rowID]
	local line = frame.lines[frame.rowID]

	if( highlighted ) then
		button:LockHighlight()
	else
		button:UnlockHighlight()
	end
	
	if( type == "addon" ) then
		button:SetText(text)
		button:GetFontString():SetPoint("LEFT", button, "LEFT", 4, 0)
		button:GetNormalTexture():SetAlpha(1.0)
		line:Hide()

	elseif( type == "category" ) then
		button:SetText(HIGHLIGHT_FONT_COLOR_CODE..text..FONT_COLOR_CODE_CLOSE)
		button:GetFontString():SetPoint("LEFT", button, "LEFT", 12, 0)
		button:GetNormalTexture():SetAlpha(0.4)
		line:Hide()

	elseif( type == "subcat" ) then
		button:SetText(HIGHLIGHT_FONT_COLOR_CODE..text..FONT_COLOR_CODE_CLOSE)
		button:GetFontString():SetPoint("LEFT", button, "LEFT", 20, 0)
		button:GetNormalTexture():SetAlpha(0.0)
		line:SetTexCoord(0, 0.4375, 0, 0.625)
		line:Show()
	end

	button.tooltip = tooltip
	button.data = data
	button.type = type
	button.catText = text
	button:Show()
end

local function updateConfigList()
	local frame = regFrames.addon
	frame.offset = frame.scroll.offset
	frame.rowID = 0
	frame.totalRows = 0

	local lastID
	local searchBy = string.trim(string.lower(frame.search:GetText()))
	if( searchBy == "" or frame.search.searchText ) then
		searchBy = nil
	end

	-- Make sure stuff matches our search results
	for id, row in pairs(frame.categories) do
		if( searchBy and not string.match(string.lower(row.name), searchBy) ) then
			frame.categories[id].hide = true
		else
			frame.categories[id].hide = nil
		end
	end

	-- Resort list if needed
	if( frame.resortList ) then
		table.sort(frame.categories, sortCategories)
		frame.resortList = nil
	end

	-- Now display
	for _, addon in pairs(frame.categories) do
		if( not addon.hide and addon.type == "addon" ) then
			-- Total addons
			if( addon.name == frame.selectedAddon ) then
				displayCategoryRow(addon.type, addon.name, addon.data, addon.tooltip, true)

				for _, cat in pairs(frame.categories) do
					-- Show all the categories with the addon as the parent
					if( not cat.hide and cat.parent == addon.name and cat.type == "category" ) then
						-- Total categories of the selected addon
						if( cat.name == frame.selectedCategory ) then
							displayCategoryRow(cat.type, cat.name, cat.data, cat.tooltip, true)

							local rowID
							for _, subCat in pairs(frame.categories) do
								-- We don't have to check type, because it's the only one that has .addon set
								if( not subCat.hide and subCat.parent == cat.name and subCat.addon == addon.name ) then
									-- Total sub categories of the selected addons selected category
									displayCategoryRow(subCat.type, subCat.name, subCat.data, subCat.tooltip, subCat.name == frame.selectedSubCat)
									lastID = frame.rowID
								end
							end

							-- Turns the line from straight down to a curve at the end
							if( lastID ) then
								frame.lines[lastID]:SetTexCoord(0.4375, 0.875, 0, 0.625)
							end
						else
							displayCategoryRow(cat.type, cat.name, cat.data, cat.tooltip)
						end
					end
				end
			else
				displayCategoryRow(addon.type, addon.name, addon.data, addon.tooltip)
			end
		end
	end
		
	updateScroll(frame.scroll, frame.totalRows)

	for i=1, 15 do
		if( frame.totalRows > 15 ) then
			frame.buttons[i]:SetWidth(140)
		else
			frame.buttons[i]:SetWidth(156)
		end

		-- We have less then 15 rows used
		-- and our index is equal or past our current
		if( frame.rowID < 15 and i > frame.rowID ) then
			frame.buttons[i]:Hide()
		end
	end
end

local function openConfigFrame(data)
	local frame = regFrames.addon

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

		if( type(data.func) == "string" ) then
			data.frame = data.handler[data.func](data.handler, data.parentCat or frame.selectedCategory, frame.selectedSubCat)
		elseif( type(data.handler) == "function" ) then
			data.frame = data.handler(data.parentCat or frame.selectedCategory, frame.selectedSubCat)
		end

		-- Mostly this is for authors, but it lets us clean up the logic a bit
		if( not data.frame ) then
			error(string.format(L["ERROR_NO_FRAME"], frame.selectedAddon, data.parentCat or frame.selectedCategory, frame.selectedSubCat), 3)
		end

		-- Validate location/width/height and force parent
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

		if( not data.noCache ) then
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
	local frame = regFrames.addon

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
	updateConfigList()
end


local function createAddonFrame(hide)
	local frame = regFrames.addon
	
	if( frame and hide ) then
		frame:Hide()
		return
	elseif( hide ) then
		return
	elseif( not frame ) then
		frame = CreateFrame("Frame", nil, regFrames.main)
		frame:SetFrameStrata("MEDIUM")
		frame:SetAllPoints(regFrames.main)
		
		regFrames.addon = frame

		frame.buttons = {}
		frame.lines = {}
		for i=1, 15 do
			local button = CreateFrame("Button", nil, frame)
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
			local line = button:CreateTexture(nil, "BACKGROUND")
			frame.lines[i] = line

			line:SetWidth(7)
			line:SetHeight(20)
			line:SetPoint("LEFT", 13, 0)
			line:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-FilterLines")
			line:SetTexCoord(0, 0.4375, 0, 0.625)

			if( i > 1 ) then
				button:SetPoint("TOPLEFT", frame.buttons[i - 1], "BOTTOMLEFT", 0, 0)
			else
				button:SetPoint("TOPLEFT", 23, -105)
			end
		end
		
		createScrollFrame(frame, 15, updateConfigList)
		frame.scroll:SetPoint("TOPRIGHT", frame, "TOPLEFT", 158, -105)
		
		createSearchInput(frame, updateConfigList)
		createCategoryListing()
	end

	-- Reset selection
	frame.selectedAddon = ""
	frame.selectedCategory = ""
	frame.selectedSubCat = ""

	-- Hide the open config frame
	if( frame.shownFrame ) then
		frame.shownFrame:Hide()
	end

	updateConfigList()
	ShowUIPanel(frame)
end

local function createOHFrame()
	if( regFrames.main ) then
		return
	end

	frame = CreateFrame("Frame", nil, UIParent)
	frame:CreateTitleRegion()
	frame:SetClampedToScreen(true)
	frame:SetMovable(false)
	frame:SetFrameStrata("MEDIUM")
	frame:SetWidth(832)
	frame:SetHeight(447)
	frame:SetPoint("TOPLEFT", 0, -104)
	frame.totalTabs = 0
	frame.tabs = {}
	
	regFrames.main = frame

	-- If we don't hide it ourself, the panel layout becomes messed up
	frame:Hide()

	frame:SetAttribute("UIPanelLayout-defined", true)
	frame:SetAttribute("UIPanelLayout-enabled", true)
--~ 	frame:SetAttribute("UIPanelLayout-area", "doublewide") -- This is broken in the Blizzy code ><  Slouken's been sent a fix
	frame:SetAttribute("UIPanelLayout-area", "left")
	frame:SetAttribute("UIPanelLayout-whileDead", true)
	table.insert(UISpecialFrames, name)

	local title = frame:GetTitleRegion()
	title:SetWidth(757)
	title:SetHeight(20)
	title:SetPoint("TOPLEFT", 75, -15)

	-- Embedded version wont include the icon cause authors are more whiny then users
	-- Also, we want to use different methods of frame dragging
	if( not IsAddOnLoaded("OptionHouse") ) then
		local texture = frame:CreateTexture(nil, "OVERLAY")
		texture:SetWidth(57)
		texture:SetHeight(57)
		texture:SetPoint("TOPLEFT", 9, -7)
		SetPortraitTexture(texture, "player")
	else
		local texture = frame:CreateTexture(nil, "OVERLAY")
		texture:SetWidth(128)
		texture:SetHeight(128)
		texture:SetPoint("TOPLEFT", 9, -2)
		texture:SetTexture("Interface\\AddOns\\OptionHouse\\GnomePortrait")
	end

	local title = frame:CreateFontString(nil, "OVERLAY")
	title:SetFontObject(GameFontNormal)
	title:SetPoint("TOP", 0, -18)
	title:SetText(L["OPTION_HOUSE"])

	frame.topLeft = frame:CreateTexture(nil, "ARTWORK")
	frame.topLeft:SetWidth(256)
	frame.topLeft:SetHeight(256)
	frame.topLeft:SetPoint("TOPLEFT", 0, 0)

	frame.top = frame:CreateTexture(nil, "ARTWORK")
	frame.top:SetWidth(320)
	frame.top:SetHeight(256)
	frame.top:SetPoint("TOPLEFT", 256, 0)

	frame.topRight = frame:CreateTexture(nil, "ARTWORK")
	frame.topRight:SetWidth(256)
	frame.topRight:SetHeight(256)
	frame.topRight:SetPoint("TOPLEFT", frame.top, "TOPRIGHT", 0, 0)

	frame.bottomLeft = frame:CreateTexture(nil, "ARTWORK")
	frame.bottomLeft:SetWidth(256)
	frame.bottomLeft:SetHeight(256)
	frame.bottomLeft:SetPoint("TOPLEFT", 0, -256)

	frame.bottom = frame:CreateTexture(nil, "ARTWORK")
	frame.bottom:SetWidth(320)
	frame.bottom:SetHeight(256)
	frame.bottom:SetPoint("TOPLEFT", 256, -256)

	frame.bottomRight = frame:CreateTexture(nil, "ARTWORK")
	frame.bottomRight:SetWidth(256)
	frame.bottomRight:SetHeight(256)
	frame.bottomRight:SetPoint("TOPLEFT", frame.bottom, "TOPRIGHT", 0, 0)
	
	-- Make sure the configuration tab is first
	local tabs = {{func = createAddonFrame, text = L["ADDON_OPTIONS"], type = "browse"}}
	createTab(L["ADDON_OPTIONS"], 1)

	for id, tab in pairs(tabfunctions) do
		table.insert(tabs, tab)
		createTab(tab.text, id + 1)
	end

	tabfunctions = tabs

	local button = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
	button:SetPoint("TOPRIGHT", 3, -8)
	button:SetScript("OnClick", function()
		HideUIPanel(frame)
	end)
end

-- PRIVATE API's
-- These are only to be used for the standalone OptionHouse modules
function OptionHouse:CreateSearchInput(frame, onChange)
	createSearchInput(frame, onChange)
end

function OptionHouse:UpdateScroll(scroll, totalRows)
	updateScroll(scroll, totalRows)
end

function OptionHouse:CreateScrollFrame(frame, displayNum, onScroll)
	createScrollFrame(frame, displayNum, onScroll)
end

function OptionHouse.RegisterTab(self, text, func, type)
	-- Simple, effective you can't register a tab unless we list it here
	-- I highly doubt will ever need to add another one
	if( text ~= L["TAB_MANAGEMENT"] and text ~= L["TAB_PERFORMANCE"] ) then return end

	table.insert(tabfunctions, {func = func, handler = self, text = text, type = type})

	-- Will create all of the tabs when the frame is created if needed
	if( not frame ) then
		return
	end

	createTab(text, #(tabfunctions))
end

function OptionHouse.UnregisterTab(self, text)
	for i=#(tabfunctions), 1, -1 do
		if( tabfunctions[i].text == text ) then
			table.remove(tabfunctions, i)
		end
	end

	for i=1, frame.totalTabs do
		if( tabfunctions[i] ) then
			createTab(tabfunctions[i].text, i)
		else
			frame.tabs[i]:Hide()
		end
	end
end

function OptionHouse.GetAddOnData(self, name)
	if( not addons[name] ) then
		return nil, nil, nil
	end

	return addons[name].title, addons[name].author, addons[name].version
end

function OptionHouse.RegisterFrame(self, type, frame)
	if( type ~= "addon" and type ~= "manage" and type ~= "perf" and type ~= "main" ) then return end
	regFrames[type] = frame
end

-- PUBLIC API's
function OptionHouse:GetFrame(type)
	if( type ~= "addon" and type ~= "manage" and type ~= "perf" and type ~= "main" ) then
		error(string.format(L["UNKNOWN_FRAMETYPE"], type), 3)
	end

	return regFrames[type]
end

function OptionHouse:Open(addonName, parentCat, childCat)
	argcheck(addonName, 1, "string", "nil")
	argcheck(parentCat, 2, "string", "nil")
	argcheck(childCat, 3, "string", "nil")

	createOHFrame()
	tabOnClick(1)

	if( not addonName ) then
		ShowUIPanel(frame)
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
	updateConfigList()
	ShowUIPanel(frame)
end

function OptionHouse:OpenTab(id)
	argcheck(id, 1, "number")
	assert(3, #(tabfunctions) > id, string.format(L["UNKNOWN_TAB"], id, #(tabfunctions)))

	createOHFrame()
	tabOnClick(id)
	ShowUIPanel(frame)
end

function OptionHouse:RegisterAddOn(name, title, author, version)
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

	if( OptionHouseOptionsFrame ) then
		addCategoryListing(name, addons[name])
		updateConfigList()
	end

	return addons[name].obj
end

function OptionHouse.RegisterCategory(addon, name, handler, func, noCache)
	argcheck(name, 2, "string")
	argcheck(handler, 3, "string", "function", "table")
	argcheck(func, 4, "string", "function", "nil")
	argcheck(noCache, 5, "boolean", "number", "nil")
	assert(3, handler or func, L["NO_FUNC_PASSED"])
	assert(3, addons[addon.name], string.format(L["MUST_CALL"], addon.name))
	assert(3, addons[addon.name].categories, string.format(L["CATEGORY_ALREADYREG"], name, addon.name))

	-- Category numbers are required so we know when to skip it because only one category/sub cat exists
	addons[addon.name].totalCats = addons[addon.name].totalCats + 1
	addons[addon.name].categories[name] = {func = func, handler = handler, noCache = noCache, sub = {}, orderID = addons[addon.name].totalCats, totalSubs = 0}

	if( OptionHouseOptionsFrame ) then
		addCategoryListing(addon.name, addons[addon.name])
		updateConfigList()
	end
end

function OptionHouse.RegisterSubCategory(addon, parentCat, name, handler, func, noCache)
	argcheck(parentCat, 2, "string")
	argcheck(name, 3, "string")
	argcheck(handler, 4, "string", "function", "table")
	argcheck(func, 5, "string", "function", "nil")
	argcheck(noCache, 6, "boolean", "number", "nil")
	assert(3, handler or func, L["NO_FUNC_PASSED"])
	assert(3, addons[addon.name], string.format(L["MUST_CALL"], addon.name))
	assert(3, addons[addon.name].categories[parentCat], string.format(L["NO_PARENTCAT"], parentCat, addon.name))
	assert(3, not addons[addon.name].categories[parentCat].sub[name], string.format(L["SUBCATEGORY_ALREADYREG"], name, parentCat, addon.name))

	addons[addon.name].totalSubs = addons[addon.name].totalSubs + 1
	addons[addon.name].categories[parentCat].totalSubs = addons[addon.name].categories[parentCat].totalSubs + 1
	addons[addon.name].categories[parentCat].sub[name] = {handler = handler, func = func, noCache = noCache, orderID = addons[addon.name].categories[parentCat].totalSubs}

	if( OptionHouseOptionsFrame ) then
		addCategoryListing(addon.name, addons[addon.name])
		updateConfigList()
	end
end

function OptionHouse.RemoveCategory(addon, name)
	argcheck(name, 2, "string")
	assert(3, addons[addon.name], string.format(L["MUST_CALL"], addon.name))
	assert(3, not addons[addon.name].categories[name], string.format(L["NO_CATEGORYEXISTS"], name, addon.name))

	addons[addon.name].totalCats = addons[addon.name].totalCats - 1
	addons[addon.name].categories[name] = nil

	if( OptionHouseOptionsFrame ) then
		removeCategoryListing(addon.name, name)
		updateConfigList()
	end
end

function OptionHouse.RemoveSubCategory(addon, parentCat, name)
	argcheck(parentCat, 2, "string")
	argcheck(name, 2, "string")
	assert(3, addons[addon.name], string.format(L["MUST_CALL"], addon.name))
	assert(3, addons[addon.name].categories[parentCat], string.format(L["NO_PARENTCAT"], name, addon.name))
	assert(3, addons[addon.name].categories[parentCat].sub[name], string.format(L["NO_SUBCATEXISTS"], name, parentCat, addon.name))

	addons[addon.name].totalSubs = addons[addon.name].totalSubs - 1
	addons[addon.name].categories[parentCat].totalSubs = addons[addon.name].categories[parentCat].totalSubs - 1
	addons[addon.name].categories[parentCat].sub[name] = nil

	if( OptionHouseOptionsFrame ) then
		removeSubCategoryListing(addon.name, parentCat, name)
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
				HideUIPanel(frame)
				DEFAULT_CHAT_FRAME:AddMessage(L["ENTERED_COMBAT"])
			end
		end)

		-- Make sure it hasn't been created already.
		-- don't have to upgrade the referance because it just uses the slash command
		-- which will upgrade below to use the current version anyway
		if( not GameMenuButtonOptionHouse ) then
			local menubutton = CreateFrame("Button", "GameMenuButtonOptionHouse", GameMenuFrame, "GameMenuButtonTemplate")
			menubutton:SetText(L["OPTION_HOUSE"])
			menubutton:SetScript("OnClick", function()
				PlaySound("igMainMenuOption")
				HideUIPanel(GameMenuFrame)
				SlashCmdList["OPTHOUSE"]()
			end)

			-- Position below "Interface Options"
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
end

OptionHouse = DongleStub:Register(OptionHouse, Activate)
