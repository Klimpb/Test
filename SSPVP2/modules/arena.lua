local Arena = SSPVP:NewModule("Arena", "AceEvent-3.0", "AceConsole-3.0")
Arena.activeIn = "arena"

local L = SSPVPLocals

-- Blizzard likes to change this monthly, so lets just store it here to make it easier
local pointPenalty = {[5] = 1.0, [3] = 0.88, [2] = 0.76}

local arenaTeams = {}

function Arena:OnInitialize()
	self.defaults = {
		profile = {
			score = true,
			personal = true,
		},
	}
	
	self.db = SSPVP.db:RegisterNamespace("arena", self.defaults)
	self:RegisterSlashCommands()
end

function Arena:OnEnable()
	-- Load the inspection stuff, or wait for it to load
	if( IsAddOnLoaded("Blizzard_InspectUI") ) then
		hooksecurefunc("InspectPVPTeam_Update", self.InspectPVPTeam_Update)
	else
		self:RegisterEvent("ADDON_LOADED")
	end
end

function Arena:OnDisable()
	self:UnregisterAllEvents()
end

function Arena:EnableModule()
	if( self.db.profile.score ) then
		self:RegisterEvent("UPDATE_BATTLEFIELD_STATUS")
	end
end

function Arena:DisableModule()
	self:UnregisterEvent("UPDATE_BATTLEFIELD_STATUS")

	-- Grab new data for next game
	for i=MAX_ARENA_TEAMS, 1, -1 do
		ArenaTeamRoster(i)
	end
end

function Arena:Reload()
	if( self.isActive ) then
		self:UnregisterAllEvents()
		self:EnableModule()
	end
end

-- Check if inspect UI loaded
function Arena:ADDON_LOADED(event, addon)
	if( addon == "Blizzard_InspectUI" ) then
		hooksecurefunc("InspectPVPTeam_Update", self.InspectPVPTeam_Update)
		self:UnregisterEvent("ADDON_LOADED")
	end
end

-- Conversions
-- Points gained/lost from beating teams
-- 1644 vs 1680, gained 17 / 1661 vs 1703, lost 14
local function getChange(aRate, bRate, aWon)	
	local aChance = 1 / ( 1 + 10 ^ ( ( bRate - aRate ) / 400 ) )
	local bChance = 1 / ( 1 + 10 ^ ( ( aRate - bRate ) / 400 ) )

	local aNew, bNew
	if( aWon ) then
		aNew = math.floor(aRate + 32 * (1 - aChance))
		bNew = math.ceil(bRate + 32 * (0 - bChance))
	else
		aNew = math.ceil(aRate + 32 * (0 - aChance))
		bNew = math.floor(bRate + 32 * (1 - bChance))
	end

	-- aNew, aDiff, bNew, bDiff
	return aNew, aNew - aRate, bNew, bNew - bRate
end


-- RATING -> POINTS
local function getPoints(rating, teamSize)
	local penalty = pointPenalty[teamSize or 5]
	
	local points = 0
	if( rating > 1500 ) then
		points = (1511.26 / (1 + 1639.28 * math.exp(1) ^ (-0.00412 * rating))) * penalty
	else
		points = ((0.22 * rating ) + 14) * penalty
	end
	
	if( points < 0 or points ~= points ) then
		points = 0
	end
	
	return points
end

-- POINTS -> RATING
local function getRating(points, teamSize)
	local penalty = pointPenalty[teamSize or 5]
	
	local rating = 0
	if( points > getPoints(1500, teamSize) ) then
		rating = (math.log(((1511.26 * penalty / points) - 1) / 1639.28) / -0.00412)
	else
		rating = ((points / penalty - 14) / 0.22 )
	end
	
	rating = math.floor(rating + 0.5)
	
	if( rating ~= rating or rating < 0 ) then
		rating = 0
	end
	
	return rating
end

