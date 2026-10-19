-- MzxRiding（御龙术动作条固定 + 坐骑按钮组）
-- 御龙术：登录/重载后把技能按固定顺序放回御龙术动作条，避免暴雪默认 UI 打乱顺序。
-- 坐骑：可拖动的悬浮按钮组（功能坐骑 / 随机飞行 / 随机双人）。
-- 模块化：功能位于 Modules\*.lua，可在设置界面单独开关。
local ADDON, ns = ...
local L = ns.L

local M = CreateFrame("Frame")
ns.M = M
_G.MzxRiding = M -- 供 Bindings.xml 的片段调用

M.version = "1.0.4"
M.moduleList = {} -- 有序模块列表
M.modules = {} -- key -> module

local PREFIX = "|cff69ccf0MzxRiding|r "
local function Print(msg)
	print(PREFIX .. tostring(msg))
end
M.Print = Print

-- ------------------------------------------------------------------ 模块系统

function M:RegisterModule(mod)
	self.moduleList[#self.moduleList + 1] = mod
	self.modules[mod.key] = mod
	mod.owner = self
end

function M:IsModuleEnabled(key)
	local mod = self.modules[key]
	if mod and mod.alwaysOn then
		return true
	end
	return (self.db and self.db.modules and self.db.modules[key]) and true or false
end

function M:SetModuleEnabled(key, on)
	local mod = self.modules[key]
	if mod and mod.alwaysOn then
		return
	end
	if not self.db then
		return
	end
	on = on and true or false
	self.db.modules[key] = on
	if mod and mod.OnToggle then
		local ok, err = pcall(mod.OnToggle, mod, on)
		if not ok then
			Print(string.format(L["Module %s error: %s"], key, tostring(err)))
		end
	end
	self:RefreshConfigIfOpen()
end

-- 注册模块事件（同一事件只向框架注册一次；事件会转发给所有已启用模块）
function M:RegisterModuleEvent(event)
	self._modEvents = self._modEvents or {}
	if not self._modEvents[event] then
		self._modEvents[event] = true
		if not pcall(self.RegisterEvent, self, event) then
			self._modEvents[event] = nil
		end
	end
end

-- ------------------------------------------------------------------ 存档

local function EnsureDB()
	local db = MzxRidingDB
	if type(db) ~= "table" then
		db = {}
		MzxRidingDB = db
	end
	if type(db.modules) ~= "table" then
		db.modules = {}
	end
	if type(db.minimapPos) ~= "number" then
		db.minimapPos = 135
	end
	return db
end
M.EnsureDB = EnsureDB

local function EnsureCharDB()
	local cdb = MzxRidingCharDB
	if type(cdb) ~= "table" then
		cdb = {}
		MzxRidingCharDB = cdb
	end
	return cdb
end
M.EnsureCharDB = EnsureCharDB

function M:InitDB()
	self.db = EnsureDB()
	local charDb = EnsureCharDB()
	-- db.locale 只保留已知语言代码；空/"AUTO"/陈旧值一律视为「跟随客户端」
	if self.db.locale and not (ns.knownLocales and ns.knownLocales[self.db.locale]) then
		self.db.locale = nil
	end
	for _, mod in ipairs(self.moduleList) do
		if not mod.alwaysOn and self.db.modules[mod.key] == nil then
			self.db.modules[mod.key] = mod.defaultEnabled and true or false
		end
		if mod.EnsureDB then
			pcall(mod.EnsureDB, mod, self.db, charDb)
		end
	end
end

function M:ApplyModuleStates()
	for _, mod in ipairs(self.moduleList) do
		if mod.OnToggle then
			pcall(mod.OnToggle, mod, self:IsModuleEnabled(mod.key))
		end
	end
end

-- 按当前生效语言（db.locale 覆盖 → 否则客户端语言）刷新模块显示名。
-- 模块在加载期用英文键写下 name，这里在语言确定后再本地化一次。
function M:LocalizeModuleNames()
	for _, mod in ipairs(self.moduleList) do
		if mod.nameKey then
			mod.name = L[mod.nameKey]
		end
	end
end

-- ------------------------------------------------------------------ 通用 UI 皮肤

-- 扁平边框：内缩填充 + 四条独立 1px 边线；返回 setColors(borderR,G,B,A, fillR,G,B,A)
function M.MakeFlatSkin(frame, thickness)
	local t = thickness or 1
	local fill = frame:CreateTexture(nil, "BACKGROUND")
	fill:SetPoint("TOPLEFT", t, -t)
	fill:SetPoint("BOTTOMRIGHT", -t, t)
	local top = frame:CreateTexture(nil, "ARTWORK")
	top:SetPoint("TOPLEFT", 0, 0)
	top:SetPoint("TOPRIGHT", 0, 0)
	top:SetHeight(t)
	local bottom = frame:CreateTexture(nil, "ARTWORK")
	bottom:SetPoint("BOTTOMLEFT", 0, 0)
	bottom:SetPoint("BOTTOMRIGHT", 0, 0)
	bottom:SetHeight(t)
	local left = frame:CreateTexture(nil, "ARTWORK")
	left:SetPoint("TOPLEFT", 0, 0)
	left:SetPoint("BOTTOMLEFT", 0, 0)
	left:SetWidth(t)
	local right = frame:CreateTexture(nil, "ARTWORK")
	right:SetPoint("TOPRIGHT", 0, 0)
	right:SetPoint("BOTTOMRIGHT", 0, 0)
	right:SetWidth(t)
	local edges = { top, bottom, left, right }
	frame.flatBorder = top
	frame.flatFill = fill
	return function(br, bg, bb, ba, fr, fg, fb, fa)
		for i = 1, 4 do
			edges[i]:SetColorTexture(br, bg, bb, ba)
		end
		fill:SetColorTexture(fr, fg, fb, fa)
	end
end

-- 吸附到整数像素（窗口落在半像素时 1px 横线会被像素对齐吞掉）
function M.SnapToPixelGrid(f)
	if not f or not f.GetLeft then
		return
	end
	pcall(function()
		local left, bottom = f:GetLeft(), f:GetBottom()
		if not left or not bottom then
			return
		end
		local scale = f:GetEffectiveScale()
		if not scale or scale == 0 then
			return
		end
		local sl = math.floor(left * scale + 0.5) / scale
		local sb = math.floor(bottom * scale + 0.5) / scale
		local dx, dy = sl - left, sb - bottom
		if math.abs(dx) < 0.001 and math.abs(dy) < 0.001 then
			return
		end
		local point, relTo, relPoint, x, y = f:GetPoint(1)
		if not point then
			return
		end
		x, y = (x or 0) + dx, (y or 0) + dy
		if relTo then
			f:SetPoint(point, relTo, relPoint, x, y)
		else
			f:SetPoint(point, relPoint, x, y)
		end
	end)
end

-- 扁平按钮四态配色（无边框）
local FLAT_BTN = {
	normal = { bg = { 0.10, 0.11, 0.13, 0.92 }, text = { 0.78, 0.80, 0.85 } },
	hover = { bg = { 0.18, 0.20, 0.24, 0.96 }, text = { 1.00, 1.00, 1.00 } },
	pushed = { bg = { 0.06, 0.06, 0.08, 1.00 }, text = { 1.00, 1.00, 1.00 } },
	disabled = { bg = { 0.05, 0.05, 0.06, 0.70 }, text = { 0.40, 0.40, 0.42 } },
	selected = { bg = { 0.28, 0.23, 0.09, 1.00 }, text = { 1.00, 0.82, 0.20 } },
}

function M.ApplyFlatButtonVisual(b)
	local enabled = true
	if b.IsEnabled then
		enabled = b:IsEnabled()
	end
	local style
	if not enabled then
		style = FLAT_BTN.disabled
	elseif b.selected then
		style = FLAT_BTN.selected
	elseif b._pushed then
		style = FLAT_BTN.pushed
	elseif b._hovered then
		style = FLAT_BTN.hover
	else
		style = FLAT_BTN.normal
	end
	if b._setSkin then
		b._setSkin(0, 0, 0, 0, style.bg[1], style.bg[2], style.bg[3], style.bg[4])
	end
	local fs = b:GetFontString()
	if fs then
		fs:SetTextColor(style.text[1], style.text[2], style.text[3])
	end
	if b.icon then
		b.icon:SetVertexColor(style.text[1], style.text[2], style.text[3])
	end
end

function M.MakeFlatButton(parent, w, h, text, onClick)
	local b = CreateFrame("Button", nil, parent)
	b:SetSize(w, h)
	b._setSkin = M.MakeFlatSkin(b, 1)
	local fs = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	fs:SetPoint("CENTER", 0, 0)
	fs:SetText(text)
	b:SetFontString(fs)
	b._hovered, b._pushed = false, false
	b:SetScript("OnEnter", function(self)
		self._hovered = true
		M.ApplyFlatButtonVisual(self)
	end)
	b:SetScript("OnLeave", function(self)
		self._hovered = false
		self._pushed = false
		M.ApplyFlatButtonVisual(self)
	end)
	b:SetScript("OnMouseDown", function(self)
		self._pushed = true
		M.ApplyFlatButtonVisual(self)
	end)
	b:SetScript("OnMouseUp", function(self)
		self._pushed = false
		M.ApplyFlatButtonVisual(self)
	end)
	b:SetScript("OnEnable", function(self)
		M.ApplyFlatButtonVisual(self)
	end)
	b:SetScript("OnDisable", function(self)
		M.ApplyFlatButtonVisual(self)
	end)
	if onClick then
		b:SetScript("OnClick", onClick)
	end
	M.ApplyFlatButtonVisual(b)
	return b
end

-- 给扁平按钮挂一个图标（无文字），原图按整数倍缩放居中显示
function M.SetButtonIcon(b, texPath, iconSize)
	local tex = b.icon
	if not tex then
		tex = b:CreateTexture(nil, "ARTWORK")
		b.icon = tex
	end
	tex:SetSize(iconSize, iconSize)
	tex:ClearAllPoints()
	tex:SetPoint("CENTER")
	tex:SetTexture(texPath)
	local fs = b:GetFontString()
	if fs then
		fs:SetText("")
	end
	M.ApplyFlatButtonVisual(b)
	return tex
end

-- 现代扁平关闭按钮：两条交叉细线，悬停变红
function M.MakeCloseButton(parent)
	local btn = CreateFrame("Button", nil, parent)
	btn:SetSize(18, 18)
	local function bar(rot)
		local t = btn:CreateTexture(nil, "ARTWORK")
		t:SetSize(13, 2)
		t:SetPoint("CENTER")
		t:SetRotation(rot)
		t:SetColorTexture(0.62, 0.63, 0.66, 1)
		return t
	end
	local a = bar(math.rad(45))
	local b = bar(math.rad(-45))
	local function paint(r, g, bl, al)
		a:SetColorTexture(r, g, bl, al)
		b:SetColorTexture(r, g, bl, al)
	end
	btn:SetScript("OnEnter", function()
		paint(1, 0.40, 0.40, 1)
	end)
	btn:SetScript("OnLeave", function()
		paint(0.62, 0.63, 0.66, 1)
	end)
	return btn
end

-- 现代扁平方框复选框（无边框，金色选中标记）
function M.MakeFlatCheckbox(parent, text, onClick)
	local cb = CreateFrame("CheckButton", nil, parent)
	cb:SetSize(18, 18)
	local setSkin = M.MakeFlatSkin(cb, 1)
	setSkin(0, 0, 0, 0, 0.08, 0.09, 0.11, 0.95)
	local check = cb:CreateTexture(nil, "OVERLAY")
	check:SetPoint("CENTER")
	check:SetSize(10, 10)
	check:SetColorTexture(1, 0.82, 0.20, 1)
	cb:SetCheckedTexture(check)
	local hover = cb:CreateTexture(nil, "HIGHLIGHT")
	hover:SetAllPoints()
	hover:SetColorTexture(1, 1, 1, 0.08)
	cb:SetHighlightTexture(hover, "ADD")
	local fs = cb:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	fs:SetPoint("LEFT", cb, "RIGHT", 6, 0)
	fs:SetText(text)
	cb.Text = fs
	if onClick then
		cb:SetScript("OnClick", onClick)
	end
	return cb
end

-- 标准「两行文字」扁平列表行（行高/图标/两行间距的唯一定义处，各模块别再各写一套）。
-- opts = { height, iconSize, stripe, singleLine, onClick }
--   singleLine = true 时只显示一行名称（名称垂直居中，不建第二行）
-- 返回 row，含 row.icon / row.name / row.sub / row.state，
-- 以及 row:SetSelected(on)（金色选中 + 左侧强调条）/ row:SetStripe(on)（斑马纹）。
M.LIST_ROW_HEIGHT = 40
function M.MakeListRow(parent, opts)
	opts = opts or {}
	local row = CreateFrame("Button", nil, parent)
	row:SetHeight(opts.height or M.LIST_ROW_HEIGHT)

	local stripe = row:CreateTexture(nil, "BACKGROUND", nil, -6)
	stripe:SetAllPoints()
	stripe:SetColorTexture(1, 1, 1, 0.03)
	stripe:SetShown(opts.stripe and true or false)
	row.stripe = stripe

	local hl = row:CreateTexture(nil, "HIGHLIGHT")
	hl:SetAllPoints()
	hl:SetColorTexture(1, 1, 1, 0.06)
	row:SetHighlightTexture(hl, "ADD")

	local sel = row:CreateTexture(nil, "BACKGROUND", nil, -4)
	sel:SetAllPoints()
	sel:SetColorTexture(1, 0.82, 0.2, 0.14)
	sel:Hide()
	row.sel = sel

	local selBar = row:CreateTexture(nil, "BACKGROUND", nil, -3)
	selBar:SetPoint("TOPLEFT", 0, 0)
	selBar:SetPoint("BOTTOMLEFT", 0, 0)
	selBar:SetWidth(2)
	selBar:SetColorTexture(1, 0.82, 0.2, 0.9)
	selBar:Hide()
	row.selBar = selBar

	local size = opts.iconSize or 22
	row.icon = row:CreateTexture(nil, "ARTWORK")
	row.icon:SetSize(size, size)
	row.icon:SetPoint("LEFT", 8, 0)
	row.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

	row.name = row:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	row.name:SetJustifyH("LEFT")
	if opts.singleLine then
		row.name:SetPoint("LEFT", row.icon, "RIGHT", 8, 0)
	else
		row.name:SetPoint("LEFT", row.icon, "RIGHT", 8, 6)
		row.sub = row:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
		row.sub:SetPoint("TOPLEFT", row.name, "BOTTOMLEFT", 0, -1)
		row.sub:SetJustifyH("LEFT")
		row.sub:SetTextColor(0.6, 0.6, 0.6)
	end

	row.state = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	row.state:SetPoint("RIGHT", row, "RIGHT", -6, 0)
	row.state:SetJustifyH("RIGHT")

	function row:SetSelected(on)
		sel:SetShown(on and true or false)
		selBar:SetShown(on and true or false)
	end

	function row:SetStripe(on)
		stripe:SetShown(on and true or false)
	end

	if opts.onClick then
		row:SetScript("OnClick", opts.onClick)
	end
	return row
end

-- 提示行前缀的小鼠标图标：自有紧裁剪纹理，图案内缩为 0，可与正文左边线严格对齐。
-- 所有提示必须走 M.MouseIcon，保证尺寸与左对齐完全一致，禁止各处另写尺寸。
local MOUSE_L = "|TInterface\\AddOns\\MzxRiding\\Textures\\mouse-left.tga:12:9|t "
local MOUSE_R = "|TInterface\\AddOns\\MzxRiding\\Textures\\mouse-right.tga:12:9|t "

function M.MouseIcon(which)
	if which == "R" then
		return MOUSE_R
	end
	return MOUSE_L
end

-- 列表右侧状态图标（主选 / 已选 / 当前语言），替代状态文字
function M.SetStateIcon(row, on, texPath, iconSize)
	local tex = row.stateIcon
	if not tex then
		if row.state then
			row.state:Hide()
		end
		tex = row:CreateTexture(nil, "ARTWORK")
		tex:SetSize(iconSize or 16, iconSize or 16)
		tex:SetPoint("RIGHT", row, "RIGHT", -8, 0)
		tex:SetTexture(texPath or "Interface\\AddOns\\MzxRiding\\Textures\\check.tga")
		tex:Hide()
		row.stateIcon = tex
	end
	tex:SetShown(on and true or false)
	return tex
end

-- 小标题（分区标题）
function M.MakeSectionLabel(parent, text)
	local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	fs:SetText("|cffffd200" .. text .. "|r")
	fs:SetJustifyH("LEFT")
	return fs
end

-- ------------------------------------------------------------------ 设置界面

local GUI_WIDTH = 470
-- 内容区高度 p_h = GUI_HEIGHT - 72 - 14 = GUI_HEIGHT - 86。
-- Mounts 模块把配置区再分成子标签，页面高 = p_h - 54 - 2；功能页 8 行 × 40 从
-- rowTop(-42, 页内) 起 → 末行底部 = 42 + 320 = 362（页内），底部控件占页高-28，
-- 故页高 ≥ 362 + 12 + 28 = 402 → p_h = 458 → GUI_HEIGHT = 458 + 86 = 544。
local GUI_HEIGHT = 544

function M:SelectTab(key)
	local f = self.configFrame
	if not f then
		return
	end
	f.selectedKey = key
	for _, mod in ipairs(self.moduleList) do
		local b = f.tabs[mod.key]
		if b then
			b.selected = (mod.key == key)
			self.ApplyFlatButtonVisual(b)
		end
	end
	for _, mod in ipairs(self.moduleList) do
		local p = mod.optionsFrame
		if p then
			p:SetShown(mod.key == key)
		end
	end
end

function M:GetModulePanel(mod)
	if mod.optionsFrame then
		return mod.optionsFrame
	end
	local f = self.configFrame
	local p = CreateFrame("Frame", nil, f.content)
	p:SetAllPoints(f.content)
	if not mod.alwaysOn then
		local cb = M.MakeFlatCheckbox(p, L["Enable this module"], function(cbSelf)
			self:SetModuleEnabled(mod.key, cbSelf:GetChecked())
		end)
		cb:SetPoint("TOPLEFT", p, "TOPLEFT", 12, -2)
		p.enable = cb
	end
	-- 必须先赋值 optionsFrame，BuildOptions 内部（如 Mounts 的 SelectSub）会读它
	mod.optionsFrame = p
	if mod.BuildOptions then
		local ok, err = pcall(mod.BuildOptions, mod, p)
		if not ok then
			Print(string.format(L["Module %s options error: %s"], mod.key, tostring(err)))
		end
	end
	-- 面板刚建好时立刻填一次内容，否则要等下一次 RefreshConfig（比如切标签）才会显示
	if mod.RefreshOptions then
		pcall(mod.RefreshOptions, mod)
	end
	return p
end

function M:RefreshConfig()
	local f = self.configFrame
	if not f then
		return
	end
	for _, mod in ipairs(self.moduleList) do
		-- 懒加载当前页要先建好，下面才能填内容（否则首次打开是空的）
		local selected = (mod.key == f.selectedKey)
		if selected then
			self:GetModulePanel(mod)
		end

		local b = f.tabs[mod.key]
		if b then
			b.selected = selected
			self.ApplyFlatButtonVisual(b)
		end
		if mod.optionsFrame then
			mod.optionsFrame:SetShown(selected)
			if mod.optionsFrame.enable then
				mod.optionsFrame.enable:SetChecked(self:IsModuleEnabled(mod.key))
			end
			if mod.RefreshOptions then
				pcall(mod.RefreshOptions, mod)
			end
		end
	end
end

function M:RefreshConfigIfOpen()
	if self.configFrame and self.configFrame:IsShown() then
		self:RefreshConfig()
	end
end

function M:CreateConfigFrame()
	if self.configFrame then
		return self.configFrame
	end
	local f = CreateFrame("Frame", "MzxRidingConfigFrame", UIParent, "BackdropTemplate")
	f:SetSize(GUI_WIDTH, GUI_HEIGHT)
	f:SetPoint("CENTER")
	-- 独立 strata：本窗内部全是子 frame（按钮/滚动条/行），子 frame 有各自的 frame level，
	-- 同 strata 时两个窗口的底都压不住对方的子件 → 交错。
	-- HIGH 已不够：暴雪的插件列表 / 设置面板也在 HIGH~DIALOG 之间，会与本窗交错。
	-- 提到 FULLSCREEN_DIALOG（高于 DIALOG、低于 TOOLTIP），整棵树作为一个整体恒在最上。
	f:SetFrameStrata("FULLSCREEN_DIALOG")
	f:SetFrameLevel((UIParent:GetFrameLevel() or 0) + 20)
	f:SetClampedToScreen(true)
	f:SetMovable(true)
	f:EnableMouse(true)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", f.StartMoving)
	f:SetScript("OnDragStop", function()
		f:StopMovingOrSizing()
		M.SnapToPixelGrid(f)
	end)
	f:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8X8",
		edgeFile = "Interface\\Buttons\\WHITE8X8",
		edgeSize = 1,
	})
	f:SetBackdropColor(0.05, 0.06, 0.07, 0.94)
	f:SetBackdropBorderColor(0.28, 0.30, 0.35, 1)
	f:SetScript("OnShow", function()
		M.SnapToPixelGrid(f)
		M:RefreshConfig()
	end)

	local header = f:CreateTexture(nil, "BACKGROUND")
	header:SetPoint("TOPLEFT", 1, -1)
	header:SetPoint("TOPRIGHT", -1, -1)
	header:SetHeight(26)
	header:SetColorTexture(0.11, 0.12, 0.14, 0.92)

	local headerLine = f:CreateTexture(nil, "ARTWORK")
	headerLine:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, 0)
	headerLine:SetPoint("TOPRIGHT", header, "BOTTOMRIGHT", 0, 0)
	headerLine:SetHeight(1)
	headerLine:SetColorTexture(1.0, 0.82, 0.20, 0.45)

	local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	title:SetPoint("LEFT", header, "LEFT", 12, 0)
	title:SetText(L["MzxRiding Settings"])

	local close = M.MakeCloseButton(f)
	close:SetPoint("TOPRIGHT", -6, -6)
	close:SetScript("OnClick", function()
		f:Hide()
	end)
	pcall(tinsert, UISpecialFrames, "MzxRidingConfigFrame")

	-- 顶部分段标签：每个模块一个
	f.tabs = {}
	local prev
	local n = #self.moduleList
	local gap = 4
	local tabW = math.floor((GUI_WIDTH - 24 - gap * (n - 1)) / math.max(n, 1))
	for i, mod in ipairs(self.moduleList) do
		local b = M.MakeFlatButton(f, tabW, 24, mod.name or mod.key, nil)
		b.selected = false
		b:SetFrameLevel(f:GetFrameLevel() + 3)
		local key = mod.key
		b:SetScript("OnClick", function()
			M:SelectTab(key)
			M:RefreshConfig()
		end)
		if i == 1 then
			b:SetPoint("TOPLEFT", f, "TOPLEFT", 12, -36)
		else
			b:SetPoint("LEFT", prev, "RIGHT", gap, 0)
		end
		f.tabs[mod.key] = b
		prev = b
	end

	-- 内容区必须锚到框体自身的左上角（分段标签那一行下面），
	-- 千万不要锚到 prev（最后一个标签在右侧，会把内容整体挤到右边）。
	f.content = CreateFrame("Frame", nil, f)
	f.content:SetFrameLevel(f:GetFrameLevel() + 1)
	f.content:SetPoint("TOPLEFT", f, "TOPLEFT", 12, -72)
	f.content:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -12, 14)

	f.selectedKey = self.moduleList[1] and self.moduleList[1].key or nil

	self.configFrame = f
	return f
