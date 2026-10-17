-- 模块：坐骑
-- 一个可拖动的悬浮按钮组（位置存档），由三个按钮组成：
--   ① 功能坐骑     左键 = 召唤主选（修理/杂货/幻化/拍卖行/邮箱）；右键 = 选择框
--   ② 随机飞行坐骑 左键 = 从设置里勾选的飞行坐骑中随机召唤
--   ③ 随机双人坐骑 左键 = 从设置里勾选的双人飞行坐骑中随机召唤
-- 设置界面：本模块分三页（功能 / 随机飞行 / 随机双人）。随机页用可滑动列表，
-- 支持 全选 / 全不选 / 多选（点行即切换勾选，金色高亮 = 已选）。
local ADDON, ns = ...
local M = ns.M
local L = ns.L

-- ------------------------------------------------------------------ 数据表

-- 已知功能性坐骑（暴雪坐骑日志 MountID）。label 仅作兜底，正常显示客户端本地化名称。
-- 想扩充直接往表里加即可。tags 是服务键数组（见 TagsText），按客户端语言显示。
local FUNCTIONAL_MOUNTS = {
	{ id = 3137, label = L["Sporebearer Fungal Strider"], tags = { "Mail", "Repair", "Transmog", "Auction House" } },     -- Sporebearer Fungal Strider
	{ id = 2265, label = L["Trader's Gilded Brutosaur"], tags = { "Auction House", "Mail" } },                             -- Trader's Gilded Brutosaur
	{ id = 1039, label = L["Mighty Caravan Brutosaur"], tags = { "Auction House", "Vendor", "Repair" } },                 -- Mighty Caravan Brutosaur
	{ id = 2982, label = L["Hearthkeeper's Wandering Caravan"], tags = { "Repair", "Mail" } },                             -- Hearthkeeper's Wandering Caravan
	{ id = 2237, label = L["Grizzly Hills Packmaster"], tags = { "Repair", "Transmog" } },                                 -- Grizzly Hills Packmaster
	{ id = 460,  label = L["Grand Expedition Yak"], tags = { "Repair", "Vendor", "Transmog" } },                           -- Grand Expedition Yak
	{ id = 280,  label = L["Traveler's Tundra Mammoth (Alliance)"], tags = { "Repair", "Vendor" } },                       -- Traveler's Tundra Mammoth (A)
	{ id = 284,  label = L["Traveler's Tundra Mammoth (Horde)"], tags = { "Repair", "Vendor" } },                          -- Traveler's Tundra Mammoth (H)
}

local byId = {}
for _, e in ipairs(FUNCTIONAL_MOUNTS) do
	byId[e.id] = e
end

-- 服务标签：tags 键数组 → 按客户端语言拼成 " · " 分隔的一行
local function TagsText(tags)
	local t = {}
	for i = 1, #tags do
		t[i] = L[tags[i]]
	end
	return table.concat(t, " · ")
end

-- 已知「可载人的多乘客坐骑」MountID（暴雪坐骑日志）。来源：Warcraft Wiki「Passenger mounts」分类。
-- 用途：「随机双人飞行坐骑」页只列出玩家已拥有、属于本表、且可飞行的坐骑，杜绝混入单人坐骑。
local DUO_MOUNTS = {
	[382]  = true, -- X-53 兜风火箭（飞行）
	[407]  = true, -- 砂岩龙 / 沙之瓶（飞行）
	[455]  = true, -- 黑曜石夜翼（飞行）
	[959]  = true, -- 暴风城霄鹰（BlizzCon，飞行）
	[960]  = true, -- 奥格瑞玛拦截者（BlizzCon，飞行）
	[1025] = true, -- 群体意识（飞行）
	[1698] = true, -- 火箭切割机 9001（飞行）
	[240]  = true, -- 机械路霸（地面）
	[275]  = true, -- 机械师的摩托（地面）
	[286]  = true, -- 黑色战争猛犸（联盟，地面）
	[287]  = true, -- 黑色战争猛犸（部落，地面）
	[288]  = true, -- 冰雪猛犸（部落，地面）
	[289]  = true, -- 冰雪猛犸（联盟，地面）
	[460]  = true, -- 大探险家牦牛（地面）
	[280]  = true, -- 旅者的苔原猛犸象（联盟，地面）
	[284]  = true, -- 旅者的苔原猛犸象（部落，地面）
	[1039] = true, -- 雄壮商队雷龙（地面）
	[2265] = true, -- 贸易大亨鎏金雷龙（地面）
	[1287] = true, -- 探险者的丛林跳跃者（地面）
	[1288] = true, -- 探险者的沙丘行者（地面）
	[3137] = true, -- 孢囊真菌行者（地面）
}

-- 功能坐骑里的阵营限定项：只有对应阵营的玩家才显示
local MOUNT_FACTION = {
	[280] = "Alliance", -- 旅者的苔原猛犸象（联盟）
	[284] = "Horde",    -- 旅者的苔原猛犸象（部落）
}

local function PlayerFaction()
	if UnitFactionGroup then
		return UnitFactionGroup("player")
	end
	return nil
end

-- 阵营限定坐骑：仅在匹配阵营时可显示/选用
local function FactionOK(id)
	local req = MOUNT_FACTION[id]
	if not req then
		return true
	end
	return PlayerFaction() == req
end

-- 飞行坐骑判定用的 mountTypeID（暴雪官方坐骑能力编号，见 Warcraft Wiki）。
local FLYING_TYPE_IDS = {
	[242] = true, -- Swift Spectral Gryphon（隐藏）
	[247] = true, -- Disc of the Red Flying Cloud
	[248] = true, -- 绝大多数飞行坐骑
	[398] = true, -- Kua'fon's Harness
	[402] = true, -- 龙骑（Dragonriding）
	[407] = true, -- Deepstar Polyp / Otterworldly Ottuk Carrier
	[424] = true, -- 龙骑动画坐骑（含暂未启用龙骑的）
	[436] = true, -- Wondrous Wavewhisker
}

local QUESTION_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"
local FLY_DEFAULT_ICON = "Interface\\Icons\\Ability_Mount_Gryphon_01"
local DUO_DEFAULT_ICON = "Interface\\Icons\\Ability_Mount_Mammoth_White"

