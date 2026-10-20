-- MzxRiding Français / French

local ADDON, ns = ...
local L = ns.L

ns.localeData = ns.localeData or {}

local t = {
	["MzxRiding Settings"] = "Options de MzxRiding",
	["Enable this module"] = "Activer ce module",
	["Module %s error: %s"] = "Erreur du module %s : %s",
	["Module %s options error: %s"] = "Erreur des options du module %s : %s",
	["Skyriding action bar fix · Mount buttons"] = "Barre de Skyriding fixe · Boutons de monture",
	["Applied"] = "Appliqué",
	["Commands:"] = "Commandes :",
	["Open settings"] = "Ouvrir les options",
	["  /mzxr                Open settings"] = "  /mzxr                Ouvrir les options",
	["  /mzxr list           List modules and their state"] = "  /mzxr list           Lister les modules et leur état",
	["  /mzxr on <module>    Enable a module"] = "  /mzxr on <module>    Activer un module",
	["  /mzxr off <module>   Disable a module"] = "  /mzxr off <module>   Désactiver un module",
	["  Modules: %s"] = "  Modules : %s",
	["%s (%s): %s"] = "%s (%s) : %s",
	["on"] = "activé",
	["off"] = "désactivé",
	["%s is now %s"] = "%s est maintenant %s",
	["enabled"] = "activé",
	["disabled"] = "désactivé",
	["Unknown module: %s"] = "Module inconnu : %s",
	["Unknown command. Type /mzxr help"] = "Commande inconnue. Tapez /mzxr help",
	["Skyriding"] = "Skyriding",
	["Cannot modify action bars in combat. Try again after combat."] = "Impossible de modifier les barres d'action en combat. Réessayez après le combat.",
	["Not learned (skipped): %s"] = "Non appris (ignoré) : %s",
	["Use Up/Down to reorder · number = action slot"] = "Réorganiser avec Haut/Bas · nombre = emplacement",
	["Apply Now"] = "Appliquer",
	["Restore Defaults"] = "Réinitialiser",
	["Mounts"] = "Montures",
	["Mail"] = "Courrier",
	["Repair"] = "Réparation",
	["Transmog"] = "Transmogrification",
	["Auction House"] = "Hôtel des ventes",
	["Vendor"] = "Vendeur",
	["Cannot summon mounts in combat"] = "Impossible d'invoquer une monture en combat",
	["Summon failed"] = "Échec de l'invocation",
	["Mount #%d"] = "Monture n°%d",
	["Not owned %s"] = "Non possedee %s",
	["%s only %s"] = "%s uniquement %s",
	["Alliance"] = "Alliance",
	["Horde"] = "Horde",
	["Not usable here %s"] = "Inutilisable ici %s",
	["Primary mount %s"] = "Monture principale %s",
	["Random Duo Mount"] = "Monture duo aléatoire",
	["Random Flying Mount"] = "Monture volante aléatoire",
	["%s none selected"] = "%s aucune selection",
	["Random summon %s"] = "Aleatoire %s",
	["%s %s"] = "%s %s",
	["No owned functional mounts"] = "Aucune monture fonctionnelle",
	["Summon %s"] = "Invoque %s",
	["Drag: move the whole button group"] = "Glisser : déplacer tout le groupe de boutons",
	["Functional Mount: %s"] = "Monture fonctionnelle : %s",
	["Functional Mount"] = "Monture fonctionnelle",
	["No listed functional mounts owned"] = "Aucune monture fonctionnelle listée possédée",
	["%d flying mounts selected"] = "%d montures volantes sélectionnées",
	["%d mounts selected"] = "%d montures sélectionnées",
	["Next summon: %s"] = "Prochaine invocation : %s",
	["Last: %s"] = "Dernière : %s",
	["Please select passenger mounts in settings first"] = "Sélectionnez d'abord des montures à passager dans les options",
	["Click: select · Right-click: summon (%d)"] = "Clic : choisir · clic droit : invoquer (%d)",
	["Select All"] = "Tout",
	["Deselect All"] = "Aucun",
	["Summon Random"] = "Invoquer au hasard",
	["Click: set primary · Right-click: summon"] = "Clic : principal · clic droit : invoquer",
	["Show floating button group"] = "Afficher le groupe de boutons flottant",
	["Summon Primary Mount"] = "Invoquer la monture principale",
	["Primary"] = "Principale",
	["Functional"] = "Fonction",
	["Random Flying"] = "Vol aléatoire",
	["Random Duo"] = "Duo aléatoire",
	["Language"] = "Langue",
	["Client default"] = "Par défaut du client",
}

ns.localeData["frFR"] = t

-- 客户端语言即为本语言时，加载期立即套用（核心在 ADDON_LOADED 也会重跑一次，幂等）。
if GetLocale() == "frFR" then
	for k, v in pairs(t) do
		L[k] = v
	end
end
