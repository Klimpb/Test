local Arena = SSPVP:NewModule("Arena", "AceEvent-3.0", "AceConsole-3.0")
Arena.activeIn = "arena"

local L = SSPVPLocals

-- Blizzard likes to change this monthly, so lets just store it here to make it easier
local pointPenalty = {[5] = 1.0, [3] = 0.88, [2] = 0.76}
local teamInfo = {}
local lastChange = 0

function Arena:OnEnable()
	if( self.defaults ) then return end

	self.defaults = {
		profile = {
			score = true,
			personal = true,
		},
	}
	
	self.db = SSPVP.db:RegisterNamespace("arena", self.defaults)
	

	-- Slash commands for conversions
	self:RegisterChatCommand("arena", function(input)
		if( string.match(input, "points ([0-9]+)") ) then
			Arena:CalculateRating(string.match(input, "points ([0-9]+)"))
		elseif( string.match(input, "rating ([0-9]+)") ) then
			Arena:CalculatePoints(string.match(input, "rating ([0-9]+)"))
		elseif( string.match(input, "attend ([0-9]+) ([0-9]+)") ) then
			local played, teamPlayed = string.match(input, "attend ([0-9]+) ([0-9]+)")
			local percent = played / teamPlayed
			
			if( percent >= 0.30 ) then
				SSPVP:Print(string.format(L["%d games out of %d total is already above 30%% (%.2f%%)."], played, teamPlayed, percent * 100))
			else
				local gamesNeeded = math.ceil(((0.3 - percent) / 0.70) * teamPlayed)
				SSPVP:Print(string.format(L["%d more games have to be played (%d total) to reach 30%%."], gamesNeeded, teamPlayed + gamesNeeded))
			end
		else
			DEFAULT_CHAT_FRAME:AddMessage(L["SSPVP Arena slash commands"])
			DEFAULT_CHAT_FRAME:AddMessage(L[" - rating <rating> - Calculates points given from the passed rating."])
			DEFAULT_CHAT_FRAME:AddMessage(L[" - points <points> - Calculates rating required to reach the passed points."])
			DEFAULT_CHAT_FRAME:AddMessage(L[" - attend <played> <team> - Calculates games required to reach 30% using the passed games <played> out of the <team> games played."])
		end
	end)
		
	-- Load the inspection stuff, or wait for it to load
	if( IsAddOnLoaded("Blizzard_InspectUI") ) then
		hooksecurefunc("InspectPVPTeam_Update", self.InspectPVPTeam_Update)
	else
		self:RegisterEvent("ADDON_LOADED")
	end
	
	if( self.db.profile.personal ) then
		self:RegisterEvent("ARENA_TEAM_ROSTER_UPDATE")
	end
	
	-- Generally, I don't hook things to change the return results

	-- but, in this case it's not suppose to return 2 when it's season 3
	local Orig_GetCurrentArenaSeason = GetCurrentArenaSeason
	GetCurrentArenaSeason = function()
		if( Orig_GetCurrentArenaSeason() < 3 ) then
			return 3
		end
		
		return Orig_GetCurrentArenaSeason()
	end
end

function Arena:EnableModule()
	if( self.db.profile.score ) then
		self:RegisterEvent("UPDATE_BATTLEFIELD_STATUS")
	end
end

function Arena:DisableModule()
	self:UnregisterEvent("UPDATE_BATTLEFIELD_STATUS")
end

function Arena:Reload()
	if( self.isActive ) then
		self:UnregisterAllEvents()
		self:EnableModule()
	end

	if( self.db.profile.personal ) then
		self:RegisterEvent("ARENA_TEAM_ROSTER_UPDATE")
	else
		self:UnregisterEvent("ARENA_TEAM_ROSTER_UPDATE")
	end
end

-- It's a pain in the ass to do this, basically we assume any personal rating change
-- beyond the initial update is due to arenas 
-- Will improve this later to do the calculates with the UPDATE_BATTLEFIELD_STATUS things
function Arena:ARENA_TEAM_ROSTER_UPDATE()
	for i=1, 3 do
		local teamName, teamSize, _, _, _, _, _, _, _, _, personalRating = GetArenaTeam(i)
		if( teamName ) then
			local id = teamName .. teamSize
			
			-- Only show personal rating changes when it differs from your team
			if( teamInfo[id] ) then
				local change = personalRating - teamInfo[id]
				if( change ~= 0 and lastChange ~= change and lastChange ~= 0 ) then
					SSPVP:Print(string.format(L["%d personal rating in %s (%dvs%d)"], change, teamName, teamSize, teamSize))
					lastChange = 0
				end
			end

			teamInfo[id] = personalRating
		end
	end
