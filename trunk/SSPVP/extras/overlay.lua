SSOverlay = SSPVP:NewModule( "SSPVP-Overlay" );

local CREATED_ROWS = 0;
local ADDED_CATEGORIES = 0;
local MAX_ROWS = 20;

local rows = {};
local priorities = { catText = 1, text = 2, timer = 3, elapsed = 4, item = 5 };
local categories = {};

function SSOverlay:Enable()
	self:RegisterEvent( "BAG_UPDATE" );
end

function SSOverlay:Reload()
	if( not self.frame ) then
		return;
	end

	if( SSPVP.db.profile.overlay.displayType == "down" ) then
		SSPVP.db.profile.positions.overlay.x, SSPVP.db.profile.positions.overlay.y = self.frame:GetLeft(), self.frame:GetTop();

	elseif( SSPVP.db.profile.overlay.displayType == "up" ) then
		SSPVP.db.profile.positions.overlay.x, SSPVP.db.profile.positions.overlay.y = self.frame:GetLeft(), self.frame:GetBottom();
	end
	
	for i=1, CREATED_ROWS do
		getglobal( self.frame:GetName() .. "Row" .. i ):EnableMouse( SSPVP.db.profile.overlay.locked );
	end
	
	SSOverlay:RemoveRow( "catText" );
	SSOverlay:UpdateColors();	
	SSOverlay:UpdateCategoryText();
	SSOverlay:UpdateOverlayText();
end

function SSOverlay:GetFactionColor( faction )
	if( faction == "Alliance" ) then
		return ChatTypeInfo["BG_SYSTEM_ALLIANCE"];
	elseif( faction == "Horde" ) then
		return ChatTypeInfo["BG_SYSTEM_HORDE"];
	end
	
	return ChatTypeInfo["BG_SYSTEM_NEUTRAL"];
end

function SSOverlay:CreateOverlay()
	if( self.frame ) then
		return;
	end
	
	-- Setup the overlay frame
	self.frame = CreateFrame( "Frame", "SSOverlayFrame", UIParent );
	
	self.frame.highestWidth = 0;
	self.frame:SetClampedToScreen( true );
	self.frame:RegisterForDrag( "LeftButton" );
	
	self.frame:SetFrameStrata( "BACKGROUND" );
	self.frame:SetMovable( true );
	self.frame:EnableMouse( true );
	
	self.frame:SetScript( "OnUpdate", self.OnUpdate );
	self.frame:SetScript( "OnMouseUp", function()
		if( not SSPVP.db.profile.overlay.locked ) then
			this:StopMovingOrSizing();
			
			if( SSPVP.db.profile.overlay.displayType == "down" ) then
				SSPVP.db.profile.positions.overlay.x, SSPVP.db.profile.positions.overlay.y = this:GetLeft(), this:GetTop();
			else
				SSPVP.db.profile.positions.overlay.x, SSPVP.db.profile.positions.overlay.y = this:GetLeft(), this:GetBottom();
			end
		end
	end );
	self.frame:SetScript( "OnMouseDown", function()
		if( not SSPVP.db.profile.overlay.locked ) then
			this:StartMoving();
		end
	end );
	
	self.frame:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
				edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
				tile = true,
				tileSize = 9,
				edgeSize = 9,
				insets = { left = 2, right = 2, top = 2, bottom = 2 } });	
	
	self.frame:SetBackdropColor( SSPVP.db.profile.overlay.background.r, SSPVP.db.profile.overlay.background.g, SSPVP.db.profile.overlay.background.b, SSPVP.db.profile.overlay.opacity );
	self.frame:SetBackdropBorderColor( SSPVP.db.profile.overlay.border.r, SSPVP.db.profile.overlay.border.g, SSPVP.db.profile.overlay.border.b, SSPVP.db.profile.overlay.opacity );
	
	if( SSPVP.db.profile.overlay.displayType == "down" ) then
		self.frame:SetPoint( "TOPLEFT", UIParent, "BOTTOMLEFT", SSPVP.db.profile.positions.overlay.x, SSPVP.db.profile.positions.overlay.y );
	elseif( SSPVP.db.profile.overlay.displayType == "up" ) then
		self.frame:SetPoint( "BOTTOMLEFT", UIParent, "BOTTOMLEFT", SSPVP.db.profile.positions.overlay.x, SSPVP.db.profile.positions.overlay.y );
	end