end

function M:OpenConfig()
	if not self.db then
		self:InitDB()
	end
	local f = self:CreateConfigFrame()
	f:Show()
	self:RefreshConfig()
	return f
end

function M:ToggleConfig()
	if not self.db then
		self:InitDB()
	end
	if self.configFrame and self.configFrame:IsShown() then
		self.configFrame:Hide()
		return
	end
	self:OpenConfig()
end

-- ------------------------------------------------------------------ 小地图按钮

local MINIMAP_ICON = "Interface\\AddOns\\MzxRiding\\Textures\\icon.tga"
local MINIMAP_RADIUS = 5
local MINIMAP_DEFAULT_POS = 135

local MINIMAP_SHAPES = {
	["ROUND"] = { true, true, true, true },
	["SQUARE"] = { false, false, false, false },
	["CORNER-TOPLEFT"] = { false, false, false, true },
	["CORNER-TOPRIGHT"] = { false, false, true, false },
	["CORNER-BOTTOMLEFT"] = { false, true, false, false },
	["CORNER-BOTTOMRIGHT"] = { true, false, false, false },
	["SIDE-LEFT"] = { false, true, false, true },
	["SIDE-RIGHT"] = { true, false, true, false },
	["SIDE-TOP"] = { false, false, true, true },
	["SIDE-BOTTOM"] = { true, true, false, false },
	["TRICORNER-TOPLEFT"] = { false, true, true, true },
	["TRICORNER-TOPRIGHT"] = { true, false, true, true },
	["TRICORNER-BOTTOMLEFT"] = { true, true, false, true },
	["TRICORNER-BOTTOMRIGHT"] = { true, true, true, false },
}

