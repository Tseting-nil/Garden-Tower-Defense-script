repeat
	task.wait(1)
	print("等待遊戲加載中...")
until game:GetService("Players").LocalPlayer.PlayerGui.TeleportGui.Enabled == false
task.wait(1)

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")

-- === 裝置檢測 ===
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local UISizes = {
	mainFrame = isMobile and UDim2.new(0, 320, 0, 350) or UDim2.new(0, 550, 0, 480),
	mainFrameMinimized = isMobile and UDim2.new(0, 320, 0, 50) or UDim2.new(0, 550, 0, 50),
	mainFrameExpanded = isMobile and UDim2.new(0, 320, 0, 350) or UDim2.new(0, 550, 0, 450),
	parameterFrame = isMobile and UDim2.new(0, 280, 0, 350) or UDim2.new(0, 360, 0, 400),
	parameterFramePosition = isMobile and UDim2.new(0.5, -140, 0.5, -175) or UDim2.new(0.5, -180, 0.5, -200),
	saveFrame = isMobile and UDim2.new(0, 280, 0, 200) or UDim2.new(0, 350, 0, 230),
	saveFramePosition = isMobile and UDim2.new(0.5, -140, 0.5, -100) or UDim2.new(0.5, -175, 0.5, -115),
	manageFrame = isMobile and UDim2.new(0, 300, 0, 350) or UDim2.new(0, 400, 0, 450),
	manageFramePosition = isMobile and UDim2.new(0.5, -150, 0.5, -175) or UDim2.new(0.5, -200, 0.5, -225),
	abilityFrame = isMobile and UDim2.new(0, 300, 0, 400) or UDim2.new(0, 380, 0, 450),
}

-- === UI 主題 ===
local Theme = {
	Background = Color3.fromRGB(25, 27, 30),
	Surface = Color3.fromRGB(35, 38, 42),
	SurfaceHighlight = Color3.fromRGB(45, 48, 52),
	Border = Color3.fromRGB(60, 65, 70),
	Text = Color3.fromRGB(230, 230, 230),
	TextDark = Color3.fromRGB(30, 30, 30),
	TextDim = Color3.fromRGB(160, 160, 160),
	Accent = Color3.fromRGB(60, 160, 255),
	AccentHover = Color3.fromRGB(90, 180, 255),
	Success = Color3.fromRGB(100, 220, 120),
	Warning = Color3.fromRGB(255, 180, 60),
	Error = Color3.fromRGB(255, 80, 80),
	Purple = Color3.fromRGB(180, 100, 255),
	CornerRadius = UDim.new(0, 10),
	Font = Enum.Font.GothamMedium,
	FontBold = Enum.Font.GothamBold,
	SizeLarge = 24,
	SizeMedium = 16,
	SizeNormal = 16,
}

-- === 遊戲資訊 ===
local gameSettings = {
	mapId = "Unknown",
	difficulty = "Unknown",
	modifier = "None",
}

-- === 腳本設定 ===
local ScriptSettings = {
	AutoReplay = true,
	RecordSpecialMutation = false,
	CostMode = true, -- true=錄「成本版」(Add* 閘門用消耗字串、無時間)；false=時間版
}

-- === 金錢追蹤（成本版錄製用，最終對列方案）===
local CostTracker = {
	LastMoney = nil,
	Connection = nil,
	ActionQueue = {},
	CostHistory = {},
}

local function readMoneyNow()
	local ok, value = pcall(function()
		local leaderstats = Players.LocalPlayer:FindFirstChild("leaderstats")
		local cash = leaderstats and leaderstats:FindFirstChild("Cash")
		if not cash then return nil end
		-- 花園塔防的 Cash 是 StringValue，且帶千分位逗號（如 "3,936"）；
		-- 去掉非數字字元（保留負號）再轉數字。
		local raw = cash.Value
		if type(raw) == "number" then return raw end
		return tonumber((tostring(raw):gsub("[^%d%-]", "")))
	end)
	return ok and tonumber(value) or nil
end

local function handleMoneyChange()
	local currentMoney = readMoneyNow()
	if not currentMoney or not CostTracker.LastMoney then
		if currentMoney then CostTracker.LastMoney = currentMoney end
		return
	end

	local diff = currentMoney - CostTracker.LastMoney
	CostTracker.LastMoney = currentMoney

	if diff < 0 then
		local cost = math.abs(diff)
		table.insert(CostTracker.CostHistory, cost)

		if #CostTracker.ActionQueue > 0 then
			local pendingAction = table.remove(CostTracker.ActionQueue, 1)
			pendingAction.cost = cost -- 儲存 cost 給可能還沒註冊 callback 的變數
			if type(pendingAction.callback) == "function" then
				task.spawn(pendingAction.callback, cost)
			end
		end
	end
end

function CostTracker.Init()
	task.spawn(function()
		local leaderstats = Players.LocalPlayer:WaitForChild("leaderstats", 10)
		if not leaderstats then return end
		local cash = leaderstats:WaitForChild("Cash", 5)
		if not cash then return end

		CostTracker.LastMoney = readMoneyNow()
		if CostTracker.Connection then
			CostTracker.Connection:Disconnect()
		end
		CostTracker.Connection = cash:GetPropertyChangedSignal("Value"):Connect(handleMoneyChange)
	end)
end

function CostTracker.PushAction(callback)
	local actionData = {
		timestamp = os.clock(),
		callback = callback
	}
	table.insert(CostTracker.ActionQueue, actionData)
	return actionData
end

function CostTracker.CancelAction(actionData)
	for i, v in ipairs(CostTracker.ActionQueue) do
		if v == actionData then
			table.remove(CostTracker.ActionQueue, i)
			break
		end
	end
end

-- 初始化
CostTracker.Init()

-- === 腳本生成設定 ===
local timeRoundUp = false
local customComment = ""
local script_SpeedMultiplier = 1
local autoScrollEnabled = true
local SCRIPT_SAVE_PATH = "Tsetingnil_script/GTD/Script"
-- GTD 重播 API（完整.lua）的載入網址；生成的重播腳本會自動 loadstring 這個 URL。
-- 目前用本機 HTTP 伺服器（本機 RAW）測試；之後發佈再換成正式 URL。
local GTD_API_URL = "https://raw.githubusercontent.com/Tseting-nil/Garden-Tower-Defense-script/refs/heads/main/%E5%AF%86%E9%91%B0%E7%B3%BB%E7%B5%B1.lua"

-- === 語言設定 ===
local currentLang = "en"
do
	local API_VAR_PATH = "Tsetingnil_script/GTD/API_VAR.json"
	pcall(function()
		if isfile and isfile(API_VAR_PATH) and readfile then
			local raw = readfile(API_VAR_PATH)
			if raw and raw ~= "" then
				local ok, data = pcall(HttpService.JSONDecode, HttpService, raw)
				if ok and type(data) == "table" and data.language then
					local lang = tostring(data.language):upper()
					if lang == "CHINESE" then
						currentLang = "zh"
					elseif lang == "ENGLISH" then
						currentLang = "en"
					end
				end
			end
		end
	end)
end

local Lang = {
	zh = {
		titleMain = "花園塔防 | 排程追蹤器",
		titleParam = "  ⚙️ 參數設定",
		titleSave = "  💾 儲存腳本",
		titleManage = "  📁 腳本管理",
		titleAbility = "  ⚡ 塔能力控制台",
		btnCopy = "📋 複製",
		btnCopied = "✅ 已複製",
		btnSave = "💾 儲存",
		btnParam = "⚙️ 參數",
		btnRefresh = "🔄 刷新",
		btnReset = "🔄 重置追蹤器",
		btnDebug = "🔍 塔追蹤清單",
		btnAbility = "⚡ 能力",
		btnConfirmSave = "✅ 確認儲存",
		btnCancel = "❌ 取消",
		toggleOn = "開",
		toggleOff = "關",
		lblInterface = "📜 介面設定",
		lblAutoScroll = "自動捲軸",
		lblGameInfo = "ℹ️ 遊戲資訊",
		lblTrackerOp = "🛠️ 追蹤器操作",
		lblScriptParam = "📝 腳本參數",
		lblAutoReplay = "自動重播 (AutoReplay)",
		lblRecordMutation = "記錄全部突變附魔",
		lblRecordMutationDesc = "開啟後腳本將記錄塔的所有附魔/突變（停用時僅記錄閃亮塔）",
		lblCostMode = "成本版錄製（無時間）",
		lblCostModeDesc = "開啟後生成腳本用消耗($)當閘門、錢夠才動作；對收入/難度差異更穩，適合掛機重播",
		lblSkipPhase2Load = "停用 Phase2 無名後綴搜尋",
		lblSkipPhase2LoadDesc = "開啟後切到第二張圖時，無指定名稱不會自動後綴搜尋舊外部 Phase2（指定名稱仍會載入）；錄新 Phase2 時開，錄完關掉",
		lblFileName = "輸入腳本名稱:",
		phFileName = "輸入腳本名稱...",
		infoFmt = "地圖: %s\n難易度: %s\n效果: %s\n自動跳波: %s",
		lblSaveMode = "儲存模式",
		saveMerged = "合併",
		saveSeparate = "分離",
		lblPhase2Name = "指定加載名稱（前綴）",
		logNoOps = "⚠️ 沒有可生成的操作記錄",
		logSaved = "✅ 已儲存: %s",
		logSavedPhase2 = "✅ 已儲存 Phase2: %s",
		logSaveFailed = "❌ 儲存失敗: %s",
		logNoScripts = "尚無已儲存的腳本",
		logCopied = "📋 已複製: %s",
		logDeleted = "🗑️ 已刪除: %s",
		logRunPhase1 = "▶ 執行 Phase1: %s",
		logRunFailed = "❌ 執行失敗: %s",
		logCopyOk = "✅ 腳本已複製到剪貼板！",
		logCopyConsole = "⚠️ 腳本已輸出到控制台（F9查看）",
		logInvalidName = "⚠️ 請輸入有效的腳本名稱",
		logReset = "🔄 追蹤器已重置",
		logTowerListHdr = "=== 塔追蹤清單 ===",
		logNoRecord = "  (無記錄)",
		logReady = "⏳ Ready 已送出，請選擇難易度...",
		logSkipWave = "跳過關卡  +%.1fs",
		logSpeedSet = "速度設定: %dx  +%.1fs",
		logGameSetting = "設定 %s = %s  +%.1fs",
		lblGameSettings = "⚙️ 遊戲設定",
		lblAutoSkipWave = "自動跳波 (AutoSkipWave)",
		logDiffStart = "難易度選擇: %s → 開始計時",
		logDiffUpdate = "難易度更新: %s",
		logModAdd = "效果套用: %s",
		logModRemove = "效果移除: %s，當前: %s",
		logWaitReady = "⏳ 等待遊戲啟動 (GameRunning)...",
		logFlow = "📋 流程：所有地圖 = GameRunning 觸發計時開始",
		logSpecialMapReady = "🗺️ 檢測到特殊地圖 [%s]，Ready 後開始計時",
		logGameEnd = "🏁 遊戲結束  總時間: %dm %ds (%.1fs)",
		logStarted = "🎉 追蹤系統已啟動！地圖: %s  難易度: %s  效果: %s",
		logInitFailed = "❌ 追蹤系統初始化失敗（可能不在遊戲中）",
		logPlaceTower = "放置塔 #%d: %s  +%.1fs",
		logPlaceFailed = "⚠️ 放置塔失敗: %s (伺服器拒絕)",
		logUpgrade = "升級塔 #%d: %s  +%.1fs",
		logUpgradeUnknown = "升級塔 [id:%s] (未追蹤)  +%.1fs",
		logSell = "刪除塔 #%d: %s  +%.1fs",
		logSellUnknown = "刪除塔 [id:%s] (未追蹤)  +%.1fs",
		logAbility = "塔能力 #%d %s: %s  +%.1fs",
		logAbilityUnknown = "塔能力 [id:%s] %s (未追蹤)  +%.1fs",
		logTowerItem = "  #%d %s [id=%s] +%.1fs",
		abilityFmt = "能力: %s / 冷卻: %ds",
		abilityReady = "🟢 就緒",
		abilityTimerFmt = "⏳ %.0fs",
		abilityAutoLabel = "自動",
		abilityFireFmt = "⚡ %s",
		abilityWaitId = "⏳ 等待 ID",
		abilityNoTowers = "尚無擁有能力的塔",
	},
	en = {
		titleMain = "Garden Tower | Tracker",
		titleParam = "  ⚙️ Parameters",
		titleSave = "  💾 Save Script",
		titleManage = "  📁 Script Manager",
		titleAbility = "  ⚡ Tower Abilities",
		btnCopy = "📋 Copy",
		btnCopied = "✅ Copied",
		btnSave = "💾 Save",
		btnParam = "⚙️ Params",
		btnRefresh = "🔄 Refresh",
		btnReset = "🔄 Reset",
		btnDebug = "🔍 Tower List",
		btnAbility = "⚡ Ability",
		btnConfirmSave = "✅ Confirm",
		btnCancel = "❌ Cancel",
		toggleOn = "ON",
		toggleOff = "OFF",
		lblInterface = "📜 Interface",
		lblAutoScroll = "Auto Scroll",
		lblGameInfo = "ℹ️ Game Info",
		lblTrackerOp = "🛠️ Tracker Ops",
		lblScriptParam = "📝 Script Params",
		lblAutoReplay = "Auto Replay",
		lblRecordMutation = "Record All Mutations & Enchants",
		lblRecordMutationDesc = "Includes all tower enchants/mutations in scripts (Shiny is always recorded)",
		lblCostMode = "Cost-based recording (no time)",
		lblCostModeDesc = "Generated script gates by cost ($) instead of time; robust to income/difficulty differences, ideal for AFK replay",
		lblSkipPhase2Load = "Disable Phase2 suffix auto-search",
		lblSkipPhase2LoadDesc = "When on, switching to the 2nd map won't auto suffix-search an old external Phase2 unless a name is specified (named loads still work); enable while recording a new Phase2, disable after",
		lblFileName = "Script name:",
		phFileName = "Enter script name...",
		infoFmt = "Map: %s\nDifficulty: %s\nModifier: %s\nAuto Skip: %s",
		lblSaveMode = "Save Mode",
		saveMerged = "Merged",
		saveSeparate = "Separate",
		lblPhase2Name = "Phase2 Load Name (prefix)",
		logNoOps = "⚠️ No operations recorded",
		logSaved = "✅ Saved: %s",
		logSavedPhase2 = "✅ Saved Phase2: %s",
		logSaveFailed = "❌ Save failed: %s",
		logNoScripts = "No saved scripts",
		logCopied = "📋 Copied: %s",
		logDeleted = "🗑️ Deleted: %s",
		logRunPhase1 = "▶ Run Phase1: %s",
		logRunFailed = "❌ Run failed: %s",
		logCopyOk = "✅ Script copied to clipboard!",
		logCopyConsole = "⚠️ Script printed to console (F9)",
		logInvalidName = "⚠️ Please enter a valid script name",
		logReset = "🔄 Tracker reset",
		logTowerListHdr = "=== Tower List ===",
		logNoRecord = "  (empty)",
		logReady = "⏳ Ready sent, select difficulty...",
		logSkipWave = "Skip wave  +%.1fs",
		logSpeedSet = "Speed: %dx  +%.1fs",
		logGameSetting = "⚙️ Setting %s = %s  +%.1fs",
		lblGameSettings = "⚙️ Game Settings",
		lblAutoSkipWave = "Auto Skip Wave",
		logDiffStart = "Difficulty: %s → Timer started",
		logDiffUpdate = "Difficulty updated: %s",
		logModAdd = "Modifier added: %s",
		logModRemove = "Modifier removed: %s, current: %s",
		logWaitReady = "⏳ Waiting for game start (GameRunning)...",
		logFlow = "📋 Flow: All maps — timer starts when GameRunning becomes true",
		logSpecialMapReady = "🗺️ Special map detected [%s], timer starts after Ready",
		logGameEnd = "🏁 Game ended  Total: %dm %ds (%.1fs)",
		logStarted = "🎉 Tracker started! Map: %s  Difficulty: %s  Modifier: %s",
		logInitFailed = "❌ Tracker init failed (not in game?)",
		logPlaceTower = "Place #%d: %s  +%.1fs",
		logPlaceFailed = "⚠️ Place failed: %s (rejected)",
		logUpgrade = "Upgrade #%d: %s  +%.1fs",
		logUpgradeUnknown = "Upgrade [id:%s] (untracked)  +%.1fs",
		logSell = "Sell #%d: %s  +%.1fs",
		logSellUnknown = "Sell [id:%s] (untracked)  +%.1fs",
		logAbility = "Ability #%d %s: %s  +%.1fs",
		logAbilityUnknown = "Ability [id:%s] %s (untracked)  +%.1fs",
		logTowerItem = "  #%d %s [id=%s] +%.1fs",
		abilityFmt = "Ability: %s / Cooldown: %ds",
		abilityReady = "🟢 Ready",
		abilityTimerFmt = "⏳ %.0fs",
		abilityAutoLabel = "Auto",
		abilityFireFmt = "⚡ %s",
		abilityWaitId = "⏳ Waiting ID",
		abilityNoTowers = "No towers with abilities",
	},
}

local function T(key)
	return Lang[currentLang][key] or key
end

-- === i18n 綁定系統 ===
local i18nElements = {}
local i18nToggleBtns = {}
local infoLabel -- forward declaration
local AutoSkipWaveValue = nil -- forward declaration
local autoSkipState = {
	on = false,
}

