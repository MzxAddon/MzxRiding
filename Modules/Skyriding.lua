-- 模块：御龙术动作条固定
-- 固定御龙术（Skyriding/Dragonriding）技能在御龙术动作条上的顺序。
-- 背景：暴雪默认 UI 在登录/重载时，若发现御龙术技能不在任何动作条上，
-- 会把它们自动塞回御龙术条（优先空槽，也可能覆盖），导致顺序错乱。
-- 御龙术条 = Bonus Bar 5 = 动作槽位 121-132。
local ADDON, ns = ...
local M = ns.M
local L = ns.L

local ABILITIES = {
	{ key = "whirl",  nameKey = "Whirling Surge", ids = { 361584, 418592 } }, -- Whirling Surge / Lightning Rush
	{ key = "surge",  nameKey = "Surge Forward", ids = { 372608 } },          -- Surge Forward
	{ key = "second", nameKey = "Second Wind", ids = { 425782 } },            -- Second Wind
	{ key = "halt",   nameKey = "Aerial Halt", ids = { 403092 } },            -- Aerial Halt
	{ key = "ascent", nameKey = "Skyward Ascent", ids = { 372610 } },         -- Skyward Ascent
}
local DEFAULT_ORDER = { "whirl", "surge", "second", "halt", "ascent" }
local DEFAULT_BASE = 121
local BAR_SIZE = 12
local APPLY_DELAY = 2

local abilityByKey = {}
for _, a in ipairs(ABILITIES) do
	abilityByKey[a.key] = a
end

-- 技能显示名：优先取客户端本地化名，取不到才回退到 ABILITIES 里的兜底。
local function AbilityName(ability)
	local id = ability.ids[1]
	if C_Spell and C_Spell.GetSpellName then
		local ok, n = pcall(C_Spell.GetSpellName, id)
		if ok and n then
			return n
		end
	end
	if GetSpellInfo then
		local ok, n = pcall(GetSpellInfo, id)
		if ok and n then
			return n
		end
	end
	return L[ability.nameKey]
end

local mod = {
	key = "skyriding",
	name = L["Skyriding"],
	nameKey = "Skyriding",
	defaultEnabled = true,
}
M:RegisterModule(mod)

-- ------------------------------------------------------------------ 底层工具

local function PickupSpellByID(id)
	local fn = (C_Spell and C_Spell.PickupSpell) or PickupSpell
	if fn then
		fn(id)
	end
end

local function PlaceOnCursor(slot)
	local fn = (C_ActionBar and C_ActionBar.PutActionInSlot) or PlaceAction
	if fn then
		fn(slot)
	end
end

local function ClearAnyCursor()
	if GetCursorInfo() then
		ClearCursor()
	end
end

local function SpellAtSlot(slot)
	local actionType, id = GetActionInfo(slot)
	if actionType == "spell" then
		return id
	end
	return nil
end

local function BuildManaged()
	local set = {}
	for _, a in ipairs(ABILITIES) do
		for _, id in ipairs(a.ids) do
			set[id] = true
		end
	end
	return set
end

local function SlotMatchesAbility(slot, ability)
	local id = SpellAtSlot(slot)
	if not id then
		return false
	end
	for _, cand in ipairs(ability.ids) do
		if cand == id then
			return true
		end
	end
	return false
end

-- ------------------------------------------------------------------ 核心

function mod:IsConfigured()
	local db = self.db
	if not db then
		return false
	end
	local base = db.baseSlot
	local managed = BuildManaged()
	for i = 1, BAR_SIZE do
		local slot = base + i - 1
		local key = db.order[i]
		local ability = key and abilityByKey[key]
		if ability then
			if not SlotMatchesAbility(slot, ability) then
				return false
			end
		else
			local id = SpellAtSlot(slot)
			if id and managed[id] then
				return false
			end
		end
	end
	return true
end

