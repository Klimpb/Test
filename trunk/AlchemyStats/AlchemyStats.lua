local L = AlchemyStatLocals

local crtProfile
local createdMulti
local createdSingle
local tooltip

local supposedCreate = {}
local itemType = {
	["Flask"] = L["Elixir Master"],
	["Elixir"] = L["Elixir Master"],
	["Potion"] = L["Potion Master"],
	["Elemental"] = L["Transmutation Master"],
}

local function Print(msg)
	DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99" .. L["Alchemy"] .. "|r: " .. msg)
end

local function Format(text)
	text = string.gsub(text, "([%^%(%)%.%[%]%*%+%-%?])", "%%%1")
	text = string.gsub(text, "%%s", "(.+)")
	text = string.gsub(text, "%%d", "(%-?%%d+)")
	return text
end

local function GetMastery()
	if( not tooltip ) then
		tooltip = CreateFrame("GameTooltip", "AlchStatTooltip", UIParent, "GameTooltipTemplate")
		tooltip:SetOwner(UIParent, "ANCHOR_NONE")
	end
	

	local _, _, offset, numSpells = GetSpellTabInfo(1)
	for i=1, numSpells do
		tooltip:SetSpell(offset + i, BOOKTYPE_SPELL)
		local spell = tooltip:GetSpell()
		
		if( spell == L["Elixir Master"] or spell == L["Potion Master"] or spell == L["Transmutation Master"] ) then
			return spell
		end
	end
	
	return nil
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
			msg = string.lower(msg or "")
			
			if( msg == "stat" ) then
				local mastery = GetMastery()
				for char, potions in pairs(AlchemyStats) do
					local server, faction, name = string.split(":", char)

					local totalCreated = 0
					local totalNoProc = 0
					local totalProc = 0
					local totalProcChance = 0
					
					for itemid, stats in pairs(potions) do
						local subType = select(7, GetItemInfo(itemid))
						if( subType ) then
							local created, used, proc, noProc = string.split(":", stats)
							
							totalCreated = totalCreated + created
							if( mastery and itemType[subType] and mastery == itemType[subType] ) then
								totalProcChance = totalProcChance + proc + noProc
								totalProc = totalProc + proc
								totalNoProc = totalNoProc + noProc
							end
						end
					end

					DEFAULT_CHAT_FRAME:AddMessage(string.format("[%s] %s - %s: Made (%d), Proc (%d), No Proc (%d), Proc Chance (%.2f%%)", server, name, faction, totalCreated, totalProc, totalNoProc, totalProc / totalProcChance))
				end
			
			elseif( msg == "elixir" ) then
			
			elseif( msg == "flask" ) then
			
			elseif( msg == "potion" ) then
			
			elseif( msg == "elemental" ) then
			
			else
				DEFAULT_CHAT_FRAME:AddMessage(L["/alchemy stat - Shows total types of items created through alchemy"])
				--DEFAULT_CHAT_FRAME:AddMessage(L["/alchemy <elixir/flask/potion/elemental> - Show total created/item stats of the passed item type"])
			end
		end
		
		-- Setup basic DB
		crtProfile = string.format("%s:%s:%s", GetRealmName(), UnitFactionGroup("player"), UnitName("player"))
		
		if( not AlchemyStats ) then
			AlchemyStats = {}
		end
				
	elseif( ( event == "TRADE_SKILL_UPDATE" or event == "TRADE_SKILL_SHOW" ) and GetTradeSkillLine() == L["Alchemy"] ) then
		for i=1, GetNumTradeSkills() do
			local itemLink = GetTradeSkillItemLink(i)
			if( itemLink ) then
				local itemid = string.match(itemLink, "item:([0-9]+):")
				itemid = tonumber(itemid)

				if( itemid ) then
					supposedCreate[itemid] = GetTradeSkillNumMade(i)
				end
			end
		end
	
	elseif( event == "CHAT_MSG_LOOT" ) then
		local name, amount = string.match(msg, createdMulti)
		if( not name and not amount ) then
			name = string.match(msg, createdSingle)
			amount = 1
		end
				
		-- No match found, not a creation
		if( not name ) then
			return
		end
		
		-- Parse out the item id
		local itemid = string.match(name, "item:([0-9]+):")
		
		amount = tonumber(amount)
		itemid = tonumber(itemid)
		
		-- Something messed up
		if( not itemid or not amount or not supposedCreate[itemid] ) then
			return
		end
		
		local crtItem = itemid
		local totalCreated, totalUsed, totalProc, noProc, oneProc, twoProc, threeProc, fourProc = 0, 0, 0, 0, 0, 0, 0, 0
		
		-- We already have stats saved
		if( AlchemyStats[crtProfile] and AlchemyStats[crtProfile][itemid] ) then
			totalCreated, totalUsed, totalProc, noProc, oneProc, twoProc, threeProc, fourProc = string.split(":", AlchemyStats[crtProfile][itemid])
		end
		
		-- totalCreated = Actual amount of potions made
		totalCreated = totalCreated + amount
		-- totalUsed = How many times we used this skill, that way we can do totalUsed / totalProc = proc chance
		totalUsed = totalUsed + supposedCreate[itemid]
		
		-- Quick and hackish, I'll clean it up later
		if( amount > supposedCreate[itemid] ) then
			local proc = amount - supposedCreate[itemid]
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
		
		-- Create our db for this char
		if( not AlchemyStats[crtProfile] ) then
			AlchemyStats[crtProfile] = {}
		end

		-- Store!
		AlchemyStats[crtProfile][itemid] = string.format("%s:%s:%s:%s:%s:%s:%s:%s", totalCreated, totalUsed, totalProc, noProc, oneProc, twoProc, threeProc, fourProc)
	end
end

local frame = CreateFrame("Frame")
frame:SetScript("OnEvent", OnEvent)
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("CHAT_MSG_LOOT")
frame:RegisterEvent("TRADE_SKILL_UPDATE")
frame:RegisterEvent("TRADE_SKILL_SHOW")