-- Rating/personal rating change
-- How many points gained/lost
function Arena:UPDATE_BATTLEFIELD_STATUS()
	if( GetBattlefieldWinner() and select(2, IsActiveBattlefieldArena()) ) then
		-- Check if we had a bugged game and thus no rating change
		for i=0, 1 do
			local oldRating, newRating = select(2, GetBattlefieldTeamInfo(1))
			if( oldRating == newRating ) then
				SSPVP:Print(L["Bugged or drawn game, no rating changed."])
				return
			end
		end

		-- Figure out what bracket we're in
		local bracket
		for i=1, MAX_BATTLEFIELD_QUEUES do
			local status, _, _, _, _, teamSize = GetBattlefieldStatus(i)
			if( status == "active" ) then
				bracket = teamSize
				break
			end
		end
		
		-- Failed (bad)
		if( not bracket ) then
			return
		end

		-- Grab player team info, watching the event seems to have issues so we do it this way instead
		for i=1, MAX_ARENA_TEAMS do
			local teamName, teamSize, _, _, _, _, _, _, _, _, playerRating = GetArenaTeam(i)
			if( teamName ) then
				local id = teamName .. teamSize

				if( not arenaTeams[id] ) then
					arenaTeams[id] = {}
				end

				arenaTeams[id].size = teamSize
				arenaTeams[id].index = i
				arenaTeams[id].personal = playerRating
			end
		end

		-- Ensure that the players team is shown first
		local firstInfo, secondInfo, playerWon, playerPersonal, enemyRating
		for i=0, 1 do
			local teamName, oldRating, newRating = GetBattlefieldTeamInfo(i)
			if( arenaTeams[teamName .. bracket] ) then
				firstInfo = string.format(L["%s %d points (%d rating)"], teamName, newRating - oldRating, newRating)
				
				-- Only show our personal rating change if it's different from our teams rating
				if( playerPersonal ~= oldRating ) then
					playerPersonal = arenaTeams[teamName .. bracket].personal
				end
				
				if( newRating > oldRating ) then
					playerWon = true
				end
			else
				secondInfo = string.format(L["%s %d points (%d rating)"], teamName, newRating - oldRating, newRating)
				enemyRating = oldRating
			end
		end
		
		
		local personal = ""
		if( self.db.profile.personal and playerPersonal ) then
			-- Figure out our personal rating change
			local newPersonal, personalDiff = getChange(playerPersonal, enemyRating, playerWon)
			personal = string.format(L["/ %d personal (%d rating)"], personalDiff, newPersonal)
		end		
		
		SSPVP:Print(string.format("%s / %s %s", firstInfo, secondInfo, personal))
	end
end

local function convertPointsRating(self)
	local points = self:GetNumber()
	

	Arena.frame.pointText2:SetFormattedText(L["[%d vs %d] %d points = %d rating"], 2, 2, points, getRating(points, 2))
	Arena.frame.pointText3:SetFormattedText(L["[%d vs %d] %d points = %d rating"], 3, 3, points, getRating(points, 3))
	Arena.frame.pointText5:SetFormattedText(L["[%d vs %d] %d points = %d rating"], 5, 5, points, getRating(points, 5))
end

local function convertRatingsPoint(self)
	local rating = self:GetNumber()
	
	
	Arena.frame.ratingText2:SetFormattedText(L["[%d vs %d] %d rating = %d points"], 5, 5, rating, getPoints(rating, 5))
	Arena.frame.ratingText3:SetFormattedText(L["[%d vs %d] %d rating = %d points"], 3, 3, rating, getPoints(rating, 3))
	Arena.frame.ratingText5:SetFormattedText(L["[%d vs %d] %d rating = %d points"], 2, 2, rating, getPoints(rating, 2))
end

local function getArenaChange(self)
	local teamA = Arena.frame.teamA:GetNumber()
	local teamB = Arena.frame.teamB:GetNumber()
	
	local aNew, aDiff, bNew, bDiff = getChange(teamA, teamB, true)
	Arena.frame.teamAText:SetFormattedText(L["Won: %d rating (%d points gained)"], aNew, aDiff)
	Arena.frame.teamBText:SetFormattedText(L["Lost: %d rating (%d points lost)"], bNew, bDiff)
