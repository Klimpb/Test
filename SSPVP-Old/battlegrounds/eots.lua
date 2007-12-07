local EoTS = SSPVP:NewModule( "SSPVP-EoTS" )
EoTS.activeIn = "eots"

local L = SSPVPLocals
local towerInfo = {[0] = 0, [1] = 0.5, [2] = 1, [3] = 2.5, [4] = 5}

local Alliance = {}
local Horde = {}
local lowest

local carrierName
local carrierFaction

local playerFaction

function EoTS:Initialize()
	hooksecurefunc("WorldStateAlwaysUpFrame_Update", self.WorldStateAlwaysUpFrame_Update)
	playerFaction = UnitFactionGroup( "player" )
	SSOverlay:AddCategory("eots", L["Battlefield Info"])
end

function EoTS:EnableModule()
	self:RegisterEvent("UPDATE_BATTLEFIELD_SCORE", "UpdateCarrier")
	self:RegisterEvent("UPDATE_WORLD_STATES", "UpdateOverlay")
	self:RegisterEvent("CHAT_MSG_BG_SYSTEM_HORDE", "HordeFlag")
	self:RegisterEvent("CHAT_MSG_BG_SYSTEM_ALLIANCE", "AllianceFlag")
	
	self:CreateCarrierButtons()
end

function EoTS:DisableModule()
	Alliance = {}
	Horde = {}
	
	carrierName = nil
	carrierFaction = nil

	self:UnregisterAllMessages()
	self:UnregisterAllEvents()
	self:UpdateCarrierAttributes()

	SSOverlay:RemoveCategory("eots")
end

function EoTS:Reload()
	if( not self.allianceButton or not self.hordeButton ) then
		return
	end
	
	if( not SSPVP.db.profile.eots.carriers ) then
		carrierName = nil
		carrierFaction = nil
		
		if( self.allianceButton and self.hordeButton ) then
			self:UpdateCarrierAttributes()
		end
	end

	self:SetCarrierBorders()

	SSOverlay:RemoveCategory("eots")
	self:UpdateOverlay()
end

-- Parse Horde flag messages
function EoTS:HordeFlag(event, msg)
	self:ParseFlag(msg, "Horde")
end

-- Parse Alliance flag messages
function EoTS:AllianceFlag(event, msg)
	self:ParseFlag(msg, "Alliance")
end

-- Parse flag messages
function EoTS:ParseFlag(msg, faction)
	-- Flag taken
	if( string.match(msg, L["(.+) has taken the flag!"]) ) then
		carrierName = string.match(msg, L["(.+) has taken the flag!"])
		carrierFaction = faction
		
		self:UpdateCarrier()

	-- Flag captured
	elseif( string.match(msg, L["The (.+) have captured the flag!"]) ) then
		if( faction == "Alliance" ) then
			Alliance.captures = ( Alliance.captures or 0 ) + 1
			
			if( SSPVP.db.profile.eots.totalCaptures ) then
				SSOverlay:UpdateText("eots", L["Flag Captures: %d"], SSOverlay:GetFactionColor("Alliance"), Alliance.captures)
			end
		elseif( faction == "Horde" ) then
			Horde.captures = ( Horde.captures or 0 ) + 1

			if( SSPVP.db.profile.eots.totalCaptures ) then
				SSOverlay:UpdateText("eots", L["Flag Captures: %d"], SSOverlay:GetFactionColor("Horde"), Horde.captures)
			end
		end
		
		if( SSPVP.db.profile.eots.respawn ) then
			SSOverlay:UpdateTimer("eots", L["Flag Respawn: %s"], 10, SSOverlay:GetFactionColor())
		end

		carrierName = nil
		carrierFaction = nil
		
		self:UpdateCarrier()
		
	-- Flag dropped
	elseif( string.match(msg, L["The flag has been dropped"]) ) then
		carrierName = nil
		carrierFaction = nil
		
		self:UpdateCarrier()
	end
end

