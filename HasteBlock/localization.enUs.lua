local debug = false
TimeBlockLocals = setmetatable({
	['General'] = true,
	['abbreviated weekday name (e.g., Wed)'] = true,
	['full weekday name (e.g., Wednesday)'] = true,
	['abbreviated month name (e.g., Sep)'] = true,
	['full month name (e.g., September)'] = true,
	['date and time (e.g., 09/16/98 23:48:10)'] = true,
	['day of month (16) [01-31]'] = true,
	['hour, using a 24-hour clock (23) [00-23]'] = true,
	['hour, using a 12-hour clock (11) [01-12]'] = true,
	['minute (48) [00-59]'] = true,
	['month (09) [01-12]'] = true,
	['either "am" or "pm" (pm)'] = true,
	['second (10) [00-61]'] = true,
	['weekday (3) [0-6 = Sunday-Saturday]'] = true,
	['date (e.g., 09/16/98)'] = true,
	['time (e.g., 23:48:10)'] = true,
	['full year (1998)'] = true,
	['two-digit year (98) [00-99]'] = true,
	['the character "%"'] = true,
	['General Options'] = true,
	['Show in combat'] = true,
	['Lock the clock'] = true,
	['Append server time'] = true,
	['Scale'] = true,
	['Background Alpha'] = true,
	['Date formats'] = true,
	['Format'] = true,
	['Description'] = true,
	['Check this to show the clock in combat'] = true,
	['Check this to lock the clock in place'] = true,
	['Check this to append the server time to the clock'] = true,
	['Use this slider to change the background alpha of the clock'] = true,
	['Clock Scale'] = true,
	['Use this slider to change the scale of the clock'] = true,
	['Time format'] = true,
	['Set the format to the date command to display on the clock'] = true,
}, {__index = function(self, key)
	if key then
		rawset(self, key, key)
		if debug then
			ChatFrame1:AddMessage("Missing "..tostring(key))
		end
		return key
	else
		return ''
	end
end})

