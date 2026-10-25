--[[
================================================================
                  花園塔防 GTD｜隊友塔查看
================================================================
【功能】
  1. 點擊地圖上隊友的塔，開啟遊戲原生的塔查看器，可查看等級與數值。
     （查看隊友的塔時會隱藏賣出 / 升級 / 目標按鈕）
  2. 查看器右側「三條（數據）」按鈕下方新增「i」按鈕，開啟塔的效果說明面板（自己的塔也適用）。
     按鈕放在 gethui，不寫入遊戲的 PlayerGui；只在查看器開啟時顯示。
     遊戲同時只能開一個面板，開啟說明後查看器會關閉，要看數值再點一次塔即可。
  3. 內建塔效果翻譯：自動把塔 / 敵人 / 詞條的英文說明換成中文。
     語言依 Tsetingnil_script/keysystem.json 的 script_language，英文則保留原文。

【使用方式】
  - 在關卡內執行即可（大廳無效）。
  - 再執行一次 = 關閉，還原點擊與按鈕。
================================================================
--]]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- 重複執行 = 關閉
if getgenv().GTD_TEAMMATE_CLEANUP then
	pcall(getgenv().GTD_TEAMMATE_CLEANUP)
	getgenv().GTD_TEAMMATE_CLEANUP = nil
	-- 一併移除舊版留下的自建視窗
	pcall(function()
		local hui = (gethui and gethui()) or game:GetService("CoreGui")
		for _, name in ipairs({ "GTD_TeammateTowers", "GTD_DescBox" }) do
			local old = hui:FindFirstChild(name)
			if old then
				old:Destroy()
			end
		end
	end)
	print("[隊友塔查看] 已關閉")
	return
end

if game.PlaceId == 108533757090220 then
	warn("[隊友塔查看] 只能在關卡內使用（目前在大廳）")
	return
end

-- ============================================================
-- 載入遊戲模組
-- ============================================================
-- 暫時切到 identity 2 執行 fn（部分執行器在高 identity 下 require 遊戲模組會失敗）
local function withIdentity2(fn)
	local getId = getthreadidentity or getidentity or get_thread_identity
	local setId = setthreadidentity or setidentity or set_thread_identity
	local oldId = 8
	if getId then
		local ok, id = pcall(getId)
		if ok and type(id) == "number" then
			oldId = id
		end
	end
	if setId then
		pcall(setId, 2)
	end
	local ok, res = pcall(fn)
	if setId then
		pcall(setId, oldId)
	end
	return ok and res or nil
end

-- 依路徑從 PlayerGui 往下找 ModuleScript
local function findModule(path)
	local node = LocalPlayer:WaitForChild("PlayerGui", 10)
	for _, name in ipairs(path) do
		node = node and node:WaitForChild(name, 10)
	end
	return node
end

local UnitBase = withIdentity2(function()
	return require(findModule({ "LogicHolder", "ClientLoader", "SharedConfig", "ItemData", "Units", "Behaviors", "base" }))
end)
local GameGUI = withIdentity2(function()
	return require(findModule({ "LogicHolder", "ClientLoader", "Plugins", "UserInterface", "GUI" }))
end)
local MouseTracker = withIdentity2(function()
	return require(findModule({ "LogicHolder", "ClientLoader", "Modules", "ClientInputHandler" })).MouseTracker
end)

local viewerSection = GameGUI and GameGUI.Sections and GameGUI.Sections.UnitViewer
local descSection = GameGUI and GameGUI.Sections and GameGUI.Sections.UnitCustomDescription
if type(UnitBase) ~= "table" or not viewerSection or not descSection or not MouseTracker then
	warn("[隊友塔查看] 找不到遊戲模組（不在關卡內？）")
	return
end
local viewerFrame = viewerSection.Frame

local alive = true

-- ============================================================
-- 塔效果翻譯（與「塔效果翻譯.lua」相同邏輯）
-- 說明面板顯示的是遊戲資料表中的文字，直接替換資料即可。
-- ============================================================
local TRANSLATION_URL = "https://raw.githubusercontent.com/Tseting-nil/Garden-Tower-Defense-script/refs/heads/main/Pages/%E5%A1%94%E6%95%88%E6%9E%9C%E7%BF%BB%E8%AD%AF%E8%A1%A8.lua"

