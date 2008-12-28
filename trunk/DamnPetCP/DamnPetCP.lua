local frame
local function createFrame()
	-- Create our display frame
	if( not frame ) then
		local backdrop = {bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
				edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
				tile = false,
				edgeSize = 1,
				tileSize = 5,
				insets = {left = 1, right = 1, top = 1, bottom = 1}}
	
		-- Create the tab frame
		frame = CreateFrame("Frame", nil, UIParent)
		frame:SetHeight(15)
		frame:SetWidth(15)
		frame:EnableMouse(true)
		frame:SetMovable(true)
		frame:SetClampedToScreen(true)
		frame:SetBackdrop(backdrop)
		frame:SetBackdropColor(0.0, 0.0, 0.0, 1.0)
		frame:SetBackdropBorderColor(0.75, 0.75, 0.75, 1.0)
		frame:SetScript("OnMouseUp", function(self)
			if( self.isMoving ) then
				self.isMoving = nil
				self:StopMovingOrSizing()

				local scale = self:GetEffectiveScale()
				DamnPetCPDB = {x = self:GetLeft() * scale, y = self:GetTop() * scale}
			end
		end)
		frame:SetScript("OnMouseDown", function(self, mouse)
			if( IsAltKeyDown() ) then
				self.isMoving = true
				self:StartMoving()
			end
		end)
	
		-- Text (obviously)
		frame.text = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
		frame.text:SetFont((GameFontHighlightSmall:GetFont()), 12)
		frame.text:SetText("")
		frame.text:SetPoint("CENTER", frame, "CENTER")
	end
	
	-- Position
	if( DamnPetCPDB ) then
		local scale = frame:GetEffectiveScale()

		frame:ClearAllPoints()
		frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", DamnPetCPDB.x / scale, DamnPetCPDB.y / scale)
	else
		frame:SetPoint("CENTER", UIParent, "CENTER")
	end
	
	frame:Show()
end


-- Buff checking
local evtFrame = CreateFrame("Frame")
evtFrame:RegisterEvent("UNIT_COMBO_POINTS")
evtFrame:RegisterEvent("UNIT_PET")
evtFrame:SetScript("OnEvent", function(self, event, unit)
	if( event == "UNIT_PET" and unit == "player" and not UnitExists("pet") and frame ) then
		frame:Hide()
	elseif( event == "UNIT_COMBO_POINTS" and unit == "pet" ) then
		local points = GetComboPoints(unit)
		if( points == 0 ) then
			points = GetComboPoints(unit, unit)
		end
		
		if( points > 0 ) then
			if( not frame ) then
				createFrame()
			end
			
			frame.text:SetText(points)
			frame:Show()
		elseif( frame ) then
			frame.text:SetText("0")
		end
	end
end)
