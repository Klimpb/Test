local SE = LibStub:GetLibrary("SpecialEvents-Alpha0")
local EventTest = {}

function EventTest:Load()
	
end


local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnShow", function()
	EventTest.OnLoad(EventTest)
end)