end

function Arena:CreateUI()
	if( self.frame ) then
		return
	end
	
	self.frame = CreateFrame("Frame", "SSArenaGUI", UIParent)
	self.frame:SetWidth(225)
	self.frame:SetHeight(265)
	self.frame:SetMovable(true)
	self.frame:EnableMouse(true)
	self.frame:SetClampedToScreen(true)
	self.frame:SetPoint("CENTER")
	self.frame:SetBackdrop({
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		edgeSize = 26,
		insets = {left = 9, right = 9, top = 9, bottom = 9},
	})
	
	table.insert(UISpecialFrames, "SSArenaGUI")

	-- Create the title/movy thing
	local texture = self.frame:CreateTexture(nil, "ARTWORK")
	texture:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
	texture:SetPoint("TOP", 0, 12)
	texture:SetWidth(175)
	texture:SetHeight(60)
	
	local title = CreateFrame("Button", nil, self.frame)
	title:SetPoint("TOP", 0, 4)
	title:SetText("SSPVP")
	title:SetPushedTextOffset(0, 0)

	title:SetTextFontObject(GameFontNormal)
	title:SetHeight(20)
	title:SetWidth(200)
	title:RegisterForDrag("LeftButton")
	title:SetScript("OnDragStart", function(self)
		self.isMoving = true
		Arena.frame:StartMoving()
	end)
	
	title:SetScript("OnDragStop", function(self)
		if( self.isMoving ) then
			self.isMoving = nil
			Arena.frame:StopMovingOrSizing()
		end
	end)
	
	-- Close the panel
	local button = CreateFrame("Button", nil, self.frame, "UIPanelCloseButton")
	button:SetPoint("TOPRIGHT", -1, -1)
	button:SetScript("OnClick", function()
		HideUIPanel(Arena.frame)
	end)

	-- Points -> Rating
	local points = CreateFrame("EditBox", "SSArenaPoints", self.frame, "InputBoxTemplate")
	points:SetHeight(20)
	points:SetWidth(60)
	points:SetAutoFocus(false)
	points:SetNumeric(true)
	points:ClearAllPoints()
	points:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 20, -30)
	points:SetScript("OnTextChanged", convertPointsRating)
	
	self.frame.points = points
	
	-- Now the actual text
	self.frame.pointText2 = points:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	self.frame.pointText2:SetHeight(15)
	self.frame.pointText2:SetPoint("BOTTOMLEFT", points, "BOTTOMLEFT", -5, -20)

	self.frame.pointText3 = points:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	self.frame.pointText3:SetHeight(15)
	self.frame.pointText3:SetPoint("BOTTOMLEFT", self.frame.pointText2, "BOTTOMLEFT", 0, -15)

	self.frame.pointText5 = points:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	self.frame.pointText5:SetHeight(15)
	self.frame.pointText5:SetPoint("BOTTOMLEFT", self.frame.pointText3, "BOTTOMLEFT", 0, -15)
	
	-- 344 = 1500 rating in 5s
	points:SetNumber(344)
	points:SetMaxLetters(4)
	
	-- Rating -> Points
	local rating = CreateFrame("EditBox", "SSArenaRatings", self.frame, "InputBoxTemplate")
	rating:SetHeight(20)
	rating:SetWidth(60)
	rating:SetAutoFocus(false)
	rating:SetNumeric(true)
	rating:ClearAllPoints()
	rating:SetPoint("BOTTOMLEFT", self.frame.pointText5, "BOTTOMLEFT", 5, -30)
	rating:SetScript("OnTextChanged", convertRatingsPoint)
	
	self.frame.rating = rating
	
	-- Now the actual text
	self.frame.ratingText2 = rating:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	self.frame.ratingText2:SetHeight(15)
	self.frame.ratingText2:SetPoint("BOTTOMLEFT", rating, "BOTTOMLEFT", -5, -20)

	self.frame.ratingText3 = rating:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	self.frame.ratingText3:SetHeight(15)
	self.frame.ratingText3:SetPoint("BOTTOMLEFT", self.frame.ratingText2, "BOTTOMLEFT", 0, -15)

	self.frame.ratingText5 = rating:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	self.frame.ratingText5:SetHeight(15)
	self.frame.ratingText5:SetPoint("BOTTOMLEFT", self.frame.ratingText3, "BOTTOMLEFT", 0, -15)
	
	-- 344 = 1500 rating in 5s
	rating:SetNumber(1500)
	rating:SetMaxLetters(4)
	
	-- Rating change based on winning or losing
	local teamA = CreateFrame("EditBox", "SSArenaRatingA", self.frame, "InputBoxTemplate")
	teamA:SetHeight(20)
	teamA:SetWidth(60)
	teamA:SetAutoFocus(false)
	teamA:SetNumeric(true)
	teamA:ClearAllPoints()
	teamA:SetPoint("BOTTOMLEFT", self.frame.ratingText5, "BOTTOMLEFT", 5, -30)
	teamA:SetScript("OnTextChanged", getArenaChange)
	teamA:SetScript("OnTabPressed", function() Arena.frame.teamB:SetFocus() end)

	self.frame.teamA = teamA

	self.frame.teamVs = rating:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	self.frame.teamVs:SetHeight(15)
	self.frame.teamVs:SetText(L["Vs"])
	self.frame.teamVs:SetPoint("TOPRIGHT", teamA, "TOPRIGHT", 28, -3)

	local teamB = CreateFrame("EditBox", "SSArenaRatingB", self.frame, "InputBoxTemplate")
	teamB:SetHeight(20)
	teamB:SetWidth(60)
	teamB:SetAutoFocus(false)
	teamB:SetNumeric(true)
	teamB:ClearAllPoints()
	teamB:SetPoint("TOPRIGHT", self.frame.teamVs, "TOPRIGHT", 80, 3)
	teamB:SetScript("OnTextChanged", getArenaChange)
	teamB:SetScript("OnTabPressed", function() Arena.frame.teamA:SetFocus() end)
	
	self.frame.teamB = teamB
	
	-- Display text
	self.frame.teamAText = rating:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	self.frame.teamAText:SetHeight(15)
	self.frame.teamAText:SetPoint("BOTTOMLEFT", teamA, "BOTTOMLEFT", -5, -20)

	self.frame.teamBText = rating:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	self.frame.teamBText:SetHeight(15)
	self.frame.teamBText:SetPoint("BOTTOMLEFT", self.frame.teamAText, "BOTTOMLEFT", 0, -15)
		
	-- Defaults
	teamA:SetMaxLetters(4)
	teamA:SetNumber(1600)
	

	teamB:SetMaxLetters(4)
	teamB:SetNumber(1500)