local function bindText(obj, key, prop)
	prop = prop or "Text"
	obj[prop] = T(key)
	table.insert(i18nElements, {
		obj = obj,
		key = key,
		prop = prop,
	})
end

-- 即時讀取 AutoSkipWave。快取物件失效時（遊戲開局會重建 Settings 值，舊物件 Changed 不再觸發、
-- Value 停在舊值）自動依路徑重抓，避免顯示/偵測錯誤。回傳明確 boolean，修正「Value=false 時誤用 fallback」的舊 bug。
-- 花園塔防沒有 Values.Settings.AutoSkipWave；改讀遊戲內 UI 文字
-- PlayerGui.GameGuiNoInset.Screen.Top.WaveControls.AutoSkip.Title.Text = "Auto Skip: On/Off"
local function readAutoSkipWave()
	local ok, on = pcall(function()
		local pg = Players.LocalPlayer:FindFirstChild("PlayerGui")
		local node = pg and pg:FindFirstChild("GameGuiNoInset")
		for _, n in ipairs({ "Screen", "Top", "WaveControls", "AutoSkip", "Title" }) do
			node = node and node:FindFirstChild(n)
		end
		return node and node.Text and string.find(node.Text, "Auto Skip: On") ~= nil
	end)
	if ok and on ~= nil then
		return on == true
	end
	return autoSkipState.on == true
end

local function updateInfoLabel()
	if infoLabel then
		local on = readAutoSkipWave()
		local skipText = on and T("toggleOn") or T("toggleOff")
		infoLabel.Text =
			T("infoFmt"):format(gameSettings.mapId, gameSettings.difficulty, gameSettings.modifier, skipText)
	end
end

local function updateI18n()
	for _, b in ipairs(i18nElements) do
		b.obj[b.prop] = T(b.key)
	end
	for _, tb in ipairs(i18nToggleBtns) do
		local isOn = tb.getState()
		tb.btn.Text = isOn and T("toggleOn") or T("toggleOff")
		tb.btn.TextColor3 = isOn and Theme.TextDark or Theme.TextDim
	end
	updateInfoLabel()
end

-- === 追蹤狀態 — Remote 參照 ===
local PlaceTowerRemote = nil
local UpgradeTowerRemote = nil
local SellTowerRemote = nil
local SkipWaveRemote = nil
local GameSpeedRemote = nil
local GamemodeRemote = nil
local ReadyRemote = nil
local GameRunningValue = nil
local TowerAbilityRemote = nil
local ToggleSettingRemote = nil
-- 花園塔防：放置塔容器（workspace.Map.Entities），子物件帶 ID attribute = 升級/賣出用的 gameId
local EntitiesFolder = nil
-- 花園塔防：ToggleAutoUpgrade(gameId) 切換某塔的自動升級
local AutoUpgradeRemote = nil

-- === 追蹤狀態 — 操作記錄 ===
local nextOrder = 1
local orderToInfo = {}
local idToOrder = {}
local upgradeLog = {}
local sellLog = {}
local skipWaveLog = {}
local speedChangeLog = {}
local abilityLog = {}
local gameSettingLog = {}
-- 花園塔防：升級偵測改用「監看每塔 client 物件的 .Level 增量」，統一收手動+自動升級
-- （取代 UpgradeUnit/ToggleAutoUpgrade remote hook）。自動升級為伺服器端執行、client 不發 UpgradeUnit，
-- 只發一次 ToggleAutoUpgrade；但升級結果會寫回 client 塔物件的 .Level，故監看 .Level 即可一併捕捉。
local towerObjById = {}      -- gameId -> client 塔實體物件（getgc 一次性快取）
local lastLevelByOrder = {}  -- order -> 上次觀測到的等級（放置時 = 1）
local lastDetectedSpeed = 1
local towerUUIDData = {}

local gameStartAutoSkipWave = false

local function getMutLabel(uuid)
	local pdata = uuid and towerUUIDData[uuid]
	if not pdata or not pdata.mutations or not next(pdata.mutations) then
		return ""
	end
	local parts = {}
	for k, v in pairs(pdata.mutations) do
		local isShiny = (k == "Shiny")
		if isShiny or ScriptSettings.RecordSpecialMutation then
			if v == true then
				table.insert(parts, tostring(k))
			elseif type(v) == "string" and v ~= "" then
				table.insert(parts, tostring(k) .. ":" .. v)
			end
		end
	end
	return #parts > 0 and (" [" .. table.concat(parts, ", ") .. "]") or ""
end

-- === 遊戲狀態追蹤 ===
local isGameRunning = false
local gameStartTime = nil
local gameEndElapsed = nil
local gameStartMapId = nil
local mapTransitionLog = {}
local readyHooked = false
local hookTaskQueue = {}

local uiVisible = true

local function getElapsed()
	if not gameStartTime then
		return 0
	end
	return tick() - gameStartTime
end

local function startGameTimer(mapId)
	if isGameRunning then
		return false
	end
	-- 花園塔防：用 workspace.GameStartTime(Unix秒) 校準錨點，支援腳本中途載入時 elapsed 從真正開局算起
	local gst = workspace:GetAttribute("GameStartTime")
	if type(gst) == "number" and gst > 0 then
		local already = os.time() - gst
		if already < 0 then already = 0 end
		gameStartTime = tick() - already
	else
		gameStartTime = tick()
	end
	isGameRunning = true
	gameStartMapId = mapId or gameSettings.mapId
	gameStartAutoSkipWave = readAutoSkipWave()
	return true
end

local function queueHookTask(fn)
	table.insert(hookTaskQueue, fn)
end

local function flushHookTaskQueue()
	if #hookTaskQueue == 0 then
		return
	end
	local queued = hookTaskQueue
	hookTaskQueue = {}
	for _, fn in ipairs(queued) do
		local ok, err = pcall(fn)
		if not ok then
			warn("[Queued Hook Error]", err)
		end
	end
end

-- ============================================================
-- 塔能力系統 狀態
-- ============================================================
-- 花園塔防能力資料：每個 unit 剛好「一個」PlayerTriggeredAbility（Name + Cooldown 秒）。
-- 來源 PlayerGui.LogicHolder.ClientLoader.SharedConfig.ItemData.Units.Configs.<unit>.UnitConfig.PlayerTriggeredAbility，
-- 一次性 dump 內嵌於此（避免每局 require 全部 468 個單位設定造成 WSA 閃退）。
-- 可用同目錄 dump 腳本重新產生：能力資料_PlayerTriggeredAbility.lua。key = unit_id（塔 entity 名稱）。
local GTD_ABILITY_DATA = {
	unit_mango            = { Name = "Mango Barrage",           Cooldown = 60 },
	unit_timekeeper       = { Name = "Timestop",               Cooldown = 60 },
	unit_eggplantinum     = { Name = "Timestop",               Cooldown = 60 },
	unit_easter_petal     = { Name = "Timestop",               Cooldown = 120 },
	unit_birthday_cake    = { Name = "Timestop",               Cooldown = 60 },
	unit_beamstock        = { Name = "Power Up",               Cooldown = 60 },
	unit_crystal_flower   = { Name = "Power Up",               Cooldown = 90 },
	unit_starbud          = { Name = "Power Up",               Cooldown = 45, MinLevel = 5 },
	unit_mech_saw         = { Name = "Speed Up",               Cooldown = 60 },
	unit_orb_stems        = { Name = "Boosted Attacks",        Cooldown = 15 },
	unit_bunny_golem      = { Name = "Energy Release",         Cooldown = 80 },
	unit_card_shroom      = { Name = "Luck of the Draw",       Cooldown = 60 },
	unit_candy_cane       = { Name = "Summon Wall",            Cooldown = 30 },
	unit_serpent          = { Name = "Summon Wall",            Cooldown = 15 },
	unit_vine_eye         = { Name = "Vines",                  Cooldown = 105 },
	unit_volcanic_eyeball = { Name = "Break the Chains",       Cooldown = 60 },
	unit_egg_beam         = { Name = "Egg Throw",              Cooldown = 60, MinLevel = 5 },
	unit_wand_flower      = { Name = "Garden Transfiguration", Cooldown = 80 },
	unit_ice_eyeball      = { Name = "Freezing",               Cooldown = 240 },
	unit_blossom_shooter  = { Name = "Range Boost",            Cooldown = 120 },
	unit_lava_golem       = { Name = "Light Up",               Cooldown = 60 },
	unit_lava_flower      = { Name = "The Floor Is Lava",      Cooldown = 30 },
	unit_lava_shroom      = { Name = "Ash Cloud",              Cooldown = 50 },
	unit_icecream         = { Name = "The Floor Is Chocolate", Cooldown = 45 },
	unit_magnet           = { Name = "Electromagnetic Surge",  Cooldown = 30 },
	unit_laser_flower     = { Name = "Solar Flare",            Cooldown = 60 },
	unit_trident          = { Name = "Tsunami",                Cooldown = 30 },
	unit_life_crystal     = { Name = "Life Transmutation",     Cooldown = 90 },
	unit_green_lights     = { Name = "Festive Surge",          Cooldown = 45 },
	unit_hw_pepper        = { Name = "Explode",                Cooldown = 15 },
	unit_firework_billy   = { Name = "Bangsplosion",           Cooldown = 10 },
	unit_val_heart        = { Name = "Loveburst",              Cooldown = 30 },
	unit_stem_beam        = { Name = "Toggle",                 Cooldown = 3, Toggle = true },
}

-- key = unit_id（花園塔防一塔一能力）。回傳 { Name, Cooldown }。
local function getAbiData(key)
	local d = GTD_ABILITY_DATA[key]
	if d then
		return { Name = d.Name, Cooldown = d.Cooldown }
	end
	return {
		Name = key,
		Cooldown = 30,
	}
end

local towersWithAbility = {} -- { [towerName] = abilityKeys[] }

local abiNextOrder = 1
local abiLiveTowers = {} -- [model] = { name, order, abilityKeys, gameId, cooldowns, savedAutoStates }
local abiTowerCards = {} -- [model] = { container, widgets[] }
local abiModelByGameId = {} -- [gameId] = model
local abiPendingGameIds = {} -- { name, gameId, time }[]
local abiGameIdCooldownHint = {} -- [gameId][abilityKey] = abiGameClock（遊戲時間戳）
local abiEmptyLabel = nil
local abiRemoteInFlight = {} -- [gameId:abilityKey] = true

-- 遊戲時間時鐘：每幀累加 dt × 當前遊戲速度。能力冷卻是用「遊戲時間」算的，
-- x2/x3 速度下時鐘走得快 → 冷卻較快就緒。所有冷卻時間戳一律用這個時鐘（而非真實 tick()）。
local abiGameClock = 0

-- Forward declaration：在 langBtn / stopAbilityRemoteTriggers 中被呼叫
local rebuildAllAbilityCards

local function getAbilityRemaining(info, abilityKey, cooldown)
	local t0 = info and info.cooldowns and info.cooldowns[abilityKey]
	if not t0 then
		return 0
	end
	-- 以遊戲時間計：abiGameClock 已含速度倍率，x2/x3 時 elapsed 累積較快
	return math.max(0, cooldown - (abiGameClock - t0))
end

local function invokeTowerAbilitySafely(model, abilityKey, cooldown)
	if not isGameRunning or not TowerAbilityRemote then
		return false
	end

	local info = abiLiveTowers[model]
	if not info or not info.gameId then
		return false
	end
	if getAbilityRemaining(info, abilityKey, cooldown) > 0 then
		return false
	end

	local invokeKey = tostring(info.gameId) .. ":" .. tostring(abilityKey)
	if abiRemoteInFlight[invokeKey] then
		return false
	end

	local gid = info.gameId
	abiRemoteInFlight[invokeKey] = true
	info.cooldowns[abilityKey] = abiGameClock

	task.spawn(function()
		local ok, res = pcall(function()
			-- 花園塔防：ActivateUnitAbility 與 UpgradeUnit/SellUnit/ToggleAutoUpgrade 同模式，只傳 gameId（數字）。
			-- abilityKey 僅用於本地冷卻記帳，不送伺服器（一塔一能力）。
			return TowerAbilityRemote:InvokeServer(gid)
		end)
		abiRemoteInFlight[invokeKey] = nil
	end)

	return true
end

local function stopAbilityRemoteTriggers()
	abiRemoteInFlight = {}
	abiPendingGameIds = {}
	abiGameIdCooldownHint = {}
	abiModelByGameId = {}

	for _, info in pairs(abiLiveTowers) do
		info.gameId = nil
		info.cooldowns = {}
	end

	if rebuildAllAbilityCards then
		rebuildAllAbilityCards()
	end
end

-- ============================================================
-- UI 建立
-- ============================================================
local guiParent = get_hidden_gui or gethui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "GTDTrackerUI"
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = false
screenGui.Parent = guiParent and guiParent() or game:GetService("CoreGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UISizes.mainFrame
mainFrame.Position = UDim2.new(0.2, 0, 0.2, 0)
mainFrame.BackgroundColor3 = Theme.Background
mainFrame.BackgroundTransparency = 0.05
mainFrame.Active = true
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
mainFrame.Parent = screenGui

do
	local c = Instance.new("UICorner")
	c.CornerRadius = Theme.CornerRadius
	c.Parent = mainFrame
end
do
	local s = Instance.new("UIStroke")
	s.Thickness = 1.5
	s.Color = Theme.Border
	s.Transparency = 0.2
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = mainFrame
end

-- 標題欄
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 45)
titleBar.BackgroundColor3 = Theme.Surface
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame
titleBar.Name = "TitleBar"
do
	local c = Instance.new("UICorner")
	c.CornerRadius = Theme.CornerRadius
	c.Parent = titleBar
end

local titleBarCover = Instance.new("Frame")
titleBarCover.Size = UDim2.new(1, 0, 0, 10)
titleBarCover.Position = UDim2.new(0, 0, 1, -10)
titleBarCover.BackgroundColor3 = Theme.Surface
titleBarCover.BorderSizePixel = 0
titleBarCover.Parent = titleBar

local titleSeparator = Instance.new("Frame")
titleSeparator.Size = UDim2.new(1, 0, 0, 1)
titleSeparator.Position = UDim2.new(0, 0, 1, -1)
titleSeparator.BackgroundColor3 = Theme.Border
titleSeparator.BorderSizePixel = 0
titleSeparator.Parent = titleBar

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -90, 1, 0)
title.BackgroundTransparency = 1
title.TextColor3 = Theme.Accent
title.Font = Theme.FontBold
title.TextSize = Theme.SizeLarge
title.TextXAlignment = Enum.TextXAlignment.Left
title.Position = UDim2.new(0, 10, 0, 0)
title.Parent = titleBar
bindText(title, "titleMain")

local langBtn = Instance.new("TextButton")
langBtn.Size = UDim2.new(0, 35, 0, 35)
langBtn.Position = UDim2.new(1, -80, 0, 5)
langBtn.Text = currentLang == "zh" and "EN" or "中"
langBtn.BackgroundColor3 = Theme.SurfaceHighlight
langBtn.TextColor3 = Theme.Accent
langBtn.Font = Theme.FontBold
langBtn.TextSize = 13
langBtn.BorderSizePixel = 0
langBtn.Parent = titleBar
do
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 8)
	c.Parent = langBtn
end

langBtn.MouseButton1Click:Connect(function()
	if currentLang == "zh" then
		currentLang = "en"
		langBtn.Text = "中"
	else
		currentLang = "zh"
		langBtn.Text = "EN"
	end
	updateI18n()
	task.spawn(function()
		rebuildAllAbilityCards()
	end)
end)

local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Size = UDim2.new(0, 35, 0, 35)
minimizeBtn.Position = UDim2.new(1, -40, 0, 5)
minimizeBtn.Text = "—"
minimizeBtn.BackgroundColor3 = Theme.SurfaceHighlight
minimizeBtn.TextColor3 = Theme.Text
minimizeBtn.Font = Theme.FontBold
minimizeBtn.TextSize = 22
minimizeBtn.BorderSizePixel = 0
minimizeBtn.Parent = titleBar
do
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 8)
	c.Parent = minimizeBtn
end

-- 滾動框架
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, -20, 1, -100)
scrollFrame.Position = UDim2.new(0, 10, 0, 50)
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.ScrollBarThickness = 4
scrollFrame.BackgroundTransparency = 1
scrollFrame.ScrollBarImageColor3 = Theme.Border
scrollFrame.Parent = mainFrame

local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 8)
listLayout.Parent = scrollFrame

listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
end)

task.spawn(function()
	while true do
		task.wait(0.1)
		if scrollFrame and autoScrollEnabled then
			pcall(function()
				scrollFrame.CanvasPosition = Vector2.new(0, scrollFrame.CanvasSize.Y.Offset)
			end)
		end
	end
end)

-- 按鈕列
local buttonContainer = Instance.new("Frame")
buttonContainer.Size = UDim2.new(1, -20, 0, 40)
buttonContainer.Position = UDim2.new(0, 10, 1, -45)
buttonContainer.BackgroundTransparency = 1
buttonContainer.Parent = mainFrame

local buttonLayout = Instance.new("UIListLayout")
buttonLayout.FillDirection = Enum.FillDirection.Horizontal
buttonLayout.SortOrder = Enum.SortOrder.LayoutOrder
buttonLayout.Padding = UDim.new(0, 6)
buttonLayout.Parent = buttonContainer