end

-- Check if inspect UI loaded
function Arena:ADDON_LOADED(event, addon)
	if( addon == "Blizzard_InspectUI" ) then
		hooksecurefunc("InspectPVPTeam_Update", self.InspectPVPTeam_Update)
		self:UnregisterEvent("ADDON_LOADED")
	end
end

-- How many points gained/lost
function Arena:UPDATE_BATTLEFIELD_STATUS()
	if( GetBattlefieldWinner() and select(2, IsActiveBattlefieldArena()) ) then
		local win = ""
		local teamName, oldRating, newRating = GetBattlefieldTeamInfo(1)
		win = string.format(L["%s %d points (%d rating)"], teamName, newRating - oldRating, newRating)

		local teamName, oldRating, newRating = GetBattlefieldTeamInfo(0)
		win = win .. " / " .. string.format(L["%s %d points (%d rating)"], teamName, newRating - oldRating, newRating)
				
		SSPVP:Print(win)
		
		-- Doesn't matter which team we check, they both gain/lose the same amount
		lastChange = math.abs(oldRating - newRating)
	end
end

-- Conversions
-- Points gained/lost from beating teams
local function getChange(winRate, loseRate)	
--[[
    Team A's Chance of Winning: 1 / (1+10(1580 - 1500)/400) = 0.38686 
    Team B's Chance of Winning: 1 / (1+10(1500 - 1580)/400) = 0.61314 

    Now Let's say Team A won the battle then 
    Team A's New Score: 1500 + 32*(1 - 0.38686) = 1500 + 19.62 = 1519.62 
    Team B's New Score: 1580 + 32*(0 - 0.61314) = 1580 + (-19.62) = 1560.38 

    Now Let's say Team B won the battle then 
    Team A's New Score: 1500 + 32*(0 - 0.38686) = 1500 + (-12.38) = 1487.62 
    Team B's New Score: 1580 + 32*(1 - 0.61314) = 1580 + 12.38 = 1592.38 

]]
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
	
	if( points < 0 ) then
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
	
	if( type(rating) ~= "number" or rating < 0 ) then
		rating = 0
	end
	
	return rating
end

-- Slash command conversions
-- Rating -> Points
function Arena:CalculatePoints(rating)
	rating = tonumber(rating)

	SSPVP:Print(string.format(L["[%d vs %d] %d rating = %d points"], 5, 5, rating, getPoints(rating)))
	SSPVP:Print(string.format(L["[%d vs %d] %d rating = %d points - %d%% = %d points"], 3, 3, rating, getPoints(rating), pointPenalty[3] * 100, getPoints(rating, 3)))
	SSPVP:Print(string.format(L["[%d vs %d] %d rating = %d points - %d%% = %d points"], 2, 2, rating, getPoints(rating), pointPenalty[2] * 100, getPoints(rating, 2)))
end

-- Points -> Rating
function Arena:CalculateRating(points)
	points = tonumber(points)

	SSPVP:Print(string.format(L["[%d vs %d] %d points = %d rating"], 5, 5, points, getRating(points)))
	SSPVP:Print(string.format(L["[%d vs %d] %d points = %d rating"], 3, 3, points, getRating(points, 3)))
	SSPVP:Print(string.format(L["[%d vs %d] %d points = %d rating"], 2, 2, points, getRating(points, 2)))
end

-- Inspection and players arena info uses the same base names
function Arena:SetRating(parent, teamSize, teamRating)
	if( teamRating == 0 ) then
		return
	end

	local ratingText = getglobal(parent .. "DataRating")
	local label = getglobal(parent.. "DataRatingLabel")

	-- Shift the rating to match the rating label
	ratingText:ClearAllPoints()
	ratingText:SetPoint("LEFT", label, "RIGHT", 2, 0)

	-- Shift the actual rating text down to the left to make room for our changes
	label:SetText(L["Rating"])
	label:SetPoint("LEFT", parent .. "DataName", "RIGHT", -32, 0)

	-- Add points gained next to the rating
	ratingText:SetText(string.format("%d |cffffffff(%d)|r", teamRating, getPoints(teamRating, teamSize)))
	ratingText:SetWidth(70)

	-- Resize team name so it doesn't overflow into our rating
	getglobal(parent .. "DataName"):SetWidth(150)
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
			Arena:SetRating("PVPTeam" .. buttonIndex, value.size, select(3, GetArenaTeam(value.index)))
		end
	end
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
				Arena:SetRating("InspectPVPTeam" .. buttonIndex, teamSize, teamRating)
			end
		end
	end
end

