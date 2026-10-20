-- MzxRiding Español (Latinoamérica) / Spanish (Latin America)

local ADDON, ns = ...
local L = ns.L

ns.localeData = ns.localeData or {}

local t = {
	["MzxRiding Settings"] = "Opciones de MzxRiding",
	["Enable this module"] = "Activar este módulo",
	["Module %s error: %s"] = "Error del módulo %s: %s",
	["Module %s options error: %s"] = "Error de opciones del módulo %s: %s",
	["Skyriding action bar fix · Mount buttons"] = "Barra de Skyriding fija · Botones de montura",
	["Applied"] = "Aplicado",
	["Commands:"] = "Comandos:",
	["Open settings"] = "Abrir opciones",
	["  /mzxr                Open settings"] = "  /mzxr                Abrir opciones",
	["  /mzxr list           List modules and their state"] = "  /mzxr list           Listar módulos y su estado",
	["  /mzxr on <module>    Enable a module"] = "  /mzxr on <módulo>     Activar un módulo",
	["  /mzxr off <module>   Disable a module"] = "  /mzxr off <módulo>    Desactivar un módulo",
	["  Modules: %s"] = "  Módulos: %s",
	["%s (%s): %s"] = "%s (%s): %s",
	["on"] = "activado",
	["off"] = "desactivado",
	["%s is now %s"] = "%s ahora está %s",
	["enabled"] = "activado",
	["disabled"] = "desactivado",
	["Unknown module: %s"] = "Módulo desconocido: %s",
	["Unknown command. Type /mzxr help"] = "Comando desconocido. Escribe /mzxr help",
	["Skyriding"] = "Skyriding",
	["Cannot modify action bars in combat. Try again after combat."] = "No se pueden modificar las barras de acción en combate. Inténtalo al terminar el combate.",
	["Not learned (skipped): %s"] = "No aprendido (omitido): %s",
	["Use Up/Down to reorder · number = action slot"] = "Ordenar con Arriba/Abajo · número = ranura",
	["Apply Now"] = "Aplicar ahora",
	["Restore Defaults"] = "Restaurar",
	["Mounts"] = "Monturas",
	["Mail"] = "Correo",
	["Repair"] = "Reparación",
	["Transmog"] = "Transfiguración",
	["Auction House"] = "Casa de subastas",
	["Vendor"] = "Vendedor",
	["Cannot summon mounts in combat"] = "No se pueden invocar monturas en combate",
	["Summon failed"] = "Fallo al invocar",
	["Mount #%d"] = "Montura n.º %d",
	["Not owned %s"] = "No obtenida %s",
	["%s only %s"] = "Solo %s %s",
	["Alliance"] = "Alianza",
	["Horde"] = "Horda",
	["Not usable here %s"] = "No usable aqui %s",
	["Primary mount %s"] = "Montura principal %s",
	["Random Duo Mount"] = "Montura de dúo aleatoria",
	["Random Flying Mount"] = "Montura voladora aleatoria",
	["%s none selected"] = "%s sin seleccion",
	["Random summon %s"] = "Aleatoria %s",
	["%s %s"] = "%s %s",
	["No owned functional mounts"] = "Sin monturas funcionales",
	["Summon %s"] = "Invocado %s",
	["Drag: move the whole button group"] = "Arrastrar: mover todo el grupo de botones",
	["Functional Mount: %s"] = "Montura funcional: %s",
	["Functional Mount"] = "Montura funcional",
	["No listed functional mounts owned"] = "No posees monturas funcionales de la lista",
	["%d flying mounts selected"] = "%d monturas voladoras seleccionadas",
	["%d mounts selected"] = "%d monturas seleccionadas",
	["Next summon: %s"] = "Próxima invocación: %s",
	["Last: %s"] = "Última: %s",
	["Please select passenger mounts in settings first"] = "Selecciona primero monturas con pasajero en las opciones",
	["Click: select · Right-click: summon (%d)"] = "Clic: elegir · clic der.: invocar (%d)",
	["Select All"] = "Todo",
	["Deselect All"] = "Ninguno",
	["Summon Random"] = "Invocar al azar",
	["Click: set primary · Right-click: summon"] = "Clic: principal · clic der.: invocar",
	["Show floating button group"] = "Mostrar grupo de botones flotante",
	["Summon Primary Mount"] = "Invocar montura principal",
	["Primary"] = "Principal",
	["Functional"] = "Función",
	["Random Flying"] = "Vuelo al azar",
	["Random Duo"] = "Dúo al azar",
	["Language"] = "Idioma",
	["Client default"] = "Predeterminado del cliente",
}

ns.localeData["esMX"] = t

-- 客户端语言即为本语言时，加载期立即套用（核心在 ADDON_LOADED 也会重跑一次，幂等）。
if GetLocale() == "esMX" then
	for k, v in pairs(t) do
		L[k] = v
	end
end
