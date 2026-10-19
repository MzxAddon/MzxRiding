-- MzxRiding Русский / Russian

local ADDON, ns = ...
local L = ns.L

ns.localeData = ns.localeData or {}

local t = {
	["MzxRiding Settings"] = "Настройки MzxRiding",
	["Enable this module"] = "Включить этот модуль",
	["Module %s error: %s"] = "Ошибка модуля %s: %s",
	["Module %s options error: %s"] = "Ошибка настроек модуля %s: %s",
	["Skyriding action bar fix · Mount buttons"] = "Фиксация панели Skyriding · Кнопки транспорта",
	["Commands:"] = "Команды:",
	["Open settings"] = "Открыть настройки",
	["  /mzxr                Open settings"] = "  /mzxr                Открыть настройки",
	["  /mzxr list           List modules and their state"] = "  /mzxr list           Список модулей и их состояние",
	["  /mzxr on <module>    Enable a module"] = "  /mzxr on <модуль>     Включить модуль",
	["  /mzxr off <module>   Disable a module"] = "  /mzxr off <модуль>    Выключить модуль",
	["  Modules: %s"] = "  Модули: %s",
	["%s (%s): %s"] = "%s (%s): %s",
	["on"] = "вкл",
	["off"] = "выкл",
	["%s is now %s"] = "%s теперь %s",
	["enabled"] = "включён",
	["disabled"] = "выключен",
	["Unknown module: %s"] = "Неизвестный модуль: %s",
	["Unknown command. Type /mzxr help"] = "Неизвестная команда. Введите /mzxr help",
	["Skyriding"] = "Skyriding",
	["Cannot modify action bars in combat. Try again after combat."] = "Нельзя изменять панели действий в бою. Повторите после боя.",
	["Already matches the configuration; no changes needed."] = "Уже соответствует настройкам; изменения не требуются.",
	["Placed %d spells into slots %d-%d."] = "Размещено %d заклинаний в ячейки %d-%d.",
	["Not learned (skipped): %s"] = "Не изучено (пропущено): %s",
	["Use Up/Down to reorder · number = action slot"] = "Порядок Вверх/Вниз · число = ячейка",
	["Apply Now"] = "Применить",
	["Restore Defaults"] = "Сбросить",
	["Mounts"] = "Транспорт",
	["Mail"] = "Почта",
	["Repair"] = "Ремонт",
	["Transmog"] = "Трансмогрификация",
	["Auction House"] = "Аукцион",
	["Vendor"] = "Торговец",
	["Cannot summon mounts in combat"] = "Нельзя призвать транспорт в бою",
	["Summon failed"] = "Не удалось призвать",
	["Mount #%d"] = "Транспорт #%d",
	["You do not own this mount, cannot set as primary: %s"] = "У вас нет этого транспорта, нельзя назначить основным: %s",
	["This mount is restricted to %s characters: %s"] = "Этот транспорт доступен только персонажам %s: %s",
	["Alliance"] = "Альянса",
	["Horde"] = "Орды",
	["This mount is not usable on your current character: %s"] = "Этот транспорт недоступен вашему текущему персонажу: %s",
	["Primary functional mount set to: %s"] = "Основной функциональный транспорт: %s",
	["Random Duo Mount"] = "Случайный транспорт на двоих",
	["Random Flying Mount"] = "Случайный летающий транспорт",
	["%s: You have not selected any mounts. Please choose in settings."] = "%s: вы не выбрали ни одного транспорта. Выберите в настройках.",
	["Randomly summoned: %s"] = "Случайно призван: %s",
	["%s: %s"] = "%s: %s",
	["You do not own any listed functional mounts."] = "У вас нет ни одного из перечисленных функциональных средств передвижения.",
	["Summoned: %s"] = "Призван: %s",
	["Drag: move the whole button group"] = "Перетащите: переместить всю группу кнопок",
	["Functional Mount: %s"] = "Функциональный транспорт: %s",
	["Functional Mount"] = "Функциональный транспорт",
	["No listed functional mounts owned"] = "Нет перечисленных функциональных средств передвижения",
	["%d flying mounts selected"] = "Выбрано летающих: %d",
	["%d mounts selected"] = "Выбрано транспорта: %d",
	["Next summon: %s"] = "Следующий вызов: %s",
	["Last: %s"] = "Прошлый: %s",
	["Please select passenger mounts in settings first"] = "Сначала выберите транспорт на двоих в настройках",
	["Click: select · Right-click: summon (%d)"] = "Клик: выбрать · ПКМ: призвать (%d)",
	["Select All"] = "Все",
	["Deselect All"] = "Ничего",
	["Summon Random"] = "Случайный",
	["Click: set primary · Right-click: summon"] = "Клик: основная · ПКМ: призвать",
	["Show floating button group"] = "Показывать плавающую группу кнопок",
	["Summon Primary Mount"] = "Призвать основной",
	["Primary"] = "Основной",
	["Functional"] = "Функции",
	["Random Flying"] = "Случайный полёт",
	["Random Duo"] = "Случайный дуэт",
	["Language"] = "Язык",
	["Client default"] = "По умолчанию клиента",
}

ns.localeData["ruRU"] = t

-- 客户端语言即为本语言时，加载期立即套用（核心在 ADDON_LOADED 也会重跑一次，幂等）。
if GetLocale() == "ruRU" then
	for k, v in pairs(t) do
		L[k] = v
	end
end
