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

	for line in io.lines("LibStub.lua") do
		ofile:write(line .. "\n")
	end

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
