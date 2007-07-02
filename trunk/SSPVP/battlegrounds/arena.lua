local Arena = SSPVP:NewModule( "SSPVP-Arena" )
Arena.activeIn = "arena"

local L = SSPVPLocals
local CREATED_ROWS = 0
local enemies = {}

local PartySlain
local SelfSlain

function Arena:Initialize()
	self:RegisterEvent( "ADDON_LOADED" )

	hooksecurefunc( "PVPTeam_Update", self.PVPTeam_Update )
	hooksecurefunc( "PVPTeamDetails_Update", self.PVPTeamDetails_Update )
	
	PartySlain = string.gsub( PARTYKILLOTHER, "%%s", "(.+)" )
	SelfSlain = string.gsub( SELFKILLOTHER, "%%s", "(.+)" )

	SSPVP.cmd:RegisterSlashHandler( L["points <rating> - Calculates how much points you will gain with the given rating"], "points (%d+)", self.CalculatePoints )
	SSPVP.cmd:RegisterSlashHandler( L["rating <points> - Calculates what rating you will need to gain the given points"], "rating (%d+)", self.CalculateRating )
	SSPVP.cmd:RegisterSlashHandler( L["percent <playedGames> <totalGames> - Calculates how many games you will need to play to reach 30% using the passed played games and total games."], "percent (%d+) (%d+)", self.CalculateGoal )
end

function Arena:EnableModule()
	self:RegisterEvent( "CHAT_MSG_ADDON" )
	self:RegisterEvent( "CHAT_MSG_COMBAT_HOSTILE_DEATH" )
	self:RegisterEvent( "CHAT_MSG_BG_SYSTEM_NEUTRAL" )
	self:RegisterEvent( "UPDATE_MOUSEOVER_UNIT" )
	self:RegisterEvent( "UPDATE_BINDINGS", "UpdateEnemyBindings" )
	self:RegisterEvent( "PLAYER_TARGET_CHANGED" )
	self:RegisterEvent( "UNIT_HEALTH" )
	
	self:RegisterMessage( "SS_ENEMY_DATA", "EnemyData" )
	self:RegisterMessage( "SS_ENEMYPET_DATA", "PetData" )
	
	self:RegisterMessage( "SS_ENEMYDIED_DATA", "EnemyDied" )
	
	SSOverlay:AddCategory( "arena", L["Arena Info"] )
	
	-- Pre create any frames if needed to reduce lag during combat
	if( CREATED_ROWS < SSPVP:MaxBattlefieldPlayers() ) then
		for i=1, SSPVP:MaxBattlefieldPlayers() do
			self:CreateTargetRow( i )
		end
	end
end

function Arena:DisableModule()
	enemies = {}
	
	SSOverlay:RemoveCategory( "arena" )

	self:UnregisterAllMessages()
	self:UnregisterAllEvents()
	self:RegisterEvent( "ADDON_LOADED" )

	self:UpdateTargetFrame()
end

