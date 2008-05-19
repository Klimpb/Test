--[[ 
	Nameplates, Mayen/Amarand (Horde) from Icecrown (US) PvE
]]


Nameplates = LibStub("AceAddon-3.0"):NewAddon("Nameplates", "AceEvent-3.0", "AceHook-3.0")

local frames = {}
local queuedFrames = {}
local backdropCache = {}
local SML

function Nameplates:OnInitialize()
	self.defaults = {
		profile = {
			healthType = "percent",
			castType = "crtmax",
			bindings = true,

			-- Status Bars
			health = {
				uiobject = { hide = false, width = 0, height = 0, alpha = 1.0, x = 4, y = 4 },
				frame = {
					backdropEnabled = false, bgName = "", edgeName = "", edgeSize = 0,
					bgColor = { r = 1.0, g = 1.0, b = 1.0, a = 1.0 },
					borderColor = { r = 1.0, g = 1.0, b = 1.0, a = 1.0 },
					insets = { left = 1, right = 1, top = 1, bottom = 1 },
				},
				texture = { name = "Nameplates Default" }
			},

			cast = {
				uiobject = { hide = false, width = 0, height = 0, alpha = 1.0, x = 0, y = 0 },
				frame = {
					backdropEnabled = false, bgName = "", edgeName = "", edgeSize = 0,
					bgColor = { r = 1.0, g = 1.0, b = 1.0, a = 1.0 },
					borderColor = { r = 1.0, g = 1.0, b = 1.0, a = 1.0 },
					insets = { left = 1, right = 1, top = 1, bottom = 1 },
				},
				texture = { name = "Nameplates Default" }
			},

			-- Misc stuff we want to hide mostly
			healthBorder = {
				uiobject = { hide = false },
			},

			castBorder = {
				uiobject = { hide = false },
			},

			highlightTexture = {
				uiobject = { hide = false},
			},
			
			-- Font Strings
			name = { 
				uiobject = { hide = false, width = 0, height = 0, alpha = 1.0, x = 0, y = 0 },
				font = { name = "Friz Quadrata TT", size = 12, border = "", justifyH = "LEFT", shadowColor = { r = 0, g = 0, b = 0, a = 1.0 }, offset = { x = 0, y = 0 },  },
			},
			level = {
				uiobject = { hide = false, width = 0, height = 0, alpha = 1.0, x = -12, y = 9 },
				font = { name = "Friz Quadrata TT", size = 11, border = "", justifyH = "LEFT", shadowColor = { r = 0, g = 0, b = 0, a = 1.0 }, offset = { x = 0, y = 0 }, },
			},
			healthText = {
				uiobject = { hide = false, width = 0, height = 0, alpha = 1.0, x = 5, y = 0 },
				font = { name = "Friz Quadrata TT", size = 8, border = "OUTLINE", shadowColor = { r = 0, g = 0, b = 0, a = 1.0 }, offset = { x = 0, y = 0 }, },
			},
			castText = {
				uiobject = { hide = false, width = 0, height = 0, alpha = 1.0, x = 0, y = 0 },
				font = { name = "Friz Quadrata TT", size = 8, border = "OUTLINE", shadowColor = { r = 0, g = 0, b = 0, a = 1.0 }, offset = { x = 0, y = 0 }, },
			},
		},
	}

	self.db = LibStub:GetLibrary("AceDB-3.0"):New("NameplatesDB", self.defaults)
	self.revision = tonumber(string.match("$Revision: 692 $", "(%d+)") or 1)
	SML = LibStub:GetLibrary("LibSharedMedia-3.0")
end

-- Frame configuration
function Nameplates:SetFSConfig(text, type)
	local config = self.db.profile[type].font	

	text:SetFont(SML:Fetch(SML.MediaType.FONT, config.name), config.size, config.border)
	if( config.shadowEnabled ) then
		if( not text.NPOriginalShadow ) then
			local x, y = text:GetShadowOffset()
			local r, g, b, a = text:GetShadowColor()
			
			text.NPOriginalShadow = { r = r, g = g, b = b, a = a, y = y, x = x }
		end
		
		text:SetShadowColor(config.shadowColor.r, config.shadowColor.g, config.shadowColor.b, config.shadowColor.a)
		text:SetShadowOffset(config.offset.x, config.offset.y)
		
	-- Restore original
	elseif( text.NPOriginalShadow ) then
		text:SetShadowColor(text.NPOriginalShadow.r, text.NPOriginalShadow.g, text.NPOriginalShadow.b, text.NPOriginalShadow.a)
		text:SetShadowOffset(text.NPOriginalShadow.x, text.NPOriginalShadow.y)
		text.NPOriginalShadow = nil
	end
	
	-- Text positioning
	if( text.justifyH ) then
		text:SetJustifyH(text.justifyH)
	end
