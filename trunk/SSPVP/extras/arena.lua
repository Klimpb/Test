local Arena = SSPVP:NewModule("SSPVP-Arena")
local L = SSPVPLocals

-- Blizzard likes to change this monthly, so lets just store it here to make it easier
local pointPenalty = {[5] = 1.0, [3] = 0.88, [2] = 0.76}

function Arena:Initialize()
	if( not IsAddOnLoaded("Blizzard_InpsectUI") ) then
		self:RegisterEvent("ADDON_LOADED")
	else
		hooksecurefunc("InspectPVPTeam_Update", self.InspectPVPTeam_Update)	
	end

	hooksecurefunc("PVPTeam_Update", self.PVPTeam_Update)
	hooksecurefunc("PVPTeamDetails_Update", self.PVPTeamDetails_Update)

	SSPVP.cmd:RegisterSlashHandler(L["points <rating> - Calculates how much points you will gain with the given rating"], "points (%d+)", self.CalculatePoints)
	SSPVP.cmd:RegisterSlashHandler(L["rating <points> - Calculates what rating you will need to gain the given points"], "rating (%d+)", self.CalculateRating)
	SSPVP.cmd:RegisterSlashHandler(L["percent <playedGames> <totalGames> - Calculates how many games you will need to play to reach 30% using the passed played games and total games."], "percent (%d+) (%d+)", self.CalculateGoal)
end

-- Stealth buff timer
function Arena:CHAT_MSG_BG_SYSTEM_NEUTRAL(event, message)
	if( message == L["The Arena battle has begun!"] ) then
		SSOverlay:UpdateTimer("arena", L["Stealth buff: %s"], 92)
	end
end

-- Calculates RATING -> POINTS
local function GetPoints(rating, teamSize)
	teamSize = teamSize or 5
	local penalty = pointPenalty[teamSize]
	
	local points = 0
	if( rating > 1500 ) then
		points = (1511.26 / (1 + 1639.28 * math.exp(1) ^ (-0.00412 * rating))) * penalty
	else
		points = ((0.22 * rating ) + 14) * penalty
	end
	
	if( points < 0 ) then
		points = 0
	end
	
	return points
end

-- Calculates POINTS -> RATING
local function GetRating(points, teamSize)
	teamSize = teamSize or 5
	local penalty = pointPenalty[teamSize]
	
	local rating = 0
	if( points > GetPoints(1500, teamSize) ) then
		rating = (math.log(((1511.26 * penalty / points) - 1) / 1639.28) / -0.00412)
	else
		rating = ((points / penalty - 14) / 0.22 )
	end
	
	rating = math.floor(rating + 0.5)
	
	-- Can the new formula go below 0?
	if( rating < 0 ) then
		rating = 0
	end
	
	return rating
end

-- Inspect/player arena team info changes
function Arena:ADDON_LOADED( event, addon )
	if( addon == "Blizzard_InspectUI" ) then
		hooksecurefunc("InspectPVPTeam_Update", self.InspectPVPTeam_Update)
		self:UnregisterEvent("ADDON_LOADED")
	end
end

-- Modifies the team details page to show percentage of games played
function Arena:PVPTeamDetails_Update()
	if( not SSPVP.db.profile.arena.modify ) then
		return
	end
	
	local _, _, _, teamPlayed, _,  seasonTeamPlayed = GetArenaTeam(PVPTeamDetails.team)

	for i=1, GetNumArenaTeamMembers(PVPTeamDetails.team, 1) do
		local playedText = getglobal("PVPTeamDetailsButton" .. i .. "Played")
		local name, rank, _, _, online, played, _, seasonPlayed = GetArenaTeamRosterInfo(PVPTeamDetails.team, i)
		
		if( rank == 0 and not online ) then
			getglobal("PVPTeamDetailsButton" .. i .. "NameText"):SetText(string.format(L["(L) %s"], name))
		end
		
		-- Fix the percentage to calculate correctly
		if( PVPTeamDetails.season and seasonPlayed > 0 and seasonTeamPlayed > 0 ) then
			percent = seasonPlayed / seasonTeamPlayed
		elseif( played > 0 and teamPlayed > 0 ) then
			percent = played / teamPlayed
		else
			percent = 0
		end
		
		playedText.tooltip = string.format("%.2f%%", percent * 100)
	end
end

-- Update the frame with the rating info
function Arena:SetRating(parent, teamSize, teamRating)
	if( teamRating == 0 ) then
		return
	end

	local ratingText = getglobal(parent .. "DataRating")
	local label = getglobal(parent.. "DataRatingLabel")

	ratingText:ClearAllPoints()
	ratingText:SetPoint("LEFT", parent .. "DataRatingLabel", "RIGHT", 2, 0)

	label:ClearAllPoints()
	label:SetPoint("LEFT", parent .. "DataName", "RIGHT", -19, 0)

	ratingText:SetText( string.format( "%d |cffffffff(%d)|r", teamRating, GetPoints(teamRating, teamSize) ) )
	ratingText:SetWidth(70)

	getglobal(parent .. "DataName"):SetWidth(160)
