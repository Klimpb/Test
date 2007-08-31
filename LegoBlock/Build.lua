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

-- This script is used to "build" a tagged version of LegoBlock.  It places this
-- new version in a subdirectory of the current directory, which is expected
-- to be the LegoBlock svn directory.

io.write("Version Name (LegoBlock-X.Y.Z-Beta): ")
local version = io.read()

print("Attempting to build LegoBlock version " .. version)

print("* Updating working copy")
os.execute("svn update")

print("* Determining latest revision")
local result = io.popen("svn update"):read("*all")
local rev = result:match("(%d+)")

print("* Making new directory")
os.execute("mkdir " .. version)

function buildFile(filename)
	print("* Checking for leaked globals in " .. filename)
	os.execute("luac -p -l \""..filename.."\" | grep SETGLOBAL")

	print("* Building " .. filename)
	local ofile = io.open(version .. "/" .. filename, "w")

	local section = [=[
--[[-------------------------------------------------------------------------
  %s
---------------------------------------------------------------------------]]]=]

	ofile:write(license .. "\n")

	local count = 0
	for line in io.lines("DongleStub.lua") do
		count = count + 1
		if count > 5 then
			ofile:write(line .. "\n")
		end
	end

    ofile:write("\n"..string.format(section, "Begin Library Implementation").."\n")

	for line in io.lines(filename) do
		ofile:write(line .. "\n")
	end
	ofile:close()
end

function copyFile(filename)
	print("* Copying " .. filename)
	local ofile = io.open(version .."/"..filename, "w")
	local buffer = io.open(filename, "r"):read("*all")
	ofile:write(buffer)
	ofile:close()
end

buildFile("LegoBlock.lua")
copyFile("LegoBlock.toc")

print("* Dumping a changelog")
-- Try with python first
local err = os.execute("svn log https://legos-wow.googlecode.com/svn -v --xml | python svn2log.py -s -O -H -p '/(branches/[^/]+|trunk)/' -o " .. version .. "/" .. "changelog.txt")
-- Use a straight svn log dump
if err ~= 0 then
	print("Failed when using svn2log.py, dumping a basic changelog instead")
	os.execute("svn log https://legos-wow.googlecode.com/svn/trunk/LegoBlock/LegoBlock.lua > " .. version .. "/" .. "changelog.txt")
end

print("\n\nNow you should be able to import this tab by doing:")
print(string.format("svn import %s/ https://legos-wow.googlecode.com/svn/tags/%s/%s-r%s/", version, version, version, rev))
