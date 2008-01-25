local Module = PerfectRaid:NewModule("PerfectRaid-ExtraThings")

--[[
* button - the unit frame
* button.leftbox - A bounding box on the left-hand side of the frame. This is by default 70 pixels wide
* button.rightbox - A bounding box on the right-hand side of the frame. This is by default 70 pixels wide
* button.healthbar - The health bar, anchored in between the two bounding boxes.. so this will be the frame size - 140.
* button.manabar - The mana bar, anchored to the bottom of the health bar
* button.status - The "DEAD, GHOST and HPMISSING" text.. this is always anchored to the right of the health bar.
* button.name - The unit's name. This is anchored to one of the bounding boxes, depending on the "ALIGN RIGHT" option.
* button.aura - Defined in PerfectRaid_Buffs.lua, this is the "buffs" text that appears by default next to the right-hand side of the health bar.
]]


function Module:Initialize()
	-- Disable the evil fading
	local Options = PerfectRaid:HasModule("PerfectRaid-Options")
	Options.FadeIn = function(self, frame)
		frame:Show()
	end
end

-- Create the backdrop, and the OnEnter/OnLeave scripts
local backdrop = {
	bgFile = "Interface\\AddOns\\PerfectRaid\\images\\bgFile", 
	tile = true, tileSize = 32, 
	insets = {
		left = 2,
		right = 6,
		top = 1,
		bottom = 1,
	},
}

function Module:UpdateButtonLayout(button, options)
	button.leftbox:ClearAllPoints()
	button.leftbox:SetPoint("TOPLEFT", 0, 0)
	button.leftbox:SetPoint("BOTTOMRIGHT", button, "BOTTOMLEFT", 1, 0)
	
	button.name:ClearAllPoints()
	button.name:SetPoint("LEFT", button.healthbar, "LEFT", 0, 0)
	button.name:SetPoint("RIGHT", button.healthbar, "RIGHT", 2, 0)
	button.name:SetParent(button.raise)
	button.name:SetJustifyH("LEFT")
	
	button:SetBackdrop(backdrop)
	button:SetBackdropColor(0, 0, 0, 0)
end