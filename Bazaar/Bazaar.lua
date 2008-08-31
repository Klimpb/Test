Bazaar = {}

local L = BazaarLocals

local IS_DEBUG = false
local FIRST_MULTIPART, NEXT_MULTIPART, LAST_MULTIPART = "BAZRD\001", "BAZRD\002", "BAZRD\003"
local Comm, Serailizer, playerName

local methods = {"RegisterCategory", "RegisterReceiveHandler", "RegisterSendHandler"}

local activeSync = {categories = {}}
local availableAddons = {}
local tempAddons, tempCategories = {}, {}
local registeredAddons = {}
local lookup = {}

function Bazaar:OnInitialize()
	playerName = UnitName("player")

	-- So we can watch for progress
	self:RegisterEvent("CHAT_MSG_ADDON")

	-- Load DB if needed
	BazaarDB = BazaarDB or { discovery = true, inCombat = false, errors = true }
	self.db = BazaarDB
	
	-- Setup our comm and such things
	Serializer = LibStub("AceSerializer-3.0")
	Comm = LibStub("AceComm-3.0")
	Comm.RegisterComm(self, "BAZR")
	
	-- We got serialized configuration data
	Comm.RegisterComm(self, "BAZRD", function(prefix, msg, type, sender)
		if( prefix == "BAZRD" and activeSync.name and activeSync.from == sender and type == "WHISPER" ) then
			Bazaar:ReceivedData(msg, sender)
		end
	end)
	
	-- NOTE TO SELF: Remove this later
	if( playerName == "Mayen" or playerName == "Amarand" ) then
		IS_DEBUG = true
	end
	
	-- So the GUI can access data
	self.registeredAddons = registeredAddons
	self.availableAddons = availableAddons
	self.lookup = lookup
end

function Bazaar:CompileAddons(...)
	for k in pairs(tempAddons) do tempAddons[k] = nil end
	
	for i=1, select("#", ...) do
		tempAddons[select(i, ...)] = true
	end
	
	return tempAddons
end

function Bazaar:CompileCategories(...)
	for k in pairs(tempCategories) do tempCategories[k] = nil end
	
	for i=1, select("#", ...) do
		tempCategories[select(i, ...)] = true
	end
	
	return tempCategories
end

function Bazaar:OnCommReceived(prefix, msg, type, sender)
	if( sender == playerName and not IS_DEBUG ) then
		return
	end
	
	local dataType, data = string.match(msg, "([^:]+)%:(.+)")
	if( not dataType and not data ) then
		dataType = msg
	end
	
	-- Someone requested we get data
	if( dataType == "PING" ) then
		-- If we don't have discovery on, then ignore pings that aren't whispers
		if( type ~= "WHISPER" and not self.db.discovery ) then
			return
		end
		
		self:SendPong(data and self:CompileAddons(string.split("\001", data)) or nil, type, sender)
	
	-- Got a pong about user data, do we need to restrict this to only people who asked for a ping?
	elseif( dataType == "PONG" ) then
		self:ReceivePong(sender, string.split("\001", data))
	
	-- User is requesting data from us, enforce this as a WHISPER
	elseif( dataType == "REQUEST" and data and type == "WHISPER" ) then
		local name, data = string.split("\001", data)
		self:ReceivedRequest(name, self:CompileCategories(string.split("\004", data)), sender)
	
	-- Our request was accepted!
	elseif( dataType == "ACCEPT" and activeSync.name ) then
		self:RequestAccepted(tonumber(data), sender)
	
	-- We were told to start the sync
	elseif( dataType == "START" and activeSync.pendingData and activeSync.from == sender and type == "WHISPER" ) then
		self:SendData(sender)
	
	-- Our request was denied
	elseif( dataType == "DENY" and data and type == "WHISPER" ) then
		self:RequestDenied(data, sender)		
	end
end

-- AceComm-3.0 doesn't give us a method for checking multipart data as it comes in so will watch the prefixes and the event to figure it out
function Bazaar:CHAT_MSG_ADDON(prefix, msg, type, sender)
	if( type == "WHISPER" and activeSync.name ) then
		-- First message total should be set to the length of what we got
		if( prefix == FIRST_MULTIPART ) then
			activeSync.received = string.len(msg)
			self.GUI:UpdateStatus("receiving", L["Receiving data..."])
			self.GUI:UpdateProgress(activeSync.received, activeSync.total)
			
		-- Sending data, so update total
		elseif( prefix == NEXT_MULTIPART or prefix == LAST_MULTIPART ) then
			activeSync.received = activeSync.received + string.len(msg)
			self.GUI:UpdateProgress(activeSync.received, activeSync.total)
		end
	end
end