local function checkButtonTarget(self)
	if( UnitExists("target") and UnitName("target") == self.carrierName ) then
		UIErrorsFrame:AddMessage(string.format(L["Targetting %s"], self.carrierName), 1.0, 0.1, 0.1, 1.0)
	else
		UIErrorsFrame:AddMessage(string.format(L["%s is out of range"], self.carrierName), 1.0, 0.1, 0.1, 1.0)
	end
end

-- Update carrier attributes
function EoTS:UpdateCarrierAttributes()
	if( InCombatLockdown() ) then
		-- Update alpha to 75% if the carrier changes in combat
		if( carrierFaction == "Alliance" and carrierName ~= self.allianceText.carrierName ) then
			self.allianceText:SetAlpha(0.75)
		elseif( carrierFaction == "Horde" and carrierName ~= self.hordeText.carrierName ) then
			self.hordeText:SetAlpha(0.75)
		end
				
		SSPVP:RegisterOOCUpdate(EoTS, "UpdateCarrierAttributes")
		return
	end
	
	-- Alliance carrier
	if( carrierFaction == "Alliance" ) then
		self.allianceText:SetAlpha(1)
		self.allianceButton:SetAttribute("type", "macro")
		self.allianceButton:SetAttribute("macrotext", "/targetexact " .. carrierName)
		self.allianceButton:SetScript("PostClick", checkButtonTarget)
		self.allianceButton.carrierName = carrierName
		self.allianceButton:Show()

		self.hordeButton:Hide()

	-- Horde carrier
	elseif( carrierFaction == "Horde" ) then
		self.hordeText:SetAlpha(1)
		self.hordeButton:SetAttribute("type", "macro")
		self.hordeButton:SetAttribute("macrotext", "/targetexact " .. carrierName)
		self.hordeButton:SetScript("PostClick", checkButtonTarget)
		self.hordeButton.carrierName = carrierName
		self.hordeButton:Show()

	-- Reset all info
	else
		self.allianceText.colorSet = nil
		self.hordeText.colorSet = nil
		
		self.allianceButton.positionSet = nil
		self.hordeButton.positionSet = nil
		
		self.allianceButton.carrierName = nil
		self.hordeButton.carrierName = nil

		self.allianceButton:Hide()
		self.hordeButton:Hide()
	end
end

-- Update carrier text/button positioning
function EoTS:UpdateCarrier()
	self:UpdateCarrierAttributes()
	
	if( not carrierName or not SSPVP.db.profile.eots.carriers ) then
		return
	end

	-- The reason we don't just directly position them to the always up frames
	-- is because then they'd be secure and couldn't be moved and such in combat
	local button, text
	if( carrierFaction == "Alliance" ) then
		button = self.allianceButton
		text = self.allianceText
		
		-- Not positioned and we actually have the frames created
		if( not button.positionSet and AlwaysUpFrame1Text ) then
			button.positionSet = true

			button:ClearAllPoints()
			button:SetPoint("LEFT", UIParent, "BOTTOMLEFT", AlwaysUpFrame1Text:GetRight() + 8, AlwaysUpFrame1Text:GetTop() - 5)

			text:ClearAllPoints()
			text:SetPoint("LEFT", UIParent, "BOTTOMLEFT", AlwaysUpFrame1Text:GetRight() + 8, AlwaysUpFrame1Text:GetTop() - 5)
		end
		
	elseif( carrierFaction == "Horde" ) then
		button = self.hordeButton
		text = self.hordeText
		
		-- Not positioned and we actually have the frames created
		if( not button.positionSet and AlwaysUpFrame2Text ) then
			button.positionSet = true

			button:ClearAllPoints()
			button:SetPoint("LEFT", UIParent, "BOTTOMLEFT", AlwaysUpFrame2Text:GetRight() + 8, AlwaysUpFrame2Text:GetTop() - 5)

			text:ClearAllPoints()
			text:SetPoint("LEFT", UIParent, "BOTTOMLEFT", AlwaysUpFrame2Text:GetRight() + 8, AlwaysUpFrame2Text:GetTop() - 5)
		end
	end
	
	-- Carrier name
	text:SetText(carrierName)
	
	-- Carrier class color if enabled/not set
	if( not text.colorSet and SSPVP.db.profile.eots.color ) then
		for i=1, GetNumBattlefieldScores() do
			local name, _, _, _, _, _, _, _, _, classToken = GetBattlefieldScore(i)
			
			-- Carriers from a different server
			if( string.match(name, "-") and carrierName == (string.split( "-", name)) ) then
				text:SetTextColor(RAID_CLASS_COLORS[classToken].r, RAID_CLASS_COLORS[classToken].g, RAID_CLASS_COLORS[classToken].b)
				text.colorSet = true
				break
			
			-- Carrier from the same server as us
			elseif( name == carrierName ) then
				text:SetTextColor(RAID_CLASS_COLORS[classToken].r, RAID_CLASS_COLORS[classToken].g, RAID_CLASS_COLORS[classToken].b)
				text.colorSet = true
				break
			end
		end
	end
	
	-- Update the color to the default because we couldn't find one
	if( not text.colorSet ) then
		text:SetTextColor(GameFontNormal:GetTextColor())
	end