end

-- Slash commands
function Arena:RegisterSlashCommands()
	-- Slash commands for conversions
	self:RegisterChatCommand("arena", function(input)
		-- Points -> rating
		if( string.match(input, "points ([0-9]+)") ) then
			local points = tonumber(string.match(input, "points ([0-9]+)"))

			SSPVP:Print(string.format(L["[%d vs %d] %d points = %d rating"], 5, 5, points, getRating(points)))
			SSPVP:Print(string.format(L["[%d vs %d] %d points = %d rating"], 3, 3, points, getRating(points, 3)))
			SSPVP:Print(string.format(L["[%d vs %d] %d points = %d rating"], 2, 2, points, getRating(points, 2)))
		
		-- Rating -> points
		elseif( string.match(input, "rating ([0-9]+)") ) then
			local rating = tonumber(string.match(input, "rating ([0-9]+)"))

			SSPVP:Print(string.format(L["[%d vs %d] %d rating = %d points"], 5, 5, rating, getPoints(rating)))
			SSPVP:Print(string.format(L["[%d vs %d] %d rating = %d points - %d%% = %d points"], 3, 3, rating, getPoints(rating), pointPenalty[3] * 100, getPoints(rating, 3)))
			SSPVP:Print(string.format(L["[%d vs %d] %d rating = %d points - %d%% = %d points"], 2, 2, rating, getPoints(rating), pointPenalty[2] * 100, getPoints(rating, 2)))

		-- Rating changes if you win/lose against a certain rating
		elseif( string.match(input, "change ([0-9]+) ([0-9]+)") ) then
			local aRating, bRating = string.match(input, "change ([0-9]+) ([0-9]+)")
			local aNew, aDiff, bNew, bDiff = getChange(tonumber(aRating), tonumber(bRating), true)
			
			SSPVP:Print(string.format(L["+%d points (%d rating) / %d points (%d rating)"], aDiff, aNew, bDiff, bNew))
			
		-- Games required for 30%
		elseif( string.match(input, "attend ([0-9]+) ([0-9]+)") ) then
			local played, teamPlayed = string.match(input, "attend ([0-9]+) ([0-9]+)")
			local percent = played / teamPlayed
			
			if( percent >= 0.30 ) then
				-- Make sure we don't show it as being above 100%
				if( percent > 1.0 ) then
					percent = 1.0
				end

				SSPVP:Print(string.format(L["%d games out of %d total is already above 30%% (%.2f%%)."], played, teamPlayed, percent * 100))
			else
				local gamesNeeded = math.ceil(((0.3 - percent) / 0.70) * teamPlayed)
				SSPVP:Print(string.format(L["%d more games have to be played (%d total) to reach 30%%."], gamesNeeded, teamPlayed + gamesNeeded))
			end
		
		-- GUI
		elseif( input == "ui" ) then
			Arena:CreateUI()
			Arena.frame:Show()
		else
			DEFAULT_CHAT_FRAME:AddMessage(L["SSPVP Arena slash commands"])
			DEFAULT_CHAT_FRAME:AddMessage(L[" - rating <rating> - Calculates points given from the passed rating."])
			DEFAULT_CHAT_FRAME:AddMessage(L[" - points <points> - Calculates rating required to reach the passed points."])
			DEFAULT_CHAT_FRAME:AddMessage(L[" - attend <played> <team> - Calculates games required to reach 30% using the passed games <played> out of the <team> games played."])
			DEFAULT_CHAT_FRAME:AddMessage(L[" - change <winner rating> <loser rating> - Calculates points gained/lost assuming the <winner rating> beats <loser rating>."])
			DEFAULT_CHAT_FRAME:AddMessage(L[" - ui - Shows a small UI for entering rating/point/attendance/change info."])
		end
	end)
