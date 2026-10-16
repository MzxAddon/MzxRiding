# AGENTS.md - MzxRiding

## 项目状态
- World of Warcraft *retail*（Midnight 12.1.5）插件 `MzxRiding`。当前**不是 git 仓库**；除非用户先让你初始化，否则**不要**执行 `git commit`。
- 文件夹：`D:\Program Files\World of Warcraft\_retail_\Interface\AddOns\MzxRiding\`
- TOC：`MzxRiding.toc`（Interface 120105，版本 1.2.7，SavedVariables `MzxRidingDB`，`## IconTexture: Interface\AddOns\MzxRiding\icon.tga`）
- 加载顺序（按 TOC）：`Localization.lua` → `Locales\*.lua`（zhCN/zhTW/koKR/deDE/frFR/esES/esMX/ruRU/ptBR/itIT） → `Core.lua` → `Modules\Skyriding.lua` → `Modules\Mounts.lua` → `Modules\Language.lua`
- 三个模块（全部默认开启，`defaultEnabled = true`）：`skyriding`、`mounts`、`language`。由 `Core.lua` 的 `M:RegisterModule(mod)` 管理，`M:IsModuleEnabled(key)`/`M:SetModuleEnabled(key,on)` 控制开关并调用 `mod.OnToggle`。
- 全局：`_G.MzxRiding = M`；命令：`/mzxr`、`/mzxriding`。

## 核心（Core.lua）
- `local ADDON, ns = ...`；`ns.M = M`；`ns.L = L`（来自 `Localization.lua` 的词库回退）。
- 模块注册表 `self.modules` 与有序列表 `self.moduleList`。`InitDB()` 为每个模块写入 `db.modules[mod.key] = defaultEnabled`，并调用各模块 `mod:EnsureDB(db)`（如果存在）。
- 配置窗 `MzxRidingConfigFrame`，`GUI_WIDTH = 470`、`GUI_HEIGHT = 544`。扁平皮肤（`M.MakeFlatSkin` + `WHITE8X8` 底/边）、header + 金色 `headerLine`、`M.MakeCloseButton`。标签页按模块分（`f.tabs[mod.key]`），选中切换对应面板 `f.panels[mod.key]`。`M:OpenConfig()`/`M:ToggleConfig()`/`M:RefreshConfig()`/`M:RefreshConfigIfOpen()`。
- 共享 UI 助手：`M.MakeFlatSkin`、`M.SnapToPixelGrid`（`OnShow` + `OnDragStop` 处理半像素缺线）、`M.ApplyFlatButtonVisual`、`M.MakeFlatButton(w,h,text,onClick)`、`M.MakeCloseButton`、`M.MakeFlatCheckbox(text,onClick)`、`M.MakeSectionLabel(text)`、**`M.MakeListRow(parent, opts)`**（扁平列表行标准，**新列表一律用这个工厂，不得手搓行**）。`M.LIST_ROW_HEIGHT = 40`。`opts = {height, iconSize=22, stripe, singleLine, onClick}`；`singleLine` 名字居中且不创建 `row.sub`；`row:SetSelected(on)` 金色调 + 2px 金色左强调条；`row:SetStripe(on)`。
- 小地图按钮（`M:CreateMinimapButton`）：31×31，父级 `Minimap`，strata MEDIUM/level 8，`border = Interface\Minimap\MiniMap-TrackingBorder`（136430，50×50），`background = SetColorTexture(0.05,0.06,0.08,0.97)`（12×12 中心，真正黑色圆已烘进 `icon.tga`），`icon = Interface\AddOns\MzxRiding\icon.tga`（18×18 CENTER），高亮 `136477`。可拖动（LibDBIcon 风格：`db.minimapPos` 角度，`GetCursorPosition()/Minimap:GetEffectiveScale()`）。左键打开配置，悬停显示提示。
- 斜杠：`/mzxr` 空参数→打开配置；`help`、`list`、`on <key>`、`off <key>`。`M:Slash(input)` 处理。