end	

-- Match info
function EoTS:UpdateOverlay()
	if( not SSPVP.db.profile.eots.overlay ) then
		SSOverlay:RemoveCategory("eots")
		return
	end
	
	-- Apparently, the capture bar is UI info #1
	-- hence why it's 2/3 for the info text instead of 1/2
	-- like it is for AB/WSG
	local _, _, allianceText = GetWorldStateUIInfo(2)
	local _, _, hordeText = GetWorldStateUIInfo(3)
	
	-- Parse Alliance info
	local towers, points = string.match(allianceText, L["Bases: ([0-9]+)  Victory Points: ([0-9]+)%/2000"])
	
	Alliance.towers = tonumber(towers)
	Alliance.points = tonumber(points)
	Alliance.left = 2000 - points

	Alliance.time = Alliance.left / towerInfo[Alliance.towers]
	Alliance.towersWin = 0
	
	-- Parse Horde info
	towers, points = string.match(hordeText, L["Bases: ([0-9]+)  Victory Points: ([0-9]+)%/2000"])
	
	Horde.towers = tonumber(towers)
	Horde.points = tonumber(points)
	Horde.left = 2000 - points
	Horde.time = Horde.left / towerInfo[Horde.towers]
	Horde.towersWin = 0
	
	-- Not started yet, exit quickly
	if( Horde.points == 0 and Alliance.points == 0 ) then
		return
	end

	-- Find time remaining in the match
	if( Alliance.time < Horde.time ) then
		lowest = Alliance.time
	else
		lowest = Horde.time
	end
	
	-- Display it
	if( SSPVP.db.profile.eots.timeLeft ) then
		SSOverlay:UpdateTimer("eots", L["Time Left: %s"], lowest, SSOverlay:GetFactionColor())
	end
	
	-- Calculate final scores
	Alliance.final = Alliance.points + floor(lowest * towerInfo[ Alliance.towers ] + 0.5)
	Horde.final = Horde.points + floor(lowest * towerInfo[ Horde.towers ] + 0.5)
	
	-- Display it
	if( SSPVP.db.profile.eots.finalScore ) then
		SSOverlay:UpdateText("eots", L["Final Score: %d"], SSOverlay:GetFactionColor("Alliance"), Alliance.final)
		SSOverlay:UpdateText("eots", L["Final Score: %d"], SSOverlay:GetFactionColor("Horde"), Horde.final)
	end
	
	-- Now calculate towers to win
	local enemy, friendly
	if( playerFaction == "Alliance" ) then
		enemy = Horde
		friendly = Alliance
	else
		enemy = Alliance
		friendly = Horde
	end
		
	for i=1, 4 do
		-- Calculate time left with the bases given
		local enemyTime = enemy.left / towerInfo[4 - i]
		local friendlyTime = friendly.left / towerInfo[i]
		if( enemyTime < friendlyTime ) then
			lowest = enemyTime
		else
			lowest = friendlyTime
		end
		
		-- Calculate final scores with bases given
		local enemyFinal = enemy.points + floor(lowest * towerInfo[4 - i] + 0.5)
		local friendlyFinal = friendly.points + floor(lowest * towerInfo[i] + 0.5)
		
		-- Will win with these bases
		if( friendlyFinal >= 2000 and enemyFinal < 2000 ) then
			Alliance.towersWin = i
			Horde.towersWin = i
			
			-- Show it!
			if( SSPVP.db.profile.eots.towersWin ) then
				if( not SSPVP.db.profile.eots.towersScore ) then
					SSOverlay:UpdateText("eots", L["Towers to win: %d"], SSOverlay:GetFactionColor(), i)
				else
					local allianceScore, hordeScore
					if( playerFaction == "Alliance" ) then
						allianceScore = friendlyFinal
						hordeScore = enemyFinal
					else
						allianceScore = enemyFinal
						hordeScore = friendlyFinal
					end
					
					SSOverlay:UpdateText("eots", L["Towers to win: %d (A:%d/H:%d)"], SSOverlay:GetFactionColor(), i, allianceScore, hordeScore)
				end
			end
			break
		end
	end
