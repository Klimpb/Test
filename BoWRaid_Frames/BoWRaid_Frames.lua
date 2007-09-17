local ForceOpen;
local ForceClosed;
local QueuePositionFrame;
local RaidGroupList = {};
local CreatedFrames = {};

local FramePadding = {};

-- Starts at 0, so it's actually 4
local BW_MAX_BUFFS = 3;

local LeftBuffInfo = {};
local RightBuffInfo = {};

-- Allows us to queue attribute changes for when we're OOC
local FrameQueue = {};
local QueueRaidUpdate;

-- Range checking
local RangeEnabled;
local RangeSpell;
local RangeCheckTime = 0.25;
local TimeElapsed = {};

function BWFrames_OnLoad()
	this:RegisterEvent( "VARIABLES_LOADED" );
	
	this:RegisterEvent( "PLAYER_ENTERING_WORLD" );
	this:RegisterEvent( "RAID_ROSTER_UPDATE" );
	
	this:RegisterEvent( "PLAYER_REGEN_ENABLED" );
		
	SLASH_LOADRFRAMES1 = "/rs";
	SLASH_LOADRFRAMES2 = "/raidshow";
	SlashCmdList["LOADRFRAMES"] = function() ForceOpen = true; ForceClosed = false; BWFrames_UpdateRaidRoster(); BWFrames_RaidUpdated(); end
	
	SLASH_HIDERFRAMES1 = "/raidhide";
	SLASH_HIDERFRAMES2 = "/rh";
	SlashCmdList["HIDERFRAMES"] = function() ForceOpen = nil; ForceClosed = true; BWFrames_HideAll(); end
	
	SLASH_BWCORRUPT1 = "/rfcorrupt";
	SlashCmdList["BWCORRUPT"] = BWFrames_CheckCorruption;
end

function BWFrames_SavePosition( frame )
	if( not frame or not frame.frameid ) then
		return;
	elseif( not BWRaid_Config.positions ) then
		BWRaid_Config.positions = {};
	end
			
	BWRaid_Config.positions[ frame.frameid ] = { x = frame:GetLeft(), y = frame:GetTop() };
	
	if( QueuePositionFrame and ( frame.frameType == "group" or frame.frameType == "class" ) ) then
		QueuePositionFrame = nil;

		BWFrames_PositionFrame( "class" );
		BWFrames_PositionFrame( "group" );
	end
end

function BWFrames_PositionFrame( type, autoGroup )
	-- Check if we're moving any frames currently
	for _, frame in pairs( CreatedFrames ) do
		if( getglobal( frame.name ).frameType == type and getglobal( frame.name .. "Move" ).isMoving ) then
			QueuePositionFrame = true;
			return;
		end
	end
	
	if( not autoGroup or BWRaid_Config.raid.rows <= 0 ) then
		for _, frameInfo in pairs( CreatedFrames ) do
			if( frameInfo.type == type ) then
				local frame = getglobal( frameInfo.name );
				frame.parentFrame = nil;
				
				if( BWRaid_Config.positions[ frame.frameid ] ) then
					frame:SetPoint( "TOPLEFT", frame:GetParent(), "BOTTOMLEFT", BWRaid_Config.positions[ frame.frameid ].x, BWRaid_Config.positions[ frame.frameid ].y );
				else
					frame:SetPoint( "TOPLEFT", frame:GetParent(), "TOPLEFT", 300, -300 );			
				end
			end
		end
	
	else
		local lastRow, lastColumn, parent, firstRowAdded, parentFrame;
		local highestFrame = 0;
		local rowsAdded = 0;
		local padX = 0;
				
		if( BWRaid_Config.buff.leftType ~= "none" and BWRaid_Config.buff.rightType ~= "none" ) then
			padX = padX + 40;
			
		elseif( BWRaid_Config.buff.leftType ~= "none" or BWRaid_Config.buff.rightType ~= "none" ) then
			padX = padX + 20;
		end
				
		for _, frameInfo in pairs( CreatedFrames ) do
			local frame = getglobal( frameInfo.name );
			if( frameInfo.type == type and frame:IsVisible() ) then
				if( not lastColumn ) then
					lastColumn = frameInfo.name;
					parentFrame = frameInfo.name;
				end
				
				if( rowsAdded == BWRaid_Config.raid.rows ) then
					posY = -150;
					posX = 0;
					rowsAdded = 0;

					if( frameInfo.type == "class" ) then
						posY = -30 - highestFrame;
						highestFrame = 0;
					end
					
					parent = lastColumn;
					lastColumn = frameInfo.name;
				elseif( rowsAdded > 0 ) then
					parent = lastRow;

					posY = 0;
					posX = 230 + padX;
				end
						
				if( firstRowAdded ) then
					frame:SetPoint( "TOPLEFT", parent, "TOPLEFT", posX, posY );
				else
					if( not BWRaid_Config.positions[ frame.frameid ] ) then
						BWRaid_Config.positions[ frame.frameid ] = { x = 600, y = 600 };
					end
				
					frame:SetPoint( "TOPLEFT", parent, "BOTTOMLEFT", BWRaid_Config.positions[ frame.frameid ].x, BWRaid_Config.positions[ frame.frameid ].y );				
				end
				
				frame.parentFrame = parentFrame;
				lastRow = frameInfo.name;

				rowsAdded = rowsAdded + 1;
				firstRowAdded = true;
				
				if( frame:GetHeight() > highestFrame ) then
					highestFrame = frame:GetHeight();
				end
			end
		end
	end
end