end

function Nameplates:SetSBConfig(bar, type)
	bar:SetStatusBarTexture(SML:Fetch(SML.MediaType.STATUSBAR, self.db.profile[type].texture.name))
end

function Nameplates:HideTexture(texture, type)
	local config = self.db.profile[type].uiobject
	

	if( not texture.NPWidth and not texture.NPHeight ) then
		texture.NPWidth = texture:GetWidth()
		texture.NPHeight = texture:GetHeight()
		texture.NPTexture = texture:GetTexture()
	end
	
	if( config.hide ) then
		texture:SetHeight(0)
		texture:SetWidth(0)
		texture:SetTexture(0, 0, 0, 0)
		texture:Hide()
	elseif( texture.NPHeight and texture.NPWidth ) then
		texture:SetHeight(texture.NPHeight)
		texture:SetWidth(texture.NPWidth)
		texture:SetTexture(texture.NPTexture)
	end
end

-- font.enabled
-- uiobject.positionEnabled


function Nameplates:SetUIObjConfig(frame, type)
	local config = self.db.profile[type].uiobject
	
	-- Keep an object hidden
	if( config.hide ) then
		frame.NPHide = config.hide
		frame:Hide()
	elseif( frame.NPHide ) then
		frame.NPHide = nil

		frame:Show()
	end
	
	-- Width/height
	-- For restoring
	if( not frame.NPWidth ) then
		frame.NPWidth = frame:GetWidth()
	end
	
	if( not frame.NPHeight ) then
		frame.NPHeight = frame:GetHeight()
	end

	if( config.width > 0 ) then
		frame:SetWidth(config.width)
	elseif( frame.NPWidth ) then
		frame:SetWidth(frame.NPWidth)
		frame.NPWidth = nil
	end
	
	if( config.height > 0 ) then
		frame:SetHeight(config.height)
	elseif( frame.NPHeight ) then
		frame:SetHeight(frame.NPHeight)
		frame.NPHeight = nil
	end
		
	-- Update the backdrop size if we have one
	if( frame.backdropFrame ) then
		--frame.backdropFrame:SetHeight(frame:GetHeight() + 2)
		--frame.backdropFrame:SetWidth(frame:GetWidth() + 2)
	end
		
	-- Alpha
	frame:SetAlpha(config.alpha)
	
	if( config.positionEnabled ) then
		-- Position
		local point, parent, relativePoint, x, y = frame:GetPoint()
		if( not frame.NPOringalPoint ) then

			frame.NPOringinalPoint = point
			frame.NPOriginalParent = parent
			frame.NPOriginalRelative = relativePoint
			frame.NPOriginalX = x
			frame.NPOriginalY = y
		end
		
		-- Custom to make it a bit easier to position things

		if( type == "name" or type == "level" ) then

			point = "TOPLEFT"
			relativePoint = "TOPLEFT"
		end


		frame:ClearAllPoints()
		frame:SetPoint(point, parent, relativePoint, config.x or x, config.y or y)
		

	elseif( frame.NPOriginalPoint ) then
		frame:ClearAllPoints()
		frame:SetPoint(frame.NPOriginalPoint, frame.NPOriginalParent, frame.NPOriginalRelative, frame.NPOriginalX, frame.NPOriginalY)
		frame.NPOriginalPoint = nil
	end
end

