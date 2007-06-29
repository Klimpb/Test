--[[-------------------------------------------------------------------------
  Copyright (c) 2006-2007, Dongle Development Team
  All rights reserved.

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are
  met:

      * Redistributions of source code must retain the above copyright
        notice, this list of conditions and the following disclaimer.
      * Redistributions in binary form must reproduce the above
        copyright notice, this list of conditions and the following
        disclaimer in the documentation and/or other materials provided
        with the distribution.
      * Neither the name of the Dongle Development Team nor the names of
        its contributors may be used to endorse or promote products derived
        from this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
  A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
  OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
  THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
---------------------------------------------------------------------------]]
local major = "DongleStub"
local minor = tonumber(string.match("$Revision: 313 $", "(%d+)") or 1)

local g = getfenv(0)

if not g.DongleStub or g.DongleStub:IsNewerVersion(major, minor) then
	local lib = setmetatable({}, {
		__call = function(t,k) 
			if type(t.versions) == "table" and t.versions[k] then 
				return t.versions[k].instance
			else
				error("Cannot find a library with name '"..tostring(k).."'", 2)
			end
		end
	})

	function lib:IsNewerVersion(major, minor)
		local versionData = self.versions and self.versions[major]

		-- If DongleStub versions have differing major version names
		-- such as DongleStub-Beta0 and DongleStub-1.0-RC2 then a second
		-- instance will be loaded, with older logic.  This code attempts
		-- to compensate for that by matching the major version against
		-- "^DongleStub", and handling the version check correctly.

		if major:match("^DongleStub") then
			local oldmajor,oldminor = self:GetVersion()
			if self.versions and self.versions[oldmajor] then
				return minor > oldminor
			else
				return true
			end
		end

		if not versionData then return true end
		local oldmajor,oldminor = versionData.instance:GetVersion()
		return minor > oldminor
	end
	
	local function NilCopyTable(src, dest)
		for k,v in pairs(dest) do dest[k] = nil end
		for k,v in pairs(src) do dest[k] = v end
	end

	function lib:Register(newInstance, activate, deactivate)
		assert(type(newInstance.GetVersion) == "function",
			"Attempt to register a library with DongleStub that does not have a 'GetVersion' method.")

		local major,minor = newInstance:GetVersion()
		assert(type(major) == "string",
			"Attempt to register a library with DongleStub that does not have a proper major version.")
		assert(type(minor) == "number",
			"Attempt to register a library with DongleStub that does not have a proper minor version.")

		-- Generate a log of all library registrations
		if not self.log then self.log = {} end
		table.insert(self.log, string.format("Register: %s, %s", major, minor))

		if not self:IsNewerVersion(major, minor) then return false end
		if not self.versions then self.versions = {} end

		local versionData = self.versions[major]
		if not versionData then
			-- New major version
			versionData = {
				["instance"] = newInstance,
				["deactivate"] = deactivate,
			}
			
			self.versions[major] = versionData
			if type(activate) == "function" then
				table.insert(self.log, string.format("Activate: %s, %s", major, minor))
				activate(newInstance)
			end
			return newInstance
		end
		
		local oldDeactivate = versionData.deactivate
		local oldInstance = versionData.instance
		
		versionData.deactivate = deactivate
		
		local skipCopy
		if type(activate) == "function" then
			table.insert(self.log, string.format("Activate: %s, %s", major, minor))
			skipCopy = activate(newInstance, oldInstance)
		end

		-- Deactivate the old libary if necessary
		if type(oldDeactivate) == "function" then
			local major, minor = oldInstance:GetVersion()
			table.insert(self.log, string.format("Deactivate: %s, %s", major, minor))
			oldDeactivate(oldInstance, newInstance)
		end

		-- Re-use the old table, and discard the new one
		if not skipCopy then
			NilCopyTable(newInstance, oldInstance)
		end
		return oldInstance
	end

	function lib:GetVersion() return major,minor end

	local function Activate(new, old)
		-- This code ensures that we'll move the versions table even
		-- if the major version names are different, in the case of 
		-- DongleStub
		if not old then old = g.DongleStub end

		if old then
			new.versions = old.versions
			new.log = old.log
		end
		g.DongleStub = new
	end
	
	-- Actually trigger libary activation here
	local stub = g.DongleStub or lib
	lib = stub:Register(lib, Activate)
end

--[[
	$Id$

	License:
		This program is free software; you can redistribute it and/or
		modify it under the terms of the GNU General Public License
		as published by the Free Software Foundation; either version 2
		of the License, or (at your option) any later version.

		This program is distributed in the hope that it will be useful,
		but WITHOUT ANY WARRANTY; without even the implied warranty of
		MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
		GNU General Public License for more details.

		You should have received a copy of the GNU General Public License
		along with this program(see GPL.txt); if not, write to the Free Software
		Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

	Note:
		This AddOn's source code is specifically designed to work with
		World of Warcraft's interpreted AddOn system.
		You have an implicit licence to use this AddOn with these facilities
		since that is its designated purpose as per:
		http://www.fsf.org/licensing/licenses/gpl-faq.html#InterpreterIncompat
]]

