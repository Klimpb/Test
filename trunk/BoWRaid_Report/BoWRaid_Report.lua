local CombatHistory = {};

local CombatStart = 0;
local CombatEnd = 0;
local IsInCombat;

-- Combat searchs
local Regex_BuffGained;
local Regex_BuffFaded;
local Regex_BuffRemoved;
local Regex_HealHit;
local Regex_HealCrit;
local Regex_MeleeHit;
local Regex_MeleeCrit;
local Regex_SpellHit;
local Regex_SpellCrit;
local Regex_Suffer;
local Regex_SelfSuffer;
local Regex_HoTHeal;
local Regex_SelfHoTHeal;
local Regex_SelfHoTHeal2;
local Regex_BuffBlockGain;
local Regex_SelfAfflicted;

function BWReport_OnLoad()
	this:RegisterEvent( "VARIABLES_LOADED" );
	
	this:RegisterEvent( "CHAT_MSG_WHISPER" );
	
	this:RegisterEvent( "PLAYER_REGEN_DISABLED" );
	this:RegisterEvent( "PLAYER_REGEN_ENABLED" );
	
	this:RegisterEvent( "CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS" );
	this:RegisterEvent( "CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE" );

	this:RegisterEvent( "CHAT_MSG_SPELL_HOSTILEPLAYER_BUFF" );
	this:RegisterEvent( "CHAT_MSG_SPELL_SELF_BUFF" );
	
	this:RegisterEvent( "CHAT_MSG_SPELL_AURA_GONE_SELF" );
	this:RegisterEvent( "CHAT_MSG_SPELL_BREAK_AURA" );

	this:RegisterEvent( "CHAT_MSG_SPELL_CREATURE_VS_SELF_DAMAGE" );
	this:RegisterEvent( "CHAT_MSG_SPELL_CREATURE_VS_SELF_MISSES" );
     	this:RegisterEvent( "CHAT_MSG_SPELL_CREATURE_VS_SELF_HITS" );

	this:RegisterEvent( "CHAT_MSG_COMBAT_CREATURE_VS_SELF_MISSES" );
     	this:RegisterEvent( "CHAT_MSG_COMBAT_CREATURE_VS_SELF_HITS" );
		
	SLASH_BWREPORT1 = "/report";
	SlashCmdList["BWREPORT"] = BWReport_HistoryCommand;
	
	SLASH_REQREPORT1 = "/reqreport";
	SlashCmdList["REQREPORT"] = BWReport_SendReportRequest;
end

-- Request report
function BWReport_SendReportRequest( msg )
	if( not msg or msg == "" ) then
		BWRaid_Message( BWR_NO_INFO, ChatTypeInfo["SYSTEM"] );
		return;
	end
	
	local _, _, name, timeBack = string.find( msg, "(.+) ([0-9]+)" );
	
	if( not name or not timeBack ) then
		BWRaid_Message( BWR_NO_INFO, ChatTypeInfo["SYSTEM"] );
		return;		
	end
	
	BWOverlay_SortHigh( false );
	BWOverlay_RemoveAll();
	SendChatMessage( "[BW] REQREPORT: " .. timeBack, "WHISPER", nil, name );
	BWRaid_Message( string.format( BWR_REPORT_SENT, name, timeBack ), ChatTypeInfo["SYSTEM"] );
end


-- Slash handler for history
function BWReport_HistoryCommand( msg )
	if( not msg or msg == "" ) then
		BWRaid_Message( BWR_HISTORY_OPTIONS, ChatTypeInfo["SYSTEM"] );
		return;
	end

	local _, _, channel, timeBack = string.find( msg, "(.+) ([0-9]+)" );
	channel = string.upper( channel );
	timeBack = tonumber( timeBack );
	
	local channNumber = GetChannelName( channel );
	
	if( channel ~= "CONSOLE" and channel ~= "RAID" and channel ~= "PARTY" and channel ~= "GUILD" and channel ~= "OFFICER" and channNumber == 0 ) then
		BWRaid_Message( BWR_HISTORY_INVALID_CHANN, ChatTypeInfo["SYSTEM"] );
		return;
	end
	
	local messages = BWReport_History( timeBack );
	
	for _, message in pairs( messages ) do
		if( channNumber > 0 ) then
			SendChatMessage( message, "CHANNEL", nil, channNumber );
		elseif( channel == "CONSOLE" ) then
			BWRaid_Message( message );
		else
			SendChatMessage( message, channel );
		end
	end
end