function BWFrames_SetFramePadding()
	FramePadding = { blizzard = { first = -2, others = 13, bottom = 3 }, default = { first = 2, others = 0, bottom = 2 } };
		
	if( not BWRaid_Config.raid.healthOnly and BWRaid_Config.raid.style == "blizzard" ) then
		FramePadding.blizzard = { first = 0, others = 15, bottom = 7 };
	end

	-- Updates the frame padding
	for _, frameInfo in pairs( CreatedFrames ) do
		local parentFrame = getglobal( frameInfo.name );
		
		for i=1, parentFrame.createdRows do
			local frame = getglobal( parentFrame:GetName() .. "Row" .. i );
			
			frame:ClearAllPoints();
			if( i > 1 ) then
				frame:SetPoint( "TOPLEFT", getglobal( parentFrame:GetName() .. "Row" .. i - 1 ), "TOPLEFT", 0, -18 - BWRaid_Config.raid.padding - FramePadding[ BWRaid_Config.raid.style ]["others"] );
			else
				frame:SetPoint( "TOPLEFT", parentFrame:GetName(), "TOPLEFT", 0, -8 - FramePadding[ BWRaid_Config.raid.style ]["first"] );
			end
		end
		
		BWFrames_UpdateGroupHeight( parentFrame );
	end
end

-- Checks the unitid to the name and makes sure that the raid data didn't become corrupted
function BWFrames_CheckCorruption( suppress )
	local MemberUnits = {};
	for i=1, GetNumRaidMembers() do
		local name = GetRaidRosterInfo( i );
		MemberUnits[ name ] = "raid" .. i;
	end
	
	local found = false;
	

	for _, frameInfo in pairs( CreatedFrames ) do
		local raid = getglobal( frameInfo.name );
		
		for i=1, raid.raidRows do
			local row = getglobal( raid:GetName() .. "Row" .. i );
			local memberName = string.trim( string.gsub( string.gsub( getglobal( row:GetName() .. "Name" ):GetText(), BWF_LEADER_ICON, "" ), BWF_ASSIST_ICON, "" ) );
			
			if( memberName ~= UnitName( row.unit ) or memberName ~= UnitName( row:GetAttribute( "unit" ) ) ) then
				if( MemberUnits[ memberName ] ) then
					row.unit = MemberUnits[ memberName ];
					BWFrames_SetAttribute( row, "unit", MemberUnits[ memberName ] );
					
					BWFrames_UpdateHealthBar( row.unit, row );
					BWFrames_UpdateManaBar( row.unit, row );

					BWFrames_CheckPowerType( row.unit, row );
					BWFrames_UpdateBuffs( row.unit, row );

					if( not suppress ) then
						BWRaid_Message( string.format( BWF_CORRUPTION_FOUND, memberName, getglobal( raid:GetName() .. "Title" ):GetText() ) );

						found = true;
					end
				elseif( not suppress ) then
					BWRaid_Message( string.format( BWF_CORRUPTION_FOUNDNOUNIT, memberName, getglobal( raid:GetName() .. "Title" ):GetText() ) );
					
					found = true;
				end
			end
		end
	end
	
	if( not found and not suppress ) then
		BWRaid_Message( BWF_NO_CORRUPTION, ChatTypeInfo["SYSTEM"] );
	end
end

function BWFrames_UpdateFrame( row, member )
	if( member ) then
		-- Append rank
		local rank = "";

		if( BWRaid_Config.raid.showRank ) then
			if( member.rank == 2 ) then
				rank = BWF_LEADER_ICON .. " ";
			elseif( member.rank == 1 ) then
				rank = BWF_ASSIST_ICON .. " ";
			end
		end
		
		-- Set name
		getglobal( row:GetName() .. "Name" ):SetText( rank .. member.name );
		
		-- Load bars
		BWFrames_UpdateHealthBar( member.unit, row );
		BWFrames_UpdateManaBar( member.unit, row );

		BWFrames_CheckPowerType( member.unit, row );
		BWFrames_UpdateBuffs( member.unit, row );
		
		row.unit = member.unit;
		row.raidIndex = member.raidIndex;	
		row:Show();

		-- Set unit
		BWFrames_SetAttribute( row, "type", "target" );
		BWFrames_SetAttribute( row, "unit", member.unit );
	else
		row.unit = nil;
		row.raidIndex = nil;
		row:Hide();

		-- Clear attribute
		BWFrames_SetAttribute( row, "unit", nil );
	end
end

-- Updates a group frame
function BWFrames_UpdateGroup( frameid, title, members )
	local frame = getglobal( "BWRaid" .. frameid );
	
	if( frame and members ) then
		if( BWRaid_Config.raid.showCount ) then
			title = title .. " (" .. #( members ) .. ")";
		end
	
		getglobal( frame:GetName() .. "Title" ):SetText( title );

		-- Hide all rows
		for i=1, frame.createdRows do
			getglobal( frame:GetName() .. "Row" .. i ):Hide();
		end
		
		-- Update
		frame.raidRows = 0;
		for _, member in pairs( members ) do
			frame.raidRows = frame.raidRows + 1;
			BWFrames_UpdateFrame( getglobal( frame:GetName() .. "Row" .. frame.raidRows ), member );
		end
		
		BWFrames_UpdateGroupHeight( frame );
	elseif( frame ) then
		frame.raidRows = 0;
		frame:Hide();
	end
end

function BWFrames_UpdateGroupHeight( frame )
	local frameHeight = 18 + FramePadding[ BWRaid_Config.raid.style ]["others"];

	if( BWRaid_Config.raid.style == "default" ) then
		frameHeight = frameHeight + BWRaid_Config.raid.padding;

		if( BWRaid_Config.raid.padding < 5 ) then
			frameHeight = frameHeight + 1;
		end		
	elseif( BWRaid_Config.raid.style == "blizzard" ) then
		frameHeight = frameHeight + 7;
	end

	frame:SetHeight( 10 + FramePadding[ BWRaid_Config.raid.style ]["bottom"] + ( frame.raidRows * frameHeight ) );	
	frame:Show();	
end

