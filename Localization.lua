-- MzxRiding 本地化 / Localization
-- 根据客户端语言（GetLocale）加载对应文本；英文为基准，其他语言只覆盖自身。
-- 用法：其他文件 `local L = ns.L`，再用 L["English string"] 取当前语言文本。
-- 未翻译的键会回退为英文键文本（永不返回 nil）。
local ADDON, ns = ...

local L = {}
ns.L = L

-- 英文基准（同时也是所有缺失翻译的兜底）。键 = 值，故只列一次。
local en = {
	-- 通用 / 配置窗
	"MzxRiding Settings",
	"Enable this module",
	"Module %s error: %s",
	"Module %s options error: %s",
	"Skyriding action bar fix · Mount buttons",
	"Drag to move the button",
	-- 斜杠命令
	"Commands:",
	"Open settings",
	"  /mzxr                Open settings",
	"  /mzxr list           List modules and their state",
	"  /mzxr on <module>    Enable a module",
	"  /mzxr off <module>   Disable a module",
	"  Modules: %s",
	"%s (%s): %s",
	"on",
	"off",
	"%s is now %s",
	"enabled",
	"disabled",
	"Unknown module: %s",
	"Unknown command. Type /mzxr help",
	-- 御龙术模块 / Skyriding
	"Skyriding",
	"Whirling Surge",
	"Surge Forward",
	"Second Wind",
	"Aerial Halt",
	"Skyward Ascent",
	"Cannot modify action bars in combat. Try again after combat.",
	"Already matches the configuration; no changes needed.",
	"Placed %d spells into slots %d-%d.",
	"Not learned (skipped): %s",
	"Use Up/Down to reorder · number = action slot",
	"Apply Now",
	"Restore Defaults",
	-- 坐骑模块 / Mounts
	"Mounts",
	"Mail",
	"Repair",
	"Transmog",
	"Auction House",
	"Vendor",
	-- 坐骑名兜底（正常显示客户端本地化名称，仅在 API 取不到名字时用到）
	"Sporebearer Fungal Strider",
	"Trader's Gilded Brutosaur",
	"Mighty Caravan Brutosaur",
	"Hearthkeeper's Wandering Caravan",
	"Grizzly Hills Packmaster",
	"Grand Expedition Yak",
	"Traveler's Tundra Mammoth (Alliance)",
	"Traveler's Tundra Mammoth (Horde)",
	-- 坐骑消息
	"Cannot summon mounts in combat",
	"Summon failed",
	"Mount #%d",
	"You do not own this mount, cannot set as primary: %s",
	"This mount is restricted to %s characters: %s",
	"Alliance",
	"Horde",
	"This mount is not usable on your current character: %s",
	"Primary functional mount set to: %s",
	"Random Duo Mount",
	"Random Flying Mount",
	"%s: You have not selected any mounts. Please choose in settings.",
	"Randomly summoned: %s",
	"%s: %s",
	"You do not own any listed functional mounts.",
	"Summoned: %s",
	-- 悬浮按钮 tooltip
	"Drag: move the whole button group",
	"Functional Mount: %s",
	"Functional Mount",
	"No listed functional mounts owned",
	"Open/close settings",
	"Summon primary mount",
	"Choose primary mount",
	"Summon and reroll",
	"%d flying mounts selected",
	"%d mounts selected",
	"Next summon: %s",
	"Last: %s",
	"Please select passenger mounts in settings first",
	-- 设置界面
	"Click: select · Right-click: summon (%d)",
	"Select All",
	"Deselect All",
	"Summon Random",
	"Click: set primary · Right-click: summon",
	"Set as primary mount",
	"Summon now",
	"Show floating button group",
	"Summon Primary Mount",
	"Primary",
	"Functional",
	"Random Flying",
	"Random Duo",
	"Refresh Lists",
	"Rescan mounts and rebuild all three lists.",
	"Language",
	"Client default",
}

for i = 1, #en do
	L[en[i]] = en[i]
end

setmetatable(L, {
	__index = function(_, key)
		return key
	end,
})

-- 各语言文件在加载时把自己的译文表登记到这里（键 = 语言代码）。
ns.localeData = ns.localeData or {}

-- 已知语言代码白名单：enUS/enGB 刻意没有译文文件（直接用英文基准），
-- 所以「有效」不能以 localeData 是否存在来判断，否则英文会被误清成跟随客户端。
ns.knownLocales = {
	enUS = true, enGB = true, zhCN = true, zhTW = true, koKR = true, deDE = true,
	frFR = true, esES = true, esMX = true, ruRU = true, ptBR = true, itIT = true,
}

-- 当前生效语言（nil 表示尚未应用；核心在 ADDON_LOADED 里调用 ApplyLocale）。
ns.activeLocale = nil

-- 先把所有键重置为英文基准，再套用指定语言的数据；缺失的键自然回退英文。
-- 「语言」标签页切换语言就是设置 db.locale 后 ReloadUI，重载时核心会以此重跑本函数。
function ns.ApplyLocale(code)
	for i = 1, #en do
		L[en[i]] = en[i]
	end
	local data = code and ns.localeData[code]
	if data then
		for k, v in pairs(data) do
			L[k] = v
		end
	end
	ns.activeLocale = code
end
