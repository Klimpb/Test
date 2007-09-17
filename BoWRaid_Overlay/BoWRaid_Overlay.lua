local OverlayRows = {};
local SortHigh;

function BWOverlay_OnLoad()
	this:RegisterForDrag( "LeftButton" );
	this:SetBackdropColor( 0, 0, 0, 1 );
	this:SetBackdropBorderColor( 0.5, 0.5, 0.5, 1 );
	this.frameid = "overlay";
end

function BWOverlay_Position()
	if( BWRaid_Config.positions.overlay ) then
		BWOverlay:SetPoint( "TOPLEFT", "UIParent", "BOTTOMLEFT", BWRaid_Config.positions.overlay.x, BWRaid_Config.positions.overlay.y );
	else
		BWOverlay:SetPoint( "TOPLEFT", "UIParent", "BOTTOMLEFT", 300, 400 );
	end
end

function BWOverlay_AddRow( data )
	data.rowID = #( OverlayRows ) + 1;
	table.insert( OverlayRows, data );
	
	BWOverlay_CreateRow( #( OverlayRows ) );
	BWOverlay_Update();
end

function BWOverlay_UpdateRow( data )
	for id, row in pairs( OverlayRows ) do
		if( string.find( row.text, data.searchOn ) ) then
			for key, value in pairs( data ) do
				row[ key ] = value;
			end
			
			OverlayRows[ id ] = row;
			BWOverlay_Update();
			return;
		end
	end
	
	BWOverlay_AddRow( data );
end

function BWOverlay_RemoveRows( row )
	for i=#( OverlayRows ), 0, -1 do
		if( string.find( OverlayRows[ i ].text, row.text ) ) then
			table.remove( OverlayRows, i );
		end
	end
	
	BWOverlay_Update();
end

function BWOverlay_SortHigh( enabled )
	SortHigh = enabled;
	BWOverlay_Update();
end

function BWOverlay_RemoveAll()
	OverlayRows = {};
	BWOverlay_Update();
end

function BWOverlay_CreateRow( rowID )
	if( not getglobal( "BWOverlayRow" .. rowID ) ) then
		local parent = "BWOverlayRow" .. ( rowID - 1 );
		if( rowID == 1 ) then
			parent = "BWOverlay";
		end
		
		local row = CreateFrame( "Frame", "BWOverlayRow" .. rowID, getglobal( parent ), "BWOverlayRow" );
		
		if( rowID == 1 ) then
			row:SetPoint( "TOPLEFT", parent, "TOPLEFT", 5, -5 );
		else
			row:SetPoint( "TOPLEFT", parent, "TOPLEFT", 0, -12 );
		end
		
		getglobal( row:GetName() .. "Text" ):SetTextColor( 1, 1, 1, 1 );
	end
end

function BWOverlay_Resize()
	if( #( OverlayRows ) == 0 ) then
		BWOverlay:Hide();
	else
		local rowWidth = 0;
		for id, _ in pairs( OverlayRows ) do
			local width = getglobal( "BWOverlayRow" .. id .. "Text" ):GetWidth();
			if( width > rowWidth ) then
				rowWidth = width;
			end
		end
		
		BWOverlay:SetWidth( rowWidth + 20 );
		BWOverlay:SetHeight( #( OverlayRows ) * ( getglobal( "BWOverlayRow1Text" ):GetHeight() + 2 ) + 9 );
		BWOverlay:Show();
		
		for id, _ in pairs( OverlayRows ) do
			getglobal( "BWOverlayRow" .. id ):SetWidth( BWOverlay:GetWidth() );
		end
	end
end

function BWOverlay_Update()
	-- Hack sort
	table.sort( OverlayRows, function( a, b )
		if( not a ) then
			return true;
		elseif( not b ) then
			return false;
				
		--[[
		-- a is a category, b is not OR a has a sortID and B does not
		elseif( ( a.category and not b.category ) or ( a.sortID and not b.sortID ) ) then
			return true;
		
		-- a isn't acategory, b is OR doesn't have a sortID and B does
		elseif( ( not a.category and b.category ) or ( not a.sortID and b.sortID ) ) then
			return false;
		]]
		
		-- a and b have sortID's
		elseif( a.sortID and b.sortID ) then
			return ( ( not SortHigh and a.sortID < b.sortID ) or ( SortHigh and a.sortID > b.sortID ) );
		end
		
		-- Nothing, sort by row id.
		return ( a.rowID > b.rowID );
	end );
	
	local i = 1;
	while( getglobal( "BWOverlayRow" .. i ) ) do
		if( OverlayRows[ i ] ) then
			getglobal( "BWOverlayRow" .. i .. "Text" ):SetText( OverlayRows[ i ].text );
		else
			getglobal( "BWOverlayRow" .. i .. "Text" ):SetText( "" );		
		end
		
		i = i + 1;
	end
	
	BWOverlay_Resize();
end