-- Check for a failed whisper while syncing
ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", function(msg)
	local name = string.match(msg, L["No player named '(.+)' is currently playing."])
	if( name and activeSync.from and string.lower(activeSync.from) == string.lower(name) ) then
		activeSync.addon = nil
		activeSync.from = nil
		
		Bazaar.GUI:TriggerError(string.format(L["It appears that %s is no longer online."], name))
		return true
	end
	
	return false
end)

-- COMM HANDLING
-- Allow us to call a function without it stopping our execution
local function safecall(func, ...)
	local success, result = pcall(func, ...)
	if( not success ) then
		geterrorhandler()(result)
		return false, result
	end
	
	return true, result
end

-- Received a full configuration to unserialize and process
function Bazaar:ReceivedData(data, sender)
	local obj = lookup[activeSync.name]
	local result, msg
	
	-- Unpack and set data
	local success, data = Serializer:Deserialize(data)
	
	-- Save it if we successfully serialized
	if( success ) then
		if( obj.receiveHandler and type(obj.receiveFunc) == "string" ) then
			result, msg = safecall(obj.receiveHandler[obj.receiveFunc], obj.receiveHandler, data, activeSync.categories)	
		elseif( type(obj.receiveFunc) == "string" ) then
			result, msg = safecall(getglobal(obj.receiveFunc), data, activeSync.categories)
		elseif( type(obj.receiveFunc) == "function" ) then
			result, msg = safecall(obj.receiveFunc, data, activeSync.categories)
		end
	else
		msg = data
	end
	
	-- Did we manage to unpack it?
	if( result ) then
		self.GUI:UpdateStatus("finished", string.format(L["Successfully unpacked configuration data for '%s'.\n%s"], activeSync.name, tostring(msg)))
	else
		self.GUI:UpdateStatus("finished", string.format(L["Failed to unpack and save data for '%s'.\n%s"], activeSync.name, tostring(msg)))
	end
	
	-- Done unpacking and everything
	activeSync.name = nil
	activeSync.from = nil

	self.GUI:UpdateProgress(activeSync.total, activeSync.total)
	self.GUI:Finished()
end

-- Sending comm messages
function Bazaar:SendData(sender)
	Bazaar:SendCommMessage(string.format("DATA:%s", activeSync.pendingData), "WHISPER", sender, "BAZRD")
	activeSync.pendingData = nil
end

function Bazaar:AcceptRequest(sender)
	-- Grab the data from the addon to serialize and send
	local obj = lookup[activeSync.name]
	local data, result
	
	if( obj.sendHandler and type(obj.sendFunc) == "string" ) then
		result, data = safecall(obj.sendHandler[obj.sendFunc], obj.sendHandler, activeSync.categories)	
	elseif( type(obj.sendFunc) == "string" ) then
		result, data = safecall(getglobal(obj.sendFunc), activeSync.categories)
	elseif( type(obj.sendFunc) == "function" ) then
		result, data = safecall(obj.sendFunc, activeSync.categories)
	end
	
	-- The safecall failed, or bad data was given
	if( not result or not data ) then
		if( self.db.errors ) then
			self:Print(string.format(L["Unable to package data for '%s' to send to %s, cancelled sync."], activeSync.addon, sender))
		end
		
		activeSync.name = nil
		Bazaar:SendCommMessage("DENY:error", "WHISPER", sender)
		return
	end
		
	-- Prepare the data for send
	activeSync.pendingData = Serializer:Serialize(data)
	activeSync.from = sender
		
	-- Send off that we accepted + the total size of what we're sending
	Bazaar:SendCommMessage(string.format("ACCEPT:%s", string.len(activeSync.pendingData)), "WHISPER", sender)
end

function Bazaar:SendRequest(addon, sendTo, categories)
	activeSync.name = addon
	
	for k in pairs(activeSync.categories) do activeSync.categories[k] = nil end
	
	local cats = ""
	for key in pairs(categories) do
		activeSync.categories[key] = true
		
		if( cats == "" ) then
			cats = key
		else
			cats = cats .. "\004" .. key
		end
	end
	
	self:SendCommMessage(string.format("REQUEST:%s\001%s", addon, cats), "WHISPER", sendTo)
end

function Bazaar:SendPing(addon, type, sendTo, isSync)
	if( isSync ) then
		activeSync.from = sendTo
	end
	
	if( addon ) then
		self:SendCommMessage(string.format("PING:%s", addon), type, sendTo)
	else
		self:SendCommMessage("PING", type, sendTo)
	end
end