end

function SSOverlay:UpdateColors()
	SSOverlay.frame:SetBackdropColor( SSPVP.db.profile.overlay.background.r, SSPVP.db.profile.overlay.background.g, SSPVP.db.profile.overlay.background.b, SSPVP.db.profile.overlay.opacity );
	SSOverlay.frame:SetBackdropBorderColor( SSPVP.db.profile.overlay.border.r, SSPVP.db.profile.overlay.border.g, SSPVP.db.profile.overlay.border.b, SSPVP.db.profile.overlay.opacity );
	
	SSOverlay:UpdateOverlayText();
end

function SSOverlay:RowOnClick()
	local row = rows[ this.rowID ];
	
	if( row ) then
		if( type( row.handler ) == "table" and type( row.OnClick ) == "string" ) then
			row.handler[ row.OnClick ]( row.handler, unpack( row.args ) );
		
		elseif( type( row.OnClick ) == "string" ) then
			getglobal( row.OnClick )( unpack( row.args ) );

		elseif( type( row.OnClick ) == "function" ) then
			row.OnClick( unpack( row.args ) );
		end
	end
end

function SSOverlay:CreateRow()
	if( CREATED_ROWS >= MAX_ROWS ) then
		return;
	end

	CREATED_ROWS = CREATED_ROWS + 1;

	local row = CreateFrame( "Frame", self.frame:GetName() .. "Row" .. CREATED_ROWS, self.frame );
	local text = row:CreateFontString( row:GetName() .. "Text", "BACKGROUND" );
	
	row:EnableMouse( SSPVP.db.profile.overlay.locked );

	row:SetHeight( 13 );
	row:SetWidth( 250 );
	
	row:SetScript( "OnMouseUp", SSOverlay.RowOnClick );
	row:SetFrameStrata( "LOW" );
	
	text:SetJustifyH( "left" );
	text:SetFont( GameFontNormalSmall:GetFont() );
	text:SetPoint( "TOPLEFT", row, "TOPLEFT", 0, 0 );
	
	if( SSPVP.db.profile.overlay.displayType == "down" ) then
		if( CREATED_ROWS > 1 ) then
			row:SetPoint( "TOPLEFT", self.frame:GetName() .. "Row" .. ( CREATED_ROWS - 1 ), "TOPLEFT", 0, -12 );
		else
			row:SetPoint( "TOPLEFT", self.frame, "TOPLEFT", 5, -5 );
		end
	
	elseif( SSPVP.db.profile.overlay.displayType == "up" ) then
		if( CREATED_ROWS > 1 ) then
			row:SetPoint( "TOPLEFT", self.frame:GetName() .. "Row" .. ( CREATED_ROWS - 1 ), "TOPLEFT", 0, 12 );
		else
			row:SetPoint( "BOTTOMLEFT", self.frame, "BOTTOMLEFT", 5, 3 );
		end
	end
end

function SSOverlay:FormatTime( seconds, timeFormat )
	if( timeFormat == "hhmmss" ) then
		-- Quick hack, deal with it later.
		seconds = floor( seconds );
		local hours, minutes;

		if( seconds >= 3600 ) then
			hours = floor( seconds / 3600 );
			if( hours <= 9 ) then
				hours = "0" .. hours; 
			end

			hours = hours .. ":";
			seconds = mod( seconds, 3600 );
		else
			hours = "";
		end

		if( seconds >= 60 ) then
			minutes = floor( seconds / 60 );
			if( minutes <= 9 ) then
				minutes = "0" .. minutes;
			end

			seconds = mod( seconds, 60 );
		else
			minutes = "00";
		end

		if( seconds <= 9 and seconds > 0 ) then
			seconds = "0" .. seconds;
		elseif( seconds <= 0 ) then
			seconds = "00";
		end
		
		return hours .. minutes .. ":" .. seconds;

	elseif( timeFormat == "minsec" or seconds < 60 ) then
		return string.trim( SecondsToTime( seconds ) );
	end
	
	return string.trim( SecondsToTime( seconds, true ) );
