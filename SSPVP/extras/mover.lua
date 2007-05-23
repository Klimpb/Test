local Mover = SSPVP:NewModule( "SSPVP-Mover" );

function Mover:Initialize()
	hooksecurefunc( "WorldStateAlwaysUpFrame_Update", self.WorldStateAlwaysUpFrame_Update );
	hooksecurefunc( "UIParent_ManageFramePositions", self.UIParent_ManageFramePositions );
	hooksecurefunc( "WorldStateScoreFrame_Update", self.WorldStateScoreFrame_Update );
	
	if( SSPVP.db.profile.positions.world ) then
		WorldStateAlwaysUpFrame:SetMovable( true );
		WorldStateAlwaysUpFrame:SetPoint( "TOPLEFT", UIParent, "BOTTOMLEFT", SSPVP.db.profile.positions.world.x, SSPVP.db.profile.positions.world.y );
		WorldStateAlwaysUpFrame:SetUserPlaced( false );
	end
	
	if( SSPVP.db.profile.positions.score ) then
		WorldStateScoreFrame:SetPoint( "TOPLEFT", UIParent, "BOTTOMLEFT", SSPVP.db.profile.positions.score.x, SSPVP.db.profile.positions.score.y );
	else
		WorldStateScoreFrame:ClearAllPoints();
		WorldStateScoreFrame:SetPoint( "CENTER", UIParent, "CENTER", 55, 0 );
	end

	WorldStateScoreFrame:SetUserPlaced( false );
end

function Mover:Reload()
	if( self.scoreFrame ) then
		self.scoreFrame:Hide();
	end
	if( self.captureFrame ) then
		self.captureFrame:Hide();
	end
	if( self.worldFrame ) then
		self.worldFrame:Hide();
	end

	self:WorldStateAlwaysUpFrame_Update();
	self:WorldStateScoreFrame_Update();
end

function Mover:WorldStateScoreFrame_Update()
	if( not SSPVP.db.profile.mover.score ) then
		if( not Mover.scoreFrame ) then
			Mover:CreateScore();
		end
		
		Mover.scoreFrame:Show();
	end
end

function Mover:UIParent_ManageFramePositions()
	if( SSPVP.db.profile.positions.capture and NUM_EXTENDED_UI_FRAMES ) then
		local captureBar;
		for i=1, NUM_EXTENDED_UI_FRAMES do
			captureBar = getglobal( "WorldStateCaptureBar" .. i );

			if( captureBar and captureBar:IsVisible() ) then
				captureBar:ClearAllPoints();
				
				if( i > 1 ) then
					captureBar:SetPoint( "TOPLEFT", getglobal( "WorldStateCaptureBar" .. ( i - 1 ) ), "TOPLEFT", 0, -25 );
				else
					captureBar:SetPoint( "TOPLEFT", UIParent, "BOTTOMLEFT", SSPVP.db.profile.positions.capture.x, SSPVP.db.profile.positions.capture.y );
				end
			end	
		end	
	end
end

function Mover:SavePosition( type, frame )
	if( not SSPVP.db.profile.positions[ type ] ) then
		SSPVP.db.profile.positions[ type ] = {};
	end
	
	SSPVP.db.profile.positions[ type ].x, SSPVP.db.profile.positions[ type ].y = frame:GetLeft(), frame:GetTop();
end

function Mover:CreateScore()
	self.scoreFrame = CreateFrame( "Frame", "ScoreMover", WorldStateScoreFrame );
	self.scoreFrame:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
				edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
				tile = true,
				tileSize = 9,
				edgeSize = 9,
				insets = { left = 2, right = 2, top = 2, bottom = 2 } });	
	
	self.scoreFrame:SetBackdropColor( 0, 0, 0, 0.90 );
	self.scoreFrame:SetBackdropBorderColor( 0.75, 0.75, 0.75, 1 );
	
	self.scoreFrame:SetFrameStrata( "HIGH" );
	self.scoreFrame:SetPoint( "TOPLEFT", WorldStateScoreFrame, "TOPLEFT", 0, 0 );
	
	self.scoreFrame:SetHeight( WorldStateScoreFrame:GetHeight() );
	self.scoreFrame:SetWidth( WorldStateScoreFrame:GetWidth() );
	
	self.scoreFrame:EnableMouse( true );
	self.scoreFrame:SetScript( "OnMouseDown", function()
		WorldStateScoreFrame:StartMoving();
	end );
	
	self.scoreFrame:SetScript( "OnMouseUp", function()
		WorldStateScoreFrame:StopMovingOrSizing();

		if( arg1 == "RightButton" ) then
			SSPVP.db.profile.positions.score = nil;
			
			WorldStateScoreFrame:ClearAllPoints();
			WorldStateScoreFrame:SetPoint( "CENTER", UIParent, "CENTER", 55, 0 );
		else
			Mover:SavePosition( "score", WorldStateScoreFrame );
		end

		WorldStateScoreFrame:SetUserPlaced( false );
	end );

	WorldStateScoreFrame:SetMovable( true );
end

