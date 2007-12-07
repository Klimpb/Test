SSOverlay = SSPVP:NewModule( "SSPVP-Overlay" )

local CREATED_ROWS = 0
local ADDED_CATEGORIES = 0
local MAX_ROWS = 20

local rows = {}
local priorities = {catText = 1, text = 2, timer = 3, elapsed = 4, item = 5}
local categories = {}

function SSOverlay:Enable()
	self:RegisterEvent( "BAG_UPDATE" )
end

function SSOverlay:Reload()
	if( not self.frame ) then
		return
	end
	
	-- Position type may have changed, resave
	SSOverlay:SavePosition()
	
	-- Enable mouse for moving if need be
	for i=1, CREATED_ROWS do
		self.overlayRows[i]:EnableMouse(SSPVP.db.profile.overlay.locked)
	end
	
	-- Scale!
	self.frame:SetScale(SSPVP.db.profile.overlay.scale)
	self:RemoveRow("catText")
	self:UpdateColors()	
	self:UpdateCategoryText()
	self:UpdateOverlayText()
end

function SSOverlay:GetFactionColor(faction)
	if( faction == "Alliance" ) then
		return ChatTypeInfo["BG_SYSTEM_ALLIANCE"]
	elseif( faction == "Horde" ) then
		return ChatTypeInfo["BG_SYSTEM_HORDE"]
	end
	
	return ChatTypeInfo["BG_SYSTEM_NEUTRAL"]
end

-- Store current position
function SSOverlay:SavePosition()
	if( SSPVP.db.profile.overlay.displayType == "down" ) then
		SSPVP.db.profile.positions.overlay.x, SSPVP.db.profile.positions.overlay.y = self.frame:GetLeft(), self.frame:GetTop()
	else
		SSPVP.db.profile.positions.overlay.x, SSPVP.db.profile.positions.overlay.y = self.frame:GetLeft(), self.frame:GetBottom()
	end
end

-- Update the overlay
local elapsed = 0
local function onUpdate()
	elapsed = elapsed + arg1
	
	if( elapsed > 0.20 ) then
		elapsed = 0
		
		local time = GetTime()
		
		for i=#(rows), 1, -1 do
			local row = rows[i]
			if( row and row.type == "timer" ) then
				row.seconds = row.startSeconds - (time - row.startTime)
				
				-- Row removed, resort/update category text
				if( floor(row.seconds) <= 0 ) then
					table.remove(rows, i)
					
					SSOverlay:UpdateCategoryText()
					--SSOverlay:SortRows()
					
					SSOverlay.frame.highestWidth = 0
					SSOverlay:UpdateOverlayText()
				else
					SSOverlay:UpdateOverlayText(i)
				end
			
			elseif( row and row.type == "elapsed" ) then
				row.seconds = row.startSeconds + (time - row.startTime)
				SSOverlay:UpdateOverlayText(i)
			end
		end
	end
end

-- Create the base overlay frame
function SSOverlay:CreateOverlay()
	if( self.frame ) then
		return
	end
		
	-- Setup the overlay frame
	self.frame = CreateFrame("Frame", nil, UIParent)
	
	self.frame.highestWidth = 0
	self.frame:SetScale(SSPVP.db.profile.overlay.scale)
	self.frame:SetClampedToScreen(true)
	self.frame:RegisterForDrag("LeftButton")
	
	self.frame:SetFrameStrata("BACKGROUND")
	self.frame:SetMovable(true)
	self.frame:EnableMouse(true)
	
	self.frame:SetScript("OnUpdate", onUpdate)
	self.frame:SetScript("OnMouseUp", function(self)
		if( not SSPVP.db.profile.overlay.locked ) then
			self:StopMovingOrSizing()
			SSOverlay:SavePosition()
		end
	end)
	self.frame:SetScript("OnMouseDown", function(self)
		if( not SSPVP.db.profile.overlay.locked ) then
			self:StartMoving()
		end
	end)
	
	self.frame:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
				edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
				tile = true,
				tileSize = 9,
				edgeSize = 9,
				insets = { left = 2, right = 2, top = 2, bottom = 2 }})	
	
	self.frame:SetBackdropColor(SSPVP.db.profile.overlay.background.r, SSPVP.db.profile.overlay.background.g, SSPVP.db.profile.overlay.background.b, SSPVP.db.profile.overlay.opacity)
	self.frame:SetBackdropBorderColor(SSPVP.db.profile.overlay.border.r, SSPVP.db.profile.overlay.border.g, SSPVP.db.profile.overlay.border.b, SSPVP.db.profile.overlay.opacity)
	
	if( SSPVP.db.profile.overlay.displayType == "down" ) then
		self.frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", SSPVP.db.profile.positions.overlay.x, SSPVP.db.profile.positions.overlay.y)
	elseif( SSPVP.db.profile.overlay.displayType == "up" ) then
		self.frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", SSPVP.db.profile.positions.overlay.x, SSPVP.db.profile.positions.overlay.y)
	end