end

-- This is a quick fix so we don't have stats showing up even after you've left a team
local function hideCustomOptions(self)
	self.seasonWin:Hide()
	self.seasonLoss:Hide()
	self.seasonGames:Hide()
	self.seasonPlayed:Hide()
	self.seasonPlayedPercent:Hide()
	self.seasonWinPercent:Hide()
	self.seasonText:Hide()
	self.dashText:Hide()

	self.weekPlayed:Hide()
	self.weekPlayedPercent:Hide()
	self.weekWinPercent:Hide()
end

-- Inspection and players arena info uses the same base names
function Arena:UpdateDisplay(parent, isInspect, ...)
	local teamName, teamSize, teamRating, weekPlayed, weekWins, seasonPlayed, seasonWins, playerPlayed, seasonPlayerPlayed, teamRank, playerRating = select(1, ...)
	if( teamRating == 0 ) then
		return
	end

	-- Add points gained next to the rating
	local name = parent .. "Data"
	
	-- Shift the actual rating text down to the left to make room for our changes
	local label = getglobal(name .. "RatingLabel")
	label:SetText(L["Rating"])
	label:SetPoint("LEFT", name .. "Name", "RIGHT", -32, 0)

	-- Shift the rating to match the rating label + Set it
	local ratingText = getglobal(name .. "Rating")
	ratingText:SetText(string.format("%d |cffffffff(%d)|r", teamRating, getPoints(teamRating, teamSize)))
	ratingText:SetWidth(70)
	ratingText:ClearAllPoints()
	ratingText:SetPoint("LEFT", label, "RIGHT", 2, 0)

	-- Resize team name so it doesn't overflow into our rating
	getglobal(name .. "Name"):SetWidth(150)

	-- Can't get week info
	if( isInspect ) then
		return
	end

	-- Reposition the week/season stats
	local parentFrame = getglobal(parent)
	if( not parentFrame.SSUpdated ) then
		parentFrame.SSUpdated = true
		
		if( parentFrame:GetScript("OnHide") ) then
			parentFrame:HookScript("OnHide", hideCustomOptions)
		else
			parentFrame:SetScript("OnHide", hideCustomOptions)
		end
		
		-- Shift played percentage/games up
		local label = getglobal(name .. "TypeLabel")
		label:ClearAllPoints()
		label:SetPoint("BOTTOMLEFT", name .. "Name", "BOTTOMLEFT", 0, -24)
		
		-- Hide games/played/-/wins/loses label, and shift them down a bit
		local label = getglobal(name .. "GamesLabel")
		label:ClearAllPoints()
		label:SetPoint("BOTTOMLEFT", name .. "TypeLabel", "BOTTOMRIGHT", -28, 16)
		label:Hide()
		
		local label = getglobal(name .. "WinLossLabel")
		label:ClearAllPoints()
		label:SetPoint("LEFT", name .. "GamesLabel", "RIGHT", -14, 0)
		label:Hide()
		
		local label = getglobal(name .. "PlayedLabel")
		label:ClearAllPoints()
		label:SetPoint("LEFT", name .. "WinLossLabel", "RIGHT", 10, 0)
		label:Hide()

		-- Create our custom widgets
		local season = parentFrame:CreateFontString(nil, "BACKGROUND", "GameFontHighlightSmall")
		season:SetPoint("BOTTOMLEFT", name .. "Name", "BOTTOMLEFT", 0, -41)
		season:SetJustifyH("LEFT")
		season:SetJustifyV("BOTTOM")
		season:SetText(L["Season"])
		
		-- Total season played
		local game = parentFrame:CreateFontString(nil, "BACKGROUND", "GameFontHighlightSmall")
		game:SetPoint("TOP", name .. "Games", "BOTTOM", 0, -7)

		-- Divider won/lost
		local dash = parentFrame:CreateFontString(nil, "BACKGROUND", "GameFontHighlightSmall")
		dash:SetPoint("TOP", name .. "-", "BOTTOM", 0, -7)
		dash:SetText(" - ")
		
		-- Total season won
		local win = parentFrame:CreateFontString(nil, "BACKGROUND", "GameFontHighlightSmall")
		win:SetPoint("RIGHT", dash, "LEFT", 0, 0)

		-- Total season lost
		local loss = parentFrame:CreateFontString(nil, "BACKGROUND", "GameFontHighlightSmall")
		loss:SetPoint("LEFT", dash, "RIGHT", 0, 0)
		
		-- Week win percent
		local winPercent = parentFrame:CreateFontString(nil, "BACKGROUND", "GameFontHighlightSmall")
		winPercent:SetPoint("LEFT", dash, "RIGHT", 25, 0)
		
		-- Season played percent
		local seasonPercent = parentFrame:CreateFontString(nil, "BACKGROUND", "GameFontHighlightSmall")
		seasonPercent:SetPoint("BOTTOMRIGHT", name .. "Rating", "BOTTOMRIGHT", -8, -41)
	
		-- Week percent played
		local weekPercent = parentFrame:CreateFontString(nil, "BACKGROUND", "GameFontHighlightSmall")
		weekPercent:SetPoint("BOTTOMRIGHT", name .. "Rating", "BOTTOMRIGHT", -8, -24)

		-- Week win percent
		local weekWinPercent = parentFrame:CreateFontString(nil, "BACKGROUND", "GameFontHighlightSmall")
		weekWinPercent:SetPoint("BOTTOMRIGHT", name .. "-" , "BOTTOMRIGHT", 60, 0)

		-- Season win percent
		local seasonWinPercent = parentFrame:CreateFontString(nil, "BACKGROUND", "GameFontHighlightSmall")
		seasonWinPercent:SetPoint("BOTTOMRIGHT", dash, "BOTTOMRIGHT", 60, 0)
		
		-- Season player rating
		local played = parentFrame:CreateFontString(nil, "BACKGROUND", "GameFontHighlightSmall")
		played:SetPoint("BOTTOMRIGHT", name .. "Rating", "BOTTOMRIGHT", -50, -41)

		-- Week # played
		local weekPlayed = parentFrame:CreateFontString(nil, "BACKGROUND", "GameFontHighlightSmall")
		weekPlayed:SetPoint("BOTTOMRIGHT", name .. "Rating", "BOTTOMRIGHT", -50, -24)

		parentFrame.seasonWin = win
		parentFrame.seasonLoss = loss
		parentFrame.seasonGames = game
		parentFrame.seasonPlayed = played
		parentFrame.seasonPlayedPercent = seasonPercent
		parentFrame.seasonWinPercent = seasonWinPercent
		parentFrame.seasonText = season
		parentFrame.dashText = dash
		
		parentFrame.weekPlayed = weekPlayed
		parentFrame.weekPlayedPercent = weekPercent
		parentFrame.weekWinPercent = weekWinPercent
	end
	
	-- DISPLAY!
	parentFrame.dashText:Show()
	parentFrame.seasonText:Show()

	-- WEEK
	getglobal(name .. "TypeLabel"):SetText(L["Week"])
	getglobal(name .. "Played"):Hide()
	 
	getglobal(name .. "Games"):SetText(weekPlayed)
	getglobal(name .. "Wins"):SetText(weekWins)
	getglobal(name .. "Loss"):SetText(weekPlayed - weekWins)		
	
	
	-- Played for this week
	local percent = playerPlayed / weekPlayed
	if( percent ~= percent ) then
		percent = 0
	end
	
	local color = "|cff20ff20"
	if( percent < 0.30 ) then
		color = "|cffff2020"
	end
	
	parentFrame.weekPlayed:SetFormattedText("%d", playerPlayed)
	parentFrame.weekPlayed:Show()
	parentFrame.weekPlayedPercent:SetFormattedText("[%s%d%%%s]", color, percent * 100, FONT_COLOR_CODE_CLOSE)
	parentFrame.weekPlayedPercent:SetVertexColor(1.0, 1.0, 1.0)
	parentFrame.weekPlayedPercent:Show()
	
	-- Win percent for the week
	local percent = weekWins / weekPlayed
	if( percent ~= percent ) then
		percent = 0	
	end
	
	local color = "|cffffffff"
	if( percent > 0.60 ) then
		color = "|cff20ff20"
	elseif( percent < 0.30 ) then
		color = "|cffff2020"
	end
	
	parentFrame.weekWinPercent:SetFormattedText("[%s%d%%%s]", color, percent * 100, FONT_COLOR_CODE_CLOSE)
	parentFrame.weekWinPercent:Show()
	
	-- SEASON
	parentFrame.seasonWin:SetText(seasonWins)
	parentFrame.seasonWin:Show()
	parentFrame.seasonLoss:SetText(seasonPlayed - seasonWins)
	parentFrame.seasonLoss:Show()
	parentFrame.seasonGames:SetText(seasonPlayed)
	parentFrame.seasonGames:Show()
	
	-- Do we want to show percent, or personal?
	local percent = seasonPlayerPlayed / seasonPlayed
	if( percent ~= percent ) then
		percent = 0
	end
	
	local color = "|cff20ff20"
	if( percent < 0.30 ) then
		color = "|cffff2020"
	end

	parentFrame.seasonPlayed:SetFormattedText("%d", playerRating)
	parentFrame.seasonPlayed:Show()
	parentFrame.seasonPlayedPercent:SetFormattedText("[%s%d%%%s]", color, percent * 100, FONT_COLOR_CODE_CLOSE)
	parentFrame.seasonPlayedPercent:SetVertexColor(1.0, 1.0, 1.0)
	parentFrame.seasonPlayedPercent:Show()

	local percent = seasonWins / seasonPlayed
	if( percent ~= percent ) then
		percent = 0	
	end
	
	local color = "|cffffffff"
	if( percent > 0.60 ) then
		color = "|cff20ff20"
	elseif( percent < 0.30 ) then
		color = "|cffff2020"
	end
	
	parentFrame.seasonWinPercent:SetFormattedText("[%s%d%%%s]", color, percent * 100, FONT_COLOR_CODE_CLOSE)
	parentFrame.seasonWinPercent:Show()