-- PONG HANDLER
-- \001 = Separates addons
-- \002 = Separates the addon from the category info
-- \003 = Seperates the category key from the category name
-- \004 = Seperates each category key/name combo from the next
-- addonA\002general\003General\004foo\003Foo\001addonB\002apple\003Apple
function Bazaar:SendPong(addons, distribution, sender)
	local msg = ""
	for name in pairs(lookup) do
		if( type(name) == "string" and ( not addons or addons[name] ) and lookup[name].hasCategories ) then
			if( msg == "" ) then
				msg = name .. "\002"
			else
				msg = msg .. "\001" .. name .. "\002"
			end
			
			-- Load the categories
			local ran
			for key, displayName in pairs(lookup[name].categories) do
				if( ran ) then
					msg = msg .. "\004"
				end

				msg = msg .. key .. "\003" .. displayName
				ran = true
			end
		end
	end
	
	self:SendCommMessage(string.format("PONG:%s", msg), distribution, sender)
end

-- Got a response to our ping
function Bazaar:LoadCategories(addon, ...)
	-- Reset it in case it's changed for this person
	for k in pairs(addon) do
		addon[k] = nil
	end
	
	for i=1, select("#", ...) do
		local key, name = string.split("\003", (select(i, ...)))
		addon[key] = name
	end
end

function Bazaar:ReceivePong(sender, ...)
	availableAddons[sender] = availableAddons[sender] or {}
	
	for i=1, select("#", ...) do
		local line = select(i, ...)
		local name, data = string.split("\002", line)
		
		availableAddons[sender][name] = availableAddons[sender][name] or {}
		self:LoadCategories(availableAddons[sender][name], string.split("\004", data))
	end

	self.GUI:UpdateStatus("pong", string.format(L["Received ping data from %s."], sender))
end

-- SYNC HANDLER
-- Denial types
-- noaddon = Obviously, we have no addon registered
-- incombat = In combat, we have auto deny on
-- badcategory\001<key1>\002<key2> = We asked for categor(y/ies) they don't have
-- manual = The user manually rejected it
-- error = An error happened when trying to grab data to send
function Bazaar:ReceivedRequest(addon, categories, sender)
	-- Bad addon passed, deny it silently
	if( not lookup[addon] ) then
		self:SendCommMessage("DENY:noaddon", "WHISPER", sender)
		return
	end
	
	-- In combat, and we don't want to allow requests in combat
	if( InCombatLockdown() and self.db.inCombat ) then
		if( self.db.errors ) then
			self:Print(string.format(L["User %s attempted to request configuration for the addon '%s', denied it due to being in combat."], sender, addon))
		end
		
		self:SendCommMessage("DENY:incombat", "WHISPER", sender)
		return
	end
	
	-- Verify that the categories exists
	local bad = ""
	for key in pairs(categories) do
		if( not lookup[addon].categories[key] ) then
			if( bad == "" ) then
				bad = key
			else
				bad = bad .. "\002" .. key
			end
		end
	end
	
	if( bad ~= "" ) then
		if( self.db.errors ) then
			self:Print(string.format(L["User %s attempted to request a bad configuration category for the addon '%s', denied request."], sender, addon))
		end
		
		self:SendCommMessage(string.format("DENY:badcategory\001%s", bad), "WHISPER", sender)
		return
	end
	
	-- Now ask if the user wants to do the request
	if( not StaticPopupDialogs["BAZAAR_DATA"] ) then
		StaticPopupDialogs["BAZAAR_DATA"] = {
			button1 = ACCEPT,
			button2 = L["Deny"],
			OnAccept = function(data)
				Bazaar:AcceptRequest(data)
			end,
			OnCancel = function(data)
				activeSync.name = nil
				Bazaar:SendCommMessage("DENY:manual", "WHISPER", data)
			end,
			timeout = 30,
			exclusive = 1,
			whileDead = 1,
			hideOnEscape = 1
		}
	end
	
	StaticPopupDialogs["BAZAAR_DATA"].text = string.format(L["%s has requested data from the addon %s."], sender, addon)
	local dialog = StaticPopup_Show("BAZAAR_DATA")
	if( dialog ) then
		dialog.data = sender
		
		activeSync.name = addon
		for k in pairs(activeSync.categories) do
			activeSync.categories[k] = nil
		end
		
		for key in pairs(categories) do
			activeSync.categories[key] = true
		end
	end
end

-- Our request was denied for some reason
function Bazaar:CompileErrors(addon, ...)
	local categories = ""
	for i=1, select("#", ...) do
		local cat = select(i, ...)
		
		if( categories == "" ) then
			categories = lookup[addon].categories[cat] or cat
		else
			categories = categories .. ", " .. lookup[addon].categories[cat] or cat
		end
	end
	
	return categories
end

