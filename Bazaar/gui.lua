local GUI = {}

function GUI:TriggerError(msg)
end

function GUI:UpdateProgress(received, total)
end

function GUI:UpdateStatus(text)
	ChatFrame1:AddMessage(text)
end

function GUI:Finished()

end

if( Bazaar ) then
	Bazaar.GUI = GUI
end