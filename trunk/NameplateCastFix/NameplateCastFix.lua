local function OnUpdate(self, ...)
	if( self.NCF_OnUpdate ) then
		self.NCF_OnUpdate(self, ...)
	end
	
	local time = GetTime()
	if( select(2, self:GetMinMaxValues()) <= time ) then
		self.border:Hide()
		self.icon:Hide()
		self:Hide()
	else
		self:SetValue(time)
	end
end

local function findUnhookedFrames(...)
	for i=1, select("#", ...) do
		local bar = select(i, ...)
		if( bar and not bar.NPCFHooked and not bar:GetName() and bar:IsVisible() and bar.GetFrameType and bar:GetFrameType() == "StatusBar" ) then
			return bar
		end
	end
end

local function hookFrames(...)
	for i=1, select("#", ...) do
		local bar = findUnhookedFrames(select(i, ...):GetChildren())
		if( bar ) then
			bar.NPCFHooked = true
			
			local parent = bar:GetParent()
			local cast = select(2, parent:GetChildren())
			local border, icon = select(2, parent:GetRegions())
			
			cast.border = border
			cast.icon = icon
			cast.NCF_OnUpdate = cast:GetScript("OnUpdate")
			cast:SetScript("OnUpdate", OnUpdate)
		end
	end
end

local numChildren = -1
local frame = CreateFrame("Frame")
frame:SetScript("OnUpdate", function()
	if( WorldFrame:GetNumChildren() ~= numChildren ) then
		numChildren = WorldFrame:GetNumChildren()
		hookFrames(WorldFrame:GetChildren())
	end	
end)