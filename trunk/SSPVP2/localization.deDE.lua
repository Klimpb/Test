if( GetLocale() ~= "deDE" ) then
	return
end

SSPVPLocals = setmetatable({
	-- Battlefield names
	["Warsong Gulch"] = "Kriegshymnenschlucht",
	["Arathi Basin"] = "Arathibecken",
	["Alterac Valley"] = "Alteractal",
	["Eye of the Storm"] = "Auge des Sturms",
	

	["Blade's Edge Arena"] = "Arena des Schergrats",
	["Nagrand Arena"] = "Arena von Nagrand",
	["Ruins of Lordaeron"] = "Ruinen von Lordaeron",
	
	["Rated"] = "Gewertet",
	["Skirmish"] = "Nicht gewertet",
	["Arena"] = "Arena",
	["All Arenas"] = "Alle Arenen",
	["%s (%dvs%d)"] = "%s (%dvs%d)",
	["Rated Arena"] = "Gewertete Arena",
	["Skirmish Arena"] = "Nicht gewertete Arena",

	["You are now in the queue for %s Arena (%dvs%d)."] = "Du bist jetzt in der Warteschlange f\195\188r %s Arena (%dvs%d).",
	["You are now in the queue for %s."] = "Du bist jetzt in der Warteschlange f\195\188r %s.",
	
	["Higher priority battlefield ready, auto joining %s in %d seconds."] = "Schlachtfeld mit h\195\182herer Priorit\195\164t gefunden, Auto-Beitreten zu %s in %d Sekunden.",
	["You're current activity is a higher priority then %s, not auto joining."] = "Ihr macht gerade etwas mit h\195\182herer Priorit\195\164t als %s, Auto-Beitreten deaktiviert.",
	
	["%s %d points (%d rating)"] = "%s %d Punkte (%d Wertung)",
	
	["You are about to leave the active or queued arena %s (%dvs%d), are you sure?"] = "Ihr seid gerade dabei, die aktive oder angemeldete Arena %s (%d vs %d) zu verlassen, seid Ihr sicher?",
	["You are about to leave the active or queued battleground %s, are you sure?"] = "Ihr seid gerade dabei, das aktive oder angemeldete Schlachtfeld %s zu verlassen, seid Ihr sicher?",
	
	["Horde"] = "Horde",
	["Alliance"] = "Allianz",
	["Screenshot saved as %s."] = "Screenshot gespeichert als %s.",
	
	["(L) %s"] = "(L) %s",
	["Rating"] = "Wertung",
	
	["Releasing..."] = "Freilassen...",
	["Using %s..."] = "Benutze %s...",
	
	["Starting: %s"] = "Beginnt in: %s",
	
	["the raid group.$"] = "Die Schlachtgruppe.$",
	
	["The"] = "Die",
	
	["Alliance"] = "Allianz",
	["Horde"] = "Horde",
	
	["[%s] %s: %s"] = "[%s] %s: %s",
	
	["Unavailable"] = "nicht vorhanden",
	["<1 Min"] = "<1 Min",
	["Join Suspended"] = "Beitritt aufgeschoben",
	["Joining"] = "Beitritt",
	["(.+) Mark of Honor"] = "(.+) Ehrenmarke",
	["%s |cffffffff(%dvs%d)|r"] = "%s |cffffffff(%dvs%d)|r",
	["Flag Respawn: %s"] = "Flaggen-Respawn: %s",
	
	-- Mover
	["PvP Objectives Anchor"] = "PvP Ziele Anker",
	["Score Objectives Anchor"] = "Ergebnis Objekte Anker",
	["Left Click + Drag to move the frame, Right Click + Drag to reset it to it's original position."] = "Linksklick und verschieben um das Fenster zu verschieben, Rechtsklick und verschieben um es an die Ursprungsposition zur\195\188ck zu setzen.",
	
	-- Win API is broken /wrist
	["The Horde wins"] = "Die Horde gewinnt",
	["The Alliance wins"] = "Die Allianz gewinnt",
	
	-- So we don't auto leave before completing
	["Call to Arms: %s"] = "Ruf zu den Waffen: %s",
	["You currently have the battleground daily quest for %s, auto leave has been set to occure once the quest completes."] = "Du hast zur Zeit den t\195\164glichen Schlachtfeldquest f\195\188r %s, automatisches Verlassen wird so lange ausgesetzt bis die Quest abgeschlossen ist.",
	
	-- Flags
	["Alliance flag carrier %s, held for %s."] = "Flaggentr\195\164ger der Allianz %s, gehalten f\195\188r %s.",
	["Horde flag carrier %s, held for %s."] = "Flaggentr\195\164ger der Horde %s, gehalten f\195\188r %s.",
	
	["was picked up by (.+)!"] = "(.+) hat die Flagge der (.+) aufgenommen!",
	["captured the"] = "(.+) hat die Flagge der (.+) errungen",
	["was dropped by (.+)!"] = "(.+) hat die Flagge der (.+) fallen lassen!",
	["was returned to its base"] = "Die Flagge der (.+) wurde von (.+) zu ihrem St\195\188tzpunkt zur\195\188ckgebracht!",
	
	["(.+) has taken the flag!"] = "(.+) hat die Flagge aufgenommen.",
	["The flag has been dropped"] = "Die Flagge wurde fallengelassen.",
	
	["Held Time: %s"] = "Gehalten: %s",
	["Capture Time: %s"] = "Eroberungszeit: %s",
	
	["Targetting %s"] = "Ziel: %s",
	["%s is out of range"] = "%s ist au\195\159er Reichweite",
	
	-- Sync queuing for AV
	["Alterac Valley queue stopped."] = "Alteractal Warteschlange gestoppt.",
	["Queuing for Alterac Valley in %d seconds."] = "In der Warteschlange f\195\188r das Alteractal seit %d Sekunden.",
	["Queuing for Alterac Valley in %d second."] = "In der Warteschlange f\195\188r das Alteractal seit %d Sekunde.",
	["Queue for Alterac Valley!"] = "Warteschlange f\195\188r das Alteractal!",
	
	["You must be in a raid or party to do this."] = "Du musst in einer Schlachgruppe oder Gruppe sein um das zu tun.",
	["You have been queued for Alterac Valley by %s."] = "Du bist in der Warteschlange f\195\188r das Alteractal seit %s.",
	["Invalid number entered for sync queue."] = "Ung\195\188ltige Nummer eigegeben f\195\188r synchrone Warteschlange.",
	
	-- CT support
	["-%d Reinforcements"] = "-%d Verst\195\164rkung",
	["+%d Points"] = "+%d Punkte",
	
	-- Score tooltip
	["%s (%d players)"] = "%s (%d Spieler)",
	["Servers"] = "Server",
	["Classes"] = "Klassen",
	
	-- Arathi basin
	["claims the ([^!]+)"] = "hat ([^!]+) besetzt!",
	["has taken the ([^!]+)"] = "hat ([^!]+) eingenommen!",
	["has assaulted the ([^!]+)"] = "hat ([^!]+) angegriffen!",
	["has defended the ([^!]+)"] = "hat ([^!]+) verteidigt!",
	
	["Bases: ([0-9]+)  Resources: ([0-9]+)/2000"] = "Basen: ([0-9]+)  Ressourcen: ([0-9]+)/2000",
	["Final Score: %d"] = "Endstand: %d",
	["Time Left: %s"] = "Verbleibende Zeit: %s",
	["Bases to win: %d"] = "Basen zum Sieg: %d",
	["Base Final: %d"] = "Basen am Ende: %d",
	
	-- Alterac valley
	["Herald"] = "Herold",
	["Snowfall Graveyard"] = "Der Schneewehenfriedhof",
	["claims the Snowfall graveyard"] = "hat den Schneewehenfriedhof besetzt",
	["(.+) is under attack"] = "(.+) wird angegriffen!",
	["(.+) was taken"] = "(.+) wurde von der (.+) erobert",
	["(.+) was destroyed"] = "(.+) wurde von der (.+) zerst\195\182rt",
	
	["Reinforcements: ([0-9]+)"] = "Verst\195\164rkung: ([0-9]+)",
	["%s will be captured by the %s in %s"] = "%s wird von der %s in %s erobert!",
	
	-- Eye of the Storm
	["Bases: ([0-9]+)  Victory Points: ([0-9]+)/2000"] = "Basen: ([0-9]+)  Siegpunkte: ([0-9]+)%/2000",
	["Bases %d  Points %d/2000"] = "Basen %d  Punkte %d/2000",
	["flag has been reset"] = "Die Flagge wurde zur\195\188ckgesetzt.",
	
	-- Gods
	["Ivus the Forest Lord"] = "Ivus der Waldf\195\188rs",
	["Lokholar the Ice Lord"] = "Lokholar der Eislord",
	
	["Ivus Moving: %s"] = "Ivus der Waldf\195\188rst in Bewegung: %s",
	["Lokholar Moving: %s"] = "Lokholar der Eislord in Bewegung: %s",
	
	["Wicked, wicked, mortals"] = "Gemeine, Gemeine, Sterbliche",
	["WHO DARES SUMMON LOKHOLA"] = "WER WAGT ES LOKHOLA HERBEIZURUFEN?",

	-- Captain Galvangar
	["Captain Galvangar"] = "Hauptmann Galvanga",
	
	["The Alliance has slain Captain Galvangar."] = "Die Allianz hat Hauptmann Galvangar get\195\182tet.",
	["The Alliance has engaged Captain Galvangar."] = "Die Allianz hat Hauptmann Galvangar angegriffen.",
	["The Alliance has reset Captain Galvangar."] = "Die Allianz hat Hauptmann Galvangar zur\195\188ckgesetzt.",
	
	["Your kind has no place in Alterac Valley"] = "F\195\188r Eure Art ist kein Platz im Alteractal!",
	["I'll never fall for that, fool!"] = "Ich werde niemals fallen, Dummkopf!",
	
	-- Captain Balinda
	["Captain Balinda Stonehearth"] = "Hauptmann Balinda Steinbruch",
	
	["The Horde has slain Captain Balinda Stonehearth."] = "Die Horde hat Hauptmann Balinda Steinbruch get\195\182tet.",
	["The Horde has engaged Captain Balinda Stonehearth."] = "Die Horde hat Hauptmann Balinda Steinbruch angegriffen.",
	["The Horde has reset Captain Balinda Stonehearth."] = "Die Horde hat Hauptmann Balinda Steinbruch zur\195\188ckgesetzt.",
	
	["Begone, uncouth scum!"] = "Verschwinde, dreckiger Abschaum!",
	["Filthy Frostwolf cowards"] = "R\195\164udige Frostwolf-Feiglinge",
	
	-- Drek'Thar
	["Drek'Thar"] = "Drek'Thar",
	
	["The Alliance has engaged Drek'Thar."] = "Die Allianz hat Drek'Thar angegriffen.",
	["The Alliance has reset Drek'Thar."] = "Die Allianz hat Drek'Thar zur\195\188ckgesetzt.",
	
	["Stormpike weaklings"] = "Sturmlanzenschw\195\164chlinge",
	["Stormpike filth!"] = "Sturmlanzenabschaum!",
	["You seek to draw the General of the Frostwolf"] = "Ihr versucht, den General der Frostwolf",
	
	-- Vanndar
	["Vanndar Stormpike"] = "Vanndar Sturmlanze",
	
	["The Horde has reset Vanndar Stormpike."] = "Die Horde hat Vanndar Sturmlanze zur\195\188ckgesetzt.",
	["The Horde has engaged Vanndar Stormpike."] = "Die Horde hat Vanndar Sturmlanze angegriffen.",
	
	["Why don't ya try again"] = "Warum versucht Ihr es nicht nochmal",
	["Soldiers of Stormpike, your General is under attack"] = "Soldaten des Sturmlanzenklans, euer General wird angegriffen!",	
	["You'll never get me out of me"] = "Ihr werdet mich niemals aus meinem Bunker",	

	-- Text for catching time until match starts
	["2 minute"] = "2 Minuten",
	["1 minute"] = "1 Minute",
	["30 seconds"] = "30 Sekunden",
	["Fifteen seconds"] = "f\195\188nfzehn Sekunden",
	["Thirty seconds"] = "drei\195\159ig Sekunden",
	["One minute"] = "Eine Minute",
	
	-- Slash commands
	["SSPVP Arena slash commands"] = "SSPVP Arena Slash Befehle",
	[" - rating <rating> - Calculates points given from the passed rating."] = " - rating <rating> - Calculates points given from the passed rating.",
	[" - points <points> - Calculates rating required to reach the passed points."] = " - points <points> - Calculates rating required to reach the passed points.",
	
	["SSPVP Alterac Valley slash commands"] = "SSPVP Alterac Valley slash commands",
	[" - sync <seconds> - Starts a count down for an Alterac Valley sync queue."] = " - sync <seconds> - Starts a count down for an Alterac Valley sync queue.",
	[" - cancel - Cancels a running sync."] = " - cancel - Cancels a running sync.",
	
	["SSPVP slash commands"] = "SSPVP slash commands",
	[" - suspend - Suspends auto join and leave for 5 minutes, or until you log off."] = " - suspend - Suspends auto join and leave for 5 minutes, or until you log off.",
	[" - ui - Opens the OptionHouse configuration for SSPVP."] = " - ui - Opens the OptionHouse configuration for SSPVP.",
	
	["Auto join and leave has been suspended for the next 5 minutes, or until you log off."] = "Auto join and leave has been suspended for the next 5 minutes, or until you log off.",
	["Suspension has been removed, you will now auto join and leave again."] = "Suspension has been removed, you will now auto join and leave again.",
	["Suspension is still active, will not auto join or leave."] = "Suspension is still active, will not auto join or leave.",
	
	["[%d vs %d] %d rating = %d points"] = "[%d vs %d] %d Wertung = %d Punkte",
	["[%d vs %d] %d rating = %d points - %d%% = %d points"] = "[%d vs %d] %d Wertung = %d Punkte - %d%% = %d Punkte",
	["[%d vs %d] %d points = %d rating"] = "[%d vs %d] %d Punkte = %d Wertung",

	-- Overlay categories
	["Faction Balance"] = "Fraktionsverteilung",
	["Timers"] = "Timer",
	["Match Info"] = "Spiel Info",
	["Bases to win"] = "Basen zum Sieg",
	["Mine Reinforcement"] = "Mine Reinforcement",
	["Battlefield Queue"] = "Schlachtfeld-Warteschlange",
	["Frame Moving"] = "Fenster bewegen",
	
	-- GOOEY
	["General"] = "Allgemein",
	["Auto Queue"] = "Auto-Warteschlange",
	["Battlefield"] = "Schlachtfeld",
	["Overlay"] = "Info-Fenster",
	["Auto Join"] = "Auto-Beitreten",
	["Display"] = "Anzeige",

	-- GENERAL
	["Play"] = "Play",
	["Stop"] = "Stop",
	
	["Sound file"] = "Sounddatei",
	["Timer channel"] = "Timer channel",
	["Show team summary after rated arena ends"] = "Show team summary after rated arena ends",
	["Auto append server name while in battlefields for whispers"] = "Auto append server name while in battlefields for whispers",
	["Auto queue when inside of a group and leader"] = "Auto queue when inside of a group and leader",
	["Battleground"] = "Schlachtfeld",
	["Party"] = "Gruppe",
	["Raid"] = "Schlachtgruppe",
	
	["Automatically append \"-server\" to peoples names when you whisper them, if multiple people are found to match the same name then it won't add the server."] = "Automatically append \"-server\" to peoples names when you whisper them, if multiple people are found to match the same name then it won't add the server.",
	["Shows team names, points change and the new ratings after the arena ends."] = "Shows team names, points change and the new ratings after the arena ends.",
	["Channel to output to when you send timers out from the overlay."] = "Channel to output to when you send timers out from the overlay.",
	["Sound file to play when a queue is ready, file must be inside Interface/AddOns/SSPVP before you started the game."] = "Sounddatei zum Abspielen wenn Warteschlange bereit ist, die Datei muss im Ordner Interface\\AddOns\\SSPVP sein, noch bevor Ihr das Spiel gestartet habt.",
	
	["Auto queue when outside of a group"] = "Auto queue when outside of a group",
	["Auto queue when inside a group and leader"] = "Auto queue when inside of a group and leader",
	
	["Queue Overlay"] = "Warteschlangen-Info",
	["Enable battlefield queue status"] = "Aktiviere Warteschlangen-Info",
	["Show inside an active battlefield"] = "Show inside an active battlefield",
	
	
	["Lock PvP objectives"] = "Fixiere Outdoor-PvP-Ziele",
	["Lock scoreboard"] = "Fixiere Schlachtfeld-Punkteanzeige",
	["Lock capture bar"] = "Fixiere Eroberungsbalken",
	["Shows an anchor above the frame that lets you move it, the frame you're trying to move may have to be visible to actually move it."] = "Shows an anchor above the frame that lets you move it, the frame you're trying to move may have to be visible to actually move it.",
	
	-- BATTLEFIELD
	["Death"] = "Tod",
	["Scoreboard"] = "Punkteanzeige",
	["Color player name by class"] = "F\195\164rbe Spielernamen nach Klasse",
	["Hide class icon next to names"] = "Verberge Klassenicon neben dem Namen",
	["Show player levels next to name"] = "Zeige Spielerlevel neben dem Namen",
	["Release from corpse when inside an active battleground"] = "Automatisches Akzeptieren von Wiederbelebungen innerhalb eines aktiven Schlachtfelds",
	["Release even with a soul stone active"] = "Automatischer Release auch mit einem aktiven Seelenstein",
	
	-- AUTO JOIN
	["Delay"] = "Verz\195\182gerung",
	["Join priorities"] = "Beitritts Priorit\195\164ten",
	["Enable auto join"] = "Aktiviere Auto-Beitreten",
	["Priority check mode"] = "Priority check mode",
	["Less than"] = "Less than",
	["Less than/equal"] = "Less than/equal",
	["Battleground join delay"] = "Verz\195\182gerung beim Beitreten von Schlachtfeldern",
	["AFK battleground join delay"] = "Verz\195\182gerung beim Beitreten von Schlachtfeldern wenn AFK",
	["Arena join delay"] = "Verz\195\182gerung beim Beitreten von Arenen",
	["Don't auto join a battlefield if the queue window is hidden"] = "Don't auto join a battlefield if the queue window is hidden",
	
	-- AUTO LEAVE
	["Auto Leave"] = "Auto-Verlassen",
	["Confirmation"] = "Best\195\164tigung",
	["Confirm when leaving a battlefield queue through minimap list"] = "Confirm when leaving a battlefield queue through minimap list",
	["Confirm when leaving a finished battlefield through score"] = "Confirm when leaving a finished battlefield through score",
	
	["Battlefield leave delay"] = "Battlefield leave delay",
	["Enable auto leave"] = "Auto-Verlassen",
	["Screenshot score board when game ends"] = "Screenshot der Punkteanzeige bei Spielende",
	
	-- OVERLAY
	["Frame"] = "Rahmen",
	["Color"] = "Farbe",
	["Lock overlay"] = "Fixiere Info-Fenster",
	["Background opacity: %d%%"] = "Hintergrund-Transparenz: %d%%",
	["Scale: %d%%"] = "Gr\195\182ße: %d%%",
	["Background color"] = "Hintergrundfarbe",
	["Border color"] = "Rahmenfarbe",
	["Category text color"] = "Kategorie-Textfarbe",
	["Text color"] = "Textfarbe",
	["Grow up"] = "Grow up",
	["The overlay will grow up instead of down when new rows are added, a reloadui maybe required for this to take affect."] = "The overlay will grow up instead of down when new rows are added, a reloadui maybe required for this to take affect.",

	["Disable overlay clicking"] = "Disable overlay clicking",
	["Removes the ability to click on the overlay, allowing you to interact with the 3D world instead. While the overlay is unlocked, this option is ignored."] = "Removes the ability to click on the overlay, allowing you to interact with the 3D world instead. While the overlay is unlocked, this option is ignored.",
	
	-- AV
	["Alerts"] = "Alerts",
	["Timers"] = "Timer",
	["Enable capture timers"] = "Aktiviere Eroberungstimer",
	["Enable interval capture messages"] = "Aktiviere Intervall f\195\188r Eroberungsnachrichten",
	["Seconds between capture messages"] = "Intervall in Sekunden zwischen den Nachrichten",
	["Show resources gained through mines"] = "Show resources gained through mines",
	["Show resources lost from captains in towers in MSBT/SCT/FCT"] = "Show resources lost from captains in towers in MSBT/SCT/FCT",
	["None"] = "None",
	["25%"] = "25%",
	["50%"] = "50%",
	["75%"] = "75%",
	
	-- EOTS/AB/WSG
	["Flag Carrier"] = "Flaggentr\195\164ger",
	["Match Info"] = "Match Info",
	
	["Show flag carrier"] = "Zeige Flaggentr\195\164ger",
	["Show carrier health when available"] = "Show carrier health when available",
	["Color carrier name by class color"] = "Color carrier name by class color",
	["Time until flag respawns"] = "Time until flag respawns",
	
	["Show basic match information"] = "Show basic match information",
	["Show bases to win"] = "Zeige zum Sieg n\195\182tige Basen im Infofenster",
	["Show flag held time and time taken to capture"] = "Show flag held time and time taken to capture",
	
	["Show points gained from flag captures in MSBT/SCT/FCT"] = "Show points gained from flag captures in MSBT/SCT/FCT",
	
	["Macro Text"] = "Macro Text",
	["Text to execute when clicking on the flag carrier button"] = "Text to execute when clicking on the flag carrier button",
	
	-- Disable modules
	["Modules"] = "Module",
	["Disable %s"] = "Deaktiviere %s",
	["match information"] = "Spielinformationen",
	["Time left in match, final scores and bases to win for Eye of the Storm and Arathi Basin."] = "Time left in match, final scores and bases to win for Eye of the Storm and Arathi Basin.",
	
	["flag carrier"] = "Flaggentr\195\164ger",
	["Who's holding the flag currently for Eye of the Storm and Warsong Gulch."] = "Who's holding the flag currently for Eye of the Storm and Warsong Gulch.",

	["Timers for Arathi Basin when capturing nodes."] = "Timers for Arathi Basin when capturing nodes.",

	["Timers for Alterac Valley when capturing nodes, as well interval alerts on time left before capture."] = "Timers for Alterac Valley when capturing nodes, as well interval alerts on time left before capture.",
	["Cleaning up the text in the PvP objectives along with points gained from captures in Eye of the Storm."] = "Cleaning up the text in the PvP objectives along with points gained from captures in Eye of the Storm.",
	
	["battleground"] = "Schlachtfeld",
	["General battleground specific changes like auto release."] = "General battleground specific changes like auto release.",
	
	["score"] = "Punkteanzeige",
	["General scoreboard changes like coloring by class or hiding the class icons."] = "General scoreboard changes like coloring by class or hiding the class icons.",
	
	-- Priorities
	["afk"] = "Wenn afk",
	["ratedArena"] = "Gewertete Arena",
	["skirmArena"] = "Ungewertete Arena",
	["eots"] = "Auge des Sturms",
	["av"] = "Alteractal",
	["ab"] = "Arathibecken",
	["wsg"] = "Kriegshymnenschlucht",
	["group"] = "In Gruppe oder Raid",
	["instance"] = "Instanz",
	["none"] = "Alles andere",
}, {__index = SSPVPLocals})