## 模块：Skyriding（Modules\Skyriding.lua）
- `key = "skyriding"`，`nameKey = "Skyriding"`，`defaultEnabled = true`。`M:RegisterModule(mod)`，注册事件 `PLAYER_LEVEL_UP`、`PLAYER_ENTERING_WORLD`。
- 目的：登录/重载/升级后，把御龙术技能按固定顺序放回**御龙术动作条**，避免暴雪默认 UI 随机打乱顺序。
- 御龙术动作条 = **Bonus Bar 5**，动作槽 **`121–132`**。`C_ActionBar.GetBonusBarIndex()` 返回 11（Dragonriding）。
- 技能（spellID）：Whirling Surge `361584`（备选 `418592`）、Surge Forward `372608`、Second Wind `425782`、Aerial Halt `403092`、Skyward Ascent `372610`。默认顺序 whirl→surge→second→halt→ascent。
- 放置：`C_Spell.PickupSpell`（或 `PickupSpell` 回退）+ `C_ActionBar.PutActionInSlot(slot)`（或 `PlaceAction` 回退）。先从槽 121-132 把受管技能剥离，再按顺序逐格放置。**战斗中跳过（`InCombatLockdown()`）**，失败均用 `pcall` 包裹。
- 配置（`BuildOptions`/`RefreshOptions`，在 `M:GetModulePanel(mod)` 内）：5 行技能，图标 + `<slot>. <name>` + 上移/下移按钮；扁平 `立即应用`（BOTTOMLEFT）/`恢复默认`（BOTTOMRIGHT）。行用斑马纹 + ADD 悬停高亮。

## 模块：Mounts（Modules\Mounts.lua）
- `key = "mounts"`，`nameKey = "Mounts"`，`defaultEnabled = true`。注册事件 `PLAYER_ENTERING_WORLD`、`NEW_MOUNT_ADDED`、`GLOBAL_MOUSE_DOWN`。
- 可拖动浮动按钮组 `MzxRidingMountGroup`（`UIParent`，MEDIUM，扁平皮肤）。三个按钮：`func`（功能坐骑）、`fly`（随机飞行）、`duo`（随机双人）。`GROUP_BUTTON=44`、`GROUP_GAP=3`、`GROUP_PAD=3`。拖动 vs 点击用 `b._dragged` 区分。
- **func**：左键 = 召唤主选功能坐骑；右键 = 自定义扁平下拉菜单（列出已拥有功能坐骑，右侧 `row.state="当前"` 标记主选，点击设为主选，底部"打开设置界面"）。主选存 `db.mounts.primary`，**仅当仍已收集且当前角色可用**时有效，否则自动回退到第一个已拥有可用。
- **fly/duo**：左键 = `SummonRandom(which)`，右键 = `OpenConfigAt(which)` 跳到设置子标签。随机池模型：保存待召唤的预选 id（运行时，不落盘）；召唤后立刻随机下一只存入预选（避免连续重复上一只）。按钮图标 = 预选 → lastXxx → 默认图标兜底。
- 功能坐骑列表 `FUNCTIONAL_MOUNTS`（硬编码，8 项）：`3137,2265,1039,2982,2237,460,280,284`，服务标签 `{Mail,Repair,Transmog,Auction House,Vendor}`。坐骑信息用 `pcall(C_MountJournal.GetMountInfoByID)` 获取 `name/icon/isCollected/isUsable/shouldHideOnChar`，`usable = isUsable and not shouldHideOnChar`；未拥有或当前角色不可用的坐骑在设置里显示为「不可用」且不可设为主选。
- 飞行判定（`IsFlyingMount`）：`isSteadyFlight` 或 `mountTypeID` ∈ `{242,247,248,398,402,407,424,436}`。`CollectedFlying()` 返回已拥有且 `usable` 且可飞行的列表（按名字排序），缓存 `self._flyCache`，`NEW_MOUNT_ADDED`/`InvalidateFlyCache()` 清空。
- **随机双人**：`DUO_MOUNTS` 为硬编码白名单（Warcraft Wiki Passenger_mounts），`CollectedDuo()` = `DUO_MOUNTS ∩ 已拥有 ∩ usable ∩ 可飞行`。**没有 API 能识别双人坐骑**，因此设置的「随机双人坐骑」池需要手动勾选。
- 池初始化：`flyPool` **一次性**用所有已拥有飞行坐骑播种（`flyPoolInit` 守护）；`duoPool` **初始为空**。`TogglePoolEntry`/`SetPoolAll(which,on)`、`SummonRandom` 都基于 `PoolList(which)`。
- 配置子标签 `func/fly/duo`（`BuildOptions` + `SelectSub`）。功能页使用 `M.MakeListRow`（单行，`iconSize=26`）；两个随机页使用自带滚动列表（`MakeScrollList`），行也用 `M.MakeListRow`（单行，`iconSize=26`），右键可直接召唤 `mod:SummonById(id)`，左键沿用原行为。底部控件：全选/全不选/随机召唤一只。
- `db.mounts = { primary, show=true, buttonPoint, flyPool={[id]=true}, duoPool={[id]=true}, flyPoolInit, duoPoolInit }`，`buttonPoint` 默认 `{ "CENTER", "UIParent", "CENTER", 0, 0 }`，`OnDragStop` + `M.SnapToPixelGrid` 后保存。