local function makeBtn(textKey, bgColor, txtColor, order, widthScale)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(widthScale or 0.25, -5, 1, 0)
	btn.BackgroundColor3 = bgColor
	btn.TextColor3 = txtColor
	btn.Font = Theme.FontBold
	btn.TextSize = Theme.SizeMedium
	btn.BorderSizePixel = 0
	btn.LayoutOrder = order
	btn.Parent = buttonContainer
	local c = Instance.new("UICorner")
	c.CornerRadius = Theme.CornerRadius
	c.Parent = btn
	bindText(btn, textKey)
	return btn
end

local copyBtn = makeBtn("btnCopy", Theme.Success, Theme.TextDark, 1, 0.25)
local saveBtn = makeBtn("btnSave", Theme.Accent, Theme.Text, 2, 0.25)
local Parameter = makeBtn("btnParam", Theme.SurfaceHighlight, Theme.Text, 3, 0.25)
local abilityBtn = makeBtn("btnAbility", Theme.Purple, Theme.Text, 4, 0.25)

local resetBtn
local debugBtn

-- ============================================================
-- addLog 函數
-- ============================================================
local logOrder = 1

local function addLog(text, color)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -10, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = color or Theme.Text
	label.Font = Theme.Font
	label.TextSize = 14
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextWrapped = true
	label.AutomaticSize = Enum.AutomaticSize.Y
	label.LayoutOrder = logOrder
	label.Parent = scrollFrame
	logOrder = logOrder + 1
end

-- ============================================================
-- 參數面板 UI
-- ============================================================
local parameterFrame = Instance.new("Frame")
parameterFrame.Size = UISizes.parameterFrame
parameterFrame.Position = UISizes.parameterFramePosition
parameterFrame.BackgroundColor3 = Theme.Background
parameterFrame.BackgroundTransparency = 0.05
parameterFrame.Active = true
parameterFrame.BorderSizePixel = 0
parameterFrame.ClipsDescendants = true
parameterFrame.Visible = false
parameterFrame.ZIndex = 10
parameterFrame.Parent = screenGui
do
	local c = Instance.new("UICorner")
	c.CornerRadius = Theme.CornerRadius
	c.Parent = parameterFrame
end
do
	local s = Instance.new("UIStroke")
	s.Thickness = 1.5
	s.Color = Theme.Border
	s.Transparency = 0.2
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = parameterFrame
end

local paramTitleBar = Instance.new("Frame")
paramTitleBar.Size = UDim2.new(1, 0, 0, 45)
paramTitleBar.BackgroundColor3 = Theme.Surface
paramTitleBar.BorderSizePixel = 0
paramTitleBar.ZIndex = 11
paramTitleBar.Parent = parameterFrame
do
	local c = Instance.new("UICorner")
	c.CornerRadius = Theme.CornerRadius
	c.Parent = paramTitleBar
end
do
	local f = Instance.new("Frame")
	f.Size = UDim2.new(1, 0, 0, 10)
	f.Position = UDim2.new(0, 0, 1, -10)
	f.BackgroundColor3 = Theme.Surface
	f.BorderSizePixel = 0
	f.ZIndex = 11
	f.Parent = paramTitleBar
end

local paramTitle = Instance.new("TextLabel")
paramTitle.Size = UDim2.new(0.8, 0, 1, 0)
paramTitle.BackgroundTransparency = 1
paramTitle.TextColor3 = Theme.Text
paramTitle.Font = Theme.FontBold
paramTitle.TextSize = Theme.SizeLarge
paramTitle.TextXAlignment = Enum.TextXAlignment.Left
paramTitle.ZIndex = 12
paramTitle.Parent = paramTitleBar
bindText(paramTitle, "titleParam")

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 35, 0, 35)
closeBtn.Position = UDim2.new(1, -40, 0, 5)
closeBtn.Text = "×"
closeBtn.BackgroundColor3 = Theme.Error
closeBtn.TextColor3 = Theme.Text
closeBtn.Font = Theme.FontBold
closeBtn.TextSize = 24
closeBtn.BorderSizePixel = 0
closeBtn.ZIndex = 12
closeBtn.Parent = paramTitleBar
do
	local c = Instance.new("UICorner")
	c.CornerRadius = Theme.CornerRadius
	c.Parent = closeBtn
end

local paramScrollFrame = Instance.new("ScrollingFrame")
paramScrollFrame.Size = UDim2.new(1, -20, 1, -55)
paramScrollFrame.Position = UDim2.new(0, 10, 0, 50)
paramScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
paramScrollFrame.ScrollBarThickness = 4
paramScrollFrame.BackgroundTransparency = 1
paramScrollFrame.ZIndex = 11
paramScrollFrame.Parent = parameterFrame

local paramListLayout = Instance.new("UIListLayout")
paramListLayout.SortOrder = Enum.SortOrder.LayoutOrder
paramListLayout.Padding = UDim.new(0, 8)
paramListLayout.Parent = paramScrollFrame

paramListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	paramScrollFrame.CanvasSize = UDim2.new(0, 0, 0, paramListLayout.AbsoluteContentSize.Y + 10)
end)

-- ============================================================
-- 儲存面板 UI
-- ============================================================
local saveFrame = Instance.new("Frame")
saveFrame.Size = UISizes.saveFrame
saveFrame.Position = UISizes.saveFramePosition
saveFrame.BackgroundColor3 = Theme.Background
saveFrame.BackgroundTransparency = 0.05
saveFrame.Active = true
saveFrame.BorderSizePixel = 0
saveFrame.ClipsDescendants = true
saveFrame.Visible = false
saveFrame.ZIndex = 10
saveFrame.Parent = screenGui
do
	local c = Instance.new("UICorner")
	c.CornerRadius = Theme.CornerRadius
	c.Parent = saveFrame
end
do
	local s = Instance.new("UIStroke")
	s.Thickness = 1.5
	s.Color = Theme.Border
	s.Transparency = 0.2
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = saveFrame
end

local saveTitleBar = Instance.new("Frame")
saveTitleBar.Size = UDim2.new(1, 0, 0, 45)
saveTitleBar.BackgroundColor3 = Theme.Surface
saveTitleBar.BorderSizePixel = 0
saveTitleBar.ZIndex = 11
saveTitleBar.Parent = saveFrame
do
	local c = Instance.new("UICorner")
	c.CornerRadius = Theme.CornerRadius
	c.Parent = saveTitleBar
end
do
	local f = Instance.new("Frame")
	f.Size = UDim2.new(1, 0, 0, 10)
	f.Position = UDim2.new(0, 0, 1, -10)
	f.BackgroundColor3 = Theme.Surface
	f.BorderSizePixel = 0
	f.ZIndex = 11
	f.Parent = saveTitleBar
end

local saveTitle = Instance.new("TextLabel")
saveTitle.Size = UDim2.new(0.8, 0, 1, 0)
saveTitle.BackgroundTransparency = 1
saveTitle.TextColor3 = Theme.Text
saveTitle.Font = Theme.FontBold
saveTitle.TextSize = Theme.SizeLarge
saveTitle.TextXAlignment = Enum.TextXAlignment.Left
saveTitle.ZIndex = 12
saveTitle.Parent = saveTitleBar
bindText(saveTitle, "titleSave")

local saveCloseBtn = Instance.new("TextButton")
saveCloseBtn.Size = UDim2.new(0, 35, 0, 35)
saveCloseBtn.Position = UDim2.new(1, -40, 0, 5)
saveCloseBtn.Text = "×"
saveCloseBtn.BackgroundColor3 = Theme.Error
saveCloseBtn.TextColor3 = Theme.Text
saveCloseBtn.Font = Theme.FontBold
saveCloseBtn.TextSize = 24
saveCloseBtn.BorderSizePixel = 0
saveCloseBtn.ZIndex = 12
saveCloseBtn.Parent = saveTitleBar
do
	local c = Instance.new("UICorner")
	c.CornerRadius = Theme.CornerRadius
	c.Parent = saveCloseBtn
end

local fileNameLabel = Instance.new("TextLabel")
fileNameLabel.Size = UDim2.new(1, -20, 0, 20)
fileNameLabel.Position = UDim2.new(0, 10, 0, 55)
fileNameLabel.BackgroundTransparency = 1
fileNameLabel.TextColor3 = Theme.TextDim
fileNameLabel.Font = Theme.Font
fileNameLabel.TextSize = Theme.SizeNormal
fileNameLabel.TextXAlignment = Enum.TextXAlignment.Left
fileNameLabel.ZIndex = 12
fileNameLabel.Parent = saveFrame
bindText(fileNameLabel, "lblFileName")

local fileNameInput = Instance.new("TextBox")
fileNameInput.Size = UDim2.new(1, -20, 0, 35)
fileNameInput.Position = UDim2.new(0, 10, 0, 80)
fileNameInput.BackgroundColor3 = Theme.SurfaceHighlight
fileNameInput.PlaceholderColor3 = Theme.TextDim
fileNameInput.Text = ""
fileNameInput.TextColor3 = Theme.Text
fileNameInput.Font = Theme.Font
fileNameInput.TextSize = Theme.SizeNormal
fileNameInput.BorderSizePixel = 0
fileNameInput.ClearTextOnFocus = false
fileNameInput.ZIndex = 12
fileNameInput.Parent = saveFrame
do
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 6)
	c.Parent = fileNameInput
end
bindText(fileNameInput, "phFileName", "PlaceholderText")

-- 指定加載名稱（前綴）：僅雙地圖 + 分離模式顯示；生成的 Phase1 用它 AddMapWait("<前綴>")
local phase2NameLabel = Instance.new("TextLabel")
phase2NameLabel.Size = UDim2.new(1, -20, 0, 20)
phase2NameLabel.Position = UDim2.new(0, 10, 0, 158)
phase2NameLabel.BackgroundTransparency = 1
phase2NameLabel.TextColor3 = Theme.TextDim
phase2NameLabel.Font = Theme.Font
phase2NameLabel.TextSize = Theme.SizeNormal
phase2NameLabel.TextXAlignment = Enum.TextXAlignment.Left
phase2NameLabel.Visible = false
phase2NameLabel.ZIndex = 12
phase2NameLabel.Parent = saveFrame
bindText(phase2NameLabel, "lblPhase2Name")

local phase2NameInput = Instance.new("TextBox")
phase2NameInput.Size = UDim2.new(1, -20, 0, 32)
phase2NameInput.Position = UDim2.new(0, 10, 0, 180)
phase2NameInput.BackgroundColor3 = Theme.SurfaceHighlight
phase2NameInput.PlaceholderColor3 = Theme.TextDim
phase2NameInput.Text = ""
phase2NameInput.TextColor3 = Theme.Text
phase2NameInput.Font = Theme.Font
phase2NameInput.TextSize = Theme.SizeNormal
phase2NameInput.BorderSizePixel = 0
phase2NameInput.ClearTextOnFocus = false
phase2NameInput.Visible = false
phase2NameInput.ZIndex = 12
phase2NameInput.Parent = saveFrame
do
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 6)
	c.Parent = phase2NameInput
end

local saveModeRow = Instance.new("Frame")
saveModeRow.Size = UDim2.new(1, -20, 0, 28)
saveModeRow.Position = UDim2.new(0, 10, 0, 122)
saveModeRow.BackgroundTransparency = 1
saveModeRow.Visible = false
saveModeRow.ZIndex = 12
saveModeRow.Parent = saveFrame

local saveModeLbl = Instance.new("TextLabel")
saveModeLbl.Size = UDim2.new(0.45, 0, 1, 0)
saveModeLbl.BackgroundTransparency = 1
saveModeLbl.TextColor3 = Theme.TextDim
saveModeLbl.Font = Theme.Font
saveModeLbl.TextSize = Theme.SizeNormal
saveModeLbl.TextXAlignment = Enum.TextXAlignment.Left
saveModeLbl.ZIndex = 13
saveModeLbl.Parent = saveModeRow
bindText(saveModeLbl, "lblSaveMode")

local saveMergedBtn = Instance.new("TextButton")
saveMergedBtn.Size = UDim2.new(0.25, -4, 1, 0)
saveMergedBtn.Position = UDim2.new(0.45, 0, 0, 0)
saveMergedBtn.BackgroundColor3 = Theme.Accent
saveMergedBtn.TextColor3 = Theme.Text
saveMergedBtn.Font = Theme.FontBold
saveMergedBtn.TextSize = 14
saveMergedBtn.BorderSizePixel = 0
saveMergedBtn.ZIndex = 13
saveMergedBtn.Parent = saveModeRow
do
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 6)
	c.Parent = saveMergedBtn
end
bindText(saveMergedBtn, "saveMerged")

local saveSeparateBtn = Instance.new("TextButton")
saveSeparateBtn.Size = UDim2.new(0.28, -4, 1, 0)
saveSeparateBtn.Position = UDim2.new(0.72, 0, 0, 0)
saveSeparateBtn.BackgroundColor3 = Theme.SurfaceHighlight
saveSeparateBtn.TextColor3 = Theme.TextDim
saveSeparateBtn.Font = Theme.FontBold
saveSeparateBtn.TextSize = 14
saveSeparateBtn.BorderSizePixel = 0
saveSeparateBtn.ZIndex = 13
saveSeparateBtn.Parent = saveModeRow
do
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 6)
	c.Parent = saveSeparateBtn
end
bindText(saveSeparateBtn, "saveSeparate")

local currentSaveMode = "merged"
local relayoutSavePanel -- forward declaration（在 saveBtnContainer 建立後賦值）

local function updateSaveModeButtons()
	if currentSaveMode == "merged" then
		saveMergedBtn.BackgroundColor3 = Theme.Accent
		saveMergedBtn.TextColor3 = Theme.Text
		saveSeparateBtn.BackgroundColor3 = Theme.SurfaceHighlight
		saveSeparateBtn.TextColor3 = Theme.TextDim
	else
		saveMergedBtn.BackgroundColor3 = Theme.SurfaceHighlight
		saveMergedBtn.TextColor3 = Theme.TextDim
		saveSeparateBtn.BackgroundColor3 = Theme.Accent
		saveSeparateBtn.TextColor3 = Theme.Text
	end
end

saveMergedBtn.MouseButton1Click:Connect(function()
	currentSaveMode = "merged"
	updateSaveModeButtons()
	if relayoutSavePanel then relayoutSavePanel() end
end)
saveSeparateBtn.MouseButton1Click:Connect(function()
	currentSaveMode = "separate"
	updateSaveModeButtons()
	if relayoutSavePanel then relayoutSavePanel() end
end)

local saveBtnContainer = Instance.new("Frame")
saveBtnContainer.Size = UDim2.new(1, -20, 0, 40)
saveBtnContainer.Position = UDim2.new(0, 10, 0, 130)
saveBtnContainer.BackgroundTransparency = 1
saveBtnContainer.ZIndex = 12
saveBtnContainer.Parent = saveFrame
do
	local l = Instance.new("UIListLayout")
	l.FillDirection = Enum.FillDirection.Horizontal
	l.Padding = UDim.new(0, 10)
	l.Parent = saveBtnContainer
end

-- 依「是否雙地圖 / 合併或分離」重新排版存檔面板，並調整面板高度
relayoutSavePanel = function()
	local hasTransition = mapTransitionLog[1] ~= nil
	saveModeRow.Visible = hasTransition
	local showPhase2 = hasTransition and currentSaveMode == "separate"
	phase2NameLabel.Visible = showPhase2
	phase2NameInput.Visible = showPhase2

	local y = 122
	if hasTransition then
		saveModeRow.Position = UDim2.new(0, 10, 0, y)
		y = y + 36
	end
	if showPhase2 then
		phase2NameLabel.Position = UDim2.new(0, 10, 0, y)
		phase2NameInput.Position = UDim2.new(0, 10, 0, y + 22)
		y = y + 22 + 32 + 12
	end
	saveBtnContainer.Position = UDim2.new(0, 10, 0, y)
	local wx = UISizes.saveFrame.X
	saveFrame.Size = UDim2.new(wx.Scale, wx.Offset, 0, y + 55)
end

local confirmSaveBtn = Instance.new("TextButton")
confirmSaveBtn.Size = UDim2.new(0.5, -5, 1, 0)
confirmSaveBtn.BackgroundColor3 = Theme.Success
confirmSaveBtn.TextColor3 = Theme.TextDark
confirmSaveBtn.Font = Theme.FontBold
confirmSaveBtn.TextSize = Theme.SizeNormal
confirmSaveBtn.BorderSizePixel = 0
confirmSaveBtn.LayoutOrder = 1
confirmSaveBtn.ZIndex = 12
confirmSaveBtn.Parent = saveBtnContainer
do
	local c = Instance.new("UICorner")
	c.CornerRadius = Theme.CornerRadius
	c.Parent = confirmSaveBtn
end
bindText(confirmSaveBtn, "btnConfirmSave")

local cancelSaveBtn = Instance.new("TextButton")
cancelSaveBtn.Size = UDim2.new(0.5, -5, 1, 0)
cancelSaveBtn.BackgroundColor3 = Theme.SurfaceHighlight
cancelSaveBtn.TextColor3 = Theme.Text
cancelSaveBtn.Font = Theme.FontBold
cancelSaveBtn.TextSize = Theme.SizeNormal
cancelSaveBtn.BorderSizePixel = 0
cancelSaveBtn.LayoutOrder = 2
cancelSaveBtn.ZIndex = 12
cancelSaveBtn.Parent = saveBtnContainer
do
	local c = Instance.new("UICorner")
	c.CornerRadius = Theme.CornerRadius
	c.Parent = cancelSaveBtn
end
bindText(cancelSaveBtn, "btnCancel")

-- ============================================================
-- 腳本管理面板
-- ============================================================
local refreshScriptList

