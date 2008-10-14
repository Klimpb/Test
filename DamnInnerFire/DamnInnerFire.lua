local SPELL_NAME = GetSpellInfo(588)
local hasBuff

-- Do a quick check of player buffs
local function checkBuffs()
	hasBuff = false
	
	local buffID = 1
	while( true ) do
		local name = UnitBuff("player", buffID)
		if( not name ) then break end
		if( name == SPELL_NAME ) then
			hasBuff = true
			break
		end
		
		buffID = buffID + 1
	end
end

-- Show/hide the alert frame
local alertFrame
local function checkAlertFrame()
	-- Already has buff, return + hide frame
	if( hasBuff ) then
		if( alertFrame ) then
			alertFrame:Hide()
		end
		return
	end
		
	-- Create our display frame
	if( not alertFrame ) then
		local backdrop = {bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
				edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
				tile = false,
				edgeSize = 1,
				tileSize = 5,
				insets = {left = 1, right = 1, top = 1, bottom = 1}}
	
		-- Create the tab frame
		alertFrame = CreateFrame("Frame", nil, UIParent)
		alertFrame:SetHeight(20)
		alertFrame:SetWidth(140)
		alertFrame:EnableMouse(true)
		alertFrame:SetMovable(true)
		alertFrame:SetClampedToScreen(true)
		alertFrame:SetBackdrop(backdrop)
		alertFrame:SetBackdropColor(0.0, 0.0, 0.0, 1.0)
		alertFrame:SetBackdropBorderColor(0.75, 0.75, 0.75, 1.0)
		alertFrame:SetScript("OnMouseUp", function(self)
			if( self.isMoving ) then
				self.isMoving = nil
				self:StopMovingOrSizing()

				local scale = self:GetEffectiveScale()
				DamnInnerFireDB = {x = self:GetLeft() * scale, y = self:GetTop() * scale}
			end
		end)
		alertFrame:SetScript("OnMouseDown", function(self, mouse)
			if( IsAltKeyDown() ) then
				self.isMoving = true
				self:StartMoving()
			end
		end)
	
		-- Text (obviously)
		alertFrame.text = alertFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
		alertFrame.text:SetText("Inner Fire is gone!")
		alertFrame.text:SetPoint("CENTER", alertFrame, "CENTER")
	end
	
	-- Position
	if( DamnInnerFireDB ) then
		local scale = alertFrame:GetEffectiveScale()

		alertFrame:ClearAllPoints()
		alertFrame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", DamnInnerFireDB.x / scale, DamnInnerFireDB.y / scale)
	else
		alertFrame:SetPoint("CENTER", UIParent, "CENTER")
	end
	
	alertFrame:Show()
end


-- Buff checking
local COMBATLOG_OBJECT_TYPE_PLAYER = COMBATLOG_OBJECT_TYPE_PLAYER
local frame = CreateFrame("Frame")
frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:SetScript("OnEvent", function(self, event, timestamp, eventType, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellID, spellName, spellSchool, auraType)
	if( event == "COMBAT_LOG_EVENT_UNFILTERED" ) then
		-- Not something we did, so just ignore it
		if( bit.band(destFlags, COMBATLOG_OBJECT_AFFILIATION_MINE) ~= COMBATLOG_OBJECT_AFFILIATION_MINE ) then
			return
		end

		-- Buff gone, show frame
		if( eventType == "SPELL_AURA_REMOVED" and auraType == "BUFF" and spellName == SPELL_NAME ) then
			hasBuff = false
			checkAlertFrame()
			
		-- Gained buff, hide frame
		elseif( eventType == "SPELL_AURA_APPLIED" and auraType == "BUFF" and spellName == SPELL_NAME ) then
			hasBuff = true
			checkAlertFrame()
		end

	elseif( event == "PLAYER_ENTERING_WORLD") then
		checkBuffs()
		checkAlertFrame()
	end
end)