end

-- Use the short hand version of the scores
function EoTS:WorldStateAlwaysUpFrame_Update()
	if( AlwaysUpFrame1 ) then
		local alliance = getglobal("AlwaysUpFrame1Text")
		local bases, points = string.match(alliance:GetText(), L["Bases: ([0-9]+)  Victory Points: ([0-9]+)%/2000"])
		
		if( bases and points ) then
			alliance:SetText(string.format(L["Bases %d  Points %d/2000"], bases, points))
		end
	end
	
	if( AlwaysUpFrame2 ) then
		local horde = getglobal("AlwaysUpFrame2Text")
		local bases, points = string.match(horde:GetText(), L["Bases: ([0-9]+)  Victory Points: ([0-9]+)%/2000"])

		if( bases and points ) then
			horde:SetText(string.format( L["Bases %d  Points %d/2000"], bases, points))
		end
	end
end

-- Show/hide the border
function EoTS:SetCarrierBorders()
	if( SSPVP.db.profile.eots.border ) then
		self.allianceText:SetFont(GameFontNormal:GetFont(), 11, "OUTLINE")
		self.hordeText:SetFont(GameFontNormal:GetFont(), 11, "OUTLINE")
	else
		self.allianceText:SetFont(GameFontNormal:GetFont(), 11, nil)
		self.hordeText:SetFont(GameFontNormal:GetFont(), 11, nil)
	end
end

-- Create the carrier buttons
function EoTS:CreateCarrierButtons()
	if( not self.allianceButton ) then
		self.allianceButton = CreateFrame( "Button", nil, UIParent, "SecureActionButtonTemplate")
		self.allianceButton:SetHeight(25)
		self.allianceButton:SetWidth(150)
		self.allianceButton:SetScript("PostClick", function()
			if( IsAltKeyDown() and carrierName ) then
				SSPVP:ChannelMessage(string.format( L["Alliance flag carrier %s"], carrierName))
			end
		end )

		self.allianceText = self.allianceButton:CreateFontString(nil, "BACKGROUND")
		self.allianceText:SetJustifyH("LEFT")
		self.allianceText:SetHeight(25)
		self.allianceText:SetWidth(150)
	end
	
	if( not self.hordeButton ) then
		self.hordeButton = CreateFrame("Button", nil, UIParent, "SecureActionButtonTemplate")
		self.hordeButton:SetHeight(25)
		self.hordeButton:SetWidth(150)
		self.hordeButton:SetScript("PostClick", function()
			if( IsAltKeyDown() and carrierName ) then
				SSPVP:ChannelMessage(string.format(L["Horde flag carrier %s"], carrierName))
			end
		end)

		self.hordeText = self.hordeButton:CreateFontString(nil, "BACKGROUND")
		self.hordeText:SetJustifyH("LEFT")
		self.hordeText:SetHeight(25)
		self.hordeText:SetWidth(150)
	end
	
	self:SetCarrierBorders()
end