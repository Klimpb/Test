local frame = CreateFrame( "Frame" )
local tooltip = CreateFrame( "GameTooltip", "FTCTooltip", frame, "GameTooltipTemplate" )

local spellReagents = {}
local buttons = {}

local L = {
	["on"] = "on",
	["off"] = "off",
	
	["No reagents have been added to the list to hide."] = "No reagents have been added to the list to hide.",
	["Added %s with no threshold set, always hiding counter."] = "Added %s with no threshold set, always hiding counter.",
	["Added %s with a threshold of %d to the list of reagent counts to hide."] = "Added %s with a threshold of %d to the list of reagent counts to hide.",
	["Removed threshold on %s, always hiding counter."] = "Removed threshold on %s, always hiding counter.",
	["Updated threshold on %s, set to %s."] = "Updated threshold on %s, set to %s.",
	["Removed reagent counter hiding on %s."] = "Removed reagent counter hiding on %s.",
	["Removed reagent counter hiding on %s (#%d)."] = "Removed reagent counter hiding on %s (#%d).",
	["Cannot find any reagent with the id #%d"] = "Cannot find any reagent with the id #%d",
	["#%d: %s, no threshold."] = "#%d: %s, no threshold.",
	["#%d: %s, threshold %d."] = "#%d: %s, threshold %d.",
	["All saved reagents have been removed."] = "All saved reagents have been removed.",
	

	["/ftc list - View a list of reagents to hide the counter."] = "/ftc list - View a list of reagents to hide the counter.",
	["/ftc add <reagent> <threshold> - Add a reagent with a set number to reshow it at, use 0 to always hide."] = "/ftc add <reagent> <threshold> - Add a reagent with a set number to reshow it at, use 0 to always hide.",
	["/ftc upd <reagent> <threshold> - Updates a specific reagents threshold."] = "/ftc upd <reagent> <threshold> - Updates a specific reagents threshold.",
	["/ftc rmv <reagent> or <reagent id> - Removes the specified reagent using either name or id."] = "/ftc rmv <reagent> or <reagent id> - Removes the specified reagent using either name or id.",
	["/ftc clear - Clears all saved reagent counters."] = "/ftc clear - Clears all saved reagent counters.",

	["Reagents"] = "Reagents",
	["FTC"] = "FTC",
}

--[[
if( GetLocale() == "deDE" ) then

elseif( GetLocale() == "frFR" ) then

end
]]

local function Print( msg )
	DEFAULT_CHAT_FRAME:AddMessage( "|cFF33FF99" .. L["FTC"] .. "|r: " .. msg )
end

local function CheckActionButton( actionID, frame )
	if( IsConsumableAction( actionID ) or IsStackableAction( actionID ) ) then
		local type, spellID = GetActionInfo( actionID )

		if( type == "spell" ) then
			local count = GetActionCount( actionID )
			local spellName = GetSpellName( spellID, BOOKTYPE_SPELL )
			local reagent = spellReagents[ spellName ]

			if( reagent and FTC_Config.list[ reagent ] and ( FTC_Config.list[ reagent ] == 0 or FTC_Config.list[ reagent ] <= count ) ) then
				getglobal( frame:GetName() .. "Count" ):Hide()
			else
				getglobal( frame:GetName() .. "Count" ):Show()
			end
			
			buttons[ frame ] = true
		end
	end
end

local function HideCount()
	CheckActionButton( ActionButton_GetPagedID( this ), this )
end

function CacheReagents()
	for k in pairs(spellReagents) do
		spellReagents[k] = nil
	end

	-- Loop-o-doom
	for book=1, MAX_SKILLLINE_TABS do
	    local _, _, offset, numSpells = GetSpellTabInfo( book )

	    for i=1, numSpells do
		tooltip:SetSpell( offset + i, BOOKTYPE_SPELL )

		for j=1, tooltip:NumLines() do
			text = getglobal( tooltip:GetName() .. "TextLeft" .. j ):GetText()

			if( string.match( text, "^" .. L["Reagents"] ) ) then
				local _, reagent = string.split( "|n", text )
				spellReagents[ ( GetSpellName( offset + i, BOOKTYPE_SPELL ) ) ] = string.lower( reagent )
				break
			end
		end
	    end
	end
end

local function CheckCountHiding()
	local actionID
	for button, _ in pairs( buttons ) do
		actionID = ActionButton_GetPagedID( button )
		if( HasAction( actionID ) ) then
			CheckActionButton( actionID, button )
		end
	end
end

