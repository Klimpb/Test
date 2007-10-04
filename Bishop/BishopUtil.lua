--[[---------------------------------------------------------------------------------
  Utility Functions
------------------------------------------------------------------------------------]]

function Bishop:ParseTooltip(name, rank)
	-- Valid spellID should be leaded into the tooltip.
	
	local min,max,mana,hot,ticks,duration
	local pattern = BISHOP.HEALS[name].pattern
	local class = BISHOP.HEALS[name].class
	
	if name == BISHOP.DESPERATE_PRAYER then
		_,_,min,max = string.find(BishopTooltipTextLeft3:GetText(), pattern)
		mana = 0
		return name,rank,min,max,mana
	
	elseif name == BISHOP.HOLY_NOVA then
		_,_,_,_,_,_,mix,max = string.find(BishopTooltipTextLeft3:GetText(), pattern)
		_,_,mana = string.find(BishopTooltipTextLeft2:GetText(), BISHOP.MANA_PATTERN)
		return name,rank,min,max,mana
	
	elseif name == BISHOP.TRANQUILITY then
		_,_,hot,ticks,duration = string.find(BishopTooltipTextLeft4:GetText(), pattern)
		_,_,mana = string.find(BishopTooltipTextLeft2:GetText(), BISHOP.MANA_PATTERN)
		hot = hot * (duration / ticks)
		return name,rank,nil,nil,hot

	elseif class == BISHOP.HOT_CLASS then
		_,_,hotAmt,duration = string.find(BishopTooltipTextLeft4:GetText(), pattern)
		_,_,mana = string.find(BishopTooltipTextLeft2:GetText(), BISHOP.MANA_PATTERN)
		return name,rank,nil,nil,mana,hotAmt
	
	elseif class == BISHOP.HOTPLUS_CLASS then
		_,_,min,max,hot,duration = string.find(BishopTooltipTextLeft4:GetText(), pattern)
		_,_,mana = string.find(BishopTooltipTextLeft2:GetText(), BISHOP.MANA_PATTERN)
		return name,rank,min,max,mana,hot

	else
		_,_,min,max = string.find(BishopTooltipTextLeft4:GetText(), pattern)
		_,_,mana = string.find(BishopTooltipTextLeft2:GetText(), BISHOP.MANA_PATTERN)
		if min and max and mana then 
			return name,rank,min,max,mana
		end
	end
end

function Bishop:ParseSpellbook()
	BISHOP.HEALRANKS = {}
	local i = 1
	while true do
		local name,rank = GetSpellName(i, BOOKTYPE_SPELL)
		self:debug("Name: " .. tostring(name) .. "Rank: " .. tostring(rank))
		if not name then break end
		
		_,_,rank = string.find(rank, BISHOP.RANK_PATTERN)
		
		if BISHOP.HEALS[name] then
			if not BISHOP.HEALS[name][rank] then BISHOP.HEALS[name][rank] = {} end
			
			self.tooltip:SetSpell(i, BOOKTYPE_SPELL)
			
			local s = {}
			if not s then s = {} end
			
			local data = BISHOP.HEALS[name][rank]
			
			BISHOP.HEALS[name].maxRank = i
			
			data.id = i
			_,_,data.min, data.max, data.mana, data.hot = self:ParseTooltip(name, rank)
			
			BISHOP.HEALRANKS[i] = rank
		end

		i = i + 1

		end
end

local ID_CACHE = {}
local RAID_IDS = {}
local PARTY_IDS = {}
for i=1,MAX_RAID_MEMBERS do RAID_IDS[i] = "raid"..i end
for i=1,MAX_PARTY_MEMBERS do PARTY_IDS[i] = "party"..i end

function Bishop:GetUnitFromName(name)
	if not name then return nil end
	
	local cache = ID_CACHE[name]
	
	if cache then 
		if UnitName(cache) == name then
			return cache
		end
	end
	
	local unitID = nil
	local n = GetNumRaidMembers()
	
	local tbl
	if name ~= UnitName("player") then
		if n > 0 then 
			tbl = RAID_IDS 
		else
			n = GetNumPartyMembers()
			tbl = PARTY_IDS
		end
		
		for i=1,n do
			local u = tbl[i]
			if UnitName(u) == name then
				unitID = u
				break
			end
		end
	else
		unitID = "player"
	end
	
	ID_CACHE[name] = unitID
	return unitID
end


function Bishop:UNIT_INVENTORY_CHANGED(force)
	
	if arg1 ~= "player" and not force then 
		-- self:debug("Caught a UNIT_INVENTORY_CHANGED() for someone other than 'player'.  Dropping")
		return
	end
	
--	self:debug("Parsing the inventory for +healing items.")
	
	local id, hasItem, ttLine
	
	self.healBonus = 0
	
	for i,slotName in BISHOP.SLOTNAMES do
		id,_ = GetInventorySlotInfo(slotName)
		self.tooltip:Hide()
		
		hasItem = self.tooltip:SetInventoryItem("player", id)
		
		if not hasItem then
			self.tooltip:ClearLines()
		else
--			self:debug("Found an item in " .. slotName)
			
			local itemName = BishopTooltipTextLeft1:GetText()
			local lines = self.tooltip:NumLines()
			
			for i=2,lines,1 do 
				ttLine = getglobal("BishopTooltipTextLeft"..i)
				local text = ttLine:GetText()
				if text then 
					-- We need to parse this line of the tooltip
					-- Lets see if we have an "Equip:" string
					-- As of right now, there are no set bonus healing bonuses, but that may change.
					
					if string.find(text, BISHOP.EQUIP_PREFIX) then
						for idx,pattern in BISHOP.HEALBONUS_PATTERNS do
							local _,_,value = string.find(text, pattern)
							
							-- We have a heal bonus string in Equip:
							if value then 							
--								self:debug("Found a heal bonus in following line:")
--								self:debug(text)
								self.healBonus = self.healBonus + value
--								self:debug("Incremented self.healBonus to " .. self.healBonus)
							end -- If heal bonus 
						end -- for each pattern
					end -- if we have "Equip:" 
				end -- If the tooltip has text
			end -- For each line in tooltip
		end -- if hasItem
	end -- for each slotName	
end