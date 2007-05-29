local UI = SSPVP:NewModule( "SSPVP-UI" );

local L = SSPVPLocals;
local soundPlaying;


function UI:Initialize()
	SSPVP.cmd:RegisterSlashHandler( L["on - Enables SSPVP"], "on", self.CmdEnable );
	SSPVP.cmd:RegisterSlashHandler( L["off - Disables SSPVP"], "off", self.CmdDisable );	
	SSPVP.cmd:RegisterSlashHandler( L["ui - Pulls up the configuration page."], "ui", self.OpenUI );
	SSPVP.cmd:RegisterSlashHandler( L["map - Toggles the battlefield minimap regardless of being inside a battleground."], "map", self.ToggleMinimap );
end

function UI:ToggleMinimap()
	BattlefieldMinimap_LoadUI(); 
	
	if( BattlefieldMinimap:IsVisible() ) then
		MiniMapBattlefieldFrame.status = "";
		BattlefieldMinimap:Hide();
	else
		MiniMapBattlefieldFrame.status = "active";
		BattlefieldMinimap:Show();
	end 
end

function UI:OpenUI()
	UIParentLoadAddOn( "SSUI" );
	SSUI:ShowConfig( "sspvp" );
end

function UI:CmdEnable()
	SSPVP:Enable();
	SSPVP:Print( L["Is now enabled."] );
end

function UI:CmdDisable()
	SSPVP:Disable();
	SSPVP:Print( L["Is now disabled."] );
end

function UI:Reload()
	local module = SSPVP:HasModule( this.ChangeArg1 or this.arg1 );
	if( module and module.Reload ) then
		module:Reload();
	end
end

function UI:ToggleSSPVP()
	if( SSPVP.db.profile.general.enabled ) then
		SSPVP:Enable();	
	else
		SSPVP:Disable();
	end
end

function UI:PlaySound()
	if( soundPlaying ) then
		this:SetText( L["Play"] );

		SSPVP:StopSound();
		soundPlaying = nil;
	else
		this:SetText( L["Stop"] );

		SSPVP:PlaySound();
		soundPlaying = true;
	end
end

