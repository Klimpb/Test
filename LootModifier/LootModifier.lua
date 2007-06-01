local frame = CreateFrame( "Frame" );

LM = {};

function LM:OnEvent( event, ... )
	if( LM[ event ] ) then
		LM[ event ]( LM, event, ... );
	end
end

function LM:ADDON_LOADED( event, addon )
	if( addon == "LootModifier" ) then
		--211/238
	end
end

frame:SetScript( "OnEvent", LM.OnEvent );
frame:RegisterEvent( "ADDON_LOADED" );