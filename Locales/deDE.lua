-- MzxRiding Deutsch / German

local ADDON, ns = ...
local L = ns.L

ns.localeData = ns.localeData or {}

local t = {
	["MzxRiding Settings"] = "MzxRiding Einstellungen",
	["Enable this module"] = "Dieses Modul aktivieren",
	["Module %s error: %s"] = "Modul %s Fehler: %s",
	["Module %s options error: %s"] = "Modul %s Optionen-Fehler: %s",
	["Skyriding action bar fix · Mount buttons"] = "Skyriding-Leiste fixieren · Reittier-Buttons",
	["Applied"] = "Angewendet",
	["Commands:"] = "Befehle:",
	["Open settings"] = "Einstellungen öffnen",
	["  /mzxr                Open settings"] = "  /mzxr                Einstellungen öffnen",
	["  /mzxr list           List modules and their state"] = "  /mzxr list           Module und Status auflisten",
	["  /mzxr on <module>    Enable a module"] = "  /mzxr on <Modul>      Modul aktivieren",
	["  /mzxr off <module>   Disable a module"] = "  /mzxr off <Modul>     Modul deaktivieren",
	["  Modules: %s"] = "  Module: %s",
	["%s (%s): %s"] = "%s (%s): %s",
	["on"] = "an",
	["off"] = "aus",
	["%s is now %s"] = "%s ist jetzt %s",
	["enabled"] = "aktiviert",
	["disabled"] = "deaktiviert",
	["Unknown module: %s"] = "Unbekanntes Modul: %s",
	["Unknown command. Type /mzxr help"] = "Unbekannter Befehl. Gib /mzxr help ein",
	["Skyriding"] = "Skyriding",
	["Cannot modify action bars in combat. Try again after combat."] = "Im Kampf können Aktionsleisten nicht geändert werden. Versuche es nach dem Kampf erneut.",
	["Not learned (skipped): %s"] = "Nicht erlernt (übersprungen): %s",
	["Use Up/Down to reorder · number = action slot"] = "Mit Hoch/Runter sortieren · Zahl = Aktionsplatz",
	["Apply Now"] = "Jetzt anwenden",
	["Restore Defaults"] = "Standard wiederherstellen",
	["Mounts"] = "Reittiere",
	["Mail"] = "Post",
	["Repair"] = "Reparatur",
	["Transmog"] = "Transmog",
	["Auction House"] = "Auktionshaus",
	["Vendor"] = "Händler",
	["Cannot summon mounts in combat"] = "Im Kampf können keine Reittiere beschworen werden",
	["Summon failed"] = "Beschwörung fehlgeschlagen",
	["Mount #%d"] = "Reittier #%d",
	["Not owned %s"] = "Nicht im Besitz %s",
	["%s only %s"] = "Nur %s %s",
	["Alliance"] = "Allianz",
	["Horde"] = "Horde",
	["Not usable here %s"] = "Hier nicht nutzbar %s",
	["Primary mount %s"] = "Hauptreittier %s",
	["Random Duo Mount"] = "Zufälliges Duo-Reittier",
	["Random Flying Mount"] = "Zufälliges Flugreittier",
	["%s none selected"] = "%s keine ausgewaehlt",
	["Random summon %s"] = "Zufall %s",
	["%s %s"] = "%s %s",
	["No owned functional mounts"] = "Keine Funktionsreittiere",
	["Summon %s"] = "Beschworen %s",
	["Drag: move the whole button group"] = "Ziehen: ganze Button-Gruppe verschieben",
	["Functional Mount: %s"] = "Funktionsreittier: %s",
	["Functional Mount"] = "Funktionsreittier",
	["No listed functional mounts owned"] = "Keine aufgelisteten Funktionsreittiere",
	["%d flying mounts selected"] = "%d Flugreittiere ausgewählt",
	["%d mounts selected"] = "%d Reittiere ausgewählt",
	["Next summon: %s"] = "Nächste Beschwörung: %s",
	["Last: %s"] = "Zuletzt: %s",
	["Please select passenger mounts in settings first"] = "Bitte zuerst Passagier-Reittiere in den Einstellungen wählen",
	["Click: select · Right-click: summon (%d)"] = "Klick: wählen · Rechtsklick: beschwören (%d)",
	["Select All"] = "Alle",
	["Deselect All"] = "Keine",
	["Summon Random"] = "Zufall rufen",
	["Click: set primary · Right-click: summon"] = "Klick: Haupt · Rechtsklick: beschwören",
	["Show floating button group"] = "Schwebende Button-Gruppe anzeigen",
	["Summon Primary Mount"] = "Primäres Reittier rufen",
	["Primary"] = "Primär",
	["Functional"] = "Funktion",
	["Random Flying"] = "Zufall Flug",
	["Random Duo"] = "Zufall Duo",
	["Language"] = "Sprache",
	["Client default"] = "Client-Standard",
}

ns.localeData["deDE"] = t

-- 客户端语言即为本语言时，加载期立即套用（核心在 ADDON_LOADED 也会重跑一次，幂等）。
if GetLocale() == "deDE" then
	for k, v in pairs(t) do
		L[k] = v
	end
end
