local GUI = {}
local L = BazaarLocals
local syncInfo = {}

if( IS_WRATH_BUILD == nil ) then
	IS_WRATH_BUILD = (select(4, GetBuildInfo()) >= 30000)
end

-- MAIN SYNCING INFO PANEL THING
local EDGEGAP, ROWHEIGHT, ROWGAP, GAP = 16, 20, 2, 4
local RefreshAddons = function() end

local function MakeButton(parent)
	local button = CreateFrame("Button", nil, parent)
	button:SetWidth(80)
	button:SetHeight(22)

	button:SetHighlightFontObject(GameFontHighlightSmall)
	button:SetDisabledFontObject(GameFontDisableSmall)

	if( IS_WRATH_BUILD ) then
		button:SetNormalFontObject(GameFontNormalSmall)
	else
		button:SetTextFontObject(GameFontNormalSmall)
	end

	button:SetNormalTexture("Interface\\Buttons\\UI-Panel-Button-Up")
	button:SetPushedTexture("Interface\\Buttons\\UI-Panel-Button-Down")
	button:SetHighlightTexture("Interface\\Buttons\\UI-Panel-Button-Highlight")
	button:SetDisabledTexture("Interface\\Buttons\\UI-Panel-Button-Disabled")
	button:GetNormalTexture():SetTexCoord(0, 0.625, 0, 0.6875)
	button:GetPushedTexture():SetTexCoord(0, 0.625, 0, 0.6875)
	button:GetHighlightTexture():SetTexCoord(0, 0.625, 0, 0.6875)
	button:GetDisabledTexture():SetTexCoord(0, 0.625, 0, 0.6875)
	button:GetHighlightTexture():SetBlendMode("ADD")

	return button
end