local LIBRARY_VERSION_MAJOR = "nSideBar-0.1"
local LIBRARY_VERSION_MINOR = tonumber(string.match("$Revision 1981$", "(%d+)") or 1)

if not DongleStub then error(LIBRARY_VERSION_MAJOR .. " requires DongleStub.") end
if not DongleStub:IsNewerVersion(LIBRARY_VERSION_MAJOR, LIBRARY_VERSION_MINOR) then return end

RegisterCVar("nSideBarPos", "visible:10:right:180")

local lib = { private = {} };
local private = lib.private
local frame

function lib:GetVersion()
	return LIBRARY_VERSION_MAJOR, LIBRARY_VERSION_MINOR;
end

local function activate(new, old)
	if (old) then
		new.frame = old.frame
		frame = new.frame
		frame.private = new.private
		private = new.private
	else
		frame = CreateFrame("Frame", "", UIParent)
		new.frame = frame
		new.private = private
		frame.private = private

		frame:SetToplevel(true)
		frame:SetHitRectInsets(-3, -3, -3, -3)
		frame:SetBackdrop({
			bgFile = "Interface/Tooltips/UI-Tooltip-Background",
			edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
			tile = true, tileSize = 32, edgeSize = 16,
			insets = { left = 4, right = 4, top = 4, bottom = 4 }
		})
		frame:SetBackdropColor(0,0,0, 0.5)
		frame:EnableMouse(true)
		frame:SetScript("OnEnter", function(me) me.private.PopOut(me) end)
		frame:SetScript("OnLeave", function(me) me.private.PopBack(me) end)
		frame:SetScript("OnUpdate", function(me, dur) me.private.Popper(me,dur) end)
		frame.Tab = frame:CreateTexture()
		frame.Tab:SetTexture(0.98, 0.78, 0)
		frame.buttons = {}

		SLASH_NSIDEBAR1 = "/nsb"
		SLASH_NSIDEBAR2 = "/nsidebar"
		SlashCmdList["NSIDEBAR"] = function(msg)
			frame.private.CommandHandler(msg)
		end
	end
	new.ApplyLayout()
end


lib.Frame = frame

function private.PopOut(me, button)
	me.PopTimer = 0.15
	me.PopDirection = 1
end

function private.PopBack(me, button)
	me.PopTimer = 0.75
	me.PopDirection = -1
end

function private.MouseDown(me, button)
	if button then
		button.icon:SetTexCoord(0, 1, 0, 1)
	end
end

function private.MouseUp(me, button)
	if button then
		button.icon:SetTexCoord(0.075, 0.925, 0.075, 0.925)
	end
end

function private.Popper(me, duration)
	if me.PopDirection then
		me.PopTimer = me.PopTimer - duration
		if me.PopTimer < 0 then
			if me.PopDirection > 0 then
				-- Pop Out
				me.PopDirection = nil
				me:ClearAllPoints()
				me.isOpen = true
			else
				-- Pop Back
				me.PopDirection = nil
				me:ClearAllPoints()
				me.isOpen = false
			end
			lib.ApplyLayout(true)
		end
	end
end

function private.CommandHandler(msg)
	local configVar = GetCVar("nSideBarPos")
	local vis, wide, side, position = strsplit(":", configVar)

	local save = false
	if (not msg or msg == "") then msg = "help" end
	local a, b, c = strsplit(" ", msg:lower())
	if (a == "help") then
		DEFAULT_CHAT_FRAME:AddMessage("/nsb [ top | left | bottom | right ] [ <n> ]")
		DEFAULT_CHAT_FRAME:AddMessage("/nsb [ fadeout | nofade ]")
		DEFAULT_CHAT_FRAME:AddMessage("/nsb size [ <n> ]")
		return
	end
	if (a == "top") 
	or (a == "left") 
	or (a == "bottom")
	or (a == "right") then
		side = a
		save = true
		if (tonumber(b)) then
			a, b, c = b, nil, nil
		end
	end
	if (tonumber(a)) then
		position = math.min(math.abs(tonumber(a)), 1200)
		save = true
	end
	if (a == "fadeout" or a == "fade") then
		vis = "fadeout"
		save = true
	elseif (a == "nofade") then
		vis = "visible"
		save = true
	end
	if (a == "size") then
		if (tonumber(b)) then
			wide = math.floor(tonumber(b))
			if (wide < 1) then wide = 1 end
			save = true
		end
	end

	if (save) then
		SetCVar("nSideBarPos", strjoin(":", vis, wide, side, position))
		lib.ApplyLayout()
	end
end