local manageFrame = Instance.new("Frame")
manageFrame.Size = UISizes.manageFrame
manageFrame.Position = UISizes.manageFramePosition
manageFrame.BackgroundColor3 = Theme.Background
manageFrame.BackgroundTransparency = 0.05
manageFrame.Active = true
manageFrame.BorderSizePixel = 0
manageFrame.ClipsDescendants = true
manageFrame.Visible = false
manageFrame.ZIndex = 10
manageFrame.Parent = screenGui
do
	local c = Instance.new("UICorner")
	c.CornerRadius = Theme.CornerRadius
	c.Parent = manageFrame
end
do
	local s = Instance.new("UIStroke")
	s.Thickness = 1.5
	s.Color = Theme.Border
	s.Transparency = 0.2
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = manageFrame
end

local manageTitleBar = Instance.new("Frame")
manageTitleBar.Size = UDim2.new(1, 0, 0, 45)
manageTitleBar.BackgroundColor3 = Theme.Surface
manageTitleBar.BorderSizePixel = 0
manageTitleBar.ZIndex = 11
manageTitleBar.Parent = manageFrame
do
	local c = Instance.new("UICorner")
	c.CornerRadius = Theme.CornerRadius
	c.Parent = manageTitleBar
end
do
	local f = Instance.new("Frame")
	f.Size = UDim2.new(1, 0, 0, 10)
	f.Position = UDim2.new(0, 0, 1, -10)
	f.BackgroundColor3 = Theme.Surface
	f.BorderSizePixel = 0
	f.ZIndex = 11
	f.Parent = manageTitleBar
end

local manageTitle = Instance.new("TextLabel")
manageTitle.Size = UDim2.new(0.6, 0, 1, 0)
manageTitle.BackgroundTransparency = 1
manageTitle.TextColor3 = Theme.Text
manageTitle.Font = Theme.FontBold
manageTitle.TextSize = Theme.SizeLarge
manageTitle.TextXAlignment = Enum.TextXAlignment.Left
manageTitle.ZIndex = 12
manageTitle.Parent = manageTitleBar
bindText(manageTitle, "titleManage")

local refreshScriptsBtn = Instance.new("TextButton")
refreshScriptsBtn.Size = UDim2.new(0, 80, 0, 30)
refreshScriptsBtn.Position = UDim2.new(1, -125, 0, 7)
refreshScriptsBtn.BackgroundColor3 = Theme.Accent
refreshScriptsBtn.TextColor3 = Theme.Text
refreshScriptsBtn.Font = Theme.Font
refreshScriptsBtn.TextSize = 14
refreshScriptsBtn.BorderSizePixel = 0
refreshScriptsBtn.ZIndex = 12
refreshScriptsBtn.Parent = manageTitleBar
do
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 6)
	c.Parent = refreshScriptsBtn
end
bindText(refreshScriptsBtn, "btnRefresh")

local manageCloseBtn = Instance.new("TextButton")
manageCloseBtn.Size = UDim2.new(0, 35, 0, 35)
manageCloseBtn.Position = UDim2.new(1, -40, 0, 5)
manageCloseBtn.Text = "×"
manageCloseBtn.BackgroundColor3 = Theme.Error
manageCloseBtn.TextColor3 = Theme.Text
manageCloseBtn.Font = Theme.FontBold
manageCloseBtn.TextSize = 24
manageCloseBtn.BorderSizePixel = 0
manageCloseBtn.ZIndex = 12
manageCloseBtn.Parent = manageTitleBar
do
	local c = Instance.new("UICorner")
	c.CornerRadius = Theme.CornerRadius
	c.Parent = manageCloseBtn
end

local manageScrollFrame = Instance.new("ScrollingFrame")
manageScrollFrame.Size = UDim2.new(1, -20, 1, -55)
manageScrollFrame.Position = UDim2.new(0, 10, 0, 50)
manageScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
manageScrollFrame.ScrollBarThickness = 4
manageScrollFrame.BackgroundTransparency = 1
manageScrollFrame.ZIndex = 11
manageScrollFrame.Parent = manageFrame

local manageListLayout = Instance.new("UIListLayout")
manageListLayout.SortOrder = Enum.SortOrder.LayoutOrder
manageListLayout.Padding = UDim.new(0, 6)
manageListLayout.Parent = manageScrollFrame

manageListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	manageScrollFrame.CanvasSize = UDim2.new(0, 0, 0, manageListLayout.AbsoluteContentSize.Y + 10)
end)

-- ============================================================
-- 塔能力面板 UI
-- ============================================================
local abilityFrame = Instance.new("Frame")
abilityFrame.Size = UISizes.abilityFrame
abilityFrame.Position = UDim2.new(0.5, 0, 0.5, -200)
abilityFrame.BackgroundColor3 = Theme.Background
abilityFrame.BackgroundTransparency = 0.05
abilityFrame.Active = true
abilityFrame.BorderSizePixel = 0
abilityFrame.ClipsDescendants = true
abilityFrame.Visible = false
abilityFrame.ZIndex = 10
abilityFrame.Parent = screenGui
do
	local c = Instance.new("UICorner")
	c.CornerRadius = Theme.CornerRadius
	c.Parent = abilityFrame
end
do
	local s = Instance.new("UIStroke")
	s.Thickness = 1.5
	s.Color = Theme.Border
	s.Transparency = 0.2
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = abilityFrame
end

local abilityTitleBar = Instance.new("Frame")
abilityTitleBar.Size = UDim2.new(1, 0, 0, 45)
abilityTitleBar.BackgroundColor3 = Theme.Surface
abilityTitleBar.BorderSizePixel = 0
abilityTitleBar.ZIndex = 11
abilityTitleBar.Parent = abilityFrame
do
	local c = Instance.new("UICorner")
	c.CornerRadius = Theme.CornerRadius
	c.Parent = abilityTitleBar
end
do
	local f = Instance.new("Frame")
	f.Size = UDim2.new(1, 0, 0, 10)
	f.Position = UDim2.new(0, 0, 1, -10)
	f.BackgroundColor3 = Theme.Surface
	f.BorderSizePixel = 0
	f.ZIndex = 11
	f.Parent = abilityTitleBar
end

local abilityTitle = Instance.new("TextLabel")
abilityTitle.Size = UDim2.new(0.8, 0, 1, 0)
abilityTitle.BackgroundTransparency = 1
abilityTitle.TextColor3 = Theme.Purple
abilityTitle.Font = Theme.FontBold
abilityTitle.TextSize = Theme.SizeLarge
abilityTitle.TextXAlignment = Enum.TextXAlignment.Left
abilityTitle.ZIndex = 12
abilityTitle.Parent = abilityTitleBar
bindText(abilityTitle, "titleAbility")

local abilityCloseBtn = Instance.new("TextButton")
abilityCloseBtn.Size = UDim2.new(0, 35, 0, 35)
abilityCloseBtn.Position = UDim2.new(1, -40, 0, 5)
abilityCloseBtn.Text = "×"
abilityCloseBtn.BackgroundColor3 = Theme.Error
abilityCloseBtn.TextColor3 = Theme.Text
abilityCloseBtn.Font = Theme.FontBold
abilityCloseBtn.TextSize = 24
abilityCloseBtn.BorderSizePixel = 0
abilityCloseBtn.ZIndex = 12
abilityCloseBtn.Parent = abilityTitleBar
do
	local c = Instance.new("UICorner")
	c.CornerRadius = Theme.CornerRadius
	c.Parent = abilityCloseBtn
end

local abilityScrollFrame = Instance.new("ScrollingFrame")
abilityScrollFrame.Size = UDim2.new(1, -20, 1, -55)
abilityScrollFrame.Position = UDim2.new(0, 10, 0, 50)
abilityScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
abilityScrollFrame.ScrollBarThickness = 4
abilityScrollFrame.BackgroundTransparency = 1
abilityScrollFrame.ScrollBarImageColor3 = Theme.Border
abilityScrollFrame.ZIndex = 11
abilityScrollFrame.Parent = abilityFrame

local abilityListLayout = Instance.new("UIListLayout")
abilityListLayout.SortOrder = Enum.SortOrder.LayoutOrder
abilityListLayout.Padding = UDim.new(0, 8)
abilityListLayout.Parent = abilityScrollFrame

abilityListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	abilityScrollFrame.CanvasSize = UDim2.new(0, 0, 0, abilityListLayout.AbsoluteContentSize.Y + 10)
end)

-- ============================================================
-- 參數面板 Helper 函數
-- ============================================================
local function createLabel(key, parent, order)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 25)
	label.BackgroundTransparency = 1
	label.TextColor3 = Theme.TextDim
	label.Font = Theme.FontBold
	label.TextSize = Theme.SizeNormal
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.LayoutOrder = order
	label.ZIndex = 13
	label.Parent = parent
	bindText(label, key)
	return label
end

local function createToggle(labelKey, parent, order, defaultValue, callback, descKey)
	local frameH = descKey and 65 or 40
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 0, frameH)
	frame.BackgroundTransparency = 1
	frame.LayoutOrder = order
	frame.ZIndex = 12
	frame.Parent = parent

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(0.75, 0, 0, 40)
	lbl.Position = UDim2.new(0, 0, 0, 0)
	lbl.BackgroundTransparency = 1
	lbl.TextColor3 = Theme.Text
	lbl.Font = Theme.Font
	lbl.TextSize = Theme.SizeNormal
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.ZIndex = 13
	lbl.Parent = frame
	bindText(lbl, labelKey)

	local isOn = defaultValue
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 55, 0, 28)
	btn.Position = UDim2.new(1, -60, 0, 6)
	btn.BackgroundColor3 = isOn and Theme.Success or Theme.SurfaceHighlight
	btn.Text = isOn and T("toggleOn") or T("toggleOff")
	btn.TextColor3 = isOn and Theme.TextDark or Theme.TextDim
	btn.Font = Theme.FontBold
	btn.TextSize = Theme.SizeNormal
	btn.BorderSizePixel = 0
	btn.ZIndex = 13
	btn.Parent = frame
	do
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 14)
		c.Parent = btn
	end

	table.insert(i18nToggleBtns, {
		btn = btn,
		getState = function()
			return isOn
		end,
	})

	btn.MouseButton1Click:Connect(function()
		isOn = not isOn
		btn.BackgroundColor3 = isOn and Theme.Success or Theme.SurfaceHighlight
		btn.Text = isOn and T("toggleOn") or T("toggleOff")
		btn.TextColor3 = isOn and Theme.TextDark or Theme.TextDim
		if callback then
			callback(isOn)
		end
	end)

	if descKey then
		local descLabel = Instance.new("TextLabel")
		descLabel.Size = UDim2.new(1, -8, 0, 22)
		descLabel.Position = UDim2.new(0, 4, 0, 41)
		descLabel.BackgroundTransparency = 1
		descLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
		descLabel.Font = Theme.Font
		descLabel.TextSize = 14
		descLabel.TextXAlignment = Enum.TextXAlignment.Left
		descLabel.TextWrapped = true
		descLabel.ZIndex = 13
		descLabel.Parent = frame
		bindText(descLabel, descKey)
	end

	return btn
end

-- ============================================================
-- 參數面板控件
-- ============================================================
createLabel("lblInterface", paramScrollFrame, 1)
createToggle("lblAutoScroll", paramScrollFrame, 2, true, function(v)
	autoScrollEnabled = v
end)

createLabel("lblGameInfo", paramScrollFrame, 3)

infoLabel = Instance.new("TextLabel")
infoLabel.Size = UDim2.new(1, 0, 0, 120)
infoLabel.BackgroundColor3 = Theme.Surface
infoLabel.BackgroundTransparency = 0.5
infoLabel.TextColor3 = Theme.Success
infoLabel.Font = Theme.Font
infoLabel.TextSize = 15
infoLabel.TextWrapped = true
infoLabel.LayoutOrder = 9
infoLabel.ZIndex = 13
infoLabel.Parent = paramScrollFrame
do
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 6)
	c.Parent = infoLabel
end
updateInfoLabel()

createLabel("lblTrackerOp", paramScrollFrame, 11)

local trackerBtnContainer = Instance.new("Frame")
trackerBtnContainer.Size = UDim2.new(1, 0, 0, 40)
trackerBtnContainer.BackgroundTransparency = 1
trackerBtnContainer.LayoutOrder = 12
trackerBtnContainer.ZIndex = 12
trackerBtnContainer.Parent = paramScrollFrame
do
	local l = Instance.new("UIListLayout")
	l.FillDirection = Enum.FillDirection.Horizontal
	l.Padding = UDim.new(0, 8)
	l.Parent = trackerBtnContainer
end

resetBtn = Instance.new("TextButton")
resetBtn.Size = UDim2.new(0.5, -4, 1, 0)
resetBtn.BackgroundColor3 = Theme.SurfaceHighlight
resetBtn.TextColor3 = Theme.Warning
resetBtn.Font = Theme.FontBold
resetBtn.TextSize = Theme.SizeNormal
resetBtn.BorderSizePixel = 0
resetBtn.LayoutOrder = 1
resetBtn.ZIndex = 13
resetBtn.Parent = trackerBtnContainer
do
	local c = Instance.new("UICorner")
	c.CornerRadius = Theme.CornerRadius
	c.Parent = resetBtn
end
bindText(resetBtn, "btnReset")

debugBtn = Instance.new("TextButton")
debugBtn.Size = UDim2.new(0.5, -4, 1, 0)
debugBtn.BackgroundColor3 = Theme.SurfaceHighlight
debugBtn.TextColor3 = Theme.TextDim
debugBtn.Font = Theme.FontBold
debugBtn.TextSize = Theme.SizeNormal
debugBtn.BorderSizePixel = 0
debugBtn.LayoutOrder = 2
debugBtn.ZIndex = 13
debugBtn.Parent = trackerBtnContainer
do
	local c = Instance.new("UICorner")
	c.CornerRadius = Theme.CornerRadius
	c.Parent = debugBtn
end
bindText(debugBtn, "btnDebug")

createLabel("lblScriptParam", paramScrollFrame, 13)
createToggle("lblAutoReplay", paramScrollFrame, 14, ScriptSettings.AutoReplay, function(v)
	ScriptSettings.AutoReplay = v
end)
-- 已移除三個非花園塔防的切換：「成本版/時間版」（閘門已固定：滾動塔走時間、其餘走金錢）、
-- 「記錄突變/附魔」（花園塔防放置不帶 unique，無突變資料）、「停用 Phase2 後綴」（Phase2 為 NTD 機制）。

-- ============================================================
-- 拖移功能
-- ============================================================
local function makeDraggable(uiElement)
	local state = {
		dragging = false,
		dragStart = nil,
		startPos = nil,
	}
	local renderConn = nil

	local function update()
		if not state.dragging then
			return
		end
		local delta = UserInputService:GetMouseLocation() - state.dragStart
		uiElement.Position = UDim2.new(
			state.startPos.X.Scale,
			state.startPos.X.Offset + delta.X,
			state.startPos.Y.Scale,
			state.startPos.Y.Offset + delta.Y
		)
	end

	uiElement.InputBegan:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			state.dragging = true
			state.dragStart = UserInputService:GetMouseLocation()
			state.startPos = uiElement.Position
			if not renderConn then
				renderConn = RunService.RenderStepped:Connect(update)
			end
		end
	end)

	uiElement.InputEnded:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			state.dragging = false
			if renderConn then
				renderConn:Disconnect()
				renderConn = nil
			end
		end
	end)
end

makeDraggable(parameterFrame)
makeDraggable(saveFrame)
makeDraggable(manageFrame)
makeDraggable(abilityFrame)

local tbDrag = {
	dragging = false,
}
local tbConn = nil
titleBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		tbDrag.dragging = true
		tbDrag.dragStart = UserInputService:GetMouseLocation()
		tbDrag.startPos = mainFrame.Position
		if not tbConn then
			tbConn = RunService.RenderStepped:Connect(function()
				if not tbDrag.dragging then
					return
				end
				local d = UserInputService:GetMouseLocation() - tbDrag.dragStart
				mainFrame.Position = UDim2.new(
					tbDrag.startPos.X.Scale,
					tbDrag.startPos.X.Offset + d.X,
					tbDrag.startPos.Y.Scale,
					tbDrag.startPos.Y.Offset + d.Y
				)
			end)
		end
	end
end)
titleBar.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		tbDrag.dragging = false
		if tbConn then
			tbConn:Disconnect()
			tbConn = nil
		end
	end
end)

-- ============================================================
-- 收合功能
-- ============================================================
local minimized = false
local function toggleMinimize()
	minimized = not minimized
	scrollFrame.Visible = not minimized
	copyBtn.Visible = not minimized
	saveBtn.Visible = not minimized
	Parameter.Visible = not minimized
	abilityBtn.Visible = not minimized
	minimizeBtn.Text = minimized and "+" or "—"
	TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
		Size = minimized and UISizes.mainFrameMinimized or UISizes.mainFrameExpanded,
	}):Play()
end
minimizeBtn.MouseButton1Click:Connect(toggleMinimize)

-- ============================================================
-- 面板互斥
-- ============================================================
local function closeAllPanels()
	parameterFrame.Visible = false
	saveFrame.Visible = false
	manageFrame.Visible = false
	abilityFrame.Visible = false
end

local function closeBlockingPanels()
	saveFrame.Visible = false
	manageFrame.Visible = false
end

local function positionAbilityFrame()
	if parameterFrame.Visible then
		abilityFrame.Position = UDim2.new(
			parameterFrame.Position.X.Scale,
			parameterFrame.Position.X.Offset + parameterFrame.AbsoluteSize.X + 10,
			parameterFrame.Position.Y.Scale,
			parameterFrame.Position.Y.Offset
		)
	else
		abilityFrame.Position = UDim2.new(
			mainFrame.Position.X.Scale,
			mainFrame.Position.X.Offset + mainFrame.AbsoluteSize.X + 10,
			mainFrame.Position.Y.Scale,
			mainFrame.Position.Y.Offset
		)
	end