function M:UpdateMinimapButtonPosition(position)
	local b = self.minimapButton
	if not b then
		return
	end
	local angle = math.rad(position or MINIMAP_DEFAULT_POS)
	local x, y, q = math.cos(angle), math.sin(angle), 1
	if x < 0 then
		q = q + 1
	end
	if y > 0 then
		q = q + 2
	end
	local quads = MINIMAP_SHAPES[GetMinimapShape and GetMinimapShape() or "ROUND"] or MINIMAP_SHAPES["ROUND"]
	local w = (Minimap:GetWidth() / 2) + MINIMAP_RADIUS
	local h = (Minimap:GetHeight() / 2) + MINIMAP_RADIUS
	if quads[q] then
		x, y = x * w, y * h
	else
		local dw = math.sqrt(2 * w * w) - 10
		local dh = math.sqrt(2 * h * h) - 10
		x = math.max(-w, math.min(x * dw, w))
		y = math.max(-h, math.min(y * dh, h))
	end
	b:ClearAllPoints()
	b:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

function M:PlaceMinimapButton()
	local db = self.db or EnsureDB()
	if type(db.minimapPos) ~= "number" then
		db.minimapPos = MINIMAP_DEFAULT_POS
	end
	self:UpdateMinimapButtonPosition(db.minimapPos)