end

-- Update colors used
function SSOverlay:UpdateColors()
	self.frame:SetBackdropColor(SSPVP.db.profile.overlay.background.r, SSPVP.db.profile.overlay.background.g, SSPVP.db.profile.overlay.background.b, SSPVP.db.profile.overlay.opacity)
	self.frame:SetBackdropBorderColor(SSPVP.db.profile.overlay.border.r, SSPVP.db.profile.overlay.border.g, SSPVP.db.profile.overlay.border.b, SSPVP.db.profile.overlay.opacity)
	
	self:UpdateOverlayText()
end

-- Check if we need to run an onclick event
local function rowOnClick(self)
	local row = rows[self.rowID]
	
	if( row ) then
		if( type(row.handler) == "table" and type(row.OnClick) == "string" ) then
			row.handler[row.OnClick](row.handler, unpack(row.args))
		
		elseif( type( row.OnClick ) == "string" ) then
			getglobal(row.OnClick)(unpack(row.args))

		elseif( type( row.OnClick ) == "function" ) then
			row.OnClick(unpack(row.args))
		end
	end
end

-- Creates a new row for the overlay
function SSOverlay:CreateRow()
	if( CREATED_ROWS >= MAX_ROWS ) then
		return
	end

	CREATED_ROWS = CREATED_ROWS + 1

	local row = CreateFrame("Frame", nil, self.frame)
	local text = row:CreateFontString(nil, "BACKGROUND")
	
	row:EnableMouse(SSPVP.db.profile.overlay.locked)

	row:SetHeight(13)
	row:SetWidth(250)
	
	row:SetScript("OnMouseUp", rowOnClick)
	row:SetFrameStrata("LOW")
	
	text:SetJustifyH("left")
	text:SetFont(GameFontNormalSmall:GetFont())
	text:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
	
	-- Bottom -> Top
	if( SSPVP.db.profile.overlay.displayType == "down" ) then
		if( CREATED_ROWS > 1 ) then
			row:SetPoint("TOPLEFT", self.overlayRows[CREATED_ROWS - 1], "TOPLEFT", 0, -12)
		else
			row:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 5, -5)
		end
	
	-- Top -> Bottom
	elseif( SSPVP.db.profile.overlay.displayType == "up" ) then
		if( CREATED_ROWS > 1 ) then
			row:SetPoint("TOPLEFT", self.overlayRows[CREATED_ROWS - 1], "TOPLEFT", 0, 12)
		else
			row:SetPoint("BOTTOMLEFT", self.frame, "BOTTOMLEFT", 5, 3)
		end
	end
	
	if( not self.overlayRows ) then
		self.overlayRows = {}
	end
	
	-- Store
	self.overlayRows[CREATED_ROWS] = row
	self.overlayRows[CREATED_ROWS].text = text
end

-- Standard time format
function SSOverlay:FormatTime(seconds, timeFormat)
	if( timeFormat == "hhmmss" ) then
		seconds = floor(seconds)
		local hours, minutes

		if( seconds >= 3600 ) then
			hours = string.format("%.2d", floor(seconds / 3600))
			seconds = mod(seconds, 3600)
		else
			hours = ""
		end

		if( seconds >= 60 ) then
			minutes = floor(seconds / 60)
			seconds = mod(seconds, 60)
		else
			minutes = 0
			
			if( seconds < 0 ) then
				seconds = 0
			end
		end

		return hours .. string.format("%.2d:%.2d", minutes, seconds)
	elseif( timeFormat == "minsec" or seconds < 60 ) then
		return string.trim(SecondsToTime(seconds))
	end
	
	return string.trim(SecondsToTime(seconds, true))
end