end

function SSOverlay:UpdateOverlayText( updateid )
	-- No rows found, hide the overlay if it exists
	if( #( rows ) == 0 ) then
		if( SSOverlay.frame ) then
			SSOverlay.frame:Hide();
		end
		return;
	end

	local count, row, overlayRow, rowParent, width;
	
	for i=1, CREATED_ROWS do
		overlayRow = getglobal( SSOverlay.frame:GetName() .. "Row" .. i .. "Text" );
		rowParent = overlayRow:GetParent();
		
		row = rows[ i ];

		if( row ) then
			if( ( updateid and i == updateid ) or not updateid ) then
				if( row.type == "text" or row.type == "catText" ) then
					overlayRow:SetText( row.text );
				elseif( row.type == "item" ) then
					overlayRow:SetText( string.format( row.text, row.count ) );

				elseif( row.type == "timer" or row.type == "elapsed" ) then
					overlayRow:SetText( string.format( row.text, SSOverlay:FormatTime( row.seconds, SSPVP.db.profile.overlay.timer ) ) );
				end
				
				if( row.color ) then
					overlayRow:SetTextColor( row.color.r, row.color.g, row.color.b, SSPVP.db.profile.overlay.textOpacity );
				elseif( row.type == "catText" ) then
					overlayRow:SetTextColor( SSPVP.db.profile.overlay.categoryColor.r, SSPVP.db.profile.overlay.categoryColor.g, SSPVP.db.profile.overlay.categoryColor.b, SSPVP.db.profile.overlay.textOpacity );
				else
					overlayRow:SetTextColor( SSPVP.db.profile.overlay.textColor.r, SSPVP.db.profile.overlay.textColor.g, SSPVP.db.profile.overlay.textColor.b, SSPVP.db.profile.overlay.textOpacity );
				end
				
				if( SSOverlay.frame.highestWidth < overlayRow:GetWidth() ) then
					SSOverlay.frame.highestWidth = overlayRow:GetWidth() + 20;
				end
				
				overlayRow.category = row.category;
				rowParent.rowID = i;
				rowParent:Show();
			end
		else
			overlayRow.category = nil;
			rowParent:Hide();
		end
	end
	
	if( not updateid ) then
		local pad = 9;
		local fact = -1;

		if( SSPVP.db.profile.overlay.displayType == "up" ) then
			fact = 1;
		end
		
		for i=1, CREATED_ROWS do
			rowParent = getglobal( SSOverlay.frame:GetName() .. "Row" .. i );
			rowParent:SetWidth( SSOverlay.frame.highestWidth + 2 );
			
			row = rows[ i ];
			
			if( i > 1 and row ) then
				if( row.type ~= "catText" ) then
					pad = pad + SSPVP.db.profile.overlay.rowPad;
					rowParent:SetPoint( "TOPLEFT", SSOverlay.frame:GetName() .. "Row" .. ( i - 1 ), "TOPLEFT", 0, fact * ( 12 - ( -1 * SSPVP.db.profile.overlay.rowPad ) ) );
				else
					pad = pad + SSPVP.db.profile.overlay.catPad;
					rowParent:SetPoint( "TOPLEFT", SSOverlay.frame:GetName() .. "Row" .. ( i - 1 ), "TOPLEFT", 0, fact * ( 12 - ( -1 * SSPVP.db.profile.overlay.catPad ) ) );
				end
				
			elseif( i == 1 ) then
				rowParent:ClearAllPoints();

				if( SSPVP.db.profile.overlay.displayType == "down" ) then
					rowParent:SetPoint( "TOPLEFT", SSOverlay.frame, "TOPLEFT", 5, -5 );
				elseif( SSPVP.db.profile.overlay.displayType == "up" ) then
					rowParent:SetPoint( "BOTTOMLEFT", SSOverlay.frame, "BOTTOMLEFT", 5, 3 );				
				end
			end
		end
		
		if( #( rows ) < CREATED_ROWS ) then
			SSOverlay.frame:SetHeight( ( #( rows ) * ( getglobal( SSOverlay.frame:GetName() .. "Row1Text" ):GetHeight() + 2 ) ) + pad );
		else
			SSOverlay.frame:SetHeight( ( CREATED_ROWS * ( getglobal( SSOverlay.frame:GetName() .. "Row1Text" ):GetHeight() + 2 ) ) + pad );
		end
	end
	
	SSOverlay.frame:SetWidth( SSOverlay.frame.highestWidth + 5 );
	SSOverlay.frame:Show();
end

function SSOverlay:BAG_UPDATE()
	for i, row in pairs( rows ) do
		if( row.type == "item" ) then
			row.count = GetItemCount( row.itemid );
			self:UpdateText( i );
		end
	end
end

local elapsed = 0;
function SSOverlay:OnUpdate()
	elapsed = elapsed + arg1;
	
	if( elapsed > 0.25 ) then
		elapsed = 0;
		
		local time = GetTime();
		
		for i=#( rows ), 1, -1 do
			local row = rows[ i ];
			if( row and row.type == "timer" ) then
				row.seconds = row.startSeconds - ( time - row.startTime );
				
				if( floor( row.seconds ) <= 0 ) then
					table.remove( rows, i );
					
					SSOverlay:UpdateCategoryText();
					SSOverlay:SortRows();
					SSOverlay.frame.highestWidth = 0;
					SSOverlay:UpdateOverlayText();
				else
					SSOverlay:UpdateOverlayText( i );
				end
				
			elseif( row and row.type == "elapsed" ) then
				row.seconds = row.startSeconds + ( time - row.startTime );
				SSOverlay:UpdateOverlayText( i );
			end
		end
	end
end


function SSOverlay:AddCategory( name, text, order, handler, OnClick )
	if( categories[ name ] ) then
		return;
	end
	
	-- If we've already got a matching order we have to shift it
	-- so we don't get display/sort issues
	if( order ) then
		for catName, category in pairs( categories ) do
			if( category.order and category.order == order ) then
				order = order + 1;
			end
		end
	end
	
	ADDED_CATEGORIES = ADDED_CATEGORIES + 1;
	order = order or ADDED_CATEGORIES;
	
	categories[ name ] = { order = order * 100, text = text, handler = handler, OnClick = OnClick };
end

function SSOverlay:AddOnClick( rowType, category, text, handler, OnClick, ... )
	for id, row in pairs( rows ) do
		if( not row.OnClick and row.type == rowType and row.category == category and string.lower( text ) == string.lower( row.addedText ) ) then
			if( type( handler ) == "table" and type( OnClick ) == "string" ) then
				rows[ id ].handler = handler;
			end
			
			rows[ id ].OnClick = OnClick;
			rows[ id ].args = { ... };
			
			return;
		end
	end
end

function SSOverlay:SortRows()
	table.sort( rows, function( a, b )
		if( a.sortID ~= b.sortID ) then
			return ( a.sortID < b.sortID );
		end
		
		return ( a.addID < b.addID );
	end );
end

function SSOverlay:UpdateCategoryText()
	-- Show mode is set to always hide
	if( SSPVP.db.profile.overlay.catType == "hide" ) then
		return;
	end
	
	local foundCats = {};
	local totalCats = 0;
	
	for _, row in pairs( rows ) do
		if( not foundCats[ row.category ] and row.type ~= "catText" ) then
			totalCats = totalCats + 1;
			foundCats[ row.category ] = true;
		end
	end
	
	-- Either we have multiple categories showing, or we're always showing them all.
	if( totalCats > 1 or SSPVP.db.profile.overlay.catType == "show" ) then
		for name, _ in pairs( foundCats ) do
			SSOverlay:UpdateRow( { type = "catText", category = name, text = categories[ name ].text } );

			if( categories[ name ].handler or categories[ name ].OnClick ) then
				SSOverlay:AddOnClick( "catText", name, categories[ name ].text, categories[ name ].handler, categories[ name ].OnClick );
			end
		end
	else
		SSOverlay:RemoveRow( "catText" );
	end
end

function SSOverlay:UpdateRow( updatedRow, ... )
	if( not updatedRow.text or not updatedRow.type or not categories[ updatedRow.category ] ) then
		return;
	end

	-- First time we're adding something to the overlay, so create it
	if( not self.frame ) then
		self:CreateOverlay();
	end
	
	local extras = { ... };
	local color;
	
	-- If they're passing a table as the first one, then it has to be a color
	if( type( extras[1] ) == "table" ) then
		color = { r = extras[1].r, g = extras[1].g, b = extras[1].b };
		table.remove( extras, 1 );
	end
	
	updatedRow.addedText = updatedRow.text;
	if( updatedRow.type == "text" or updatedRow.type == "catText" ) then
		updatedRow.text = string.format( updatedRow.text, unpack( extras ) );
	elseif( updatedRow.type == "elapsed" or updatedRow.type == "timer" ) then
		updatedRow.text = string.format( updatedRow.text, "%s", unpack( extras ) );
	end
	
	updatedRow.color = color;
	updatedRow.sortID = categories[ updatedRow.category ].order + priorities[ updatedRow.type ];
	
	for id, row in pairs( rows ) do
		-- Does type/category/text match?
		if( row.type == updatedRow.type and row.category == updatedRow.category and string.lower( row.addedText ) == string.lower( updatedRow.addedText ) ) then
			if( not updatedRow.color or ( updatedRow.color and row.color and updatedRow.color.r == row.color.r and updatedRow.color.g == row.color.g and updatedRow.color.b == row.color.b ) ) then
				rows[ id ] = updatedRow;
				rows[ id ].addID = id;

				SSOverlay:UpdateOverlayText( id );
				return;
			end
		end
	end
	
	updatedRow.addID = #( rows ) + 1;
	table.insert( rows, updatedRow );
	
	if( #( rows ) > CREATED_ROWS ) then
		self:CreateRow();
	end
	
	if( updatedRow.type ~= "catText" ) then
		self:UpdateCategoryText();
	end
	
	self:SortRows();
	SSOverlay:UpdateOverlayText();
end

function SSOverlay:UpdateText( category, text, ... )
	SSOverlay:UpdateRow( { type = "text", category = category, text = text, type = "text" } , ... );
end

function SSOverlay:UpdateElapsed( category, text, start, ... )
	SSOverlay:UpdateRow( { type = "elapsed", category = category, text = text, seconds = start or 0, startSeconds = start or 0, startTime = GetTime() } , ... );
end

function SSOverlay:UpdateTimer( category, text, start, ... )
	SSOverlay:UpdateRow( { type = "timer", category = category, text = text, seconds = start, startSeconds = start, startTime = GetTime() } , ... );
end

function SSOverlay:UpdateItem( category, text, item, ... )
	SSOverlay:UpdateRow( { type = "item", category = category, text = text, itemid = item, count = GetItemCount( item ) }, ... );
end

function SSOverlay:RemoveCategory( category )
	for i=#( rows ), 1, -1 do
		if( rows[ i ].category == category ) then
			table.remove( rows, i );
			self.frame.highestWidth = 0;
		end
	end
	
	if( self.frame and self.frame.highestWidth == 0 ) then
		self:UpdateCategoryText();
		self:SortRows();
		self:UpdateOverlayText();
	end
end

function SSOverlay:RemoveRow( type, category, text, color )
	local row;
	
	for i=#( rows ), 1, -1 do
		row = rows[ i ];
		
		-- Check type
		if( ( type and row.type == type ) or not type ) then
			-- Check category
			if( ( category and row.category == category ) or not category ) then
				-- Check text
				if( ( text and string.lower( row.addedText ) == string.lower( text ) ) or not text ) then
					-- Check color
					if( not color or ( color and row.color and color.r == row.color.r and color.g == row.color.g and color.b == row.color.b ) ) then
						table.remove( rows, i );
						self.frame.highestWidth = 0;
					end
				end
			end
		end
	end
	
	if( type ~= "catText" ) then
		self:UpdateCategoryText();
	end
	self:SortRows();
	self:UpdateOverlayText();
end

function SSOverlay:RemoveAll()
	rows = {};
	
	for i=1, CREATED_ROWS do
		getglobal( self.frame:GetName() .. "Row" .. i ):Hide();
	end

	self.frame:Hide();
	self.frame.highestWidth = 0;
end