function Arena:Reload()
	-- Disabled, so clear everything and hide
	if( not SSPVP.db.profile.arena.target ) then
		enemies = {}
		self:UpdateTargetFrame()
		return
	end

	-- Provide a fake entry for moving
	if( not SSPVP.db.profile.arena.locked and #( enemies ) == 0 ) then
		table.insert( enemies, { name = UnitName( "player" ), server = GetRealmName(), health = UnitHealth( "player" ) or 100, maxHealth = UnitHealthMax( "player" ) or 100, race = UnitRace( "player" ), classToken = select( 2, UnitClass( "player" ) ) } )
		table.insert( enemies, { name = L["Pet"], owner = UnitName( "player" ) } )
		
	-- Relocked and we still have the fake entry, remove it.
	elseif( SSPVP.db.profile.arena.locked ) then
		for _, enemy in pairs( enemies ) do
			if( enemy.name == UnitName( "player" ) ) then
				enemies = {}
				break
			end
		end
	end

	self:UpdateTargetFrame()

	-- Update scale/colors
	if( self.frame ) then
		if( SSPVP.db.profile.arena.showHealth ) then
			self.frame:SetScript( "OnUpdate", self.HealthOnUpdate )
		else
			self.frame:SetScript( "OnUpdate", nil )
		end

		self.frame:SetScale( SSPVP.db.profile.arena.scale )
		
		local row, text, texture
		for i=1, CREATED_ROWS do
			row = getglobal( self.frame:GetName() .. "Row" .. i )
			text = getglobal( row:GetName() .. "Text" )
			texture = getglobal( row:GetName() .. "Icon" )
			
			row:SetBackdropColor( SSPVP.db.profile.arena.background.r, SSPVP.db.profile.arena.background.g, SSPVP.db.profile.arena.background.b, SSPVP.db.profile.arena.opacity )
			row:SetBackdropBorderColor( SSPVP.db.profile.arena.border.r, SSPVP.db.profile.arena.border.g, SSPVP.db.profile.arena.border.b, SSPVP.db.profile.arena.opacity )

			if( SSPVP.db.profile.arena.showIcon ) then
				text:SetPoint( "TOPLEFT", texture, "TOPLEFT", 17, 5 )
			else
				text:SetPoint( "TOPLEFT", row, "TOPLEFT", 3, 3 )
			end
			
			if( enemies[ i ] and not enemies[ i ].owner ) then
				self:UpdateEnemyHealth( i, enemies[ i ].health, enemies[ i ].maxHealth )
			end
		end
	end
end

function Arena:UpdateEnemyBindings()
	if( not self.frame ) then
		return
	end
	
	local bindKey
	for i=1, CREATED_ROWS do
		bindKey = GetBindingKey( "ARENATAR" .. i )
		
		if( bindKey ) then
			SetOverrideBindingClick( getglobal( self.frame:GetName() .. "Row" .. i .. "Button" ), false, bindKey, self.frame:GetName() .. "Row" .. i .. "Button" )
		else
			ClearOverrideBindings( getglobal( self.frame:GetName() .. "Row" .. i .. "Button" ) )
		end
	end
end


function Arena:StartMoving()
	ArenaEnemies:StartMoving()
end

function Arena:StopMoving()
	ArenaEnemies:StopMovingOrSizing()
	SSPVP.db.profile.positions.arena.x, SSPVP.db.profile.positions.arena.y = ArenaEnemies:GetLeft(), ArenaEnemies:GetTop()
end

function Arena:UpdateEnemyText( enemy, rowID, text )
	local extras = ""
		
	if( SSPVP.db.profile.arena.enemyNum ) then
		extras = extras .. "|cffffffff" .. rowID .. "|r "
	end
	
	if( SSPVP.db.profile.arena.showHealth ) then
		extras = extras .. "[" .. math.floor( enemy.health / enemy.maxHealth * 100 ) .. "%] "
	end
	
	if( SSPVP.db.profile.arena.showTalents and AEI ) then
		local tree1, tree2, tree3 = AEI:GetTalents( enemy.name, enemy.server )
		
		if( tree1 > 0 or tree2 > 0 or tree3 > 0 ) then
			extras = extras .. "[" .. tree1 .. "/" .. tree2 .. "/" .. tree3 .. "] "
		end
	end
	
	text:SetText( extras .. enemy.name )
end

function Arena:UpdateEnemyHealth( id, health, maxHealth )
	local text, rowID
	local enemy = enemies[ id ]
	
	for i=1, CREATED_ROWS do
		text = getglobal( self.frame:GetName() .. "Row" .. i .. "Text" )
		if( text.usedName and text.usedName == enemy.name ) then
			rowID = i
			break
		end
	end
	
	if( not rowID ) then
		return
	end
	
	if( enemy.isDead ) then
		health = 0
		maxHealth = 100
	else
		health = health or 100
		maxHealth = maxHealth or 100
	end
	
	enemy.health = health
	enemy.maxHealth = maxHealth
	enemies[ id ] = enemy
		
	if( self.frame ) then
		if( enemy.isDead or health == 0 ) then
			getglobal( self.frame:GetName() .. "Row" .. rowID ):SetAlpha( SSPVP.db.profile.arena.deadOpacity )
		else
			getglobal( self.frame:GetName() .. "Row" .. rowID ):SetAlpha( 1.0 )
		end
		
		Arena:UpdateEnemyText( enemy, rowID, text )
	end
end

function Arena:ScanHealth( unit )
	local name = UnitName( unit )
	for id, enemy in pairs( enemies ) do
		if( not enemy.owner and enemy.name == name ) then
			self:UpdateEnemyHealth( id, UnitHealth( unit ), UnitHealthMax( unit ) )
			break
		end
	end
end

function Arena:UNIT_HEALTH( event, unit )
	if( unit == "target" ) then
		self:ScanHealth( "target" )
	end
end

-- This deals with scanning name plates for health values
local function HealthValueChanged( ... )
	if( this.SSValueChanged ) then
		this.SSValueChanged( ... )
	end
	
	local _, _, _, _, nameFrame = this:GetParent():GetRegions()
	local plateName = nameFrame:GetText()
	
	if( plateName ) then
		for id, enemy in pairs( enemies ) do
			if( not enemy.owner and enemy.name == plateName ) then
				Arena:UpdateEnemyHealth( id, this:GetValue(), select( 2, this:GetMinMaxValues() ) )
				break
			end
		end
	end
end

local function FindUnhookedFrames( ... )
	for i=1, select( "#", ... ) do
		local bar = select( i, ... )
		if( bar and not bar.SSHooked and not bar:GetName() and bar:IsVisible() and bar.GetFrameType and bar:GetFrameType() == "StatusBar" ) then
			return bar
		end
	end
end

local function HookFrames( ... )
	for i=1, select( "#", ... ) do
		local bar = FindUnhookedFrames( select( i, ... ):GetChildren() )
		if( bar ) then
			local health = bar:GetParent():GetChildren()

			bar.SSHooked = true
			health.SSValueChanged = health:GetScript( "OnValueChanged" )
			health:SetScript( "OnValueChanged", HealthValueChanged )
		end
	end
end

local elapsed = 0
local numChildren = 0
function Arena:HealthOnUpdate()
	elapsed = elapsed + arg1

	if( WorldFrame:GetNumChildren() ~= numChildren ) then
		numChildren = WorldFrame:GetNumChildren()
		HookFrames( WorldFrame:GetChildren() )
	end
	
	if( elapsed > 0.25 ) then
		elapsed = 0
		
		local name
		for i=1, GetNumPartyMembers() do
			if( UnitExists( "party" .. i .. "target" ) ) then
				Arena:ScanHealth( "party" .. i .. "target" )
			end
		end
	end
end


function Arena:CreateTargetFrame()
	self.frame = CreateFrame( "Frame", "ArenaEnemies", UIParent )

	self.frame:SetClampedToScreen( true )
	self.frame:SetMovable( true )
	
	self.frame:SetScale( SSPVP.db.profile.arena.scale )
	self.frame:SetPoint( "TOPLEFT", UIParent, "BOTTOMLEFT", SSPVP.db.profile.positions.arena.x, SSPVP.db.profile.positions.arena.y )
	
	if( SSPVP.db.profile.arena.showHealth ) then
		self.frame:SetScript( "OnUpdate", self.HealthOnUpdate )
	end
	
	local width = 145
	
	if( SSPVP.db.profile.arena.showIcon ) then
		width = width + 20
	end
	if( SSPVP.db.profile.arena.showHealth ) then
		width = width + 10
	end
	if( SSPVP.db.profile.arena.showTalents ) then
		width = width + 25
	end
	
	self.frame:SetWidth( width )
end


function Arena:CreateTargetRow( id )
	if( not self.frame or getglobal( self.frame:GetName() .. "Row" .. id ) ) then
		return
	end
	
	CREATED_ROWS = CREATED_ROWS + 1
	
	local row = CreateFrame( "Frame", self.frame:GetName() .. "Row" .. id, self.frame )
	local text = row:CreateFontString( row:GetName() .. "Text", "BACKGROUND" )
	local texture = row:CreateTexture( row:GetName() .. "Icon", "OVERLAY" )
	local button = CreateFrame( "Button", row:GetName() .. "Button", row, "SecureActionButtonTemplate" )
	
	row:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
				edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
				tile = true,
				tileSize = 9,
				edgeSize = 9,
				insets = { left = 2, right = 2, top = 2, bottom = 2 } })	
	
	row:SetBackdropColor( SSPVP.db.profile.arena.background.r, SSPVP.db.profile.arena.background.g, SSPVP.db.profile.arena.background.b, SSPVP.db.profile.arena.opacity )
	row:SetBackdropBorderColor( SSPVP.db.profile.arena.border.r, SSPVP.db.profile.arena.border.g, SSPVP.db.profile.arena.border.b, SSPVP.db.profile.arena.opacity )
	
	row:SetWidth( self.frame:GetWidth() )
	row:SetHeight( 19 )
	
	button:SetWidth( self.frame:GetWidth() )
	button:SetHeight( 18 )
	
	texture:SetWidth( 16 )
	texture:SetHeight( 16 )

	text:SetJustifyH( "LEFT" )
	text:SetHeight( 25 )
	text:SetWidth( self.frame:GetWidth() - 20 )
	text:SetFont( GameFontNormal:GetFont(), 13, "OUTLINE" )
	
	texture:SetPoint( "TOPLEFT", row, "TOPLEFT", 2, -2 )
	button:SetPoint( "TOPLEFT", row, "TOPLEFT", 0, 0 )
	
	if( SSPVP.db.profile.arena.showIcon ) then
		text:SetPoint( "TOPLEFT", texture, "TOPLEFT", 17, 5 )
	else
		text:SetPoint( "TOPLEFT", row, "TOPLEFT", 3, 3 )
	end
	
	
	local bindKey = GetBindingKey( "ARENATAR" .. id )
	if( bindKey ) then
		SetOverrideBindingClick( button, false, bindKey, button:GetName() )
	end
	
	if( id > 1 ) then
		row:SetPoint( "TOPLEFT", getglobal( self.frame:GetName() .. "Row" .. ( id - 1 ) ), "TOPLEFT", 0, -18 )
	else
		row:SetPoint( "TOPLEFT", self.frame, "TOPLEFT", 5, -1 )
	end