-- Update either all the overlay text, or a single row
function SSOverlay:UpdateOverlayText(updateid)
	-- No rows found, hide the overlay if it exists
	if( #( rows ) == 0 ) then
		if( self.frame ) then
			self.frame:Hide()
		end
		return
	end
	
	for i=1, CREATED_ROWS do
		local overlayRow = self.overlayRows[i]
		local overlayText = overlayRow.text
		
		local row = rows[i]

		if( row ) then
			if( ( updateid and i == updateid ) or not updateid ) then
				-- Category text, set text
				if( row.type == "text" or row.type == "catText" ) then
					overlayText:SetText(row.text)
				-- Item text, format in the item count
				elseif( row.type == "item" ) then
					overlayText:SetText(string.format(row.text, row.count))
				-- Timer or elapsed, format time and format in the result
				elseif( row.type == "timer" or row.type == "elapsed" ) then
					overlayText:SetText(string.format(row.text, self:FormatTime(row.seconds, SSPVP.db.profile.overlay.timer)))
				end
				
				-- Specific color
				if( row.color ) then
					overlayText:SetTextColor(row.color.r, row.color.g, row.color.b, SSPVP.db.profile.overlay.textOpacity)
				-- Category text, use special one
				elseif( row.type == "catText" ) then
					overlayText:SetTextColor(SSPVP.db.profile.overlay.categoryColor.r, SSPVP.db.profile.overlay.categoryColor.g, SSPVP.db.profile.overlay.categoryColor.b, SSPVP.db.profile.overlay.textOpacity)
				-- Use default
				else
					overlayText:SetTextColor(SSPVP.db.profile.overlay.textColor.r, SSPVP.db.profile.overlay.textColor.g, SSPVP.db.profile.overlay.textColor.b, SSPVP.db.profile.overlay.textOpacity)
				end
				
				if( self.frame.highestWidth < overlayText:GetWidth() ) then
					SSOverlay.frame.highestWidth = overlayText:GetWidth() + 20
				end
				
				overlayText.category = row.category
				overlayRow.rowID = i
				overlayRow:Show()
			end
		else
			overlayText.category = nil
			overlayRow:Hide()
		end
	end
	
	-- Doing a full update, so reposition/set height again
	-- Usually, this means a new row or one was removed
	if( not updateid ) then
		local pad = 9
		local fact = -1

		if( SSPVP.db.profile.overlay.displayType == "up" ) then
			fact = 1
		end
		
		for i=1, CREATED_ROWS do
			local row = rows[i]

			rowParent = self.overlayRows[i]
			rowParent:SetWidth(self.frame.highestWidth + 2)
			
			if( i > 1 and row ) then
				if( row.type ~= "catText" ) then
					pad = pad + SSPVP.db.profile.overlay.rowPad
					rowParent:SetPoint("TOPLEFT", self.overlayRows[i - 1], "TOPLEFT", 0, fact * (12 - (-1 * SSPVP.db.profile.overlay.rowPad)))
				else
					pad = pad + SSPVP.db.profile.overlay.catPad
					rowParent:SetPoint("TOPLEFT", self.overlayRows[i - 1], "TOPLEFT", 0, fact * (12 - (-1 * SSPVP.db.profile.overlay.catPad)))
				end
			elseif( i == 1 ) then
				rowParent:ClearAllPoints()

				if( SSPVP.db.profile.overlay.displayType == "down" ) then
					rowParent:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 5, -5)
				elseif( SSPVP.db.profile.overlay.displayType == "up" ) then
					rowParent:SetPoint("BOTTOMLEFT", self.frame, "BOTTOMLEFT", 5, 3)				
				end
			end
		end
		
		if( #(rows) < CREATED_ROWS ) then
			self.frame:SetHeight((#(rows) * (self.overlayRows[1].text:GetHeight() + 2)) + pad)
		else
			self.frame:SetHeight((CREATED_ROWS * (self.overlayRows[1].text:GetHeight() + 2)) + pad)
		end
	end
	
	self.frame:SetWidth(self.frame.highestWidth + 5)
	self.frame:Show()
end

-- Update item counts
function SSOverlay:BAG_UPDATE()
	for i, row in pairs(rows) do
		if( row.type == "item" ) then
			local count = GetItemCount(row.itemid)
			if( count ~= row.count ) then
				row.count = count
				self:UpdateText(i)
			end
		end
	end
end

-- Add a new category
function SSOverlay:AddCategory(name, text, order, handler, onClick)
	if( categories[name] ) then
		return
	end
	
	-- If we've already got a matching order we have to shift it
	-- so we don't get display/sort issues
	if( order ) then
		for catName, category in pairs(categories) do
			if( category.order and category.order == order ) then
				order = order + 1
			end
		end
	end
	
	ADDED_CATEGORIES = ADDED_CATEGORIES + 1
	order = order or ADDED_CATEGORIES
	
	categories[name] = {order = order * 100, text = text, handler = handler, OnClick = onClick}
end

-- Add a new on click handler to a specific row
function SSOverlay:AddOnClick(rowType, category, text, handler, onClick, ...)
	for id, row in pairs(rows) do
		if( not row.OnClick and row.type == rowType and row.category == category and (string.match(string.lower(row.addedText), string.lower(text)) or text == row.addedText) ) then
			if( type(handler) == "table" and type(onClick) == "string" ) then
				rows[id].handler = handler
			end
			
			rows[id].OnClick = onClick
			rows[id].args = { ... }
			
			break
		end
	end
end

-- Resort everything
function SSOverlay:SortRows()
	table.sort(rows, function( a, b )
		if( a.sortID ~= b.sortID ) then
			return ( a.sortID < b.sortID )
		end
		
		return ( a.addID < b.addID )
	end )
end

-- Figure out which category texts should be shown
local foundCats = {}
function SSOverlay:UpdateCategoryText()
	-- Show mode is set to always hide
	if( SSPVP.db.profile.overlay.catType == "hide" ) then
		return
	end
	
	local totalCats = 0
	-- Figure out how many rows we have using a cat
	if( SSPVP.db.profile.overlay.catType ~= "hide" ) then
		for _, row in pairs(rows) do
			if( not foundCats[row.category] and row.type ~= "catText" ) then
				totalCats = totalCats + 1
				foundCats[row.category] = true
			end
		end
	end
	
	-- Either we have multiple categories showing, or we're always showing them all.
	if( totalCats > 1 or SSPVP.db.profile.overlay.catType == "show" ) then
		for name, _ in pairs(foundCats) do
			SSOverlay:UpdateRow({type = "catText", category = name, text = categories[name].text})

			if( categories[name].handler or categories[name].OnClick ) then
				SSOverlay:AddOnClick("catText", name, categories[name].text, categories[name].handler, categories[name].OnClick)
			end
		end
	else
		SSOverlay:RemoveRow("catText")
	end
	
	-- Clear it out so we can reuse it next time
	for k, _ in pairs(foundCats) do
		foundCats[k] = nil
	end
end

-- "Generic" update row
function SSOverlay:UpdateRow(updatedRow, ...)
	if( not updatedRow.text or not updatedRow.type or not categories[updatedRow.category] ) then
		return
	end

	-- First time we're adding something to the overlay, so create it
	if( not self.frame ) then
		self:CreateOverlay()
	end
	
	local extras = { ... }
	local color
	
	-- If they're passing a table as the first one, then it has to be a color
	if( type(extras[1]) == "table" ) then
		color = {r = extras[1].r, g = extras[1].g, b = extras[1].b}
		table.remove(extras, 1)
	end
		
	updatedRow.addedText = updatedRow.text
	if( updatedRow.type == "text" or updatedRow.type == "catText" ) then
		updatedRow.text = string.format(updatedRow.text, unpack(extras))
	elseif( updatedRow.type == "elapsed" or updatedRow.type == "timer" ) then
		updatedRow.text = string.format(updatedRow.text, "%s", unpack(extras))
	end
	
	updatedRow.color = color
	updatedRow.sortID = categories[updatedRow.category].order + priorities[updatedRow.type]
	
	for id, row in pairs( rows ) do
		-- Does type/category/text match?
		if( row.type == updatedRow.type and row.category == updatedRow.category and ( string.lower(row.addedText) == string.lower(updatedRow.addedText) or string.match(updatedRow.addedText, row.addedText) ) ) then
			if( not updatedRow.color or ( updatedRow.color and row.color and updatedRow.color.r == row.color.r and updatedRow.color.g == row.color.g and updatedRow.color.b == row.color.b ) ) then
				rows[id] = updatedRow
				rows[id].addID = id

				SSOverlay:UpdateOverlayText(id)
				return
			end
		end
	end
	
	updatedRow.addID = #(rows) + 1
	table.insert(rows, updatedRow)
	
	if( #( rows ) > CREATED_ROWS ) then
		self:CreateRow()
	end
	
	if( updatedRow.type ~= "catText" ) then
		self:UpdateCategoryText()
	end
	
	self:SortRows()
	self:UpdateOverlayText()
end

--[[
This isn't working, not sure why but will look into it before using this now code
function SSOverlay:UpdateRow(updatedRow, color, ...)
	if( not updatedRow.text or not updatedRow.type or not categories[updatedRow.category] ) then
		return
	end

	-- First time we're adding something to the overlay, so create it
	if( not self.frame ) then
		self:CreateOverlay()
	end
	
	updatedRow.addedText = updatedRow.text
	
	-- If color is a table....then it's actually a color so not format it in
	if( type(color) == "table" ) then
		-- Text/categories can't have any other formats besides
		-- the extra ones
		if( updatedRow.type == "text" or updatedRow.type == "catText" ) then
			updatedRow.text = string.format(updatedRow.text, ...)
		
		-- Elapsed/timers however, have to have a %s for the timer
		elseif( updatedRow.type == "elapsed" or updatedRow.type == "timer" ) then
			updatedRow.text = string.format(updatedRow.text, "%s", ...)
		end
	else
		if( updatedRow.type == "text" or updatedRow.type == "catText" ) then
			updatedRow.text = string.format(updatedRow.text, color, ...)
		elseif( updatedRow.type == "elapsed" or updatedRow.type == "timer" ) then
			updatedRow.text = string.format(updatedRow.text, "%s", color, ...)
		end
	end
	
	updatedRow.color = color
	updatedRow.sortID = categories[updatedRow.category].order + priorities[updatedRow.type]
	
	-- Make sure we're not updating a row that already exists
	for id, row in pairs(rows) do
		-- Does type/category/text match?
		if( row.type == updatedRow.type and row.category == updatedRow.category and string.lower(row.addedText) == string.lower(updatedRow.addedText) ) then
			if( not updatedRow.color or ( updatedRow.color and row.color and updatedRow.color.r == row.color.r and updatedRow.color.g == row.color.g and updatedRow.color.b == row.color.b ) ) then
				row = updatedRow
				row.addID = id
				
				SSOverlay:UpdateOverlayText(id)
				return
			end
		end
	end
	
	updatedRow.addID = #(rows) + 1
	table.insert(rows, updatedRow)
	
	if( #(rows) > CREATED_ROWS ) then
		self:CreateRow()
	end
	
	if( updatedRow.type ~= "catText" ) then
		self:UpdateCategoryText()
	end
	
	self:SortRows()
	self:UpdateOverlayText()
end]]

-- Update text row
function SSOverlay:UpdateText(category, text, ...)
	SSOverlay:UpdateRow({type = "text", category = category, text = text, type = "text"} , ...)
end

-- Update elapsed row
function SSOverlay:UpdateElapsed(category, text, start, ...)
	SSOverlay:UpdateRow({type = "elapsed", category = category, text = text, seconds = start or 0, startSeconds = start or 0, startTime = GetTime()} , ...)
end

-- Update timer row
function SSOverlay:UpdateTimer(category, text, start, ...)
	SSOverlay:UpdateRow({type = "timer", category = category, text = text, seconds = start, startSeconds = start, startTime = GetTime()} , ...)
end

-- Update item count row
function SSOverlay:UpdateItem(category, text, item, ...)
	SSOverlay:UpdateRow({type = "item", category = category, text = text, itemid = item, count = GetItemCount(item)}, ...)
end

-- Remove all rows in a specific category
function SSOverlay:RemoveCategory(category)
	for i=#(rows), 1, -1 do
		if( rows[i].category == category ) then
			self.frame.highestWidth = 0
			table.remove(rows, i)
		end
	end
	
	if( self.frame and self.frame.highestWidth == 0 ) then
		self:UpdateCategoryText()
		self:SortRows()
		self:UpdateOverlayText()
	end
end

-- Remove a specific row
function SSOverlay:RemoveRow(type, category, text, color)
	for i=#(rows), 1, -1 do
		local row = rows[i]
		
		-- Check type
		if( ( type and row.type == type ) or not type ) then
			-- Check category
			if( ( category and row.category == category ) or not category ) then
				-- Check text
				if( ( text and (string.match(string.lower(text), string.lower(row.addedText)) or text == row.addedText) ) or not text ) then
					self.frame.highestWidth = 0
					table.remove(rows, i)
				end
			end
		end
	end
	
	if( type ~= "catText" ) then
		self:UpdateCategoryText()
	end
	self:SortRows()
	self:UpdateOverlayText()
end

-- Clear the overlay
function SSOverlay:RemoveAll()
	for i=#(rows), 1, -1 do
		table.remove(rows, i)
	end
	
	for i=1, CREATED_ROWS do
		self.overlayRows[i]:Hide()
	end

	self.frame.highestWidth = 0
	self.frame:Hide()
end