## 模块：Language（Modules\Language.lua）
- `key = "language"`，`nameKey = "Language"`，`defaultEnabled = true`。
- `LOCALES` 共 12 项：`enUS,enGB,zhCN,zhTW,koKR,deDE,frFR,esES,esMX,ruRU,ptBR,itIT`。列表行用 `M.MakeListRow`（单行，`ROW_H=28`），点击 `mod:SetLocale(code)`（`AUTO` 对应 `nil` → 跟随客户端）后通过 `M.Print` 提示并调用 `ReloadUI()` 生效。`db.locale` 存在时覆盖客户端语言。
- `ns.knownLocales` 白名单用于 DB 清洗；`ns.ApplyLocale(code)` 全量重置英文基准再套用指定语言（找不到键则回退英文）。

## i18n / 本地化
- `Localization.lua`：英文基准词库 + `__index` 回退；`ns.RegisterLocale(code, data)` 注册语言表；`ns.ApplyLocale` 应用。
- `Locales\*.lua` 各自只覆盖不同键。**enUS/enGB 不单独提供 locale 文件**，直接用基准。
- 基准键覆盖全面，缺失键一律回退英文，不会返回 nil。

## 图标（icon.tga / icon-source.png）
- `## IconTexture: Interface\AddOns\MzxRiding\icon.tga`（128×128，32bpp 未压缩 TGA，top-down，type 2）
- `icon-source.png` 为渲染源（**不得同时保留 `icon.png` 与 `icon.tga`**）。重生成后必须用 `adddisc.ps1` 对 `icon.tga` **烘焙暗色圆盘**（基色 RGB(13,15,20)，半径 `min(w,h)/2-1`），并备份旧版。四角 A=0，边缘抗锯齿正常，**0 绿像素**。
- 小地图 18×18 降采样时需保证马蹄铁可辨，翅膀为浅色点缀属可接受范围。

## 代码风格与约定
- **不要添加任何注释，除非用户明确要求**。
- 修改文件前先 `read`/`grep` 理解上下文，严格模仿现有代码风格、命名与模式。
- **新增列表一律使用 `M.MakeListRow`，禁止手搓行**。两个插件同类封装**各自放各自插件里，绝不共用**。
- 外观统一（扁平风格、间距、锚定一致），不得破坏原有 UI（不错位、不交错），不得破坏功能（不失灵）。
- 所有外部 API 调用优先用 WoW 现代 API（C_*），必要时用 pcall 包裹，避免因单个条目报错导致整个列表崩溃。
- 子标签/按钮宽度约 116–146px，文案一律精简。介绍/提示文本尽量短。
- **只在用户明确要求时才执行 `git commit`**。当前目录不是 git 仓库。

## 校验
- 语法检查可用 `luaparse`（Lua 5.1）；临时脚本位于 `C:\Users\huang\AppData\Local\Temp\opencode\`（`check.js`、`enccheck.js`、`i18ncheck.js` 等）。无需运行测试/构建。
- 修改后优先自查关键逻辑（锚定、事件注册、池初始化/预选、combat guard），然后简短汇报结果。

## 环境说明
- 路径含空格（`Program Files`、`World of Warcraft`），处理文件路径时务必加双引号。
- PowerShell：避免 `Get-Content`/`Set-Content` 处理 CJK（易双重编码），优先用 `edit`/`write` 或 `[System.IO.File]::ReadAllText/WriteAllText(..., [System.Text.UTF8Encoding]::new($false))`。
- 控制台 CJK 显示可能乱码，需审查文案时导出 UTF-8 文件再查看。