function Bazaar:RequestDenied(reason, sender)
	-- Nothing going on anymore
	activeSync.name = nil
	activeSync.from = nil
		
	if( reason == "manual" ) then
		self.GUI:TriggerError(string.format(L["%s has manually denied your request for a sync."], sender))
	elseif( reason == "noaddon" ) then
		self.GUI:TriggerError(string.format(L["%s does not have a version of '%s' that supports Bazaar."], sender, activeSync.name))
	elseif( reason == "incombat" ) then
		self.GUI:TriggerError(string.format(L["%s has auto denied your request due to being in combat, try again later."], sender))
	elseif( reason == "error" ) then
		self.GUI:TriggerError(string.format(L["%s has received an error when trying to pack the data to send."], sender))
	elseif( string.match(reason, "^badcategory") ) then
		local reason, data = string.split("\001", reason)
		self.GUI:TriggerError(string.format(L["%s is using a version of '%s' that does not support syncing of the categories %s."], sender, activeSync.name, self:CompileErrors(activeSync.name, string.split("\002", data))))
	end
end

-- Our request was accepted, get ready to start syncing
function Bazaar:RequestAccepted(total, sender)
	self.GUI:UpdateStatus("accepted", string.format(L["Request accepted from %s for '%s'! Waiting for data."], sender, activeSync.name))
	
	-- Tad silly but we add an extra 5% so we can add a status for unpacking data in case it's slow
	activeSync.total = total * 1.05
	activeSync.from = sender
	
	self:SendCommMessage("START", "WHISPER", sender)
end

-- REGISTERING ADDONS
local function assert(level,condition,message)
	if( not condition ) then
		error(message,level)
	end
end

local function argcheck(value, num, ...)
	if( type(num) ~= "number" ) then
		error(L["bad argument #%d to '%s' (%s expected, got %s)"]:format(2, "argcheck", "number", type(num)), 1)
	end

	for i=1,select("#", ...) do
		if type(value) == select(i, ...) then return end
	end

	local types = strjoin(", ", ...)
	local name = string.match(debugstack(2,2,0), ": in function [`<](.-)['>]")
	error(L["bad argument #%d to '%s' (%s expected, got %s)"]:format(num, name, types, type(value)), 3)
end

-- Register an addon with Bazaar
function Bazaar:RegisterAddOn(name)
	argcheck(name, 1, "string")
	assert(3, not lookup[name], string.format(L["The addon '%s' is already registered to Bazaar."], name))
	assert(3, IsAddOnLoaded(name) == 1, string.format(L["No addon with the name '%s' is loaded."], name))
	
	local obj = {categories = {}, name = name}
	
	table.insert(registeredAddons, name)
	lookup[name] = obj
	lookup[obj] = true
	
	for _, func in pairs(methods) do
		obj[func] = Bazaar[func]
	end
	
	return obj
end

-- Register a new configuration category
function Bazaar.RegisterCategory(obj, key, name)
	argcheck(key, 2, "string")
	argcheck(name, 3, "string")
	assert(3, lookup[obj], string.format(L["Must call '%s' from a registered BazaarObj."], "RegisterCategory"))
	assert(3, not obj.categories[key], string.format(L["The category key '%s' is already registered to '%s'."], key, obj.name))
	assert(3, not string.match(key, "[\001-\004]"), L["Characters \\001-\\004 are reserved for comm handling."])
	assert(3, not string.match(name, "[\001-\004]"), L["Characters \\001-\\004 are reserved for comm handling."])
	
	obj.hasCategories = true
	obj.categories[key] = name
end

-- Register a handler/function to be used when we receive data
function Bazaar.RegisterReceiveHandler(obj, handler, func)
	argcheck(handler, 2, "table", "function", "string")
	argcheck(func, 3, "string", "nil")
	assert(3, lookup[obj], string.format(L["Must call '%s' from a registered BazaarObj."], "RegisterReceiveHandler"))
	
	if( func ) then
		obj.receiveHandler = handler
		obj.receiveFunc = func
	else
		obj.receiveFunc = handler
	end
end

-- Register a handler/function to give us data to send
function Bazaar.RegisterSendHandler(obj, handler, func)
	argcheck(handler, 2, "table", "function", "string")
	argcheck(func, 3, "string", "nil")
	assert(3, lookup[obj], string.format(L["Must call '%s' from a registered BazaarObj."], "RegisterSendHandler"))
	
	if( func ) then
		obj.sendHandler = handler
		obj.sendFunc = func
	else
		obj.sendFunc = handler
	end
end

-- EVENT HANDLER
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, ...)
	if( event == "ADDON_LOADED" ) then
		if( select(1, ...) == "Bazaar" ) then
			self:UnregisterEvent("ADDON_LOADED")
			Bazaar:OnInitialize()
		end
		return
	end
	
	Bazaar[event](Bazaar, ...)
end)

function Bazaar:RegisterEvent(event)
	frame:RegisterEvent(event)
end

function Bazaar:UnregisterEvent(event)
	frame:UnregisterEvent(event)
end

-- Misc
function Bazaar:Print(msg)
	DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99Bazaar|r: " .. msg)
end

function Bazaar:SendCommMessage(msg, type, target, prefix)
	Comm:SendCommMessage(prefix or "BAZR", msg, type, target)
end