function Mover:CreateCapture()
	self.captureFrame = CreateFrame( "Frame", "CaptureMover", WorldStateCaptureBar1 );
	self.captureFrame:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
				edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
				tile = true,
				tileSize = 9,
				edgeSize = 9,
				insets = { left = 2, right = 2, top = 2, bottom = 2 } });	
	
	self.captureFrame:SetBackdropColor( 0, 0, 0, 0.90 );
	self.captureFrame:SetBackdropBorderColor( 0.75, 0.75, 0.75, 1 );
	
	self.captureFrame:SetFrameStrata( "HIGH" );
	self.captureFrame:SetPoint( "TOPLEFT", WorldStateCaptureBar1, "TOPLEFT", 0, 0 );
	
	self.captureFrame:EnableMouse( true );
	self.captureFrame:SetScript( "OnMouseDown", function()
		WorldStateAlwaysUpFrame:UnregisterEvent( "UPDATE_WORLD_STATES" );
		WorldStateCaptureBar1:StartMoving();
	end );
	
	self.captureFrame:SetScript( "OnMouseUp", function()
		WorldStateCaptureBar1:StopMovingOrSizing();

		if( arg1 == "RightButton" ) then
			SSPVP.db.profile.positions.capture = nil;
			
			local captureBar;
			for i=1, NUM_EXTENDED_UI_FRAMES do
				captureBar = getglobal( "WorldStateCaptureBar" .. i );
				if( captureBar ) then
					captureBar:ClearAllPoints();
				end
			end
		else
			Mover:SavePosition( "capture", WorldStateCaptureBar1 );
		end

		WorldStateAlwaysUpFrame:RegisterEvent( "UPDATE_WORLD_STATES" );
		WorldStateAlwaysUpFrame_Update();
	end );

	WorldStateCaptureBar1:SetMovable( true );
	WorldStateCaptureBar1:SetClampedToScreen( true );
end

function Mover:CreateWorld()
	self.worldFrame = CreateFrame( "Frame", "WorldMover", WorldStateAlwaysUpFrame );

	self.worldFrame.totalWidth = 0;

	self.worldFrame:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
				edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
				tile = true,
				tileSize = 9,
				edgeSize = 9,
				insets = { left = 2, right = 2, top = 2, bottom = 2 } });	
	
	self.worldFrame:SetBackdropColor( 0, 0, 0, 0.90 );
	self.worldFrame:SetBackdropBorderColor( 0.75, 0.75, 0.75, 1 );
	
	self.worldFrame:SetFrameStrata( "HIGH" );
	self.worldFrame:SetPoint( "TOPLEFT", AlwaysUpFrame1, "TOPLEFT", -5, 15 );
	
	self.worldFrame:EnableMouse( true );
	self.worldFrame:SetScript( "OnMouseDown", function()
		WorldStateAlwaysUpFrame:StartMoving();
	end );
	
	self.worldFrame:SetScript( "OnMouseUp", function()
		WorldStateAlwaysUpFrame:StopMovingOrSizing();

		if( arg1 == "RightButton" ) then
			SSPVP.db.profile.positions.world = nil;

			WorldStateAlwaysUpFrame:ClearAllPoints();
			WorldStateAlwaysUpFrame:SetPoint( "TOP", "UIParent", "TOP", -5, -15 );
		else
			Mover:SavePosition( "world", WorldStateAlwaysUpFrame );
		end

		WorldStateAlwaysUpFrame:SetUserPlaced( false );
	end );

	WorldStateAlwaysUpFrame:SetMovable( true );
	WorldStateAlwaysUpFrame:SetClampedToScreen( true );
end


function Mover:WorldStateAlwaysUpFrame_Update()
	local state, dynamicIcon, extendedUI, currentWidth;

	local captureTotal = 1;
	local alwaysTotal = 1;
	
	for i=1, GetNumWorldStateUI() do
		state, _, _, dynamicIcon, _, _, extendedUI = GetWorldStateUIInfo( i );
		
		if( state > 0 ) then
			if( not SSPVP.db.profile.mover.capture and extendedUI ~= "" ) then
				if( captureTotal == 1 ) then
					if( not Mover.captureFrame ) then
						Mover:CreateCapture();
					end
					
					Mover.captureFrame:SetHeight( WorldStateCaptureBar1:GetHeight() );
					Mover.captureFrame:SetWidth( WorldStateCaptureBar1:GetWidth() );
					Mover.captureFrame:Show();
				end
				
				captureTotal = captureTotal + 1;
				
			elseif( not SSPVP.db.profile.mover.world and extendedUI == "" ) then
				if( not Mover.worldFrame ) then
					Mover:CreateWorld();
				end
				
				-- Resize the mover frame to what the longest always up row is
				currentWidth = getglobal( "AlwaysUpFrame" .. alwaysTotal .. "Text" ):GetWidth();
				if( dynamicIcon ~= "" ) then
					currentWidth = currentWidth + getglobal( "AlwaysUpFrame" .. alwaysTotal .. "DynamicIconButtonIcon" ):GetWidth();
				end
				
				if( Mover.worldFrame.totalWidth < currentWidth ) then
					Mover.worldFrame:SetWidth( currentWidth );
					Mover.worldFrame.totalWidth = currentWidth;
				end
			
				alwaysTotal = alwaysTotal + 1;
			end
		end
	end
	
	if( alwaysTotal > 1 ) then	
		Mover.worldFrame:SetHeight( alwaysTotal * 20 );
		Mover.worldFrame:Show();

	elseif( Mover.worldFrame ) then
		Mover.worldFrame:Hide();
	end
	
	if( captureTotal == 1 and Mover.captureFrame ) then
		Mover.captureFrame:Hide();
	end
end