-- 執行翻譯表原始碼並回傳結果表；內容無效時回傳 nil
local function runSource(src)
	if type(src) ~= "string" or src == "" then
		return nil
	end
	local ok, res = pcall(function()
		return loadstring(src)()
	end)
	if ok and type(res) == "table" and (type(res.Units) == "table" or type(res.Traits) == "table") then
		return res
	end
	return nil
end

-- 載入翻譯表：從 Gist 下載最新版
local function loadTranslation()
	local okHttp, remoteSrc = pcall(function()
		return game:HttpGet(TRANSLATION_URL)
	end)
	return okHttp and runSource(remoteSrc) or nil
end

-- 套用翻譯：替換塔 / 敵人的 CustomDescription 與詞條的 Description
local function applyTranslation()
	if getgenv().GTD_DESC_ZH_LOADED then
		return
	end
	local Translation = loadTranslation()
	if not Translation then
		warn("[隊友塔查看] 翻譯表載入失敗（無法從 Gist 下載），說明維持英文")
		return
	end
	local units, traits = Translation.Units or {}, Translation.Traits or {}
	if next(units) == nil and next(traits) == nil then
		return -- 英文：翻譯表為空，保留遊戲原文
	end
	withIdentity2(function()
		local CD = require(game:GetService("ReplicatedStorage"):WaitForChild("Others", 10):WaitForChild("CustomDescriptions", 10))
		local SID = require(findModule({ "LogicHolder", "ClientLoader", "Modules", "SharedItemData" }))

		-- 同步替換來源表 CustomDescriptions，並建立「英文原文 → 翻譯」對照，
		-- 供沒有獨立條目、但說明文字相同的單位使用
		local byText = {}
		if type(CD) == "table" then
			for id, text in pairs(units) do
				if type(CD[id]) == "string" then
					byText[CD[id]] = text
					CD[id] = text
				end
			end
		end
		-- 查找順序：自身 id → 本體（BaseUnit，變種塔用）→ 相同原文
		for _, item in pairs(SID.GetCategory("Units") or {}) do
			local p = item.Params
			local desc = p and p.CustomDescription
			if type(desc) == "string" then
				local text = units[item.ID] or (p.BaseUnit and units[p.BaseUnit]) or byText[desc]
				if text then
					p.CustomDescription = text
				end
			end
		end
		for _, item in pairs(SID.GetCategory("RollableTraits") or {}) do
			local p = item.Params
			if p and traits[item.ID] then
				p.Description = traits[item.ID]
			end
		end
	end)
	getgenv().GTD_DESC_ZH_LOADED = true
end

task.spawn(applyTranslation)

-- ============================================================
-- 塔查看器（UnitViewer）
-- ============================================================
local viewerSession = 0 -- 每次開 / 關查看器遞增，用來讓舊的隱藏迴圈自行結束

-- 查看器上的賣出 / 升級 / 目標按鈕
local function viewerButtons()
	local f = viewerFrame and viewerFrame:FindFirstChild("Frame")
	if not f then
		return {}
	end
	local left, right = f:FindFirstChild("Left"), f:FindFirstChild("Right")
	return {
		left and left:FindFirstChild("Sell"),
		right and right:FindFirstChild("Upgrade"),
		right and right:FindFirstChild("Target"),
	}
end

-- 開啟指定塔的查看器（遊戲的查看器不檢查擁有者，可直接開隊友的塔）
local function openViewer(unit)
	if not (unit and unit.ID) or unit.Destroyed then
		return
	end
	local isMine = unit.Data and unit.Data.Owner == LocalPlayer
	viewerSession = viewerSession + 1
	local session = viewerSession
	local saved = {}
	pcall(function()
		GameGUI.CloseMenu("UnitViewer")
	end)
	pcall(function()
		GameGUI.OpenMenu("UnitViewer", {
			EntityId = unit.ID,
			CallOnClose = function()
				-- 關閉時還原按鈕，避免影響之後查看自己的塔
				for btn, vis in pairs(saved) do
					btn.Visible = vis
				end
				if session == viewerSession then
					viewerSession = viewerSession + 1
				end
			end,
		})
	end)
	if isMine then
		return
	end
	-- 隊友的塔無法賣出 / 升級 / 改目標，隱藏這些按鈕。
	-- 遊戲會依等級重新顯示升級按鈕，所以查看器開啟期間持續隱藏。
	task.spawn(function()
		while session == viewerSession and viewerFrame and viewerFrame.Visible do
			for _, btn in ipairs(viewerButtons()) do
				if btn then
					if saved[btn] == nil then
						saved[btn] = btn.Visible
					end
					btn.Visible = false
				end
			end
			task.wait(0.1)
		end
	end)