-- Does the actual history parsing/returning
function BWReport_History( timeBack )
	if( not timeBack or timeBack <= 0 ) then
		timeBack = 10;
	end
	
	local Messages = {};
	local TotalDamage = 0;
	local TotalHealing = 0;
	local TotalCombatSeconds = 0;
	local CutoffTime;
	local CombatTime;
	local CombatEnded;
	
	if( IsInCombat ) then
		CombatTime = GetTime() - CombatStart;
		CutoffTime = GetTime() - timeBack;
		CombatEnded = GetTime();
	else
		CombatTime = CombatEnd - CombatStart;
		CutoffTime = CombatEnd - timeBack;
		CombatEnded = CombatEnd;
	end
	
	if( CombatTime <= 0 ) then
		return { string.format( BWR_NO_HISTORY_FOUND, timeBack ) };
	end
	
	if( CombatTime > timeBack ) then
		CombatTime = timeBack;
	end
	
	table.insert( Messages, BWR_REPORT_HEADER );

	local HealingSearch = { Regex_HealHit, Regex_HealCrit, Regex_SelfHeal, Regex_SelfCritHeal };
	local DamageSearch = { Regex_MeleeHit, Regex_MeleeCrit, Regex_SpellHit, Regex_SpellCrit };
	local AuraSearch = { Regex_SelfSuffer, Regex_Suffer };
	local HoTHealSearch = { Regex_HoTHeal, Regex_SelfHoTHeal, Regex_SelfHoTHeal2 };
	local GeneralSearch = { Regex_BuffGained, Regex_BuffFaded, Regex_BuffRemoved };
		
	for i=1, table.getn( CombatHistory ) do
		local combat = CombatHistory[ i ];
		
		if( combat.time >= CutoffTime and combat.time <= CombatEnded ) then
			local FoundEvent = nil;
			
			-- Is it damage?
			for _, text in pairs( DamageSearch ) do
				if( string.find( combat.text, text ) ) then
					local _, _, _, amount = string.find( combat.text, text );
					
					TotalDamage = TotalDamage + amount;
					FoundEvent = true;
					break;
				end
			end

			-- Is it healing?
			for _, text in pairs( HealingSearch ) do
				if( string.find( combat.text, text ) ) then
					local _, _, ability, amount1, amount2 = string.find( combat.text, text );
					local healAmount = tonumber( amount2 or amount1 );
					
					-- Only display heals above 100
					if( healAmount and healAmount >= 100 ) then
						TotalHealing = TotalHealing + healAmount;
						FoundEvent = true;
						break;
					end
				end
			end
			
			-- HoT Heal?
			for _, text in pairs( HoTHealSearch ) do
				if( string.find( combat.text, text ) ) then
					local _, _, amount, type = string.find( combat.text, text );
					
					-- Only display heals above 100
					amount = tonumber( amount );
					if( amount and amount >= 100 ) then
						TotalHealing = TotalHealing + amount;
						FoundEvent = true;
						break;
					end
				end
			end
					
			-- Maybe aura damage?
			for _, text in pairs( AuraSearch ) do
				if( string.find( combat.text, text ) ) then
					local _, _, amount = string.find( combat.text, text );
					
					TotalDamage = TotalDamage + amount;
					FoundEvent = true;
					break;
				end
			end
			
			if( not FoundEvent ) then
				for _, text in pairs( GeneralSearch ) do
					if( string.find( combat.text, text ) ) then
						FoundEvent = true;
						break;
					end
				end
				
				-- Hack
				if( string.find( combat.text, Regex_BuffGained ) and string.find( combat.text, Regex_BuffBlockGain ) ) then
					FoundEvent = nil;
				end
			end
			
			if( FoundEvent ) then
				table.insert( Messages, string.format( BWR_REPORT_ROW, BWReport_SecondsToTime( CombatEnded - combat.time ),  combat.health, combat.text ) );
			end
		end
	end
	
	table.insert( Messages, BWR_REPORT_FOOTER );
	table.insert( Messages, string.format( BWR_REPORT_INFO, timeBack, CombatTime ) );
	table.insert( Messages, string.format( BWR_REPORT_HEALING, TotalHealing, tonumber( TotalHealing / CombatTime ) ) );
	table.insert( Messages, string.format( BWR_REPORT_DAMAGE, TotalDamage, tonumber( TotalDamage / CombatTime ) ) );
	
	return Messages;
end

function BWReport_SecondsToTime( seconds )
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
end