function UI:LoadUI()
	SSUI:RegisterUI( "sspvp", { defaultTab = "SSGeneral", title = L["SSPVP"], get = function( vars ) return SSPVP.db.profile[ vars[1] ][ vars[2] ]; end, set = function( vars, value ) SSPVP.db.profile[ vars[1] ][ vars[2] ] = value; end } );

	SSUI:RegisterTab( "sspvp", "SSGeneral", L["General"], 1 );
	SSUI:RegisterTab( "sspvp", "SSModules", L["Modules"], 2 );
	SSUI:RegisterTab( "sspvp", "SSJoin", L["Auto Join"], 3 );
	SSUI:RegisterTab( "sspvp", "SSLeave", L["Auto Leave"], 4 );
	SSUI:RegisterTab( "sspvp", "SSBattlefield", L["Battlefield"], 5 );
	SSUI:RegisterTab( "sspvp", "SSCOverlay", L["Overlay"], 6 );
	SSUI:RegisterTab( "sspvp", "SSQOverlay", L["Queue Overlay"], 7 );
	SSUI:RegisterTab( "sspvp", "SSCArena", L["Arenas"], 8 );
	SSUI:RegisterTab( "sspvp", "SSAlteracValley", L["Alterac Valley"], 9 );
	SSUI:RegisterTab( "sspvp", "SSArathiBasin", L["Arathi Basin"], 10 );
	SSUI:RegisterTab( "sspvp", "SSWarsongGulch", L["Warsong Gulch"], 11 );
	SSUI:RegisterTab( "sspvp", "SSEyeOfTheStorm", L["Eye of the Storm"], 12 );
	SSUI:RegisterTab( "sspvp", "SSTurnIn", L["Auto turn in"], 13 );
	
	local priorityList = {};
	for key, num in pairs( SSPVP.db.profile.priority ) do
		table.insert( priorityList, { num, key, L[ key ] } );
	end
	
	-- Add the elements
	local UIList = {
		-- General
		{ text = L["Enable SSPVP"], OnChange = UI.ToggleSSPVP, type = "check", var = { "general", "enabled" }, parent = "SSGeneral" };
		{ text = L["Block all messages starting with [SS]"], tooltip = L["This will block all messages that SSPVP sent out, this is mainly timers or found messages in Arenas."], type = "check", var = { "general", "block" }, parent = "SSGeneral" };
		{ text = L["Default Channel"], tooltip = L["Default channel that all information like score board faction balance and timers are sent to."], type = "dropdown", list = { { "BATTLEGROUND", L["Battleground"] }, { "RAID", L["Raid"] }, { "PARTY", L["Party"] } },  var = { "general", "channel" }, parent = "SSGeneral" },
		{ text = L["Enable faction balance overlay"], type = "check", OnChange = self.Reload, arg1 = "SSPVP-Score", var = { "general", "factBalance" }, parent = "SSGeneral" };
		{ text = L["Auto solo queue when ungrouped"], type = "check", var = { "queue", "autoSolo" }, parent = "SSGeneral" };
		{ text = L["Auto group queue when leader"], type = "check", var = { "queue", "autoGroup" }, parent = "SSGeneral" };
		{ text = L["Lock world PvP objectives"], type = "check", OnChange = self.Reload, arg1 = "SSPVP-Mover", var = { "mover", "world" }, parent = "SSGeneral" };
		{ text = L["Lock battlefield scoreboard"], type = "check", OnChange = self.Reload, arg1 = "SSPVP-Mover", var = { "mover", "score" }, parent = "SSGeneral" };
		{ text = L["Lock capture bars"], type = "check", OnChange = self.Reload, arg1 = "SSPVP-Mover", var = { "mover", "capture" }, parent = "SSGeneral" };
		{ text = L["Sound file"], tooltip = L["Sound file to play when a queue is ready, the file must be inside Interface\\AddOns\\SSPVP and have been present when you started the game."], type = "input", width = 150, var = { "general", "sound" }, parent = "SSGeneral" },
		{ text = L["Play"], type = "button", width = 100, OnChange = UI.PlaySound, parent = "SSGeneral" },
 		
 		-- Auto join
 		{ text = L["Enable auto join"], type = "check", var = { "join", "enabled" }, parent = "SSJoin" };
		{ text = L["Battleground join delay"], type = "input", forceType = "int", width = 30, var = { "join", "bgDelay" }, parent = "SSJoin" },
		{ text = L["AFK battleground join delay"], type = "input", forceType = "int", width = 30, var = { "join", "bgAfk" }, parent = "SSJoin" },
		{ text = L["Arena join delay"], type = "input", forceType = "int", width = 30, var = { "join", "arenaDelay" }, parent = "SSJoin" },
		{ text = L["Battlefield auto joining priorities"], tooltip = L["Priority system to use when auto joining battlegrounds, equal priorities will not override eachother, If you have Warsong Gulch as #1 and Arathi Basin as #2 you'll always auto join Warsong Gulch when in Arathi Basin, but not Arathi Basin when inside Warsong Gulch."], list = priorityList, type = "priority", var = { "priority" }, parent = "SSJoin" },
 		
 		-- Auto leave
 		{ text = L["Enable auto leave"], type = "check", var = { "leave", "enabled" }, parent = "SSLeave" };
 		{ text = L["Enable confirmation when leaving"], type = "check", var = { "leave", "confirm" }, parent = "SSLeave" };
 		{ text = L["Take score screenshot on game end"], type = "check", var = { "leave", "screen" }, parent = "SSLeave" };
		{ text = L["Auto leave delay"], type = "input", forceType = "int", width = 30, var = { "leave", "delay" }, parent = "SSLeave" },
 		
 		-- Battlefield
 		{ text = L["Auto open minimap when inside a battleground"], type = "check", var = { "bf", "minimap" }, parent = "SSBattlefield" };
 		{ text = L["Auto release when inside an active battlefield"], type = "check", var = { "bf", "release" }, parent = "SSBattlefield" };
 		{ text = L["Auto release even with a soulstone active"], type = "check", var = { "bf", "releaseSS" }, parent = "SSBattlefield" };
 		{ text = L["Auto accept corpse ressurects inside a battlefield"], type = "check", var = { "bf", "autoAccept" }, parent = "SSBattlefield" };
 		{ text = L["Color names by class on score board"], type = "check", var = { "score", "color" }, parent = "SSBattlefield" };
 		{ text = L["Hide class icon next to names on score board"], type = "check", var = { "score", "icon" }, parent = "SSBattlefield" };
 		{ text = L["Show player levels next to names on score board"], type = "check", var = { "score", "level" }, parent = "SSBattlefield" };

 		-- Queue Overlay
		{ text = L["Enable queue overlay"], type = "check", OnChange = SSPVP.Reload, var = { "queue", "enabled" }, parent = "SSQOverlay" };
		{ text = L["Show queue overlay inside battlegrounds"], OnChange = SSPVP.Reload, type = "check", var = { "queue", "insideField" }, parent = "SSQOverlay" };
		{ text = L["Show estimated time until queue is ready"], OnChange = SSPVP.Reload, type = "check", var = { "queue", "showEta" }, parent = "SSQOverlay" };
		{ text = L["Estimated time format"], type = "dropdown", OnChange = SSPVP.Reload, list = { { "hhmmss", L["hh:mm:ss"] }, { "minsec", L["Min X, Sec X"] }, { "min", L["Min X"] } },  var = { "queue", "etaFormat" }, parent = "SSQOverlay" },
 		
 		-- Overlay
		{ text = L["Lock overlay"], type = "check", OnChange = self.Reload, arg1 = "SSPVP-Overlay", var = { "overlay", "locked" }, parent = "SSCOverlay" };
		{ text = L["Timer format"], OnChange = self.Reload, arg1 = "SSPVP-Overlay", type = "dropdown", list = { { "hhmmss", L["hh:mm:ss"] }, { "minsec", L["Min X, Sec X"] }, { "min", L["Min X"] } },  var = { "overlay", "timer" }, parent = "SSCOverlay" },
		{ text = L["Category text type"], OnChange = self.Reload, arg1 = "SSPVP-Overlay", tooltip = L["Mode to use when displaying category text, auto will show it when more then one category is being shown."], type = "dropdown", list = { { "hide", L["Always hide"] }, { "show", L["Always show"] }, { "auto", L["Auto hiding"] } },  var = { "overlay", "catType" }, parent = "SSCOverlay" },
		{ text = L["Display mode"], OnChange = self.Reload, arg1 = "SSPVP-Overlay", type = "dropdown", list = { { "down", L["Top -> Bottom"] }, { "up", L["Bottom -> Top"] } },  var = { "overlay", "displayType" }, parent = "SSCOverlay" },
		{ text = L["Row padding"], tooltip = L["Spacing in between rows in the overlay"], type = "input", OnChange = self.Reload, arg1 = "SSPVP-Overlay", forceType = "int", width = 30, var = { "overlay", "rowPad" }, parent = "SSCOverlay" },
		{ text = L["Category padding"], tooltip = L["Spacing in between categories in the overlay"], type = "input", OnChange = self.Reload, arg1 = "SSPVP-Overlay", forceType = "int", width = 30, var = { "overlay", "catPad" }, parent = "SSCOverlay" },
		{ text = L["Background color"], OnChange = self.Reload, arg1 = "SSPVP-Overlay", type = "color", var = { "overlay", "background" }, parent = "SSCOverlay" },
		{ text = L["Border color"], OnChange = self.Reload, arg1 = "SSPVP-Overlay", type = "color", var = { "overlay", "border" }, parent = "SSCOverlay" },
		{ text = L["Text color"], OnChange = self.Reload, arg1 = "SSPVP-Overlay", type = "color", var = { "overlay", "textColor" }, parent = "SSCOverlay" },
		{ text = L["Category text color"], OnChange = self.Reload, arg1 = "SSPVP-Overlay", type = "color", var = { "overlay", "categoryColor" }, parent = "SSCOverlay" },
		{ text = L["Background opacity: %d%%"], OnChange = self.Reload, arg1 = "SSPVP-Overlay", showValue = true, isPercent = true, type = "slider", var = { "overlay", "opacity" }, parent = "SSCOverlay" },
		{ text = L["Text opacity: %d%%"], OnChange = self.Reload, arg1 = "SSPVP-Overlay", showValue = true, isPercent = true, type = "slider", var = { "overlay", "textOpacity" }, parent = "SSCOverlay" },
		
		-- Arena
		{ text = L["Enable enemy team report"], OnChange = self.Reload, arg1 = "SSPVP-Arena", tooltip = L["Reports team you are facing when you mouse over them inside an arena, this will also pull up a frame you can click to target them.\nThis will NOT update while you are in combat."], type = "check", var = { "arena", "target" }, parent = "SSCArena" };
		{ text = L["Show enemy number next to name on arena frames"], type = "check", OnChange = self.Reload, arg1 = "SSPVP-Arena", var = { "arena", "enemyNum" }, parent = "SSCArena" };
		{ text = L["Lock team report frame"], type = "check", OnChange = self.Reload, arg1 = "SSPVP-Arena", var = { "arena", "locked" }, parent = "SSCArena" },
		{ text = L["Show enemy health next to name on arena frame"], type = "check", OnChange = self.Reload, arg1 = "SSPVP-Arena", var = { "arena", "showHealth" }, parent = "SSCArena" },
		{ text = L["Show enemy class icon"], type = "check", OnChange = self.Reload, arg1 = "SSPVP-Arena", var = { "arena", "showIcon" }, parent = "SSCArena" },
		{ text = L["Show enemy minions on arena enemy frames"], tooltip = L["Controls display of Warlock and Mage Elemental pets"], type = "check", OnChange = self.Reload, arg1 = "SSPVP-Arena", var = { "arena", "showPets" }, parent = "SSCArena" },
		{ text = L["Enemy pet name color"], type = "color", OnChange = self.Reload, arg1 = "SSPVP-Arena", var = { "arena", "petColor" }, parent = "SSCArena" },
		{ text = L["Border color"], type = "color", OnChange = self.Reload, arg1 = "SSPVP-Arena", var = { "arena", "border" }, parent = "SSCArena" },
		{ text = L["Background color"], type = "color", OnChange = self.Reload, arg1 = "SSPVP-Arena", var = { "arena", "background" }, parent = "SSCArena" },
		{ text = L["Background opacity: %d%%"], OnChange = self.Reload, arg1 = "SSPVP-Arena", showValue = true, isPercent = true, type = "slider", var = { "arena", "opacity" }, parent = "SSCArena" },
		{ text = L["Dead enemy opacity: %d%%"], tooltip = L["Enemy row opacity if they are currently dead."], OnChange = self.Reload, arg1 = "SSPVP-Arena", showValue = true, isPercent = true, type = "slider", var = { "arena", "deadOpacity" }, parent = "SSCArena" },
		{ text = L["Targetting frame scale: %d%%"], OnChange = self.Reload, arg1 = "SSPVP-Arena", showValue = true, isPercent = true, type = "slider", var = { "arena", "scale" }, parent = "SSCArena" },
 		
 		-- Alterac Valley
		{ text = L["Enable capture timers"], type = "check", OnChange = self.Reload, arg1 = "SSPVP-AV", var = { "av", "timers" }, parent = "SSAlteracValley" };
		{ text = L["Enable armor scraps tracking"], type = "check", OnChange = self.Reload, arg1 = "SSPVP-AV", var = { "av", "armor" }, parent = "SSAlteracValley" };
		{ text = L["Enable flesh/medal tracking"], type = "check", OnChange = self.Reload, arg1 = "SSPVP-AV", var = { "av", "medal" }, parent = "SSAlteracValley" };
		{ text = L["Enable blood/crystal tracking"], type = "check", OnChange = self.Reload, arg1 = "SSPVP-AV", var = { "av", "crystal" }, parent = "SSAlteracValley" };
		{ text = L["Enable interval capture messages"], type = "check", OnChange = self.Reload, arg1 = "SSPVP-AV", var = { "av", "enabled" }, parent = "SSAlteracValley" };
		{ text = L["Interval in seconds between messages"], type = "input", forceType = "int", width = 30, var = { "av", "interval" }, parent = "SSAlteracValley" },
		{ text = L["Interval frequency increase"], tooltip = L["The percentage to increase the frequency of the capture alerts, this will active when 2 minutes is left before something is captured."], OnChange = self.Reload, arg1 = "SSPVP-AV", type = "dropdown", list = { { 0, L["None"] }, { 0.75, L["25%"] }, { 0.50, L["50%"] }, { 0.25, L["75%"] } },  var = { "av", "speed" }, parent = "SSAlteracValley" },
		
		-- Arathi Basin
		{ text = L["Enable capture timers"], type = "check", OnChange = self.Reload, arg1 = "SSPVP-AB", var = { "ab", "timers" }, parent = "SSArathiBasin" };
		{ text = L["Enable estimated final score overlay"], type = "check", OnChange = self.Reload, arg1 = "SSPVP-AB", var = { "ab", "overlay" }, parent = "SSArathiBasin" };
		{ text = L["Estimated final score"], type = "check", OnChange = self.Reload, arg1 = "SSPVP-AB", var = { "ab", "finalScore" }, parent = "SSArathiBasin" };
		{ text = L["Estimated time left in the battlefield"], type = "check", OnChange = self.Reload, arg1 = "SSPVP-AB", var = { "ab", "timeLeft" }, parent = "SSArathiBasin" };
		{ text = L["Show bases to win"], type = "check", OnChange = self.Reload, arg1 = "SSPVP-AB", var = { "ab", "basesWin" }, parent = "SSArathiBasin" };
		{ text = L["Show bases to win score"], type = "check", OnChange = self.Reload, arg1 = "SSPVP-AB", var = { "ab", "basesScore" }, parent = "SSArathiBasin" };
		
		-- Warsong Gulch
		{ text = L["Enable carrier names"], type = "check", OnChange = self.Reload, arg1 = "SSPVP-WSG", var = { "wsg", "carriers" }, parent = "SSWarsongGulch" };
		{ text = L["Show border around carrier names"], type = "check", OnChange = self.Reload, arg1 = "SSPVP-WSG", var = { "wsg", "border" }, parent = "SSWarsongGulch" };
		{ text = L["Show carrier health when available"], type = "check", OnChange = self.Reload, arg1 = "SSPVP-WSG", var = { "wsg", "health" }, parent = "SSWarsongGulch" };
		{ text = L["Time until flag respawns"], type = "check",OnChange = self.Reload, arg1 = "SSPVP-WSG", var = { "wsg", "respawn" }, parent = "SSWarsongGulch" };
		{ text = L["Show time elapsed since flag was picked up"], type = "check",OnChange = self.Reload, arg1 = "SSPVP-WSG", var = { "wsg", "flagElapsed" }, parent = "SSWarsongGulch" };
		{ text = L["Show time taken before the flag was captured"], tooltip = L["Tells how long it took from the time the flag was picked up to the time the flag was captured."], type = "check",OnChange = self.Reload, arg1 = "SSPVP-WSG", var = { "wsg", "flagCapTime" }, parent = "SSWarsongGulch" };

		-- Eye of the Storm
		{ text = L["Enable overlay"], type = "check", OnChange = self.Reload, arg1 = "SSPVP-EoTS", var = { "eots", "overlay" }, parent = "SSEyeOfTheStorm" };
		{ text = L["Enable carrier names"], type = "check", OnChange = self.Reload, arg1 = "SSPVP-EoTS", var = { "eots", "carriers" }, parent = "SSEyeOfTheStorm" };
		{ text = L["Show border around carrier names"], type = "check", OnChange = self.Reload, arg1 = "SSPVP-EoTS", var = { "eots", "border" }, parent = "SSEyeOfTheStorm" };
		{ text = L["Time until flag respawns"], type = "check",OnChange = self.Reload, arg1 = "SSPVP-EoTS", var = { "eots", "respawn" }, parent = "SSEyeOfTheStorm" };
		{ text = L["Estimated time left in the battlefield"], type = "check", OnChange = self.Reload, arg1 = "SSPVP-EoTS", var = { "eots", "timeLeft" }, parent = "SSEyeOfTheStorm" };
		{ text = L["Estimated final score"], type = "check", OnChange = self.Reload, arg1 = "SSPVP-EoTS", var = { "eots", "finalScore" }, parent = "SSEyeOfTheStorm" };
		{ text = L["Show bases to win"], type = "check", OnChange = self.Reload, arg1 = "SSPVP-EoTS", var = { "eots", "towersWin" }, parent = "SSEyeOfTheStorm" };
		{ text = L["Show bases to win score"], type = "check", OnChange = self.Reload, arg1 = "SSPVP-EoTS", var = { "eots", "towersScore" }, parent = "SSEyeOfTheStorm" };
		{ text = L["Show captures to win"], type = "check", OnChange = self.Reload, arg1 = "SSPVP-EoTS", var = { "eots", "captureWin" }, parent = "SSEyeOfTheStorm" };
		{ text = L["Show total flag captures for Alliance and Horde"], type = "check", OnChange = self.Reload, arg1 = "SSPVP-EoTS", var = { "eots", "totalCaptures" }, parent = "SSEyeOfTheStorm" };
		
		-- Auto turn in
		{ text = L["Enable auto turn in"], type = "check", var = { "turnin", "enabled" }, parent = "SSTurnIn" },
		
 	};
 	
 	-- Auto turn in types
 	for key, text in pairs( L["TURNTYPES"] ) do
		table.insert( UIList, { text = string.format( L["Disable %s"], text ), type = "check", var = { "turnin", key }, parent = "SSTurnIn" } );
	end
	
	-- Modules
	for name, module in SSPVP:IterateModules() do
		if( L[ name ] ) then
			table.insert( UIList, { text = string.format( L["Disable module %s"], L[ name ] ), type = "check", var = { "modules", name }, parent = "SSModules" } );
		end
	end

	for _, element in pairs( UIList ) do
		SSUI:RegisterElement( "sspvp", element );
	end
end

function SSPVP:LoadUI()
	UI:LoadUI();
end