end

-- Add points next to rating
function Arena:PVPTeam_Update()
	if( not SSPVP.db.profile.arena.modify ) then
		return
	end

	local teams = {{size = 2}, {size = 3}, {size = 5}}
	
	for _, value in pairs(teams) do
		for i=1, MAX_ARENA_TEAMS do
			local teamName, teamSize = GetArenaTeam(i)
			if( value.size == teamSize ) then
				value.index = i
			end
		end
	end

	local buttonIndex = 0
	for _, value in pairs(teams) do
		if( value.index ) then
			buttonIndex = buttonIndex + 1 
			local _, _, teamRating, teamPlayed, _, seasonTeamPlayed, _, playerPlayed, seasonPlayerPlayed = GetArenaTeam(value.index)
			
			if( PVPFrame.season and seasonPlayerPlayed > 0 and seasonTeamPlayed > 0 ) then
				percent = seasonPlayerPlayed / seasonTeamPlayed
				playerPlayed = seasonPlayerPlayed

			elseif( playerPlayed > 0 and teamPlayed > 0 ) then
				percent = playerPlayed / teamPlayed
			else
				percent = 0
				playerPlayed = 0
			end

			if( percent < 0.10 ) then
				getglobal("PVPTeam" .. buttonIndex .."DataPlayed"):SetVertexColor(1.0, 0, 0)
			else
				getglobal("PVPTeam" .. buttonIndex .."DataPlayed"):SetVertexColor(1.0, 1.0, 1.0)
			end

			getglobal("PVPTeam" .. buttonIndex .. "DataPlayed"):SetText(playerPlayed .. " (" .. math.floor(percent * 100) .. "%)")
			Arena:SetRating("PVPTeam" .. buttonIndex, value.size, teamRating)
		end
	end
end

-- Add points next to rating, and also add team bracket
function Arena:InspectPVPTeam_Update()
	if( not SSPVP.db.profile.arena.modify ) then
		return
	end

	local teams = {{size = 2}, {size = 3}, {size = 5}}

	for _, value in pairs(teams) do
		for i=1, MAX_ARENA_TEAMS do
			local teamName, teamSize = GetInspectArenaTeamData(i)
			if( value.size == teamSize ) then
				value.index = i
			end
		end
	end
	
	local buttonIndex = 0
	for _, value in pairs(teams) do
		if( value.index ) then
			local teamName, teamSize, teamRating = GetInspectArenaTeamData(value.index)

			buttonIndex = buttonIndex + 1
			
			getglobal("InspectPVPTeam" .. buttonIndex .. "DataName"):SetText(string.format(L["%s |cffffffff(%dvs%d)|r"], teamName, teamSize, teamSize))
			Arena:SetRating("InspectPVPTeam" .. buttonIndex, teamSize, teamRating)
		end
	end
end

-- Slash commands
-- Games required to get 30%
-- soo very hackish
function Arena.CalculateGoal(currentGames, currentTotal)
	currentGames = tonumber(currentGames)
	currentTotal = tonumber(currentTotal)
		
	local percentage = currentGames / currentTotal
	
	if( percentage >= 0.30 ) then
		SSPVP:Print(string.format(L["%d games is already 30%% of %d."], currentGames, currentTotal))
		return
	end
	
	local totalGames = currentTotal
	local games = currentGames
	
	while( percentage < 0.30 ) do
		games = games + 1
		totalGames = totalGames + 1
		
		percentage = games / totalGames
	end
	
	SSPVP:Print(string.format(L["You have played %d games and need to play %d more (%d played games, %d total games) to reach 30%%"], currentGames, totalGames - currentTotal, games, totalGames))
end

-- Rating -> Points
function Arena.CalculatePoints(rating)
	rating = tonumber(rating)

	SSPVP:Print(string.format(L["[%d vs %d] %d rating = %d points"], 5, 5, rating, GetPoints(rating)))
	SSPVP:Print(string.format(L["[%d vs %d] %d rating = %d points - %d%% = %d points"], 3, 3, rating, GetPoints(rating), pointPenalty[3] * 100, GetPoints(rating, 3)))
	SSPVP:Print(string.format(L["[%d vs %d] %d rating = %d points - %d%% = %d points"], 2, 2, rating, GetPoints(rating), pointPenalty[2] * 100, GetPoints(rating, 2)))
end

-- Points -> Rating
function Arena.CalculateRating(points)
	points = tonumber(points)

	SSPVP:Print(string.format(L["[%d vs %d] %d points = %d rating"], 5, 5, points, GetRating(points)))
	SSPVP:Print(string.format(L["[%d vs %d] %d points = %d rating"], 3, 3, points, GetRating(points, 3)))
	SSPVP:Print(string.format(L["[%d vs %d] %d points = %d rating"], 2, 2, points, GetRating(points, 2)))
end
