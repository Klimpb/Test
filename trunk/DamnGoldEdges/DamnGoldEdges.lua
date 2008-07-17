local createdBuffs = {}
local createdDebuffs = {}

local totalBuffs = 0
local totalDebuffs = 0

local defaultBuff, defaultDebuff

local function createCooldown(name, parent)
	local cooldown = CreateFrame("Cooldown", string.format("%sCooldown", name), parent, "CooldownFrameTemplate")
	cooldown:SetReverse(true)
	cooldown:SetPoint("CENTER", 0, -1)
end

-- Pre-create everything so Blizzard doesn't thus keeping our overrides active
local function overrideBuffs()
	if( totalBuffs == MAX_TARGET_BUFFS and totalDebuffs == MAX_TARGET_DEBUFFS ) then
		return
	end
	
	if( not defaultBuff ) then
		defaultBuff = CreateFrame("Button", "DGEDefaultBuff", nil, "TargetBuffButtonTemplate")
	end
	
	for i=1, MAX_TARGET_BUFFS do
		local name = string.format("TargetFrameBuff%d", i)
		if( not createdBuffs[name] ) then
			local button = CreateFrame("Button", name, TargetFrame)
			button:SetWidth(21)
			button:SetHeight(21)
			button:SetScript("OnUpdate", defaultBuff:GetScript("OnUpdate"))
			button:SetScript("OnEnter", defaultBuff:GetScript("OnEnter"))
			button:SetScript("OnLeave", defaultBuff:GetScript("OnLeave"))
			
			-- Buff icon
			button.icon = button:CreateTexture(name .. "Icon", "ARTWORK")
			button.icon:SetAllPoints()
			
			-- Stack count
			button.count = button:CreateFontString(name .. "Count", nil, "NumberFontNormalSmall")
			button.count:SetPoint("BOTTOMRIGHT", 2, 0)

			-- Cooldown ring
			createCooldown(name, button)
			
			createdBuffs[name] = button
			totalBuffs = totalBuffs + 1
		end
	end

	if( not defaultDebuff ) then
		defaultDebuff = CreateFrame("Button", "DGEDefaultDebuff", nil, "TargetDebuffButtonTemplate")
	end

	for i=1, MAX_TARGET_DEBUFFS do
		local name = string.format("TargetFrameDebuff%d", i)
		if( not createdDebuffs[name] ) then
			local button = CreateFrame("Button", name, TargetFrame)
			button:SetWidth(17)
			button:SetHeight(17)
			button:SetScript("OnUpdate", defaultDebuff:GetScript("OnUpdate"))
			button:SetScript("OnEnter", defaultDebuff:GetScript("OnEnter"))
			button:SetScript("OnLeave", defaultDebuff:GetScript("OnLeave"))
			
			-- Debuff icon
			button.icon = button:CreateTexture(name .. "Icon", "ARTWORK")
			button.icon:SetAllPoints()
			
			-- Debuff type border
			button.border = button:CreateTexture(name .. "Border", "OVERLAY")
			button.border:SetWidth(17)
			button.border:SetHeight(17)
			button.border:SetTexture("Interface\\Buttons\\UI-Debuff-Overlays")
			button.border:SetPoint("CENTER", 0, 0)
			button.border:SetTexCoord(0.296875, 0.5703125, 0.0, 0.515625)

			--<TexCoords left="0.296875" right="0.5703125" top="0" bottom="0.515625"/>

			-- Stack count
			button.count = button:CreateFontString(name .. "Count", nil, "NumberFontNormalSmall")
			button.count:SetPoint("BOTTOMRIGHT", -1, 0)

			-- Cooldown ring
			createCooldown(name, button)
			
			createdDebuffs[name] = button
			totalDebuffs = totalDebuffs + 1
		end
	end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, addon)
	overrideBuffs()
end)