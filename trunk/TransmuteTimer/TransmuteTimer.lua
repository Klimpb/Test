local frame = CreateFrame( "Frame" )

local realmName
local playerFaction
local playerName

local almostReady = 0

local L = {
	["on"] = "on",
	["off"] = "off",

	["%s timer ready for %s - %s, %s."] = "%s timer ready for %s - %s, %s.",
	["Transmute"] = "Transmute",
	
	["/transmute tailor - Toggles transmute timer support for tailoring"] = "/transmute tailor - Toggles transmute timer support for tailoring",
	["/transmute alchemy - Toggles transmute timer support for alchemy"] = "/transmute alchemy - Toggles transmute timer support for alchemy",
	["/trasnmute jc - Toggles transmute timer support for jewelcrafting"] = "/trasnmute jc - Toggles transmute timer support for jewelcrafting",
	["/transmute cross - Toggles checking for characters on other servers"] = "/transmute cross - Toggles checking for characters on other servers",
	["/transmute char - Toggles checking for different characters you aren't on"] = "/transmute char - Toggles checking for different characters you aren't on",
	["/transmute check - Lists time left on all transmutes"] = "/transmute check - Lists time left on all transmutes",
	
	["%s, %s - %s, %s, %s"] = "%s, %s - %s, %s, %s",
	["Jewelcrafting transmute tracking is now %s."] = "Jewelcrafting transmute tracking is now %s.",
	["Alchemy transmute tracking is now %s."] = "Alchemy transmute tracking is now %s.",
	["Tailoring transmute tracking is now %s."] = "Tailoring transmute tracking is now %s.",
	["Cross-server checking is now %s."] = "Cross-server checking is now %s.",
	["Same character checking is now %s."] = "Same character checking is now %s.",
	
	["Alchemy"] = "Alchemy",
	["Tailoring"] = "Tailoring",
	["Jewelcrafting"] = "Jewelcrafting",
	["You do not have any transmute timers saved!"] = "You do not have any transmute timers saved!",
}

--[[
if( GetLocale() == "deDE" ) then

elseif( GetLocale() == "frFR" ) then

end
]]

local function Print(msg)
	DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99" .. L["Transmute"] .. "|r: " .. msg)
end

local function CheckTimers()
	local crtTime = time()
	almostReady = 0
	
	for realm, timers in pairs(TransmuteTimers) do
		if( TT_Config.crossServer or ( not TT_Config.crossServer and realm == realmName ) ) then
			for i=#(timers), 1, -1 do
				local timer = timers[i]
				if( TT_Config.crossChar or ( not TT_Config.crossChar and playerName == timer.name ) ) then
					if( timer.ready <= crtTime ) then
						local type = L["Alchemy"]
						if( timer.type == "tailor" ) then
							type = L["Tailoring"]
						elseif( timer.type == "jc" ) then
							type = L["Jewelcrafting"]
						end
					
						Print(string.format(L["%s timer ready for %s - %s, %s."], type, timer.name, realm, timer.faction))
						UIErrorsFrame:AddMessage(string.format(L["%s timer ready for %s - %s, %s."], type, timer.name, realm, timer.faction ), 1, 0, 0)

						table.remove(timers, i)
					elseif( ( timer.ready - crtTime ) <= 130 ) then
						almostReady = almostReady + 1
					end
				end
			end

			TransmuteTimers[realm] = timers
		end
	end
end

local function OnEvent()
	if( event == "ADDON_LOADED" and arg1 == "TransmuteTimer" ) then
		if( not TT_Config ) then
			TT_Config = { interval = 120, tailor = true, alchemy = true, jc = true, crossServer = true, crossFaction = true, crossChar = true }
		end
			
		-- Setup the transmute list fun-o-fun
		realmName = GetRealmName()
		playerFaction = UnitFactionGroup("player")
		playerName = UnitName("player")
		
		if( not TransmuteTimers ) then
			TransmuteTimers = {}
		end

		if( not TransmuteTimers[realmName] ) then
			TransmuteTimers[realmName] = {}
		end

		CheckTimers()
		
	elseif( event == "TRADE_SKILL_UPDATE" or event == "TRADE_SKILL_UPDATE" ) then
		local tradeSkill
		if( GetTradeSkillLine() == L["Tailoring"] and TT_Config.tailor ) then
			tradeSkill = "tailor"
		elseif( GetTradeSkillLine() == L["Alchemy"] and TT_Config.alchemy ) then
			tradeSkill = "alchemy"
		elseif( GetTradeSkillLine() == L["Jewelcrafting"] and TT_Config.jc ) then
			tradeSkill = "jc"
		else
			return
		end
		
		local cooldown
		for i=1, GetNumTradeSkills() do
			cooldown = GetTradeSkillCooldown(i)
			if( cooldown ) then
				for id, timer in pairs(TransmuteTimers[realmName]) do
					if( timer.name == playerName and timer.type == tradeSkill ) then
						TransmuteTimers[realmName][id].ready = time() + cooldown
						return
					end
				end
				
				table.insert(TransmuteTimers[realmName], {name = playerName, type = tradeSkill, faction = playerFaction, ready = time() + cooldown})
				return
			end
		end
	end