end

-- ============================================================
-- 「i」按鈕 → 塔說明面板（UnitCustomDescription，同大廳卡片的 Info）
-- ============================================================
local INFO_BTN_NAME = "GTD_DescInfoButton"

-- 開啟目前查看中那座塔的說明（含詞條）
local function openDescription()
	local params = viewerSection.FrameParams
	local unit = params and params.EntityId and UnitBase.FindEntityById(params.EntityId)
	if not (unit and unit.UnitId) then
		return
	end
	pcall(function()
		descSection.Open({
			UnitId = unit.UnitId,
			RollableTraitId = unit.Data and unit.Data.RollableTraitId,
		})
	end)
end

-- 「i」按鈕放在 gethui 自己的 ScreenGui，不寫進遊戲的 PlayerGui（避免遊戲掃描到不存在的物件）。
-- 外觀複製查看器原生的「X」按鈕（同底圖 / 陰影 / 描邊 / 字型），改成藍色「i」，
-- 每幀對齊到原生「三條（Stats）」按鈕正下方；只在查看器 .Visible 時顯示。
local INFO_COLOR = Color3.fromRGB(45, 150, 245)
local INFO_STROKE = Color3.fromRGB(20, 60, 120)
local infoGui = nil
local infoConn = nil

-- 移除複製來的物件上所有 Tag / Attribute（原生按鈕帶 KeybindButton 標籤與 KeyBind 屬性，
-- 不清掉會被遊戲的快捷鍵系統綁上）
local function stripGameMarks(root)
	local CollectionService = game:GetService("CollectionService")
	local all = root:GetDescendants()
	table.insert(all, root)
	for _, inst in ipairs(all) do
		for _, tag in ipairs(CollectionService:GetTags(inst)) do
			CollectionService:RemoveTag(inst, tag)
		end
		for name in pairs(inst:GetAttributes()) do
			inst:SetAttribute(name, nil)
		end
	end
end

local function createInfoButton()
	if infoGui and infoGui.Parent then
		return
	end
	local closeBtn = viewerFrame and viewerFrame:FindFirstChild("Close")
	local statsBtn = viewerFrame and viewerFrame:FindFirstChild("Stats")
	local gameGui = viewerFrame and viewerFrame:FindFirstAncestorOfClass("ScreenGui")
	if not (closeBtn and statsBtn and gameGui) then
		return
	end

	infoGui = Instance.new("ScreenGui")
	infoGui.Name = INFO_BTN_NAME
	infoGui.ResetOnSpawn = false
	-- 與遊戲 GameGui 相同的座標設定，AbsolutePosition 才對得上
	infoGui.IgnoreGuiInset = gameGui.IgnoreGuiInset
	infoGui.ScreenInsets = gameGui.ScreenInsets
	infoGui.DisplayOrder = gameGui.DisplayOrder + 1
	infoGui.Parent = (gethui and gethui()) or game:GetService("CoreGui")

	local btn = closeBtn:Clone()
	stripGameMarks(btn)
	btn.Name = "Info"
	btn.AnchorPoint = Vector2.new(0, 0)
	btn.ImageColor3 = INFO_COLOR
	btn.Visible = false
	for _, d in ipairs(btn:GetDescendants()) do
		if d:IsA("UIAspectRatioConstraint") then
			d:Destroy() -- 尺寸改由每幀同步原生按鈕的實際大小
		elseif d:IsA("UIStroke") then
			d.Color = INFO_STROKE
		end
	end
	local title = btn:FindFirstChild("Title")
	if title then
		title.Text = "i"
	end
	btn.Parent = infoGui
	btn.MouseButton1Click:Connect(openDescription)

	-- 每幀：查看器開著才顯示，位置 = Stats 正下方（間距同 X 與 Stats 之間）
	infoConn = game:GetService("RunService").RenderStepped:Connect(function()
		local show = viewerFrame.Visible and gameGui.Enabled
		btn.Visible = show
		if not show then
			return
		end
		local sPos, sSize = statsBtn.AbsolutePosition, statsBtn.AbsoluteSize
		local gap = sPos.Y - closeBtn.AbsolutePosition.Y - closeBtn.AbsoluteSize.Y
		btn.Size = UDim2.fromOffset(sSize.X, sSize.Y)
		btn.Position = UDim2.fromOffset(sPos.X, sPos.Y + sSize.Y + gap)
	end)