end

-- Modifies the team details page to show percentage of games played
hooksecurefunc("PVPTeamDetails_Update", function()
	local _, _, _, teamPlayed, _,  seasonTeamPlayed = GetArenaTeam(PVPTeamDetails.team)
	for i=1, GetNumArenaTeamMembers(PVPTeamDetails.team, 1) do
		local playedText = getglobal("PVPTeamDetailsButton" .. i .. "Played")
		local name, rank, _, _, online, played, _, seasonPlayed = GetArenaTeamRosterInfo(PVPTeamDetails.team, i)
		
		-- So we can show whos leader
		if( rank == 0 and not online ) then
			getglobal("PVPTeamDetailsButton" .. i .. "NameText"):SetText(string.format(L["(L) %s"], name))
		end
		
		-- Show decimal of games played instead of rounding
		if( PVPTeamDetails.season and seasonPlayed > 0 and seasonTeamPlayed > 0 ) then
			percent = seasonPlayed / seasonTeamPlayed
		elseif( played > 0 and teamPlayed > 0 ) then
			percent = played / teamPlayed
		else
			percent = 0
		end
		
		playedText.tooltip = string.format("%.2f%%", percent * 100)
	end
end)

-- Player frame
hooksecurefunc("PVPTeam_Update", function()
	local teams = {{size = 2}, {size = 3}, {size = 5}}
	
	-- Figure out which teams they have
	for _, value in pairs(teams) do
		for i=1, MAX_ARENA_TEAMS do
			local teamName, teamSize = GetArenaTeam(i)
			if( value.size == teamSize ) then
				value.index = i
			end
		end
	end

	-- Annd now display
	local buttonIndex = 0
	for _, value in pairs(teams) do
		if( value.index ) then
			buttonIndex = buttonIndex + 1 
			Arena:UpdateDisplay("PVPTeam" .. buttonIndex, nil, GetArenaTeam(value.index))
		end
	end
	
	-- Hide the season toggle
	PVPFrameToggleButton:Hide()
end)

-- Inspection frame
function Arena:InspectPVPTeam_Update()
	local teams = {{size = 2}, {size = 3}, {size = 5}}

	-- Figure out which teams they have
	for _, value in pairs(teams) do
		for i=1, MAX_ARENA_TEAMS do
			local teamName, teamSize = GetInspectArenaTeamData(i)
			if( value.size == teamSize ) then
				value.index = i
			end
		end
	end
	
	-- Annd now display
	local buttonIndex = 0
	for _, value in pairs(teams) do
		if( value.index ) then
			buttonIndex = buttonIndex + 1
			
			local teamName, teamSize, teamRating = GetInspectArenaTeamData(value.index)
			if( teamName ) then
				getglobal("InspectPVPTeam" .. buttonIndex .. "DataName"):SetText(string.format(L["%s |cffffffff(%dvs%d)|r"], teamName, teamSize, teamSize))
				Arena:UpdateDisplay("InspectPVPTeam" .. buttonIndex, true, GetInspectArenaTeamData(value.index))
			end
		end
	end
end