function Nameplates:SetFrameConfig(frame, type)
	local config = self.db.profile[type].frame
	if( not config.backdropEnabled ) then
		if( frame.backdropFrame ) then
			frame.backdropFrame:Hide()
		end
		return
	end
	
	-- Store backdrops with the same config once so we don't have to keep creating tables and fetch textures
	local id = string.format("%s:%s:%s:%s:%s:%s:%s", config.bgName, config.edgeName, config.edgeSize, config.insets.left, config.insets.right, config.insets.top, config.insets.bottom)
	if( not backdropCache[id] ) then
		backdropCache[id] = {
			tile = false,
			bgFile = SML:Fetch(SML.MediaType.BACKGROUND, config.bgName),
			edgeFile = SML:Fetch(SML.MediaType.BORDER, config.edgeName),
			edgeSize = config.edgeSize,
			insets = {left = config.insets.left, right = config.insets.right, top = config.insets.top, bottom = config.insets.bottom},
		}
	end
	
	-- Status bars apparently don't get backdrops, so create a frame we can stick one onto
	if( not frame.backdropFrame ) then
		frame.backdropFrame = CreateFrame("Frame", nil, frame)
		frame.backdropFrame:SetHeight(frame:GetHeight())
		frame.backdropFrame:SetWidth(frame:GetWidth())
		--frame.backdropFrame:SetPoint("RIGHT", frame, "RIGHT", 1, 0)
		--frame.backdropFrame:SetPoint("LEFT", frame, "LEFT", -1, -1)
		--frame.backdropFrame:SetPoint("CENTER", frame, "CENTER")
		frame.backdropFrame:SetFrameLevel(0)
	end
	
	frame.backdropFrame:SetBackdrop(backdropCache[id])
	frame.backdropFrame:SetBackdropColor(config.bgColor.r, config.bgColor.g, config.bgColor.b, config.bgColor.a)
	frame.backdropFrame:SetBackdropBorderColor(config.borderColor.r, config.borderColor.g, config.borderColor.b, config.borderColor.a)
	frame.backdropFrame:GetRegions():SetDrawLayer("BORDER")
	frame.backdropFrame:Show()
end

-- Health
function Nameplates:HealthOnShow(frame)
	local parent = frame:GetParent()
	local healthBorder, castBorder, spellIcon, highlightTexture, nameText, levelText, bossIcon, raidIcon = parent:GetRegions()
	
	Nameplates:SetSBConfig(frame, "health")
	Nameplates:SetUIObjConfig(frame, "health")
	Nameplates:SetFrameConfig(frame, "health")

	Nameplates:SetUIObjConfig(frame.NPText, "healthText")
	Nameplates:SetFSConfig(frame.NPText, "healthText")

	Nameplates:SetUIObjConfig(nameText, "name")
	Nameplates:SetFSConfig(nameText, "name")

	Nameplates:SetFSConfig(levelText, "level")
	Nameplates:SetUIObjConfig(levelText, "level")
	Nameplates:SetUIObjConfig(bossIcon, "level")
	
	Nameplates:HideTexture(highlightTexture, "highlightTexture")
	Nameplates:HideTexture(healthBorder, "healthBorder")	

	-- Keep the frame clickable even if the health is changed
	if( Nameplates.db.profile.health.uiobject.height > 0 ) then
		local height = frame:GetHeight() + 5
		if( InCombatLockdown() and parent:GetHeight() ~= height ) then
			queuedFrames[frame] = true
		else	
			parent:SetHeight(height)
		end
	end

	if( Nameplates.db.profile.health.uiobject.width > 0 ) then
		local width = frame:GetWidth() + 5
		if( InCombatLockdown() and parent:GetWidth() ~= width ) then
			queuedFrames[frame] = true
		else	
			parent:SetWidth(width)
		end
	end

	-- Flagged to be kept hidden
	if( frame.NPHide ) then
		frame:Hide()
	end
end

function Nameplates:HealthOnValueChanged(frame, value)
	local _, maxValue = frame:GetMinMaxValues()
	
	if( self.db.profile.healthType == "minmax" ) then
		if( maxValue == 100 ) then
			frame.NPText:SetFormattedText("%d%% / %d%%", value, maxValue)	
		else
			frame.NPText:SetFormattedText("%d / %d", value, maxValue)	
		end
	elseif( self.db.profile.healthType == "deff" ) then
		value = maxValue - value
		if( value > 0 ) then
			if( maxValue == 100 ) then
				frame.NPText:SetFormattedText("-%d%%", value)
			else

				frame.NPText:SetFormattedText("-%d", value)
			end
		else

			frame.NPText:SetText("")
		end
	elseif( self.db.profile.healthType == "percent" ) then
		frame.NPText:SetFormattedText("%d%%", value / maxValue * 100)
	else
		frame.NPText:SetText("")
	end