end

local function openSavePanel()
	closeAllPanels()
	local defaultName = string.format(
		"%s_%s_%s",
		gameStartMapId or gameSettings.mapId or "Map",
		gameSettings.difficulty or "Diff",
		os.date("%Y%m%d_%H%M%S")
	)
	defaultName = defaultName:gsub("[^%w_%-]", "_")
	fileNameInput.Text = defaultName
	phase2NameInput.Text = defaultName -- 指定加載名稱預設帶主檔名（前綴）

	local hasTransition = mapTransitionLog[1] ~= nil
	if not hasTransition then
		currentSaveMode = "merged"
		updateSaveModeButtons()
	end
	relayoutSavePanel()

	saveFrame.Visible = true
end

-- ============================================================
-- 檔案操作
-- ============================================================
local function listScripts()
	local scripts = {}
	pcall(function()
		if listfiles then
			for _, fp in ipairs(listfiles(SCRIPT_SAVE_PATH)) do
				if fp:match("%.lua$") then
					local name = fp:match("([^/\\]+)%.lua$")
					if name then
						table.insert(scripts, {
							name = name,
							path = fp,
						})
					end
				end
			end
		end
	end)
	table.sort(scripts, function(a, b)
		return a.name > b.name
	end)
	return scripts
end

local function saveScriptToFile(fileName, content)
	local fullPath = SCRIPT_SAVE_PATH .. "/" .. fileName .. ".lua"
	local ok, err = pcall(function()
		if writefile then
			writefile(fullPath, content)
		else
			error("writefile unavailable")
		end
	end)
	if ok then
		addLog(T("logSaved"):format(fileName), Theme.Success)
		return true, fullPath
	else
		addLog(T("logSaveFailed"):format(tostring(err)), Theme.Error)
		return false, err
	end
end

function refreshScriptList()
	for _, child in pairs(manageScrollFrame:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	local scripts = listScripts()
	if #scripts == 0 then
		local el = Instance.new("TextLabel")
		el.Size = UDim2.new(1, -10, 0, 40)
		el.BackgroundTransparency = 1
		el.Text = T("logNoScripts")
		el.TextColor3 = Theme.TextDim
		el.Font = Theme.Font
		el.TextSize = Theme.SizeNormal
		el.ZIndex = 12
		el.Parent = manageScrollFrame
		return
	end
	for i, script in ipairs(scripts) do
		local item = Instance.new("Frame")
		item.Size = UDim2.new(1, -5, 0, 45)
		item.BackgroundColor3 = Theme.SurfaceHighlight
		item.BackgroundTransparency = 0.3
		item.BorderSizePixel = 0
		item.LayoutOrder = i
		item.ZIndex = 12
		item.Parent = manageScrollFrame
		do
			local c = Instance.new("UICorner")
			c.CornerRadius = UDim.new(0, 6)
			c.Parent = item
		end

		local nl = Instance.new("TextLabel")
		nl.Size = UDim2.new(1, -140, 1, 0)
		nl.Position = UDim2.new(0, 10, 0, 0)
		nl.BackgroundTransparency = 1
		nl.Text = script.name
		nl.TextColor3 = Theme.Text
		nl.Font = Theme.Font
		nl.TextSize = 14
		nl.TextXAlignment = Enum.TextXAlignment.Left
		nl.TextTruncate = Enum.TextTruncate.AtEnd
		nl.ZIndex = 13
		nl.Parent = item

		local runBtn = Instance.new("TextButton")
		runBtn.Size = UDim2.new(0, 35, 0, 30)
		runBtn.Position = UDim2.new(1, -130, 0, 7)
		runBtn.Text = "▶"
		runBtn.BackgroundColor3 = Theme.Success
		runBtn.TextColor3 = Theme.TextDark
		runBtn.Font = Theme.FontBold
		runBtn.TextSize = 16
		runBtn.BorderSizePixel = 0
		runBtn.ZIndex = 13
		runBtn.Parent = item
		do
			local c = Instance.new("UICorner")
			c.CornerRadius = UDim.new(0, 6)
			c.Parent = runBtn
		end

		local cpBtn = Instance.new("TextButton")
		cpBtn.Size = UDim2.new(0, 35, 0, 30)
		cpBtn.Position = UDim2.new(1, -90, 0, 7)
		cpBtn.Text = "📋"
		cpBtn.BackgroundColor3 = Theme.Accent
		cpBtn.TextColor3 = Theme.Text
		cpBtn.Font = Theme.FontBold
		cpBtn.TextSize = 16
		cpBtn.BorderSizePixel = 0
		cpBtn.ZIndex = 13
		cpBtn.Parent = item
		do
			local c = Instance.new("UICorner")
			c.CornerRadius = UDim.new(0, 6)
			c.Parent = cpBtn
		end

		local dlBtn = Instance.new("TextButton")
		dlBtn.Size = UDim2.new(0, 35, 0, 30)
		dlBtn.Position = UDim2.new(1, -50, 0, 7)
		dlBtn.Text = "🗑️"
		dlBtn.BackgroundColor3 = Theme.Error
		dlBtn.TextColor3 = Theme.Text
		dlBtn.Font = Theme.FontBold
		dlBtn.TextSize = 16
		dlBtn.BorderSizePixel = 0
		dlBtn.ZIndex = 13
		dlBtn.Parent = item
		do
			local c = Instance.new("UICorner")
			c.CornerRadius = UDim.new(0, 6)
			c.Parent = dlBtn
		end

		local fp = script.path
		local sname = script.name

		runBtn.MouseButton1Click:Connect(function()
			local ok2, content = pcall(function()
				return readfile and readfile(fp) or nil
			end)
			if not ok2 or not content or content == "" then
				addLog(T("logRunFailed"):format(sname), Theme.Error)
				return
			end
			local loadedFn, loadErr = loadstring(content)
			if not loadedFn then
				addLog(T("logRunFailed"):format(tostring(loadErr)), Theme.Error)
				return
			end
			addLog(T("logRunPhase1"):format(sname), Theme.Success)
			manageFrame.Visible = false
			task.spawn(loadedFn)
		end)
		cpBtn.MouseButton1Click:Connect(function()
			local ok2, content = pcall(function()
				return readfile and readfile(fp) or nil
			end)
			if ok2 and content then
				pcall(function()
					setclipboard(content)
				end)
				addLog(T("logCopied"):format(sname), Theme.Accent)
			end
		end)
		dlBtn.MouseButton1Click:Connect(function()
			pcall(function()
				if delfile then
					delfile(fp)
				end
			end)
			addLog(T("logDeleted"):format(sname), Theme.Warning)
			refreshScriptList()
		end)
	end
end

-- ============================================================
-- 生成腳本 (writeOp / buildOperations / generatePhase2Script / generateScript)
-- ============================================================
local function writeOp(lines, op)
	local rawE = op.elapsed or 0
	local e = timeRoundUp and (math.ceil(rawE * 10) / 10) or (math.floor(rawE * 10) / 10)
	-- 閘門固定（不給使用者選金錢/時間）：
	--   只有滾動塔 unit_wheel_bush 的放置/升級走「時間」（沿路滾動，放置時機影響效果）；
	--   其餘放置/升級走「金錢($)」；賣出/跳波/變速等不花錢，一律走時間。
	local opUnitType
	if op.type == "place" then
		opUnitType = op.info and op.info.UnitType
	elseif op.type == "upgrade" and op.order then
		local placed = orderToInfo[op.order]
		opUnitType = placed and placed.UnitType
	end
	local isCostGated = (op.type == "place" or op.type == "upgrade") and (opUnitType ~= "unit_wheel_bush")
	local gate, tag
	if isCostGated then
		-- 優先用查表修正後的牌價（op.correctedCost）；查不到才退回錄製時的金錢 delta 推算值
		local opCost = 0
		if op.type == "place" then
			opCost = op.correctedCost or (op.info and op.info.cost) or 0
		elseif op.type == "upgrade" then
			opCost = op.correctedCost or op.cost or 0
		end
		gate = string.format('"%d"', math.max(0, math.floor(opCost + 0.5)))
		tag = "$" .. tostring(math.max(0, math.floor(opCost + 0.5)))
	else
		gate = string.format("%.1f", e)
		tag = string.format("+%.1fs", e)
	end

	if op.type == "place" then
		local info = op.info
		local p = info.Position
		local x = p and p.X or 0
		local y = p and p.Y or 0
		local z = p and p.Z or 0
		local rot = math.floor((info.Rotation or 0) + 0.5)
		if info.PathIndex ~= nil then
			-- 沿路塔（如滾動塔 unit_wheel_bush）：多帶 PathIndex / DistanceAlongPath
			table.insert(lines, string.format(
				'\tGTD.AddPlaceTower("%s", %s, %.3f, %.3f, %.3f, %d, %d, %.3f) -- #%d %s',
				info.UnitType, gate, x, y, z, rot, info.PathIndex, info.DistanceAlongPath or 0, info.Index, tag))
		else
			table.insert(lines, string.format(
				'\tGTD.AddPlaceTower("%s", %s, %.3f, %.3f, %.3f, %d) -- #%d %s',
				info.UnitType, gate, x, y, z, rot, info.Index, tag))
		end
	elseif op.type == "upgrade" then
		if op.order then
			table.insert(lines, string.format("\tGTD.AddUpgradeTower(%d, %s) -- #%d %s", op.order, gate, op.order, tag))
		else
			table.insert(lines, string.format("\t-- WARN: upgrade untracked tower [ID:%s] %s", tostring(op.gameId), tag))
		end
	elseif op.type == "sell" then
		if op.order then
			table.insert(lines, string.format("\tGTD.AddSellTower(%d, %s) -- #%d %s", op.order, gate, op.order, tag))
		else
			table.insert(lines, string.format("\t-- WARN: sell untracked tower [ID:%s] %s", tostring(op.gameId), tag))
		end
	elseif op.type == "skipwave" then
		table.insert(lines, string.format("\tGTD.AddSkipWave(%s) -- %s", gate, tag))
	elseif op.type == "gamesetting" then
		if op.name == "AutoSkipWave" then
			table.insert(lines, string.format("\tGTD.AddSetAutoSkip(%s, %s) -- Auto Skip %s %s",
				op.value == true and "true" or "false",
				gate,
				op.value == true and "On" or "Off",
				tag))
		end
	elseif op.type == "speed" then
		table.insert(lines, string.format("\tGTD.AddSetSpeed(%d, %s) -- Speed %dx %s", op.speed, gate, op.speed, tag))
	end
	-- autoupgrade 已移除：自動升級由 Level 監看器收成普通 upgrade，走上面的 upgrade 分支
	-- towerability 非花園塔防重播操作，已移除
end

local function buildOperations()
	local operations = {}
	for order = 1, nextOrder - 1 do
		local info = orderToInfo[order]
		if info then
			table.insert(operations, {
				type = "place",
				order = order,
				elapsed = info.Elapsed or 0,
				info = info,
			})
		end
	end
	for _, up in ipairs(upgradeLog) do
		table.insert(operations, {
			type = "upgrade",
			order = up.order,
			elapsed = up.elapsed or 0,
			gameId = up.gameId,
			cost = up.cost,
		})
	end
	for _, sl in ipairs(sellLog) do
		table.insert(operations, {
			type = "sell",
			order = sl.order,
			elapsed = sl.elapsed or 0,
			gameId = sl.gameId,
		})
	end
	for _, sk in ipairs(skipWaveLog) do
		table.insert(operations, {
			type = "skipwave",
			elapsed = sk.elapsed or 0,
		})
	end
	for _, sp in ipairs(speedChangeLog) do
		table.insert(operations, {
			type = "speed",
			speed = sp.speed,
			elapsed = sp.elapsed or 0,
		})
	end
	for _, ab in ipairs(abilityLog) do
		table.insert(operations, {
			type = "towerability",
			order = ab.order,
			elapsed = ab.elapsed or 0,
			gameId = ab.gameId,
			abilityName = ab.abilityName,
		})
	end
	for _, gs in ipairs(gameSettingLog) do
		table.insert(operations, {
			type = "gamesetting",
			name = gs.name,
			value = gs.value,
			elapsed = gs.elapsed or 0,
		})
	end
	-- autoupgrade 已移除（自動升級併入 upgradeLog，見 StartLevelWatcher）

	-- 每個放置的 elapsed（給「依賴塔的操作不得早於該塔放置」夾住用）
	local placeElapsed = {}
	for order = 1, nextOrder - 1 do
		local info = orderToInfo[order]
		if info then placeElapsed[order] = info.Elapsed or 0 end
	end
	-- 排序鍵：升級/賣出/能力等「依賴某塔」的操作，排序時不得排在該塔的放置之前。
	-- （修 Level 監看器在遊戲結束瞬間 gameStartTime=nil → getElapsed()=0 → 升級被記 elapsed≈0
	--   → 排到放置前 → 重播時 orderToGameId 尚未綁定、升級被跳過的問題。）
	-- 用 build 索引當 tiebreak 做穩定排序（放置先插入故索引較小 → 同鍵時放置排在自己的升級前）。
	for i, op in ipairs(operations) do
		op._i = i
		local key = op.elapsed or 0
		if (op.type == "upgrade" or op.type == "sell" or op.type == "towerability") and op.order then
			local pe = placeElapsed[op.order]
			if pe and key < pe then key = pe + 0.001 end
		end
		op._sortKey = key
	end
	table.sort(operations, function(a, b)
		if a._sortKey ~= b._sortKey then return a._sortKey < b._sortKey end
		return a._i < b._i
	end)
	return operations
end

-- ============================================================
-- 花園塔防：塔價查表（取代不可靠的 Cash delta 成本推算）
-- 註：UpgradeUnit 回傳 true=成功 / false=金錢不足沒升級（成功與否可由回傳判定，2026-06-22 實測確認）；
-- 但「實付成本」無法由回傳得知，且 Cash delta 受收入/價格修正器干擾不準，故成本改查單位設定表。
-- 改查單位設定 Configs.<unit_id>.UnitConfig：
--   放置(level 1) = UnitConfig.Cost；升級到第 N+1 級 = UnitConfig.Upgrades[N].Cost
-- 查不到（未知塔/等級超出表）則保留原 Cash delta 值當退路。
-- 注意：此為「基礎牌價」，若該局有 md_unit_price_* 之類價格修正器會與實付有差。
-- ============================================================
local unitConfigCache = {}
local unitConfigsFolder = nil
local function getUnitConfig(unitId)
	if unitConfigCache[unitId] ~= nil then
		return unitConfigCache[unitId] or nil
	end
	if not unitConfigsFolder then
		local node = Players.LocalPlayer:FindFirstChild("PlayerGui")
		for _, n in ipairs({ "LogicHolder", "ClientLoader", "SharedConfig", "ItemData", "Units", "Configs" }) do
			node = node and node:FindFirstChild(n)
		end
		unitConfigsFolder = node
	end
	local mod = unitConfigsFolder and unitConfigsFolder:FindFirstChild(unitId)
	if not mod then
		unitConfigCache[unitId] = false
		return nil
	end
	-- require 遊戲模組前先降 thread identity 到 2 再還原
	local getId = getthreadidentity or getidentity or get_thread_identity
	local setId = setthreadidentity or setidentity or set_thread_identity
	local oldId = 8
	if getId then
		local okId, id = pcall(getId)
		if okId and type(id) == "number" then oldId = id end
	end
	if setId then pcall(setId, 2) end
	local ok, res = pcall(require, mod)
	if setId then pcall(setId, oldId) end
	local cfg = ok and res or nil
	unitConfigCache[unitId] = cfg or false
	return cfg
end

-- level 1 = 放置；level 2,3.. = 升級到該級
local function getUnitCost(unitId, level)
	local cfg = unitId and getUnitConfig(unitId)
	local uc = cfg and cfg.UnitConfig
	if type(uc) ~= "table" then return nil end
	if level <= 1 then
		return type(uc.Cost) == "number" and uc.Cost or nil
	end
	local up = type(uc.Upgrades) == "table" and uc.Upgrades[level - 1]
	return (type(up) == "table" and type(up.Cost) == "number") and up.Cost or nil
end

-- 用查表價覆寫成本 → op.correctedCost（依每塔升級次數累進等級）
local function applyTablePriceCorrection(operations)
	local levelByOrder = {}
	for _, op in ipairs(operations) do
		if op.type == "place" and op.order then
			levelByOrder[op.order] = 1
			local name = op.info and op.info.UnitType
			local price = getUnitCost(name, 1)
			if price then op.correctedCost = math.max(0, math.floor(price + 0.5)) end
		elseif op.type == "upgrade" and op.order then
			local lvl = (levelByOrder[op.order] or 1) + 1
			levelByOrder[op.order] = lvl
			local info = orderToInfo[op.order]
			local name = info and info.UnitType
			local price = getUnitCost(name, lvl)
			if price then op.correctedCost = math.max(0, math.floor(price + 0.5)) end
		end
	end
end

local function generateScript(mode)
	if nextOrder <= 1 and #upgradeLog == 0 and #skipWaveLog == 0 and #gameSettingLog == 0 then
		addLog(T("logNoOps"), Theme.Warning)
		return nil
	end

	-- 收集用到的塔（去重，提示玩家在大廳裝備）
	local usedTowers = {}
	local seenTower = {}
	for order = 1, nextOrder - 1 do
		local info = orderToInfo[order]
		if info and info.UnitType and not seenTower[info.UnitType] then
			seenTower[info.UnitType] = true
			table.insert(usedTowers, info.UnitType)
		end
	end

	local operations = buildOperations()
	applyTablePriceCorrection(operations) -- 用塔資料庫牌價覆寫成本（免疫 Cash delta 污染）

	-- 花園塔防：只生成「關卡內佇列」重播腳本，呼叫 GTD 重播 API（完整.lua）。
	local fullLines = {}
	table.insert(fullLines, "--[[")
	table.insert(fullLines, "")
	table.insert(fullLines, string.format("Map: %s  |  Difficulty: %s", gameSettings.mapId, gameSettings.difficulty))
	if gameEndElapsed then
		table.insert(fullLines, string.format("Time: %dm %ds (%.1fs)",
			math.floor(gameEndElapsed / 60), math.floor(gameEndElapsed % 60), gameEndElapsed))
	end
	table.insert(fullLines, "")
	if customComment ~= "" then
		table.insert(fullLines, customComment)
		table.insert(fullLines, "")
	end
	if #usedTowers > 0 then
		table.insert(fullLines, "Towers used (記得在大廳裝備這些塔):")
		for _, n in ipairs(usedTowers) do
			table.insert(fullLines, "  - " .. n)
		end
		table.insert(fullLines, "")
	end
	table.insert(fullLines, "]]")
	table.insert(fullLines, "")
	table.insert(fullLines, "-- 自動載入花園塔防 GTD 重播 API（完整.lua）")
	table.insert(fullLines, "local GTD = getgenv().GTD")
	table.insert(fullLines, "if not GTD or not GTD.ExecuteQueue then")
	table.insert(fullLines, string.format('    loadstring(game:HttpGet("%s"))()', GTD_API_URL))
	table.insert(fullLines, "    GTD = getgenv().GTD")
	table.insert(fullLines, "end")
	table.insert(fullLines, "")
	-- 大廳分支：在大廳執行時自動選圖+難度進關卡（進關卡後本腳本由 autoexec/SaveLocalScript 重載，走下方 IsInGame）
	local hasMap = type(gameSettings.mapId) == "string" and gameSettings.mapId:match("^map_") ~= nil
	local hasDif = gameSettings.difficultyId ~= nil and gameSettings.difficultyId ~= ""
	table.insert(fullLines, "if GTD.IsLobby() then")
	-- 大廳：先裝備錄製用到的塔（EquipLoadout 預設先卸全部再裝，精準還原該套陣容），再選圖
	if #usedTowers > 0 then
		local towerLits = {}
		for _, n in ipairs(usedTowers) do
			table.insert(towerLits, string.format('"%s"', n))
		end
		table.insert(fullLines, string.format(
			'\tif GTD.EquipLoadout then GTD.EquipLoadout({ %s }) end -- 裝備這套塔',
			table.concat(towerLits, ", ")))
	end
	if hasMap and hasDif then
		table.insert(fullLines, string.format(
			'\tif GTD.SelectMap then GTD.SelectMap("%s", "%s") else warn("[GTD] 此版 API 無 SelectMap，請更新 完整.lua 後重試") end',
			gameSettings.mapId, gameSettings.difficultyId))
		table.insert(fullLines, '\tprint("[GTD] 已在大廳選圖，進入關卡後本腳本將自動接手執行佇列")')
	else
		table.insert(fullLines, '\twarn("[GTD] 錄製未含有效地圖/難度，無法自動選圖，請手動進入關卡後再執行")')
	end
	table.insert(fullLines, "\treturn")
	table.insert(fullLines, "end")
	table.insert(fullLines, "")
	table.insert(fullLines, "if GTD.IsInGame() then")
	-- 反巨集抖動：預設帶上（API 內預設本就開，這行讓設定在重播腳本裡可見可調；
	-- 想關閉改成 GTD.SetJitter(false) 或註解掉本行；用 if 防舊版常駐 API 無此函式）
	table.insert(fullLines, "\tif GTD.SetJitter then GTD.SetJitter({ actionDelayMin = 0.05, actionDelayMax = 0.35, placeOffsetStuds = 0.15, pathDistJitter = 0 }) end")
	if ScriptSettings.AutoReplay then
		table.insert(fullLines, "\tGTD.AutoReplay(true)")
	end
	if gameSettings.difficultyId and gameSettings.difficultyId ~= "" then
		table.insert(fullLines, string.format('\tGTD.SelectDifficulty("%s") -- 投票難度開始遊戲', gameSettings.difficultyId))
	end
	table.insert(fullLines, string.format("\tGTD.AddSetAutoSkip(%s, 0) -- Auto Skip 開局狀態",
		gameStartAutoSkipWave and "true" or "false"))
	table.insert(fullLines, "")
	table.insert(fullLines, "\t-- 操作（金錢閘門=$X / 時間閘門=+Xs）")
	for _, op in ipairs(operations) do
		writeOp(fullLines, op)
	end
	table.insert(fullLines, "")
	if gameEndElapsed then
		table.insert(fullLines, string.format("\tGTD.AddEnd(%.1f)", gameEndElapsed))
	end
	table.insert(fullLines, "\tGTD.ExecuteQueue()")
	table.insert(fullLines, '\tprint("[GTD] 佇列已載入，等待開局...")')
	table.insert(fullLines, "else")
	table.insert(fullLines, '\twarn("[GTD] 請在關卡內執行本重播腳本")')
	table.insert(fullLines, "end")

	local fullScriptContent = table.concat(fullLines, "\n")

	-- 外層啟動器（照 NTD 兩層架構）：載入 API → SaveLocalScript（存檔供 AutoReplay/重連重載）→ 執行內層
	local outer = {}
	table.insert(outer, "--[[")
	table.insert(outer, "  花園塔防 放置追蹤器 生成的重播腳本")
	table.insert(outer, string.format("  Map: %s  |  Difficulty: %s", gameSettings.mapId, gameSettings.difficulty))
	if gameEndElapsed then
		table.insert(outer, string.format("  Time: %dm %ds", math.floor(gameEndElapsed / 60), math.floor(gameEndElapsed % 60)))
	end
	table.insert(outer, "]]")
	table.insert(outer, "")
	table.insert(outer, "local fullScript = [=[")
	table.insert(outer, fullScriptContent)
	table.insert(outer, "]=" .. "]")
	table.insert(outer, "")
	table.insert(outer, "local GTD = getgenv().GTD")
	table.insert(outer, "if not GTD or not GTD.ExecuteQueue then")
	table.insert(outer, string.format('    loadstring(game:HttpGet("%s"))()', GTD_API_URL))
	table.insert(outer, "    GTD = getgenv().GTD")
	table.insert(outer, "end")
	table.insert(outer, "if GTD.SaveLocalScript then GTD.SaveLocalScript(fullScript) end")
	table.insert(outer, "loadstring(fullScript)()")

	return table.concat(outer, "\n")
end

-- ============================================================
-- 塔能力面板 卡片建構 / 管理函數
-- ============================================================
local abiCardOrder = 0

local function buildAbilityCard(model)
	if abiTowerCards[model] then
		return
	end
	local info = abiLiveTowers[model]
	if not info or not info.abilityKeys or #info.abilityKeys == 0 then
		return
	end

	if abiEmptyLabel then
		abiEmptyLabel.Visible = false
	end

	abiCardOrder = abiCardOrder + 1
	local hasId = info.gameId ~= nil
	local idStr = hasId and tostring(info.gameId) or "?"

	local container = Instance.new("Frame")
	container.Size = UDim2.new(1, -4, 0, 0)
	container.AutomaticSize = Enum.AutomaticSize.Y
	container.BackgroundColor3 = Theme.Surface
	container.BackgroundTransparency = 0.3
	container.BorderSizePixel = 0
	container.LayoutOrder = abiCardOrder
	container.ZIndex = 12
	container.Parent = abilityScrollFrame
	do
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 8)
		c.Parent = container
	end

	local cardLayout = Instance.new("UIListLayout")
	cardLayout.SortOrder = Enum.SortOrder.LayoutOrder
	cardLayout.Padding = UDim.new(0, 4)
	cardLayout.Parent = container

	local cardPadding = Instance.new("UIPadding")
	cardPadding.PaddingTop = UDim.new(0, 8)
	cardPadding.PaddingBottom = UDim.new(0, 8)
	cardPadding.PaddingLeft = UDim.new(0, 8)
	cardPadding.PaddingRight = UDim.new(0, 8)
	cardPadding.Parent = container

	local widgets = {}
	local saved = info.savedAutoStates or {}

	for idx, key in ipairs(info.abilityKeys) do
		local abi = getAbiData(key)
		local capturedKey = key
		local capturedCd = abi.Cooldown
		local autoEnabled = saved[key] == true

		local abiLabel = Instance.new("TextLabel")
		abiLabel.Size = UDim2.new(1, 0, 0, 22)
		abiLabel.BackgroundTransparency = 1
		abiLabel.Text = string.format(
			"#%d  %s  [ID: %s]    %s",
			info.order,
			info.name,
			idStr,
			T("abilityFmt"):format(abi.Name, abi.Cooldown)
		)
		abiLabel.TextColor3 = Theme.Accent
		abiLabel.Font = Theme.FontBold
		abiLabel.TextSize = 14
		abiLabel.TextXAlignment = Enum.TextXAlignment.Left
		abiLabel.TextTruncate = Enum.TextTruncate.AtEnd
		abiLabel.LayoutOrder = idx * 10
		abiLabel.ZIndex = 13
		abiLabel.Parent = container

		local btnRow = Instance.new("Frame")
		btnRow.Size = UDim2.new(1, 0, 0, 30)
		btnRow.BackgroundTransparency = 1
		btnRow.LayoutOrder = idx * 10 + 1
		btnRow.ZIndex = 13
		btnRow.Parent = container

		local barBg = Instance.new("Frame")
		barBg.Size = UDim2.new(0.65, -4, 1, 0)
		barBg.Position = UDim2.new(0, 0, 0, 0)
		barBg.BackgroundColor3 = Theme.SurfaceHighlight
		barBg.BorderSizePixel = 0
		barBg.ZIndex = 14
		barBg.ClipsDescendants = true
		barBg.Parent = btnRow
		do
			local c = Instance.new("UICorner")
			c.CornerRadius = UDim.new(0, 6)
			c.Parent = barBg
		end

		local barFill = Instance.new("Frame")
		barFill.Size = UDim2.new(1, 0, 1, 0)
		barFill.BackgroundColor3 = Theme.Success
		barFill.BorderSizePixel = 0
		barFill.ZIndex = 15
		barFill.Parent = barBg
		do
			local c = Instance.new("UICorner")
			c.CornerRadius = UDim.new(0, 6)
			c.Parent = barFill
		end

		local barText = Instance.new("TextLabel")
		barText.Size = UDim2.new(1, 0, 1, 0)
		barText.BackgroundTransparency = 1
		barText.Text = hasId and T("abilityReady") or T("abilityWaitId")
		barText.TextColor3 = Theme.Text
		barText.Font = Theme.FontBold
		barText.TextSize = 12
		barText.ZIndex = 16
		barText.Parent = barBg

		local fireBtn = Instance.new("TextButton")
		fireBtn.Size = UDim2.new(0.65, -4, 1, 0)
		fireBtn.Position = UDim2.new(0, 0, 0, 0)
		fireBtn.BackgroundTransparency = 1
		fireBtn.Text = ""
		fireBtn.TextColor3 = hasId and Theme.Text or Theme.TextDim
		fireBtn.Font = Theme.FontBold
		fireBtn.TextSize = 13
		fireBtn.BorderSizePixel = 0
		fireBtn.ZIndex = 17
		fireBtn.Parent = btnRow

		fireBtn.MouseButton1Click:Connect(function()
			invokeTowerAbilitySafely(model, capturedKey, capturedCd)
		end)

		local autoState = {
			enabled = autoEnabled,
		}
		local autoBtn = Instance.new("TextButton")
		autoBtn.Size = UDim2.new(0.35, -4, 1, 0)
		autoBtn.Position = UDim2.new(0.65, 4, 0, 0)
		autoBtn.BackgroundColor3 = autoState.enabled and Theme.Success or Theme.SurfaceHighlight
		autoBtn.Text = T("abilityAutoLabel") .. (autoState.enabled and " ✓" or "")
		autoBtn.TextColor3 = autoState.enabled and Theme.TextDark or Theme.TextDim
		autoBtn.Font = Theme.FontBold
		autoBtn.TextSize = 13
		autoBtn.BorderSizePixel = 0
		autoBtn.ZIndex = 17
		autoBtn.Parent = btnRow
		do
			local c = Instance.new("UICorner")
			c.CornerRadius = UDim.new(0, 6)
			c.Parent = autoBtn
		end

		autoBtn.MouseButton1Click:Connect(function()
			autoState.enabled = not autoState.enabled
			autoBtn.BackgroundColor3 = autoState.enabled and Theme.Success or Theme.SurfaceHighlight
			autoBtn.Text = T("abilityAutoLabel") .. (autoState.enabled and " ✓" or "")
			autoBtn.TextColor3 = autoState.enabled and Theme.TextDark or Theme.TextDim
		end)

		if idx < #info.abilityKeys then
			local sep = Instance.new("Frame")
			sep.Size = UDim2.new(1, 0, 0, 1)
			sep.BackgroundColor3 = Theme.Border
			sep.BackgroundTransparency = 0.5
			sep.BorderSizePixel = 0
			sep.LayoutOrder = idx * 10 + 3
			sep.ZIndex = 13
			sep.Parent = container
		end

		table.insert(widgets, {
			barFill = barFill,
			barText = barText,
			fireBtn = fireBtn,
			autoBtn = autoBtn,
			autoState = autoState,
			autoFiredAt = nil,
			key = capturedKey,
			cd = capturedCd,
			abiName = abi.Name,
			abiLabel = abiLabel,
		})
	end

	info.savedAutoStates = nil
	abiTowerCards[model] = {
		container = container,
		widgets = widgets,
	}
