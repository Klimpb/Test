FSR = {}
local L = FSRLocal
local ruleStart, playerMana, frame

function FSR:OnInitialize()
	-- Make sure they even need this
	local class = select(2, UnitClass("player"))
	if( class == "ROGUE" or class == "WARRIOR" or class == "DEATHKNIGHT" ) then
		self.evtFrame:UnregisterAllEvents()
		return
	end
	
	FiveSecondRuleDB = FiveSecondRuleDB or {visible = true}
	
	self:RegisterEvent("UNIT_MANA")
	self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
	
	playerMana = UnitPower("player", 0)
	
	-- Showing the frame!
	if( FiveSecondRuleDB.visible ) then
		self:CreateFrame()
	end
end

function FSR:UNIT_MANA(unit)
	if( unit ~= "player" ) then
		return
	end
	
	local mana = UnitPower("player", 0)
	if( UnitPowerMax("player", 0) == mana ) then
		self.evtFrame:Hide()
	elseif( mana < playerMana ) then
		-- Experiment, calibration based off lag
		isChannel = UnitChannelInfo("player")
		ruleStart = GetTime() + 5 - (select(3, GetNetStats()) / 1000)
		self.evtFrame:Show()
	end

	playerMana = mana
end

function FSR:UNIT_SPELLCAST_CHANNEL_STOP(unit, ...)
	if( unit ~= "player" ) then
		return
	end
	
	isChannel = nil
	self:UpdateFrame()
end

function FSR:UpdateFrame()
	if( not frame ) then
		return
	end
	
	-- If we're channeling, and "out" of FSR, then set it to 0/red since we don't
	-- actually exit it until the channel is done
	if( ruleStart == 0 and isChannel ) then
		frame.currentMP:SetFormattedText("%d", select(2, GetManaRegen()))
		frame.timeLeft:SetText("0")
		frame.timeLeft:SetTextColor(1, 0.10, 0.10, 1.0)

	-- Haven't exited FSR yet
	elseif( ruleStart > 0 ) then
		frame.currentMP:SetFormattedText("%d", select(2, GetManaRegen()))
		frame.timeLeft:SetFormattedText("%.1f", ruleStart - GetTime())
		frame.timeLeft:SetTextColor(1.0, 1.0, 1.0, 1.0)
	
	-- Out!
	else
		frame.currentMP:SetFormattedText("%d", (GetManaRegen()))

		frame.timeLeft:SetText("0")
		frame.timeLeft:SetTextColor(0.10, 0.80, 0.10, 1.0)
	end
end

local timeElapsed = 0
local function fsrMonitor(self, elapsed)
	if( ruleStart < GetTime() ) then
		ruleStart = 0
		self:Hide()

		FSR:UpdateFrame()
	end
	
	if( ruleStart > 0 ) then
		timeElapsed = timeElapsed + elapsed
		
		if( timeElapsed >= 0.10 ) then
			FSR:UpdateFrame()
		end
	end
end

-- Display frame
function FSR:CreateFrame()
	-- Create our display frame
	if( not frame ) then
		local backdrop = {bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
				edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
				tile = false,
				edgeSize = 0.90,
				tileSize = 5,
				insets = {left = 1, right = 1, top = 1, bottom = 1}}
	
		-- Create the tab frame
		frame = CreateFrame("Frame", nil, UIParent)
		frame:SetHeight(18)
		frame:SetWidth(90)
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
				FiveSecondRuleDB.position = {x = self:GetLeft() * scale, y = self:GetTop() * scale}
			end
		end)
		frame:SetScript("OnMouseDown", function(self, mouse)
			if( IsAltKeyDown() ) then
				self.isMoving = true
				self:StartMoving()
			end
		end)
	
		-- Time left before exiting
		frame.timeLeft = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
		frame.timeLeft:SetFont((GameFontHighlightSmall:GetFont()), 12)
		frame.timeLeft:SetPoint("TOPLEFT", frame, "TOPLEFT", 2, -3)
		
		-- Current MP5
		frame.currentMP = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
		frame.currentMP:SetFont((GameFontHighlightSmall:GetFont()), 12)
		frame.currentMP:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -2, -3)
		
		self:UpdateFrame()
	end
	
	-- Position
	if( FiveSecondRuleDB.position ) then
		local scale = frame:GetEffectiveScale()

		frame:ClearAllPoints()
		frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", FiveSecondRuleDB.position.x / scale, FiveSecondRuleDB.position.y / scale)
	else
		frame:SetPoint("CENTER", UIParent, "CENTER")
	end
	
	frame:Show()
end

-- Random junk
local evtFrame = CreateFrame("Frame")
evtFrame:RegisterEvent("ADDON_LOADED")
evtFrame:Hide()

evtFrame:SetScript("OnUpdate", fsrMonitor)
evtFrame:SetScript("OnEvent", function(self, event, ...)
	if( event == "ADDON_LOADED" and select(1, ...) == "FiveSecondRule" ) then
		FSR:OnInitialize()
		self:UnregisterEvent("ADDON_LOADED")
	elseif( FSR[event] ) then
		FSR[event](FSR, ...)
	end
end)

function FSR:RegisterEvent(event)
	evtFrame:RegisterEvent(event)
end

function FSR:UnregisterEvent(event)
	evtFrame:UnregisterEvent(event)
end

function FSR:Print(msg)
	DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99FSR|r: " .. msg)
end

function FSR:Echo(msg)
	DEFAULT_CHAT_FRAME:AddMessage(msg)
end

FSR.evtFrame = evtFrame

-- Slash commands
SLASH_FSR1 = "/fsr"
SLASH_FSR2 = "/fivesecondrule"
SlashCmdList["FSR"] = function(msg)
	FiveSecondRuleDB.visible = not FiveSecondRuleDB.visible
	
	if( FiveSecondRuleDB.visible ) then
		FSR:Print(L["Now showing the FSR block."])
		FSR:CreateFrame()
	else
		FSR:Print(L["No longer showing the FSR block."])
		if( frame ) then
			frame:Hide()
		end
	end
end