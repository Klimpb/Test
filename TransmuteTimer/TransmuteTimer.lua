local frame = CreateFrame( "Frame" );

local realmName;
local playerFaction;
local playerName;

local almostReady = 0;

local L = {
	["on"] = "on",
	["off"] = "off",

	["Timer ready for %s - %s, %s."] = "Timer ready for %s - %s, %s.",
	["Transmute"] = "Transmute",

	["/transmute interval <seconds> - Seconds inbetween checks for timers."] = "/transmute interval <seconds> - Seconds inbetween checks for timers.",
	["/transmute cross - Toggles checking for characters on other servers."] = "/transmute cross - Toggles checking for characters on other servers.",
	["/transmute char - Toggles checking for different characters you aren't on"] = "/transmute char - Toggles checking for different characters you aren't on",
	["/transmute check - Lists time left on all transmutes."] = "/transmute check - Lists time left on all transmutes.",
	
	["%s - %s, %s: %s"] = "%s - %s, %s: %s",
	["Cross-server checking is now %s."] = "Cross-server checking is now %s.",
	["Same character checking is now %s."] = "Same character checking is now %s.",
};

--[[
if( GetLocale() == "deDE" ) then

elseif( GetLocale() == "frFR" ) then

end
]]

local function Print( msg )
	DEFAULT_CHAT_FRAME:AddMessage( "|cFF33FF99" .. L["Transmute"] .. "|r: " .. msg );
end

local function CheckTimers()
	local crtTime = time();
	almostReady = 0;
	
	for realm, timers in pairs( TransmuteTimers ) do
		if( TT_Config.crossServer or ( not TT_Config.crossServer and realm == realmName ) ) then
			for i=#( timers ), 1, -1 do
				if( TT_Config.crossChar or ( not TT_Config.crossChar and playerName == timers[ i ].name ) ) then
					if( timers[ i ].ready <= crtTime ) then
						Print( string.format( L["Timer ready for %s - %s, %s."], timers[ i ].name, realm, timers[ i ].faction ) );
						UIErrorsFrame:AddMessage( string.format( L["Timer ready for %s - %s, %s."], timers[ i ].name, realm, timers[ i ].faction ), 1, 0, 0 );

						table.remove( timers, i );
					elseif( ( timers[ i ].ready - crtTime ) <= 120 ) then
						almostReady = almostReady + 1;
					end
				end
			end

			TransmuteTimers[ realm ] = timers;
		end
	end
end

local function OnEvent()
	if( event == "ADDON_LOADED" and arg1 == "TransmuteTimer" ) then
		if( not TT_Config ) then
			TT_Config = { interval = 60, crossServer = true, crossFaction = true, crossChar = true };
		end

		SLASH_TRANSMUTETIME1 = "/transmute";
		SLASH_TRANSMUTETIME2 = "/transmutetimer";
		SLASH_TRANSMUTETIME3 = "/transmute";
		SlashCmdList["TRANSMUTETIME"] = function( msg )
			if( not msg or msg == "" ) then
				DEFAULT_CHAT_FRAME:AddMessage( L["/transmute interval <seconds> - Seconds inbetween checks for timers."] );
				DEFAULT_CHAT_FRAME:AddMessage( L["/transmute cross - Toggles checking for characters on other servers."] );
				DEFAULT_CHAT_FRAME:AddMessage( L["/transmute char - Toggles checking for different characters you aren't on"] );
				DEFAULT_CHAT_FRAME:AddMessage( L["/transmute check - Lists time left on all transmutes."] );
			
			elseif( msg == "check" ) then
				local crtTime = time();
				
				for realm, timers in pairs( TransmuteTimers ) do
					for i=#( timers ), 1, -1 do
						if( timers[ i ].ready <= crtTime ) then
							DEFAULT_CHAT_FRAME:AddMessage( string.format( L["Timer ready for %s - %s, %s."], timers[ i ].name, realm, timers[ i ].faction ) );
						else
							DEFAULT_CHAT_FRAME:AddMessage( string.format( L["%s - %s, %s: %s"], timers[ i ].name, realm, timers[ i ].faction, SecondsToTime( timers[ i ].ready - crtTime ) ) );
						end
					end
				end
				
			elseif( string.match( msg, "interval (%d+)" ) ) then
				Print( string.format( L["Check interval set to %d."], tonumber( string.match( msg, "interval (%d+)" ) ) ) );
			
			elseif( msg == "cross" ) then
				TT_Config.crossServer = not TT_Config.crossServer;
				local status = L["on"];
				if( not TT_Config.crossServer ) then
					status = L["off"];	
				end
				
				Print( string.format( L["Cross-server checking is now %s."], status ) );
			
			elseif( msg == "char" ) then
				TT_Config.crossChar = not TT_Config.crossChar;
				local status = L["on"];
				if( not TT_Config.crossChar ) then
					status = L["off"];	
				end
				
				Print( string.format( L["Same character checking is now %s."], status ) );
			end
		end
		
		-- Setup the transmute list fun-o-fun
		realmName = GetRealmName();
		playerFaction = UnitFactionGroup( "player" );
		playerName = UnitName( "player" );
		
		if( not TransmuteTimers ) then
			TransmuteTimers = {};
		end

		if( not TransmuteTimers[ realmName ] ) then
			TransmuteTimers[ realmName ] = {};
		end
		
		CheckTimers();
		
	elseif( event == "TRADE_SKILL_UPDATE" or event == "TRADE_SKILL_UPDATE" ) then
		local cooldown;
		for i=1, GetNumTradeSkills() do
			cooldown = GetTradeSkillCooldown( i );
			if( cooldown ) then
				for id, timer in pairs( TransmuteTimers[ realmName ] ) do
					if( timer.name == playerName ) then
						TransmuteTimers[ realmName ][ id ].ready = time() + cooldown;
						return;
					end
				end
				
				table.insert( TransmuteTimers[ realmName ], { name = playerName, faction = playerFaction, ready = time() + cooldown } );
				return;
			end
		end
	end
end

local elapsed = 0;
local readyElapsed = 0;
local function OnUpdate()
	elapsed = elapsed + arg1;

	if( almostReady > 0 ) then
		readyElapsed = readyElapsed + arg1;
		
		if( readyElapsed > 5 ) then
			readyElapsed = 0;
			CheckTimers();
			return;
		end
	end
	
	if( elapsed >= TT_Config.interval ) then
		elapsed = 0;
		CheckTimers();
	end
end

frame:SetScript( "OnEvent", OnEvent );
frame:SetScript( "OnUpdate", OnUpdate );

frame:RegisterEvent( "ADDON_LOADED" );
frame:RegisterEvent( "TRADE_SKILL_SHOW" );
frame:RegisterEvent( "TRADE_SKILL_UPDATE" );