end

local function removeAbilityCard(model)
	local card = abiTowerCards[model]
	if not card then
		return
	end
	if abiLiveTowers[model] then
		local saved = {}
		for _, w in ipairs(card.widgets) do
			saved[w.key] = w.autoState.enabled
		end
		abiLiveTowers[model].savedAutoStates = saved
	end
	card.container:Destroy()
	abiTowerCards[model] = nil

	if not next(abiTowerCards) and abiEmptyLabel then
		abiEmptyLabel.Visible = true
	end
end

-- 實作 forward-declared rebuildAllAbilityCards
rebuildAllAbilityCards = function()
	for model in pairs(abiTowerCards) do
		removeAbilityCard(model)
	end
	for model in pairs(abiLiveTowers) do
		buildAbilityCard(model)
	end
end

local function abiBindGameId(model, gameId)
	local info = abiLiveTowers[model]
	if not info or info.gameId ~= nil then
		return
	end
	info.gameId = gameId
	abiModelByGameId[gameId] = model
	if abiGameIdCooldownHint[gameId] then
		for k, t0 in pairs(abiGameIdCooldownHint[gameId]) do
			info.cooldowns[k] = t0
		end
		abiGameIdCooldownHint[gameId] = nil
	end
	if abiTowerCards[model] then
		removeAbilityCard(model)
		buildAbilityCard(model)
	end
end

-- 空提示標籤
abiEmptyLabel = Instance.new("TextLabel")
abiEmptyLabel.Size = UDim2.new(1, -10, 0, 40)
abiEmptyLabel.BackgroundTransparency = 1
abiEmptyLabel.Text = T("abilityNoTowers")
abiEmptyLabel.TextColor3 = Theme.TextDim
abiEmptyLabel.Font = Theme.Font
abiEmptyLabel.TextSize = Theme.SizeNormal
abiEmptyLabel.ZIndex = 12
abiEmptyLabel.LayoutOrder = 9999
abiEmptyLabel.Parent = abilityScrollFrame

-- ============================================================
-- 塔能力回調
-- ============================================================
local function onAbilityPlaceTower(towerName, gameId)
	local bound = false
	for model, info in pairs(abiLiveTowers) do
		if info.name == towerName and info.gameId == nil then
			abiBindGameId(model, gameId)
			bound = true
			break
		end
	end
	if not bound then
		table.insert(abiPendingGameIds, {
			name = towerName,
			gameId = gameId,
			time = tick(),
		})
	end
end

local function onAbilitySellTower(gameId)
	local model = abiModelByGameId[gameId]
	if model and abiLiveTowers[model] then
		removeAbilityCard(model)
		abiLiveTowers[model] = nil
		abiModelByGameId[gameId] = nil
	end
end

local function onAbilityTowerAbility(gameId, abilityKey)
	if not abilityFrame.Visible then
		positionAbilityFrame()
		abilityFrame.Visible = true
	end
	if gameId and abilityKey then
		local model = abiModelByGameId[gameId]
		if model and abiLiveTowers[model] then
			abiLiveTowers[model].cooldowns[abilityKey] = abiGameClock
		else
			abiGameIdCooldownHint[gameId] = abiGameIdCooldownHint[gameId] or {}
			abiGameIdCooldownHint[gameId][abilityKey] = abiGameClock
		end
	end
end

-- ============================================================
-- 按鈕事件
-- ============================================================
copyBtn.MouseButton1Click:Connect(function()
	local s = generateScript()
	if s then
		local ok = pcall(setclipboard, s)
		if ok then
			addLog(T("logCopyOk"), Color3.fromRGB(100, 255, 100))
			copyBtn.Text = T("btnCopied")
			copyBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
			print("\n========== Generated Script ==========")
			print(s)
			print("=======================================\n")
			task.wait(2)
			copyBtn.Text = T("btnCopy")
			copyBtn.BackgroundColor3 = Theme.Success
		else
			addLog(T("logCopyConsole"), Theme.Warning)
			print(s)
		end
	end
end)

