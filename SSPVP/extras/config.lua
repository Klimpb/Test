local UI = SSPVP:NewModule("SSPVP-UI")

local L = SSPVPLocals
local OptionHouse
local HousingAuthority

function UI:Initialize()
	SSPVP.cmd:RegisterSlashHandler(L["on - Enables SSPVP"], "on", function()
		SSPVP:Enable()
		SSPVP:UPDATE_BATTLEFIELD_STATUS()
		SSPVP:Print(L["Is now enabled."])
	end)
	SSPVP.cmd:RegisterSlashHandler(L["off - Disables SSPVP"], "off", function()
		SSPVP:Disable()
		SSPVP:Print(L["Is now disabled."])
	end)	
	SSPVP.cmd:RegisterSlashHandler(L["ui - Pulls up the configuration page."], "ui", function()
		OptionHouse:Open("SSPVP")
	end)
	
	-- Toggle battlefield minimap
	SSPVP.cmd:RegisterSlashHandler(L["map - Toggles the battlefield minimap regardless of being inside a battleground."], "map", function()
		BattlefieldMinimap_LoadUI() 
		if( BattlefieldMinimap:IsVisible() ) then
			MiniMapBattlefieldFrame.status = ""
			BattlefieldMinimap:Hide()
		else
			MiniMapBattlefieldFrame.status = "active"
			BattlefieldMinimap:Show()
		end 
	end)
	
	OptionHouse = LibStub("OptionHouse-1.1")
	HousingAuthority = LibStub("HousingAuthority-1.2")
	
	local OHObj = OptionHouse:RegisterAddOn("SSPVP", nil, "Mayen", "r" .. SSPVP.revision)
	OHObj:RegisterCategory(L["General"], self, "General", nil, 1)
	OHObj:RegisterCategory(L["Battlefield"], self, "Battlefield", nil, 2)
	OHObj:RegisterCategory(L["Auto Join"], self, "AutoJoin", nil, 3)
	OHObj:RegisterCategory(L["Auto Leave"], self, "AutoLeave", nil, 4)
	OHObj:RegisterCategory(L["Overlay"], self, "Overlay", nil, 5)
	OHObj:RegisterCategory(L["Warsong Gulch"], self, "WarsongGulch", nil, 6)
	OHObj:RegisterCategory(L["Alterac Valley"], self, "AlteracValley", nil, 7)
	OHObj:RegisterCategory(L["Arathi Basin"], self, "ArathiBasin", nil, 8)
	OHObj:RegisterCategory(L["Eye of the Storm"], self, "EyeOfTheStorm", nil, 9)
	OHObj:RegisterSubCategory(L["Overlay"], L["Queue"], self, "QueueOverlay")
end

-- Toggle sspvp
function UI:ToggleSSPVP()
	if( SSPVP.db.profile.general.enabled ) then
		SSPVP:Enable()
	else
		SSPVP:Disable()
	end
end

-- Toggle things for sound
function UI:PlaySound()
	if( self.soundPlaying ) then
		self:SetText(L["Play"])

		SSPVP:StopSound()
		self.soundPlaying = nil
	else
		self:SetText(L["Stop"])

		SSPVP:PlaySound()
		self.soundPlaying = true
	end
end

