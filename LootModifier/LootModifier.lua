LootMod = DongleStub("Dongle-1.0"):New("LootMod")
local L = LootModLocals

function LootMod:Initialize()
	self:RegisterEvent( "LOOT_OPENED" )
	self:RegisterEvent( "LOOT_SLOT_CLEARED" )
	self:RegisterEvent( "LOOT_CLOSED" )
	self:RegisterEvent( "OPEN_MASTER_LOOT_LIST" )
	self:RegisterEvent( "UPDATE_MASTER_LOOT_LIST" )
	
	self.defaults = {
		profile = {
			showType = true,
			showSubType = true,
			locked = true,
			typeColor = { r = 1, g = 1, b = 1 },
		},
	}
	
	self.db = self:InitializeDB( "LootModDB", self.defaults )

	-- Register with OptionHouse
	local OH = LibStub("OptionHouse-1.1")
	local ui = OH:RegisterAddOn( "LootModifier", L["Loot Mod"], "Amarand", "r" .. tonumber( string.match( "$Revision$", "(%d+)" ) or 1 ) )
	ui:RegisterCategory( L["General"], self, "CreateUI" )	
	
	-- Prevents the old LF from showing
	LootFrame:UnregisterAllEvents()	
	
	-- Positioning
	UIPanelWindows["LMWindow"] = { area = "left", pushable = 7 }
	
	-- Base frame
	self.frame = CreateFrame( "Frame", "LMWindow", UIParent )
	self.frame:SetHeight( 256 )
	self.frame:SetWidth( 256 )
	self.frame:SetHitRectInsets( 0, 70, 0, 0 )
	self.frame:SetMovable( not self.db.profile.locked )
	self.frame:EnableMouse( not self.db.profile.locked )
	self.frame:SetClampedToScreen( true )
	self.frame:SetScript( "OnShow", self.LootOnShow )
	self.frame:SetScript( "OnHide", self.LootOnHide )

	self.frame:CreateTitleRegion()
	self.frame:GetTitleRegion():SetAllPoints( self.frame )
	self.frame:Hide()
	
	-- Background texture
	self.frame.topTexture = self.frame:CreateTexture(nil, "ARTWORK")
	self.frame.topTexture:SetWidth(512)
	self.frame.topTexture:SetHeight(128)
	self.frame.topTexture:SetTexture("Interface\\AddOns\\LootModifier\\images\\LootPanel-Top.tga")
	self.frame.topTexture:SetPoint("TOPLEFT", 0, 0)

	self.frame.bottomTexture = self.frame:CreateTexture(nil, "ARTWORK")
	self.frame.bottomTexture:SetWidth(512)
	self.frame.bottomTexture:SetHeight(16)
	self.frame.bottomTexture:SetTexture("Interface\\AddOns\\LootModifier\\images\\LootPanel-Bottom.tga")
	self.frame.bottomTexture:SetPoint("TOPLEFT", 0, -512)

	local text = self.frame:CreateFontString( self.frame:GetName() .. "ItemsText", "ARTWORK", "GameFontNormal" )
	text:SetText( L["Items"] )
	text:SetPoint( "TOPLEFT", self.frame, "TOPLEFT", 10, -6 )
	
	local button = CreateFrame( "Button", self.frame:GetName() .. "Close", self.frame )
	button:SetHeight( 32 )
	button:SetWidth( 32 )
	button:SetPoint( "CENTER", self.frame, "TOPRIGHT", -56, -12 )
	button:SetNormalTexture( "Interface\\Buttons\\UI-Panel-MinimizeButton-Up" )
	button:SetPushedTexture( "Interface\\Buttons\\UI-Panel-MinimizeButton-Down" )
	button:SetHighlightTexture( "Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight" )
	button:GetHighlightTexture():SetBlendMode( "ADD" )
	button:SetScript( "OnClick", function()
		HideUIPanel( self.frame )
	end )
	
	-- Previous / v Arrow
	self.pageUp = CreateFrame( "Button", self.frame:GetName() .. "PageUp", self.frame )
	self.pageUp:SetHeight( 32 )
	self.pageUp:SetWidth( 32 )
	self.pageUp:SetPoint( "BOTTOMLEFT", self.frame, "BOTTOMLEFT", 8, 22 )
	self.pageUp:SetScript( "OnClick", self.PageUp )
	self.pageUp:SetNormalTexture( "Interface\\ChatFrame\\UI-ChatIcon-ScrollUp-Up" )
	self.pageUp:SetPushedTexture( "Interface\\ChatFrame\\UI-ChatIcon-ScollUp-Down" )
	self.pageUp:SetDisabledTexture( "Interface\\ChatFrame\\UI-ChatIcon-ScrollUp-Disabled" )
	--self.pageUp:SetHighlightTexture( "Interface\\ChatFrame\\UI-Common-Mousehilight" )
	--self.pageUp:GetHighlightTexture():SetBlendMode( "ADD" )
		
	self.previousText = self.frame:CreateFontString( self.frame:GetName() .. "PreviousText", "ARTWORK", "GameFontNormal" )
	self.previousText:SetText( L["Previous"] )
	self.previousText:ClearAllPoints()self.previousText:SetPoint( "BOTTOMLEFT", self.pageUp, "BOTTOMLEFT", 30, 10 )
	
	-- Next / ^ Arrow
	self.pageDown = CreateFrame( "Button", self.frame:GetName() .. "PageDown", self.frame )
	self.pageDown:SetHeight( 32 )
	self.pageDown:SetWidth( 32 )
	self.pageDown:SetPoint( "BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", -53, 22 )
	self.pageDown:SetScript( "OnClick", self.PageDown )
	self.pageDown:SetNormalTexture( "Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up" )
	self.pageDown:SetPushedTexture( "Interface\\ChatFrame\\UI-ChatIcon-ScollUp-Down" )
	self.pageDown:SetDisabledTexture( "Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Disabled" )
	--self.pageDown:SetHighlightTexture( "Interface\\ChatFrame\\UI-Common-Mousehilight" )
	--self.pageDown:GetHighlightTexture():SetBlendMode( "ADD" )

	self.nextText = self.frame:CreateFontString( self.frame:GetName() .. "NextText", "ARTWORK", "GameFontNormal" )
	self.nextText:SetText( L["Next"] )
	self.nextText:SetPoint( "BOTTOMLEFT", self.pageDown, "BOTTOMLEFT", -30, 10 )

	-- Loot buttons
	for i=1, LOOTFRAME_NUMBUTTONS do
		button = CreateFrame( "Button", self.frame:GetName() .. "Button" .. i, self.frame, "ItemButtonTemplate" )
		button:SetHeight( 30 )
		button:SetWidth( 30 )
		button:SetScript( "OnEnter", self.LootOnEnter )
		button:SetScript( "OnLeave", self.LootOnLeave )
		button:SetScript( "PostClick", self.LootModifierClicked )
		button:SetScript( "OnUpdate", self.LootOnUpdate )
		button:SetScript( "OnClick", self.LootOnClick )
		button:SetID( i )
		
		if( i > 1 ) then
			button:SetPoint( "TOP", self.frame:GetName() .. "Button" .. ( i - 1 ), "BOTTOM", 0, -5 )
		else
			button:SetPoint( "TOPLEFT", 15, -70 )
		end
		
		button:GetNormalTexture():ClearAllPoints()
		
		button:RegisterForClicks( "LeftButtonUp", "RightButtonUp" )
		button.hasItem = false
		button:Hide()
		
		getglobal( button:GetName() .. "Count" ):SetPoint( "BOTTOMRIGHT", -2, 2 )
		
		-- Item name
		text = button:CreateFontString( button:GetName() .. "Text", "GameFontNormal" )
		text:SetPoint( "TOPRIGHT", button:GetName() .. "IconTexture", "TOPRIGHT", 154, 8 )
		text:SetFont( ( GameFontNormalSmall:GetFont() ), 10 )
		text:SetJustifyH( "LEFT" )
		text:SetWidth( 150 )
		text:SetHeight( 30 )
		
		-- Type, "One-Hand Sword", "Armor", ect
		text = button:CreateFontString( button:GetName() .. "ItemType", "GameFontNormal" )
		text:SetPoint( "TOPLEFT", button:GetName() .. "Text", "TOPLEFT", 0, -13 )
		text:SetFont( ( GameFontNormalSmall:GetFont() ), 10 )
		text:SetJustifyH( "LEFT" )
		text:SetWidth( 150 )
		text:SetHeight( 30 )
	end
	
	-- Got to make sure it uses LootModifiers slot
	StaticPopupDialogs["CONFIRM_LOOT_DISTRIBUTION"].OnAccept = function( data )
		GiveMasterLoot( self.frame.selectedSlot, data )
	end