end

local elapsed = 0
local readyElapsed = 0
local function OnUpdate()
	elapsed = elapsed + arg1

	if( almostReady > 0 ) then
		readyElapsed = readyElapsed + arg1
		
		if( readyElapsed > 5 ) then
			readyElapsed = 0
			CheckTimers()
			return
		end
	end
	
	if( elapsed >= TT_Config.interval ) then
		elapsed = 0
		CheckTimers()
	end
end

frame:SetScript("OnEvent", OnEvent)
frame:SetScript("OnUpdate", OnUpdate)

frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("TRADE_SKILL_SHOW")
frame:RegisterEvent("TRADE_SKILL_UPDATE")

-- Slash command
SLASH_TRANSMUTETIME1 = "/transmute"
SLASH_TRANSMUTETIME2 = "/transmutetimer"
SLASH_TRANSMUTETIME3 = "/transmute"
SlashCmdList["TRANSMUTETIME"] = function(msg)
	if( not msg or msg == "" ) then
		DEFAULT_CHAT_FRAME:AddMessage(L["/transmute tailor - Toggles transmute timer support for tailoring"])
		DEFAULT_CHAT_FRAME:AddMessage(L["/transmute alchemy - Toggles transmute timer support for tailoring"])
		DEFAULT_CHAT_FRAME:AddMessage(L["/transmute jc - Toggles transmute timer support for jewelcrafting"])
		DEFAULT_CHAT_FRAME:AddMessage(L["/transmute interval <seconds> - Seconds inbetween checks for timers"])
		DEFAULT_CHAT_FRAME:AddMessage(L["/transmute cross - Toggles checking for characters on other servers"])
		DEFAULT_CHAT_FRAME:AddMessage(L["/transmute char - Toggles checking for different characters you aren't on"])
		DEFAULT_CHAT_FRAME:AddMessage(L["/transmute check - Lists time left on all transmutes"])
		return
	end

	msg = string.lower( msg )

	if( msg == "check" ) then
		local crtTime = time()
		local totalTransmutes = 0

		for realm, timers in pairs(TransmuteTimers) do
			for i=#(timers), 1, -1 do
				local timer = timers[i]
				totalTransmutes = totalTransmutes + 1

				local type = L["Alchemy"]
				if( timer.type == "tailor" ) then
					type = L["Tailoring"]
				elseif( timer.type == "jc" ) then
					type = L["Jewelcrafting"]
				end

				if( timer.ready <= crtTime ) then
					Print(string.format(L["%s timer ready for %s - %s, %s."], type, timer.name, realm, timer.faction))
				else
					Print(string.format(L["%s, %s - %s, %s, %s"], type, timer.name, realm, timer.faction, SecondsToTime(timer.ready - crtTime)))
				end
			end
		end

		if( totalTransmutes == 0 ) then
			Print(L["You do not have any transmute timers saved!"])
		end

	elseif( msg == "alchemy" ) then
		TT_Config.alchemy = not TT_Config.alchemy
		local status = L["on"]
		if( not TT_Config.alchemy ) then
			status = L["off"]	
		end

		Print(string.format(L["Alchemy transmute tracking is now %s."], status))

	elseif( msg == "tailor" ) then
		TT_Config.tailor = not TT_Config.tailor
		local status = L["on"]
		if( not TT_Config.tailor ) then
			status = L["off"]	
		end

		Print(string.format(L["Tailoring transmute tracking is now %s."], status))

	elseif( msg == "jc" ) then
		TT_Config.jc = not TT_Config.jc
		local status = L["on"]
		if( not TT_Config.jc ) then
			status = L["off"]	
		end

		Print(string.format(L["Jewelcrafting transmute tracking is now %s."], status))

	elseif( msg == "cross" ) then
		TT_Config.crossServer = not TT_Config.crossServer
		local status = L["on"]
		if( not TT_Config.crossServer ) then
			status = L["off"]	
		end

		Print(string.format(L["Cross-server checking is now %s."], status))

	elseif( msg == "char" ) then
		TT_Config.crossChar = not TT_Config.crossChar
		local status = L["on"]
		if( not TT_Config.crossChar ) then
			status = L["off"]	
		end

		Print(string.format(L["Same character checking is now %s."], status))
	end
end
