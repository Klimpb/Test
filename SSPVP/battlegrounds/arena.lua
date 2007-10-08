Arena = SSPVP:NewModule( "SSPVP-Arena" )
Arena.activeIn = "arena"

local L = SSPVPLocals

-- Blizzard likes to change this monthly, so lets just
-- store it here to make it easier
local pointPenalty = {[5] = 1.0, [3] = 0.88, [2] = 0.76}

local CREATED_ROWS = 0

local enemies = {}
local enemyPets = {}

local PartySlain
local SelfSlain

local TattleEnabled
local AEIEnabled

function Arena:Initialize()
	if( not IsAddOnLoaded("Blizzard_InpsectUI") ) then
		self:RegisterEvent("ADDON_LOADED")
	else
		hooksecurefunc("InspectPVPTeam_Update", self.InspectPVPTeam_Update)	
	end

	hooksecurefunc("PVPTeam_Update", self.PVPTeam_Update)
	hooksecurefunc("PVPTeamDetails_Update", self.PVPTeamDetails_Update)
	
	PartySlain = string.gsub(PARTYKILLOTHER, "%%s", "(.+)")
	SelfSlain = string.gsub(SELFKILLOTHER, "%%s", "(.+)")

	SSPVP.cmd:RegisterSlashHandler(L["points <rating> - Calculates how much points you will gain with the given rating"], "points (%d+)", self.CalculatePoints)
	SSPVP.cmd:RegisterSlashHandler(L["rating <points> - Calculates what rating you will need to gain the given points"], "rating (%d+)", self.CalculateRating)
	SSPVP.cmd:RegisterSlashHandler(L["percent <playedGames> <totalGames> - Calculates how many games you will need to play to reach 30% using the passed played games and total games."], "percent (%d+) (%d+)", self.CalculateGoal)
end


function Arena:EnableModule()
	self:RegisterEvent("UNIT_HEALTH")
	self:RegisterEvent("CHAT_MSG_ADDON")
	self:RegisterEvent("PLAYER_FOCUS_CHANGED")
	self:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
	self:RegisterEvent("PLAYER_TARGET_CHANGED")
	self:RegisterEvent("CHAT_MSG_BG_SYSTEM_NEUTRAL")
	self:RegisterEvent("CHAT_MSG_COMBAT_HOSTILE_DEATH")
	self:RegisterEvent("UPDATE_BINDINGS", "UpdateBindings")
	
	self:RegisterMessage("SS_ENEMY_DATA", "EnemyData")
	self:RegisterMessage("SS_ENEMYPET_DATA", "PetData")
	self:RegisterMessage("SS_ENEMYDIED_DATA", "EnemyDied")
	
	SSOverlay:AddCategory("arena", L["Arena Info"])
	
	-- Pre create any frames if needed to reduce lag before entering combat
	if( CREATED_ROWS < SSPVP:MaxBattlefieldPlayers() ) then
		for i=1, SSPVP:MaxBattlefieldPlayers() do
			self:CreateRow()
		end
	end
	
	if( IsAddOnLoaded("ArenaEnemyInfo") ) then
		AEIEnabled = true
	elseif( IsAddOnLoaded("Tattle") ) then
		TattleEnabled = true
	end
end

function Arena:DisableModule()
	-- Can't hide frames in combat =(
	if( InCombatLockdown() ) then
		SSPVP:RegisterOOCUpdate(Arena, "ResetFrames")
	else
		self:ResetFrames()
	end
	
	-- Remove timers
	SSOverlay:RemoveCategory("arena")
	
	-- Unregister events!
	self:UnregisterAllMessages()
	self:UnregisterAllEvents()
	self:RegisterEvent("ADDON_LOADED")
end

function Arena:ResetFrames()
	-- Clear the table so we can reuse it later
	for i=#(enemies), 1, -1 do
		table.remove(enemies, i)
	end
	
	for i=#(enemyPets), 1, -1 do
		table.remove(enemyPets, i)
	end
	
	-- Now hide them all
	if( self.frame ) then
		self.frame:Hide()

		for i=1, CREATED_ROWS do
			self.rows[i].ownerName = nil
			self.rows[i]:Hide()
		end
	end
end

