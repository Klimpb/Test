local frame = CreateFrame( "Frame" );
local nsb = DongleStub("nSideBar-0.1");
local scripts = { "OnClick", "OnEnter", "OnEvent", "OnHide", "OnLeave", "OnMouseDown", "OnMouseUp", "OnMouseWheel", "OnShow", "OnSizeChanged" }
local registeredButtons = {}

local function HideMinimapButton()
	this:Hide()
end

local function ScanMinimap( ... )
	local child, texture, button
	
	for i=1, select( "#", ... ) do
		child = select( i, ... )
		if( child:GetName() and not registeredButtons[ child:GetName() ] and not string.match( string.lower( child:GetName() ), "^minimap" ) ) then
			if( child:GetHeight() <= 50 and child:GetWidth() <= 50 ) then
				if( getglobal( child:GetName() .. "Icon" ) ) then
					child:SetScript( "OnShow", HideMinimapButton )
					child:Hide()
					
					texture = getglobal( child:GetName() .. "Icon" )
					
					if( texture ) then
						button = nsb:AddButton( i, texture:GetTexture() )
						button.self = child.self
					
						for _, script in pairs( scripts ) do
							if( child:GetScript( script ) ) then
								if( button:GetScript( script ) ) then
									button:HookScript( script, child:GetScript( script ) )
								else
									button:SetScript( script, child:GetScript( script ) )
								end
							end
						end
					end
				end
			end
		end
	end
end

local children = 0
local function OnUpdate()
	if( children ~= Minimap:GetNumChildren() ) then
		children = Minimap:GetNumChildren()
		ScanMinimap( Minimap:GetChildren() )
	end
end

local function OnEvent()
	if( event == "ADDON_LOADED" and arg1 == "DamnMinimapIcons" ) then
		ScanMinimap( Minimap:GetChildren() )
	end
end

--frame:SetScript( "OnUpdate", OnUpdate )
--frame:SetScript( "OnEvent", OnEvent );
--frame:RegisterEvent( "ADDON_LOADED" );
--[[
local LastCombat
frame:SetScript( "OnEvent", function()
	if( string.find( event, "SELF_" ) or string.find( event, "HOSTILEPLAYER" ) ) then
		LastCombat = GetTime();
	elseif( event == "PLAYER_REGEN_ENABLED" ) then
		if( LastCombat ) then
			Debug( GetTime() - LastCombat );
		end
	end
end );
frame:RegisterAllEvents();
]]