function lib.AddButton(id, texture, priority)
	if not priority then priority = 200 end

	local button
	if not frame.buttons[id] then
		button = CreateFrame("Button", "", frame)
		button.frame = frame
		button:SetPoint("TOPLEFT", frame, "TOPLEFT", 0,0)
		button:SetWidth(30)
		button:SetHeight(30)
		button:SetScript("OnMouseDown", function (me) me.frame.private.MouseDown(me.frame, me) end)
		button:SetScript("OnMouseUp", function (me) me.frame.private.MouseUp(me.frame, me) end)
		button:SetScript("OnEnter", function (me) me.frame.private.PopOut(me.frame, me) end)
		button:SetScript("OnLeave", function (me) me.frame.private.PopBack(me.frame, me) end)
		button.icon = button:CreateTexture("", "BACKGROUND")
		button.icon:SetTexCoord(0.075, 0.925, 0.075, 0.925)
		button.icon:SetPoint("TOPLEFT", button, "TOPLEFT", 0,0)
		button.icon:SetWidth(30)
		button.icon:SetHeight(30)
		button.id = id
		frame.buttons[id] = button
	else
		button = frame.buttons[id]
	end
	button.icon:SetTexture(texture)
	button.priority = priority

	lib.ApplyLayout()
	return button
end

function lib.ApplyLayout(useLayout)
	local configVar = GetCVar("nSideBarPos")
	if not (lib.lastConfig and configVar == lib.lastConfig) then
		useLayout = false
	end

	local vis, wide, side, position = strsplit(":", configVar)
	position = math.abs(tonumber(position) or 180)
	wide = tonumber(wide)
	side = side:lower()

	if not lib.private.layout then
		lib.private.layout = {}
		useLayout = false
	end
	local layout = lib.private.layout

	if not useLayout then
		for i = 1, #layout do table.remove(layout) end
		for id, button in pairs(frame.buttons) do
			table.insert(layout, button)
		end
	
		if (#layout == 0) then
			frame:Hide()
			return
		end
		
		table.sort(layout, function (a, b)
			if (a.priority < b.priority) then
				return true
			elseif (a.id < b.id) then
				return true
			end
			return false
		end)
	end

	if (#layout == 0) then
		frame:Hide()
		return
	end
		
	local width = wide
	if (#layout < wide) then width = #layout end
	local height = math.floor((#layout - 1) / wide) + 1

	local distance = 9
	if (frame.isOpen) then
		distance = width * 32 + 10
		if (frame:GetAlpha() < 1) then
			UIFrameFadeIn(frame, 0.25, frame:GetAlpha(), 1)
		end
	elseif (vis ~= "visible") then
		if (frame:GetAlpha() > 0.2) then
			UIFrameFadeOut(frame, 1.5, frame:GetAlpha(), 0.2)
		end
	end

	frame:ClearAllPoints()
	if (side == "top") then
		frame:SetPoint("BOTTOMLEFT", UIParent, "TOPLEFT", position, -1*distance)
	elseif (side == "bottom") then
		frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", position, distance)
	elseif (side == "left") then
		frame:SetPoint("TOPRIGHT", UIParent, "TOPLEFT", distance, -1*position)
	elseif (side == "right") then
		frame:SetPoint("TOPLEFT", UIParent, "TOPRIGHT", -1*distance, -1*position)
	end

	if (useLayout) then return end

	frame.Tab:ClearAllPoints()
	if (side == "top" or side == "bottom") then
		frame:SetWidth(height * 32 + 10)
		frame:SetHeight(width * 32 + 18)
		if (side == "top") then
			frame.Tab:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 5, 5)
			frame.Tab:SetPoint("RIGHT", frame, "RIGHT", -5, 0)
		else
			frame.Tab:SetPoint("TOPLEFT", frame, "TOPLEFT", 5, -5)
			frame.Tab:SetPoint("RIGHT", frame, "RIGHT", -5, 0)
		end
		frame.Tab:SetHeight(3)
	else
		frame:SetWidth(width * 32 + 18)
		frame:SetHeight(height * 32 + 10)
		if (side == "right") then
			frame.Tab:SetPoint("TOPLEFT", frame, "TOPLEFT", 5, -5)
			frame.Tab:SetPoint("BOTTOM", frame, "BOTTOM", 0, 5)
		else
			frame.Tab:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
			frame.Tab:SetPoint("BOTTOM", frame, "BOTTOM", 0, 5)
		end
		frame.Tab:SetWidth(3)
	end
	frame:Show()
	
	local button
	for pos = 1, #layout do
		button = layout[pos]
		pos = pos - 1
		local row = math.floor(pos / wide)
		local col = pos % wide

		if (row == 0) then width = col end

		button:ClearAllPoints()
		if (side == "right") then
			button:SetPoint("TOPLEFT", frame, "TOPLEFT", col*32+10, 0-(row*32+5))
		elseif (side == "left") then
			button:SetPoint("TOPLEFT", frame, "TOPLEFT", col*32+5, 0-(row*32+5))
		elseif (side == "bottom") then
			button:SetPoint("TOPLEFT", frame, "TOPLEFT", row*32+5, 0-(col*32+10))
		elseif (side == "top") then
			button:SetPoint("TOPLEFT", frame, "TOPLEFT", row*32+5, 0-(col*32+5))
		end
	end
end

-- Register our library
DongleStub:Register(lib, activate)