end

function M:CreateMinimapButton()
	if self.minimapButton then
		return self.minimapButton
	end

	local b = CreateFrame("Button", "MzxRidingMinimapButton", Minimap)
	b:SetSize(31, 31)
	b:SetFrameStrata("MEDIUM")
	b:SetFixedFrameStrata(true)
	b:SetFrameLevel(8)
	b:SetFixedFrameLevel(true)
	b:RegisterForClicks("LeftButtonUp")
	b:RegisterForDrag("LeftButton")

	local border = b:CreateTexture(nil, "OVERLAY")
	border:SetTexture(136430)
	border:SetSize(50, 50)
	border:SetPoint("TOPLEFT", 0, 0)
	b.border = border

	-- 圆形黑底已烘进 icon.tga 本身；这里只留一块很小的纯色兜底（完全被圆盖住）
	local background = b:CreateTexture(nil, "BACKGROUND")
	background:SetColorTexture(0.05, 0.06, 0.08, 0.97)
	background:SetSize(12, 12)
	background:SetPoint("CENTER", 0, 0)
	b.background = background

	local icon = b:CreateTexture(nil, "ARTWORK")
	icon:SetTexture(MINIMAP_ICON)
	icon:SetPoint("CENTER")
	icon:SetSize(18, 18)
	b.icon = icon

	-- 悬停高亮用标准小地图光环（LibDBIcon 默认同款）：圆形光晕只点亮边框，
	-- 不像「纯色 + SetAllPoints」那样把整个方块盖住、四角露出色块显出方框。
	b:SetHighlightTexture(136477) -- "Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight"

	b:SetScript("OnClick", function()
		M:ToggleConfig()
	end)

	local function onUpdate()
		local mx, my = Minimap:GetCenter()
		local px, py = GetCursorPosition()
		local scale = Minimap:GetEffectiveScale()
		px, py = px / scale, py / scale
		local pos = math.deg(math.atan2(py - my, px - mx)) % 360
		if M.db then
			M.db.minimapPos = pos
		end
		M:UpdateMinimapButtonPosition(pos)
	end

	b:SetScript("OnDragStart", function(self)
		self:LockHighlight()
		GameTooltip:Hide()
		b:SetScript("OnUpdate", onUpdate)
	end)
	b:SetScript("OnDragStop", function(self)
		b:SetScript("OnUpdate", nil)
		self:UnlockHighlight()
	end)

	b:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_LEFT")
		GameTooltip:AddLine("MzxRiding", 1, 1, 1)
		GameTooltip:AddLine(L["Skyriding action bar fix · Mount buttons"], 0.6, 0.6, 0.6)
		GameTooltip:AddLine(M.MouseIcon("L") .. L["Open/close settings"], 0.8, 0.8, 0.8)
		GameTooltip:Show()
	end)
	b:SetScript("OnLeave", GameTooltip_Hide)

	self.minimapButton = b
	self:PlaceMinimapButton()
	return b
