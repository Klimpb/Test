local major = "SECore-Alpha0"
local minor = tonumber(string.match("$Revision: 604 $", "(%d+)") or 1)

assert(LibStub, string.format("%s requires LibStub.", major))

local SEInstance, oldRevision = LibStub:NewLibrary(major, minor)
if( SEInstance ) then
	local SECore = {}

	local invalidArg = "Invalid argument #%d %s expected, got %s in '%s'."
	local embeds = {}
	local registered = {}
	local row = {}
		
	-- Embed
	function SECore:Embed(lib)
		lib["RegisterCallback"] = SECore["RegisterCallback"]
		lib["UnregisterCallback"] = SECore["UnregisterCallback"]
		table.insert(embeds, lib)
	end

	-- Register the callback name, the handler and the func to call
	function SECore:RegisterCallback(name, handler, func)
		-- Verify
		if( type(name) ~= "string" ) then
			error(string.format(invalidArg, 1, "string", type(name), "RegisterCallback"), 3)
		elseif( type(handler) ~= "string" and type(handler) ~= "function" and type(handler) ~= "table" ) then
			error(string.format(invalidArg, 2, "string, function or table", type(handler), "RegisterCallback"), 3)
		elseif( type(func) ~= "string" and type(func) ~= "function" and type(func) ~= "nil" ) then
			error(string.format(invalidArg, 3, "string, function or nil", type(handler), "RegisterCallback"), 3)
		end
		
		-- If the third arg is nil, then "handler" is the function
		if( not func ) then
			func = handler
			handler = nil
		end

		-- Make sure it's not already registered
		for _, row in pairs(registered) do
			if( row.name == name and row.func == row.func ) then
				if( ( row.handler and row.handler == handler ) or not row.handler ) then
					return
				end
			end
		end
		
		-- Add
		row.name = name
		row.handler = handler
		row.func = func
		table.insert(registered, row)
	end
	
	-- Unregister!
	function SECore:UnregisterCallback(name, handler, func)
		-- Verify
		if( type(name) ~= "string" ) then
			error(string.format(invalidArg, 1, "string", type(name), "UnregisterCallback"), 3)
		elseif( type(handler) ~= "string" and type(handler) ~= "function" and type(handler) ~= "table" ) then
			error(string.format(invalidArg, 2, "string, function or table", type(handler), "UnregisterCallback"), 3)
		elseif( type(func) ~= "string" and type(func) ~= "function" and type(func) ~= "nil" ) then
			error(string.format(invalidArg, 3, "string, function or nil", type(handler), "UnregisterCallback"), 3)
		end
		
		-- If the third arg is nil, then "handler" is the function
		if( not func ) then
			func = handler
			handler = nil
		end

		-- Now unregister
		for i=#(registered), 1, -1 do
			local row = registered[i]
			if( row.name == name and row.func == row.func ) then
				if( ( row.handler and row.handler == handler ) or not row.handler ) then
					table.remove(registered, i)
				end
			end
		end
	end
	
	-- Trigger everything
	function SECore:TriggerCallback(name, ...)
		DEFAULT_CHAT_FRAME:AddMessage(name .. ": " .. table.concat({...}, ", ")
		
		for _, row in pairs(registered) do
			if( row.name == name ) then
				if( row.handler ) then
					row.handler[row.func](row.handler, ...)
				else
					row.func(...)		
				end
			
			end
		end
	end
	
	-- Upgrade, or setup vars needed for it
	if( oldRevision ) then
		SECore.registered = SEInstance.registered or registered
	else
		SECore.registered = registered
	end

	-- Upgrade any embeds
	for _, lib in pairs(embeds) do
		lib["RegisterCallback"] = SECore["RegisterCallback"]
		lib["UnregisterCallback"] = SECore["UnregisterCallback"]
	end
	
	-- Make it live
	for k, v in pairs(SECore) do
		SEInstance[k] = v
	end
end