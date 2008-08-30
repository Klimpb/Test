BazaarLocals = {
	["No player named '(.+)' is currently playing."] = "No player named '(.+)' is currently playing.",

	-- API errors
	["Must call '%s' from a registered BazaarObj."] = "Must call '%s' from a registered BazaarObj.",
	["bad argument #%d to '%s' (%s expected, got %s)"] = "bad argument #%d to '%s' (%s expected, got %s)",
	["The addon '%s' is already registered to Bazaar."] = "The addon '%s' is already registered to Bazaar.",
	["The category key '%s' is already registered to '%s'."] = "The category key '%s' is already registered to '%s'.",
	["No addon with the name '%s' is loaded."] = "No addon with the name '%s' is loaded.",
	
	["Characters \\001-\\004 are reserved for comm handling."] = "Characters \\001-\\004 are reserved for comm handling.",
	
	-- Syncing
	["%s has requested data from the addon %s."] = "%s has requested data from the addon %s.",
	["Deny"] = "Deny",
	
	["%s is using a version of '%s' that does not support syncing of the categories %s."] = "%s is using a version of '%s' that does not support syncing of the categories %s.",
	["%s has auto denied your request due to being in combat, try again later."] = "%s has auto denied your request due to being in combat, try again later.",
	["%s does not have a version of '%s' that supports Bazaar."] = "%s does not have a version of '%s' that supports Bazaar.",
	["%s has manually denied your request for a sync."] = "%s has manually denied your request for a sync.",
	["%s has received an error when trying to pack the data to send."] = "%s has received an error when trying to pack the data to send.",

	["Successfully unpacked configuration data for '%s'.\n%s"] = "Successfully unpacked configuration data for '%s'.\n%s",
	["Sent ping request to %s."] = "Sent ping request to %s.",
	["Received ping data from %s."] = "Received ping data from %s.",
	["Request accepted from %s for '%s'! Waiting for data."] = "Request accepted from %s for '%s'! Waiting for data.",
	["Receiving data..."] = "Receiving data...",
	
	-- Sync errors
	["Unable to package data for '%s' to send to %s, cancelled sync."] = "Unable to package data for '%s' to send to %s, cancelled sync.",
	["User %s attempted to request configuration for the addon '%s', denied it due to being in combat."] = "User %s attempted to request configuration for the addon '%s', denied it due to being in combat.",
	["User %s attempted to request a bad configuration category for the addon '%s', denied request."] = "User %s attempted to request a bad configuration category for the addon '%s', denied request.",
	
	["Failed to unpack and save data for '%s'.\n%s"] = "Failed to unpack and save data for '%s'.\n%s",
	
	["It appears that %s is no longer online."] = "It appears that %s is no longer online.",
	
	-- GUI
	["Ping"] = "Ping",
	["Request"] = "Request",
	["Enter the player name of who you want to get data for '%s' from."] = "Enter the player name of who you want to get data for '%s' from.",
	
	["Users who have data for this addon available."] = "Users who have data for this addon available.",
	
	["Nobody is known to have data for this addon, you can still try by hitting the request button."] = "Nobody is known to have data for this addon, you can still try by hitting the request button.",
	["Addon configuration syncing with other users who use this and have an addon that supports Bazaar."] = "Addon configuration syncing with other users who use this and have an addon that supports Bazaar.",
	["%s%d|r |cffffffffusers|r"] = "%s%d|r |cffffffffusers|r",
	["%s%d|r |cffffffffuser|r"] = "%s%d|r |cffffffffuser|r",
	["No users"] = "No users",
	
	["Choose the categories of configuration to sync from %s for '%s'."] = "Choose the categories of configuration to sync from %s for '%s'.",
	["Sent addon configuration sync request to %s."] = "Sent addon configuration sync request to %s.",
	
	["Closing this frame will not mess up any syncing or requests going on, you just won't get any updates on the progress until you open it again."] = "Closing this frame will not mess up any syncing or requests going on, you just won't get any updates on the progress until you open it again.",
	
	["Finished"] = "Finished",
	
	["Request Configuration"] = "Request Configuration",
	["Select All"] = "Select All",
	["Unselect All"] = "Unselect All",
}