local function OnEvent()
	if( event == "ADDON_LOADED" and arg1 == "ForgetTwoCount" ) then
		if( not FTC_Config ) then
			FTC_Config = { list = {} }
		end

		SLASH_REGBLOCK1 = "/ftc"
		SLASH_REGBLOCK2 = "/regblock"
		SLASH_REGBLOCK3 = "/reghide"
		SlashCmdList["REGBLOCK"] = function( msg )
			if( not msg or msg == "" ) then
				DEFAULT_CHAT_FRAME:AddMessage( L["/ftc list - View a list of reagents to hide the counter."] )
				DEFAULT_CHAT_FRAME:AddMessage( L["/ftc add <reagent> <threshold> - Add a reagent with a set number to reshow it at, use 0 to always hide."] )
				DEFAULT_CHAT_FRAME:AddMessage( L["/ftc upd <reagent> <threshold> - Updates a specific reagents threshold."] )
				DEFAULT_CHAT_FRAME:AddMessage( L["/ftc rmv <reagent> or <reagent id> - Removes the specified reagent using either name or id."] )
				DEFAULT_CHAT_FRAME:AddMessage( L["/ftc clear - Clears all saved reagent counters."] )
				return
			end
			
			msg = string.lower( msg )
			
			if( msg == "list" ) then
				local total = 0
				
				for reagent, threshold in pairs( FTC_Config.list ) do
					total = total + 1
					
					if( threshold == 0 ) then
						DEFAULT_CHAT_FRAME:AddMessage( string.format( L["#%d: %s, no threshold."], total, reagent ) )
					else
						DEFAULT_CHAT_FRAME:AddMessage( string.format( L["#%d: %s, threshold %d."], total, reagent, threshold) )
					end
				end
				
				if( total == 0 ) then
					Print( L["No reagents have been added to the list to hide."] )
				end
			
			elseif( msg == "clear" ) then
				FTC_Config.list = {}
				CheckCountHiding()
				
				Print( L["All saved reagents have been removed."] )
			
			-- Yes these 3 are the same thing, shhhhhhh
			elseif( string.match( msg, "add (.+) ([0-9]+)" ) ) then
				local reagent, threshold = string.match( msg, "add (.+) ([0-9]+)" )
				threshold = tonumber( threshold ) or 0
				
				if( threshold < 0 ) then
					threshold = 0
				end
				
				FTC_Config.list[ string.lower( reagent ) ] = threshold
				
				if( threshold > 0 ) then
					Print( string.format( L["Added %s with a threshold of %d to the list of reagent counts to hide."], reagent, threshold ) )
				else
					Print( string.format( L["Added %s with no threshold set, always hiding counter."], reagent ) )
				end

				CheckCountHiding()

			elseif( string.match( msg, "add (.+)" ) ) then
				local reagent = string.match( msg, "add (.+)" )
				
				FTC_Config.list[ string.lower( reagent ) ] = 0
				Print( string.format( L["Added %s with no threshold set, always hiding counter."], reagent ) )

				CheckCountHiding()

			elseif( string.match( msg, "upd (.+) ([0-9]+)" ) ) then
				local reagent, threshold = string.match( msg, "upd (.+) ([0-9]+)" )
				threshold = tonumber( threshold ) or 0
				
				if( threshold < 0 ) then
					threshold = 0
				end
				
				FTC_Config.list[ string.lower( reagent ) ] = threshold
				
				if( threshold > 0 ) then
					Print( string.format( L["Updated threshold on %s, set to %s."], reagent, threshold ) )
				else
					Print( string.format( L["Removed threshold on %s, always hiding counter."], reagent ) )
				end
				
				CheckCountHiding()

			elseif( string.match( msg, "rmv ([0-9]+)" ) ) then
				local reagentID = string.match( msg, "rmv ([0-9]+)" )
				local i = 0
				
				reagentID = tonumber( reagentID ) or 0
				
				for reagent, threshold in pairs( FTC_Config.list ) do
					i = i + 1
					if( i == reagentID ) then
						Print( string.format( L["Removed reagent counter hiding on %s (#%d)."], reagent, i ) )
						return
					end
				end
				
				Print( string.format( L["Cannot find any reagent with the id #%d"], reagentID ) )

				CheckCountHiding()
			
			elseif( string.match( msg, "rmv (.+)" ) ) then
				local reagent = string.match( msg, "rmv (.+)" )
				
				FTC_Config.list[ reagent ] = nil
				Print( string.format( L["Removed reagent counter hiding on %s."], reagent ) )
				
				CheckCountHiding()
			end
		end
				
		hooksecurefunc( "ActionButton_UpdateCount", HideCount )

		CacheReagents()
	
	-- New spell learn, recheck list
	elseif( event == "LEARNED_SPELL_IN_TAB" or event == "SPELLS_CHANGED" ) then
		CacheReagents()
	end
end

tooltip:SetOwner( frame, "ANCHOR_NONE" )

frame:SetScript( "OnEvent", OnEvent )
frame:SetScript( "OnUpdate", OnUpdate )

frame:RegisterEvent( "ADDON_LOADED" )
frame:RegisterEvent( "LEARNED_SPELL_IN_TAB" )
frame:RegisterEvent( "SPELLS_CHANGED" )