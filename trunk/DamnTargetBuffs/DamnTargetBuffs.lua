-- Modify these two as you wish, spacing between each buff/debuff
local DEBUFF_OFFSET = 4
local BUFF_OFFSET = 3

-- Figure out how many buffs will be shown in the first row
local firstBuffRow = 5
local numBuffs = 0
local numDebuffs = 0

local Orig_TargetDebuffButton_Update = TargetDebuffButton_Update
function TargetDebuffButton_Update(...)
	if( TargetofTargetFrame:IsShown() ) then
		firstBuffRow = 5
	else
		firstBuffRow = 6
	end
	
	numBuffs = 0
	for i=1, MAX_TARGET_BUFFS do
		if( select(3, UnitBuff("target", i)) ) then
			numBuffs = numBuffs + 1
		end
	end
	
	
	numDebuffs = 0
	for i=1, MAX_TARGET_DEBUFFS do
		if( select(3, UnitDebuff("target", i)) ) then
			numDebuffs = numDebuffs + 1
		end
	end
	
	Orig_TargetDebuffButton_Update(...)
end

-- Update buff positioning/size
local Orig_TargetFrame_UpdateBuffAnchor = TargetFrame_UpdateBuffAnchor
function TargetFrame_UpdateBuffAnchor(buffName, index, numFirstRowBuffs, numDebuffs, buffSize, offset, ...)
	if( numBuffs >= firstBuffRow ) then
		buffSize = SMALL_BUFF_SIZE
	else
		buffSize = LARGE_BUFF_SIZE
	end
	
	Orig_TargetFrame_UpdateBuffAnchor(buffName, index, firstBuffRow, numDebuffs, buffSize, BUFF_OFFSET, ...)
end

-- Update debuff positioning/size
local Orig_TargetFrame_UpdateDebuffAnchor = TargetFrame_UpdateDebuffAnchor
function TargetFrame_UpdateDebuffAnchor(buffName, index, numFirstRowBuffs, numBuffs, buffSize, offset, ...)
	if( numDebuffs >= firstBuffRow ) then
		buffSize = SMALL_BUFF_SIZE
	else
		buffSize = LARGE_BUFF_SIZE
	end
		
	Orig_TargetFrame_UpdateDebuffAnchor(buffName, index, firstBuffRow, numBuffs, buffSize, DEBUFF_OFFSET, ...)
end