end

-- ------------------------------------------------------------------ 命令

function M:Help()
	Print(L["Commands:"])
	print(L["  /mzxr                Open settings"])
	print(L["  /mzxr list           List modules and their state"])
	print(L["  /mzxr on <module>    Enable a module"])
	print(L["  /mzxr off <module>   Disable a module"])
	local keys = {}
	for _, mod in ipairs(self.moduleList) do
		keys[#keys + 1] = mod.key
	end
	print(string.format(L["  Modules: %s"], table.concat(keys, " ")))
end

function M:Slash(input)
	if not self.db then
		self:InitDB()
	end
	local cmd, rest = string.match(input or "", "^(%S*)%s*(.*)$")
	cmd = string.lower(cmd or "")
	rest = rest or ""
	if cmd == "" then
		self:OpenConfig()
	elseif cmd == "help" then
		self:Help()
	elseif cmd == "list" then
		for _, mod in ipairs(self.moduleList) do
			Print(string.format(L["%s (%s): %s"], mod.name or mod.key, mod.key, self:IsModuleEnabled(mod.key) and L["on"] or L["off"]))
		end
	elseif cmd == "on" or cmd == "off" then
		local key = string.lower((rest:gsub("%s+$", "")))
		if self.modules[key] then
			self:SetModuleEnabled(key, cmd == "on")
			Print(string.format(L["%s is now %s"], key, cmd == "on" and L["enabled"] or L["disabled"]))
		else
			Print(string.format(L["Unknown module: %s"], key))
		end
	else
		Print(L["Unknown command. Type /mzxr help"])
	end
end

SLASH_MZXRIDING1 = "/mzxr"
SLASH_MZXRIDING2 = "/mzxriding"
SlashCmdList["MZXRIDING"] = function(input)
	M:Slash(input)
end

-- ------------------------------------------------------------------ 事件

M:RegisterEvent("ADDON_LOADED")
M:RegisterEvent("PLAYER_ENTERING_WORLD")

M:SetScript("OnEvent", function(self, event, ...)
	if event == "ADDON_LOADED" then
		if ... == ADDON then
			self:InitDB()
			ns.ApplyLocale(self.db.locale or GetLocale())
			self:LocalizeModuleNames()
			self:CreateMinimapButton()
			self:ApplyModuleStates()
		end
		return
	end
	if event == "PLAYER_ENTERING_WORLD" then
		if not self.minimapButton then
			self:CreateMinimapButton()
		end
		self:PlaceMinimapButton()
	end
	for _, mod in ipairs(self.moduleList) do
		if self:IsModuleEnabled(mod.key) and mod.OnEvent then
			local ok, err = pcall(mod.OnEvent, mod, event, ...)
			if not ok then
				Print(string.format(L["Module %s error: %s"], mod.key, tostring(err)))
			end
		end
	end
end)
