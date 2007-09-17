local license = [=[--[[-------------------------------------------------------------------------
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
---------------------------------------------------------------------------]]]=]

-- Determine the platform
local platform
local copy = "cp"
local sep = "/"

if package.config:match("\\\n;\n%?\n!\n-") then
    -- Win32
    platform = "win32"
    copy = "copy"
    sep = "\\"
elseif package.config:match("/\n;\n%?\n!\n-") then
    -- Unix-ish
    platform = "unix"
    copy = "cp"
    sep = "/"
end

print("* Beginning build for HousingAuthority")
print("* Updating working copy")
os.execute("svn update")

print("* Determining latest revision")
local result = io.popen("svn update"):read("*all")
local rev = result:match("(%d+)")

function buildFile(dirname, filename)
	print("* Checking for leaked globals in " .. filename)
	os.execute("luac -p -l \""..filename.."\" | grep SETGLOBAL")

	print("* Building " .. filename)
	local ofile = io.open(dirname .. sep .. filename, "w")

	local section = [=[
--[[-------------------------------------------------------------------------
  %s
---------------------------------------------------------------------------]]]=]

	local count = 0
	for line in io.lines("LibStub.lua") do
		count = count + 1
		if count > 1 then
			ofile:write(line .. "\n")
		end
	end
	
	ofile:write("\n" .. license .. "\n")
	ofile:write("\n"..string.format(section, "Begin Library Implementation").."\n")

	for line in io.lines(filename) do
        ofile:write(line .. "\n")
	end
	ofile:close()
end

function copyFile(dirname, filename)
	print("* Copying " .. filename)
	local ofile = io.open(dirname .. sep ..filename, "w")
	local buffer = io.open(filename, "r"):read("*all")
	ofile:write(buffer)
	ofile:close()
end

-- Standalone copy
print("* Making HousingAuthority library - revision " .. rev)
print("Making directory HousingAuthority")
os.execute("mkdir HousingAuthority")

buildFile("HousingAuthority", "HousingAuthority.lua")

print("* Dumping a changelog")
os.execute("svn log > HousingAuthority"..sep.."changelog.txt")
os.execute("svn -m \"*Creating directory for HousingAutority-r" .. rev .. "\ mkdir https://shadowed-wow.googlecode.com/svn/tags/HousingAuthority-r" .. rev)
os.execute("svn -m \"* Importing HousingAuthority-r"..rev.." addon\" import HousingAuthority https://shadowed-wow.googlecode.com/svn/tags/HousingAuthority-r" .. rev)
