-- MzxRiding Italiano / Italian

local ADDON, ns = ...
local L = ns.L

ns.localeData = ns.localeData or {}

local t = {
	["MzxRiding Settings"] = "Impostazioni MzxRiding",
	["Enable this module"] = "Attiva questo modulo",
	["Module %s error: %s"] = "Errore del modulo %s: %s",
	["Module %s options error: %s"] = "Errore opzioni del modulo %s: %s",
	["Skyriding action bar fix · Mount buttons"] = "Barra di Skyriding fissa · Pulsanti delle cavalcature",
	["Commands:"] = "Comandi:",
	["Open settings"] = "Apri impostazioni",
	["  /mzxr                Open settings"] = "  /mzxr                Apri impostazioni",
	["  /mzxr list           List modules and their state"] = "  /mzxr list           Elenca moduli e stato",
	["  /mzxr on <module>    Enable a module"] = "  /mzxr on <modulo>     Attiva un modulo",
	["  /mzxr off <module>   Disable a module"] = "  /mzxr off <modulo>    Disattiva un modulo",
	["  Modules: %s"] = "  Moduli: %s",
	["%s (%s): %s"] = "%s (%s): %s",
	["on"] = "attivo",
	["off"] = "disattivo",
	["%s is now %s"] = "%s ora è %s",
	["enabled"] = "attivato",
	["disabled"] = "disattivato",
	["Unknown module: %s"] = "Modulo sconosciuto: %s",
	["Unknown command. Type /mzxr help"] = "Comando sconosciuto. Digita /mzxr help",
	["Skyriding"] = "Skyriding",
	["Cannot modify action bars in combat. Try again after combat."] = "Impossibile modificare le barre d'azione in combattimento. Riprova dopo il combattimento.",
	["Already matches the configuration; no changes needed."] = "Già conforme alla configurazione; nessuna modifica necessaria.",
	["Placed %d spells into slots %d-%d."] = "%d incantesimi inseriti negli slot %d-%d.",
	["Not learned (skipped): %s"] = "Non appreso (saltato): %s",
	["Use Up/Down to reorder · number = action slot"] = "Riordina con Su/Giù · numero = slot",
	["Apply Now"] = "Applica ora",
	["Restore Defaults"] = "Ripristina",
	["Mounts"] = "Cavalcature",
	["Mail"] = "Posta",
	["Repair"] = "Riparazione",
	["Transmog"] = "Trasmogrificazione",
	["Auction House"] = "Casa d'aste",
	["Vendor"] = "Venditore",
	["Cannot summon mounts in combat"] = "Impossibile evocare cavalcature in combattimento",
	["Summon failed"] = "Evocazione fallita",
	["Mount #%d"] = "Cavalcatura n. %d",
	["You do not own this mount, cannot set as primary: %s"] = "Non possiedi questa cavalcatura, impossibile impostarla come principale: %s",
	["This mount is restricted to %s characters: %s"] = "Questa cavalcatura è riservata ai personaggi %s: %s",
	["Alliance"] = "Alleanza",
	["Horde"] = "Orda",
	["This mount is not usable on your current character: %s"] = "Questa cavalcatura non è utilizzabile dal tuo personaggio attuale: %s",
	["Primary functional mount set to: %s"] = "Cavalcatura funzionale principale impostata: %s",
	["Random Duo Mount"] = "Cavalcatura doppia casuale",
	["Random Flying Mount"] = "Cavalcatura volante casuale",
	["%s: You have not selected any mounts. Please choose in settings."] = "%s: non hai selezionato alcuna cavalcatura. Scegli nelle impostazioni.",
	["Randomly summoned: %s"] = "Evocata casualmente: %s",
	["%s: %s"] = "%s: %s",
	["You do not own any listed functional mounts."] = "Non possiedi nessuna delle cavalcature funzionali elencate.",
	["Summoned: %s"] = "Evocata: %s",
	["Drag: move the whole button group"] = "Trascina: sposta l'intero gruppo di pulsanti",
	["Functional Mount: %s"] = "Cavalcatura funzionale: %s",
	["Functional Mount"] = "Cavalcatura funzionale",
	["No listed functional mounts owned"] = "Nessuna cavalcatura funzionale elencata posseduta",
	["%d flying mounts selected"] = "%d cavalcature volanti selezionate",
	["%d mounts selected"] = "%d cavalcature selezionate",
	["Next summon: %s"] = "Prossima evocazione: %s",
	["Last: %s"] = "Ultima: %s",
	["Please select passenger mounts in settings first"] = "Seleziona prima le cavalcature con passeggero nelle impostazioni",
	["Click: select · Right-click: summon (%d)"] = "Clic: scegli · destro: evoca (%d)",
	["Select All"] = "Tutti",
	["Deselect All"] = "Nessuno",
	["Summon Random"] = "Evoca casuale",
	["Click: set primary · Right-click: summon"] = "Clic: principale · destro: evoca",
	["Show floating button group"] = "Mostra gruppo di pulsanti mobile",
	["Summon Primary Mount"] = "Evoca cavalcatura principale",
	["Primary"] = "Principale",
	["Functional"] = "Funzione",
	["Random Flying"] = "Volo casuale",
	["Random Duo"] = "Doppia casuale",
	["Language"] = "Lingua",
	["Client default"] = "Predefinito del client",
}

ns.localeData["itIT"] = t

-- 客户端语言即为本语言时，加载期立即套用（核心在 ADDON_LOADED 也会重跑一次，幂等）。
if GetLocale() == "itIT" then
	for k, v in pairs(t) do
		L[k] = v
	end
end
