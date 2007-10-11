ArenaGuess = DongleStub("Dongle-1.1"):New("ArenaGuess")

local L = ArenaGuessLocals

function ArenaGuess:Enable()
	self.defaults = {
		profile = {
		}
	}
	
	self.db = self:InitializeDB("ArenaGuessDB", self.defaults)

	self.cmd = self:InitializeSlashCommand(L["Arena Guestimate slash commands"], "ArenaGuess", "arenaguess", "aguess", "ag")
	self.cmd:InjectDBCommands(self.db, "delete", "copy", "list", "set")
	self.cmd:RegisterSlashHandler(L["ui - Opens the OptionHouse UI"], "ui", function() OH:Open("Arena Guestimate") end)
	
	self:RegisterEvent("ADDON_LOADED")

	-- Register with OH
	local ui = OH:RegisterAddOn("Arnea Guestimate", L["Arena Guess"], "Amarand", "r" .. tonumber( string.match( "$Revision: 231 $", "(%d+)" ) or 1 ) )
	ui:RegisterCategory(L["General"], self, "CreateUI")
end

function ArenaGuess:CreateUI()

end
