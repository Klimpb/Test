local function restorePositions()
	ItemRefTooltipTexture10:Hide()

	ItemRefTooltipTextLeft1:ClearAllPoints()
	ItemRefTooltipTextLeft1:SetPoint("TOPLEFT", ItemRefTooltip, "TOPLEFT", 8, -10)

	ItemRefTooltipTextLeft2:ClearAllPoints()
	ItemRefTooltipTextLeft2:SetPoint("TOPLEFT", ItemRefTooltipTextLeft1, "BOTTOMLEFT", 0, -2)
end

hooksecurefunc("SetItemRef", function(link, text, button)
	local icon = select(10, GetItemInfo(link))
	if( not icon or not string.match(link, "item:") ) then
		restorePositions()
		return
	end
	
	

	ItemRefTooltipTexture10:ClearAllPoints()
	ItemRefTooltipTexture10:SetPoint("TOPLEFT", ItemRefTooltip, "TOPLEFT", 8, -7)
	ItemRefTooltipTexture10:SetTexture(icon)
	ItemRefTooltipTexture10:SetHeight(20)
	ItemRefTooltipTexture10:SetWidth(20)
	ItemRefTooltipTexture10:Show()
	
	ItemRefTooltipTextLeft1:ClearAllPoints()
	ItemRefTooltipTextLeft1:SetPoint("TOPLEFT", ItemRefTooltipTexture10, "TOPLEFT", 24, -2)

	ItemRefTooltipTextLeft2:ClearAllPoints()
	ItemRefTooltipTextLeft2:SetPoint("TOPLEFT", ItemRefTooltip, "TOPLEFT", 8, -28)
	
	local textRight = ItemRefTooltipTextLeft1:GetRight()
	local closeLeft = ItemRefCloseButton:GetLeft()
	
	if( closeLeft <= textRight ) then
		ItemRefTooltip:SetWidth(ItemRefTooltip:GetWidth() + (textRight - closeLeft))
	end
end)