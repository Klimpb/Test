Ace3 = AceLibrary( "AceAddon-2.0" ):new( "AceConsole-2.0" )

local cards = { "Ace", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "Jack", "Queen", "King" }
local suits = { "Heart", "Spade", "Diamond", "Clover" }

local dealer = {}
local player = {}
local gold = 50
local bet = 0
local rules

function Ace3:OnInitialize()
	Ace3:RegisterChatCommand("/ace3", {
	type = "group",
	args = {
		start = {
			type = "execute",
			name = "Start game",
			desc = "Starts a new game of Ace3",
			handler = Ace3,
			func = "StartGame",
		},
		suit = {
			type = "text",
			name = "Guess Suit",
			desc = "[<bet> <Heart, Spade, Diamond, Clover>] Takes a guess at what suit the dealer has",
			handler = Ace3,
			set = "GuessSuit",
			get = false,
			usage = "<bet> <Heart, Spade, Diamond, Clover>",
		},
		card = {
			type = "text",
			name = "Guess Card",
			desc = "[<bet> <Ace, Jack, Queen, King, 1-10>] Takes a guess at what card the dealer has",
			handler = Ace3,
			get = false,
			set = "GuessCard",
			usage = "<bet> <Ace, Jack, Queen, King, 1-10>",
		},
		stop = {
			type = "execute",
			name = "End game",
			desc = "Finishes a started game of Ace3",
			handler = Ace3,
			func = "EndGame",
		},
	}})
end

function Ace3:GenerateDealer()
	dealer = {}

	table.insert( dealer, { card = cards[math.random(1, #(cards))], suit = suits[math.random(1, #(suits))] } )
	table.insert( dealer, { card = cards[math.random(1, #(cards))], suit = suits[math.random(1, #(suits))] } )
	table.insert( dealer, { card = cards[math.random(1, #(cards))], suit = suits[math.random(1, #(suits))] } )
end

function Ace3:GeneratePlayer()
	player = {}

	local yourCards = {}
	for i=1, 3 do
		local row = { card = cards[math.random(1, #(cards))], suit = suits[math.random(1, #(suits))] }
		
		table.insert( yourCards, row.card .. " of " .. row.suit )
		table.insert( player, row )
	end
	
	self:Print( "Your cards: " .. table.concat( yourCards, ", " ) )
end

function Ace3:StartGame()
	self:GeneratePlayer()
	self:GenerateDealer()
	self:Print( "Take a guess!" )
	
	if( not rules ) then
		self:Print( "Rules: You can take a guess at one of the dealers 3 cards and you'll win bet * 1.5, or you can try and guess the suit for bet * 0.50." )
		self:Print( "The dealer will take a guess at one of your cards or suits depending what you were guessing for him, if your guess is wrong you lose the amount of gold you bet." )
		self:Print( "If the dealer guesses you lose the amount of gold you gained" )
		self:Print( "If you run out of gold, you lose" )
		self:Print( "You start out with 50 gold." );
		rules = true
	end
end

function Ace3:DealerGuess(bet, type)
	if( type == "suit" ) then
		local suit = suits[math.random(1, #suits)]
		
		for _, row in pairs(player) do
			if( row.suit == suit ) then
				gold = math.abs( gold - bet )
				self:Print( "Dealer guessed correctly! [" .. row.card .. " of " .. row.suit .. "] [Gold: " .. gold .. " (Lost " .. bet .. ")]" )

				if( gold == 0 ) then
					self:EndGame()
				end
				
				self:GeneratePlayer()
				return
			end
		end
		
		self:Print( "Dealer guessed incorrectly." )
		
	elseif( type == "card" ) then
		local card = cards[math.random(1, #cards)]
		
		for _, row in pairs(player) do
			if( row.card == card ) then
				gold = math.abs( gold - bet )
				self:Print( "Dealer guessed correctly! [" .. row.card .. " of " .. row.suit .. "] [Gold: " .. gold .. " (Lost " .. bet .. ")]" )

				if( gold == 0 ) then
					self:EndGame()
				end

				self:GeneratePlayer()
				return
			end
		end
		
		self:Print( "Dealer guessed incorrectly." )
	
	end
end

function Ace3:GuessSuit(cmd)
	if( #(dealer) == 0 ) then
		self:Print( "You don't have a game currently running." )
		return
	end
	
	local betGold, guessedSuit = string.split( " ", cmd )
	betGold = tonumber(betGold)
	if( not betGold or not guessedSuit ) then
		self:Print( "Incorrect arguments." );
		return
	end
	
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
	
	if( betGold > gold ) then
		self:Print( "You can't bet more gold then you have." )
		return
	end
	
	bet = betGold

	for _, row in pairs(dealer) do
		if( row.suit == suit ) then
			gold = gold + ( bet * 0.5 )

			self:Print( "You guessed correctly, it was [" .. row.card .. " of " .. row.suit .. "] [Gold: " .. gold .. " (Gained " .. (bet * 0.5 ) .. ")]" )
			self:GenerateDealer()
			self:DealerGuess( bet * 0.5, "suit" )
			return
		end
	end

	gold = math.abs( gold - bet )
	self:Print( "Wrong! [Gold: " .. gold .. " (Lost " .. bet .. ")]" )
	self:DealerGuess( bet, "suit" )

	if( gold == 0 ) then
		self:EndGame()
	end

end

function Ace3:GuessCard(cmd)
	if( #(dealer) == 0 ) then
		self:Print( "You don't have a game currently running." )
		return
	end
	
	local betGold, guessedCard = string.split( " ", cmd )
	betGold = tonumber(betGold)
	if( not betGold or not guessedCard ) then
		self:Print( "Incorrect arguments." );
		return
	end

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
	
	if( betGold > gold ) then
		self:Print( "You can't bet more gold then you have." )
		return
	end
	
	bet = betGold
	
	for _, row in pairs(dealer) do
		if( row.card == card ) then
			gold = gold + ( bet * 1.5 )

			self:Print( "You guessed correctly, it was [" .. row.card .. " of " .. row.suit .. "] [Gold: " .. gold .. " (Gained " .. (bet * 1.5 ) .. ")]" )
			self:GenerateDealer()
			self:DealerGuess( bet * 1.5, "card" )
			return
		end
	end

	gold = math.abs( gold - bet )
	self:Print( "Wrong! [Gold: " .. gold .. " (Lost " .. bet .. ")]" )
	self:DealerGuess( bet, "card" )

	if( gold == 0 ) then
		self:EndGame()
	end
end

function Ace3:EndGame()
	self:Print( "Game Over!" )

	if( gold > 50 ) then
		self:Print( "You won " .. ( gold - 50 ) " gold! =D." )
	elseif( gold == 0 ) then
		self:Print( "You lost all of your gold =(." )
	else
		self:Print( "You lost " .. ( 50 - gold ) .. " gold =(." )
	end

	player = {}
	dealer = {}
	bet = 0
	gold = 0
end