-- Something in configuration changed
function Arena:Reload()
	if( not SSPVP.db.profile.arena.locked ) then
		if( #(enemies) == 0 and #(enemyPets) == 0 ) then
			table.insert(enemies, {sortID = "", name = UnitName("player"), server = GetRealmName(), race = UnitRace("player"), class = UnitClass("player"), classToken = select(2, UnitClass("player")), health = UnitHealth("player"), maxHealth = UnitHealthMax("player")})
			table.insert(enemyPets, {sortId = "", name = L["Pet"], owner = UnitName("player"), health = UnitHealth("player"), maxHealth = UnitHealthMax("player")})

			self:UpdateEnemies()
		end
	elseif( #(enemies) == 1 and #(enemyPets) == 1 ) then
		enemies = {}
		enemyPets = {}
		
		if( self.frame ) then
			self.frame:Hide()
			
			for i=1, CREATED_ROWS do
				self.rows[i].ownerName = nil
				self.rows[i]:Hide()
			end
		end
	end
	
	if( self.frame ) then
		self.frame:SetMovable(not SSPVP.db.profile.arena.locked)
		self.frame:EnableMouse(not SSPVP.db.profile.arena.locked)
	end
	
	-- Can't move the frame if the rows all are clickable
	for i=1, CREATED_ROWS do
		self.rows[i]:SetStatusBarTexture(SSPVP.db.profile.arena.statusBar)
		self.rows[i].button:EnableMouse(SSPVP.db.profile.arena.locked)
	end
end

-- Set up bindings
function Arena:UpdateBindings()
	if( not self.frame ) then
		return
	end
	
	for i=1, CREATED_ROWS do
		local bindKey = GetBindingKey("ARENATAR" .. i)
				
		if( bindKey ) then
			SetOverrideBindingClick(self.rows[i].button, false, bindKey, self.rows[i].button:GetName())	
		else
			ClearOverrideBindings(self.rows[i].button)
		end
	end
end


-- Grabs the data from the name
function Arena:GetDataFromName(name)
	for _, enemy in pairs(enemies) do
		if( enemy.name == name ) then
			return enemy
		end
	end
	
	return nil
end

-- Check if an enemy died
function Arena:CHAT_MSG_COMBAT_HOSTILE_DEATH(event, msg)
	-- Check if someone in our party killed them
	if( string.match(msg, PartySlain) ) then
		local died = string.match(msg, PartySlain)

		self:EnemyDied(event, died)		
		PVPSync:SendMessage("ENEMYDIED:" .. died)

	-- Check if we killed them
	elseif( string.find(msg, SelfSlain) ) then
		local died = string.match(msg, SelfSlain)

		self:EnemyDied(event, died)
		PVPSync:SendMessage("ENEMYDIED:" .. died)
	end
end

-- Updates all the health info!
function Arena:UpdateHealth(enemy, health, maxHealth)
	-- No data passed (Bad) return quickly
	if( not enemy ) then
		return
	end
	
	local row, id
	for i=1, CREATED_ROWS do
		if( self.rows[i].ownerName == enemy.name ) then
			row = self.rows[i]
			id = i
			break
		end
	end
	
	-- Unable to find them on the frame, so don't update
	if( not id ) then
		return
	end
	
	-- Max health changed (Never really should happen)
	if( enemy.maxHealth ~= maxHealth ) then
		row:SetMinMaxValues(0, maxHealth)
		enemy.maxHealth = maxHealth
	end
	
	enemy.health = health or enemy.health
	if( enemy.health == 0 ) then
		enemy.isDead = true
	end

	self:UpdateRow(enemy, id)
end

-- Health update, check if it's one of our guys
function Arena:UNIT_HEALTH(event, unit)
	if( unit == "focus" or unit == "target" ) then
		self:UpdateHealth(self:GetDataFromName(UnitName(unit)), UnitHealth(unit), UnitHealthMax(unit))
	end
end

-- Basically this handles things that change mid combat
-- like health or dying
function Arena:UpdateRow(enemy, id)
	self.rows[id]:SetValue(enemy.health)
	self.rows[id].healthText:SetText((enemy.health / enemy.maxHealth) * 100)
	
	if( enemy.isDead ) then
		self.rows[id]:SetAlpha(0.75)
	else
		self.rows[id]:SetAlpha(1.0)
	end
end

-- Update the entire frame and everything in it
function Arena:UpdateEnemies()
	-- Can't update in combat of course
	if( InCombatLockdown() ) then
		SSPVP:RegisterOOCUpdate(Arena, "UpdateEnemies")
		return
	end
		
	local id = 0

	-- Update enemy players
	for _, enemy in pairs(enemies) do
		id = id + 1
		if( not self.rows[id] ) then
			self:CreateRow()
		end

		local row = self.rows[id]
		
		-- Players name
		local name = enemy.name
		
		-- Enemy talents
		if( SSPVP.db.profile.arena.showTalents ) then
			if( AEIEnabled ) then
				name = "|cffffff" .. AEI:GetSpec(enemy.name, enemy.server) .. "|r " .. name
			elseif( TattleEnabled ) then
				local data = Tattle:GetPlayerData(enemy.name, enemy.server)
				if( data ) then
					name = "|cffffff[" .. data.tree1 .. "/" .. data.tree2 .. "/" .. data.tree3 .. "]|r " .. name
				end
			end
		end
		
		-- Enemy ID
		if( SSPVP.db.profile.arena.showID ) then
			name = "|cffffff" .. id .. "|r " .. name
		end

		row.text:SetText(name)
		row.ownerName = enemy.name
		
		-- Show class icon to the left of the players name
		if( SSPVP.db.profile.arena.showIcon ) then
			local coords = CLASS_BUTTONS[enemy.classToken]

			row.classTexture:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
			row.classTexture:Show()
		else
			row.classTexture:Hide()
		end
		
		row:SetMinMaxValues(0, enemy.maxHealth)
		row:SetStatusBarColor(RAID_CLASS_COLORS[enemy.classToken].r, RAID_CLASS_COLORS[enemy.classToken].g, RAID_CLASS_COLORS[enemy.classToken].b, 1.0)
		
		-- Now do a quick basic update of other info
		self:UpdateRow(enemy, id)
		
		-- Make it so we can target the person
		row.button:SetAttribute("type", "macro")
		row.button:SetAttribute("macrotext", "/target " .. enemy.name)
		
		row:Show()
	end
	
	if( not SSPVP.db.profile.arena.showPets ) then
		self.frame:SetHeight(18 * id)
		self.frame:Show()
		return
	end
	
	-- Update enemy pets
	for _, enemy in pairs(enemyPets) do
		id = id + 1
		if( not self.rows[id] ) then
			self:CreateRow()
		end
		
		local row = self.rows[id]
		
		local name = string.format(L["%s's %s"], enemy.owner, (enemy.family or enemy.name))
		if( SSPVP.db.profile.showID ) then
			name = "|cffffff" .. id .. "|r " .. name
		end
		
		row.text:SetText(name)
		row.ownerName = nil

		row.classTexture:Hide()
		
		row:SetMinMaxValues(0, enemy.maxHealth)
		row:SetStatusBarColor(SSPVP.db.profile.arena.petColor.r, SSPVP.db.profile.arena.petColor.g, SSPVP.db.profile.arena.petColor.b, 1.0)
		
		-- Quick update
		self:UpdateRow(enemy, id)
		
		-- Make it so we can target the pet
		row.button:SetAttribute("type", "macro")
		row.button:SetAttribute("macrotext", "/target " .. enemy.name)

		row:Show()
	end

	self.frame:SetHeight(18 * id)
	self.frame:Show()
end

-- Quick redirects!
function Arena:PLAYER_TARGET_CHANGED()
	self:ScanUnit("target")
end

function Arena:UPDATE_MOUSEOVER_UNIT()
	self:ScanUnit("mouseover")
end

function Arena:PLAYER_FOCUS_CHANGED()
	self:ScanUnit("focus")
end

-- Sort the enemies by the sortID thing
local function sortEnemies(a, b)
	if( not b ) then
		return false
	end
	
	return ( a.sortID > b.sortID )
end

-- Scan unit, see if they're valid as an enemy or enemy pet
function Arena:ScanUnit(unit)
	-- Mods disabled
	if( not SSPVP.db.profile.arena.unitFrames ) then
		return
	end
		
	-- 1) Roll a Priest with the name Unknown
	-- 2) Join an arena team
	-- 3) ????
	-- 4) Profit! Because all arena mods check for Unknown names before exiting
	local name, server = UnitName(unit)
	if( name == L["Unknown"] or not UnitIsEnemy("player", unit) ) then
		return
	end
	
	if( UnitIsPlayer(unit) ) then
		server = server or GetRealmName()
		
		for _, player in pairs(enemies) do
			if( player.name == name and player.server == server ) then
				return
			end
		end
		
		local race = UnitRace(unit)
		local class, classToken = UnitClass(unit)
		local guild = GetGuildInfo(unit)
		
		table.insert(enemies, {sortID = name .. "-" .. server, name = name, server = server, race = race, class = class, classToken = classToken, guild = guild, health = UnitHealth(unit), maxHealth = UnitHealthMax(unit) or 100})
		
		if( guild ) then
			if( SSPVP.db.profile.arena.reportChat ) then
				SSPVP:ChannelMessage(string.format(L["[%d/%d] %s / %s / %s / %s / %s"], #(enemies), SSPVP:MaxBattlefieldPlayers(), name, server, race, class, guild))
			end
			
			PVPSync:SendMessage("ENEMY:" .. name .. "," .. server .. "," .. race .. "," .. classToken .. "," .. guild)
		else
			if( SSPVP.db.profile.arena.reportChat ) then
				SSPVP:ChannelMessage(string.format(L["[%d/%d] %s / %s / %s / %s"], #(enemies), SSPVP:MaxBattlefieldPlayers(), name, server, race, class))
			end
			
			PVPSync:SendMessage("ENEMY:" .. name .. "," .. server .. "," .. race .. "," .. classToken)
		end
		
		table.sort(enemies, sortEnemies)
		self:UpdateEnemies()
		
	-- Warlock pet or a Water Elemental
	elseif( UnitCreatureFamily(unit) or name == L["Water Elemental"] ) then
		-- Need to find the pets owner
		if( not self.tooltip ) then
			self.tooltip = CreateFrame("GameTooltip", "SSArenaTooltip", UIParent, "GameTooltipTemplate")
			self.tooltip:SetOwner(UIParent, "ANCHOR_NONE")
		end
		
		self.tooltip:SetUnit(unit)
		
		-- Exit quickly, no data found
		if( self.tooltip:NumLines() == 0 ) then
			return
		end
		
		local owner = string.match(SSArenaTooltipTextLeft2:GetText(), L["([a-zA-Z]+)%'s Minion"])
		
		-- Found the pet owner
		if( owner and owner ~= L["Unknown"] ) then
			local family = UnitCreatureFamily(unit)
			for _, pet in pairs(enemyPets) do
				if( pet.name == name ) then
					return
				end
			end
			
			table.insert(enemyPets, {sortID = name .. "-" .. owner, name = name, owner = owner, family = family, health = UnitHealth(unit), maxHealth = UnitHealthMax(unit) or 100})
			
			if( family ) then
				if( SSPVP.db.profile.arena.reportChat ) then
					SSPVP:ChannelMessage(string.format( L["[%d/%d] %s's pet, %s %s"], #(enemyPets), SSPVP:MaxBattlefieldPlayers(), owner, name, family))
				end
				
				PVPSync:SendMessage("ENEMYPET:" .. name .. "," .. owner .. "," .. family)
			else
				if( SSPVP.db.profile.arena.reportChat ) then
					SSPVP:ChannelMessage(string.format(L["[%d/%d] %s's pet, %s"], #(enemyPets), SSPVP:MaxBattlefieldPlayers(), owner, name))
				end
				
				PVPSync:SendMessage("ENEMYPET:" .. name .. "," .. owner)
			end
			
			table.sort(enemyPets, sortEnemies)
			self:UpdateEnemies()
		end
	end
end

-- Health value updated, rescan our saved enemies
local function healthValueChanged(...)
	local ownerName = select(5, this:GetParent():GetRegions()):GetText()

	Arena:UpdateHealth(Arena:GetDataFromName(ownerName), value, select(2, this:GetMinMaxValues()))

	if( this.SSValueChanged ) then
		this.SSValueChanged(...)
	end
end

-- Find unhooked anonymous frames
local function findUnhookedNameplates(...)
	for i=1, select("#", ...) do
		local bar = select(i, ...)
		if( bar and not bar.SSHooked and not bar:GetName() and bar:IsVisible() and bar.GetFrameType and bar:GetFrameType() == "StatusBar" ) then
			return bar
		end
	end
end

-- Scan WorldFrame children
local function scanFrames(...)
	for i=1, select("#", ...) do
		local bar = findUnhookedNameplates(select( i, ...):GetChildren())
		if( bar ) then
			bar.SSHooked = true
			
			local health = bar:GetParent():GetChildren()
			health.SSValueChanged = health:GetScript("OnValueChanged")
			health:SetScript("OnValueChanged", healthValueChanged)
		end
	end
end

-- Create the master frame to hold everything
function Arena:CreateFrame()
	if( self.frame ) then
		return
	end
	
	if( InCombatLockdown() ) then
		SSPVP:RegisterOOCUpdate(Arena, "CreateFrame")
		return
	end
	
	self.frame = CreateFrame("Frame")
	self.frame:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeSize = 0.6,
		insets = {left = 1, right = 1, top = 1, bottom = 1}})

	self.frame:SetBackdropColor(0, 0, 0, 1.0)
	self.frame:SetBackdropBorderColor(0.60, 0.60, 0.60, 1.0)
	self.frame:SetScale(SSPVP.db.profile.arena.scale)
	self.frame:SetWidth(180)
	self.frame:SetMovable(not SSPVP.db.profile.arena.locked)
	self.frame:EnableMouse(not SSPVP.db.profile.arena.locked)
	self.frame:SetClampedToScreen(true)

	-- Moving the frame
	self.frame:SetScript("OnMouseDown", function(self)
		if( not SSPVP.db.profile.arena.locked ) then
			self.isMoving = true
			self:StartMoving()
		end
	end)

	self.frame:SetScript("OnMouseUp", function(self)
		if( self.isMoving ) then
			self.isMoving = nil
			self:StopMovingOrSizing()

			SSPVP.db.profile.positions.arena.x = self:GetLeft()
			SSPVP.db.profile.positions.arena.y = self:GetTop()
		end
	end)
	
	-- Health monitoring
	local timeElapsed = 0
	local numChildren = -1;
	self.frame:SetScript("OnUpdate", function(self, elapsed)
		-- When number of children changes, 99% of the time it's
		-- due to a new nameplate being added
		if( WorldFrame:GetNumChildren() ~= numChildren ) then
			numChildren = WorldFrame:GetNumChildren()
			scanFrames(WorldFrame:GetChildren())
		end
		
		-- Scan party targets every 0.75 seconds
		-- Really, nameplate scanning should get the info 99% of the time
		-- so we don't need to be so aggressive with this
		timeElapsed = timeElapsed + elapsed
		if( timeElapsed > 0.75 ) then
			for i=1, GetNumPartyMembers() do
				if( UnitExists("party" .. i .. "target" ) ) then
					Arena:UpdateHealth(Arena:GetDataFromName(UnitName("party" .. i .. "target")), UnitHealth("party" .. i .. "target"), UnitHealthMax("party" .. i .. "target"))
				end
			end
		end
	end)
	
	-- Position to last saved area
	self.frame:ClearAllPoints()
	if( SSPVP.db.profile.positions.arena ) then
		self.frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", SSPVP.db.profile.positions.arena.x, SSPVP.db.profile.positions.arena.y)
	else
		self.frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	end
	
	self.rows = {}
end

-- Create a single row
function Arena:CreateRow()
	if( InCombatLockdown() ) then
		SSPVP:RegisterOOCUpdate(Arena, "CreateRow")
		return
	end

	if( not self.frame ) then
		self:CreateFrame()
	end
	
	CREATED_ROWS = CREATED_ROWS + 1
	local id = CREATED_ROWS
	
	-- Health bar
	local row = CreateFrame("StatusBar", nil, self.frame)
	row:SetHeight(16)
	row:SetWidth(178)
	row:SetStatusBarTexture(SSPVP.db.profile.arena.statusBar)
	row:Hide()
	
	local path, size = GameFontNormalSmall:GetFont()
	
	-- Player name text
	local text = row:CreateFontString(nil, "OVERLAY")
	text:SetTextColor(1, 1, 1, 1.0)
	text:SetFont(path, size, "OUTLINE")
	text:SetPoint("LEFT", row, "LEFT", 1, 0)
	
	-- Health percent text
	local healthText = row:CreateFontString(nil, "OVERLAY")
	healthText:SetTextColor(1, 1, 1, 1.0)
	healthText:SetFont(path, size, "OUTLINE")
	healthText:SetPoint("RIGHT", row, "RIGHT", -1, 0)
	
	-- Class icon
	local texture = row:CreateTexture(nil, "OVERLAY")
	texture:SetHeight(15)
	texture:SetWidth(15)
	texture:SetTexture("Interface\\WorldStateFrame\\Icons-Classes")
	texture:SetPoint("CENTER", row, "LEFT", -10, 0)
	
	-- So we can actually run macro text
	local button = CreateFrame("Button", "SSArenaButton" .. id, row, "SecureActionButtonTemplate")
	button:SetHeight(16)
	button:SetWidth(179)
	button:SetPoint("LEFT", row, "LEFT", 1, 0)
	button:EnableMouse(SSPVP.db.profile.arena.locked)
	
	-- Position
	if( id > 1 ) then
		row:SetPoint("TOPLEFT", self.rows[id - 1], "BOTTOMLEFT", 0, -2)
	else
		row:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 1, -1)
	end

	self.rows[id] = row
	self.rows[id].text = text
	self.rows[id].classTexture = texture
	self.rows[id].button = button
	self.rows[id].healthText = healthText
	
	-- Add key bindings
	local bindKey = GetBindingKey("ARENATAR" .. id)

	if( bindKey ) then
		SetOverrideBindingClick(self.rows[id].button, false, bindKey, self.rows[id].button:GetName())	
	else
		ClearOverrideBindings(self.rows[id].button)
	end
end

-- Syncing
function Arena:EnemyData(event, name, server, race, classToken, guild)
	if( not SSPVP.db.profile.arena.unitFrames ) then
		return
	end
	
	for _, enemy in pairs( enemies ) do
		if( not enemy.owner and enemy.name == name ) then
			return
		end
	end

	table.insert(enemies, {sortID = name .. "-" .. server, name = name, health = 100, maxHealth = 100, server = server, race = race, classToken = classToken, guild = guild})
	self:UpdateEnemies()
end

-- New pet found
function Arena:PetData(event, name, owner, family)
	if( not SSPVP.db.profile.arena.unitFrames or not SSPVP.db.profile.arena.showPets ) then
		return
	end
	
	for _, enemy in pairs( enemies ) do
		if( enemy.owner == owner and enemy.name == name ) then
			return
		end
	end

	table.insert(enemyPets, {sortID = name .. "-" .. owner, name = name, owner = owner, family = family, health = 100, maxHealth = 100})
	self:UpdateEnemies()
end

-- Someone died, update them to actually be dead
function Arena:EnemyDied(event, name)
	if( not SSPVP.db.profile.arena.unitFrames ) then
		return
	end

	for id, enemy in pairs(enemies) do
		if( not enemy.isDead and enemy.name == name ) then
			enemy.isDead = true
			enemy.health = 0
			self:UpdateRow(enemy, id)
			break
		end
	end
end

-- Most arena mods are incredibly evil, and don't use class token
-- so, we need to translate it from evil class -> token class
function Arena:TranslateClass(class)
	for classToken, className in pairs(L["CLASSES"]) do
		if( className == class ) then
			return classToken
		end
	end
	
	return nil
end

function Arena:CHAT_MSG_ADDON(event, prefix, msg, type, author)
	-- <name> <class>
	if( prefix == "ArenaMaster" ) then
		local name, class = string.split(" ", msg)
		self:EnemyData(event, name, nil, nil, string.upper(class))

	-- <name>,<class>
	elseif( prefix == "ALF_T" ) then
		local name, class = string.split( ",", msg )
		self:EnemyData( event, name, nil, nil, self:TranslateClass(class))
	
	-- AOP <name>:<class>:<race>
	--elseif( prefix == "BGGQ" and string.sub(msg, 0, 3) == "AOP" ) then
	--	local name, class, race = string.split(":", string.sub(msg, 5))
	--	self:EnemyData(event, name, nil, race, self:TranslateClass(class))
	
	-- 0,<name>,<class>
	-- Yay ArenaUnitFrames plays nicely and uses class Token
	elseif( prefix == "ArenaUnitFrames" ) then
		local _, name, class = string.split(",", msg)
		self:EnemyData(event, name, nil, nil, class)
	
	-- Accidentally SSPVP 2.4 uses "RAID" type instead of "BATTLEGROUND", meaning
	-- most of the time the sync messages from it wont be caught unless you're grouped
	-- FOUND:<num>:<name>:<server>:<race>:<class>
	--elseif( prefix == "SSPVP" and string.sub(msg, 0, 5) == "FOUND" ) then
	--	local _, name, server, race, class = string.split(":", string.sub(msg, 7))
	--	self:EnemyData(event, name, server, race, self:TranslateClass(class))
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
	
	-- Can the new formula go below 0?
	if( rating < 0 ) then
		rating = 0
	end
	
	return math.floor(rating + 0.5)
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