end


-- I'll fix this up later
function Arena:SortEnemies( a, b )
	if( not a or not b ) then
		return false
	end
	
	if( a.name < b.name ) then
		return false
	end
	
	return true
end

function Arena:UpdateTargetFrame()
	if( InCombatLockdown() ) then
		SSPVP:RegisterOOCUpdate( self, "UpdateTargetFrame" )
		return
	end

	if( #( enemies ) == 0 ) then
		if( self.frame ) then
			self.frame:Hide()
		end
		return
	end

	if( not self.frame ) then
		self:CreateTargetFrame()
	end

	for i=1, CREATED_ROWS do
		getglobal( self.frame:GetName() .. "Row" .. i .. "Text" ).usedName = nil
		getglobal( self.frame:GetName() .. "Row" .. i ):Hide()
	end
	
	local sepEnemies, sepPets, parsedEnemies
	
	if( SSPVP.db.profile.arena.showPets ) then
		sepEnemies = {}
		sepPets = {}
		parsedEnemies = {}

		-- Seperate the enemies from the pets
		for _, enemy in pairs( enemies ) do
			if( not enemy.owner ) then
				table.insert( sepEnemies, enemy )
			else
				table.insert( sepPets, enemy )
			end
		end

		-- Sort them all
		table.sort( sepEnemies, self.SortEnemies )
		table.sort( sepPets, self.SortEnemies )
		
		-- Now merge
		parsedEnemies = sepEnemies
		for id, row in pairs( sepPets ) do
			table.insert( parsedEnemies, row )
		end
	else
		parsedEnemies = enemies
		table.sort( parsedEnemies, self.SortEnemies )
	end
	
	local coords, row, button, text, texture
	local num = ""
	
	for id, enemy in pairs( parsedEnemies ) do
		self:CreateTargetRow( id )
		
		row = getglobal( self.frame:GetName() .. "Row" .. id )
		button = getglobal( row:GetName() .. "Button" )
		text = getglobal( row:GetName() .. "Text" )
		texture = getglobal( row:GetName() .. "Icon" )
		
		-- Is it a player?
		if( not enemy.owner ) then
			self: UpdateEnemyText( enemy, id, text )
			text.usedName = enemy.name
			text:SetTextColor( RAID_CLASS_COLORS[ enemy.classToken ].r, RAID_CLASS_COLORS[ enemy.classToken ].g, RAID_CLASS_COLORS[ enemy.classToken ].b )
			
			if( SSPVP.db.profile.arena.showIcon ) then
				coords = CLASS_BUTTONS[ enemy.classToken ]
	
				texture:SetTexture( "Interface\\WorldStateFrame\\Icons-Classes" )
				texture:SetTexCoord( coords[1], coords[2], coords[3], coords[4] )
				texture:Show()
			else
				texture:Hide()
			end

		elseif( SSPVP.db.profile.arena.showPets ) then
			if( enemy.family ) then
				text:SetText( num .. enemy.name .. " " .. enemy.family )
			else
				text:SetText( num .. string.format( L["%s's %s"], enemy.owner, enemy.name ) )
			end
			
			text:SetTextColor( SSPVP.db.profile.arena.petColor.r, SSPVP.db.profile.arena.petColor.g, SSPVP.db.profile.arena.petColor.b )
			texture:Hide()
		end
		
		if( not enemy.isDead ) then
			row:SetAlpha( 1.0 )
		else
			row:SetAlpha( SSPVP.db.profile.arena.deadOpacity )
		end

		if( SSPVP.db.profile.arena.locked ) then
			button:SetAttribute( "type", "macro" )
			button:SetAttribute( "macrotext", "/target " .. enemy.name )
		else
			button:SetScript( "OnMouseDown", self.StartMoving )
			button:SetScript( "OnMouseUp", self.StopMoving )
		end
		
		row:Show()
	end

	self.frame:SetHeight( ( #( enemies ) * 19 ) + 5 )
	self.frame:Show()
end

function Arena:EnemyData( event, name, server, race, classToken, guild )
	if( SSPVP.db.profile.arena.target ) then
		for _, enemy in pairs( enemies ) do
			if( not enemy.owner and enemy.name == name ) then
				return
			end
		end
		
		table.insert( enemies, { name = name, health = 100, maxHealth = 100, server = server, race = race, classToken = classToken, guild = guild } )
		
		self:UpdateTargetFrame()
	end
end

function Arena:PetData( event, name, owner, family )
	if( SSPVP.db.profile.arena.target ) then
		for _, enemy in pairs( enemies ) do
			if( enemy.owner == owner and enemy.name == name ) then
				return
			end
		end
		
		table.insert( enemies, { name = name, owner = owner, family = family } )
		
		self:UpdateTargetFrame()
	end
end

function Arena:EnemyDied( event, name )
	for id, enemy in pairs( enemies ) do
		if( not enemy.isDead and enemy.name == name ) then
			enemies[ id ].isDead = true
			self:UpdateEnemyHealth( id, 0, 100 )
			break
		end
	end
end

function Arena:CHAT_MSG_COMBAT_HOSTILE_DEATH( event, msg )
	if( string.find( msg, PartySlain ) ) then
		local died = string.match( msg, PartySlain )

		self:EnemyDied( event, died )		
		PVPSync:SendMessage( "ENEMYDIED:" .. died )

	elseif( string.find( msg, SelfSlain ) ) then
		local died = string.match( msg, SelfSlain )

		self:EnemyDied( event, died )
		PVPSync:SendMessage( "ENEMYDIED:" .. died )
	end
end
function Arena:CheckUnit( unit )
	if( SSPVP.db.profile.arena.target and UnitIsEnemy( unit, "player" ) and UnitIsPVP( unit ) ) then
		if( UnitIsPlayer( unit ) ) then
			local name, server = UnitName( unit )
			server = server or GetRealmName()
			
			if( name ~= L["Unknown"] ) then
				for _, enemy in pairs( enemies ) do
					if( not enemy.owner and enemy.name == name ) then
						return
					end
				end
				
				local race = UnitRace( unit )
				local class, classToken = UnitClass( unit )
				local guild = GetGuildInfo( unit )
				
				table.insert( enemies, { name = name, server = server, race = race, health = UnitHealth( unit ) or 100, maxHealth = UnitHealthMax( unit ) or 100, classToken = classToken, guild = guild } )
				self:UpdateTargetFrame()
				
				local spec = ""
				if( AEI ) then
					spec = AEI:GetSpec( name, server )
				end
				
				-- Print out info message
				if( guild ) then
					SSPVP:ChannelMessage( string.format( L["[%d/%d] %s / %s / %s / %s / %s"], #( enemies ), SSPVP:MaxBattlefieldPlayers(), name, class, race, guild, server ) .. spec )
					PVPSync:SendMessage( "ENEMY:" .. name .. "," .. server .. "," .. race .. "," .. classToken .. "," .. guild )
				else
					SSPVP:ChannelMessage( string.format( L["[%d/%d] %s / %s / %s / %s"], #( enemies ), SSPVP:MaxBattlefieldPlayers(), name, class, race, server ) .. spec )				
					PVPSync:SendMessage( "ENEMY:" .. name .. "," .. server .. "," .. race .. "," .. classToken )
				end
			end

		-- No method of finding out the owner unless we mouse over
		elseif( unit ~= "target" ) then
			-- Warlock or Mage pet
			local owner = string.match( GameTooltipTextLeft2:GetText(), L["([a-zA-Z]+)%'s Minion"] )
			if( owner and owner ~= L["Unknown"] ) then
				local name =  UnitName( unit )
				if( name ~= L["Unknown"] ) then
					for _, enemy in pairs( enemies ) do
						if( enemy.owner == owner and enemy.name == name ) then
							return
						end
					end
					
					local family = UnitCreatureFamily( unit )

					table.insert( enemies, { name = name, owner = owner, family = family } )
					self:UpdateTargetFrame()
					
					-- Warlock pets have a family type, Mage pets do not
					if( family ) then
						SSPVP:ChannelMessage( string.format( L["[%d/%d] %s's pet, %s %s"], #( enemies ), SSPVP:MaxBattlefieldPlayers(), owner, name, family ) )
						PVPSync:SendMessage( "ENEMYPET:" .. name .. "," .. owner .. "," .. family )
					else
						SSPVP:ChannelMessage( string.format( L["[%d/%d] %s's pet, %s"], #( enemies ), SSPVP:MaxBattlefieldPlayers(), owner, name ) )
						PVPSync:SendMessage( "ENEMYPET:" .. name .. "," .. owner )
					end
				end
			end
		end
	end
end

function Arena:UPDATE_MOUSEOVER_UNIT()
	self:CheckUnit( "mouseover" )
	self:ScanHealth( "mouseover" )
end

function Arena:PLAYER_TARGET_CHANGED()
	self:CheckUnit( "target" )
end

function Arena:CHAT_MSG_BG_SYSTEM_NEUTRAL( event, message )
	if( message == L["The Arena battle has begun!"] ) then
		SSOverlay:UpdateTimer( "arena", L["Stealth buff spawn: %s"], 92 )
		
		-- It's possible to mouseover an "enemy" when they're zoning in, so clear it just to be safe
		enemies = {}
		self:UpdateTargetFrame()
	end
end

function Arena:ADDON_LOADED( event, addon )
	if( addon == "Blizzard_InspectUI" ) then
		hooksecurefunc( "InspectPVPTeam_Update", self.InspectPVPTeam_Update )	
	end
end

-- Modifies the team details page to show percentage of games played
function Arena:PVPTeamDetails_Update()
	if( not SSPVP.db.profile.arena.modify ) then
		return
	end
	
	local _, _, _, teamPlayed, _,  seasonTeamPlayed = GetArenaTeam( PVPTeamDetails.team )
	local name, rank, online, playedText, played, seasonPlayed, percent
			
	for i=1, GetNumArenaTeamMembers( PVPTeamDetails.team, 1 ) do
		playedText = getglobal( "PVPTeamDetailsButton" .. i .. "Played" )
		
		name, rank, _, _, online, played, _, seasonPlayed = GetArenaTeamRosterInfo( PVPTeamDetails.team, i )
		
		if( rank == 0 and not online ) then
			getglobal( "PVPTeamDetailsButton" .. i .. "NameText" ):SetText( string.format( L["(L) %s"], name ) )
		end
		
		-- Fix the percentage
		if( PVPTeamDetails.season and seasonPlayed > 0 and seasonTeamPlayed > 0 ) then
			percent = seasonPlayed / seasonTeamPlayed
			
		elseif( played > 0 and teamPlayed > 0 ) then
			percent = played / teamPlayed
		else
			percent = 0
		end
		
		playedText.tooltip = string.format( "%.2f%%", percent * 100 )
	end
end

-- Adds the actual rating!
function Arena:SetRating( parent, teamSize, teamRating )
	if( teamRating == 0 ) then
		return
	end

	local points
	local ratingText = getglobal( parent .. "DataRating" )
	local label = getglobal( parent.. "DataRatingLabel" )
	
	if( teamRating > 1500 ) then
		points = 1426.79 / ( 1 + 918.836 * math.pow( 2.71828, -0.00386405 * teamRating ) )
	else
		points = 0.38 * teamRating - 194
	end

	if( points < 0 ) then
		points = 0
	end

	-- Apply the percent reduction from brackets
	if( teamSize == 3 ) then
		points = points * 0.80
	elseif( teamSize == 2 ) then
		points = points * 0.70
	end

	ratingText:ClearAllPoints()
	ratingText:SetPoint( "LEFT", parent .. "DataRatingLabel", "RIGHT", 2, 0 )

	label:ClearAllPoints()
	label:SetPoint( "LEFT", parent .. "DataName", "RIGHT", -19, 0 )

	ratingText:SetText( string.format( "%d |cffffffff(%d)|r", teamRating, points ) )
	ratingText:SetWidth( 70 )

	getglobal( parent .. "DataName" ):SetWidth( 160 )
end

-- Add points next to rating
function Arena:PVPTeam_Update()
	if( not SSPVP.db.profile.arena.modify ) then
		return
	end
	
	local teams = { { size = 2 }, { size = 3 }, { size = 5 } }
	local teamSize, teamName, teamRating, teamPlayed, seasonTeamPlayed, playerPlayed, seasonPlayerPlayed

	for _, value in pairs( teams ) do
		for i=1, MAX_ARENA_TEAMS do
			teamName, teamSize = GetArenaTeam( i )
			if( value.size == teamSize ) then
				value.index = i
			end
		end
	end

	local buttonIndex = 0
	
	for _, value in pairs( teams ) do
		if( value.index ) then
			buttonIndex = buttonIndex + 1 
			_, _, teamRating, teamPlayed, _, seasonTeamPlayed, _, playerPlayed, seasonPlayerPlayed = GetArenaTeam( value.index )
			
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
				getglobal( "PVPTeam" .. buttonIndex .."DataPlayed"):SetVertexColor( 1.0, 0, 0 )
			else
				getglobal( "PVPTeam" .. buttonIndex .."DataPlayed"):SetVertexColor( 1.0, 1.0, 1.0 )
			end

			getglobal( "PVPTeam" .. buttonIndex .. "DataPlayed" ):SetText( playerPlayed .. " (" ..floor( percent * 100 ) .. "%)" )

			Arena:SetRating( "PVPTeam" .. buttonIndex, value.size, teamRating )
		end
	end
end

-- Add points next to rating, and also add team bracket
function Arena:InspectPVPTeam_Update()
	if( not SSPVP.db.profile.arena.modify ) then
		return
	end

	local teams = { { size = 2 }, { size = 3 }, { size = 5 } }
	local teamName, teamSize, teamName, teamRating

	for _, value in pairs( teams ) do
		for i=1, MAX_ARENA_TEAMS do
			teamName, teamSize = GetInspectArenaTeamData( i )
			if( value.size == teamSize ) then
				value.index = i
			end
		end
	end

	local buttonIndex = 0
	
	for _, value in pairs( teams ) do
		if( value.index ) then
			teamName, teamSize, teamRating = GetInspectArenaTeamData( value.index )

			buttonIndex = buttonIndex + 1

			getglobal( "InspectPVPTeam" .. buttonIndex .. "DataName" ):SetText( string.format( L["%s |cffffffff(%dvs%d)|r"], teamName, teamSize, teamSize ) )
			Arena:SetRating( "InspectPVPTeam" .. buttonIndex, teamSize, teamRating )
		end
	end
end

-- Deals with catching sync messages from other battleground mods
function Arena:TranslateClass( class )
	for classToken, className in pairs( L["CLASSES"] ) do
		if( className == class ) then
			return classToken
		end
	end
	
	return nil
end

function Arena:CHAT_MSG_ADDON( event, prefix, msg, type, author )
	-- "<name> <class>"
	if( prefix == "ArenaMaster" ) then
		local name, class = string.split( " ", msg )
		self:EnemyData( event, name, nil, nil, string.upper( class ) )

	-- "<name>,<class>"
	elseif( prefix == "ALF_T" ) then
		local name, class = string.split( ",", msg )
		self:EnemyData( event, name, nil, nil, self:TranslateClass( class ) )
	
	-- "AOP <name>:<class>:<race>"
	elseif( prefix == "BGGQ" and string.sub( msg, 0, 3 ) == "AOP" ) then
		local name, class, race = string.split( ":", string.sub( msg, 5 ) )
		self:EnemyData( event, name, nil, race, self:TranslateClass( class ) )
	
	-- "0,<name>,<class>"
	-- Yay ArenaUnitFrames plays nicely and uses class Token
	elseif( prefix == "ArenaUnitFrames" ) then
		local _, name, class = string.split( ",", msg )
		self:EnemyData( event, name, nil, nil, class )
	
	-- Accidentally SSPVP 2.4 uses "RAID" type instead of "BATTLEGROUND", meaning
	-- most of the time the sync messages from it wont be caught unless you're grouped
	-- "FOUND:<num>:<name>:<server>:<race>:<class>"
	elseif( prefix == "SSPVP" and string.sub( msg, 0, 5 ) == "FOUND" ) then
		local _, name, server, race, class = string.split( ":", string.sub( msg, 7 ) )
		self:EnemyData( event, name, server, race, self:TranslateClass( class ) )
	end
end

-- Slash commands
-- Games required to get 30%
function Arena.CalculateGoal( currentGames, currentTotal )
	currentGames = tonumber( currentGames )
	currentTotal = tonumber( currentTotal )
		
	local percentage = currentGames / currentTotal
	
	if( percentage >= 0.30 ) then
		SSPVP:Print( string.format( L["%d games is already 30%% of %d."], currentGames, currentTotal ) )
		return
	end
	
	local totalGames = currentTotal
	local games = currentGames
	
	while( percentage < 0.30 ) do
		games = games + 1
		totalGames = totalGames + 1
		
		percentage = games / totalGames
	end
	
	SSPVP:Print( string.format( L["You have played %d games and need to play %d more (%d played games, %d total games) to reach 30%%"], currentGames, totalGames - currentTotal, games, totalGames ) )
end

-- Points -> Rating
local function GetRating( points )
	local rating = 0
	if( points > 376 ) then
		rating = math.log( ( 1426.79 / points - 1 ) / 918.836 ) / -0.00386405
	else
		rating = ( points + 194 ) / 0.38
	end

	if( rating < 0 ) then
		rating = 0
	end
	
	return math.floor( rating + 0.5 )
end

function Arena.CalculateRating( points )
	points = tonumber( points )

	SSPVP:Print( string.format( L["[%d vs %d] %d points = %d rating"], 5, 5, points, GetRating( points ) ) )
	SSPVP:Print( string.format( L["[%d vs %d] %d points = %d rating"], 3, 3, points, GetRating( points * 0.80 ) ) )
	SSPVP:Print( string.format( L["[%d vs %d] %d points = %d rating"], 2, 2, points, GetRating( points * 0.70 ) ) )
end

-- Rating -> Points
function Arena.CalculatePoints( rating )
	rating = tonumber( rating )
	
	local points
	if( rating > 1500 ) then
		points = 1426.79 / ( 1 + 918.836 * math.pow( 2.71828, -0.00386405 * rating ) )
	else
		points = 0.38 * rating - 194
	end
	
	if( points < 0 ) then
		points = 0
	end

	SSPVP:Print( string.format( L["[%d vs %d] %d rating = %d points"], 5, 5, rating, points ) )
	SSPVP:Print( string.format( L["[%d vs %d] %d rating = %d points - %d%% = %d points"], 3, 3, rating, points, 80, points * 0.80 ) )
	SSPVP:Print( string.format( L["[%d vs %d] %d rating = %d points - %d%% = %d points"], 2, 2, rating, points, 70, points * 0.70 ) )
end