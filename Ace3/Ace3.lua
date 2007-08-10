Ace3 = AceLibrary( "AceAddon-2.0" ):new( "AceConsole-2.0" )

local cards = { "Ace", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "Jack", "Queen", "King" }
local suits = { "Heart", "Spade", "Diamond", "Clover" }

local dealer = {}
local player = {}
local money = 50
local bet = 0

function Ace3:OnInitialize()
	Ac3:RegisterChatCommand("/ace3", {
	type = "group",
	args = {
		msg = {
			type = "execute",
			name = "Start game"
			desc = "Starts a new game of Ace3",
			handler = Ace3,
			func = "StartGame",
		},
		msg = {
			type = "text",
			name = "Guess Suit"
			desc = "Takes a guess at what suit the dealer has",
			handler = Ace3,
			set = "GuessSuit",
			usage = "<bet> <Heart, Spade, Diamond, Clover>",
		},
		msg = {
			type = "text",
			name = "Guess Card"
			desc = "Takes a guess at what card the dealer has",
			handler = Ace3,
			set = "GuessCard",
			usage = "<bet> <Ace, Jack, Queen, King, 1-10>",
		},
		msg = {
			type = "execute",
			name = "End game"
			desc = "Finishes a started game of Ace3",
			handler = Ace3,
			func = "EndGame",
		},
	}})
end

function Ace3:GenerateDealer()
	dealer = {}
	table.insert( dealer, { card = cards[math.random(1, #(cards))], suit = suits[math.random(1, #(cards))] )
end

function Ace3:StartGame()
	local yourCards = {}
	for i=1, 3 do
		local row = { card = cards[math.random(1, #(cards))], suit = suits[math.random(1, #(cards))] }
		
		table.insert( yourCards, row.card .. " of " .. row.suit )
		table.insert( player, row )
	end
		
	self:GenerateDealer()
	
	self:Print( "[Money: " .. money .. "] Your cards: " .. table.concat( ",", yourCards ) )
	self:Print( "Take a guess!" )
end

function Ace3:GuessSuit(cmd)
	if( #(dealer) == 0 ) then
		self:Print( "You don't have a game currently running." )
		return
	end
	
	local betMoney, guessedSuit = string.split( ",", cmd )
	
	local suit
	
	for _, checkSuit in pairs(suits) do
		if( string.lower(checkSuit) == string.lower(guessedSuit) ) then
			suit = checkSuit
			break
		end
	end
	
	if( not suit ) then
		self:Print( "No suit exists by the name of \"" .. guessedSuit .. "\"." )
		return
	end
	
	if( betMoney > money ) then
		self:Print( "You can't bet more money then you have." )
		return
	end
	
	bet = betMoney
	
	if( dealer.suit == suit ) then
		money = money + ( bet * 0.5 )
		self:Print( "You guessed correctly it's the " .. dealer.card .. " of " .. dealer.suit .. "! [Money: " .. money .. "]" )
		self:GenerateDealer()
	else
		money = math.abs( money - bet )
		self:Print( "Wrong, the suit was " .. dealer.card .. " of " .. dealer.suit .. " [Money: " .. money .. "]" )
		
		if( money == 0 ) then
			self:EndGame()
		end
	end

end

function Ace3:GuessCard(cmd)
	if( #(dealer) == 0 ) then
		self:Print( "You don't have a game currently running." )
		return
	end
	
	local betMoney, guessedCard = string.split( ",", cmd )

	local card
	
	for _, checkCard in pairs(cards) do
		if( string.lower(checkCard) == string.lower(guessedCard) ) then
			card = checkCard
			break
		end
	end
	
	if( not card ) then
		self:Print( "No card exists by the name of \"" .. guessedCard .. "\"." )
		return
	end
	
	if( betMoney > money ) then
		self:Print( "You can't bet more money then you have." )
		return
	end
	
	bet = betMoney
	
	if( dealer.card == card ) then
		money = money + ( bet * 1.5 )
		self:GenerateDealer()
		self:Print( "You guessed correctly! [Money: " .. money .. "]" )
	else
		money = math.abs( money - bet )
		self:Print( "Wrong, the card was " .. dealer.card .. " of " .. dealer.suit .. " [Money: " .. money .. "]" )
		
		if( money == 0 ) then
			self:EndGame()
		end
	end
end

function Ace3:EndGame()
	self:Print( "Game Over!" )

	if( money > 50 ) then
		self:Print( "You won " .. ( money - 50 ) " money! =D." )
	else if( money == 0 ) then
		self:Print( "You lost all of your money =(." )
	else
		self:Print( "You lost " .. ( 50 - money ) .. " money =(." )
	end

	player = {}
	dealer = {}
	bet = 0
	money = 0
end