end

function LootMod:CreateUI()
	local frame = CreateFrame("Frame", nil, OptionHouseFrames.addon)
	frame:SetScript("OnShow", function()
		LootMod.uiLocked:SetChecked( LootMod.db.profile.locked )
		LootMod.uiType:SetChecked( LootMod.db.profile.showType )
		LootMod.uiSubType:SetChecked( LootMod.db.profile.showSubType )
	end )
	
	self.uiLocked = CreateFrame( "CheckButton", "LMUILocked", frame, "OptionsCheckButtonTemplate" )
	self.uiLocked:SetWidth( 32 )
	self.uiLocked:SetHeight( 32 )
	self.uiLocked:SetPoint( "TOPLEFT", 5, -5 )
	LMUILockedText:SetText( L["Lock loot frame"] )
	self.uiLocked:SetScript( "OnClick", function( self )
		if( self:GetChecked() ) then
			LootMod.db.profile.locked = true
		else
			LootMod.db.profile.locked = false
		end
		
		LootMod.frame:SetMovable( not LootMod.db.profile.locked )
		LootMod.frame:EnableMouse( not LootMod.db.profile.locked )
	end )

	self.uiType = CreateFrame( "CheckButton", "LMUIType", frame, "OptionsCheckButtonTemplate" )
	self.uiType:SetWidth( 32 )
	self.uiType:SetHeight( 32 )
	self.uiType:SetPoint( "TOPLEFT", 5, -35 )
	LMUITypeText:SetText( L["Show item type"] )
	self.uiType:SetScript( "OnClick", function( self )
		if( self:GetChecked() ) then
			LootMod.db.profile.showType = true
		else
			LootMod.db.profile.showType = false
		end
	end )

	self.uiSubType = CreateFrame( "CheckButton", "LMUISubType", frame, "OptionsCheckButtonTemplate" )
	self.uiSubType:SetWidth( 32 )
	self.uiSubType:SetHeight( 32 )
	self.uiSubType:SetPoint( "TOPLEFT", 5, -65 )
	LMUISubTypeText:SetText( L["Show sub item type"] )
	self.uiSubType:SetScript( "OnClick", function( self )
		if( self:GetChecked() ) then
			LootMod.db.profile.showSubType = true
		else
			LootMod.db.profile.showSubType = false
		end
	end )

	
	return frame