function BWFrames_RaidUpdated()
	-- If we're in combat, block any raid changes from happening
	if( InCombatLockdown() ) then
		QueueRaidUpdate = true;
		return;
	end
	
	BWFrames_CreateRaidFrames();
		
	-- Update all group raid frames
	for group, enabled in pairs( BWRaid_Config.group ) do
		if( enabled ) then
			BWFrames_UpdateGroup( group, BWF_GROUP .. " " .. group, RaidGroupList[ group ] );
		end
	end
	
	-- Now load everything for any class thats enabled
	for class, enabled in pairs( BWRaid_Config.class ) do
		if( enabled ) then
			BWFrames_UpdateGroup( class, BWFrames_GetUnlocalizedClass( class ), RaidGroupList[ class ] );
		end
	end
end

function BWFrames_GetUnlocalizedClass( class )
	for _, row in pairs( BWF_CLASSES ) do
		if( row.unloc == class ) then
			return row.class;
		end
	end
	
	return nil;
end

function BWFrames_CreateRaidFrames()
	-- Load everything for all the groups
	for group, enabled in pairs( BWRaid_Config.group ) do
		if( enabled ) then
			BWFrames_CreateFrame( group, 5 );
		end
	end
	
	-- Now load everything for any class thats enabled
	for class, enabled in pairs( BWRaid_Config.class ) do
		if( enabled and RaidGroupList[ class ] ) then
			BWFrames_CreateFrame( class, #( RaidGroupList[ class ] ) );
		end
	end
end

function BWFrames_GetFrame( frameName )
	for _, frame in pairs( CreatedFrames ) do
		if( frame.name == frameName ) then
			return frame;
		end
	end
	
	return nil;
end

function BWFrames_CreateFrame( frameName, rows )
	local parentFrame = getglobal( "BWRaid" .. frameName );
	
	-- Check if the parent was created
	if( not parentFrame ) then
		parentFrame = CreateFrame( "Frame", "BWRaid" .. frameName, UIParent, "SecureUnitButtonTemplate,BWGroupTemplate" );
--		parentFrame = CreateFrame( "Frame", "BWRaid" .. frameName, UIParent, "SecureUnitButtonTemplate,GameMenuButtonTemplate,BWGroupTemplate" );
		parentFrame.raidRows = 0;
		parentFrame.createdRows = 0;
		parentFrame.frameid = frameName;
		
		if( type( frameName ) == "number" ) then
			parentFrame.frameType = "group";
		else
			parentFrame.frameType = "class";
		end

		table.insert( CreatedFrames, { name = parentFrame:GetName(), id = frameName, type = parentFrame.frameType } );
		
		-- Now sort it so the groups are in order
		table.sort( CreatedFrames, function( a, b )
			if( a and b and a.type == "group" and b.type == "group" ) then
			    return ( a.id < b.id );
			else
			    return false;
			end
		end );
		
		TimeElapsed[ parentFrame:GetName() ] = 0;
		
		-- Set scale/colors
		parentFrame:SetScale( BWRaid_Config.frame.scale );
		parentFrame:SetBackdropColor( BWRaid_Config.frame.backgroundColor.r, BWRaid_Config.frame.backgroundColor.g, BWRaid_Config.frame.backgroundColor.b, BWRaid_Config.frame.backgroundOpacity );
		parentFrame:SetBackdropBorderColor( BWRaid_Config.frame.borderColor.r, BWRaid_Config.frame.borderColor.g, BWRaid_Config.frame.borderColor.b, BWRaid_Config.frame.borderOpacity );

		parentFrame:Hide();
	end
	
	-- Create the rows
	for i=1, rows do
		local frame = getglobal( "BWRaid" .. frameName .. "Row" .. i );

		-- Check if the row doesn't exist
		if( not frame ) then
			parentFrame.createdRows = parentFrame.createdRows + 1;
			
			local parent;
			if( i == 1 ) then
				parent = parentFrame;			
			else
				parent = getglobal( "BWRaid" .. frameName .. "Row" .. i - 1 );
			end
			
			frame = CreateFrame( "Button", "BWRaid" .. frameName .. "Row" .. i, parent, "SecureUnitButtonTemplate,BWGroupMemberTemplate" );
--			frame = CreateFrame( "Button", "BWRaid" .. frameName .. "Row" .. i, parent, "SecureUnitButtonTemplate,GameMenuButtonTemplate,BWGroupMemberTemplate" );
			
			if( i == 1 ) then
				frame:SetPoint( "TOPLEFT", parent, "TOPLEFT", 0, -8 - FramePadding[ BWRaid_Config.raid.style ]["first"] );
			else
				frame:SetPoint( "TOPLEFT", parent, "TOPLEFT", 0, -18 - BWRaid_Config.raid.padding - FramePadding[ BWRaid_Config.raid.style ]["others"] );
			end
			
			-- Reposition the buffs if needed
			if( BW_MAX_BUFFS == 1 ) then
				getglobal( frame:GetName() .. "LDebuff1" ):SetPoint( "TOPLEFT", frame, "TOPLEFT", -12, -4 )
				getglobal( frame:GetName() .. "RDebuff1" ):SetPoint( "TOPLEFT", frame, "TOPRIGHT", 0, -4 )
			end
	
			-- Hack, fix later
			getglobal( frame:GetName() .. "HealthText" ):SetPoint( "CENTER", frame:GetName() .. "HealthBar", "CENTER", 0, 1 );
			getglobal( frame:GetName() .. "HealthText" ):SetTextColor( BWRaid_Config.raid.healthColor.r, BWRaid_Config.raid.healthColor.g, BWRaid_Config.raid.healthColor.b );
			
			-- Hide the alert backdrop
			frame:SetBackdropColor( 0, 0, 0, 0 );
			
			-- Register events
			frame:RegisterEvent( "UNIT_AURA" );
			frame:RegisterEvent( "UNIT_DISPLAYPOWER" );
			
			frame:RegisterEvent( "UNIT_HEALTH" );
			frame:RegisterEvent( "UNIT_MAXHEALTH" );
			
			frame:RegisterEvent( "UNIT_MANA" );
			frame:RegisterEvent( "UNIT_RAGE" );
			frame:RegisterEvent( "UNIT_ENERGY" );
			frame:RegisterEvent( "UNIT_MAXMANA" );
			frame:RegisterEvent( "UNIT_MAXRAGE" );

			-- Add the click casting entry
			ClickCastFrames[ frame ] = true;
			
			-- Update any frame specific data if needed
			BWFrames_ChangeBarStyle( frame );
			BWFrames_ChangeFrameStyle( frame, parentFrame );
		end
	end
end

-- Hide/Show all frames of a specific type
function BWFrames_HideAll( type )
	for _, frame in pairs( CreatedFrames ) do
		if( type == nil or ( type and frame.type == type ) ) then
			BWFrames_Hide( getglobal( frame.name ) );
		end
	end
end

function BWFrames_ShowAll( type )
	for _, frame in pairs( CreatedFrames ) do
		if( type == nil or ( type and frame.type == type ) ) then
			BWFrames_Show( getglobal( frame.name ) );
		end
	end
end

function BWFrames_Group_OnShow()
	if( ( ( ForceClosed or not BWRaid_Config.raid.enable ) and not ForceOpen ) or GetNumRaidMembers() == 0 or ( this.frameType and not BWRaid_Config[ this.frameType ][ this.frameid ] ) ) then
		BWFrames_Hide( this );
	elseif( this.frameType and this.frameType == "group" ) then
		BWFrames_PositionFrame( this.frameType, BWRaid_Config.raid.groupRaid );
	elseif( this.frameType and this.frameType == "class" ) then
		BWFrames_PositionFrame( this.frameType, BWRaid_Config.raid.groupClass );
	end
end

function BWFrames_Group_OnHide()
	if( ( ( ForceOpen or BWRaid_Config.raid.enable ) and not ForceClosed ) and GetNumRaidMembers() > 0 ) then
		if( this.raidRows > 0 and BWRaid_Config[ this.frameType ][ this.frameid ] ) then
			BWFrames_Show( this );
		end	
	elseif( this.frameType and this.frameType == "group" ) then
		BWFrames_PositionFrame( this.frameType, BWRaid_Config.raid.groupRaid );
	elseif( this.frameType and this.frameType == "class" ) then
		BWFrames_PositionFrame( this.frameType, BWRaid_Config.raid.groupClass );
	end
end

function BWFrames_Unit_OnEvent( event, frame )
	-- Update unit mana
	if( ( event == "UNIT_MANA" or event == "UNIT_RAGE" or event == "UNIT_ENERGY" ) and arg1 == frame.unit ) then
		BWFrames_UpdateManaBar( frame.unit, frame );
	
	-- Maximum mana changed
	elseif( ( event == "UNIT_MAXMANA" or event == "UNIT_MAXRAGE" or event == "UNIT_MAXENERGY" ) and arg1 == frame.unit ) then
		BWFrames_UpdateManaBar( frame.unit, frame );
	
	-- Update (de)buffs
	elseif( event == "UNIT_AURA" and arg1 == frame.unit ) then
		BWFrames_UpdateBuffs( frame.unit, frame );
	
	-- Update unit health
	elseif( event == "UNIT_HEALTH" and arg1 == frame.unit ) then
		BWFrames_UpdateHealthBar( frame.unit, frame );
	
	-- Maximum health changed
	elseif( event == "UNIT_MAXHEALTH" and arg1 == frame.unit ) then
		BWFrames_UpdateHealthBar( frame.unit, frame );
	
	-- Form shifting
	elseif( event == "UNIT_DISPLAYPOWER" and arg1 == frame.unit ) then
		BWFrames_CheckPowerType( frame.unit, frame );
	end
end


-- Updates buffs for the specific unit/frame
function BWFrames_UpdateBuffs( unit, frame )
	frame.DisplayedBuffs = {};
	frame.DisplayedDebuffs = {};
	
	BWFrames_SetupBuffs( frame:GetName() .. "LDebuff", unit, LeftBuffInfo );
	BWFrames_SetupBuffs( frame:GetName() .. "RDebuff", unit, RightBuffInfo );

	-- Setup debuff alerts
	if( BWRaid_Config.alert.enable and ( BWRaid_Config.alert.curable or BWRaid_Config.alert.debuff ) ) then
		local debuffName, debuffType;
		if( BWRaid_Config.alert.curable ) then
			debuffName, _, _, _, debuffType = UnitDebuff( unit, 1, true );
		else
			debuffName, _, _, _, debuffType = UnitDebuff( unit, 1 );
		end
		
		frame.alertCure = ( debuffName ~= nil );
		
		-- Show the alert background
		if( not frame.alertShown and frame.alertCure ) then
			if( not BWRaid_Config.alert.colorDebuff ) then
				frame:SetBackdropColor( BWRaid_Config.alert.cureColor.r, BWRaid_Config.alert.cureColor.g, BWRaid_Config.alert.cureColor.b, 1 );
			else
				if( not DebuffTypeColor[ debuffType ] ) then
					debuffType = "none";
				end
				
				frame:SetBackdropColor( DebuffTypeColor[ debuffType ].r, DebuffTypeColor[ debuffType ].g, DebuffTypeColor[ debuffType ].b, 1 );
			end
			
			frame.alertShown = "cure";
		
		-- Show the HP background since we no longer have a cure one
		elseif( frame.alertShown == "cure" and not frame.alertCure and frame.alertHP ) then
			frame.alertShown = nil;
			
			-- Update the healthbar for the background color, and pray to code we don't get an overflow
			BWFrames_UpdateHealthBar( unit, frame );

		-- Hide the alert background
		elseif( frame.alertShown and not frame.alertCure and not frame.alertHP ) then
			frame:SetBackdropColor( 0, 0, 0, 0 );
			frame.alertShown = nil;
		end
	end

end

-- Sets up the buffs according to the info passed
function BWFrames_SetupBuffs( buffFrame, unit, info )
	local addedIndex = 0;
	local index = info.position;
	local frame = getglobal( buffFrame .. "1" ):GetParent();
	

	-- Hide all
	if( info.type ~= "none" ) then
		for i=0 , BW_MAX_BUFFS do
			BWFrames_SetUnitBuff( getglobal( buffFrame .. i + 1 ), unit, -1 );
		end
	end

	-- Show buffs
	if( info.type == "buff" ) then
		while( UnitBuff( unit, index, info.filter ) ) do
			local name = UnitBuff( unit, index );
			
			if( not BWRaid_Config.buff.showUnique or ( BWRaid_Config.buff.showUnique and not frame.DisplayedBuffs[ name ] ) ) then
				addedIndex = addedIndex + 1;
				BWFrames_SetUnitBuff( getglobal( buffFrame .. addedIndex ), unit, index, info.filter );
				
				frame.DisplayedBuffs[ name ] = true;
				
				if( addedIndex >= BW_MAX_BUFFS ) then
					break;
				end
			end
			
			index = index + 1;
		end
	
	-- Show debuffs
	elseif( info.type == "debuff" ) then
		while( UnitDebuff( unit, index, info.filter ) ) do
			local name = UnitDebuff( unit, index );
			
			if( not BWRaid_Config.buff.showUnique or ( BWRaid_Config.buff.showUnique and not frame.DisplayedDebuffs[ name ] ) ) then
				addedIndex = addedIndex + 1;
				BWFrames_SetUnitDebuff( getglobal( buffFrame .. addedIndex ), unit, index, info.filter );
				
				frame.DisplayedDebuffs[ name ] = true;

				if( addedIndex >= BW_MAX_BUFFS ) then
					break;
				end
			end
			
			index = index + 1;
		end
	
	-- Show all HoT's
	elseif( info.type == "hot" ) then
		local index = info.position;
		local addedIndex = 0;
		
		while( UnitBuff( unit, index, info.filter ) ) do
			local name = UnitBuff( unit, index );
			
			if( not BWRaid_Config.buff.showUnique or ( BWRaid_Config.buff.showUnique and not frame.DisplayedBuffs[ name ] ) ) then
				for _, hot in pairs( BWF_HOTS ) do
					if( hot == name ) then
						addedIndex = addedIndex + 1;
						BWFrames_SetUnitBuff( getglobal( buffFrame .. addedIndex ), unit, index, info.filter );
						
						frame.DisplayedBuffs[ name ] = true;
						break;
					end
				end

				if( addedIndex >= BW_MAX_BUFFS ) then
					break;
				end
			end
			
			index = index + 1;
		end
	end
end


-- Update mana bar
function BWFrames_UpdateManaBar( unit, frame )
	local manaBar = getglobal( frame:GetName() .. "ManaBar" );
	manaBar:SetMinMaxValues( 0, UnitManaMax( unit ) );
	manaBar:SetValue( UnitMana( unit ) );
	
	if( not UnitIsConnected( unit ) ) then
		manaBar:SetValue( 0 );
	end
	
	BWFrames_CheckPowerType( unit, frame );
end

-- Update health bar
function BWFrames_UpdateHealthBar( unit, frame )
	local healthBar = getglobal( frame:GetName() .. "HealthBar" );

	healthBar:SetMinMaxValues( 0, UnitHealthMax( unit ) );
	healthBar:SetValue( UnitHealth( unit ) );

	if( getglobal( frame:GetName() .. "HealthText" ) ) then
		if( BWRaid_Config.raid.healthType == "lost" ) then
			local missing = UnitHealthMax( unit ) - UnitHealth( unit );
			if( missing > 0 ) then
				getglobal( frame:GetName() .. "HealthText" ):SetText( "-" .. missing );
			else
				getglobal( frame:GetName() .. "HealthText" ):SetText( "" );		
			end

		elseif( BWRaid_Config.raid.healthType == "percent" ) then
			getglobal( frame:GetName() .. "HealthText" ):SetText( math.floor( ( UnitHealth( unit ) / UnitHealthMax( unit ) * 100 ) + 0.5 ) .. "%" );
		elseif( BWRaid_Config.raid.healthType == "crt" ) then
			getglobal( frame:GetName() .. "HealthText" ):SetText( UnitHealth( unit ) );
		elseif( BWRaid_Config.raid.healthType == "crttl" ) then
			getglobal( frame:GetName() .. "HealthText" ):SetText( UnitHealth( unit ) .. "/" .. UnitHealthMax( unit ) );
		end
	end
	
	-- They're offline, grey out the bar
	if( not UnitIsConnected( unit ) ) then
		healthBar:SetValue( UnitHealthMax( unit ) );
		healthBar:SetStatusBarColor( 0.5, 0.5, 0.5 );
	end

	BWFrames_CheckDeadStatus( unit, frame );
	
	-- Setup alerts
	if( BWRaid_Config.alert.enable and BWRaid_Config.alert.health > 0 ) then
		frame.alertHP = ( ( UnitHealth( unit ) / UnitHealthMax( unit ) * 100 ) <= BWRaid_Config.alert.health );
		
		-- Show the alert background
		if( not frame.alertShown and frame.alertHP ) then
			frame:SetBackdropColor( BWRaid_Config.alert.hpColor.r, BWRaid_Config.alert.hpColor.g, BWRaid_Config.alert.hpColor.b, 1 );
			frame.alertShown = "hp";
		
		-- Show the cure background since we no longer have a cure one
		elseif( frame.alertShown == "hp" and not frame.alertHP and frame.alertCure ) then
			BWFrames_UpdateBuffs( unit, frame );

		-- Hide the alert background
		elseif( frame.alertShown and not frame.alertCure and not frame.alertHP ) then
			frame:SetBackdropColor( 0, 0, 0, 0 );
			frame.alertShown = nil;
		end
	end
end

-- Power type check
function BWFrames_CheckPowerType( unit, frame )
	local info = ManaBarColor[ UnitPowerType( unit ) ];
	getglobal( frame:GetName() .. "ManaBar" ):SetStatusBarColor( info.r, info.g, info.b );
end

-- Dead check
function BWFrames_CheckDeadStatus( unit, frame )
	if( frame.dontColor ) then
		return;
	end
	
	if( UnitIsDeadOrGhost( unit ) or not UnitIsConnected( unit ) ) then
		getglobal( frame:GetName() .. "Name" ):SetTextColor( RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b );
		
		-- Add dead or offline if needed
		if( BWRaid_Config.raid.healthType ~= "none" and getglobal( frame:GetName() .. "HealthText" ) ) then
			if( not UnitIsConnected( unit ) ) then
				getglobal( frame:GetName() .. "HealthText" ):SetText( BWR_OFFLINE );
			else
				getglobal( frame:GetName() .. "HealthText" ):SetText( BWR_DEAD );	
			end
		end
		
		-- Clear alert
		frame.alertShown = nil;
		frame.alertCure = nil;
		frame.alertHP = nil;
		frame:SetBackdropColor( 0, 0, 0, 0 );
	else
		local _, class = UnitClass( unit );
		local color = RAID_CLASS_COLORS[ class ];
		if( color ) then
			getglobal( frame:GetName() .. "Name" ):SetTextColor( color.r, color.g, color.b );
		end
	end
end

function BWFrames_SetUnitBuff( frame, unit, index, filter )
	local _, _, texture = UnitBuff( unit, index, filter );
		
	if( texture ) then
		frame.buffType = "buff";
		frame.buffIndex = index;
		frame.buffFilter = filter;
		frame.unit = unit;
		
		getglobal( frame:GetName() .. "Border" ):SetVertexColor( 0.9, 0.9, 0.9 );
		getglobal( frame:GetName() .. "Icon" ):SetTexture( texture );
		
		frame:Show();
	else
		frame.buffType = nil;
		frame.buffIndex = nil;
		frame.buffFilter = nil;
		frame.unit = nil;
		frame:Hide();
	end
end

function BWFrames_SetUnitDebuff( frame, unit, index, filter )
	local _, _, texture, _, debuffType = UnitDebuff( unit, index, filter );
	
	if( texture ) then
		frame.buffType = "debuff";
		frame.buffIndex = index;
		frame.buffFilter = filter;
		frame.unit = unit;
		
		if( not DebuffTypeColor[ debuffType ] ) then
			debuffType = "none";
		end
		
		getglobal( frame:GetName() .. "Border" ):SetVertexColor( DebuffTypeColor[ debuffType ].r, DebuffTypeColor[ debuffType ].g, DebuffTypeColor[ debuffType ].b );
		getglobal( frame:GetName() .. "Icon" ):SetTexture( texture );
		
		frame:Show();
	else
		frame.buffType = nil;
		frame.buffIndex = nil;
		frame.buffFilter = nil;
		frame.unit = nil;
		frame:Hide();
	end
end

-- Hides all buffs and reloads them
function BWFrames_ReloadBuffs()
	BWFrames_SetBuffInfo();

	for _, frame in pairs( CreatedFrames ) do
		local raid = getglobal( frame.name );
		
		for i=1, raid.createdRows do
			local member = getglobal( raid:GetName() .. "Row" .. i );
			
			local buff = 1;
			while( getglobal( member:GetName() .. "LDebuff" .. buff ) ) do
				getglobal( member:GetName() .. "LDebuff" .. buff ):Hide();				
				getglobal( member:GetName() .. "RDebuff" .. buff ):Hide();

				buff = buff + 1;
			end
						
			if( BW_MAX_BUFFS == 1 ) then
				getglobal( member:GetName() .. "LDebuff1" ):SetPoint( "TOPLEFT", member, "TOPLEFT", -12, -4 )
				getglobal( member:GetName() .. "RDebuff1" ):SetPoint( "TOPLEFT", member, "TOPRIGHT", 0, -4 )
			else
				getglobal( member:GetName() .. "LDebuff1" ):SetPoint( "TOPLEFT", member, "TOPLEFT", -12, 2 )			
				getglobal( member:GetName() .. "RDebuff1" ):SetPoint( "TOPLEFT", member, "TOPRIGHT", 0, 2 )			
			end

			if( member.unit ) then
				BWFrames_UpdateBuffs( member.unit, member );
			end
		end
	end
	
	BWFrames_PositionFrame( "group", BWRaid_Config.raid.groupRaid );
	BWFrames_PositionFrame( "class", BWRaid_Config.raid.groupClass );
end

function BWFrames_SetBuffInfo()
	if( BWRaid_Config.raid.padding < 6 ) then
		BW_MAX_BUFFS = 1;
	else
		BW_MAX_BUFFS = 3;
	end

	LeftBuffInfo = {};
	RightBuffInfo = {};
	
	local filter = { debuff = BWRaid_Config.buff.showCurable, buff = BWRaid_Config.buff.showCastable, hot = BWRaid_Config.buff.showCastable };
	
	-- Same display types on both sides, so show 1-4 on left, 5-8 on right
	if( BWRaid_Config.buff.rightType == BWRaid_Config.buff.leftType ) then
		LeftBuffInfo = { type = BWRaid_Config.buff.leftType, position = 1, filter = filter[ BWRaid_Config.buff.leftType ] };
		RightBuffInfo = { type = BWRaid_Config.buff.rightType , position = BW_MAX_BUFFS + 2, filter = filter[ BWRaid_Config.buff.rightType ]  };
	else
		LeftBuffInfo = { type = BWRaid_Config.buff.leftType, position = 1, filter = filter[ BWRaid_Config.buff.leftType ]  };
		RightBuffInfo = { type = BWRaid_Config.buff.rightType, position = 1, filter = filter[ BWRaid_Config.buff.rightType ]  };
	end	

end

-- Changes bar style between health/mana and health only ( clean up later )
function BWFrames_ChangeBarStyle( member )
	local manaBar = getglobal( member:GetName() .. "ManaBar" );
	local manaTexture = getglobal( member:GetName() .. "ManaTexture" );
	local healthBar = getglobal( member:GetName() .. "HealthBar" );
	local healthTexture = getglobal( member:GetName() .. "HealthTexture" );

	if( BWRaid_Config.raid.healthOnly ) then
		manaTexture:Hide();
		manaBar:Hide();

		if( BWRaid_Config.raid.largeHealth --[[and BWRaid_Config.raid.padding > 5]] ) then
			healthTexture:SetHeight( 20 );
			healthBar:SetHeight( 13 );
		else
			healthTexture:SetHeight( 17 );
			healthBar:SetHeight( 10 );
		end

		member.healthOnly = true;

	elseif( not BWRaid_Config.raid.healthOnly and member.healthOnly ) then
		manaTexture:Show();
		manaBar:Show();

		healthTexture:SetHeight( 12 );
		healthBar:SetHeight( 6 );

		member.healthOnly = nil;
	end
end

-- Changes the player name style whatchamacallits
function BWFrames_ChangeFrameStyle( member, raid )
	local memberName = getglobal( member:GetName() .. "Name" );

	local manaBar = getglobal( member:GetName() .. "ManaBar" );
	local manaTexture = getglobal( member:GetName() .. "ManaTexture" );

	local healthBar = getglobal( member:GetName() .. "HealthBar" );
	local healthTexture = getglobal( member:GetName() .. "HealthTexture" );

	memberName:ClearAllPoints();

	manaTexture:ClearAllPoints();
	manaBar:ClearAllPoints();

	healthTexture:ClearAllPoints();
	healthBar:ClearAllPoints();

	if( BWRaid_Config.raid.style == "blizzard" ) then
		memberName:SetJustifyH( "CENTER" );
		memberName:SetPoint( "CENTER", member, "TOP", 0, -8 );

		local barPadding = 0;
		if( not BWRaid_Config.raid.healthOnly ) then
			barPadding = 3;
		end

		healthTexture:SetPoint( "CENTER", memberName, "CENTER", 0, -19 + barPadding );
		healthBar:SetPoint( "CENTER", memberName, "CENTER", 0, -19 + barPadding );

		manaTexture:SetPoint( "CENTER", healthTexture, "CENTER", 0, -10 );
		manaBar:SetPoint( "CENTER", healthTexture, "CENTER", 0, -10 );

		member:SetWidth( 127 );
		member:SetHeight( 40 );

		member:SetBackdrop( {	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
					tile = true,
					tileSize = 15,
					insets = { left = 7, right = 7, top = 2, bottom = 23 } } );
		
		if( not member.alertShown ) then
			member:SetBackdropColor( 0, 0, 0, 0 );
		end
	else
		memberName:SetJustifyH( "LEFT" );
		memberName:SetPoint( "TOPLEFT", member:GetName(), "TOPLEFT", 10, -7 );

		healthTexture:SetPoint( "TOPLEFT", member, "TOPLEFT", 97, 0 );
		healthBar:SetPoint( "TOPLEFT", member, "TOPLEFT", 100, -3 );

		manaTexture:SetPoint( "TOPLEFT", healthTexture, "TOPLEFT", 0, -8 );
		manaBar:SetPoint( "TOPLEFT", healthBar, "TOPLEFT", 0, -8 );

		member:SetWidth( 215 );
		member:SetHeight( 20 );

		member:SetBackdrop( {	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
					tile = true,
					tileSize = 15,
					insets = { left = 5, right = 120, top = 2, bottom = 2 } } );
		
		if( not member.alertShown ) then
			member:SetBackdropColor( 0, 0, 0, 0 );
		end
	end
	
	-- Set the group height
	if( BWRaid_Config.raid.style == "blizzard" ) then
		raid:SetWidth( 127 );
	else
		raid:SetWidth( 215 );
	end
end

-- Update our group cache
function BWFrames_UpdateRaidRoster()
	RaidGroupList = {};
	for i=1, GetNumRaidMembers() do
		local name, rank, subgroup, _, class, unlocClass, _, online, isDead = GetRaidRosterInfo( i );

		if( not RaidGroupList[ subgroup ] ) then
			RaidGroupList[ subgroup ] = {};
		end
		
		if( not RaidGroupList[ unlocClass ] and unlocClass ) then
			RaidGroupList[ unlocClass ] = {};
		end

		local data = { name = name, raidIndex = i, rank = rank, class = class, unlocClass = unlocClass, dead = isDead, online = online, unit = "raid" .. i };
		
		table.insert( RaidGroupList[ subgroup ], data );
		
		if( RaidGroupList[ unlocClass ] ) then
			table.insert( RaidGroupList[ unlocClass ], data );
		end
	end
end

function BWFrames_UpdateHealthType()
	-- Reload/reset the frame settings
	for _, frameInfo in pairs( CreatedFrames ) do
		local parentFrame = getglobal( frameInfo.name );
		
		for i=1, parentFrame.raidRows do
			local frame = getglobal( parentFrame:GetName() .. "Row" .. i );
			
			-- Update health color
			getglobal( frame:GetName() .. "HealthText" ):SetTextColor( BWRaid_Config.raid.healthColor.r, BWRaid_Config.raid.healthColor.g, BWRaid_Config.raid.healthColor.b );
			
			if( BWRaid_Config.raid.healthType == "none" or not BWRaid_Config.raid.healthOnly ) then
				getglobal( frame:GetName() .. "HealthText" ):Hide();			
			else
				getglobal( frame:GetName() .. "HealthText" ):Show();
			end
			
			BWFrames_UpdateHealthBar( frame.unit, frame );

		end
	end
end

function BWFrames_ReloadFrames()
	BWFrames_SetFramePadding();
	
	BWFrames_UpdateRaidRoster();
	BWFrames_RaidUpdated();
	
	-- Reload/reset the frame settings
	for _, frameInfo in pairs( CreatedFrames ) do
		local parentFrame = getglobal( frameInfo.name );
		
		for i=1, parentFrame.raidRows do
			local frame = getglobal( parentFrame:GetName() .. "Row" .. i );

			BWFrames_ChangeBarStyle( frame );
			BWFrames_ChangeFrameStyle( frame, parentFrame );
						
			-- Reset alerts
			frame.alertHP = nil;
			frame.alertCure = nil;
			frame.alertShown = nil;
			frame:SetBackdropColor( 0, 0, 0, 0 );
		end
		
		parentFrame:SetScale( BWRaid_Config.frame.scale );
		parentFrame:SetBackdropColor( BWRaid_Config.frame.backgroundColor.r, BWRaid_Config.frame.backgroundColor.g, BWRaid_Config.frame.backgroundColor.b, BWRaid_Config.frame.backgroundOpacity );
		parentFrame:SetBackdropBorderColor( BWRaid_Config.frame.borderColor.r, BWRaid_Config.frame.borderColor.g, BWRaid_Config.frame.borderColor.b, BWRaid_Config.frame.borderOpacity );
		parentFrame:Hide();
	end

	BWFrames_ReloadBuffs();	
	BWFrames_UpdateHealthType();

	BWFrames_PositionFrame( "group", BWRaid_Config.raid.groupRaid );
	BWFrames_PositionFrame( "class", BWRaid_Config.raid.groupClass );
end

-- Allows us to queue restricted functions when in combat
function BWFrames_SetAttribute( frame, key, value )
	if( not InCombatLockdown() ) then
		frame:SetAttribute( key, value );
	else
		table.insert( FrameQueue, { frame = frame:GetName(), key = key, value = value } );
	end
end

function BWFrames_Show( frame )
	if( not InCombatLockdown() ) then
		frame:Show();
	else
		table.insert( FrameQueue, { frame = frame:GetName(), show = true } );
	end
end

function BWFrames_Hide( frame )
	if( not InCombatLockdown() ) then
		frame:Hide();
	else
		table.insert( FrameQueue, { frame = frame:GetName(), hide = true } );
	end
end

-- Range checking
function BWFrames_SetRangeConfig()
	local _, PlayerClass = UnitClass( "player" );
	
	if( BWF_RANGETYPE[ PlayerClass ] and BWF_RANGETYPE[ PlayerClass ][ BWRaid_Config.range.type ] ) then
		RangeEnable = BWRaid_Config.range.enable;
		RangeSpell = BWF_RANGETYPE[ PlayerClass ][ BWRaid_Config.range.type ];
	else
		RangeEnable = nil;
		RangeSpell = nil;
	end
	
	-- Reset alpha
	if( not RangeEnable ) then
		for _, frameInfo in pairs( CreatedFrames ) do
			local raid = getglobal( frameInfo.name );
			
			for i=1, raid.raidRows do
				local row = getglobal( raid:GetName() .. "Row" .. i );
				row:SetAlpha( 1.0 );
			end
		end
	end
end

function BWFrames_Group_OnUpdate( elapsed )
	if( RangeEnable ) then
		local frameName = this:GetName();
		
		TimeElapsed[ frameName ] = TimeElapsed[ frameName ] + elapsed;

		if( TimeElapsed[ frameName ] > RangeCheckTime ) then
			TimeElapsed[ frameName ] = TimeElapsed[ frameName ] - RangeCheckTime;
			
			for i=1, this.raidRows do
				local row = getglobal( frameName .. "Row" .. i );

				if( IsSpellInRange( RangeSpell, row:GetAttribute( "unit" ) ) == 1 ) then
					row:SetAlpha( 1.0 );
				else
					row:SetAlpha( 0.5 );
				end
			end
		end
	end
end

-- Event handler
function BWFrames_OnEvent( event )
	if( event == "VARIABLES_LOADED" ) then
		BWFrames_SetBuffInfo();
		BWFrames_SetFramePadding();
		BWFrames_SetRangeConfig();

	elseif( event == "PLAYER_ENTERING_WORLD" ) then
		if( GetNumRaidMembers() > 0 and ( BWRaid_Config.raid.enable or ForceOpen ) and not ForceClose ) then
			BWFrames_UpdateRaidRoster();
			BWFrames_RaidUpdated();
		end
		
	elseif( event == "PLAYER_REGEN_ENABLED" ) then
		for _, frameInfo in pairs( FrameQueue ) do
			local frame = getglobal( frameInfo.frame );
		
			if( frameInfo.key )  then
				frame:SetAttribute( frameInfo.key, frameInfo.value );
			elseif( frameInfo.hide ) then
				frame:Hide();
			elseif( frameInfo.show ) then
				frame:Show();
			end
		end
		
		FrameQueue = {};
		
		if( QueueRaidUpdate ) then
			QueueRaidUpdate = nil;
			
			BWFrames_UpdateRaidRoster();
			BWFrames_RaidUpdated();
		end
		
	elseif( event == "RAID_ROSTER_UPDATE" ) then
		BWFrames_UpdateRaidRoster();
		
		if( ( BWRaid_Config.raid.enable or ForceOpen ) and not ForceClosed ) then
			BWFrames_RaidUpdated();
		end
		
		if( GetNumRaidMembers() == 0 ) then
			ForceOpen = nil;
			ForceClosed = nil;
			BWFrames_HideAll();
		end
	end
end