local parent = CreateFrame("Frame", nil, UIParent)
parent.name = "Bazaar"
parent:Hide()
parent:SetScript("OnShow", function(frame)
	-- Update display
	local rows = {}
	frame.rows = rows
	
	local offset = 0
	RefreshAddons = function()
		if( not parent:IsVisible() ) then
			return
		end

		for id, row in ipairs(rows) do
			if( ( id + offset ) <= #(Bazaar.registeredAddons) ) then
				local data = Bazaar.lookup[Bazaar.registeredAddons[id + offset]]
				
				-- How many users have this?
				local tooltip = "|cffffffff" .. L["Users who have data for this addon available."] .. "|r"
				local total = 0
				for sender, addons in pairs(Bazaar.availableAddons) do
					if( addons[data.name] ) then
						if( total == 0 ) then
							tooltip = tooltip .. "\n\n" .. sender
						elseif( total % 3 == 0 ) then
							tooltip = tooltip .. "\n" .. sender
						else
							tooltip = tooltip .. ", " .. sender
						end

						total = total + 1
					end
				end
				
				if( total > 1 ) then
					row.discovered:SetFormattedText(L["%s%d|r |cffffffffusers|r"], GREEN_FONT_COLOR_CODE, total)
				elseif( total == 1 ) then
					row.discovered:SetFormattedText(L["%s%d|r |cffffffffuser|r"], GREEN_FONT_COLOR_CODE, total)
				else	
					tooltip = "|cffffffff" .. L["Nobody is known to have data for this addon, you can still try by hitting the request button."] .. "|r"
					row.discovered:SetFormattedText("%s%s|r", GRAY_FONT_COLOR_CODE, L["No users"])
				end
				
				row.title:SetText(select(2, GetAddOnInfo(data.name)))
				row.discovered.tooltip = tooltip
				row.discovered.addon = data.name
				row.ping.addon = data.name
				row:Show()
			else
				row:Hide()
			end
		end
	end

	-- Show the quick ping page
	local function PopupDiscovered(self)
	
	end
	
	-- Show the "Who do you want to ping" static popup
	local function PopupPing(self)
		if( not StaticPopupDialogs["BAZAAR_INPUT"] ) then
			StaticPopupDialogs["BAZAAR_INPUT"] = {
				button1 = ACCEPT,
				button2 = CANCEL,
				hasEditBox = 1,
				maxLetters = 12,
				OnAccept = function(data)
					local editBox = getglobal(this:GetParent():GetName() .. "EditBox")
					GUI:SendPing(data, editBox:GetText())
				end,
				OnShow = function()
					getglobal(this:GetName() .. "EditBox"):SetFocus()
				end,
				OnHide = function()
					if ( ChatFrameEditBox:IsShown() ) then
						ChatFrameEditBox:SetFocus()
					end
					getglobal(this:GetName() .. "EditBox"):SetText("")
				end,
				EditBoxOnEnterPressed = function(data)
					local editBox = getglobal(this:GetParent():GetName() .. "EditBox")
					GUI:SendPing(data, editBox:GetText())
					this:GetParent():Hide()
				end,
				EditBoxOnEscapePressed = function()
					this:GetParent():Hide()
				end,
				timeout = 0,
				exclusive = 1,
				whileDead = 1,
				hideOnEscape = 1
			}
		end

		StaticPopupDialogs["BAZAAR_INPUT"].text = string.format(L["Enter the player name of who you want to get data for '%s' from."], self.addon)
		local dialog = StaticPopup_Show("BAZAAR_INPUT")
		if( dialog ) then
			dialog.data = self.addon
		end
	end

	local function OnEnter(self)
		if( self.tooltip ) then
			GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT")
			GameTooltip:SetText(self.tooltip, nil, nil, nil, nil, true)
		end
	end
	local function OnLeave()
		GameTooltip:Hide()
	end
	
	local title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 16, -16)
	title:SetText("Bazaar")
	
	local subtitle = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	subtitle:SetHeight(32)
	subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
	subtitle:SetPoint("RIGHT", frame, -32, 0)
	subtitle:SetNonSpaceWrap(true)
	subtitle:SetJustifyH("LEFT")
	subtitle:SetJustifyV("TOP")
	subtitle:SetText(L["Addon configuration syncing with other users who use this and have an addon that supports Bazaar."])

	local anchor
	for i=1, math.floor((305-22) / (ROWHEIGHT + ROWGAP)) do
		local row = CreateFrame("Button", nil, frame)
		if( not anchor ) then
			row:SetPoint("TOP", subtitle, "BOTTOM", 0, -16)
		else
			row:SetPoint("TOP", anchor, "BOTTOM", 0, -ROWGAP)
		end
		
		row:SetPoint("LEFT", EDGEGAP, 0)
		row:SetPoint("RIGHT", -EDGEGAP, 0)
		row:SetHeight(ROWHEIGHT)
		
		anchor = row
		rows[i] = row

		local title = row:CreateFontString(nil, "BACKGROUND", "GameFontNormal")
		title:SetPoint("LEFT")
		row.title = title

		-- Ping a specific user
		local ping = MakeButton(row)
		ping:SetWidth(70)
		ping:SetPoint("RIGHT")
		ping:SetText(L["Request"])
		ping:SetScript("OnClick", PopupPing)
		ping:SetScript("OnEnter", OnEnter)
		ping:SetScript("OnLeave", OnLeave)
		row.ping = ping

		-- How many users are using this addon
		local discovered = CreateFrame("Button", nil, row)
		discovered:SetWidth(80)
		discovered:SetHeight(22)
		discovered:SetDisabledFontObject(GameFontDisableSmall)
		if( IS_WRATH_BUILD ) then
			discovered:SetNormalFontObject(GameFontNormalSmall)
		else
			discovered:SetTextFontObject(GameFontNormalSmall)
		end
		discovered:SetPoint("RIGHT", ping, "LEFT", 0, 0)
		discovered:SetScript("OnClick", PopupDiscovered)
		discovered:SetScript("OnEnter", OnEnter)
		discovered:SetScript("OnLeave", OnLeave)
		discovered:SetText("*")
		discovered:GetFontString():SetPoint("LEFT", discovered)
		
		row.discovered = discovered
	end

	RefreshAddons()
	
	frame:EnableMouseWheel()
	frame:SetScript("OnMouseWheel", function(self, val)
		offset = math.max(math.min(offset - math.floor(val * #(rows) / 2), #(Bazaar.registeredAddons) - #(rows)), 0)
		RefreshAddons()
	end)
	
	-- Sort the addons table by alpha!
	local function sortAddons(a, b)
		return a < b
	end
	
	local requestLimit = 0
	frame:SetScript("OnShow", function()
		table.sort(Bazaar.registeredAddons, sortAddons)
		
		RefreshAddons()
		
		-- Cap guild requests at one every 5 minutes
		if( IsInGuild() and requestLimit <= GetTime() ) then
			requestLimit = GetTime() + 300
			Bazaar:SendPing(nil, "GUILD")
		end
	end)
	
	-- Add our button to ping ALL addon data from a certain person
	local editBox = CreateFrame("EditBox", nil, frame)
	editBox:SetAutoFocus(false)
	editBox:SetHeight(32)
	editBox:SetWidth(110)
	editBox:SetFontObject("GameFontHighlightSmall")
	editBox:SetScript("OnEditFocusLost", function(self) self:HighlightText(0, 0) end)
	editBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	editBox:SetScript("OnEnterPressed", function(self) parent.ping:GetScript("OnClick")(parent.ping) end)
	editBox:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
	editBox:SetPoint("BOTTOMLEFT", 16, 16)

	local left = editBox:CreateTexture(nil, "BACKGROUND")
	left:SetWidth(8)
	left:SetHeight(20)
	left:SetPoint("LEFT", -5, 0)
	left:SetTexture("Interface\\Common\\Common-Input-Border")
	left:SetTexCoord(0, 0.0625, 0, 0.625)

	local right = editBox:CreateTexture(nil, "BACKGROUND")
	right:SetWidth(8)
	right:SetHeight(20)
	right:SetPoint("RIGHT", 0, 0)
	right:SetTexture("Interface\\Common\\Common-Input-Border")
	right:SetTexCoord(0.9375, 1, 0, 0.625)

	local center = editBox:CreateTexture(nil, "BACKGROUND")
	center:SetHeight(20)
	center:SetPoint("RIGHT", right, "LEFT", 0, 0)
	center:SetPoint("LEFT", left, "RIGHT", 0, 0)
	center:SetTexture("Interface\\Common\\Common-Input-Border")
	center:SetTexCoord(0.0625, 0.9375, 0, 0.625)
	
	local ping = MakeButton(frame)
	ping:SetPoint("BOTTOMRIGHT", editBox, 90, 4)
	ping:SetText(L["Ping"])
	ping:SetScript("OnClick", function()
		Bazaar:SendPing(nil, "WHISPER", string.trim(editBox:GetText() or ""))
		editBox:SetText("")
	end)
	
	parent.ping = ping

	if( IsInGuild() and requestLimit <= GetTime() ) then
		requestLimit = GetTime() + 300
		Bazaar:SendPing(nil, "GUILD")
	end
end)

InterfaceOptions_AddCategory(parent)

-- CONFIGURATION
--[[
local frame = CreateFrame("Frame", nil, UIParent)
frame.name = "Options"
frame.parent = parent
frame.addonname = "Bazaar"
frame:Hide()
frame:SetScript("OnShow", function(frame)

end)

InterfaceOptions_AddCategory(frame)
]]

-- SYNC CATEGORIES
local categories = CreateFrame("Frame", nil, UIParent)
categories.name = "Categories"
categories.parent = parent
categories.addonname = "Bazaar"
categories.hidden = true
categories:Hide()
categories:SetScript("OnShow", function(frame)
	local rows = {}
	local categories = {}
	
	local function OnClick(self)
		if( self.category ) then
			categories[self.category] = self:GetChecked() and true or nil

			-- Don't allow them to send a request without any categories selected
			frame.request:Disable()

			for _, flag in pairs(categories) do
				if( flag ) then
					frame.request:Enable()
					return
				end
			end
		end
	end
	
	local function sortCategories(a, b)
		return a < b
	end
	
	-- CLEAN UP LATER
	local categoryList = {}
	local function Load()
		for i=#(categoryList), 1, -1 do table.remove(categoryList) end
		for k in pairs(categories) do categories[k] = nil end
		
		local cats = Bazaar.lookup[syncInfo.addon].categories
		for key, name in pairs(cats) do
			-- Don't show the category if they don't have it available
			-- I'm going to change this eventually so it shows the category but it's grayed out
			-- and they get a message saying it's not available blah blah
			if( Bazaar.availableAddons[syncInfo.from][syncInfo.addon][key] ) then
				table.insert(categoryList, key)
				categories[key] = false
			end
		end
		
		table.sort(categoryList, sortCategories)
		
		frame.subtitle:SetFormattedText(L["Choose the categories of configuration to sync from %s for '%s'."], syncInfo.from, syncInfo.addon)
	end
	
	local offset = 0
	local function Refresh()
		if( not frame:IsVisible() ) then
			return
		end

		for id, row in ipairs(rows) do
			if( ( id + offset ) <= #(categoryList) ) then
				local key = categoryList[id + offset]
				local name = Bazaar.lookup[syncInfo.addon].categories[key]
				
				row.title:SetText(name)
				row.check.category = key
				row.check:SetChecked(categories[key])
				row:Show()
			else
				row:Hide()
			end
		end
	end
	
	local title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 16, -16)
	title:SetText("Bazaar")
	
	local subtitle = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	subtitle:SetHeight(32)
	subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
	subtitle:SetPoint("RIGHT", frame, -32, 0)
	subtitle:SetNonSpaceWrap(true)
	subtitle:SetJustifyH("LEFT")
	subtitle:SetJustifyV("TOP")
	subtitle:SetText(L["Choose the categories of configuration to sync from %s for '%s'."])
	
	frame.subtitle = subtitle
	
	for i=1,math.floor((305-22)/(ROWHEIGHT + ROWGAP)) do
		local row = CreateFrame("Button", nil, frame)
		if( not anchor ) then
			row:SetPoint("TOP", subtitle, "BOTTOM", 0, -16)
		else
			row:SetPoint("TOP", anchor, "BOTTOM", 0, -ROWGAP)
		end
		
		row:SetPoint("LEFT", EDGEGAP, 0)
		row:SetPoint("RIGHT", -EDGEGAP, 0)
		row:SetHeight(ROWHEIGHT)
		
		anchor = row
		rows[i] = row

		local check = CreateFrame("CheckButton", nil, row)
		check:SetWidth(ROWHEIGHT + 4)
		check:SetHeight(ROWHEIGHT + 4)
		check:SetPoint("LEFT")
		check:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up")
		check:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down")
		check:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight")
		check:SetDisabledCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check-Disabled")
		check:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")
		check:SetScript("OnClick", OnClick)
		row.check = check

		local title = row:CreateFontString(nil, "BACKGROUND", "GameFontNormal")
		title:SetPoint("LEFT", check, "RIGHT", 4, 0)
		row.title = title
	end

	frame:EnableMouseWheel()
	frame:SetScript("OnMouseWheel", function(self, val)
		offset = math.max(math.min(offset - math.floor(val * #(rows) / 2), #(Bazaar.registeredAddons) - #(rows)), 0)
		Refresh()
	end)
	
	-- Check/uncheck all of the categories
	local checkAll = MakeButton(frame)
	checkAll:SetPoint("BOTTOMLEFT", 16, 16)
	checkAll:SetText(L["Select All"])
	checkAll:SetScript("OnClick", function()
		for _, row in pairs(rows) do
			if( row.check.category ) then
				categories[row.check.category] = true
			end
			
			row.check:SetChecked(true)
			frame.request:Enable()
		end
	end)
	
	local uncheckAll = MakeButton(frame)
	uncheckAll:SetPoint("LEFT", checkAll, "RIGHT", 4, 0)
	uncheckAll:SetText(L["Unselect All"])
	uncheckAll:SetScript("OnClick", function()
		for _, row in pairs(rows) do
			if( row.check.category ) then
				categories[row.check.category] = false
			end
			
			frame.request:Disable()
			row.check:SetChecked(false)
		end
	end)

	-- Compile everything and send our request
	local request = MakeButton(frame)
	request:SetWidth(140)
	request:SetPoint("BOTTOMRIGHT", -16, 16)
	request:SetText(L["Request Configuration"])
	request:Disable()
	request:SetScript("OnClick", function()
		GUI:SendRequest(categories)
	end)
	
	frame.request = request
	
	frame:SetScript("OnShow", function(frame)
		Load()
		Refresh()
		
		frame.subtitle:SetFormattedText(L["Choose the categories of configuration to sync from %s for '%s'."], syncInfo.from, syncInfo.addon)
	end)
	
	Load()
	Refresh()
end)

InterfaceOptions_AddCategory(categories)

-- SYNC PROGRESS
local progress = CreateFrame("Frame", nil, UIParent)
progress.name = "Progress"
progress.parent = parent
progress.addonname = "Bazaar"
progress.hidden = true
progress:Hide()
progress:SetScript("OnShow", function(frame)
	local title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 16, -16)
	title:SetText("Bazaar")
	
	local subtitle = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	subtitle:SetHeight(32)
	subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
	subtitle:SetPoint("RIGHT", frame, -32, 0)
	subtitle:SetNonSpaceWrap(true)
	subtitle:SetJustifyH("LEFT")
	subtitle:SetJustifyV("TOP")
	subtitle:SetText(L["Closing this frame will not mess up any syncing or requests going on, you just won't get any updates on the progress until you open it again."])
	
	-- Progress bar!
	local bar = CreateFrame("StatusBar", nil, frame)
	bar:SetMinMaxValues(0, 1)
	bar:SetValue(0)
	bar:SetStatusBarTexture("Interface\\Addons\\Bazaar\\texture")
	bar:SetStatusBarColor(0.20, 0.90, 0.20, 1)
	bar:SetPoint("BOTTOMLEFT", frame, 4, 50)
	bar:SetPoint("BOTTOMRIGHT", frame, -4, 50)
	bar:SetHeight(30)
	bar:SetWidth(30)
	
	bar.bg = CreateFrame("StatusBar", nil, bar)
	bar.bg:SetMinMaxValues(0, 1)
	bar.bg:SetValue(1)
	bar.bg:SetAllPoints(bar)
	bar.bg:SetFrameLevel(0)
	bar.bg:SetStatusBarTexture("Interface\\Addons\\Bazaar\\texture")
	bar.bg:SetStatusBarColor(0.20, 0.90, 0.20, 0.20)
	
	frame.bar = bar
	
	-- Status text!
	local status = bar:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	status:SetHeight(32)
	status:SetPoint("BOTTOMLEFT", frame, 4, 90)
	status:SetPoint("BOTTOMRIGHT", frame, -4, 90)
	status:SetNonSpaceWrap(false)
	status:SetJustifyH("LEFT")
	status:SetJustifyV("TOP")
	
	frame.status = status
	
	-- Percent text
	local percent = bar:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	percent:SetHeight(32)
	percent:SetPoint("CENTER", bar, "CENTER")
	percent:SetText("0%")
	
	frame.percent = percent

	-- Enable it once we're finished
	local done = MakeButton(frame)
	done:SetWidth(140)
	done:SetPoint("BOTTOMRIGHT", -16, 16)
	done:SetText(L["Finished"])
	done:Disable()
	done:SetScript("OnClick", function()
		progress.hidden = true
		InterfaceAddOnsList_Update()
		InterfaceOptionsFrame_OpenToFrame(parent)
	end)
	
	progress.done = done
	
	-- If we're viewing this page and we don't have an active sync, something is wrong
	progress:SetScript("OnShow", function()
		progress.done:Disable()
		
		if( not syncInfo.addon and not syncInfo.from ) then
			progress.hidden = true
			InterfaceAddOnsList_Update()
			InterfaceOptionsFrame_OpenToFrame(parent)
		end
	end)
	
	-- Done syncing, so hide it from the list
	progress:SetScript("OnHide", function()
		if( not syncInfo.addon and not syncInfo.from ) then
			progress.hidden = true
			InterfaceAddOnsList_Update()
		end
	end)
end)

InterfaceOptions_AddCategory(progress)

-- Open the configuration panel
SLASH_BAZAAR1 = "/bazaar"
SlashCmdList["BAZAAR"] = function()
	InterfaceOptionsFrame_OpenToFrame(parent)
end

-- INNERARDS!

-- Error, like the request was denied
function GUI:TriggerError(msg)
	self:UnlockPings()
	self:UpdateStatus("error", msg)
	
	syncInfo.addon = nil
	syncInfo.from = nil
end

-- Show categories panel
function GUI:ShowCategories()
	-- Open the categories panel
	progress.hidden = true
	categories.hidden = nil
	
	InterfaceAddOnsList_Update()
	InterfaceOptionsFrame_OpenToFrame(categories)
end

-- Show progress panel
function GUI:ShowProgress()
	-- Open the progress panel
	progress.hidden = nil
	categories.hidden = true
	
	InterfaceAddOnsList_Update()
	InterfaceOptionsFrame_OpenToFrame(progress)
end

-- Update progress bar
function GUI:UpdateProgress(received, total)
	if( progress.bar ) then
		local percent = received / total
		progress.percent:SetFormattedText("%.2f%%", percent * 100)
		progress.percent:Show()
		
		progress.bar:SetValue(percent)
		progress.bar:Show()
	end
end

-- Update the status
function GUI:UpdateStatus(code, text)
	-- Check if we got our data
	if( code == "pong" and syncInfo.pending ) then
		if( Bazaar.availableAddons[syncInfo.from] and Bazaar.availableAddons[syncInfo.from][syncInfo.addon] ) then
			syncInfo.pending = nil
			self:ShowCategories()
		end
	elseif( code == "sent" or code == "error" ) then
		self:ShowProgress()
		
		progress.bar:SetValue(0)
		progress.percent:Hide()
		
		if( code == "error" ) then
			progress.done:Enable()
		end
	elseif( code == "requested" ) then
		self:ShowProgress()
		self:UpdateProgress(0, 1)
	end
	
	-- Update progress text
	if( progress.status ) then
		progress.status:SetText(text)
	end
	
	-- Refresh the main page for new addon data
	if( parent:IsVisible() ) then
		RefreshAddons()
	end
end

-- Send a ping for data
function GUI:SendPing(addon, name)
	name = string.trim(name)
	if( name == "" ) then
		return
	end
	
	syncInfo.addon = addon
	syncInfo.from = name
	syncInfo.pending = nil

	-- Lock all pings so the user can't fuck with anything
	self:LockPings()

	-- If we already have data available, skip the ping and go directly to the next part
	if( Bazaar.availableAddons[name] and Bazaar.availableAddons[name][addon] ) then
		self:ShowCategories()
	else
		syncInfo.pending = true
		Bazaar:SendPing(addon, "WHISPER", name, true)
		self:UpdateStatus("sent", string.format(L["Sent ping request to %s."], name))
	end
end

-- Send the sync request
function GUI:SendRequest(categories)
	Bazaar:SendRequest(syncInfo.addon, syncInfo.from, categories)
	self:UpdateStatus("requested", string.format(L["Sent addon configuration sync request to %s."], syncInfo.from))
end

-- Prevent pings from happening during syncs
function GUI:LockPings()
	if( parent and parent.rows ) then
		parent.ping:Disable()
		
		for _, row in pairs(parent.rows) do
			row.ping:Disable()
		end
	end
end

function GUI:UnlockPings()
	if( parent and parent.rows ) then
		parent.ping:Enable()
		
		for _, row in pairs(parent.rows) do
			row.ping:Enable()
		end
	end
end

-- All done
function GUI:Finished()
	syncInfo.addon = nil
	syncInfo.from = nil
	
	self:UnlockPings()
	progress.done:Enable()
end

if( Bazaar ) then
	Bazaar.GUI = GUI
end
