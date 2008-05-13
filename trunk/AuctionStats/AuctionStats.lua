AuctionStats = LibStub("AceAddon-3.0"):NewAddon("AuctionStats", "AceEvent-3.0")

local L = AuctionStatLocals
local auctionSpent = {}
local auctionSold = {}

function AuctionStats:OnInitialize()
	self.defaults = {
		profile = {
		},
	}
	self.db = LibStub:GetLibrary("AceDB-3.0"):New("AuctionStatsDB", self.defaults)
	
	-- No data found, default to current char
	if( not self.db.profile.gatherData ) then
		self.db.profile.gatherData = {}
		table.insert(self.db.profile.gatherData, {name = UnitName("player"), server = GetRealmName()})
	end
end

local function sortByTime(a, b)
	return a.time < b.time
end

function AuctionStats:CompileSpent()
	local auctionData = {}
	
	--['completedBids/Buyouts] == itemName, Auction won, money, deposit , fee, buyout , bid, buyer, (time the mail arrived in our mailbox), current wealth, date
	for _, check in pairs(self.db.profile.gatherData) do
		-- Make sure this server/character has data
		if( BeanCounterDB[check.server] and BeanCounterDB[check.server][check.name] ) then
			local auctionDB = BeanCounterDB[check.server][check.name]
			
			-- Loop through items we've succesfully bought out, or bid and won
			for itemid, itemData in pairs(auctionDB["completedBids/Buyouts"]) do
				itemid = tonumber(itemid)
				
				-- Annnd loop through each item itself
				for _, line in pairs(itemData) do
					local itemName, _, _, _, _, buyout, bid, buyer, arrivedAt = string.split(";", line)
					local dateID = date("%m:%d:%Y", arrivedAt)

					if( not auctionData[dateID] ) then
						auctionData[dateID] = {}
					end

					if( not auctionData[dateID][itemid] ) then
						auctionData[dateID][itemid] = {time = arrivedAt, totalBuyout = 0, totalBids = 0, totalBought = 0}
					end

					-- Sadly, we can't check the total # of items we bought unless we do it through AH data, but then we can't really track bids
					auctionData[dateID][itemid].totalBought = auctionData[dateID][itemid].totalBought + 1

					-- If the buyout is 0 then we won it off of bid
					buyout = tonumber(buyout)
					bid = tonumber(bid)
					
					if( buyout > 0 ) then
						auctionData[dateID][itemid].totalBuyout = auctionData[dateID][itemid].totalBuyout + buyout
					else
						auctionData[dateID][itemid].totalBids = auctionData[dateID][itemid].totalBids + bid
					end
				end
			end
		end
	end
		
	-- Compile it into a single table per date
	for i=#(auctionSpent), 1, -1 do
		table.remove(auctionSpent, i)
	end

	for date, itemData in pairs(auctionData) do
		local totalBuyout = 0
		local totalBids = 0
		local totalBought = 0
		local time = 0
		
		for itemid, data in pairs(itemData) do
			totalBuyout = totalBuyout + data.totalBuyout
			totalBids = totalBids + data.totalBids
			totalBought = totalBought + data.totalBought
			time = data.time
		end
		
		table.insert(auctionSpent, { date = date, time = time, buyout = totalBuyout, bid = totalBids, bought = totalBought })
	end
	
	table.sort(auctionSpent, sortByTime)
end

function AuctionStats:DumpSpent()
	AuctionStats:CompileSpent()
	

	for _, data in pairs(auctionSpent) do
		ChatFrame1:AddMessage(string.format("[%s] Spent [%d], bought [%d] items", data.date, (data.buyout + data.bid) / 10000, data.bought))
	end
end

function AuctionStats:CompileSold()
	local auctionData = {}

	
	--['completedAuctions'] == itemName, Auction successful, money, deposit , fee, buyout , bid, buyer, (time the mail arrived in our mailbox), current wealth, date
	for _, check in pairs(self.db.profile.gatherData) do
		-- Make sure this server/character has data
		if( BeanCounterDB[check.server] and BeanCounterDB[check.server][check.name] ) then
			local auctionDB = BeanCounterDB[check.server][check.name]
			
			-- Loop through items we've succesfully bought out, or bid and won
			for itemid, itemData in pairs(auctionDB["completedAuctions"]) do
				itemid = tonumber(itemid)

				-- Annnd loop through each item itself
				for _, line in pairs(itemData) do
					local itemName, _, money, deposit, fee, buyout, bid, buyer, arrivedAt = string.split(";", line)
					local dateID = date("%m:%d:%Y", arrivedAt)

					if( not auctionData[dateID] ) then
						auctionData[dateID] = {}
					end

					if( not auctionData[dateID][itemid] ) then
						auctionData[dateID][itemid] = {time = arrivedAt, totalMoney = 0, totalDeposit = 0, totalFee = 0, totalSold = 0}
					end

					auctionData[dateID][itemid].totalSold = auctionData[dateID][itemid].totalSold + 1
					auctionData[dateID][itemid].totalMoney = auctionData[dateID][itemid].totalMoney + money
					auctionData[dateID][itemid].totalDeposit = auctionData[dateID][itemid].totalDeposit + deposit
					auctionData[dateID][itemid].totalFee = auctionData[dateID][itemid].totalFee + fee
				end
			end
		end
	end
	
	-- Compile it into a single table per date
	for i=#(auctionSold), 1, -1 do
		table.remove(auctionSold, i)
	end

	for date, itemData in pairs(auctionData) do
		local time = 0
		local totalSold = 0
		local totalMoney = 0
		local totalDeposit = 0
		local totalFee = 0
		
		for itemid, data in pairs(itemData) do
			totalSold = totalSold + data.totalSold
			totalMoney = totalMoney + data.totalMoney
			totalDeposit = totalDeposit + data.totalDeposit
			totalFee = totalFee + data.totalFee
			time = data.time
		end
		
		table.insert(auctionSold, { date = date, time = time, sold = totalSold, money = totalMoney, deposit = totalDeposit, fee = totalFee })
	end
	
	table.sort(auctionSold, sortByTime)
end

function AuctionStats:DumpSold()
	AuctionStats:CompileSold()
	
	for _, data in pairs(auctionSold) do
		ChatFrame1:AddMessage(string.format("[%s] made [%d], sold [%d] items", data.date, data.money / 10000, data.sold))
	end
end