end

-- Have  to take it over since the default LF wont have anything set
function GroupLootDropDown_GiveLoot()
	if( LootMod.frame.selectedQuality >= MASTER_LOOT_THREHOLD ) then
		local dialog = StaticPopup_Show( "CONFIRM_LOOT_DISTRIBUTION", ITEM_QUALITY_COLORS[LootMod.frame.selectedQuality].hex .. LootMod.frame.selectedItem .. FONT_COLOR_CODE_CLOSE, this:GetText() )
		if( dialog ) then
			dialog.data = this.value;
		end
	else
		GiveMasterLoot( LootMod.frame.selectedSlot, this.value );
	end
	
	CloseDropDownMenus()
end

function LootMod:UpdateLootList()
	local lootShown = LOOTFRAME_NUMBUTTONS
	if( self.frame.numItems > LOOTFRAME_NUMBUTTONS ) then
		lootShown = lootShown - 1
	end
	
	local texture, item, quantity, slot
	local itemLink, itemType, subType, quantityText, button

	for i=1, LOOTFRAME_NUMBUTTONS do
		button = getglobal( self.frame:GetName() .. "Button" .. i )
		slot = ( lootShown * ( self.frame.page - 1 ) ) + i
		
		if( slot <= self.frame.numItems and i <= lootShown ) then
			if( ( LootSlotIsItem( slot ) or LootSlotIsCoin( slot ) ) ) then
				texture, item, quantity, quality = GetLootSlotInfo( slot )
				itemLink = GetLootSlotLink( slot )
				
				getglobal( self.frame:GetName() .. "Button" .. i .. "IconTexture" ):SetTexture( texture )
				
				text = getglobal( self.frame:GetName() .. "Button" .. i .. "Text" )
				
				if( quantity == 0 and quality == 0 ) then
					text:SetPoint( "TOPRIGHT", button:GetName() .. "IconTexture", "TOPRIGHT", 154, 0 )
					text:SetVertexColor( 1, 1, 1 )
				
					if( #( { string.split( "\n", item ) } ) <= 2 ) then
						text:SetText( string.gsub( item, "\n", ", " ) )
					else
						text:SetText( string.gsub( item, "\n", ", ", 1 ) )
					end
					
					getglobal( button:GetName() .. "ItemType" ):Hide()
				else
					text:SetPoint( "TOPRIGHT", button:GetName() .. "IconTexture", "TOPRIGHT", 154, 8 )
					
					if( string.len( item ) > 28 ) then
						item = string.sub( item, 0, 28 ) .. "..."
					end

					text:SetText( item )
					text:SetVertexColor( ITEM_QUALITY_COLORS[ quality ].r, ITEM_QUALITY_COLORS[ quality ].g, ITEM_QUALITY_COLORS[ quality ].b )	
				
					if( itemLink ) then
						_, _, _, _, _, itemType, subType = GetItemInfo( itemLink )
						
						local typeText
						-- It's rather obvious it's a weapon already, don't show it
						if( itemType == L["Weapon"] or not self.db.profile.showType ) then
							itemType = nil
						end
						
						if( itemType == subType or not self.db.profile.showSubType ) then
							subType = nil
						end
						
						if( itemType and subType ) then
							typeText = itemType .. ", " .. subType
						elseif( itemType or subType ) then
							typeText = itemType or subType
						end
				
						if( typeText ) then
							getglobal( button:GetName() .. "ItemType" ):SetTextColor( self.db.profile.typeColor.r, self.db.profile.typeColor.g, self.db.profile.typeColor.b, 1 )
							getglobal( button:GetName() .. "ItemType" ):SetText( typeText )
							getglobal( button:GetName() .. "ItemType" ):Show()
						else
							getglobal( button:GetName() .. "ItemType" ):Hide()
						end
					end
				end
				
				quantityText = getglobal( self.frame:GetName() .. "Button" .. i .. "Count" )
				if( quantity > 1 ) then
					quantityText:SetText( quantity )
					quantityText:Show()
				else
					quantityText:Hide()
				end
				
				button.slot = slot
				button.quality = quality
				button:Show()
			else
				button:Hide()
			end
		else
			button:Hide()
		end
	end
	
	if( self.frame.page == 1 ) then
		self.pageUp:Hide()
		self.previousText:Hide()
	else
		self.pageUp:Show()
		self.previousText:Show()
	end
	
	if( self.frame.numItems == 0 or self.frame.page == ceil( self.frame.numItems / lootShown ) ) then
		self.pageDown:Hide()
		self.nextText:Hide()
	else
		self.pageDown:Show()
		self.nextText:Show()
	end
end

function LootMod:LootOnShow()
	LootMod.frame.numItems = GetNumLootItems()
	
	if( LOOT_UNDER_MOUSE == "1" ) then
		local x, y = GetCursorPosition()
		x = x / LootMod.frame:GetEffectiveScale()
		y = y / LootMod.frame:GetEffectiveScale()

		local posX = x - 175
		local posY = y + 25
		
		if( LootMod.frame.numItems > 0 ) then
			posX = x - 40
			posY = y + 55
			posY = posY + 40
		end

		LootMod.frame:ClearAllPoints()
		LootMod.frame:SetPoint( "TOPLEFT", nil, "BOTTOMLEFT", posX, posY )
		LootMod.frame:GetCenter()
		LootMod.frame:Raise()
	end
	
	LootMod:UpdateLootList()
	
	if( LootMod.frame.numItems ) then
		PlaySound("LOOTWINDOWOPENEMPTY")
	elseif( IsFishingLoot() ) then
		PlaySound("FISHING REEL IN")
	end
end

function LootMod:LootOnHide()
	CloseLoot()
	StaticPopup_Hide( "CONFIRM_LOOT_DISTRIBUTION" )
end

function LootMod:LootOnClick()
	if( not IsModifierKeyDown() ) then
		StaticPopup_Hide( "CONFIRM_LOOT_DISTRIBUTION" )

		LootMod.frame.selectedLoot = this:GetName()
		LootMod.frame.selectedSlot = this.slot
		LootMod.frame.selectedQuality = this.quality
		LootMod.frame.selectedItem = getglobal( this:GetName() .. "Text" ):GetText()
		LootMod.selectedLootButton = this
		
		LootSlot( this.slot )
	end
end

function LootMod:LootModifierClicked()
	if( IsModifierKeyDown() ) then
		if( IsShiftKeyDown() ) then
			ChatEdit_InsertLink( GetLootSlotLink( this.slot ) )
		elseif( IsControlKeyDown() ) then
			DressUpItemLink( GetLootSlotLink( this.slot ) )
		end
	end
end

function LootMod:LootOnEnter()
	local slot = ( ( LOOTFRAME_NUMBUTTONS - 1 ) * ( LootMod.frame.page -1 ) ) + this:GetID()

	if( LootSlotIsItem( slot ) ) then
		GameTooltip:SetOwner( this, "ANCHOR_RIGHT" )
		GameTooltip:SetLootItem( slot )
		if( IsShiftKeyDown() ) then
			GameTooltip_ShowCompareItem()
		end
		CursorUpdate()
	end
end

function LootMod:LootOnLeave()
	GameTooltip:Hide()
	ResetCursor()
end


function LootMod:LootOnUpdate()
	if( GameTooltip:IsOwned( this ) ) then
		LootMod:LootOnEnter()
	end
	
	CursorOnUpdate()
end

function LootMod:PageDown()
	LootMod.frame.page = LootMod.frame.page + 1
	LootMod:UpdateLootList()
end

function LootMod:PageUp()
	LootMod.frame.page = LootMod.frame.page - 1
	LootMod:UpdateLootList()
end

-- Events
function LootMod:LOOT_OPENED()
	self.frame.page = 1
	
	ShowUIPanel( self.frame )
	
	if( not this:IsShown() ) then
		CloseLoot( 1 )
	end
end

function LootMod:LOOT_SLOT_CLEARED( event, slot )
	if( not this:IsShown() ) then
		return
	end
	
	local lootShown = LOOTFRAME_NUMBUTTONS
	local button

	if( self.frame.numItems > LOOTFRAME_NUMBUTTONS ) then
		lootShown = lootShown - 1
	end

	slot = slot - ( ( self.frame.page - 1 ) * lootShown )
	
	if( slot > 0 and slot < ( lootShown + 1 ) ) then
		button = getglobal( self.frame:GetName() .. "Button" .. slot )
		if( button ) then
			button:Hide()
		end
	end
	
	local buttonsHidden = true
	
	for i=1, LOOTFRAME_NUMBUTTONS do
		button = getglobal( self.frame:GetName() .. "Button" .. i )
		if( button:IsShown() ) then
			buttonsHidden = nil
		end
	end
	
	if( buttonsHidden and self.pageDown:IsShown() ) then
		self:PageDown()
	end
end

function LootMod:LOOT_CLOSED()
	StaticPopup_Hide( "LOOT_BIND" )
	HideUIPanel( self.frame )
end

function LootMod:OPEN_MASTER_LOOT_LIST()
	ToggleDropDownMenu( 1, nil, GroupLootDropDown, self.selectedLootButton, 0, 0 )
end

function LootMod:UPDATE_MASTER_LOOT_LIST()
	UIDropDownMenu_Refresh( GroupLootDropDown )
end