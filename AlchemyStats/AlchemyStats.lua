local frame = CreateFrame("Frame")
local crtProfile
local createdMulti, createdSingle

local L = {
	["Alchemy"] = "Alchemy",
}

--[[
if( GetLocale() == "deDE" ) then

elseif( GetLocale() == "frFR" ) then

end
]]

local function Print(msg)
	DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99" .. L["Alchemy"] .. "|r: " .. msg)
end

function Format(text)
	text = string.gsub(text, "([%^%(%)%.%[%]%*%+%-%?])", "%%%1")
	text = string.gsub(text, "%%s", "(.+)")
	text = string.gsub(text, "%%d", "(%-?%%d+)")
	
	return text
end

local function OnEvent(self, event, msg)
	if( event == "ADDON_LOADED" and arg1 == "AlchemyStats" ) then
		-- Log messages
		createdMulti = Format(LOOT_ITEM_CREATED_SELF_MULTIPLE)
		createdSingle = Format(LOOT_ITEM_CREATED_SELF)
		
		-- Slash commands
		SLASH_ALCHEMYSTAT1 = "/alchemy"
		SLASH_ALCHEMYSTAT2 = "/alchemystats"
		SLASH_ALCHEMYSTAT3 = "/alchemystat"
		SlashCmdList["ALCHEMYSTAT"] = function(msg)
			if( not msg or msg == "" ) then
				return
			end
			
			msg = string.lower(msg)
			
		end
		
		-- Setup basic DB
		crtProfile = string.format("%s:%s:%s", GetRealmName(), UnitFactionGroup("player"), UnitName("player"))
		
		if( not AlchemyStats ) then
			AlchemyStats = {}
		end
		
		if( not AlchemyStats[crtProfile] ) then
			AlchemyStats[crtProfile] = {}
		end
		
		
	elseif( event == "CHAT_MSG_LOOT" ) then
		local name, amount = string.match(msg, createdMulti)
		if( not name and not amount ) then
			name = string.match(msg, createdSingle)
			amount = 1
		end
		
		if( not name ) then
			return
		end
		
		local itemid = string.match(name, "item:([0-9]+):")
		
		amount = tonumber(amount)
		itemid = tonumber(itemid)
		
		-- Not a consumable so ignore it
		local itemType = select(6, GetItemInfo(itemid))
		if( not itemType or itemType ~= "Consumable" ) then
			return
		end
		
		
		-- Something messed up
		if( not itemid or not amount ) then
			return
		end
		
		local crtItem = itemid
		local totalCreated, totalUsed, totalProc, noProc, oneProc, twoProc, threeProc, fourProc = 0, 0, 0, 0, 0, 0, 0, 0
		
		if( AlchemyStats[crtProfile][itemid] ) then
			totalCreated, totalUsed, totalProc, noProc, oneProc, twoProc, threeProc, fourProc = string.split(":", AlchemyStats[crtProfile][itemid])
		end
		
		-- totalCreated = Actual amount of potions made
		totalCreated = totalCreated + amount
		-- totalUsed = How many times we used this skill, that way we can do totalUsed / totalProc = proc chance
		totalUsed = totalUsed + 1
		
		-- Quick and hackish, I'll clean it up later
		if( amount > 1 ) then
			local proc = amount - 1
			totalProc = totalProc + proc
			if( proc == 1 ) then
				oneProc = oneProc + 1
			elseif( proc == 2 ) then
				twoProc = twoProc + 1
			elseif( proc == 3 ) then
				threeProc = threeProc + 1
			elseif( proc == 4 ) then
				fourProc = fourProc + 1
			end
		else
			noProc = noProc + 1
		end
		
		AlchemyStats[crtProfile][itemid] = string.format("%s:%s:%s:%s:%s:%s:%s:%s", totalCreated, totalUsed, totalProc, noProc, oneProc, twoProc, threeProc, fourProc)
	end
end

frame:SetScript("OnEvent", OnEvent)
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("CHAT_MSG_LOOT")
