LM = DongleStub( "Dongle-1.0" ):New( "LM" );

local L = LootModLocals;

function LM:Initialize()
	self:RegisterEvent( "LOOT_OPENED" );
	self:RegisterEvent( "LOOT_SLOT_CLEARED" );
	self:RegisterEvent( "LOOT_CLOSED" );
	self:RegisterEvent( "OPEN_MASTER_LOOT_LIST" );
	self:RegisterEvent( "UPDATE_MASTER_LOOT_LIST" );

	LootFrame:UnregisterAllEvents();	
	
	UIPanelWindows["LMWindow"] = { area = "left", pushable = 7 };
	
	self.frame = CreateFrame( "Frame", "LMWindow", UIParent );
	self.frame:SetHeight( 256 );
	self.frame:SetWidth( 256 );
	self.frame:SetPoint( "TOPLEFT", 0, -104 );
	self.frame:SetHitRectInsets( 0, 70, 0, 0 );
	--self.frame:SetTopLevel( true );
	self.frame:SetMovable( true );
	self.frame:EnableMouse( true );
	self.frame:SetClampedToScreen( true );
	self.frame:SetScript( "OnShow", LM.LootOnShow );
	self.frame:SetScript( "OnHide", LM.LootOnHide );
	
	self.frame:CreateTitleRegion();
	self.frame:GetTitleRegion():SetAllPoints( self.frame );
	self.frame:Hide();
	
	local texture = self.frame:CreateTexture( self.frame:GetName() .. "BGTexture", "ARTWORK" );
	texture:SetTexture( "Interface\\AddOns\\LootModifier\\LootWindow.tga" );
	texture:SetAllPoints();
	texture:Show();
	
	local text = self.frame:CreateFontString( self.frame:GetName() .. "ItemsText", "ARTWORK", "GameFontNormal" );
	text:SetText( "Items" );
	text:SetPoint( "TOPLEFT", self.frame, "TOPLEFT", 10, -6 );
		
	local button = CreateFrame( "Button", self.frame:GetName() .. "Close", self.frame );
	button:SetHeight( 32 );
	button:SetWidth( 32 );
	button:SetPoint( "CENTER", self.frame, "TOPRIGHT", -56, -12 );
	button:SetNormalTexture( "Interface\\Buttons\\UI-Panel-MinimizeButton-Up" );
	button:SetPushedTexture( "Interface\\Buttons\\UI-Panel-MinimizeButton-Down" );
	button:SetHighlightTexture( "Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight" );
	button:GetHighlightTexture():SetBlendMode( "ADD" );
	button:SetScript( "OnClick", function()
		HideUIPanel( self.frame );
	end );
	
	self.pageUp = CreateFrame( "Button", self.frame:GetName() .. "PageUp", self.frame );
	self.pageUp:SetHeight( 32 );
	self.pageUp:SetWidth( 32 );
	self.pageUp:SetPoint( "BOTTOMLEFT", self.frame, "BOTTOMLEFT", 8, 22 );
	self.pageUp:SetScript( "OnClick", LM.PageUp );
	self.pageUp:SetNormalTexture( "Interface\\ChatFrame\\UI-ChatIcon-ScrollUp-Up" );
	self.pageUp:SetPushedTexture( "Interface\\ChatFrame\\UI-ChatIcon-ScollUp-Down" );
	self.pageUp:SetDisabledTexture( "Interface\\ChatFrame\\UI-ChatIcon-ScrollUp-Disabled" );
	--self.pageUp:SetHighlightTexture( "Interface\\ChatFrame\\UI-Common-Mousehilight" );
	--self.pageUp:GetHighlightTexture():SetBlendMode( "ADD" );

	self.pageDown = CreateFrame( "Button", self.frame:GetName() .. "PageDown", self.frame );
	self.pageDown:SetHeight( 32 );
	self.pageDown:SetWidth( 32 );
	self.pageDown:SetPoint( "BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", -53, 22 );
	self.pageDown:SetScript( "OnClick", LM.PageDown );
	self.pageDown:SetNormalTexture( "Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up" );
	self.pageDown:SetPushedTexture( "Interface\\ChatFrame\\UI-ChatIcon-ScollUp-Down" );
	self.pageDown:SetDisabledTexture( "Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Disabled" );
	--self.pageDown:SetHighlightTexture( "Interface\\ChatFrame\\UI-Common-Mousehilight" );
	--self.pageDown:GetHighlightTexture():SetBlendMode( "ADD" );
		
	self.previousText = self.frame:CreateFontString( self.frame:GetName() .. "PreviousText", "ARTWORK", "GameFontNormal" );
	self.previousText:SetText( "Previous" );
	self.previousText:ClearAllPoints();self.previousText:SetPoint( "BOTTOMLEFT", self.pageUp, "BOTTOMLEFT", 30, 10 );

	self.nextText = self.frame:CreateFontString( self.frame:GetName() .. "NextText", "ARTWORK", "GameFontNormal" );
	self.nextText:SetText( "Next" );
	self.nextText:SetPoint( "BOTTOMLEFT", self.pageDown, "BOTTOMLEFT", -30, 10 );

	for i=1, LOOTFRAME_NUMBUTTONS do
		button = CreateFrame( "Button", self.frame:GetName() .. "Button" .. i, self.frame, "ItemButtonTemplate" );
		button:SetHeight( 30 );
		button:SetWidth( 30 );
		button:SetScript( "OnEnter", LM.LootOnEnter );
		button:SetScript( "OnLeave", LM.LootOnLeave );
		button:SetScript( "PostClick", LM.LootModifierClicked );
		button:SetScript( "OnUpdate", LM.LootOnUpdate );
		button:SetScript( "OnClick", LM.LootOnClick );
		button:SetID( i );
		
		if( i > 1 ) then
			button:SetPoint( "TOP", self.frame:GetName() .. "Button" .. ( i - 1 ), "BOTTOM", 0, -5 );
		else
			button:SetPoint( "TOPLEFT", 15, -70 );
		end
		
		button:GetNormalTexture():ClearAllPoints();
		
		button:RegisterForClicks( "LeftButtonUp", "RightButtonUp" );
		button.hasItem = true;
		button:Hide();
		
		getglobal( button:GetName() .. "Count" ):SetPoint( "BOTTOMRIGHT", -2, 2 );
		
		text = button:CreateFontString( button:GetName() .. "Text", "GameFontNormal" );
		text:SetPoint( "TOPRIGHT", button:GetName() .. "IconTexture", "TOPRIGHT", 154, 8 );
		text:SetFont( ( GameFontNormalSmall:GetFont() ), 10 );
		text:SetJustifyH( "LEFT" );
		text:SetWidth( 150 );
		text:SetHeight( 30 );
		
		text = button:CreateFontString( button:GetName() .. "ItemType", "GameFontNormal" );
		text:SetPoint( "TOPLEFT", button:GetName() .. "Text", "TOPLEFT", 0, -10 );
		text:SetFont( ( GameFontNormalSmall:GetFont() ), 10 );
		text:SetJustifyH( "LEFT" );
		text:SetWidth( 150 );
		text:SetHeight( 30 );
	end