saveBtn.MouseButton1Click:Connect(openSavePanel)

confirmSaveBtn.MouseButton1Click:Connect(function()
	local fileName = fileNameInput.Text:gsub("[^%w_%-]", "_")
	if fileName == "" or fileName:match("^_+$") then
		addLog(T("logInvalidName"), Theme.Warning)
		return
	end
	local s = generateScript()
	if s then
		local ok = saveScriptToFile(fileName, s)
		if ok then
			saveFrame.Visible = false
		end
	end
end)

cancelSaveBtn.MouseButton1Click:Connect(function()
	saveFrame.Visible = false
end)
saveCloseBtn.MouseButton1Click:Connect(function()
	saveFrame.Visible = false
end)
manageCloseBtn.MouseButton1Click:Connect(function()
	manageFrame.Visible = false
end)
closeBtn.MouseButton1Click:Connect(function()
	parameterFrame.Visible = false
end)
abilityCloseBtn.MouseButton1Click:Connect(function()
	abilityFrame.Visible = false
end)
refreshScriptsBtn.MouseButton1Click:Connect(function()
	refreshScriptList()
end)

Parameter.MouseButton1Click:Connect(function()
	if not parameterFrame.Visible then
		closeBlockingPanels()
		parameterFrame.Position = UDim2.new(
			mainFrame.Position.X.Scale,
			mainFrame.Position.X.Offset + mainFrame.AbsoluteSize.X + 10,
			mainFrame.Position.Y.Scale,
			mainFrame.Position.Y.Offset
		)
		parameterFrame.Visible = true
		if abilityFrame.Visible then
			positionAbilityFrame()
		end
	else
		parameterFrame.Visible = false
		if abilityFrame.Visible then
			positionAbilityFrame()
		end
	end
end)

abilityBtn.MouseButton1Click:Connect(function()
	if not abilityFrame.Visible then
		closeBlockingPanels()
		positionAbilityFrame()
		abilityFrame.Visible = true
	else
		abilityFrame.Visible = false
	end
end)

resetBtn.MouseButton1Click:Connect(function()
	nextOrder = 1
	orderToInfo = {}
	idToOrder = {}
	upgradeLog = {}
	towerObjById = {}     -- 清空塔物件快取（Level 偵測）
	lastLevelByOrder = {} -- 清空等級基準（Level 偵測）
	sellLog = {}
	skipWaveLog = {}
	speedChangeLog = {}
	abilityLog = {}
	gameSettingLog = {}
	gameStartAutoSkipWave = false
	lastDetectedSpeed = 1
	isGameRunning = false
	gameStartTime = nil
	gameEndElapsed = nil
	gameStartMapId = nil
	mapTransitionLog = {}
	readyHooked = false

	-- 重置能力面板
	for model in pairs(abiTowerCards) do
		removeAbilityCard(model)
	end
	abiLiveTowers = {}
	abiModelByGameId = {}
	abiPendingGameIds = {}
	abiGameIdCooldownHint = {}
	abiRemoteInFlight = {}
	abiNextOrder = 1
	abiCardOrder = 0
	if abiEmptyLabel then
		abiEmptyLabel.Visible = true
	end

	-- 花園塔防：重置時用 workspace 屬性重新同步地圖（NTD 的 ReplicatedStorage.Values 在 GTD 不存在，
	-- 舊碼的 WaitForChild("Values",3) 每次重置都會白等 3 秒 timeout）。難度由 InitTracker 的
	-- Difficulty 屬性監聽持續維護，重置不需重讀。
	pcall(function()
		gameSettings.mapId = workspace:GetAttribute("MapId") or gameSettings.mapId or "Unknown"
	end)

	for _, child in pairs(scrollFrame:GetChildren()) do
		child:Destroy()
	end
	listLayout:Destroy()
	listLayout = Instance.new("UIListLayout")
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding = UDim.new(0, 8)
	listLayout.Parent = scrollFrame
	listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
	end)
	logOrder = 1

	updateInfoLabel()
	addLog(T("logReset"), Color3.fromRGB(100, 200, 255))
end)

debugBtn.MouseButton1Click:Connect(function()
	addLog(T("logTowerListHdr"), Color3.fromRGB(100, 200, 255))
	if nextOrder <= 1 then
		addLog(T("logNoRecord"), Theme.TextDim)
	else
		for order = 1, nextOrder - 1 do
			local info = orderToInfo[order]
			if info then
				addLog(
					T("logTowerItem"):format(
						info.order,
						info.UnitType .. getMutLabel(info.UUID),
						tostring(info.GameID),
						info.Elapsed or 0
					),
					Color3.fromRGB(200, 200, 200)
				)
			end
		end
	end
end)

-- F8 切換顯示
UserInputService.InputBegan:Connect(function(input, gp)
	if input.KeyCode == Enum.KeyCode.F8 and not gp then
		uiVisible = not uiVisible
		mainFrame.Visible = uiVisible
		if not uiVisible then
			closeAllPanels()
		end
	end
end)

-- ============================================================
-- 花園塔防專用 helper（自舊版移植）
-- ============================================================
-- 取得模型樞紐世界座標（放置後比對 Entities 用）
local function getModelPivotPosition(model)
	if typeof(model) ~= "Instance" then return nil end
	local ok, pivot = pcall(function() return model.WorldPivot end)
	if ok and pivot then return pivot.Position end
	ok, pivot = pcall(function() return model:GetPivot() end)
	if ok and pivot then return pivot.Position end
	if model:IsA("Model") and model.PrimaryPart then return model.PrimaryPart.Position end
	return nil
end

-- 兩座標是否接近（綁定放置塔 id 用）
local function positionsClose(a, b, tolerance)
	if not a or not b then return false end
	tolerance = tolerance or 0.5
	return (a - b).Magnitude <= tolerance
end

-- 遊戲速度：讀 workspace 屬性 TickSpeed（比舊版抓 UI 顏色穩；回傳數字 1/2/3）
local function detectGameSpeedNum()
	local v = workspace:GetAttribute("TickSpeed")
	if type(v) == "number" and v > 0 then return v end
	return 1
end

-- 難度正規化：dif_easy → Easy
local difficultyMap = {
	dif_easy = "Easy", dif_normal = "Normal", dif_hard = "Hard",
	dif_insane = "Insane", dif_impossible = "Impossible", dif_apocalypse = "Apocalypse",
}
local function normalizeDifficulty(difId)
	if type(difId) ~= "string" then return "Unknown" end
	return difficultyMap[difId] or difId
end

-- 單次掃描 workspace.Map.Entities，找位置吻合且非 enemy_ 的未綁定 entity，讀其 ID attribute。
-- 回傳 gameId（數字）或 nil。
local function findUnboundEntityAt(targetPos)
	if not EntitiesFolder then return nil end
	for _, child in ipairs(EntitiesFolder:GetChildren()) do
		if not child.Name:match("^enemy_") then
			local idVal = child:GetAttribute("ID")
			if type(idVal) == "number" and not idToOrder[idVal] then
				local childPos = getModelPivotPosition(child)
				if childPos and positionsClose(childPos, targetPos, 0.6) then
					return idVal, child
				end
			end
		end
	end
	return nil
end

-- 待綁定放置佇列：__namecall hook 由「遊戲」呼叫時跑在受限能力執行緒（lacking capability Plugin），
-- 不能建立 UI Instance；故 hook 只 push 純表工作，實際綁定+addLog 移到 Heartbeat（elevated）處理。
local pendingPlacements = {}

-- 每幀處理待綁定放置（在 Heartbeat 內呼叫 → elevated capability，可操作 Instance）。
local function processPendingPlacements()
	if #pendingPlacements == 0 then return end
	local now = os.clock()
	for i = #pendingPlacements, 1, -1 do
		local job = pendingPlacements[i]
		local gameId = findUnboundEntityAt(job.targetPos)
		if gameId then
			table.remove(pendingPlacements, i)
			local elapsed = job.elapsed or getElapsed()
			local info = {
				order = nextOrder,
				name = job.unitName,
				id = gameId,
				position = job.targetPos,
				Index = nextOrder,
				UnitType = job.unitName,
				DisplayName = job.unitName,
				Position = job.targetPos,
				GameID = gameId,
				Rotation = job.rotation or 0,
				CF = job.placeCF,
				PathIndex = job.pathIndex,
				DistanceAlongPath = job.distanceAlongPath,
				Elapsed = elapsed,
				cost = 0,
			}
			if job.placeAction then
				job.placeAction.callback = function(cost)
					info.cost = cost
				end
				if job.placeAction.cost then
					info.cost = job.placeAction.cost
				end
			end
			orderToInfo[nextOrder] = info
			idToOrder[gameId] = nextOrder
			lastLevelByOrder[nextOrder] = 1 -- 放置即 1 級；之後由 Level 監看器偵測升級
			local placeLogText = T("logPlaceTower"):format(nextOrder, job.unitName, elapsed)
			if ScriptSettings.CostMode and info.cost and info.cost > 0 then
				placeLogText = placeLogText .. string.format("  $%d", info.cost)
			end
			addLog(placeLogText, Color3.fromRGB(100, 255, 100))
			nextOrder += 1
			pcall(onAbilityPlaceTower, job.unitName, gameId)
		elseif now >= job.deadline then
			table.remove(pendingPlacements, i)
			if job.placeAction then
				CostTracker.CancelAction(job.placeAction)
			end
			addLog(T("logPlaceFailed"):format(job.unitName), Theme.Warning)
		end
	end
end

-- ============================================================
-- 升級偵測 — 監看 client 塔物件的 .Level 增量（統一手動+自動升級）
-- 塔的 client 實體物件帶 ID(=gameId)/Level/IsAutoUpgrading/Owner。無 gameId→物件的純表管理器，
-- 故用 getgc 一次性掃描建快取，之後只輪詢快取物件的 .Level（純表讀取，零 getgc、不卡頓）。
-- getgc 一律走「背景+單 rawget 預篩+湊齊即停+每 500 表讓一幀+硬上限」，避免凍住遊戲。
-- ============================================================
local levelWatchActive = false
local lastLevelScanClock = 0

-- 安全 getgc：只為 neededIds（gameId 集合）找對應塔物件並寫入 towerObjById，湊齊即停。
local function collectTowerObjects(neededIds)
	local remaining = 0
	for _ in pairs(neededIds) do
		remaining += 1
	end
	if remaining == 0 then
		return
	end
	local lp = Players.LocalPlayer
	pcall(function()
		local gc = getgc(true)
		task.wait() -- 重快照後先讓一幀
		local scanned = 0
		for i = 1, #gc do
			local v = gc[i]
			if type(v) == "table" then
				local id = rawget(v, "ID")
				-- 單一 rawget 預篩；再用 Level/IsAutoUpgrading/Owner 精確認定為「我方塔物件」
				if id ~= nil and neededIds[id]
					and type(rawget(v, "Level")) == "number"
					and rawget(v, "IsAutoUpgrading") ~= nil
					and rawget(v, "Owner") == lp then
					towerObjById[id] = v
					neededIds[id] = nil
					remaining -= 1
					if remaining <= 0 then
						break
					end
				end
			end
			scanned += 1
			if scanned % 500 == 0 then
				task.wait()
			end
			if scanned >= 400000 then
				break
			end
		end
	end)
end

-- 背景監看器：補抓缺物件的塔（getgc，有冷卻）+ 偵測 .Level 增量 → 補普通升級 op。
-- 由 InitTracker 的 task.defer（elevated）啟動，故本執行緒可碰 UI（addLog）。
local function StartLevelWatcher()
	if levelWatchActive then
		return
	end
	levelWatchActive = true
	task.spawn(function()
		while true do
			task.wait(0.5)
			if isGameRunning then
				-- 目前在場的我方塔 id（便宜：Entities 子物件數量少）
				local presentIds = {}
				local Entities = EntitiesFolder
				if not (Entities and Entities.Parent) then
					local Map = workspace:FindFirstChild("Map")
					Entities = Map and Map:FindFirstChild("Entities")
				end
				if Entities then
					for _, child in ipairs(Entities:GetChildren()) do
						if not child.Name:match("^enemy_") then
							local idVal = child:GetAttribute("ID")
							if type(idVal) == "number" then
								presentIds[idVal] = true
							end
						end
					end
				end

				-- 補抓缺物件的塔（只抓「已追蹤 ∧ 在場 ∧ 尚無快取」者；getgc 有 3s 冷卻防連續重掃）
				local needed, missing = {}, 0
				for gameId in pairs(idToOrder) do
					if presentIds[gameId] and not towerObjById[gameId] then
						needed[gameId] = true
						missing += 1
					end
				end
				if missing > 0 and (os.clock() - lastLevelScanClock) >= 3 then
					lastLevelScanClock = os.clock()
					collectTowerObjects(needed)
				end

				-- 偵測等級增量 → 每升一級補一筆普通 upgrade（成本由生成時的牌價表覆寫，故記 0）
				for gameId, order in pairs(idToOrder) do
					if presentIds[gameId] then
						local obj = towerObjById[gameId]
						if obj then
							local lvl = rawget(obj, "Level")
							if type(lvl) == "number" then
								local last = lastLevelByOrder[order] or 1
								if lvl > last then
									local k = lvl - last
									lastLevelByOrder[order] = lvl
									local elapsed = getElapsed()
									-- 防呆：升級時間不得早於該塔放置時間。遊戲結束瞬間 gameStartTime 被清 nil →
									-- getElapsed()=0，會把末段塔的升級記成 elapsed≈0 → 排序排到放置前 → 重播跳過。
									local pInfo = orderToInfo[order]
									if pInfo and pInfo.Elapsed and elapsed < pInfo.Elapsed then
										elapsed = pInfo.Elapsed
									end
									for _ = 1, k do
										table.insert(upgradeLog, {
											gameId = gameId,
											order = order,
											elapsed = elapsed,
											cost = 0,
										})
									end
									local info = orderToInfo[order]
									if info then
										addLog(string.format(
											"⬆ 升級 #%d: %s → Lv.%d (+%d) +%.1fs",
											order, info.UnitType or "?", lvl, k, elapsed),
											Color3.fromRGB(255, 255, 100))
									end
								end
							end
						end
					end
				end
			end
		end
	end)
end