end

-- Cast
function Nameplates:CastOnShow(frame)
	local healthBorder, castBorder, spellIcon, highlightTexture, nameText, levelText, bossIcon, raidIcon = frame:GetParent():GetRegions()
	
	Nameplates:SetSBConfig(frame, "cast")
	--Nameplates:SetUIObjConfig(frame, "cast")
	Nameplates:SetFrameConfig(frame, "cast")

	Nameplates:SetFSConfig(frame.NPText, "castText")
	Nameplates:SetUIObjConfig(frame.NPText, "castText")

	--Nameplates:HideTexture(castBorder, "castBorder")
end

function Nameplates:CastOnValueChanged(frame, value)
	local minValue, maxValue = frame:GetMinMaxValues()
	
	if( value >= maxValue or value == 0 ) then
		frame.NPText:SetText("")
		return
	end
	
	-- Quick hack stolen from old NP, I need to fix this up
	maxValue = maxValue - value + ( value - minValue )
	value = math.floor(((value - minValue) * 100) + 0.5) / 100
	
	if( self.db.profile.castType == "crtmax" ) then
		frame.NPText:SetFormattedText("%.2f / %.2f", value, maxValue)
	elseif( self.db.profile.castType == "crt" ) then
		frame.NPText:SetFormattedText("%.2f", value)
	elseif( self.db.profile.castType == "percent" ) then
		frame.NPText:SetFormattedText("%d%%", value / maxValue)
	elseif( self.db.profile.castType == "timeleft" ) then
		frame.NPText:SetFormattedText("%.2f", maxValue - value)
	else
		frame.NPText:SetText("")
	end

end

function Nameplates:CreateText(frame)
	frame.NPText = frame:CreateFontString(nil, "ARTWORK")
	frame.NPText:SetPoint("CENTER", frame, "CENTER", 5, 0)
	frame.NPText:SetHeight(15)
	frame.NPText:SetWidth(100)
end

-- REGIONS
-- 1 = Health bar/level border
-- 2 = Border for the casting bar
-- 3 = Spell icon for the casting bar
-- 4 = Glow around the health bar when hovering over
-- 5 = Name text
-- 6 = Level text
-- 7 = Skull icon if the mob/player is 10 or more levels higher then you
-- 8 = Raid icon when you're close enough to the mob/player to see the name plate
local function hookFrames(...)
	local self = Nameplates
	for i=1, select("#", ...) do
		local frame = select(i, ...)
		local region = frame:GetRegions()
		if( not frames[frame] and not frame:GetName() and region and region:GetObjectType() == "Texture" and region:GetTexture() == "Interface\\Tooltips\\Nameplate-Border" ) then
			frames[frame] = true

			local healthBorder, castBorder, spellIcon, highlightTexture, nameText, levelText, bossIcon, raidIcon = frame:GetRegions()
			local health, cast = frame:GetChildren()
			
			self:CreateText(health)
			self:HookScript(health, "OnValueChanged", "HealthOnValueChanged")
			self:HookScript(health, "OnShow", "HealthOnShow")
			
			self:HealthOnShow(health)
			self:HealthOnValueChanged(health, health:GetValue())

			self:CreateText(cast)
			self:HookScript(cast, "OnValueChanged", "CastOnValueChanged")
			self:HookScript(cast, "OnShow", "CastOnShow")
			
			self:CastOnShow(cast)
			self:CastOnValueChanged(cast, cast:GetValue())
		end
	end
end

local numChildren = -1
local frame = CreateFrame("Frame")
frame:SetScript("OnUpdate", function(self, elapsed)
	if( WorldFrame:GetNumChildren() ~= numChildren ) then
		numChildren = WorldFrame:GetNumChildren()
		hookFrames(WorldFrame:GetChildren())
	end
end)

function Nameplates:Reload()
	for frame in pairs(frames) do
		local health, cast = frame:GetChildren()

		self:HealthOnShow(health)
		self:HealthOnValueChanged(health, health:GetValue())

		self:CastOnShow(cast)
		self:CastOnValueChanged(cast, cast:GetValue())
	end
end

function Nameplates:Print(msg)
	DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99Nameplates|r: " .. msg)
end