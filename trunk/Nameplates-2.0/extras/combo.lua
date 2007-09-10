local CP = Nameplates:NewModule( "Nameplates-CP" );

function CP:EnableModule()
end

function CP:DisableModule()
	self:UnregisterAllEvents();
end