local MENU_WIDTH = 250
local MENU_PAD = 4

local GROUP_BUTTON = 44
local GROUP_GAP = 3
local GROUP_PAD = 3

local mod = {
	key = "mounts",
	name = L["Mounts"],
	nameKey = "Mounts",
	defaultEnabled = true,
}
M:RegisterModule(mod)

-- ------------------------------------------------------------------ 坐骑日志

local function J()
	return C_MountJournal
end

-- 返回 { id, name, icon, collected, usable, steadyFlight }
local function MountInfo(id)
	local out = { id = id, collected = false, usable = false, steadyFlight = false }
	local cj = J()
	local fn = cj and cj.GetMountInfoByID
	if fn then
		-- name, spellID, icon, isActive, isUsable, sourceType, isFavorite,
		-- isFactionSpecific, faction, shouldHideOnChar, isCollected, mountID, isSteadyFlight
		local ok, name, _, icon, _, isUsable, _, _, _, _, _, isCollected, _, isSteadyFlight = pcall(fn, id)
		if ok then
			out.name = (type(name) == "string") and name or nil
			out.icon = icon
			out.collected = isCollected and true or false
			out.usable = isUsable and true or false
			out.steadyFlight = isSteadyFlight and true or false
		end
	end
	return out
end

-- 已拥有（不看此刻能否召唤：isUsable 在禁坐骑区域会整体变 false）
local function OwnedOK(id)
	return MountInfo(id).collected and FactionOK(id)
end

-- 池内可用：已拥有 + 此刻真的能召唤
local function PoolOK(id)
	return OwnedOK(id) and MountInfo(id).usable
end

local function MountTypeID(id)
	local cj = J()
	local fn = cj and cj.GetMountInfoExtraByID
	if not fn then
		return nil
	end
	local ok, _, _, _, _, mountTypeID = pcall(fn, id)
	if ok then
		return mountTypeID
	end
	return nil
end

local dragonSet
local function DragonridingSet()
	if dragonSet == nil then
		dragonSet = {}
		local cj = J()
		if cj and cj.GetCollectedDragonridingMounts then
			local ok, t = pcall(cj.GetCollectedDragonridingMounts)
			if ok and type(t) == "table" then
				for _, id in ipairs(t) do
					dragonSet[id] = true
				end
			end
		end
	end
	return dragonSet
end

-- 飞行坐骑：稳定飞行能力 或 龙骑 或 mountTypeID 属于飞行类型（三路取并集，尽量不漏）
local function IsFlyingMount(id)
	local info = MountInfo(id)
	if info.steadyFlight then
		return true
	end
	if DragonridingSet()[id] then
		return true
	end
	local mt = MountTypeID(id)
	if mt and FLYING_TYPE_IDS[mt] then
		return true
	end
	return false
end