end

function LM:UpdateLootList()
	local lootShown = LOOTFRAME_NUMBUTTONS;
	if( self.frame.numItems > LOOTFRAME_NUMBUTTONS ) then
		lootShown = lootShown - 1;
	end
	
	local texture, item, quantity, slot;
	local itemLink, itemType, subType, quantityText, button;

	for i=1, LOOTFRAME_NUMBUTTONS do
		button = getglobal( self.frame:GetName() .. "Button" .. i );
		slot = ( lootShown * ( self.frame.page - 1 ) ) + i;
		
		if( slot <= self.frame.numItems and i <= lootShown ) then
			if( ( LootSlotIsItem( slot ) or LootSlotIsCoin( slot ) ) ) then
				texture, item, quantity, quality = GetLootSlotInfo( slot );
				itemLink = GetLootSlotLink( slot );
				
				getglobal( self.frame:GetName() .. "Button" .. i .. "IconTexture" ):SetTexture( texture );
				
				text = getglobal( self.frame:GetName() .. "Button" .. i .. "Text" )
				
				if( quantity == 0 and quality == 0 ) then
					text:SetPoint( "TOPRIGHT", button:GetName() .. "IconTexture", "TOPRIGHT", 154, 0 );
					text:SetVertexColor( 1, 1, 1 );
				
					if( #( { string.split( "\n", item ) } ) <= 2 ) then
						text:SetText( string.gsub( item, "\n", ", " ) );
					else
						text:SetText( string.gsub( item, "\n", ", ", 1 ) );
					end
					
					getglobal( button:GetName() .. "ItemType" ):Hide();
				else
					text:SetPoint( "TOPRIGHT", button:GetName() .. "IconTexture", "TOPRIGHT", 154, 8 );
					
					if( string.len( item ) > 28 ) then
						item = string.sub( item, 0, 28 ) .. "...";
					end

					text:SetText( item );
					text:SetVertexColor( ITEM_QUALITY_COLORS[ quality ].r, ITEM_QUALITY_COLORS[ quality ].g, ITEM_QUALITY_COLORS[ quality ].b );	
				
					if( itemLink ) then
						_, _, _, _, _, itemType, subType = GetItemInfo( itemLink );
						
						if( itemType ~= subType ) then
							itemType = "\n|cffffffff" .. string.format( L["%s, %s"], itemType, subType ) .. "|r";
						else
							itemType = "\n|cffffffff" .. itemType .. "|r";						
						end
						
						getglobal( button:GetName() .. "ItemType" ):SetText( itemType );
						getglobal( button:GetName() .. "ItemType" ):Show();
					end
				end
				
				quantityText = getglobal( self.frame:GetName() .. "Button" .. i .. "Count" );
				if( quantity > 1 ) then
					quantityText:SetText( quantity );
					quantityText:Show();
				else
					quantityText:Hide();
				end
				
				button.slot = slot;
				button.quality = quality;
				button:Show();
			else
				button:Hide();
			end
		else
			button:Hide();
		end
	end
	
	if( self.frame.page == 1 ) then
		self.pageUp:Hide();
		self.previousText:Hide();
	else
		self.pageUp:Show();
		self.previousText:Show();
	end
	
	if( self.frame.page == ceil( self.frame.numItems / lootShown ) or self.frame.numItems == 0 ) then
		self.pageDown:Hide();
		self.nextText:Hide();
	else
		self.pageDown:Show();
		self.nextText:Show();
	end
end

function LM:LootOnShow()
	LM.frame.numItems = GetNumLootItems();
	
	if( LOOT_UNDER_MOUSE == "1" ) then
		local x, y = GetCursorPosition();
		x = x / LM.frame:GetEffectiveScale();
		y = y / LM.frame:GetEffectiveScale();

		local posX = x - 175;
		local posY = y + 25;
		
		if( LM.frame.numItems > 0 ) then
			posX = x - 40;
			posY = y + 55;
			posY = posY + 40;
		end

		LM.frame:ClearAllPoints();
		LM.frame:SetPoint( "TOPLEFT", nil, "BOTTOMLEFT", posX, posY );
		LM.frame:GetCenter();
		LM.frame:Raise();
	end
	
	LM:UpdateLootList();
	
	if( LM.frame.numItems ) then
		PlaySound("LOOTWINDOWOPENEMPTY");
	elseif( IsFishingLoot() ) then
		PlaySound("FISHING REEL IN");
	end
end

function LM:LootOnHide()
	CloseLoot();
	StaticPopup_Hide( "CONFIRM_LOOT_DISTRIBUTION" );
end

function LM:LootOnClick()
	if( not IsModifierKeyDown() ) then
		StaticPopup_Hide( "CONFIRM_LOOT_DISTRIBUTION" );

		LM.frame.selectedLoot = this:GetName();
		LM.frame.selectedSlot = this.slot;
		LM.frame.selectedQuality = this.quality;
		LM.frame.selectedItem = getglobal( this:GetName() .. "Text" ):GetText();

		LootSlot( this.slot );
	end
end

function LM:LootModifierClicked()
	if( IsModifierKeyDown() ) then
		if( IsShiftKeyDown() ) then
			ChatEdit_InsertLink( GetLootSlotLink( this.slot ) );
		elseif( IsControlKeyDown() ) then
			DressUpItemLink( GetLootSlotLink( this.slot ) );
		end
	end
end

function LM:LootOnEnter()
	local slot = ( ( LOOTFRAME_NUMBUTTONS - 1 ) * ( LM.frame.page -1 ) ) + this:GetID();

	if( LootSlotIsItem( slot ) ) then
		GameTooltip:SetOwner( this, "ANCHOR_RIGHT" );
		GameTooltip:SetLootItem( slot );
		if( IsShiftKeyDown() ) then
			GameTooltip_ShowCompareItem();
		end
		CursorUpdate();
	end
end

function LM:LootOnLeave()
	GameTooltip:Hide();
	ResetCursor();
end


function LM:LootOnUpdate()
	if( GameTooltip:IsOwned( this ) ) then
		LM:LootOnEnter();
	end
	
	CursorOnUpdate();
end

function LM:PageDown()
	LM.frame.page = LM.frame.page + 1;
	LM:UpdateLootList();
end

function LM:PageUp()
	LM.frame.page = LM.frame.page - 1;
	LM:UpdateLootList();
end

function LM:LOOT_OPENED()
	self.frame.page = 1;
	
	ShowUIPanel( self.frame );
	
	if( not this:IsShown() ) then
		CloseLoot( 1 );
	end
end

function LM:LOOT_SLOT_CLEARED( event, slot )
	if( not this:IsShown() ) then
		return;
	end
	
	local lootShown = LOOTFRAME_NUMBUTTONS;
	local button;

	if( self.frame.numItems > LOOTFRAME_NUMBUTTONS ) then
		lootShown = lootShown - 1;
	end

	slot = slot - ( ( self.frame.page - 1 ) * lootShown );
	
	if( slot > 0 and slot < ( lootShown + 1 ) ) then
		button = getglobal( self.frame:GetName() .. "Button" .. slot );
		if( button ) then
			button:Hide();
		end
	end
	
	local buttonsHidden = true;
	
	for i=1, LOOTFRAME_NUMBUTTONS do
		button = getglobal( self.frame:GetName() .. "Button" .. i );
		if( button:IsShown() ) then
			buttonsHidden = nil;
		end
	end
	
	if( buttonsHidden and self.pageDown:IsShown() ) then
		LM:PageDown();
	end
end

function LM:LOOT_CLOSED()
	StaticPopup_Hide( "LOOT_BIND" );
	HideUIPanel( self.frame );
end

function LM:OPEN_MASTER_LOOT_LIST()
	ToggleDropDownMenu( 1, nil, GroupLootDropDown, self.selectedLootButton, 0, 0 );
end

function LM:UPDATE_MASTER_LOOT_LIST()
	UIDropDownMenu_Refresh( GroupLootDropDown );
end