-- ============================================================
-- 初始化追蹤系統
-- ============================================================
local function InitTracker()
	print("[GTD Tracker] Initializing...")
	local ok, err = pcall(function()
		-- 花園塔防：remote 全在 ReplicatedStorage.RemoteFunctions（扁平，皆 InvokeServer）
		local RF = ReplicatedStorage:WaitForChild("RemoteFunctions", 10)
		PlaceTowerRemote = RF:WaitForChild("PlaceUnit", 10)
		UpgradeTowerRemote = RF:WaitForChild("UpgradeUnit", 10)
		SellTowerRemote = RF:WaitForChild("SellUnit", 10)
		SkipWaveRemote = RF:WaitForChild("SkipWave", 10)
		GameSpeedRemote = RF:WaitForChild("ChangeTickSpeed", 10)
		GamemodeRemote = RF:WaitForChild("PlaceDifficultyVote", 10) -- 難度投票
		TowerAbilityRemote = RF:FindFirstChild("ActivateUnitAbility")
		AutoUpgradeRemote = RF:FindFirstChild("ToggleAutoUpgrade")
		ToggleSettingRemote = nil
		ReadyRemote = nil      -- 花園塔防無 Ready remote（難度投票後倒數即開始）
		GameRunningValue = nil -- 花園塔防無 GameRunning 值，狀態走 workspace 屬性

		-- 放置塔容器（升級/賣出 gameId 來源）
		local Map = workspace:WaitForChild("Map", 10)
		EntitiesFolder = Map and Map:WaitForChild("Entities", 10)

		-- 遊戲資訊：讀 workspace 屬性
		gameSettings.mapId = workspace:GetAttribute("MapId") or "Unknown"
		gameSettings.difficulty = normalizeDifficulty(workspace:GetAttribute("Difficulty"))
		gameSettings.difficultyId = workspace:GetAttribute("Difficulty") -- 原始 id（dif_insane），重播投票用
		gameSettings.modifier = "None"
		lastDetectedSpeed = detectGameSpeedNum()

		-- 地圖切換監聽（雙圖流程）
		workspace:GetAttributeChangedSignal("MapId"):Connect(function()
			local newMap = workspace:GetAttribute("MapId") or "Unknown"
			if isGameRunning and newMap ~= gameSettings.mapId then
				local elapsed = getElapsed()
				table.insert(mapTransitionLog, {
					fromMap = gameSettings.mapId,
					toMap = newMap,
					elapsed = elapsed,
				})
				addLog(
					string.format("🗺️ Map: %s → %s  +%.1fs", gameSettings.mapId, newMap, elapsed),
					Color3.fromRGB(255, 200, 80)
				)
			end
			gameSettings.mapId = newMap
			updateInfoLabel()
		end)

		-- 難度變化（PlaceDifficultyVote hook 也會設；這裡監聽屬性保險）
		workspace:GetAttributeChangedSignal("Difficulty"):Connect(function()
			local raw = workspace:GetAttribute("Difficulty")
			local d = normalizeDifficulty(raw)
			if gameSettings.difficulty ~= d then
				gameSettings.difficulty = d
				gameSettings.difficultyId = raw
				updateInfoLabel()
			end
		end)

		-- AutoSkip：UI 文字偵測 + 定期輪詢記錄變化
		autoSkipState.on = readAutoSkipWave()
		pcall(updateInfoLabel)
		task.spawn(function()
			while true do
				task.wait(0.5)
				local on = readAutoSkipWave()
				if on ~= autoSkipState.on then
					autoSkipState.on = on
					pcall(updateInfoLabel)
					if isGameRunning then
						local elapsed = getElapsed()
						table.insert(gameSettingLog, {
							name = "AutoSkipWave",
							value = on,
							elapsed = elapsed,
						})
						addLog(
							T("logGameSetting"):format("AutoSkipWave", tostring(on), elapsed),
							Color3.fromRGB(200, 150, 255)
						)
					end
				end
			end
		end)

		-- === Namecall Handlers ===
		local NamecallHandlers = {}
		NamecallHandlers.InvokeServer = {}
		NamecallHandlers.FireServer = {}

		-- 花園塔防：PlaceUnit(unitId, {CF,Rotation,Valid,Position[,PathIndex,DistanceAlongPath]})。
		-- 不回傳可用 id；且 hook 跑在受限能力執行緒（不能碰 UI / 不宜阻塞）。
		-- 這裡只 push 純表工作到 pendingPlacements，綁定+UI 交給 Heartbeat 的 processPendingPlacements（elevated）。
		NamecallHandlers.InvokeServer.PlaceTower = function(_, args, result, placeAction)
			local unitName = args[1]
			local placeParams = args[2]
			if type(unitName) ~= "string" or type(placeParams) ~= "table" then
				if placeAction then CostTracker.CancelAction(placeAction) end
				return result
			end
			local targetPos = placeParams.Position or (placeParams.CF and placeParams.CF.Position)
			if not isGameRunning or not targetPos then
				if placeAction then CostTracker.CancelAction(placeAction) end
				return result
			end
			table.insert(pendingPlacements, {
				unitName = unitName,
				targetPos = targetPos,
				rotation = placeParams.Rotation or 0,
				pathIndex = placeParams.PathIndex,
				distanceAlongPath = placeParams.DistanceAlongPath,
				placeCF = placeParams.CF,
				placeAction = placeAction,
				elapsed = getElapsed(),
				deadline = os.clock() + 5,
			})
			return result
		end

		-- 註：升級不再用 UpgradeUnit hook 記錄；改由 StartLevelWatcher 監看每塔 .Level 增量
		-- 統一捕捉手動+自動升級（自動升級為伺服器端執行、不發 UpgradeUnit）。

		NamecallHandlers.InvokeServer.SellTower = function(_, args, result)
			local towerId = tonumber(args[1])
			local idStr = args[1]

			queueHookTask(function()
				-- 花園塔防 SellUnit 回傳值未確認，比照舊版無條件記錄
				if not isGameRunning then
					return
				end

				local order = towerId and idToOrder[towerId]
				local info = order and orderToInfo[order]
				local elapsed = getElapsed()

				table.insert(sellLog, {
					gameId = towerId,
					order = order,
					elapsed = elapsed,
				})

				pcall(onAbilitySellTower, towerId)

				if info then
					addLog(T("logSell"):format(info.order, info.UnitType, elapsed), Color3.fromRGB(255, 100, 100))
				else
					addLog(T("logSellUnknown"):format(idStr, elapsed), Color3.fromRGB(255, 100, 100))
				end
			end)

			return result
		end

		NamecallHandlers.InvokeServer.TowerAbility = function(_, args, result)
			local towerId = tonumber(args[1])
			local abilityName = args[2] or "Unknown"
			local idStr = args[1]

			queueHookTask(function()
				if not isGameRunning then
					return
				end

				local order = towerId and idToOrder[towerId]
				local info = order and orderToInfo[order]
				local elapsed = getElapsed()

				table.insert(abilityLog, {
					gameId = towerId,
					order = order,
					abilityName = abilityName,
					elapsed = elapsed,
				})

				pcall(onAbilityTowerAbility, towerId, abilityName)

				if info then
					addLog(
						T("logAbility"):format(info.order, info.UnitType, abilityName, elapsed),
						Color3.fromRGB(180, 100, 255)
					)
				else
					addLog(T("logAbilityUnknown"):format(idStr, abilityName, elapsed), Color3.fromRGB(180, 100, 255))
				end
			end)

			return result
		end

		-- 花園塔防：SkipWave / ChangeTickSpeed / PlaceDifficultyVote 皆 RemoteFunction(InvokeServer)
		NamecallHandlers.InvokeServer.SkipWave = function(_, _, result)
			if readAutoSkipWave() then
				return result
			end

			if isGameRunning then
				local elapsed = getElapsed()
				table.insert(skipWaveLog, {
					elapsed = elapsed,
				})

				queueHookTask(function()
					addLog(T("logSkipWave"):format(elapsed), Color3.fromRGB(150, 150, 255))
				end)
			end

			return result
		end

		NamecallHandlers.InvokeServer.GameSpeed = function(_, args, result)
			local speed = tonumber(args[1]) or 1

			if isGameRunning and speed ~= lastDetectedSpeed then
				lastDetectedSpeed = speed
				local elapsed = getElapsed()

				table.insert(speedChangeLog, {
					speed = speed,
					elapsed = elapsed,
				})

				queueHookTask(function()
					addLog(T("logSpeedSet"):format(speed, elapsed), Color3.fromRGB(255, 200, 150))
				end)
			end

			return result
		end

		NamecallHandlers.InvokeServer.Difficulty = function(_, args, result)
			local difficulty = normalizeDifficulty(args[1])
			gameSettings.difficulty = difficulty
			gameSettings.difficultyId = args[1] -- 原始 id（dif_*），重播投票用
			queueHookTask(function()
				addLog(T("logDiffStart"):format(difficulty), Color3.fromRGB(150, 200, 255))
				updateInfoLabel()
			end)
			return result
		end

		-- 註：自動升級（ToggleAutoUpgrade）不再單獨記錄為 op；其升級效果由 StartLevelWatcher
		-- 監看 .Level 增量收成普通 upgrade，重播時即為一連串 GTD.AddUpgradeTower。

		-- Hook（花園塔防：全部走 InvokeServer，無 FireServer 分支）
		local oldNamecall
		oldNamecall = hookmetamethod(
			game,
			"__namecall",
			newcclosure(function(self, ...)
				local method = string.lower(getnamecallmethod())
				local args = {
					...,
				}

				-- 關鍵：用 table.pack/unpack 原樣保留並轉發「全部」回傳值。
				-- 花園塔防 UpgradeUnit/PlaceUnit 等會回多個值，遊戲 UI 要拿去算等級/價格；
				-- 只接第一個會讓 SetLevel/updateUpgradeButtonColor 拿到 nil → 報錯、UI 不更新。
				if method == "invokeserver" then
					if self == PlaceTowerRemote then
						local placeAction
						if ScriptSettings.CostMode then
							placeAction = CostTracker.PushAction(nil)
						end
						local res = table.pack(oldNamecall(self, ...))
						-- PlaceUnit 不回傳 id；成敗由 handler 綁定 Entities 後自行決定是否 CancelAction
						NamecallHandlers.InvokeServer.PlaceTower(self, args, res[1], placeAction)
						return table.unpack(res, 1, res.n)
					end
					-- UpgradeUnit：不攔截記錄（升級改由 .Level 監看器捕捉）；
					-- 原生 fall through 到底部 return oldNamecall(self, ...) 完整轉發全部回傳值。
					if self == SellTowerRemote then
						local res = table.pack(oldNamecall(self, ...))
						NamecallHandlers.InvokeServer.SellTower(self, args, res[1])
						return table.unpack(res, 1, res.n)
					end
					-- ToggleAutoUpgrade：不攔截記錄（自動升級效果由 .Level 監看器收成普通升級）。
					if TowerAbilityRemote and self == TowerAbilityRemote then
						local res = table.pack(oldNamecall(self, ...))
						NamecallHandlers.InvokeServer.TowerAbility(self, args, res[1])
						return table.unpack(res, 1, res.n)
					end
					if self == SkipWaveRemote then
						local res = table.pack(oldNamecall(self, ...))
						NamecallHandlers.InvokeServer.SkipWave(self, args, res[1])
						return table.unpack(res, 1, res.n)
					end
					if self == GameSpeedRemote then
						local res = table.pack(oldNamecall(self, ...))
						NamecallHandlers.InvokeServer.GameSpeed(self, args, res[1])
						return table.unpack(res, 1, res.n)
					end
					if self == GamemodeRemote then
						local res = table.pack(oldNamecall(self, ...))
						NamecallHandlers.InvokeServer.Difficulty(self, args, res[1])
						return table.unpack(res, 1, res.n)
					end
				end

				return oldNamecall(self, ...)
			end)
		)

		print("[GTD Tracker] hookmetamethod OK ")

		-- === 建立塔能力索引（花園塔防：能力資料內嵌於 GTD_ABILITY_DATA，免 require 全部單位設定，避免 WSA 閃退）===
		local abiCount = 0
		for unitId in pairs(GTD_ABILITY_DATA) do
			towersWithAbility[unitId] = { unitId }
			abiCount += 1
		end
		print(string.format("[GTD Tracker] Tower ability index built (%d units)", abiCount))
	end)

	-- （花園塔防放置不帶 unique/突變，無 NTD 的 currentPlrData.Items.Towers；已移除舊的本地突變讀取）

	task.defer(function()
		if not ok then
			warn("[GTD Tracker] Init failed:", err)
			addLog(T("logInitFailed"), Theme.Error)
			return
		end

		updateInfoLabel()

		addLog(T("logWaitReady"), Color3.fromRGB(255, 200, 100))
		addLog(T("logFlow"), Color3.fromRGB(180, 180, 255))

		-- 花園塔防：用 workspace.GameStartTime 屬性當「遊戲開始」訊號（取代 NTD 的 GameRunning 值）
		local function onGameStart()
			if isGameRunning then
				return
			end
			local gst = workspace:GetAttribute("GameStartTime")
			if type(gst) ~= "number" or gst <= 0 then
				return
			end
			startGameTimer(gameSettings.mapId)
			task.spawn(function()
				addLog(T("logDiffStart"):format(gameSettings.difficulty), Color3.fromRGB(100, 255, 100))
			end)
		end
		workspace:GetAttributeChangedSignal("GameStartTime"):Connect(onGameStart)
		onGameStart() -- 腳本中途載入：若遊戲已開始，立即起算

		-- 遊戲結束：偵測 GameGui.Screen.Middle.GameEnd 顯示（取代 GameRunning=false）
		task.spawn(function()
			local pg = Players.LocalPlayer:WaitForChild("PlayerGui")
			local gameGui = pg:WaitForChild("GameGui", 30)
			local screen = gameGui and gameGui:WaitForChild("Screen", 10)
			local middle = screen and screen:WaitForChild("Middle", 10)
			local gameEnd = middle and middle:WaitForChild("GameEnd", 30)
			if not gameEnd then
				return
			end
			local function onEnd()
				if gameEnd.Visible and isGameRunning then
					local endElapsed = getElapsed()
					gameEndElapsed = endElapsed
					isGameRunning = false
					gameStartTime = nil
					readyHooked = false
					stopAbilityRemoteTriggers()
					addLog(
						T("logGameEnd"):format(math.floor(endElapsed / 60), math.floor(endElapsed % 60), endElapsed),
						Color3.fromRGB(255, 255, 100)
					)
				end
			end
			gameEnd:GetPropertyChangedSignal("Visible"):Connect(onEnd)
			onEnd()
		end)

		-- 啟動升級偵測（監看 .Level 增量；本 defer 為 elevated，故其 task.spawn 可碰 UI）
		StartLevelWatcher()

		addLog(
			T("logStarted"):format(gameSettings.mapId, gameSettings.difficulty, gameSettings.modifier),
			Color3.fromRGB(100, 255, 100)
		)
		print("[GTD Tracker] Init complete")
	end)
end

-- ============================================================
-- Heartbeat 主迴圈：能力掃描 + 進度條更新
-- ============================================================
local abiScanTimer = 0
local abiUpdateTimer = 0

RunService.Heartbeat:Connect(function(dt)
	flushHookTaskQueue()
	processPendingPlacements() -- 綁定放置塔 id + 記錄日誌（此處為 elevated capability）

	-- 遊戲時間時鐘前進（含速度倍率）：能力冷卻以遊戲時間計，x2/x3 下冷卻較快就緒
	abiGameClock = abiGameClock + dt * (lastDetectedSpeed > 0 and lastDetectedSpeed or 1)

	-- === 1. 掃描器（每 0.5 秒）===
	abiScanTimer = abiScanTimer + dt
	if abiScanTimer >= 0.5 then
		abiScanTimer = 0

		-- 花園塔防：塔在 workspace.Map.Entities（非 NTD 的 Map.Towers），entity 以 unit_id 命名、
		-- 帶 ID 屬性 = gameId。gameId 直接從 ID 屬性綁，不靠 NTD 的 place-hook 名稱配對。
		local Entities = EntitiesFolder
		if not (Entities and Entities.Parent) then
			local Map = workspace:FindFirstChild("Map")
			Entities = Map and Map:FindFirstChild("Entities")
		end

		if Entities then
			local seen = {}

			for _, child in ipairs(Entities:GetChildren()) do
				local unitId = child.Name
				if GTD_ABILITY_DATA[unitId] then
					seen[child] = true
					if not abiLiveTowers[child] then
						local order = abiNextOrder
						abiNextOrder = abiNextOrder + 1
						local gid = child:GetAttribute("ID")
						local info = {
							name = unitId,
							order = order,
							abilityKeys = towersWithAbility[unitId] or { unitId },
							gameId = (type(gid) == "number") and gid or nil,
							cooldowns = {},
						}
						abiLiveTowers[child] = info

						if info.gameId then
							abiModelByGameId[info.gameId] = child
							if abiGameIdCooldownHint[info.gameId] then
								for k, t0 in pairs(abiGameIdCooldownHint[info.gameId]) do
									info.cooldowns[k] = t0
								end
								abiGameIdCooldownHint[info.gameId] = nil
							end
						end

						if not abilityFrame.Visible then
							positionAbilityFrame()
							abilityFrame.Visible = true
						end
						buildAbilityCard(child)
					elseif not abiLiveTowers[child].gameId then
						-- entity 剛生成時 ID 屬性可能略晚才設，補綁
						local gid = child:GetAttribute("ID")
						if type(gid) == "number" then
							abiBindGameId(child, gid)
						end
					end
				end
			end

			local toRemove = {}
			for model in pairs(abiLiveTowers) do
				if model.Parent == nil or not seen[model] then
					table.insert(toRemove, model)
				end
			end
			for _, model in ipairs(toRemove) do
				local info = abiLiveTowers[model]
				if info and info.gameId then
					abiModelByGameId[info.gameId] = nil
				end
				removeAbilityCard(model)
				abiLiveTowers[model] = nil
			end
		else
			local toRemove = {}
			for model in pairs(abiLiveTowers) do
				if model.Parent == nil then
					table.insert(toRemove, model)
				end
			end
			for _, model in ipairs(toRemove) do
				local info = abiLiveTowers[model]
				if info and info.gameId then
					abiModelByGameId[info.gameId] = nil
				end
				removeAbilityCard(model)
				abiLiveTowers[model] = nil
			end
		end
	end

	-- === 2. 進度條更新（每 0.1 秒）===
	abiUpdateTimer = abiUpdateTimer + dt
	if abiUpdateTimer < 0.1 then
		return
	end
	abiUpdateTimer = 0

	for model, info in pairs(abiLiveTowers) do
		local card = abiTowerCards[model]
		if not card then
			continue
		end
		local hasId = info.gameId ~= nil
		local canUseAbility = isGameRunning and hasId

		for _, w in ipairs(card.widgets) do
			local t0 = info.cooldowns[w.key]

			if not t0 then
				w.barFill.Size = UDim2.new(1, 0, 1, 0)
				w.barFill.BackgroundColor3 = canUseAbility and Theme.Success or Theme.SurfaceHighlight
				w.barText.Text = canUseAbility and T("abilityReady") or T("abilityWaitId")
				w.fireBtn.TextColor3 = canUseAbility and Theme.Text or Theme.TextDim
				if canUseAbility and w.autoState.enabled then
					info.cooldowns[w.key] = abiGameClock - w.cd - 1
				end
				continue
			end

			local elapsed = abiGameClock - t0
			local remaining = math.max(0, w.cd - elapsed)
			local fillPct = math.min(elapsed / w.cd, 1)
				-- 顯示換算成真實秒數（÷ 當前速度），讓倒數貼近實際牆鐘時間
				local dispRemaining = remaining / (lastDetectedSpeed > 0 and lastDetectedSpeed or 1)

			w.barFill.Size = UDim2.new(fillPct, 0, 1, 0)
			w.barFill.BackgroundColor3 = remaining > 0 and Theme.Accent or Theme.Success
			w.barText.Text = remaining > 0 and T("abilityTimerFmt"):format(dispRemaining) or T("abilityReady")

			local canFire = canUseAbility and remaining == 0
			w.fireBtn.TextColor3 = canFire and Theme.Text or Theme.TextDim

			if
				canUseAbility
				and w.autoState.enabled
				and remaining == 0
				and elapsed >= w.cd + 0.5
				and w.autoFiredAt ~= t0
			then
				if invokeTowerAbilitySafely(model, w.key, w.cd) then
					w.autoFiredAt = t0
				end
			end
		end
	end
end)

-- ============================================================

InitTracker()