-- 已拥有的飞行坐骑列表（按名称排序，缓存）
function mod:CollectedFlying()
	if self._flyCache then
		return self._flyCache
	end
	local list = {}
	local cj = J()
	local fn = cj and cj.GetMountIDs
	if fn then
		local ok, ids = pcall(fn)
		if ok and type(ids) == "table" then
			for _, id in ipairs(ids) do
				local info = MountInfo(id)
				if PoolOK(id) and IsFlyingMount(id) then
					list[#list + 1] = { id = id, name = info.name or ("#" .. tostring(id)), icon = info.icon }
				end
			end
		end
	end
	table.sort(list, function(a, b)
		return (a.name or "") < (b.name or "")
	end)
	-- 禁坐骑区域会扫不出任何可用坐骑：此时保留上一次的结果，不让列表变空
	if #list == 0 and self._flyCache and #self._flyCache > 0 then
		return self._flyCache
	end
	self._flyCache = list
	return list
end

function mod:InvalidateFlyCache()
	self._flyCache = nil
	self._duoCache = nil
end

-- 已拥有的「双人/多乘客」坐骑列表（只保留可飞行者），按名称排序，缓存
function mod:CollectedDuo()
	if self._duoCache then
		return self._duoCache
	end
	local list = {}
	local cj = J()
	local fn = cj and cj.GetMountIDs
	if fn then
		local ok, ids = pcall(fn)
		if ok and type(ids) == "table" then
			for _, id in ipairs(ids) do
				if DUO_MOUNTS[id] then
					local info = MountInfo(id)
					if PoolOK(id) and IsFlyingMount(id) then
						list[#list + 1] = { id = id, name = info.name or ("#" .. tostring(id)), icon = info.icon }
					end
				end
			end
		end
	end
	table.sort(list, function(a, b)
		return (a.name or "") < (b.name or "")
	end)
	if #list == 0 and self._duoCache and #self._duoCache > 0 then
		return self._duoCache
	end
	self._duoCache = list
	return list
end

-- 随机池的可选坐骑来源：fly = 全部已拥有飞行坐骑；duo = 已拥有的双人飞行坐骑
function mod:PoolList(which)
	if which == "duo" then
		return self:CollectedDuo()
	end
	return self:CollectedFlying()
end

local function OwnedList()
	local list = {}
	for _, e in ipairs(FUNCTIONAL_MOUNTS) do
		if OwnedOK(e.id) then
			list[#list + 1] = e
		end
	end
	return list
end

local function SummonFallback(id)
	local cj = J()
	if not (cj and cj.GetMountIDs and CallCompanion) then
		return false
	end
	local ok, ids = pcall(cj.GetMountIDs)
	if not ok or type(ids) ~= "table" then
		return false
	end
	for idx, mid in ipairs(ids) do
		if mid == id then
			return (pcall(CallCompanion, "MOUNT", idx)) and true or false
		end
	end
	return false
end

local function SummonMount(id)
	if InCombatLockdown() then
		return false, L["Cannot summon mounts in combat"]
	end
	local cj = J()
	if cj and cj.SummonByID then
		local ok = pcall(cj.SummonByID, id)
		if ok then
			return true
		end
	end
	if SummonFallback(id) then
		return true
	end
	return false, L["Summon failed"]
end

function mod:MountName(id)
	local info = MountInfo(id)
	return info.name or string.format(L["Mount #%d"], id)
end

-- ------------------------------------------------------------------ 主选逻辑

function mod:LabelFor(id)
	local e = byId[id]
	local info = MountInfo(id)
	return info.name or (e and e.label) or string.format(L["Mount #%d"], id)
end

function mod:GetChosenId()
	return self.db and self.db.primary or nil
end

function mod:GetPrimaryId()
	local chosen = self:GetChosenId()
	if chosen then
		if OwnedOK(chosen) then
			return chosen
		end
	end
	local owned = OwnedList()
	if owned[1] then
		return owned[1].id
	end
	return nil
end

function mod:SetPrimary(id)
	if not self.db then
		return
	end
	if not MountInfo(id).collected then
		M.Print(string.format(L["You do not own this mount, cannot set as primary: %s"], self:LabelFor(id)))
		return
	end
	if not FactionOK(id) then
		M.Print(string.format(L["This mount is restricted to %s characters: %s"], L[MOUNT_FACTION[id] == "Alliance" and "Alliance" or "Horde"], self:LabelFor(id)))
		return
	end
	if self.db.primary ~= id then
		self.db.primary = id
		M.Print(string.format(L["Primary functional mount set to: %s"], self:LabelFor(id)))
	end
	self:UpdateButtons()
	M:RefreshConfigIfOpen()
end

-- ------------------------------------------------------------------ 随机池

-- which = "fly" | "duo"
function mod:Pool(which)
	local store = self.charDb or self.db
	if not store then
		return {}
	end
	local poolKey = (which == "duo") and "duoPool" or "flyPool"
	local initKey = (which == "duo") and "duoPoolInit" or "flyPoolInit"
	if type(store[poolKey]) ~= "table" then
		store[poolKey] = {}
	end
	local list = self:PoolList(which)
	-- 随机飞行 / 随机双人：每角色首次进入默认全选；列表尚未就绪时不写 init，等下次再播种
	if not store[initKey] and #list > 0 then
		store[initKey] = true
		for _, e in ipairs(list) do
			store[poolKey][e.id] = true
		end
	end
	return store[poolKey]
end

function mod:IsPoolSelected(which, id)
	return self:Pool(which)[id] == true
end

function mod:TogglePoolEntry(which, id)
	local pool = self:Pool(which)
	if pool[id] == true then
		pool[id] = nil
	else
		if not PoolOK(id) then
			M.Print(string.format(L["This mount is not usable on your current character: %s"], self:LabelFor(id)))
			return
		end
		pool[id] = true
	end
	self:RevalidatePending(which)
end

function mod:SetPoolAll(which, on)
	local pool = self:Pool(which)
	for k in pairs(pool) do
		pool[k] = nil
	end
	if on then
		for _, e in ipairs(self:PoolList(which)) do
			if PoolOK(e.id) then
				pool[e.id] = true
			end
		end
	end
	self:RevalidatePending(which)
end

-- 从池里随机挑一只（尽量避开 avoid），返回 id 或 nil
function mod:PickRandom(which, avoid)
	local pool = self:Pool(which)
	local ids = {}
	for _, e in ipairs(self:PoolList(which)) do
		if pool[e.id] == true and PoolOK(e.id) then
			ids[#ids + 1] = e.id
		end
	end
	local n = #ids
	if n == 0 then
		return nil
	end
	local pick = ids[math.random(n)]
	if n > 1 and avoid then
		for _ = 1, 8 do
			if pick ~= avoid then
				break
			end
			pick = ids[math.random(n)]
		end
		if pick == avoid then
			for i = 1, n do
				if ids[i] ~= avoid then
					pick = ids[i]
					break
				end
			end
		end
	end
	return pick
end

function mod:SummonRandom(which)
	local label = (which == "duo") and L["Random Duo Mount"] or L["Random Flying Mount"]
	local pool = self:Pool(which)
	local pending = self:GetPendingRandom(which)
	local pick
	-- 预选的坐骑若还在池中就直接召唤它；否则重新挑一只
	if pending and pool[pending] == true and PoolOK(pending) then
		pick = pending
	else
		pick = self:PickRandom(which, (which == "duo") and self.lastDuo or self.lastFly)
	end
	if not pick then
		M.Print(string.format(L["%s: You have not selected any mounts. Please choose in settings."], label))
		return
	end

	local name = self:MountName(pick)
	local ok, err = SummonMount(pick)
	if ok then
		if which == "duo" then
			self.lastDuo = pick
		else
			self.lastFly = pick
		end
		M.Print(string.format(L["Randomly summoned: %s"], name))
	else
		M.Print(string.format(L["%s: %s"], err or L["Summon failed"], name))
	end
	-- 召唤后立刻预选下一只，按钮图标随之更新
	self:NextRandom(which)
	self:UpdateButtons()
end

-- ------------------------------------------------------------------ 右键选择框（功能坐骑）

function mod:HideMenu()
	if self.menu then
		self.menu:Hide()
	end
	if self.catcher then
		self.catcher:Hide()
		self.catcher = nil
	end
end

-- 预选下一只随机坐骑：按钮上始终备好一只待召唤的坐骑，
-- 点击时召唤它并立刻再预选一只，这样第一次加载就不用塞默认坐骑。
function mod:NextRandom(which)
	local prev = (which == "duo") and self.lastDuo or self.lastFly
	local id = self:PickRandom(which, prev)
	-- 池为空时清空预选，按钮回退到默认图标
	self[which] = id
	return id
end

function mod:GetPendingRandom(which)
	local v = self[which]
	if type(v) == "number" then
		return v
	end
	return nil
end

-- 预选失效（不在池中/被取消勾选）时重新挑一只
function mod:RevalidatePending(which)
	local pending = self:GetPendingRandom(which)
	if not pending or self:Pool(which)[pending] ~= true then
		self:NextRandom(which)
		self:UpdateButtons()
	end
end

-- 按钮创建后先各预选一只，保证按钮一出现图标就是真实坐骑
function mod:PrimeRandomPicks()
	self:NextRandom("fly")
	self:NextRandom("duo")
end
function mod:BuildMenu()
	if self.menu then
		return self.menu
	end
	local m = CreateFrame("Frame", "MzxRidingMountMenu", UIParent, "BackdropTemplate")
	m:SetWidth(MENU_WIDTH)
	m:SetFrameStrata("FULLSCREEN_DIALOG")
	m:SetFrameLevel((UIParent:GetFrameLevel() or 0) + 30)
	m:SetClampedToScreen(true)
	m:EnableMouse(true)
	m._setSkin = M.MakeFlatSkin(m, 1)
	m._setSkin(1, 0.82, 0.2, 0.55, 0.07, 0.08, 0.10, 0.98)
	m.rows = {}
	self.menu = m

	pcall(tinsert, UISpecialFrames, "MzxRidingMountMenu")
	return m
end

function mod:AcquireMenuRow(i)
	local m = self.menu
	local row = m.rows[i]
	if row then
		return row
	end
	row = M.MakeListRow(m, { iconSize = 20, height = M.LIST_ROW_HEIGHT, stripe = (i % 2 == 0) })
	row:SetPoint("TOPLEFT", m, "TOPLEFT", MENU_PAD, -(MENU_PAD + (i - 1) * M.LIST_ROW_HEIGHT))
	row:SetPoint("RIGHT", m, "RIGHT", -MENU_PAD, 0)
	m.rows[i] = row
	return row
end

local function FillMenuMountRow(row, icon, label, sub, primary)
	row.icon:SetTexture(icon or QUESTION_ICON)
	row.icon:Show()
	row.name:SetTextColor(1, 1, 1)
	row.name:SetText(label)
	row.sub:SetText(sub or "")
	row.state:SetText("")
	row.state:SetTextColor(1, 0.82, 0.2)
	row:SetSelected(false)
	row:Enable()
end

local function FillMenuPlainRow(row, label, gold)
	row.icon:Hide()
	row.name:SetText(label)
	row.name:SetTextColor(gold and 1 or 0.7, gold and 0.82 or 0.7, gold and 0.2 or 0.7)
	row.sub:SetText("")
	row.state:SetText("")
	row:SetSelected(false)
end

function mod:ShowMenu()
	local m = self:BuildMenu()
	local owned = OwnedList()
	local count = 0
	for _, e in ipairs(owned) do
		count = count + 1
		local row = self:AcquireMenuRow(count)
		local info = MountInfo(e.id)
		FillMenuMountRow(row, info.icon, self:LabelFor(e.id), TagsText(e.tags), false)
		local id = e.id
		row:SetScript("OnClick", function()
			SummonMount(id)
			mod:HideMenu()
		end)
		row:Show()
	end
	local totalRows
	if count == 0 then
		local row = self:AcquireMenuRow(1)
		FillMenuPlainRow(row, L["No listed functional mounts owned"], false)
		row:SetScript("OnClick", nil)
		row:Disable()
		row:Show()
		totalRows = 2
	else
		totalRows = count + 1
	end

	local srow = self:AcquireMenuRow(totalRows)
	FillMenuPlainRow(srow, L["Open settings"], true)
	srow:Enable()
	srow:SetScript("OnClick", function()
		mod:HideMenu()
		mod:OpenConfigAt("func")
	end)
	srow:Show()

	for i = totalRows + 1, #m.rows do
		m.rows[i]:Hide()
	end

	m:SetHeight(totalRows * M.LIST_ROW_HEIGHT + MENU_PAD * 2)
	local anchor = self.buttons and self.buttons.func or self.group
	local _, by = anchor:GetCenter()
	local up = (by or 0) < (UIParent:GetHeight() / 2)
	m:ClearAllPoints()
	if up then
		m:SetPoint("BOTTOM", anchor, "TOP", 0, 6)
	else
		m:SetPoint("TOP", anchor, "BOTTOM", 0, -6)
	end
	m:Show()
end

function mod:SummonPrimary(verbose)
	local id = self:GetPrimaryId()
	if not id then
		M.Print(L["You do not own any listed functional mounts."])
		return
	end
	local label = self:LabelFor(id)
	local ok, err = SummonMount(id)
	if ok then
		if verbose then
			M.Print(string.format(L["Summoned: %s"], label))
		end
	else
		M.Print(string.format(L["%s: %s"], err or L["Summon failed"], label))
	end
end

function mod:SummonById(id)
	if not id then
		return
	end
	local label = self:LabelFor(id)
	local ok, err = SummonMount(id)
	if ok then
		M.Print(string.format(L["Summoned: %s"], label))
	else
		M.Print(string.format(L["%s: %s"], err or L["Summon failed"], label))
	end
end

-- ------------------------------------------------------------------ 悬浮按钮组

function mod:PlaceButton()
	local g = self.group
	if not g then
		return
	end
	g:ClearAllPoints()
	local p = self.db and self.db.buttonPoint
	if type(p) == "table" and p[1] then
		g:SetPoint(p[1], UIParent, p[2] or p[1], p[3] or 0, p[4] or 0)
	else
		g:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	end
end

function mod:SaveButtonPosition()
	local g = self.group
	if not g or not self.db then
		return
	end
	local point, _, relPoint, x, y = g:GetPoint(1)
	if point then
		self.db.buttonPoint = { point, relPoint, x or 0, y or 0 }
	end
end

function mod:UpdateButtons()
	local btns = self.buttons
	if not btns then
		return
	end
	-- 首次加载时若还没有预选，就随机一只，保证按钮图标是真实坐骑而不是默认图
	if not self:GetPendingRandom("fly") and next(self:Pool("fly") or {}) then
		self:NextRandom("fly")
	end
	if not self:GetPendingRandom("duo") and next(self:Pool("duo") or {}) then
		self:NextRandom("duo")
	end
	local id = self:GetPrimaryId()
	btns.func.icon:SetTexture((id and MountInfo(id).icon) or QUESTION_ICON)
	local flyId = self:GetPendingRandom("fly") or self.lastFly
	local duoId = self:GetPendingRandom("duo") or self.lastDuo
	btns.fly.icon:SetTexture((flyId and MountInfo(flyId).icon) or FLY_DEFAULT_ICON)
	btns.duo.icon:SetTexture((duoId and MountInfo(duoId).icon) or DUO_DEFAULT_ICON)
end

function mod:UpdateButtonVisibility()
	local g = self.group
	if not g then
		return
	end
	if M:IsModuleEnabled(self.key) then
		g:Show()
	else
		g:Hide()
		self:HideMenu()
	end
end

local function OnButtonDragStart()
	mod._dragged = true
	if mod.group then
		mod.group:StartMoving()
	end
end

local function OnButtonDragStop()
	if mod.group then
		mod.group:StopMovingOrSizing()
		M.SnapToPixelGrid(mod.group)
		mod:SaveButtonPosition()
	end
end

function mod:MakeGroupButton(g, order, tooltipFn, onClick)
	local b = CreateFrame("Button", nil, g)
	b:SetSize(GROUP_BUTTON, GROUP_BUTTON)
	b:SetPoint("LEFT", g, "LEFT", GROUP_PAD + (order - 1) * (GROUP_BUTTON + GROUP_GAP), 0)
	b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	b:RegisterForDrag("LeftButton")

	b._setSkin = M.MakeFlatSkin(b, 1)
	b._setSkin(0, 0, 0, 0, 0.10, 0.11, 0.14, 0.95)

	b.icon = b:CreateTexture(nil, "ARTWORK")
	b.icon:SetPoint("TOPLEFT", 3, -3)
	b.icon:SetPoint("BOTTOMRIGHT", -3, 3)
	b.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

	local hl = b:CreateTexture(nil, "HIGHLIGHT")
	hl:SetAllPoints()
	hl:SetColorTexture(1, 0.82, 0.2, 0.18)
	b:SetHighlightTexture(hl, "ADD")

	b:SetScript("OnMouseDown", function()
		mod._dragged = false
	end)
	b:SetScript("OnDragStart", OnButtonDragStart)
	b:SetScript("OnDragStop", OnButtonDragStop)
	b:SetScript("OnClick", function(_, button)
		if mod._dragged then
			mod._dragged = false
			return
		end
		if onClick then
			onClick(button)
		end
	end)
	b:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		if tooltipFn then
			tooltipFn(GameTooltip)
		end
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(L["Drag: move the whole button group"], 0.8, 0.8, 0.8)
		GameTooltip:Show()
	end)
	b:SetScript("OnLeave", GameTooltip_Hide)
	return b
end

function mod:CreateButton()
	if self.group then
		return self.group
	end
	local g = CreateFrame("Frame", "MzxRidingMountGroup", UIParent)
	local w = GROUP_PAD * 2 + GROUP_BUTTON * 3 + GROUP_GAP * 2
	local h = GROUP_PAD * 2 + GROUP_BUTTON
	g:SetSize(w, h)
	g:SetFrameStrata("MEDIUM")
	g:SetClampedToScreen(true)
	g:SetMovable(true)
	g._setSkin = M.MakeFlatSkin(g, 1)
	g._setSkin(1, 0.82, 0.2, 0.35, 0.06, 0.07, 0.09, 0.85)
	self.group = g

	self.buttons = {}

	self.buttons.func = self:MakeGroupButton(g, 1, function(tip)
		local id = mod:GetPrimaryId()
		if id then
			tip:SetText(string.format(L["Functional Mount: %s"], mod:LabelFor(id)), 1, 0.82, 0.2)
			local e = byId[id]
			if e then
				tip:AddLine(TagsText(e.tags), 0.8, 0.8, 0.8, true)
			end
		else
			tip:SetText(L["Functional Mount"], 1, 0.82, 0.2)
			tip:AddLine(L["No listed functional mounts owned"], 0.8, 0.8, 0.8, true)
		end
		tip:AddLine(M.MouseIcon("L") .. L["Summon primary mount"], 1, 1, 1)
		tip:AddLine(M.MouseIcon("R") .. L["Choose primary mount"], 1, 1, 1)
	end, function(button)
		if button == "RightButton" then
			mod:ShowMenu()
		else
			mod:SummonPrimary()
		end
	end)

	self.buttons.fly = self:MakeGroupButton(g, 2, function(tip)
		tip:SetText(L["Random Flying Mount"], 1, 0.82, 0.2)
		local n = 0
		local pool = mod:Pool("fly")
		for _, e in ipairs(mod:PoolList("fly")) do
			if pool[e.id] == true then n = n + 1 end
		end
		tip:AddLine(string.format(L["%d flying mounts selected"], n), 0.8, 0.8, 0.8)
		local pending = mod:GetPendingRandom("fly")
		if pending then
			tip:AddLine(string.format(L["Next summon: %s"], mod:MountName(pending)), 1, 0.82, 0.2)
		end
		if mod.lastFly then
			tip:AddLine(string.format(L["Last: %s"], mod:MountName(mod.lastFly)), 0.8, 0.8, 0.8)
		end
		tip:AddLine(M.MouseIcon("L") .. L["Summon and reroll"], 1, 1, 1)
		tip:AddLine(M.MouseIcon("R") .. L["Open settings"], 1, 1, 1)
	end, function(button)
		if button == "RightButton" then
			mod:OpenConfigAt("fly")
		else
			mod:SummonRandom("fly")
		end
	end)

	self.buttons.duo = self:MakeGroupButton(g, 3, function(tip)
		tip:SetText(L["Random Duo Mount"], 1, 0.82, 0.2)
		local n = 0
		local pool = mod:Pool("duo")
		for _, e in ipairs(mod:PoolList("duo")) do
			if pool[e.id] == true then n = n + 1 end
		end
		tip:AddLine(string.format(L["%d mounts selected"], n), 0.8, 0.8, 0.8)
		if n == 0 then
			tip:AddLine(L["Please select passenger mounts in settings first"], 1, 0.6, 0.4)
		end
		if mod.lastDuo then
			tip:AddLine(string.format(L["Last: %s"], mod:MountName(mod.lastDuo)), 0.8, 0.8, 0.8)
		end
		local pendingDuo = mod:GetPendingRandom("duo")
		if pendingDuo then
			tip:AddLine(string.format(L["Next summon: %s"], mod:MountName(pendingDuo)), 1, 0.82, 0.2)
		end
		tip:AddLine(M.MouseIcon("L") .. L["Summon and reroll"], 1, 1, 1)
		tip:AddLine(M.MouseIcon("R") .. L["Open settings"], 1, 1, 1)
	end, function(button)
		if button == "RightButton" then
			mod:OpenConfigAt("duo")
		else
			mod:SummonRandom("duo")
		end
	end)

	self:PlaceButton()
	self:UpdateButtons()
	return g
end

-- ------------------------------------------------------------------ 模块接口

function mod:EnsureDB(db, charDb)
	local s = db.mounts
	if type(s) ~= "table" then
		s = {}
		db.mounts = s
	end
	if s.show == nil then
		s.show = true
	end
	if s.primary ~= nil and type(s.primary) ~= "number" then
		s.primary = nil
	end
	if s.buttonPoint ~= nil and type(s.buttonPoint) ~= "table" then
		s.buttonPoint = nil
	end

	charDb = charDb or db
	local c = charDb.mounts
	if type(c) ~= "table" then
		c = {}
		charDb.mounts = c
	end
	for _, key in ipairs({ "flyPool", "duoPool" }) do
		if type(s[key]) == "table" and c[key] == nil then
			c[key] = s[key]
		end
		if c[key] ~= nil and type(c[key]) ~= "table" then
			c[key] = nil
		end
	end
	for _, key in ipairs({ "flyPoolInit", "duoPoolInit" }) do
		if c[key] == nil and s[key] ~= nil then
			c[key] = s[key]
		end
	end
	s.flyPool = nil
	s.duoPool = nil
	s.flyPoolInit = nil
	s.duoPoolInit = nil
	self.db = s
	self.charDb = c
end

function mod:OnToggle(on)
	if not self.db then
		return
	end
	self:CreateButton()
	self:UpdateButtons()
	self:UpdateButtonVisibility()
end

function mod:OnEvent(event)
	if event == "PLAYER_ENTERING_WORLD" or event == "NEW_MOUNT_ADDED" then
		self:InvalidateFlyCache()
		self:UpdateButtons()
		self:UpdateButtonVisibility()
		M:RefreshConfigIfOpen()
	elseif event == "GLOBAL_MOUSE_DOWN" then
		self:OnGlobalMouseDown()
	end
end

-- 非阻塞外点关闭：不使用全屏点击捕捉层（会挡住角色操作），
-- 改为监听全局鼠标按下，只在鼠标既不在菜单、也不在功能坐骑锚点按钮上时关闭。
function mod:OnGlobalMouseDown()
	local m = self.menu
	if not m or not m:IsShown() then
		return
	end
	if m:IsMouseOver() then
		return
	end
	local fb = self.buttons and self.buttons.func
	if fb and fb:IsMouseOver() then
		return
	end
	self:HideMenu()
end

M:RegisterModuleEvent("PLAYER_ENTERING_WORLD")
M:RegisterModuleEvent("NEW_MOUNT_ADDED")
M:RegisterModuleEvent("GLOBAL_MOUSE_DOWN")

-- ------------------------------------------------------------------ 设置界面

local ROW_HEIGHT = M.LIST_ROW_HEIGHT
local SUB_TAB_H = 22
-- 三个子页的列表统一外观：同一图标尺寸、同一左右内边距、同一顶部起点、同一单行布局。
local LIST_ICON = 26
local LIST_LEFT = 12
local LIST_RIGHT = 12

-- 带细滚动条的滑动列表（自绘，不使用暴雪模板）
local function MakeScrollList(parent)
	local scroll = CreateFrame("ScrollFrame", nil, parent)
	scroll:EnableMouseWheel(true)

	local content = CreateFrame("Frame", nil, scroll)
	content:SetSize(1, 1)
	scroll:SetScrollChild(content)

	local track = scroll:CreateTexture(nil, "BACKGROUND")
	track:SetPoint("TOPLEFT", scroll, "TOPRIGHT", 7, 0)
	track:SetPoint("BOTTOMLEFT", scroll, "BOTTOMRIGHT", 7, 0)
	track:SetWidth(4)
	track:SetColorTexture(1, 1, 1, 0.06)

	local sb = CreateFrame("Slider", nil, scroll)
	sb:SetOrientation("VERTICAL")
	sb:SetPoint("TOPLEFT", scroll, "TOPRIGHT", 6, 0)
	sb:SetPoint("BOTTOMLEFT", scroll, "BOTTOMRIGHT", 6, 0)
	sb:SetWidth(6)
	sb:SetMinMaxValues(0, 0)
	sb:SetValue(0)
	sb:SetObeyStepOnDrag(true)
	local thumb = sb:CreateTexture(nil, "ARTWORK")
	thumb:SetColorTexture(1, 0.82, 0.2, 0.5)
	thumb:SetSize(6, 40)
	sb:SetThumbTexture(thumb)

	local function UpdateScrollBar()
		local range = scroll:GetVerticalScrollRange() or 0
		local viewH = scroll:GetHeight()
		if range <= 0 or not viewH or viewH <= 0 then
			sb:Hide()
			return
		end
		sb:Show()
		sb:SetMinMaxValues(0, range)
		local trackH = sb:GetHeight() or 1
		thumb:SetHeight(math.max(24, viewH / (viewH + range) * trackH))
	end

	return scroll, content, sb, UpdateScrollBar
end

local function CreatePoolRow(page, parent)
	local row = M.MakeListRow(parent, { height = ROW_HEIGHT, iconSize = LIST_ICON, singleLine = true })
	row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	row:SetScript("OnClick", function(self, button)
		local id = self.mountId
		if not id then
			return
		end
		if button == "RightButton" then
			page.mod:SummonById(id)
		else
			page.mod:TogglePoolEntry(page.which, id)
			page.RefreshRow(self)
		end
	end)
	return row
end

function mod:BuildPoolPage(parent, which)
	local page = {
		mod = self,
		which = which,
		pool = {},
		rows = {},
	}

	local hint = parent:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	hint:SetPoint("TOPLEFT", parent, "TOPLEFT", LIST_LEFT, 0)
	hint:SetWidth((parent:GetWidth() or 440) - LIST_LEFT - LIST_RIGHT)
	hint:SetJustifyH("LEFT")
	hint:SetNonSpaceWrap(true)
	page.hint = hint

	local scroll, content, sb, UpdateScrollBar = MakeScrollList(parent)
	scroll:SetPoint("TOPLEFT", hint, "BOTTOMLEFT", 0, -8)
	scroll:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -LIST_RIGHT, 34)
	page.scroll = scroll
	page.content = content
	page.sb = sb
	page.UpdateScrollBar = UpdateScrollBar

	page.RefreshRow = function(row)
		local idx = row._index
		local e = idx and page.list and page.list[idx]
		if not e then
			return
		end
		row.icon:SetTexture(e.icon or QUESTION_ICON)
		row.name:SetText(e.name)
		local sel = page.mod:IsPoolSelected(page.which, e.id)
		M.SetStateIcon(row, sel)
		row:SetSelected(sel)
	end

	page.Layout = function()
		local list = page.list or {}
		local n = #list
		content:SetWidth(math.max(1, scroll:GetWidth() or 1))
		content:SetHeight(math.max(1, n * ROW_HEIGHT))
		local viewH = scroll:GetHeight() or 0
		UpdateScrollBar()
		if viewH <= 0 or n == 0 then
			for _, r in ipairs(page.rows) do r:Hide() end
			return
		end
		local top = scroll:GetVerticalScroll() or 0
		local first = math.floor(top / ROW_HEIGHT) + 1
		local last = math.min(n, first + math.ceil(viewH / ROW_HEIGHT))
		if first < 1 then first = 1 end
		local shown = 0
		for idx = first, last do
			shown = shown + 1
			local row = page.rows[shown]
			if not row then
				row = CreatePoolRow(page, content)
				page.rows[shown] = row
			end
			row._index = idx
			row.mountId = list[idx].id
			row:ClearAllPoints()
			row:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -(idx - 1) * ROW_HEIGHT)
			row:SetPoint("RIGHT", content, "RIGHT", 0, 0)
			row:SetStripe(idx % 2 == 0)
			page.RefreshRow(row)
			row:Show()
		end
		for i = shown + 1, #page.rows do
			page.rows[i]:Hide()
		end
	end

	scroll:SetScript("OnVerticalScroll", function()
		sb:SetValue(scroll:GetVerticalScroll())
		page.Layout()
	end)
	scroll:SetScript("OnScrollRangeChanged", UpdateScrollBar)
	sb:SetScript("OnValueChanged", function(_, v)
		scroll:SetVerticalScroll(v)
	end)
	scroll:SetScript("OnMouseWheel", function(_, delta)
		local range = scroll:GetVerticalScrollRange() or 0
		local target = scroll:GetVerticalScroll() - delta * ROW_HEIGHT * 3
		if target < 0 then target = 0 end
		if target > range then target = range end
		scroll:SetVerticalScroll(target)
	end)

	function page:Refresh()
		self.list = self.mod:PoolList(self.which)
		self.hint:SetText(string.format(L["Click: select · Right-click: summon (%d)"], #self.list))
		self.scroll:SetVerticalScroll(0)
		self.Layout()
		if C_Timer and C_Timer.After then
			C_Timer.After(0, function()
				if page.scroll:IsShown() then
					page.Layout()
				end
			end)
		end
	end

	-- 底部按钮（三等分铺满内容宽度）
	local bw = math.floor(((parent:GetWidth() or 440) - LIST_LEFT - LIST_RIGHT - 12) / 3)
	local all = M.MakeFlatButton(parent, bw, 22, L["Select All"], function()
		self:SetPoolAll(which, true)
		page.Layout()
	end)
	all:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", LIST_LEFT, 6)

	local none = M.MakeFlatButton(parent, bw, 22, L["Deselect All"], function()
		self:SetPoolAll(which, false)
		page.Layout()
	end)
	none:SetPoint("LEFT", all, "RIGHT", 6, 0)

	local roll = M.MakeFlatButton(parent, bw, 22, L["Summon Random"], function()
		self:SummonRandom(which)
	end)
	roll:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -LIST_RIGHT, 6)

	page.buttons = { all = all, none = none, roll = roll }
	return page
end

function mod:BuildFuncPage(parent)
	local hint = parent:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	hint:SetPoint("TOPLEFT", parent, "TOPLEFT", LIST_LEFT, 0)
	hint:SetWidth((parent:GetWidth() or 440) - LIST_LEFT - LIST_RIGHT)
	hint:SetJustifyH("LEFT")
	hint:SetNonSpaceWrap(true)
	hint:SetText(L["Click: set primary · Right-click: summon"])

	local page = { rows = {} }

	page.Rebuild = function()
		for i = #page.rows, 1, -1 do
			local old = page.rows[i]
			old:Hide()
			old:SetParent(nil)
			page.rows[i] = nil
		end
		local shown = 0
		for _, e in ipairs(FUNCTIONAL_MOUNTS) do
			local id = e.id
			if OwnedOK(id) then
				shown = shown + 1
				local row = M.MakeListRow(parent, { height = ROW_HEIGHT, iconSize = LIST_ICON, singleLine = true, stripe = (shown % 2 == 0) })
				row.mountId = id
				row:SetPoint("TOPLEFT", hint, "BOTTOMLEFT", 0, -8 - (shown - 1) * ROW_HEIGHT)
				row:SetPoint("RIGHT", parent, "RIGHT", -LIST_RIGHT, 0)
				row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
				row:SetScript("OnClick", function(_, button)
					if button == "RightButton" then
						mod:SummonById(id)
					else
						mod:SetPrimary(id)
					end
				end)
				row:SetScript("OnEnter", function(self2)
					GameTooltip:SetOwner(self2, "ANCHOR_RIGHT")
					GameTooltip:SetText(mod:LabelFor(id), 1, 1, 1)
					GameTooltip:AddLine(TagsText(e.tags), 0.8, 0.8, 0.8, true)
					GameTooltip:AddLine(M.MouseIcon("L") .. L["Set as primary mount"], 1, 0.82, 0.2)
					GameTooltip:AddLine(M.MouseIcon("R") .. L["Summon now"], 0.8, 0.8, 0.8)
					GameTooltip:Show()
				end)
				row:SetScript("OnLeave", GameTooltip_Hide)
				page.rows[shown] = row
			end
		end
	end

	page.Rebuild()

	local summon = M.MakeFlatButton(parent, (parent:GetWidth() or 440) - LIST_LEFT - LIST_RIGHT, 24, L["Summon Primary Mount"], function()
		self:SummonPrimary(true)
	end)
	summon:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", LIST_LEFT, 4)

	return { rows = page.rows, page = page, summon = summon, hint = hint }
end

function mod:RefreshMountLists()
	self:InvalidateFlyCache()
	if self.db then
		for _, which in ipairs({ "fly", "duo" }) do
			local pool = (self.charDb or self.db)[(which == "duo") and "duoPool" or "flyPool"]
			if type(pool) == "table" then
				for id in pairs(pool) do
					if not OwnedOK(id) then
						pool[id] = nil
					end
				end
			end
			self:RevalidatePending(which)
		end
	end
	self:PrimeRandomPicks()
	self:UpdateButtons()
	local p = self.optionsFrame
	if p and p.pages then
		local func = p.pages.func
		if func and func.page and func.page.Rebuild then
			func.page.Rebuild()
		end
		for key, page in pairs(p.pages) do
			if key ~= "func" and page and page.Refresh then
				page:Refresh()
			end
		end
	end
	self:RefreshOptions()
	M:RefreshConfigIfOpen()
end

function mod:SelectSub(which)
	local p = self.optionsFrame
	if not p or not p.pages then
		return
	end
	p.subKey = which
	for key, page in pairs(p.pages) do
		if page.frame then
			page.frame:SetShown(key == which)
		end
	end
	for key, b in pairs(p.subTabs or {}) do
		b.selected = (key == which)
		M.ApplyFlatButtonVisual(b)
	end
	local page = p.pages[which]
	if page and page.Refresh then
		page:Refresh()
	end
end

-- 打开配置窗并切到「坐骑」模块标签 + 指定子标签（供按钮右键/菜单使用）
function mod:OpenConfigAt(which)
	M:OpenConfig()
	M:GetModulePanel(mod)
	M:SelectTab(self.key)
	if which then
		self:SelectSub(which)
	end
end

function mod:RefreshOptions()
	local p = self.optionsFrame
	if not p or not p.pages then
		return
	end
	local func = p.pages.func
	if func and func.rows then
		local chosen = self:GetChosenId()
		local effective = self:GetPrimaryId()
		for _, row in ipairs(func.rows) do
			local id = row.mountId
			local info = MountInfo(id)
			row.icon:SetTexture(info.icon or QUESTION_ICON)
			row.name:SetText(self:LabelFor(id))
			local isPrimary = (chosen == id) or (chosen == nil and effective == id)
			M.SetStateIcon(row, isPrimary)
			row:SetSelected(isPrimary)
		end
	end
	-- 刷新当前可见的随机页
	local cur = p.pages[p.subKey]
	if cur and cur.Refresh then
		cur:Refresh()
	end
end

function mod:BuildOptions(p)
	-- 子标签：功能 / 随机飞行 / 随机双人
	local defs = {
		{ key = "func", label = L["Functional"] },
		{ key = "fly", label = L["Random Flying"] },
		{ key = "duo", label = L["Random Duo"] },
	}
	p.subTabs = {}
	p.subKey = "func"
	local n = #defs
	local refreshW = SUB_TAB_H
	local totalW = (p:GetWidth() or 444) - 24 - refreshW - 4
	local gap = 4
	local tabW = math.floor((totalW - gap * (n - 1)) / n)
	local prev
	for i, d in ipairs(defs) do
		local b = M.MakeFlatButton(p, tabW, SUB_TAB_H, d.label, function()
			mod:SelectSub(d.key)
		end)
		b.selected = (d.key == "func")
		b:SetFrameLevel(p:GetFrameLevel() + 3)
		if i == 1 then
			b:SetPoint("TOPLEFT", p, "TOPLEFT", 12, -26)
		else
			b:SetPoint("LEFT", prev, "RIGHT", gap, 0)
		end
		prev = b
		p.subTabs[d.key] = b
	end

	local refresh = CreateFrame("Button", nil, p)
	refresh:SetSize(refreshW, SUB_TAB_H)
	refresh:SetPoint("TOPRIGHT", p, "TOPRIGHT", -12, -26)
	refresh:SetFrameLevel(p:GetFrameLevel() + 3)
	local refreshTex = refresh:CreateTexture(nil, "ARTWORK")
	refreshTex:SetSize(16, 16)
	refreshTex:SetPoint("TOPLEFT", 3, -3)
	refreshTex:SetPoint("BOTTOMRIGHT", -3, 3)
	refreshTex:SetTexture("Interface\\AddOns\\MzxRiding\\Textures\\refresh.tga")
	local refreshHl = refresh:CreateTexture(nil, "HIGHLIGHT")
	refreshHl:SetAllPoints()
	refreshHl:SetColorTexture(1, 1, 1, 0.08)
	refresh:SetScript("OnClick", function()
		mod:RefreshMountLists()
	end)
	refresh:SetScript("OnEnter", function(self2)
		GameTooltip:SetOwner(self2, "ANCHOR_TOP")
		GameTooltip:SetText(L["Refresh Lists"], 1, 0.82, 0.2)
		GameTooltip:AddLine(L["Rescan mounts and rebuild all three lists."], 0.8, 0.8, 0.8)
		GameTooltip:Show()
	end)
	refresh:SetScript("OnLeave", GameTooltip_Hide)
	p.refresh = refresh

	p.pages = {}

	local funcFrame = CreateFrame("Frame", nil, p)
	funcFrame:SetFrameLevel(p:GetFrameLevel() + 1)
	funcFrame:SetPoint("TOPLEFT", p, "TOPLEFT", 0, -54)
	funcFrame:SetPoint("BOTTOMRIGHT", p, "BOTTOMRIGHT", 0, 2)
	funcFrame:SetShown(false)
	local funcData = self:BuildFuncPage(funcFrame)
	funcData.frame = funcFrame
	p.pages.func = funcData

	for _, which in ipairs({ "fly", "duo" }) do
		local fr = CreateFrame("Frame", nil, p)
		fr:SetFrameLevel(p:GetFrameLevel() + 1)
		fr:SetPoint("TOPLEFT", p, "TOPLEFT", 0, -54)
		fr:SetPoint("BOTTOMRIGHT", p, "BOTTOMRIGHT", 0, 2)
		fr:SetShown(false)
		local page = self:BuildPoolPage(fr, which)
		page.frame = fr
		p.pages[which] = page
	end

	self:SelectSub("func")

	for key, b in pairs(p.subTabs) do
		b.selected = (key == p.subKey)
		M.ApplyFlatButtonVisual(b)
	end
end
