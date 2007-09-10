local Binding = Nameplates:NewModule( "Nameplates-Binding" );
local L = NameplatesLocals;

function Binding:EnableModule()
	if( not self.enemyBinding ) then
		self.enemyBinding = CreateFrame( "Button", "NPEnemyBinding" );
		self.enemyBinding:SetScript( "OnMouseDown", self.EnemyBindings );
	end
	
	if( not self.friendlyBinding ) then
		self.friendlyBinding = CreateFrame( "Button", "NPFriendlyBinding" );
		self.friendlyBinding:SetScript( "OnMouseDown", self.FriendlyBindings );
	end
	
	if( not self.allBinding ) then
		self.allBinding = CreateFrame( "Button", "NPAllBinding" );
		self.allBinding:SetScript( "OnMouseDown", self.AllBindings );
	end
	
	self:RegisterEvent( "UPDATE_BINDINGS" );
	self:UPDATE_BINDINGS();
end

function Binding:DisableModule()
	self:UnregisterAllEvents();

	ClearOverrideBindings( self.allBinding );
	ClearOverrideBindings( self.enemyBinding );
	ClearOverrideBindings( self.friendlyBinding );
end

-- Update our override bindings
function Binding:UPDATE_BINDINGS()
	if( GetBindingKey( "NAMEPLATES" ) ) then
		SetOverrideBindingClick( self.enemyBinding, false, GetBindingKey( "NAMEPLATES" ), self.enemyBinding:GetName() );
	else
		ClearOverrideBindings( self.enemyBinding );
	end
	
	if( GetBindingKey( "FRIENDNAMEPLATES" ) ) then
		SetOverrideBindingClick( self.friendlyBinding, false, GetBindingKey( "FRIENDNAMEPLATES" ), self.friendlyBinding:GetName() );
	else
		ClearOverrideBindings( self.friendlyBinding );
	end
	
	if( GetBindingKey( "ALLNAMEPLATES" ) ) then
		SetOverrideBindingClick( self.allBinding, false, GetBindingKey( "ALLNAMEPLATES" ), self.allBinding:GetName() );
	else
		ClearOverrideBindings( self.allBinding );
	end
end

-- Toggle Messages
function Binding:EnemyBindings()
	RunBinding( "NAMEPLATES" );

	if( NAMEPLATES_ON and not FRIENDNAMEPLATES_ON ) then
		Nameplates:Print( L["Enemy player/npc name plates are now visible."] );
	else
		Nameplates:Print( L["Enemy player/npc name plates are now hidden."] );
	end
end

function Binding:FriendlyBindings()
	RunBinding( "FRIENDNAMEPLATES" );

	if( FRIENDNAMEPLATES_ON and not NAMEPLATES_ON ) then
		Nameplates:Print( L["Friendly player/npc name plates are now visible."] );
	else
		Nameplates:Print( L["Friendly player/npc name plates are now hidden."] );
	end
end

function Binding:AllBindings()
	RunBinding( "ALLNAMEPLATES" );

	if( NAMEPLATES_ON and FRIENDNAMEPLATES_ON ) then
		Nameplates:Print( L["All name plates are now visible."] );
	else
		Nameplates:Print( L["All name plates are now hidden."] );
	end
end