end

local function removeInfoButton()
	if infoConn then
		infoConn:Disconnect()
		infoConn = nil
	end
	if infoGui then
		infoGui:Destroy()
		infoGui = nil
	end
	-- 舊版放在查看器圖片上的按鈕
	local old = viewerFrame and viewerFrame:FindFirstChild(INFO_BTN_NAME, true)
	if old then
		old:Destroy()
	end
end

-- ============================================================
-- 讓地圖上隊友的塔可以點擊
-- 遊戲在 MouseTracker 為每座塔都註冊了項目，但只有自己的塔設定 OnClick，
-- 這裡替隊友的塔補上 OnClick。項目清單取自 MouseTracker.StartTracking 的 upvalue。
-- OnClick 在遊戲執行緒（identity 2）中呼叫，權限不足，
-- 因此只記下被點的塔，交給下方背景迴圈開啟查看器。
-- ============================================================
local trackerEntries = nil
pcall(function()
	local getup = debug.getupvalues or getupvalues
	for _, v in pairs(getup(MouseTracker.StartTracking)) do
		local first = type(v) == "table" and v[1]
		if type(first) == "table" and first.object ~= nil and first.hovering ~= nil then
			trackerEntries = v
			break
		end
	end
end)
if not trackerEntries then
	warn("[隊友塔查看] 找不到滑鼠追蹤清單，地圖點擊無法啟用")
end

local patchedEntries = {} -- 已補上 OnClick 的項目（關閉時還原）
local pendingOpen = nil -- 等待開啟查看器的塔

-- 替所有隊友的塔補上點擊
local function patchTeammateClicks()
	if not trackerEntries then
		return
	end
	local ok, units = pcall(UnitBase.GetActiveUnits)
	if not ok or type(units) ~= "table" then
		return
	end
	local byObject = {}
	for _, e in ipairs(trackerEntries) do
		if e.object then
			byObject[e.object] = e
		end
	end
	for _, unit in ipairs(units) do
		local data = unit.Data
		local inst = unit.Instance
		if type(data) == "table" and data.Owner ~= LocalPlayer and typeof(inst) == "Instance" then
			local entry = byObject[inst] or byObject[inst.Parent]
			if entry and entry.OnClick == nil then
				entry.OnClick = function()
					pendingOpen = unit
				end
				patchedEntries[entry] = true
			end
		end
	end
end

-- 還原所有補上的點擊
local function unpatchTeammateClicks()
	for entry in pairs(patchedEntries) do
		entry.OnClick = nil
	end
	patchedEntries = {}
end

-- ============================================================
-- 背景迴圈：處理點擊、每秒替新放置的塔補點擊並確認「i」按鈕
-- ============================================================
task.spawn(function()
	local lastPatch = 0
	while alive do
		if pendingOpen then
			local unit = pendingOpen
			pendingOpen = nil
			openViewer(unit)
		end
		if os.clock() - lastPatch >= 1 then
			lastPatch = os.clock()
			pcall(patchTeammateClicks)
			pcall(createInfoButton)
		end
		task.wait(0.05)
	end
end)

-- 關閉函式（再次執行腳本時呼叫）
getgenv().GTD_TEAMMATE_CLEANUP = function()
	alive = false
	unpatchTeammateClicks()
	removeInfoButton()
	pcall(function()
		if viewerFrame and viewerFrame.Visible then
			GameGUI.CloseMenu("UnitViewer")
		end
	end)
end

print("[隊友塔查看] 已開啟：地圖上可點隊友的塔、查看器多了「i」說明鈕（再執行一次可關閉）")
