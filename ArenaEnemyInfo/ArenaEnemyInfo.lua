AEI = {};

local enemies = {};

local frame = CreateFrame( "Frame" );

function AEI:BGMessage( msg )
	if( GetNumRaidMembers() > 0 or GetNumPartyMembers() > 0 ) then
		SendChatMessage( msg, "BATTLEGROUND" );
	end
end

function AEI:OnEvent( event )
	if( event == "ADDON_LOADED" and arg1 == "ArenaEnemyInfo" ) then
		if( not AEI_NoDataID ) then
			AEI_NoDataID = 0;
		end

		if( not AEI_NoData ) then
			AEI_NoData = {};
		end
	
	elseif( event == "ADDON_LOADED" and addon == "AEI_Data" and AEI_NoDataID == AEI_DataID ) then
		AEI_NoData = {};
		
	elseif( event == "CHAT_MSG_ADDON" and arg1 == "SSPVP" and not IsAddOnLoaded( "SSPVP" ) ) then
		local _, _, dataType, data = string.find( msg, "([^:]+)%:(.+)" );

		if( dataType and data and dataType == "ENEMY" ) then
			local name, server, race, classToken, guild = string.split( ",", data );

			for _, enemy in pairs( enemies ) do
				if( enemy.name == name ) then
					return;
				end
			end

			table.insert( enemies, { name = name, server = server, race = race, classToken = classToken, guild = guild } );
		end
	elseif( event == "UPDATE_MOUSEOVER_UNIT" and ( IsActiveBattlefieldArena() ) ) then
		if( UnitIsPlayer( "mouseover" ) and UnitIsEnemy( "mouseover", "player" ) and UnitIsPVP( "mouseover" ) ) then
			local name, server = UnitName( "mouseover" );
			server = ( server or GetRealmName() );

			if( not AEI_Data[ name .. "-" .. server ] ) then
				for _, noSpec in pairs( AEI_NoData ) do
					if( noSpec == name .. "-" .. server ) then
						return;
					end
				end

				AEI_NoDataID = floor( GetTime() );
				table.insert( AEI_NoData, name .. "-" .. server );
			end

			-- SSPVP 3 has built in support for this so don't send duplicate messages
			if( IsAddOnLoaded( "SSPVP" ) ) then
				return;
			end

			for _, enemy in pairs( enemies ) do
				if( enemy.name == name ) then
					return;
				end
			end

			local race = UnitRace( "mouseover" );
			local class, classToken = UnitClass( "mouseover" );
			local guild = GetGuildInfo( "mouseover" );
			local spec = "";

			table.insert( enemies, { name = name, server = server, race = race, classToken = classToken, guild = guild } );

			if( AEI_Data[ name .. "-" .. server ] ) then
				spec = " /" .. AEI:GetSpec( name, server );
			end

			-- Print out info message
			if( guild ) then
				AEI:BGMessage( string.format( "%s / %s / %s / %s / %s", name, class, race, guild, server ) .. spec );
				SendAddonMessage( "SSPVP", "ENEMY:" .. name .. "," .. server .. "," .. race .. "," .. classToken .. "," .. guild, "BATTLEGROUND" );
			else
				AEI:BGMessage( string.format( "%s / %s / %s / %s", name, class, race, server ) .. spec );				
				SendAddonMessage( "SSPVP", "ENEMY:" .. name .. "," .. server .. "," .. race .. "," .. classToken, "BATTLEGROUND" );
			end
		end
	end
end


-- Get the formatted spec as " [##/##/##]" if found
function AEI:GetSpec( name, server )
	name = name .. "-" .. server;
	
	
	if( AEI_Data[ name ] ) then
		local point1, point2, point3 = string.split( ":", AEI_Data[ name ] );
		return " [" .. point1 .. "/" .. point2 .. "/" .. point3 .. "]";
	end
	
	return "";
end

-- Gets the actual spec numbers if you want to use your own formatting
function AEI:GetTalents( name, server )
	name = name .. "-" .. server;
	
	if( AEI_Data[ name ] ) then
		return string.split( ":", AEI_Data[ name ] );
	end
	
	return 0, 0, 0;
end

frame:SetScript( "OnEvent", AEI.OnEvent );
frame:RegisterEvent( "ADDON_LOADED" );
frame:RegisterEvent( "CHAT_MSG_ADDON" );
frame:RegisterEvent( "UPDATE_MOUSEOVER_UNIT" );