-- Variable management
function UI:Set(vars, val)
	if( #( vars ) == 3 ) then
		SSPVP.db.profile[vars[1]][vars[2]][vars[3]] = val
	elseif( #( vars ) == 2 ) then
		SSPVP.db.profile[vars[1]][vars[2]] = val
	elseif( #( vars ) == 1 ) then
		SSPVP.db.profile[vars[1]] = val
	end
end

function UI:Get(vars)
	if( #(vars) == 3 ) then
		return SSPVP.db.profile[vars[1]][vars[2]][vars[3]]
	elseif( #(vars) == 2 ) then
		return SSPVP.db.profile[vars[1]][vars[2]]
	elseif( #(vars) == 1 ) then
		return SSPVP.db.profile[vars[1]]
	end
	
	return nil
end

-- Priority widget
local function updatePriorityList(frame)
	for id, row in pairs(frame.list) do
		if( row[1] <= 1 ) then
			getglobal(frame:GetName() .. "Row" .. id .. "Up"):Disable()
			getglobal(frame:GetName() .. "Row" .. id .. "Down"):Enable()

		elseif( row[1] >= #( frame.list ) ) then
			getglobal(frame:GetName() .. "Row" .. id .. "Down"):Disable()
			getglobal(frame:GetName() .. "Row" .. id .. "Up"):Enable()
		else
			getglobal(frame:GetName() .. "Row" .. id .. "Up"):Enable()
			getglobal(frame:GetName() .. "Row" .. id .. "Down"):Enable()
		end
		
		getglobal(frame:GetName() .. "Row" .. id .. "Text"):SetText(row[3])
		getglobal(frame:GetName() .. "Row" .. id .. "Priority"):SetText(row[1])
		getglobal(frame:GetName() .. "Row" .. id):Show()
	end
end

local function movePriorityUp(self)
	local frame = self:GetParent():GetParent()
	local text = getglobal(self:GetParent():GetName() .. "Text"):GetText()
	
	for id, row in pairs(frame.list) do
		if( row[3] == text ) then
			if( row[1] > 1 ) then
				frame.list[id][1] = row[1] - 1
				frame.vars[2] = row[2]
								
				UI:Set(frame.vars, frame.list[id][1])
				updatePriorityList(frame)
				return
			end
		end
	end
end

local function movePriorityDown(self)
	local frame = self:GetParent():GetParent()
	local text = getglobal(self:GetParent():GetName() .. "Text"):GetText()

	for id, row in pairs(frame.list) do
		if( row[3] == text ) then
			if( row[1] < #(frame.list) ) then
				frame.list[id][1] = row[1] + 1
				frame.vars[2] = row[2]
				
				UI:Set(frame.vars, frame.list[id][1])
				updatePriorityList(frame)
				return
			end
		end
	end
end

function UI:CreatePriority(parent, list, vars)
	local name = "SSPriorityWidget"
	
	table.sort(list, function(a, b)
		if( a[1] == b[1] ) then
			return ( a[3] > b[3] )
		end
		
		return ( a[1] < b[1] )
	end )

	local frame = CreateFrame("Frame", name, parent)
	frame:SetFrameStrata("MEDIUM")
	frame:SetWidth(250)
	frame:SetHeight(#(list) * 23)
	frame:EnableMouse(true)
	frame.list = list
	frame.vars = vars
	
	local row, text, priority, up, down
	for i=1, #(list) do
		row = CreateFrame("Frame", name .. "Row" .. i, frame)
		text = row:CreateFontString(row:GetName() .. "Text", "BACKGROUND", "GameFontNormalSmall" )
		priority = row:CreateFontString(row:GetName() .. "Priority", "BACKGROUND", "GameFontNormal")

		up = CreateFrame("Button", row:GetName() .. "Up", row, "UIPanelScrollUpButtonTemplate")
		down = CreateFrame("Button", row:GetName() .. "Down", row, "UIPanelScrollDownButtonTemplate")
		
		up:SetScript( "OnClick", movePriorityUp)
		down:SetScript( "OnClick", movePriorityDown)
		
		text:SetPoint("TOPLEFT", row, "TOPLEFT", 5, -5)
		priority:SetPoint("CENTER", up, "CENTER", 20, 0)

		up:SetPoint("TOPRIGHT", row, "TOPRIGHT", -60, -3)
		down:SetPoint("TOPRIGHT", up, "TOPRIGHT", 40, 0)

		row:SetHeight(20)
		row:SetWidth(250)
		
		if( i > 1 ) then
			row:SetPoint("TOPLEFT", getglobal(name .. "Row" .. i - 1), "TOPLEFT", 0, -25)
		else
			row:SetPoint("TOPLEFT", frame, "TOPLEFT", 5, -5)
		end
		
		row:Hide()
	end
	
	updatePriorityList(frame)
	
	return frame
end

function UI:Reload(vars)
	local module
	if( vars[1] == "mover" ) then
		module = "SSPVP-Mover"
	elseif( vars[1] == "general" and vars[2] == "factBalance" ) then
		module = "SSPVP-Score"
	elseif( vars[1] == "overlay" ) then
		module = "SSPVP-Overlay"
	elseif( vars[1] == "arena" ) then
		module = "SSPVP-Arena"
	elseif( vars[1] == "av" ) then
		module = "SSPVP-AV"
	elseif( vars[1] == "ab" ) then
		module = "SSPVP-AB"
	elseif( vars[1] == "wsg" ) then
		module = "SSPVP-WSG"
	elseif( vars[1] == "eots" ) then
		module = "SSPVP-EoTs"
	elseif( vars[1] == "queue" ) then
		SSPVP:Reload()
		return
	end
	
	module = SSPVP:HasModule(module)
	if( module and module.Reload ) then
		module.Reload(module)
	end
end

-- GENERAL
function UI:General()
	local config = {
		{ group = L["General"], type = "groupOrder", order = 1 },
		{ group = L["Auto Queue"], type = "groupOrder", order = 2 },
		{ group = L["Reformat"], type = "groupOrder", order = 3 },
		{ group = L["Arena"], type = "groupOrder", order = 4 },
		{ group = L["Frame Mover"], type = "groupOrder", order = 5 },
		
		{ order = 1, group = L["General"], text = L["Enable SSPVP"], func = UI.ToggleSSPVP, type = "check", var = {"general", "enabled"}},
		{ order = 2, group = L["General"], text = L["Block all messages starting with [SS]"], type = "check", var = {"general", "block"}},
		{ order = 3, group = L["General"], text = L["Default Channel"], type = "dropdown", list = {{"BATTLEGROUND", L["Battleground"]}, {"RAID", L["Raid"]}, {"PARTY", L["Party"]}},  var = {"general", "channel"}},
		{ order = 4, group = L["General"], text = L["Enable faction balance overlay"], type = "check", onSet = "Reload", var = {"general", "factBalance"}},
		{ order = 5, group = L["General"], text = L["Sound file"], type = "input", width = 150, var = {"general", "sound"}},
		{ order = 6, group = L["General"], text = L["Play"], type = "button",  onSet = "PlaySound"},
 		
 		{ order = 1, group = L["Auto Queue"], text = L["Auto solo queue when ungrouped"], type = "check", var = {"queue", "autoSolo"}},
		{ order = 2, group = L["Auto Queue"], text = L["Auto group queue when leader"], type = "check", var = {"queue", "autoGroup"}},
		
		{ order = 1, group = L["Reformat"], text = L["Append server name when sending whispers in battlefields"], type = "check", var = {"reformat", "autoAppend"}},
		{ order = 2, group = L["Reformat"], text = L["Block raid join/leave spam in battlegrounds"], type = "check", var = {"reformat", "blockSpam"}},
		
 		{ order = 1, group = L["Arena"], text = L["Show team name/rating in chat after game ends"], type = "check", var = {"arena", "teamInfo"}},
		{ order = 2, group = L["Arena"], text = L["Enable modified player/inspect pvp screens"], type = "check", var = {"arena", "modify"}},
	
 		{ order = 1, group = L["Frame Mover"], text = L["Lock world PvP objectives"], type = "check",  onSet = "Reload", var = {"mover", "world"}},
		{ order = 2, group = L["Frame Mover"], text = L["Lock battlefield scoreboard"], type = "check", onSet = "Reload", var = {"mover", "score"}},
		{ order = 3, group = L["Frame Mover"], text = L["Lock capture bars"], type = "check", onSet = "Reload", var = {"mover", "capture"}},
	}
	
	return HousingAuthority:CreateConfiguration(config, {set = "Set", get = "Get", handler = UI})
end

-- AUTO JOIN
function UI:AutoJoin()
	local frame = CreateFrame("Frame", nil, OptionHouse:GetFrame("addon"))
	
	-- Config -> priority format
	local priorityList = {}
	for key, num in pairs(SSPVP.db.profile.priority) do
		table.insert(priorityList, {num, key, L[key]})
	end
	
	local config = {
		{ group = L["General"], type = "groupOrder", order = 1 },
		{ group = L["Delay"], type = "groupOrder", order = 2 },
		{ group = L["Battlefield auto joining priorities"], type = "groupOrder", order = 3 },
		
		{ order = 1, group = L["General"], text = L["Enable auto join"], type = "check", var = {"join", "enabled"}},
		{ order = 2, group = L["General"], text = L["Priority check mode"], type = "dropdown", list = {{"less", L["Less than"]}, {"lseql", L["Less than/equal"]}},  var = {"join", "type"}},
		
		{ order = 1, group = L["Delay"], text = L["Battleground join delay"], type = "input", numeric = true, width = 30, var = {"join", "bgDelay"}},
		{ order = 2, group = L["Delay"], text = L["AFK battleground join delay"], type = "input", numeric = true, width = 30, var = {"join", "bgAfk"}},
		{ order = 3, group = L["Delay"], text = L["Arena join delay"], type = "input", numeric = true, width = 30, var = {"join", "arenaDelay"}},
		
		{ group = L["Battlefield auto joining priorities"], type = "inject", widget = UI:CreatePriority(frame, priorityList, {"priority"}), yPos = 0, xPos = 0 }
	}
	
	return HousingAuthority:CreateConfiguration(config, {frame = frame, set = "Set", get = "Get", handler = UI})
end

-- AUTO LEAVE
function UI:AutoLeave()
	local config = {
 		{ group = L["General"], type = "groupOrder", order = 1 },
		{ group = L["Delay"], type = "groupOrder", order = 2 },
		{ group = L["Confirmation"], type = "groupOrder", order = 3 },
		
		{ order = 1, group = L["General"], text = L["Enable auto leave"], type = "check", var = {"leave", "enabled"}},
 		{ order = 2, group = L["General"], text = L["Take score screenshot on game end"], type = "check", var = {"leave", "screen"}},
		
 		{ order = 1, group = L["Delay"], text = L["Battleground leave delay"], type = "input", numeric = true, width = 30, var = {"leave", "bgDelay"}},
 		{ order = 2, group = L["Delay"], text = L["Arena leave delay"], type = "input", numeric = true, width = 30, var = {"leave", "arenaDelay"}},

		{ order = 1, group = L["Confirmation"], text = L["Enable confirmation when leaving a battlefield queue"], type = "check", var = {"leave", "queueConfirm"}},
 		{ order = 2, group = L["Confirmation"], text = L["Enable confirmation when leaving a finished battlefield"], type = "check", var = {"leave", "doneConfirm"}},
	}
	
	return HousingAuthority:CreateConfiguration(config, {set = "Set", get = "Get", handler = UI})
end

-- BATTLEFIELD
function UI:Battlefield()
	local config = {
 		{ group = L["General"], type = "groupOrder", order = 1 },
		{ group = L["Scores"], type = "groupOrder", order = 2 },
		{ group = L["Death"], type = "groupOrder", order = 3 },

 		{ order = 1, group = L["General"], text = L["Auto open minimap when inside a battleground"], type = "check", var = {"bf", "minimap"}},
 		
 		{ order = 1, group = L["Scores"], text = L["Color names by class on score board"], type = "check", var = {"score", "color"}},
 		{ order = 2, group = L["Scores"], text = L["Hide class icon next to names on score board"], type = "check", var = {"score", "icon"}},
 		{ order = 3, group = L["Scores"], text = L["Show player levels next to names on score board"], type = "check", var = {"score", "level"}},
		
		{ order = 1, group = L["Death"], text = L["Auto release when inside an active battlefield"], type = "check", var = {"bf", "release"}},
 		{ order = 2, group = L["Death"], text = L["Auto release even with a soulstone active"], type = "check", var = {"bf", "releaseSS"}},
 		{ order = 3, group = L["Death"], text = L["Auto accept corpse ressurects inside a battlefield"], type = "check", var = {"bf", "autoAccept"}},
 	}

	return HousingAuthority:CreateConfiguration(config, {set = "Set", get = "Get", handler = UI})
end

-- OVERLAY
function UI:Overlay()
	local config = {
		{ group = L["Frame"], type = "groupOrder", order = 1 },
		{ group = L["Padding"], type = "groupOrder", order = 2 },
		{ group = L["Color"], type = "groupOrder", order = 3 },
		{ group = L["Display"], type = "groupOrder", order = 4 },

		{ order = 1, group = L["Frame"], text = L["Lock overlay"], type = "check", var = {"overlay", "locked"}},
		{ order = 2, group = L["Frame"], format = L["Background opacity: %d%%"], type = "slider", var = {"overlay", "opacity"}},
		{ order = 3, group = L["Frame"], format = L["Text opacity: %d%%"], type = "slider", var = {"overlay", "textOpacity"}},
		{ order = 4, group = L["Frame"], format = L["Overlay frame scale: %d%%"], min = 0.0, max = 2.0, type = "slider", var = {"overlay", "scale"}},

		{ order = 1, group = L["Padding"], text = L["Row padding"], type = "input", numeric = true, width = 30, var = {"overlay", "rowPad"}},
		{ order = 2, group = L["Padding"], text = L["Category padding"], type = "input", numeric = true, width = 30, var = {"overlay", "catPad"}},
		
		{ order = 1, group = L["Color"], text = L["Background color"], type = "color", var = {"overlay", "background"}},
		{ order = 2, group = L["Color"], text = L["Border color"], type = "color", var = {"overlay", "border"}},
		{ order = 3, group = L["Color"], text = L["Text color"], type = "color", var = {"overlay", "textColor"}},
		{ order = 4, group = L["Color"], text = L["Category text color"], type = "color", var = {"overlay", "categoryColor"}},
	
		{ order = 1, group = L["Display"], text = L["Display mode"], type = "dropdown", list = {{"down", L["Top -> Bottom"]}, {"up", L["Bottom -> Top"]}},  var = {"overlay", "displayType"}},
		{ order = 2, group = L["Display"], text = L["Timer format"], type = "dropdown", list = {{"hhmmss", L["hh:mm:ss"]}, {"minsec", L["Min X, Sec X"]}, {"min", L["Min X"]}},  var = {"overlay", "timer"}},
		{ order = 3, group = L["Display"], text = L["Category text type"], type = "dropdown", list = {{"hide", L["Always hide"]}, {"show", L["Always show"]}, {"auto", L["Auto hiding"]}},  var = {"overlay", "catType"}},
	}
	
	return HousingAuthority:CreateConfiguration(config, {onSet = "Reload", set = "Set", get = "Get", handler = UI})
end

-- QUEUE OVERLAY
function UI:QueueOverlay()
	local config = {
		{ order = 1, group = L["General"], text = L["Enable queue overlay"], type = "check", var = {"queue", "enabled"}},
		{ order = 2, group = L["General"], text = L["Show queue overlay inside battlegrounds"], type = "check", var = {"queue", "insideField"}},
		{ order = 3, group = L["General"], text = L["Show estimated time until queue is ready"], type = "check", var = {"queue", "showEta"}},
		{ order = 4, group = L["General"], text = L["Estimated time format"], type = "dropdown", list = {{"hhmmss", L["hh:mm:ss"]}, {"minsec", L["Min X, Sec X"]}, {"min", L["Min X"]}},  var = {"queue", "etaFormat"}},
	}

	return HousingAuthority:CreateConfiguration(config, {set = "Set", get = "Get", onSet = "Reload", handler = UI})
end

-- ALTERAC VALLEY
function UI:AlteracValley()
	local config = {
		{ group = L["General"], type = "groupOrder", order = 1 },
		{ group = L["Alerts"], type = "groupOrder", order = 2 },
		{ group = L["Item Tracking"], type = "groupOrder", order = 3 },
		
		{ order = 1, group = L["General"], text = string.format(L["Disable %s module"], L["Alterac Valley"]), type = "check", var = {"modules", "SSPVP-AV"}},

		{ order = 1, group = L["Alerts"], text = L["Enable capture timers"], type = "check", var = {"av", "timers"}},
		{ order = 2, group = L["Alerts"], text = L["Enable interval capture messages"], type = "check", var = {"av", "enabled"}},
		{ order = 3, group = L["Alerts"], text = L["Interval in seconds between messages"], type = "input", numeric = true, width = 30, var = {"av", "interval"}},
		{ order = 4, group = L["Alerts"], text = L["Interval frequency increase"], type = "dropdown", list = {{0, L["None"]}, {0.75, L["25%"]}, {0.50, L["50%"]}, {0.25, L["75%"]}},  var = {"av", "speed"}},

		{ order = 1, group = L["Item Tracking"], text = L["Enable armor scraps tracking"], type = "check", var = {"av", "armor"}},
		{ order = 2, group = L["Item Tracking"], text = L["Enable flesh/medal tracking"], type = "check", var = {"av", "medal"}},
		{ order = 3, group = L["Item Tracking"], text = L["Enable blood/crystal tracking"], type = "check", var = {"av", "crystal"}},
	}

	return HousingAuthority:CreateConfiguration(config, {set = "Set", get = "Get", onSet = "Reload", handler = UI})
end

-- ARATHI BASIN
function UI:ArathiBasin()
	local config = {
		{ group = L["General"], type = "groupOrder", order = 1 },
		{ group = L["Alerts"], type = "groupOrder", order = 2 },
		{ group = L["Match Info"], type = "groupOrder", order = 3 },

		{ order = 1, group = L["General"], text = string.format(L["Disable %s module"], L["Arathi Basin"]), type = "check", var = {"modules", "SSPVP-AB"}},

		{ order = 1, group = L["Alerts"], text = L["Enable capture timers"], type = "check", var = {"ab", "timers"}},

		{ order = 1, group = L["Match Info"], text = L["Enable estimated final score overlay"], type = "check", var = {"ab", "overlay"}},
		{ order = 2, group = L["Match Info"], text = L["Estimated final score"], type = "check", var = {"ab", "finalScore"}},
		{ order = 3, group = L["Match Info"], text = L["Estimated time left in the battlefield"], type = "check", var = {"ab", "timeLeft"}},
		{ order = 4, group = L["Match Info"], text = L["Show bases to win"], type = "check", var = {"ab", "basesWin"}},
		{ order = 5, group = L["Match Info"], text = L["Show bases to win score"], type = "check", var = {"ab", "basesScore"}},
	}

	return HousingAuthority:CreateConfiguration(config, {set = "Set", get = "Get", onSet = "Reload", handler = UI})
end

-- WARSONG GULCH
function UI:WarsongGulch()
	local config = {
		{ group = L["General"], type = "groupOrder", order = 1 },
		{ group = L["Carrier Info"], type = "groupOrder", order = 2 },
		{ group = L["Overlay"], type = "groupOrder", order = 3 },

		{ order = 1, group = L["General"], text = string.format(L["Disable %s module"], L["Warsong Gulch"]), type = "check", var = {"modules", "SSPVP-WSG"}},

		{ order = 1, group = L["Carrier Info"], text = L["Enable carrier names"], type = "check", var = {"wsg", "carriers"}},
		{ order = 2, group = L["Carrier Info"], text = L["Show border around carrier names"], type = "check", var = {"wsg", "border"}},
		{ order = 3, group = L["Carrier Info"], text = L["Show carrier health when available"], type = "check", var = {"wsg", "health"}},
		
		{ order = 1, group = L["Overlay"], text = L["Time until flag respawns"], type = "check", var = {"wsg", "respawn"}},
		{ order = 2, group = L["Overlay"], text = L["Show time elapsed since flag was picked up"], type = "check", var = {"wsg", "flagElapsed"}},
		{ order = 3, group = L["Overlay"], text = L["Show time taken before the flag was captured"], type = "check", var = {"wsg", "flagCapTime"}},
	}

	return HousingAuthority:CreateConfiguration(config, {set = "Set", get = "Get", onSet = "Reload", handler = UI})
end

-- EYE OF THE STORM
function UI:EyeOfTheStorm()
	local config = {
		{ group = L["General"], type = "groupOrder", order = 1 },
		{ group = L["Carrier Info"], type = "groupOrder", order = 2 },
		{ group = L["Match Info"], type = "groupOrder", order = 3 },

		{ order = 1, group = L["General"], text = string.format(L["Disable %s module"], L["Eye of the Storm"]), type = "check", var = {"modules", "SSPVP-EoTS"}},
		
		{ order = 1, group = L["Carrier Info"], text = L["Enable carrier names"], type = "check", var = {"eots", "carriers"}},
		{ order = 2, group = L["Carrier Info"], text = L["Show border around carrier names"], type = "check", var = {"eots", "border"}},
		
		{ order = 1, group = L["Match Info"], text = L["Enable overlay"], type = "check", var = {"eots", "overlay"}},
		{ order = 2, group = L["Match Info"], text = L["Time until flag respawns"], type = "check",func = self.Reload, arg1 = "SSPVP-EoTS", var = {"eots", "respawn"}},
		{ order = 3, group = L["Match Info"], text = L["Estimated time left in the battlefield"], type = "check", var = {"eots", "timeLeft"}},
		{ order = 4, group = L["Match Info"], text = L["Estimated final score"], type = "check", var = {"eots", "finalScore"}},
		{ order = 5, group = L["Match Info"], text = L["Show bases to win"], type = "check", var = {"eots", "towersWin"}},
		{ order = 6, group = L["Match Info"], text = L["Show bases to win score"], type = "check", var = {"eots", "towersScore"}},
		{ order = 7, group = L["Match Info"], text = L["Show total flag captures for Alliance and Horde"], type = "check", var = {"eots", "totalCaptures"}},
	}

	return HousingAuthority:CreateConfiguration(config, {set = "Set", get = "Get", onSet = "Reload", handler = UI})
end