function mod:Apply(verbose, force)
	local db = self.db
	if not db then
		return
	end
	if InCombatLockdown() then
		if verbose then
			M.Print(L["Cannot modify action bars in combat. Try again after combat."])
		end
		return
	end
	if not force and self:IsConfigured() then
		if verbose then
			M.Print(L["Already matches the configuration; no changes needed."])
		end
		return
	end

	ClearAnyCursor()

	local base = db.baseSlot
	local managed = BuildManaged()

	-- 1) 先清掉动作条上所有由本模块管理的御龙术技能，避免重复。
	for i = 1, BAR_SIZE do
		local slot = base + i - 1
		local id = SpellAtSlot(slot)
		if id and managed[id] then
			PickupAction(slot)
			ClearAnyCursor()
		end
	end

	-- 2) 按配置顺序放置（只放能拾取到的技能）。
	local placed, missing = 0, {}
	for i, key in ipairs(db.order) do
		local ability = abilityByKey[key]
		if ability then
			local slot = base + i - 1
			local ok = false
			for _, cand in ipairs(ability.ids) do
				PickupSpellByID(cand)
				if GetCursorInfo() then
					PlaceOnCursor(slot)
					ok = true
					ClearAnyCursor()
					break
				end
			end
			if ok then
				placed = placed + 1
			else
				missing[#missing + 1] = AbilityName(ability)
			end
		end
	end

	if verbose then
		M.Print(string.format(L["Placed %d spells into slots %d-%d."], placed, base, base + BAR_SIZE - 1))
		if #missing > 0 then
			M.Print(string.format(L["Not learned (skipped): %s"], table.concat(missing, ", ")))
		end
	end
end

function mod:ScheduleApply()
	if self._pending then
		return
	end
	self._pending = true
	C_Timer.After(APPLY_DELAY, function()
		self._pending = false
		if M:IsModuleEnabled("skyriding") then
			self:Apply(false)
		end
	end)
end

function mod:ResetOrder()
	self.db.order = {}
	for i, k in ipairs(DEFAULT_ORDER) do
		self.db.order[i] = k
	end
	self.db.baseSlot = DEFAULT_BASE
end

function mod:MovePosition(fromPos, toPos)
	local order = self.db.order
	if not order[fromPos] or not order[toPos] then
		return
	end
	order[fromPos], order[toPos] = order[toPos], order[fromPos]
end

-- ------------------------------------------------------------------ 模块接口

function mod:EnsureDB(db)
	local s = db.skyriding
	if type(s) ~= "table" then
		s = {}
		db.skyriding = s
	end
	s.baseSlot = tonumber(s.baseSlot) or DEFAULT_BASE
	if type(s.order) ~= "table" or #s.order == 0 then
		s.order = {}
		for i, k in ipairs(DEFAULT_ORDER) do
			s.order[i] = k
		end
	end
	self.db = s
end

function mod:OnToggle(on)
	if on then
		self:ScheduleApply()
	end
end

function mod:OnEvent(event)
	if event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_LEVEL_UP" then
		self:ScheduleApply()
	end
end

M:RegisterModuleEvent("PLAYER_LEVEL_UP")

-- ------------------------------------------------------------------ 设置界面

local ROW_HEIGHT = 30

local function SpellIcon(ability)
	local id = ability.ids[1]
	local tex
	if C_Spell and C_Spell.GetSpellTexture then
		tex = C_Spell.GetSpellTexture(id)
	end
	tex = tex or GetSpellTexture(id)
	return tex
end

function mod:RefreshOptions()
	local p = self.optionsFrame
	if not p or not p.rows then
		return
	end
	for i, row in ipairs(p.rows) do
		local key = self.db.order[i]
		local ability = key and abilityByKey[key]
		if ability then
			row.icon:SetTexture(SpellIcon(ability))
			row.name:SetText(string.format("%d. %s", self.db.baseSlot + i - 1, AbilityName(ability)))
		end
		row.up:SetEnabled(i > 1)
		row.down:SetEnabled(i < #p.rows)
		M.ApplyFlatButtonVisual(row.up)
		M.ApplyFlatButtonVisual(row.down)
	end
end

function mod:BuildOptions(p)
	local W = p:GetWidth() or 444
	local hint = p:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	hint:SetWidth(W - 24)
	hint:SetJustifyH("LEFT")
	hint:SetNonSpaceWrap(true)
	hint:SetPoint("TOPLEFT", p, "TOPLEFT", 12, -34)
	hint:SetText(L["Use Up/Down to reorder · number = action slot"])

	p.rows = {}
	for i = 1, #ABILITIES do
		local pos = i
		local row = M.MakeListRow(p, { singleLine = true, height = ROW_HEIGHT, iconSize = 24, stripe = (pos % 2 == 0) })
		if pos == 1 then
			row:SetPoint("TOPLEFT", hint, "BOTTOMLEFT", 0, -10)
		else
			row:SetPoint("TOPLEFT", p.rows[1], "TOPLEFT", 0, -(pos - 1) * ROW_HEIGHT)
		end
		row:SetPoint("RIGHT", p, "RIGHT", -12, 0)

		row.down = M.MakeFlatButton(row, 48, 22, L["Down"], function()
			mod:MovePosition(pos, pos + 1)
			mod:RefreshOptions()
			mod:ScheduleApply()
		end)
		row.down:SetPoint("RIGHT", row, "RIGHT", -2, 0)

		row.up = M.MakeFlatButton(row, 48, 22, L["Up"], function()
			mod:MovePosition(pos, pos - 1)
			mod:RefreshOptions()
			mod:ScheduleApply()
		end)
		row.up:SetPoint("RIGHT", row.down, "LEFT", -6, 0)

		p.rows[pos] = row
	end

	local bw = math.floor((W - 24 - 10) / 2)
	p.apply = M.MakeFlatButton(p, bw, 24, L["Apply Now"], function()
		mod:Apply(true, true)
		mod:RefreshOptions()
	end)
	p.apply:SetPoint("BOTTOMLEFT", p, "BOTTOMLEFT", 12, 4)

	p.reset = M.MakeFlatButton(p, bw, 24, L["Restore Defaults"], function()
		mod:ResetOrder()
		mod:RefreshOptions()
		mod:ScheduleApply()
	end)
	p.reset:SetPoint("BOTTOMRIGHT", p, "BOTTOMRIGHT", -12, 4)
end

-- 供框架事件分发：PLAYER_ENTERING_WORLD 由框架直接注册，PLAYER_LEVEL_UP 也需分发
M:RegisterModuleEvent("PLAYER_ENTERING_WORLD")
