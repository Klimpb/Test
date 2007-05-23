if( GetLocale() ~= "deDE" ) then
	return;
end

SSPVPLocals = setmetatable( {
	["SSPVP is now enabled."] = "SSPVP ist nun aktiviert.",
	["SSPVP is now disabled."] = "SSPVP ist nun deaktiviert.",
	["SSPVP Slash Commands"] = "SSPVP Slash-Kommandos",
	
	["Eye of the Storm"] = "Auge des Sturms",
	["Warsong Gulch"] = "Kriegshymnenschlucht",
	["Arathi Basin"] = "Arathibecken",
	["Alterac Valley"] = "Alteractal",
	["Blade's Edge Arena"] = "Arena des Schergrats",
	["Nagrand Arena"] = "Arena von Nagrand",
	["Ruins of Lordaeron"] = "Ruinen von Lordaeron",
	["Arenas"] = "Arenas",

	["Higher priority battleground found, auto joining %s in %d seconds."] = "Schlachtfeld mit h\195\182herer Priorit\195\164t gefunden, Auto-Beitreten zu %s in %d Sekunden.",
	["You're currently inside/doing something that is a higher priority then %s, auto join disabled."] = "Ihr macht gerade etwas mit h\195\182herer Priorit\195\164t als %s, Auto-Beitreten deaktiviert.",
	["The battlefield %s is ready to join, auto leave has been disabled."] = "Das Schlachtfeld %s ist bereit zum Beitreten, Auto-Verlassen wurde deaktiviert.",
	
	["I would like to go to the battleground."] = "Ich m\195\182chte das Schlachtfeld betreten.",
	["I would like to fight in an arena."] = "Ich m\195\182chte in der Arena k\195\164mpfen.",
	["I wish to join the battle!"] = "Ich m\195\182chte mich dem Kampf anschlie\195\159en!",
	
	["Releasing..."] = "Releasing...",
	["Using %s..."] = "Benutze %s...",

	["Unknown"] = "Unbekannt",
	
	["You are about to leave the active or queued battlefield %s, are you sure?"] = "Ihr seid gerade dabei, das aktive oder angemeldete Schlachtfeld %s zu verlassen, seid Ihr sicher?",
	["You are about to leave the active or queued arena %s (%d vs %d), are you sure?"] = "Ihr seid gerade dabei, die aktive oder angemeldete Arena %s (%d vs %d) zu verlassen, seid Ihr sicher?",
	
	["Battlefield Info"] = "Schlachtfeldinfo",
	
	["Time before start"] = "Zeit bis zum Start",
	["Starting In: %s"] = "Startet in: %s";
	
	["2 minute"] = "2 Minuten", 
	["1 minute"] = "1 Minute",
	["30 seconds"] = "30 Sekunden",
	["One minute until"] = "Eine Minute bis",
	["Thirty seconds until"] = "Drei\195\159ig Sekunden bis",
	["Fifteen seconds until"] = "F\195\188nfzehn Sekunden bis",
	
	["Alliance flag carrier %s"] = "Flaggentr\195\164ger der Allianz %s",
	["Horde flag carrier %s"] = "Flaggentr\195\164ger der Horde %s",
		
	["Time Left: %s"] = "Zeit \195\188brig: %s",
	["Final Score: %d"] = "Endstand: %d",
	
	["Alliance"] = "Allianz",
	["Horde"] = "Horde",

	["Timers"] = "Timer",
	
	["No data found"] = "Keine Daten gefunden",
	["%s (%d players)"] = "%s (%d Spieler)",
	["Server Balance"] = "Serververteilung",
	["Class Balance"] = "Klassenverteilung",
	
	["Battlefield queues"] = "Schlachtfeld-Warteschlangen",
	["Time left %s"] = "Verbleibende Zeit %s";
	["%s (%d vs %d)"] = "%s (%d vs %d)",
	["%s (%dvs%d)"] = "%s (%dvs%d)",

	["Queue for Alterac Valley in %d seconds."] = "Warteschlange f\195\188r Alteractal in %d Sekunden.",
	["Queueing in %d second(s)."] = "Anmeldung in %d Sekunde(n).",
	["Queued for Alterac Valley!"] = "Angemeldet f\195\188r Alteractal!",
	["You have been queued for Alterac Valley by %s."] = "Ihr wurdet angemeldet f\195\188r Alteractal durch %s.",
	["Alterac Valley sync queue has been canceled!"] = "Alteractal-Synchronisierung wurde abgebrochen!",
	["You must be party or raid leader to perform this action."] = "Ihr m\195\188sst der Gruppen- oder Raidleader sein, um diese Aktion ausf\195\188hren zu k\195\182nnen.",

	["[%s] %s: %s"] = "[%s] %s: %s",
	
	-- Used for checking SSPVP 2.x.x syncs
	["Queueing for Alterac Valley in ([0-9]+) seconds"] = "Warteschlange f\195\188r Alteractal in  ([0-9]+) Sekunden",
	["Sync queue count down has been"] = "Abgleich des Warteschlangen-Countdowns wurde",
	
	-- Slash Commands
	["SSPVP commands"] = "SSPVP Kommandos",
	["on - Enables SSPVP"] = "on - Aktiviert SSPVP",
	["off - Disables SSPVP"] = "off - Deaktiviert SSPVP",
	["sync <count> - Starts an Alterac Valley sync queue count down."] = "sync <count> - Startet einen Countdown zum Abgleich der Warteschlange des Alteractals.",
	["ui - Pulls up the configuration page."] = "ui - \195\150ffnet die Konfigurationsseite.",
	["cancel - Cancels a running sync count down."] = "cancel - bricht einen laufenden Abgleichscountdown ab.",
	["rating <points> - Calculates what rating you will need to gain the given points"] = "rating <points> - Calculates what rating you will need to gain the given points",
	["points <rating> - Calculates how much points you will gain with the given rating"] = "points <rating> - Calculates how much points you will gain with the given rating",
	["[%d vs %d] %d points = %d rating"] = "[%d vs %d] %d Punkte = %d Wertung",
	["[%d vs %d] %d rating = %d points"] = "[%d vs %d] %d Wertung = %d Punkte",
	["[%d vs %d] %d rating = %d points - %d%% = %d points"] = "[%d vs %d] %d Wertung = %d Punkte - %d%% = %d Punkte",


	-- Arenas
	["Arena Info"] = "Arena-Info",
	["Stealth buff spawn: %s"] = "Stealth buff spawn: %s",
	["The Arena battle has begun!"] = "The Arena battle has begun!",
	
	["([a-zA-Z]+)%'s Minion"] = "([a-zA-Z]+)%'s Minion",
	["%s's pet, %s %s."] = "%s's pet, %s %s.",
	["[%d/%d] %s / %s / %s / %s / %s %s"] = "[%d/%d] %s / %s / %s / %s / %s %s",
	["[%d/%d] %s / %s / %s / %s %s"] = "[%d/%d] %s / %s / %s / %s %s",
	
	-- Warsong Gulch
	["was picked up by (.+)!"] = "(.+) hat die Flagge der (.+) aufgenommen!",
	["was dropped by (.+)!"] = "(.+) hat die Flagge der (.+) fallen lassen!",
	["(.+) captured the"] = "(.+) hat die Flagge der (.+) errungen",
	["was returned to its base"] = "was returned to its base",
	["Flag Respawn: %s"] = "Flaggen-Respawn: %s",
	
	-- Alterac Valley
	["Item Tracker"] = "Item Tracker",
	["Herald"] = "Herold",
	["The"] = "The",
	["Snowfall Graveyard"]  = "Der Schneewehenfriedhof",
	["Sync Queueing: %s"] = "Sync Queueing: %s",

	["%s will be captured by the %s in %s!"] = "%s will be captured by the %s in %s!",
	
	["Armor Scraps"] = "R/195/188stungsfetzen",
	
	["Soldiers Blood"] = "Blut eines Soldaten",
	["Storm Crystals"] = "Sturmkristalle",
	
	["Soldiers Flesh"] = "Fleisch eines Sturmlanzensoldaten",
	["Lieutenants Flesh"] = "Fleisch eines Sturmlanzenleutnants",
	["Commanders Flesh"] = "Fleisch eines Sturmlanzenkommandanten",
	
	["Soldiers Medal"] = "Medaille des Soldaten",
	["Lieutenants Medal"] = "Medaille des Leutnants",
	["Commanders Medal"] = "Medaille des Kommandanten",
	
	["claims the (.+) graveyard!"] = "hat ([^!]+) besetzt!",
	["(.+) is under attack!"] = "(.+) is under attack!",
	["(.+) was taken by the"] = "(.+) was taken by the",
	["(.+) was destroyed by the"] = "(.+) wurde von der (.+) zerst\195\182rt",
	
	["AVNodes"] = {
		["DBNB"] = "Dun Baldar North Bunker",
		["DBNS"] = "Dun Baldar South Bunker",
		["EFWT"] = "East Frostwolf Tower",
		["WFWT"] = "West Frostwolf Tower",
		["FWGY"] = "Frostwolf Graveyard",
		["FWRH"] = "Frostwolf Relief Hut",
		["IBGY"] = "Iceblood Graveyard",
		["IBT"] = "Iceblood Tower",
		["IWB"] = "Icewing Bunker",
		["SFGY"] = "Schneewehenfriedhof",
		["SHB"] = "Stonehearth Bunker",
		["SHGY"] = "Stonehearth Graveyard",
		["SPAS"] = "Stormpike Aid Station",
		["SPGY"] = "Stormpike Graveyard",
		["TP"] = "Turmstellung",
		["IVUS"] = "Ivus der Waldf\195\188rst",
		["LOKH"] = "Lokholar der Eislord",
	},
	
	-- Gods
	["Ivus the Forest Lord"] = "Ivus der Waldf\195\188rst",
	["Lokholar the Ice Lord"] = "Lokholar der Eislord",
	
	["Ivus the Forest Lord Moving: %s"] = "Ivus der Waldf\195\188rst in Bewegung: %s",
	["Lokholar the Ice Lord Moving: %s"] = "Lokholar der Eislord in Bewegung: %s",
	
	["Wicked, wicked, mortals"] = "Wicked, wicked, mortals",
	["WHO DARES SUMMON LOKHOLA"] = "WHO DARES SUMMON LOKHOLA",

	-- Marshal/Warmasters
	["(.+) Marshal"] = "(.+) Marschall",
	["(.+) Warmaster"] = "(.+) Kriegsmeister",
	
	-- Captain Galvangar
	["Captain Galvangar"] = "Hauptmann Galvangar",
	
	["The Alliance have engaged Captain Galvangar."] = "Die Allianz hat Hauptmann Galvangar angegriffen.",
	["The Alliance have reset Captain Galvangar."] = "Die Allianz hat Hauptmann Galvangar zur\195\188ckgesetzt.",
	
	["Your kind has no place in Alterac Valley"] = "F\195\188r Eure Art ist kein Platz im Alteractal!",
	["I'll never fall for that, fool!"] = "Ich werde niemals",
	
	-- Captain Balinda
	["Captain Balinda Stonehearth"] = "Hauptmann Balinda Steinbruch",
	
	["The Horde have engaged Captain Balinda Stonehearth."] = "Die Horde hat Hauptmann Balinda Steinbruch angegriffen.",
	["The Horde have reset Captain Balinda Stonehearth."] = "Die Horde hat Hauptmann Balinda Steinbruch zur\195\188ckgesetzt.",
	
	["Begone, uncouth scum!"] = "Verschwinde, dreckiger Abschaum!",
	["Filthy Frostwolf cowards"] = "R\195\164udige Frostwolf-Feiglinge",
	
	-- Drek'Thar
	["Drek'Thar"] = "Drek'Thar",
	
	["The Alliance have engaged Drek'Thar."] = "Die Allianz hat Drek'Thar angegriffen.",
	["The Alliance have reset Drek'Thar."] = "Die Allianz hat Drek'Thar zur\195\188ckgesetzt.",
	
	["Stormpike weaklings"] = "Sturmlanzenschw\195\164chlinge",
	["Stormpike filth!"] = "Sturmlanzenabschaum!",
	["You seek to draw the General of the Frostwolf"] = "Ihr versucht, den General der Frostwolf",

	-- Vanndar
	["Vanndar Stormpike"] = "Vanndar Sturmlanze",
	
	["The Horde have reset Vanndar Stormpike."] = "Die Horde hat Vanndar Sturmlanze zur\195\188ckgesetzt.",
	["The Horde have engaged Vanndar Stormpike."] = "Die Horde hat Vanndar Sturmlanze angegriffent.",
	
	["Why don't ya try again"] = "Warum versucht Ihr es nicht nochmal",
	["Soldiers of Stormpike, your General is under attack"] = "Soldaten des Sturmlanzenklans, euer General wird angegriffen!",	
	["You'll never get me out of me"] = "Ihr werdet mich niemals aus meinem Bunker",
	
	-- Arathi Basin
	["Bases: ([0-9]+)  Resources: ([0-9]+)/2000"] = "Basen: ([0-9]+)  Ressourcen: ([0-9]+)/2000",
	["Bases to win: %d"] = "Basen zum Sieg: %d",
	["Bases to win: %d (A:%d/H:%d)"] = "Basen zum Sieg: %d (A:%d/H:%d)",
	["has taken the ([^!]+)"] = "hat ([^!]+) eingenommen!",
	["has assaulted the ([^!]+)"] = "hat ([^!]+) angegriffen!",
	["has defended the ([^!]+)"] = "hat ([^!]+) verteidigt!",
	["(.+) claims the ([^!]+)"] = "hat ([^!]+) besetzt!",

	-- Eye of the Storm
	["Bases: ([0-9]+)  Victory Points: ([0-9]+)%/2000"] = "Basen: ([0-9]+)  Siegpunkte: ([0-9]+)%/2000",
	["Bases %d  Points %d/2000"] = "Basen %d  Punkte %d/2000",
	
	["(.+) has taken the flag!"] = "(.+) has taken the flag!",
	["The (.+) have captured the flag!"] = "The (.+) have captured the flag!",
	["The flag has been dropped"] = "The flag has been dropped",
	
	["Flag Captures: %d"] = "Flaggeneroberungen: %d",
	["Towers to win: %d"] = "T\195\188rme zum Sieg: %d",
	["Towers to win: %d (A:%d/H:%d)"] = "T\195\188rme zum Sieg: %d (A:%d/H:%d)",
	["Captures to win: %d"] = "Flaggen zum Sieg: %d",

	-- Auto turn in
	["Removed the quest '%s...' from auto complete."] = "Quest entfernt aus Auto-Abgabe!",
	["Added the quest '%s...' to the skip list, hold ALT and click the text again to remove it."] = "Den Quest '%s...' hinzugef\195\188gt zur \195\156berspringen-Liste, Ihr k\195\182nnt ALT dr\195\188cken w\195\164hrend des Klickens des Quests um ihn wieder zu entfernen.",

	["TURNTYPES"] = {
		["av"] = "Alteractal-Quests",
		["manual"] = "H\195\164ndisch hinzugef\195\188gte Quests",
	},
	["TURNQUESTS"] = {
		{ name = "Vorr/195/164te der Eisenschachtmine", type = "av" },
		{ name = "Vorr/195/164te der Eisbei/195/159ermine", type = "av" },
		{ name = "Mehr R\195\188stungsfetzen", type = "av", item = { ["17422"] = 20 } },
		{ name = "Ivus der Waldf\195\188rst", type = "av", item = { ["17423"] = 1 } },
		{ name = "Haufenweise Kristalle", type = "av", item = { ["17423"] = 5 } },
		{ name = "RWidderzaumzeug", type = "av", item = { ["17643"] = 1 } },
		{ name = "Erzrutschs Luftflotte", type = "av", item = { ["17502"] = 1 } },
		{ name = "Vipores Luftflotte", type = "av", item = { ["17503"] = 1 } },
		{ name = "Ichmans Luftflotte", type = "av", item = { ["17504"] = 1 } },
		{ name = "Mehr Beute", type = "av", item = { ["17422"] = 20 } },
		{ name = "Eine Gallone Blut", type = "av", item = { ["17306"] = 5 } },
		{ name = "Lokholar der Eislord", type = "av", item = { ["17306"] = 1 } },
		{ name = "Widderledernes Zaumzeug", type = "av", item = { ["17642"] = 1 } },
		{ name = "Guses Luftflotte", type = "av", item = { ["17326"] = 1 } },
		{ name = "Jeztors Luftflotte", type = "av", item = { ["17327"] = 1 } },
		{ name = "Mulvericks Luftflotte", type = "av", item = { ["17328"] = 1 } },	
	},
	
	-- UI
	["SSPVP"] = "SSPVP",
	["General"] = "Allgemein",
	["Battleground"] = "Schlachtfeld",
	["Auto Join"] = "Auto-Beitreten",
	["Auto Leave"] = "Auto-Verlassen",
	["Battlefield"] = "Schlachtfeld",
	["Overlay"] = "Info-Fenster",
	["Queue Overlay"] = "Warteschlangen-Info",
	["Auto turn in"] = "Auto-Abgabe",

	["None"] = "None",
	["Lock team report frame"] = "Fixiere Teamreport-Rahmen",

	["Enable queue overlay"] = "Aktiviere Warteschlangen-Info",
	["Show queue overlay inside battlegrounds"] = "Zeige Warteschlangen-Info in Schlachtfeldern",
	["Show estimated time until queue is ready"] = "Zeige gesch\195\164tzte Zeit bis Warteschlange bereit ist",
	["Estimated time format"] = "Format der gesch\195\164tzten Zeit",

	["Raid"] = "Raid",
	["Party"] = "Party",
	["Play"] = "Play",
	["Stop"] = "Stop",
	
	["Enable auto turn in"] = "Aktiviere Auto-Abgabe",
	["Enable overlay"] = "Aktiviere Info-Fenster",
	["afk"] = "Wenn afk",
	["instance"] = "In einer Instanz",
	["arena"] = "Gewertete & ungewertete Arena",
	["eots"] = "Auge des Sturms",
	["av"] = "Alteractal",
	["ab"] = "Arathibecken",
	["wsg"] = "Kriegshymnenschlucht",
	["grouped"] = "In Gruppe oder Raid",
	["none"] = "Alles andere",

	["Disable %s"] = "Deaktiviere %s",
	
	["Enable modified player/inspect pvp screens"] = "Aktiviere ver\195\164nderte Spieler/Betrachten-PVP-Anzeige",
	["Shows the points gained next to the rating on both players and inspect pvp screens, the bracket for the inspected players team will also be shown next to the name."] = "Shows the points gained next to the rating on both players and inspect pvp screens, the bracket for the inspected players team will also be shown next to the name.",	
	["Enable auto leave"] = "Aktiviere Auto-Verlassen",
	["Enable confirmation when leaving"] = "Aktiviere Best\195\164tigung vor Auto-Verlassen",
	["Auto leave delay"] = "Verz\195\182gerung f\195\188r Auto-Verlassen",
	["Auto accept corpse ressurects inside a battlefield"] = "Automatisches Akzeptieren von Wiederbelebungen auf dem Schlachtfeld",
	["Take score screenshot on game end"] = "Screenshot der Punkteanzeige bei Spielende",
	
	["Color names by class on score board"] = "F\195\164rbe Namen nach Klassen auf Punkteanzeige",
	["Hide class icon next to names on score board"] = "Verberge Klassenicon neben dem Namen auf Punkteanzeige",
	["Show player levels next to names on score board"] = "Zeige Spielerlevel neben dem Namen auf Punkteanzeige",
	
	["Enable enemy team report"] = "Aktiviere feindlichen Teamreport",
	["Reports team you are facing when you mouse over them inside an arena, this will also pull up a frame you can click to target them.\nThis will NOT update while you are in combat."] = "Reports team you are facing when you mouse over them inside an arena, this will also pull up a frame you can click to target them.\nThis will NOT update while you are in combat.",
	["Targetting frame scale: %d%%"] = "Zielrahmen Gr\195\182ße: %d%%",
	
	["Enable estimated final score overlay"] = "Zeige gesch\195\164tzten Endstand im Infofenster",
	["Enable capture timers"] = "Aktiviere Eroberungstimer",
	["Estimated time left in the battlefield"] = "Zeige gesch\195\164tzte verbleibende Matchdauer im Schlachtfeld",
	["Estimated final score"] = "Gesch\195\164tzter Endstand",
	["Show bases to win"] = "Zeige zum Sieg n\195\182tige Basen im Infofenster",
	["Show bases to win score"] = "Zeige zum Sieg n\195\182tige Basenpunkte im Infofenster",
	
	["Show total captures for Alliance and Horde"] = "Zeige Gesamteroberungen f\195\188r Allianz und Horde",
	["Enable carrier names"] = "Aktiviere Flaggentr\195\164gernamen",
	["Show border around carrier names"] = "Zeige Rahmen um Flaggentr\195\164gernamens",
	["Time until flag respawns"] = "Zeit bis Flaggenrespawn",
	["Show captures to win"] = "Zeige Eroberungen zum Sieg",
	["Show total flag captures for Alliance and Horde"] = "Zeige gesamte Flaggeneroberungen f\195\188r Allianz und Horde",
	["Show carrier health when available"] = "Zeige Gesundheit des Flaggentr\195\164gers wenn m\195\182glich",
	
	["Timer format"] = "Timerformat",
	["Category text type"] = "Kategorietext-Typ",
	["Min X, Sec X"] = "Min X, Sek X",
	["Min X"] = "Min X",
	["hh:mm:ss"] = "hh:mm:ss",
	["Always hide"] = "Immer verbergen",
	["Always show"] = "Immer zeigen",
	["Auto hiding"] = "Auto-Verbergen",
	["Mode to use when displaying category text, auto will show it when more then one category is being shown."] = "Modus zur Anzeige des Kategorie-Texts, Auto zeigt ihn wenn mehr als eine Kategorie angezeigt wird.",
	["Lock overlay"] = "Fixiere Info-Fenster",
	["Background color"] = "Hintergrundfarbe",
	["Border color"] = "Rahmenfarbe",
	["Text color"] = "Textfarbe",
	["Category text color"] = "Kategorie-Textfarbe",
	["Background opacity: %d%%"] = "Hintergrund-Transparenz: %d%%",
	["Text opacity: %d%%"] = "Text-Transparenz: %d%%",

	["Enable blood/crystal tracking"] = "Aktiviere Anzeige von Blut/Kristallen",
	["Enable armor scraps tracking"] = "Aktiviere Anzeige von R\195\188stungsfetzen",
	["Enable flesh/medal tracking"] = "Aktiviere Anzeige von Fleisch/Medaillen",
	
	["Interval in seconds between messages"] = "Intervall in Sekunden zwischen den Nachrichten",
	["Enable interval capture messages"] = "Aktiviere Intervall für Eroberungsnachrichten",
	["Interval frequency increase"] = "Erh\195\182hte Intervallfrequenz",
	["The percentage to increase the frequency of the capture alerts, this will active when 2 minutes is left before something is captured."] = "Prozentsatz, um den sich die Frequenz der Eroberungsnachrichten erh\195\182ht, dies geschieht wenn noch 2 Minuten bis zur Eroberung \195\188brig sind.",
	
	["25%"] = "25%",
	["50%"] = "50%",
	["75%"] = "75%",
	
	["Enable auto join"] = "Aktiviere Auto-Beitreten",
	["Battleground join delay"] = "Verz\195\182gerung beim Beitreten von Schlachtfeldern",
	["AFK battleground join delay"] = "Verz\195\182gerung beim Beitreten von Schlachtfeldern wenn AFK",
	["Arena join delay"] = "Verz\195\182gerung beim Beitreten der Arena",
	["AFK arena join delay"] = "Verz\195\182gerung beim Beitreten der Arena wenn AFK",
	["Battlefield auto joining priorities"] = "Priorit\195\164ten f\195\188r Auto-Beitreten von Schlachtfeldern",
	["Priority system to use when auto joining battlegrounds, equal priorities will not override eachother, If you have Warsong Gulch as #1 and Arathi Basin as #2 you'll always auto join Warsong Gulch when in Arathi Basin, but not Arathi Basin when inside Warsong Gulch."] = "Priority system to use when auto joining battlegrounds, equal priorities will not override eachother, If you have Warsong Gulch as #1 and Arathi Basin as #2 you'll always auto join Warsong Gulch when in Arathi Basin, but not Arathi Basin when inside Warsong Gulch.",
	
	["Auto open minimap when inside a battleground"] = "\195\150ffne Minimap automatisch beim Beitreten des Schlachtfelds",
	["Auto release when inside an active battlefield"] = "Automatischer Release innerhalb eines aktiven Schlachtfelds",
	["Auto release even with a soulstone active"] = "Automatischer Release auch mit einem aktiven Seelenstein",
	["Auto accept corpse ressurections inside a battlefield"] = "Automatisches Akzeptieren von Wiederbelebungen innerhalb eines aktiven Schlachtfelds",

	["Block all messages starting with [SS]"] = "Blockiere alle Nachrichten die mit [SS] beginnen",
	["This will block all messages that SSPVP sent out, this is mainly timers or found messages in Arenas."] = "Dies blockiert alle Nachrichten, die SSPVP verschickt, haupts\195\164chlich Timer oder gefunden-Nachrichten in Arenas.",
	["Lock world PvP objectives"] = "Fixiere Outdoor-PvP-Ziele",
	["Lock battlefield scoreboard"] = "Fixiere Schlachtfeld-Punkteanzeige",
	["Lock capture bars"] = "Fixiere Eroberungsbalken",
	["Show world PvP objectives in overlay"] = "Zeige Outdoor-PvP-Ziele im Info-Fenster",
	["This will hide the world PvP objectives frame and show it inside the overlay instead."] = "Dies verbirgt die Anzeige der Outdoor-PvP-Ziele und zeigt sie stattdessen im Info-Fenster.",
	["Enable SSPVP"] = "Aktiviere SSPVP",
	["Default Channel"] = "Standard-Channel",
	["Default channel that all information like score board faction balance and timers are sent to."] = "Standard-Channel, an den alle Informationen wie Punkteanzeige, Fraktionsverteilung und Timer gesendet werden.",
	["Auto group queue when leader"] = "Automatische Gruppenanmeldung wenn Gruppenleiter",
	["Auto solo queue when ungrouped"] = "Automatische Soloanmeldung wenn nicht in Gruppe",
	["Sound file"] = "Sounddatei",
	["Sound file to play when a queue is ready, the file must be inside Interface\\AddOns\\SSPVP and have been present when you started the game."] = "Sounddatei zum Abspielen wenn Warteschlange bereit ist, die Datei muss im Ordner Interface\\AddOns\\SSPVP sein, noch bevor Ihr das Spiel gestartet habt.",
}, { __index = SSPVPLocals } );