-- Removes any history thats over 10 minutes old (i hope)
function BWReport_CheckHistory()
	local removeTime = GetTime() - 600;
	
	for i=table.getn( CombatHistory ), 0, -1 do
		if( CombatHistory[ i ] and CombatHistory[ i ].time <= removeTime ) then
			table.remove( CombatHistory, i );
		end
	end
	
	BWRaid_ScheduleEvent( "BWReport_CheckHistory", 600 );
end

function BWReport_SendQueueWhisper( whisper )
	SendChatMessage( whisper.msg, "WHISPER", nil, whisper.target );
end

function BWReport_OnEvent( event )
	if( event == "VARIABLES_LOADED" ) then
		
		-- Setup the combat regex
		Regex_BuffGained = BWRaid_ParseString( AURAADDEDSELFHELPFUL );
		Regex_BuffFaded = BWRaid_ParseString( AURAREMOVEDSELF );
		Regex_BuffRemoved = BWRaid_ParseString( AURADISPELSELF );
		Regex_HealHit = BWRaid_ParseString( HEALEDOTHERSELF );
		Regex_HealCrit = BWRaid_ParseString( HEALEDCRITOTHERSELF );
		Regex_MeleeHit = BWRaid_ParseString( COMBATHITOTHERSELF );
		Regex_MeleeCrit = BWRaid_ParseString( COMBATHITCRITOTHERSELF );
		Regex_SpellHit = BWRaid_ParseString( COMBATHITSCHOOLOTHERSELF );
		Regex_SpellCrit = BWRaid_ParseString( COMBATHITCRITSCHOOLOTHERSELF );
		Regex_Suffer = BWRaid_ParseString( PERIODICAURADAMAGEOTHERSELF );
		Regex_SelfSuffer = BWRaid_ParseString( PERIODICAURADAMAGESELFSELF );
		Regex_SelfHeal = BWRaid_ParseString( HEALEDSELFSELF );
		Regex_SelfCritHeal = BWRaid_ParseString( HEALEDCRITSELFSELF );
		Regex_HoTHeal = BWRaid_ParseString( PERIODICAURAHEALOTHERSELF );
		Regex_SelfHoTHeal = BWRaid_ParseString( PERIODICAURAHEALSELFSELF );
		Regex_SelfHotHeal2 = BWRaid_ParseString( PERIODICAURAHEALSELFOTHER );
		Regex_BuffBlockGain = BWRaid_ParseString( POWERGAINSELFSELF );
		Regex_SelfAfflicted = BWRaid_ParseString( AURAADDEDSELFHARMFUL );
		
		
		-- Start history check
		BWRaid_ScheduleEvent( "BWReport_CheckHistory", 600 );
	
	elseif( event == "PLAYER_REGEN_ENABLED" ) then
		IsInCombat = nil;
		CombatEnd = GetTime();
	
	elseif( event == "PLAYER_REGEN_DISABLED" ) then
		IsInCombat = true;
		CombatStart = GetTime();
	
	elseif( event == "CHAT_MSG_WHISPER" ) then
		-- Report requested
		if( string.sub( arg1, 0, 15 ) == "[BW] REQREPORT:" and BWRaid_UserHasPermission( arg2 ) ) then
			local timeBack = tonumber( string.sub( arg1, 17 ) );
			if( timeBack and timeBack > 0 ) then
				BWRaid_Message( string.format( BWR_REPORT_REQUESTED, string.sub( arg1, 17 ), arg2 ), ChatTypeInfo["SYSTEM"] );
				
				local history = BWReport_History( timeBack );
				local delay = 0;

				-- How many lines we're sending (not used, incase we need to use it later on)
				SendChatMessage( "[BW]LINES: " .. #( history ), "WHISPER", nil, arg2 );

				-- Sends a line every 0.05 seconds per a line, 0.05 first, 0.1 second, 1.05 third, ect
				for i=1, #( history ) do
					delay = delay + 0.05;				
					BWRaid_ScheduleEvent( BWReport_SendQueueWhisper, delay, { target = arg2, msg = "[BW][R:" .. i .. "]" .. history[i] } );
				end
			end

		-- Report sent back, remove the tag crap and add the prefix.
		elseif( string.sub( arg1, 0, 7 ) == "[BW][R:" ) then
			local _, _, index, message = string.find( arg1, "%[BW%]%[R%:([0-9]+)%](.+)" );

			index = tonumber( index );
			if( index and message ~= "END" ) then
				BWOverlay_AddRow( { text = message, sortID = index } );
			end
		end
		
	elseif( string.find( event, "CHAT_MSG" ) ) then
		table.insert( CombatHistory, { time = GetTime(), health = UnitHealth( "player" ), text = arg1 } );
	end
end