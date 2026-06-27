-- 側邊通知模組
if not getgenv().NotificationModule then
	loadstring(game:HttpGet("https://gist.githubusercontent.com/Tseting-nil/08653e6aa9fc12a9f097bfb10e6654e7/raw/00001d614d928fc5dafce59133a012dd78419afd/%25E5%2581%25B4%25E9%2582%258A%25E9%2580%259A%25E7%259F%25A5%25E6%25A8%25A1%25E7%25B5%2584.lua"))()
end

if not getgenv().MOVEAPI then
  local MoveAPI = loadstring(game:HttpGet("https://gist.githubusercontent.com/Tseting-nil/494a4830fa6d3466596e4e01ca25bdee/raw/15a370f3f09720e1359601e05da6d9e0a24bcc23/%25E5%25B7%25A1%25E8%25B7%25AF%25E6%25A8%25A1%25E7%25B5%2584"))()
  MoveAPI:SetJumpEnabled(false)
  MoveAPI:SetDirectMovementDistance(500)
  getgenv().MOVEAPI = MoveAPI
end
local Move = getgenv().MOVEAPI

-- 生成當前腳本執行的唯一實例 ID，用於清理舊線程，防重複運行
local myInstanceId = tostring(tick()) .. "_" .. tostring(math.random(1000, 9999))
getgenv().GTD_UI_InstanceId = myInstanceId

-- 局部掛機狀態控制（每個 UI 獨立，每次加載皆從 0 開始）
local matchCount = 0
local alrEnabled = true

-- i18n
local HttpService = game:GetService("HttpService")
local currentLang = "zh"
do
	local API_VAR_PATH = "Tsetingnil_script/keysystem.json"
	pcall(function()
		if isfile and isfile(API_VAR_PATH) and readfile then
			local raw = readfile(API_VAR_PATH)
			if raw and raw ~= "" then
				local ok, data = pcall(HttpService.JSONDecode, HttpService, raw)
				local scriptLang = nil
				if ok and type(data) == "table" then
					scriptLang = data.script_language or data.language
				else
					scriptLang = raw:match('"script_language"%s*:%s*"([^"]+)"') or raw:match('"language"%s*:%s*"([^"]+)"')
				end
				
				if scriptLang then
					local sl = tostring(scriptLang):lower()
					if sl:find("chinese") or sl:find("zh") then
						currentLang = "zh"
					elseif sl:find("english") or sl:find("en") then
						currentLang = "en"
					end
				end
			end
		end
	end)
end

local i18n = {
	zh = {
		windowTitle    = "遊戲內介面",
		tab_main       = "Main",
		tab_playinfo   = "玩家資訊",
		tab_localscript = "本地腳本",
		tab_event      = "Event",
		event_collect_section = "自動撿取",
		event_collect_toggle = "自動撿取（Lucky Block／蛋／鑽石…）",
		event_collect_started = "自動撿取已啟動",
		event_collect_stopped = "自動撿取已停止",
		event_load_failed = "%s 載入失敗：%s",
		event_run_error = "%s 執行錯誤：%s",
		sectionStatus  = "當前狀態",
		envChecking    = "環境檢查中...",
		gameState      = "遊戲當前狀態",
		autoReplay     = "重開",
		sectionControl = "控制按鈕",
		btnToggleAutoReplay = "控制自動重開",
		btnManualReplay     = "手動重開",
		btnLobby            = "回大廳",
		noEnv          = "無環境",
		cantLeave      = "遊戲限制未完成戰鬥無法離開",
		stateLobby     = "當前遊戲狀態：在大廳",
		stateCombat    = "當前遊戲狀態：戰鬥中",
		stateGameOver  = "當前遊戲狀態：結束",
		stateUnknown   = "當前遊戲狀態：未知",
		envExist       = "環境檢查：本地環境存在",
		envNotExist    = "環境檢查：本地環境不存在",
		autoReplayOn   = "自動重新戰鬥：已開啟",
		autoReplayOff  = "自動重新戰鬥：未開啟",
		queueRemaining = "佇列剩餘：",
		queueNA        = "---",
		queueOvertime  = "（超時）",
		localscript_path           = "路徑: ",
		localscript_list           = "腳本列表",
		localscript_refresh        = "重新整理",
		localscript_run            = "執行",
		localscript_no_scripts     = "目錄中無腳本",
		localscript_done           = "執行完成",
		localscript_error          = "執行錯誤",
		localscript_refreshed      = "清單已重新整理",
		localscript_delete         = "刪除",
		localscript_confirm_title  = "確認刪除?",
		localscript_confirm_title2 = "⚠ 此操作無法復原",
		localscript_confirm_yes    = "確認",
		localscript_confirm_no     = "取消",
		localscript_delete_final   = "永久刪除",
		localscript_deleted        = "已刪除",
		localscript_delete_error   = "刪除失敗",
		localscript_info           = "i",
		localscript_info_no_block  = "（無資訊區塊）",
		localscript_info_read_fail = "讀取失敗",
		localscript_info_close     = "關閉",
		localscript_info_copy      = "複製",
		localscript_info_copied    = "已複製到剪貼簿",
		localscript_save_running    = "儲存正在運行的腳本",
		localscript_save            = "儲存",
		localscript_save_name_title = "輸入儲存名稱",
		localscript_save_name_ph    = "腳本名稱...",
		localscript_save_success    = "已儲存",
		localscript_save_error      = "儲存失敗",
		localscript_save_no_running = "無正在運行的腳本",
		replayConfirm_title    = "確認手動重開?",
		lobbyConfirm_title     = "確認回到大廳?",
		alreadyRunning         = "自動化佇列已在運行中",
		playCashInit           = "金錢：---",
		playSeedsInit          = "種子：---",
		playTotalSeedsInit     = "累計賺取種子：---",
		playGamesWonInit       = "贏得場數：---",
		playEnemiesKilledInit  = "總擊殺敵人：---",
		playTimePlayedInit     = "總遊戲時長：---",
		playBeggarDonatedInit  = "乞丐已捐贈：---",
		playCurrencyNotFound   = "找不到玩家貨幣資料",
		playCashFmt            = "金錢：%s",
		playSeedsFmt           = "種子：%s",
		playTotalSeedsFmt      = "累計賺取種子：%s",
		playGamesWonFmt        = "贏得場數：%s",
		playEnemiesKilledFmt   = "總擊殺敵人：%s",
		playTimePlayedFmt      = "總遊戲時長：%s",
		playBeggarDonatedFmt   = "乞丐已捐贈：%s",
		tab_settings              = "設置",
		keyTimeLabel              = "密鑰剩餘時間：",
		keyTimePerm               = "永久",
		keyExpired                = "已過期",
		unitDay = "天", unitHour = "時", unitMin = "分",
		key_update_btn            = "更新密鑰",
		key_no_update_needed      = "密鑰剩餘時間大於 1 天，無需更新密鑰",
		instantUpdate             = "自動更新",
		onText = "開", offText = "關",
		instantUpdateConfirmTitle = "確認關閉自動更新？",
		instantUpdateConfirmDesc  = "關閉後主腳本只會在『大廳』更新，掛機中途不會被打斷。",
		tab_stats              = "統計",
		stats_section          = "累計統計",
		stats_wins             = "勝：",
		stats_losses           = "輸：",
		stats_total            = "總場：",
		stats_winrate          = "勝率：",
		stats_money            = "賺取種子：",
		stats_lastReset        = "上次重置：",
		stats_reset            = "重置統計",
		stats_reset_confirm    = "確認重置統計？",
		stats_never_reset      = "從未重置",
		autoLobbyReplay_title = "自動重新開局設定",
		autoLobbyReplay_label = "自動重開場數：%d / %d",
		autoLobbyReplay_btn_on = "自動重開：已開啟",
		autoLobbyReplay_btn_off = "自動重開：已關閉",
		autoLobbyReplay_btn_reset = "手動重置場數",
		autoLobbyReplay_reset_msg = "場數已手動重設為 0",
		autoLobbyReplay_toggle = "自動重開",
		rotation_pool_header = "輪換腳本池（可多選，每 N 場換一支）",
		rotation_interval_label = "每幾場輪換",
		rotation_refresh_btn = "重新整理清單",
		rotation_save_btn = "儲存輪換設定",
		rotation_no_scripts = "Script 資料夾內沒有可用腳本",
		rotation_saved_msg = "輪換設定已儲存：%d 支腳本，每 %d 場輪換",
		rotation_empty_pool = "未選任何輪換腳本，將以同一支腳本重開",
		rotation_picked_msg = "本輪換到腳本：%s",
		rotation_apply_fail = "套用輪換腳本失敗，沿用目前腳本",
	},
	en = {
		windowTitle    = "In-Game UI",
		tab_main       = "Main",
		tab_playinfo   = "Player Info",
		tab_localscript = "Local Script",
		tab_event      = "Event",
		event_collect_section = "Auto Collect",
		event_collect_toggle = "Auto Collect (Lucky Block / Egg / Diamond...)",
		event_collect_started = "Auto Collect started",
		event_collect_stopped = "Auto Collect stopped",
		event_load_failed = "%s load failed: %s",
		event_run_error = "%s run error: %s",
		sectionStatus  = "Current Status",
		envChecking    = "Checking environment...",
		gameState      = "Game State",
		autoReplay     = "Auto Replay",
		sectionControl = "Control Buttons",
		btnToggleAutoReplay = "Toggle Auto Replay",
		btnManualReplay     = "Replay",
		btnLobby            = "To Lobby",
		noEnv          = "No Environment",
		cantLeave      = "Cannot leave mid-combat",
		stateLobby     = "Game State: In Lobby",
		stateCombat    = "Game State: In Combat",
		stateGameOver  = "Game State: Game Over",
		stateUnknown   = "Game State: Unknown",
		envExist       = "Environment: Local env exists",
		envNotExist    = "Environment: Local env missing",
		autoReplayOn   = "Auto Replay: Enabled",
		autoReplayOff  = "Auto Replay: Disabled",
		queueRemaining = "Queue Remaining: ",
		queueNA        = "---",
		queueOvertime  = " (overtime)",
		localscript_path           = "Path: ",
		localscript_list           = "Script List",
		localscript_refresh        = "Refresh",
		localscript_run            = "Run",
		localscript_no_scripts     = "No scripts in directory",
		localscript_done           = "Executed",
		localscript_error          = "Error",
		localscript_refreshed      = "List refreshed",
		localscript_delete         = "Delete",
		localscript_confirm_title  = "Confirm Delete?",
		localscript_confirm_title2 = "⚠ This cannot be undone",
		localscript_confirm_yes    = "Confirm",
		localscript_confirm_no     = "Cancel",
		localscript_delete_final   = "Delete Forever",
		localscript_deleted        = "Deleted",
		localscript_delete_error   = "Delete failed",
		localscript_info           = "i",
		localscript_info_no_block  = "(No info block)",
		localscript_info_read_fail = "Read failed",
		localscript_info_close     = "Close",
		localscript_info_copy      = "Copy",
		localscript_info_copied    = "Copied to clipboard",
		localscript_save_running    = "Save Running Script",
		localscript_save            = "Save",
		localscript_save_name_title = "Enter Save Name",
		localscript_save_name_ph    = "Script name...",
		localscript_save_success    = "Saved",
		localscript_save_error      = "Save failed",
		localscript_save_no_running = "No running script",
		replayConfirm_title    = "Confirm Replay?",
		lobbyConfirm_title     = "Confirm back to Lobby?",
		alreadyRunning         = "Automation queue is already running",
		playCashInit           = "Cash: ---",
		playSeedsInit          = "Seeds: ---",
		playTotalSeedsInit     = "Total Seeds Earned: ---",
		playGamesWonInit       = "Games Won: ---",
		playEnemiesKilledInit  = "Total Enemies Killed: ---",
		playTimePlayedInit     = "Total Time Played: ---",
		playBeggarDonatedInit  = "Seeds Donated to Beggar: ---",
		playCurrencyNotFound   = "Player currency data not found",
		playCashFmt            = "Cash: %s",
		playSeedsFmt           = "Seeds: %s",
		playTotalSeedsFmt      = "Total Seeds Earned: %s",
		playGamesWonFmt        = "Games Won: %s",
		playEnemiesKilledFmt   = "Total Enemies Killed: %s",
		playTimePlayedFmt      = "Total Time Played: %s",
		playBeggarDonatedFmt   = "Seeds Donated to Beggar: %s",
		tab_settings              = "Settings",
		keyTimeLabel              = "Key time left: ",
		keyTimePerm               = "Permanent",
		keyExpired                = "Expired",
		unitDay = "d", unitHour = "h", unitMin = "m",
		key_update_btn            = "Update Key",
		key_no_update_needed      = "Key remaining time is > 1 day, no need to update",
		instantUpdate             = "Auto Update",
		onText = "ON", offText = "OFF",
		instantUpdateConfirmTitle = "Disable auto update?",
		instantUpdateConfirmDesc  = "When off, the main script only updates in the LOBBY — farming won't be interrupted.",
		tab_stats              = "Stats",
		stats_section          = "Cumulative Stats",
		stats_wins             = "Wins: ",
		stats_losses           = "Losses: ",
		stats_total            = "Total: ",
		stats_winrate          = "Win Rate: ",
		stats_money            = "Seeds Earned: ",
		stats_lastReset        = "Last Reset: ",
		stats_reset            = "Reset Stats",
		stats_reset_confirm    = "Confirm Reset?",
		stats_never_reset      = "Never reset",
		autoLobbyReplay_title = "Auto Lobby Replay Config",
		autoLobbyReplay_label = "Auto Lobby Replay: %d / %d",
		autoLobbyReplay_btn_on = "Auto Replay: ON",
		autoLobbyReplay_btn_off = "Auto Replay: OFF",
		autoLobbyReplay_btn_reset = "Reset Match Count",
		autoLobbyReplay_reset_msg = "Match count has been reset to 0",
		autoLobbyReplay_toggle = "Auto Lobby Replay",
		rotation_pool_header = "Script Rotation Pool (multi-select, swap every N games)",
		rotation_interval_label = "Games per rotation",
		rotation_refresh_btn = "Refresh List",
		rotation_save_btn = "Save Rotation Config",
		rotation_no_scripts = "No scripts available in the Script folder",
		rotation_saved_msg = "Rotation saved: %d scripts, swap every %d games",
		rotation_empty_pool = "No rotation scripts selected; restarting with the same script",
		rotation_picked_msg = "Rotated to script: %s",
		rotation_apply_fail = "Failed to apply rotation script; keeping current script",
	},
}

local L = i18n[currentLang]
local fontSize = currentLang == "en" and 14 or nil

local Msg = getgenv().NotificationModule
local GTD_API = nil
local Scripttable = nil
local Mainfunction = nil

-- ========================================================================== --
-- GUI

local ReGui = loadstring(game:HttpGet("https://gist.githubusercontent.com/Tseting-nil/169b7303e1418cb301bad5ab427e9351/raw/93e90190f628387b545eef62b49e4ce146d1dad8/GUI:ReGui"))()

local UserInputService = game:GetService("UserInputService")
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local windowSize = currentLang == "en" and UDim2.new(0, 325, 0, 280) or UDim2.new(0, 325, 0, 280)

local TabsWindow =  ReGui:TabsWindow({
	Title = L.windowTitle,
	Size = windowSize,
	NoScroll = true,
})

local Tabs = {}

for _, Name in ipairs({
	L.tab_main,
	L.tab_playinfo,
	L.tab_localscript,
	L.tab_settings,
	L.tab_event
}) do
	local Tab = TabsWindow:CreateTab({
		Name = Name
	})
	table.insert(Tabs, Tab)
end

-- 修改 Tab 字體和大小
task.spawn(function()
	task.wait(0.1)
	for _, tab in ipairs(Tabs) do
		local tabButton = tab.TabButton.Button
		local label = tabButton:FindFirstChildWhichIsA("TextLabel")
		if label then
			label.TextSize = currentLang == "en" and 14 or 18
			label.Font = Enum.Font.Ubuntu
		end
	end
end)

local Tab_main = Tabs[1]:ScrollingCanvas({
	Fill = true,
	UiPadding = UDim.new(0, 0)
})

local Tab_playinfo = Tabs[2]:ScrollingCanvas({
	Fill = true,
	UiPadding = UDim.new(0, 0)
})

local Tab_Localscript = Tabs[3]:ScrollingCanvas({
	Fill = true,
	UiPadding = UDim.new(0, 0)
})

local Tab_settings = Tabs[4]:ScrollingCanvas({
	Fill = true,
	UiPadding = UDim.new(0, 0)
})

local Tab_event = Tabs[5]:ScrollingCanvas({
	Fill = true,
	UiPadding = UDim.new(0, 0)
})

-- ===== 設置分頁：密鑰剩餘時間 + 即時更新開關 =====
local SETTINGS_API_VAR = "Tsetingnil_script/keysystem.json"

local function readApiVarTable()
	local ok, data = pcall(function()
		if isfile and readfile and isfile(SETTINGS_API_VAR) then
			return HttpService:JSONDecode(readfile(SETTINGS_API_VAR))
		end
	end)
	return (ok and type(data) == "table") and data or {}
end

local function fmtKeyRemaining()
	local exp = tonumber(readApiVarTable().expires_at)
	if not exp then return L.keyTimeLabel .. L.keyTimePerm end
	if exp > 1e10 then exp = math.floor(exp / 1000) end -- 毫秒→秒
	local left = exp - os.time()
	if left <= 0 then return L.keyTimeLabel .. L.keyExpired end
	local d = math.floor(left / 86400)
	local h = math.floor((left % 86400) / 3600)
	local m = math.floor((left % 3600) / 60)
	return string.format("%s%d%s %d%s %d%s", L.keyTimeLabel, d, L.unitDay, h, L.unitHour, m, L.unitMin)
end

Tab_settings:Separator({ Text = L.tab_settings })

local KeyTime_Label = Tab_settings:Label({
	Text = fmtKeyRemaining(),
	TextSize = fontSize or 16,
	NoTheme = true,
	TextColor3 = Color3.fromRGB(240, 240, 240),
})

local KeyTime_UpdateBtn = Tab_settings:Button({
	Text = L.key_update_btn,
	Callback = function()
		getgenv().AutoVerify = false
		local exp = tonumber(readApiVarTable().expires_at)
		if exp then
			if exp > 1e10 then exp = math.floor(exp / 1000) end
			local currentLeft = exp - os.time()
			if currentLeft < 86400 then
				loadstring(game:HttpGet("https://raw.githubusercontent.com/Tseting-nil/Garden-Tower-Defense-script/refs/heads/main/%E5%AF%86%E9%91%B0%E7%B3%BB%E7%B5%B1.lua"))()
			else
				Msg:Warning(L.key_no_update_needed)
			end
		end
		getgenv().AutoVerify = true
	end
})
KeyTime_UpdateBtn.Visible = false

-- 初始更新按鈕顯示狀態
pcall(function()
	local exp = tonumber(readApiVarTable().expires_at)
	if exp then
		if exp > 1e10 then exp = math.floor(exp / 1000) end
		local left = exp - os.time()
		if left < 86400 then
			KeyTime_UpdateBtn.Visible = true
		end
	end
end)

Tab_main:Separator({
	Text = L.sectionStatus
})

local API_Check_Label = Tab_main:Label({
	Text = L.envChecking,
	TextSize = fontSize or 18,
	NoTheme = true,
	TextColor3 = Color3.fromRGB(240, 240, 240),
})

local GameState_Label = Tab_main:Label({
	Text = L.gameState,
	TextSize = fontSize or 16,
	NoTheme = true,
	TextColor3 = Color3.fromRGB(240, 240, 240),
})

local AutoReplay_Label = Tab_main:Label({
	Text = L.autoReplay,
	TextSize = fontSize or 16,
	NoTheme = true,
	TextColor3 = Color3.fromRGB(240, 240, 240),
})

local QueueRemaining_Label = Tab_main:Label({
	Text = L.queueRemaining .. L.queueNA,
	TextSize = fontSize or 16,
	NoTheme = true,
	TextColor3 = Color3.fromRGB(240, 240, 240),
})

Tab_main:Separator({
	Text = L.sectionControl
})

local ROW_QK = Tab_main:Row()

ROW_QK:Button({
	Text = L.btnToggleAutoReplay,
	TextSize = fontSize or 18,
	Callback = function()
		if getgenv().GTD then
			if Scripttable.autoReplay then
				Mainfunction.AutoReplay(false)
			else
				Mainfunction.AutoReplay(true)
			end
		else
			Msg:Warning(L.noEnv)
		end
	end,
	DoubleClick = false,
})

ROW_QK:Button({
	Text = L.btnManualReplay,
	TextSize = fontSize or 18,
	Callback = function(btn)
		if getgenv().GTD then
			if Scripttable and Scripttable.running then
				Msg:Warning(L.alreadyRunning or "自動化佇列已在運行中")
				return
			end
			local Popup = Tab_main:PopupModal({ RelativeTo = btn })
			Popup:Separator({ Text = L.replayConfirm_title })
			local PopupRow = Popup:Row({ Expanded = true })
			PopupRow:Button({
				Text = L.localscript_confirm_yes,
				Callback = function()
					Popup:ClosePopup()
					task.spawn(function()
						-- 1. 獲取 RestartGame 遠端函數
						local RF = game:GetService("ReplicatedStorage"):WaitForChild("RemoteFunctions", 5)
						local RestartGame = RF and RF:WaitForChild("RestartGame", 3)

						if not RestartGame then
							Msg:Warning("找不到 RestartGame 遠端函數，改為直接執行佇列")
							pcall(Mainfunction.ExecuteQueue)
							return
						end

						-- 2. 檢查介面：如果遊戲已結束，等待結算面板/Actions 面板載入
						if Mainfunction.IsGameOver and Mainfunction.IsGameOver() then
							task.wait(1.0)
						end

						-- 3. 觸發重開
						local gstBefore = workspace:GetAttribute("GameStartTime")
						local success = false
						for attempt = 1, 3 do
							pcall(function()
								RestartGame:InvokeServer()
							end)
							
							local deadline = os.clock() + 10
							while os.clock() < deadline do
								local gstNow = workspace:GetAttribute("GameStartTime")
								if gstNow ~= gstBefore then
									success = true
									break
								end
								task.wait(0.5)
							end
							if success then break end
						end

						-- 4. 如果沒有重載，則在當前 VM 下啟動佇列
						if success then
							task.wait(1.0)
							pcall(Mainfunction.ExecuteQueue)
						else
							Msg:Warning("重開超時，直接嘗試在當前局執行佇列")
							pcall(Mainfunction.ExecuteQueue)
						end
					end)
				end,
			})
			PopupRow:Button({
				Text = L.localscript_confirm_no,
				Callback = function()
					Popup:ClosePopup()
				end,
			})
		else
			Msg:Warning(L.noEnv)
		end
	end,
	DoubleClick = false,
})

local function returnToLobby()
	pcall(function()
		game:GetService("TeleportService"):Teleport(108533757090220)
	end)
end

ROW_QK:Button({
	Text = L.btnLobby,
	TextSize = fontSize or 18,
	Callback = function(btn)
		if getgenv().GTD then
			local Popup = Tab_main:PopupModal({ RelativeTo = btn })
			Popup:Separator({ Text = L.lobbyConfirm_title or "確認回到大廳?" })
			local PopupRow = Popup:Row({ Expanded = true })
			PopupRow:Button({
				Text = L.localscript_confirm_yes,
				Callback = function()
					Popup:ClosePopup()
					returnToLobby()
				end,
			})
			PopupRow:Button({
				Text = L.localscript_confirm_no,
				Callback = function()
					Popup:ClosePopup()
				end,
			})
		else
			Msg:Warning(L.noEnv)
		end
	end,
	DoubleClick = false,
})

-- ===== 腳本輪換（每 N 場換一支錄製腳本，打散防巨集「每局同指紋」特徵）=====
-- 池 = 使用者在下方面板勾選的腳本（Script 資料夾內檔名，可多選）。達到 interval 場時：
-- 以隨機種子從池中挑一支（排除上次挑中的，避免連續重複）→ 把該腳本內容覆寫進
-- main_<UserId>.lua（queue_on_teleport 的 resume 會 loadfile 它）→ 存 lastPicked → 回大廳自動執行。
-- 設定持久化於 Rotation_Config.json，跨傳送有效（getgenv 不過傳送，故用檔案）。
local Rotation = {
	configPath = "Tsetingnil_script/GTD/Config/Rotation_Config.json",
	scriptDir  = "Tsetingnil_script/GTD/Script",
	pool       = {},   -- { "scriptA.lua", ... }
	interval   = 20,
	lastPicked = nil,
}

function Rotation.ensureFolder()
	pcall(function()
		if not isfolder or not makefolder then return end
		if not isfolder("Tsetingnil_script") then makefolder("Tsetingnil_script") end
		if not isfolder("Tsetingnil_script/GTD") then makefolder("Tsetingnil_script/GTD") end
		if not isfolder("Tsetingnil_script/GTD/Config") then makefolder("Tsetingnil_script/GTD/Config") end
	end)
end

-- 以玩家 UserId 當外層 key：同帳號在大廳/關卡內共用同一份（UserId 不隨場景變），
-- 不同帳號各自獨立（多帳號各有各的輪換設定）。
local function rotationUserKey()
	return tostring(game:GetService("Players").LocalPlayer.UserId)
end

function Rotation.load()
	local ok, data = pcall(function()
		if not (isfile and isfile(Rotation.configPath) and readfile) then return nil end
		return HttpService:JSONDecode(readfile(Rotation.configPath))
	end)
	if ok and type(data) == "table" then
		-- 外層為 UserId 的新格式
		local entry = data[rotationUserKey()]
		if type(entry) == "table" then
			Rotation.pool       = type(entry.pool) == "table" and entry.pool or {}
			Rotation.interval   = tonumber(entry.interval) or 30
			Rotation.lastPicked = entry.lastPicked
		end
	end
	if Rotation.interval < 1 then Rotation.interval = 1 end
end

function Rotation.save()
	pcall(function()
		if not writefile then return end
		Rotation.ensureFolder()
		-- 讀回現有檔案，保留其他 UserId 的設定，只覆寫本 UserId 區段
		local all = {}
		local ok, existing = pcall(function()
			if isfile and isfile(Rotation.configPath) and readfile then
				return HttpService:JSONDecode(readfile(Rotation.configPath))
			end
		end)
		if ok and type(existing) == "table" then
			all = existing
		end
		all[rotationUserKey()] = {
			pool       = Rotation.pool,
			interval   = Rotation.interval,
			lastPicked = Rotation.lastPicked,
		}
		writefile(Rotation.configPath, HttpService:JSONEncode(all))
	end)
end

-- 列出 Script 資料夾內可選腳本（.lua），回傳排序後的檔名陣列
function Rotation.listScripts()
	local names = {}
	local ok, files = pcall(listfiles, Rotation.scriptDir)
	if ok and files then
		for _, fp in ipairs(files) do
			local name = fp:match("([^/\\]+)$") or fp
			if name:match("%.lua$") then
				names[#names + 1] = name
			end
		end
	end
	table.sort(names)
	return names
end

function Rotation.inPool(name)
	for _, n in ipairs(Rotation.pool) do
		if n == name then return true end
	end
	return false
end

function Rotation.setInPool(name, on)
	if on then
		if not Rotation.inPool(name) then Rotation.pool[#Rotation.pool + 1] = name end
	else
		for i = #Rotation.pool, 1, -1 do
			if Rotation.pool[i] == name then table.remove(Rotation.pool, i) end
		end
	end
end

-- 從池中隨機挑下一支（排除上次挑中的；池<=1 不排除）。回傳檔名或 nil（池為空）。
function Rotation.pickNext()
	local pool = Rotation.pool
	if #pool == 0 then return nil end
	if #pool == 1 then return pool[1] end
	local candidates = {}
	for _, n in ipairs(pool) do
		if n ~= Rotation.lastPicked then candidates[#candidates + 1] = n end
	end
	if #candidates == 0 then candidates = pool end
	math.randomseed(os.time() + math.floor((os.clock() % 1) * 1e6))
	return candidates[math.random(1, #candidates)]
end

-- 把選中的腳本內容覆寫進 main_<UserId>.lua（resume 的 loadfile 目標）。回傳 true/false。
-- 直接複製 Script/<name>（包裝啟動器）：resume 載入後它會自我 bootstrap GTD、
-- 並 SaveLocalScript(內層) 把 main 修正回內層腳本，與手動執行該存檔完全一致。
function Rotation.applyToMain(name)
	local applied = false
	pcall(function()
		local srcPath = Rotation.scriptDir .. "/" .. name
		if not (isfile and isfile(srcPath) and readfile) then return end
		local content = readfile(srcPath)
		if not content or content == "" then return end
		local userId = tostring(game:GetService("Players").LocalPlayer.UserId)
		local mainFW = "Tsetingnil_script/GTD/main_" .. userId .. ".lua"
		local mainBS = "Tsetingnil_script\\GTD\\main_" .. userId .. ".lua"
		local target = (isfile and isfile(mainBS) and not isfile(mainFW)) and mainBS or mainFW
		writefile(target, content)
		applied = true
	end)
	return applied
end

Rotation.load()

-- === 自動重新開局 (防記憶體崩潰) GUI 元件 ===
Tab_main:Separator({
	Text = L.autoLobbyReplay_title
})

local AutoLobbyReplay_CountLabel = Tab_main:Label({
	Text = string.format(L.autoLobbyReplay_label, 0, Rotation.interval),
	TextSize = fontSize or 16,
	NoTheme = true,
	TextColor3 = Color3.fromRGB(240, 240, 240),
})

local AutoLobbyReplay_ROW = Tab_main:Row()
local AutoLobbyReplay_ToggleBox = AutoLobbyReplay_ROW:Radiobox({
	Value = alrEnabled,
	Label = L.autoLobbyReplay_toggle or "自動重開",
	Callback = function(self, Value)
		alrEnabled = Value
	end,
})

local AutoLobbyReplay_ResetBtn = AutoLobbyReplay_ROW:SmallButton({
	Text = L.autoLobbyReplay_btn_reset,
	TextSize = fontSize or 16,
	Callback = function()
		matchCount = 0
		if Msg and Msg.Success then
			Msg:Success(L.autoLobbyReplay_reset_msg)
		end
	end,
	DoubleClick = false,
})

-- === 腳本輪換池 UI（可折疊面板 = 多選下拉；每支錄製一個勾選框）===
do
	local rotHeader = Tab_main:CollapsingHeader({ Title = L.rotation_pool_header, Collapsed = true })

	rotHeader:InputInt({
		Value = Rotation.interval,
		Label = L.rotation_interval_label,
		Increment = 1,
		Minimum = 1,
		Maximum = 999,
		Callback = function(_, v)
			Rotation.interval = math.max(1, math.floor(tonumber(v) or 30))
		end,
	})

	local rotTable = rotHeader:Table()
	local function buildRotList()
		rotTable:ClearRows()
		local names = Rotation.listScripts()
		if #names == 0 then
			rotTable:NextRow():Column():Label({ Text = L.rotation_no_scripts })
			return
		end
		for _, name in ipairs(names) do
			rotTable:NextRow():Column():Checkbox({
				Value = Rotation.inPool(name),
				Label = name,
				Callback = function(_, on)
					Rotation.setInPool(name, on)
				end,
			})
		end
	end
	buildRotList()

	local rotBtnRow = rotHeader:Row()
	rotBtnRow:Button({
		Text = L.rotation_refresh_btn,
		Callback = function()
			buildRotList()
		end,
	})
	rotBtnRow:Button({
		Text = L.rotation_save_btn,
		Callback = function()
			Rotation.save()
			if Msg and Msg.Success then
				Msg:Success(string.format(L.rotation_saved_msg, #Rotation.pool, Rotation.interval))
			end
		end,
	})
end

if getgenv().GTD then
	GTD_API = getgenv().GTD
	Scripttable = getgenv().GTD.Scripttable
	Mainfunction = getgenv().GTD.Mainfunction
end

local function GetGameState()
	if not getgenv().GTD then return "Unknown" end
	if not Mainfunction.IsInGame() then return "Lobby" end
	if Mainfunction.IsGameOver() then return "GameOver" end
	return "Combat"
end

local function ReGameStateLabel()
	local GameState = GetGameState()
	if GameState == "Lobby" then
		GameState_Label.Text = L.stateLobby
	elseif GameState == "Combat" then
		GameState_Label.Text = L.stateCombat
	elseif GameState == "GameOver" then
		GameState_Label.Text = L.stateGameOver
	else
		GameState_Label.Text = L.stateUnknown
	end
end

local function UpdateQueueLabels()
	if GTD_API and GTD_API.GetQueueRemaining then
		local remaining = GTD_API.GetQueueRemaining()
		if remaining then
			if remaining < 0 then
				QueueRemaining_Label.Text = L.queueRemaining .. string.format("%d s", -remaining) .. L.queueOvertime
			else
				QueueRemaining_Label.Text = L.queueRemaining .. string.format("%d s", remaining)
			end
		else
			QueueRemaining_Label.Text = L.queueRemaining .. L.queueNA
		end
	else
		QueueRemaining_Label.Text = L.queueRemaining .. L.queueNA
	end
end

local updatePlayInfo

task.spawn(function()
	while true do
		if getgenv().GTD_UI_InstanceId ~= myInstanceId then break end
		if getgenv().GTD then
			GTD_API = getgenv().GTD
			Scripttable = getgenv().GTD.Scripttable
			Mainfunction = getgenv().GTD.Mainfunction
			API_Check_Label.Text = L.envExist
			if Scripttable.autoReplay then
				AutoReplay_Label.Text = L.autoReplayOn
			else
				AutoReplay_Label.Text = L.autoReplayOff
			end
			task.spawn(ReGameStateLabel)
			task.spawn(UpdateQueueLabels)
		else
			API_Check_Label.Text = L.envNotExist
			AutoReplay_Label.Text = L.noEnv
		end
		
		-- 定時更新自動重開場數 UI
		pcall(function()
			AutoLobbyReplay_CountLabel.Text = string.format(L.autoLobbyReplay_label, matchCount, Rotation.interval)
		end)

		pcall(function()
			KeyTime_Label.Text = fmtKeyRemaining()
			local exp = tonumber(readApiVarTable().expires_at)
			local visible = false
			if exp then
				if exp > 1e10 then exp = math.floor(exp / 1000) end
				local left = exp - os.time()
				if left < 86400 then
					visible = true
				end
			end
			KeyTime_UpdateBtn.Visible = visible
		end)
		pcall(function() if updatePlayInfo then updatePlayInfo() end end)
		task.wait(1)
	end
end)

-- ========================================================================== --
-- Tab_playinfo
local function formatWithCommas(n)
	if not n then return "---" end
	local s = tostring(math.floor(tonumber(n) or 0))
	return s:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
end

local function formatDuration(seconds)
	if not seconds or seconds == 0 then return "---" end
	local d = math.floor(seconds / 86400)
	local h = math.floor((seconds % 86400) / 3600)
	local m = math.floor((seconds % 3600) / 60)
	if currentLang == "zh" then
		return string.format("%d天 %02d時 %02d分", d, h, m)
	else
		return string.format("%dd %02dh %02dm", d, h, m)
	end
end

local play_seeds = Tab_playinfo:Label({
	Text = L.playSeedsInit,
	TextSize = fontSize or 16,
	NoTheme = true,
	TextColor3 = Color3.fromRGB(240, 240, 240),
})

local play_time_played = Tab_playinfo:Label({
	Text = L.playTimePlayedInit,
	TextSize = fontSize or 16,
	NoTheme = true,
	TextColor3 = Color3.fromRGB(240, 240, 240),
})

updatePlayInfo = function()
	local lp = game:GetService("Players").LocalPlayer
	local leaderstats = lp:FindFirstChild("leaderstats")
	local seedsVal = leaderstats and leaderstats:FindFirstChild("Seeds")
	
	-- 獲取 Seeds (優先 ClientDataHandler，備用方案為 leaderstats)
	local seedsCount = nil
	local ok, data = pcall(function()
		local ClientDataHandler = require(game.Players.LocalPlayer.PlayerGui.LogicHolder.ClientLoader.Modules.ClientDataHandler)
		return type(ClientDataHandler.GetData) == "function" and ClientDataHandler.GetData() or ClientDataHandler:GetData()
	end)
	if ok and data and data.Seeds then
		seedsCount = data.Seeds
	elseif seedsVal then
		seedsCount = seedsVal.Value
	end
	
	local timePlayed = "---"
	if ok and data then
		if data.TotalTimePlayed then timePlayed = formatDuration(data.TotalTimePlayed) end
	end

	local seedsText = "---"
	if seedsCount then
		if type(seedsCount) == "number" then
			seedsText = formatWithCommas(seedsCount)
		else
			seedsText = tostring(seedsCount)
		end
	end
	play_seeds.Text = string.format(L.playSeedsFmt, seedsText)
	play_time_played.Text = string.format(L.playTimePlayedFmt, timePlayed)
end

task.spawn(function()
	local lp = game:GetService("Players").LocalPlayer
	local leaderstats = lp:WaitForChild("leaderstats", 15)
	if not leaderstats then
		warn(L.playCurrencyNotFound)
		return
	end
	
	local seedsVal = leaderstats:WaitForChild("Seeds", 5)
	if seedsVal then seedsVal:GetPropertyChangedSignal("Value"):Connect(updatePlayInfo) end
	updatePlayInfo()
end)

-- ========================================================================== --
-- Tab_stats (合併至 Tab_playinfo 底下)
-- ========================================================================== --
local STATS_DATA_PATH = "Tsetingnil_script/GTD/Config/Ingame_Data_Config.json"
local Stats_LocalPlayer = game:GetService("Players").LocalPlayer
local Stats_playerId    = tostring(Stats_LocalPlayer.UserId)

local function statsEnsureFolder()
	pcall(function()
		if not isfolder or not makefolder then return end
		if not isfolder("Tsetingnil_script") then makefolder("Tsetingnil_script") end
		if not isfolder("Tsetingnil_script/GTD") then makefolder("Tsetingnil_script/GTD") end
		if not isfolder("Tsetingnil_script/GTD/Config") then makefolder("Tsetingnil_script/GTD/Config") end
	end)
end

local function statsReadAll()
	local ok, data = pcall(function()
		if not (isfile and isfile(STATS_DATA_PATH) and readfile) then return {} end
		return HttpService:JSONDecode(readfile(STATS_DATA_PATH))
	end)
	return (ok and type(data) == "table") and data or {}
end

local function statsWriteAll(allData)
	pcall(function()
		if not writefile then return end
		statsEnsureFolder()
		writefile(STATS_DATA_PATH, HttpService:JSONEncode(allData))
	end)
end

local function statsGetOrInit(allData)
	if not allData[Stats_playerId] then
		allData[Stats_playerId] = {
			lastReset = os.time(),
			wins      = 0,
			losses    = 0,
			money     = 0,
		}
		statsWriteAll(allData)
	end
	return allData[Stats_playerId]
end

local function statsSave(isWin, earned)
	local allData = statsReadAll()
	local pd = statsGetOrInit(allData)
	if isWin then
		pd.wins = pd.wins + 1
	else
		pd.losses = pd.losses + 1
	end
	pd.money = pd.money + earned
	allData[Stats_playerId] = pd
	statsWriteAll(allData)
	return pd
end

local function statsReset()
	local allData = statsReadAll()
	allData[Stats_playerId] = {
		lastReset = os.time(),
		wins      = 0,
		losses    = 0,
		money     = 0,
	}
	statsWriteAll(allData)
	return allData[Stats_playerId]
end

local function statsParseEarned(frame)
	local earned = 0
	pcall(function()
		for _, child in ipairs(frame:GetDescendants()) do
			if child:IsA("TextLabel") then
				local text = child.Text
				local numStr = text:match("%+([%d,%.]+)")
				if numStr then
					local num = tonumber((numStr:gsub(",", "")))
					if num then
						earned = earned + num
					end
				end
			end
		end
	end)
	return earned
end

local function statsComma(n)
	local s = tostring(math.floor(n))
	return s:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
end

local function statsFmtWinRate(wins, losses)
	local total = wins + losses
	if total == 0 then return "0.0%" end
	return string.format("%.1f%%", wins / total * 100)
end

local function statsFmtTime(ts)
	if not ts or ts == 0 then return L.stats_never_reset end
	return os.date("%Y-%m-%d %H:%M:%S", ts)
end

-- 初始載入
local _statsAllData = statsReadAll()
local _statsPd      = statsGetOrInit(_statsAllData)

-- UI (合併至 Tab_playinfo)
Tab_playinfo:Separator({ Text = L.stats_section })

local statsLabel_wins = Tab_playinfo:Label({
	Text = L.stats_wins .. _statsPd.wins,
	TextSize = fontSize or 16,
	NoTheme = true,
	TextColor3 = Color3.fromRGB(240, 240, 240),
})

local statsLabel_losses = Tab_playinfo:Label({
	Text = L.stats_losses .. _statsPd.losses,
	TextSize = fontSize or 16,
	NoTheme = true,
	TextColor3 = Color3.fromRGB(240, 240, 240),
})

local statsLabel_total = Tab_playinfo:Label({
	Text = L.stats_total .. (_statsPd.wins + _statsPd.losses),
	TextSize = fontSize or 16,
	NoTheme = true,
	TextColor3 = Color3.fromRGB(240, 240, 240),
})

local statsLabel_winrate = Tab_playinfo:Label({
	Text = L.stats_winrate .. statsFmtWinRate(_statsPd.wins, _statsPd.losses),
	TextSize = fontSize or 16,
	NoTheme = true,
	TextColor3 = Color3.fromRGB(240, 240, 240),
})

local statsLabel_money = Tab_playinfo:Label({
	Text = L.stats_money .. statsComma(_statsPd.money),
	TextSize = fontSize or 16,
	NoTheme = true,
	TextColor3 = Color3.fromRGB(240, 240, 240),
})

local statsLabel_lastReset = Tab_playinfo:Label({
	Text = L.stats_lastReset .. statsFmtTime(_statsPd.lastReset),
	TextSize = fontSize or 14,
	NoTheme = true,
	TextColor3 = Color3.fromRGB(180, 180, 180),
})

local function refreshStatsUI(pd)
	statsLabel_wins.Text      = L.stats_wins      .. pd.wins
	statsLabel_losses.Text    = L.stats_losses    .. pd.losses
	statsLabel_total.Text     = L.stats_total     .. (pd.wins + pd.losses)
	statsLabel_winrate.Text   = L.stats_winrate   .. statsFmtWinRate(pd.wins, pd.losses)
	statsLabel_money.Text     = L.stats_money     .. statsComma(pd.money)
	statsLabel_lastReset.Text = L.stats_lastReset .. statsFmtTime(pd.lastReset)
end

Tab_playinfo:Button({
	Text = L.stats_reset,
	TextSize = fontSize or 16,
	Callback = function(btn)
		local Popup = Tab_playinfo:PopupModal({ RelativeTo = btn })
		Popup:Separator({ Text = L.stats_reset_confirm })
		local PopupRow = Popup:Row({ Expanded = true })
		PopupRow:Button({
			Text = L.localscript_confirm_yes,
			Callback = function()
				Popup:ClosePopup()
				local pd = statsReset()
				refreshStatsUI(pd)
			end,
		})
		PopupRow:Button({
			Text = L.localscript_confirm_no,
			Callback = function()
				Popup:ClosePopup()
			end,
		})
	end,
})

-- ========================================================================== --
-- Tab_Localscript
local Localscript = {
	path = "Tsetingnil_script/GTD/Script",
	ScriptListTable = nil,
	Excluded = {"_Venus", "_Saturn", "_Mars"},
}

local BuildScriptList
BuildScriptList = function()
	Localscript.ScriptListTable:ClearRows()
	local path = Localscript.path
	local ok, files = pcall(listfiles, path)
	local scripts = {}
	if ok and files then
		for _, filePath in ipairs(files) do
			local name = filePath:match("([^/\\]+)$") or filePath
			if name:match("%.lua$") or name:match("%.txt$") then
				local excluded = false
				for _, suffix in ipairs(Localscript.Excluded) do
					if name:match(suffix .. "%.lua$") or name:match(suffix .. "%.txt$") then
						excluded = true; break
					end
				end
				if not excluded then
					scripts[#scripts + 1] = { name = name, path = filePath }
				end
			end
		end
	end
	if #scripts == 0 then
		local EmptyRow = Localscript.ScriptListTable:NextRow()
		EmptyRow:Column():Label({ Text = L.localscript_no_scripts })
		return
	end
	for _, script in ipairs(scripts) do
		local Row = Localscript.ScriptListTable:NextRow()

		local NameCol = Row:Column()
		NameCol:Label({ Text = script.name })

		local ActionsCol = Row:Column()
		local actionsFrame = ActionsCol.RawObject
		local actionsFlex = Instance.new("UIFlexItem", actionsFrame)
		actionsFlex.FlexMode = Enum.UIFlexMode.None
		actionsFrame.Size = UDim2.new(0, 75, 1, 0)

		local ActionRow = ActionsCol:Row({ Expanded = true })

		ActionRow:SmallButton({
			Text = L.localscript_info,
			Callback = function()
				local content
				local ok3, raw = pcall(readfile, script.path)
				if ok3 and raw then
					local map, diff, mod, timeStr
					local towers = {}
					local seenTowers = {}
					local inTowers = false
					for line in (raw .. "\n"):gmatch("([^\n]*)\n") do
						line = line:gsub("\r", "")
						local m, d, mo = line:match(
							"Map:%s*([^|]+)%s*|%s*Difficulty:%s*([^|]+)%s*|%s*Modifier:%s*(.-)%s*$"
						)
						if not m then
							m, d = line:match("Map:%s*([^|]+)%s*|%s*Difficulty:%s*(.-)%s*$")
						end
						if not m then
							m = line:match("地圖:%s*([^|]+)")
							d = line:match("難度:%s*([^|]+)")
						end
						if m then
							map = m:match("^%s*(.-)%s*$")
						end
						if d then
							diff = d:match("^%s*(.-)%s*$")
						end
						if mo then
							mod = mo:match("^%s*(.-)%s*$")
						end
						
						if line:find("Time:") then
							timeStr = line:match("Time:%s*(.-)%s*%(") or line:match("Time:%s*(.-)%s*$")
							if timeStr then timeStr = timeStr:match("^%s*(.-)%s*$") end
						elseif line:find("Towers used") or line:find("使用塔") or line:find("Towers") then
							inTowers = true
						elseif inTowers and (line:find("%-%s+%S") or line:find("•%s+%S")) then
							local tower = line:match("[%-%s•]+(.-)%s*$")
							if tower and tower ~= "" and not seenTowers[tower] then
								seenTowers[tower] = true
								towers[#towers + 1] = tower
							end
						elseif inTowers then
							inTowers = false
						end
					end
					local out = {}
					if map and diff then
						local row1 = "Map: " .. map .. " | Difficulty: " .. diff
						if timeStr then row1 = row1 .. " | Time: " .. timeStr end
						out[#out + 1] = row1
					end
					if mod and mod ~= "" then
						out[#out + 1] = "<font color='#FFB347'>Modifier:</font>"
						for part in (mod .. ","):gmatch("([^,]+),") do
							local trimmed = part:match("^%s*(.-)%s*$")
							if trimmed ~= "" then
								out[#out + 1] = "  " .. trimmed
							end
						end
					end
					if #towers > 0 then
						out[#out + 1] = "<font color='#5BC8F5'>Towers used:</font>"
						for _, t in ipairs(towers) do
							out[#out + 1] = "  - " .. t
						end
					end
					content = #out > 0 and table.concat(out, "\n") or L.localscript_info_no_block
				else
					content = L.localscript_info_read_fail
				end
				local InfoModal = TabsWindow:PopupModal({ Title = script.name })
				local BtnRow = InfoModal:Row({ Expanded = true })
				BtnRow:Button({
					Text     = L.localscript_info_close,
					Callback = function() InfoModal:ClosePopup() end,
				})
				BtnRow:Button({
					Text     = L.localscript_info_copy,
					Callback = function()
						if raw and pcall(setclipboard, raw) then
							Msg:Success(L.localscript_info_copied)
						end
					end,
				})
				InfoModal:Console({
					Value    = content,
					ReadOnly = true,
					RichText = true,
					Border   = true,
					Size     = UDim2.new(1, 0, 0, isMobile and 110 or 150),
				})
			end,
		})


		ActionRow:SmallButton({
			Text = L.localscript_delete,
			Callback = function(delBtn)
				local Popup1 = Tab_Localscript:PopupModal({
					RelativeTo = delBtn,
				})
				Popup1:Separator({ Text = L.localscript_confirm_title })
				Popup1:Label({ Text = script.name, TextWrapped = true })
				local Row1 = Popup1:Row({ Expanded = true })
				Row1:Button({
					Text = L.localscript_confirm_yes,
					Callback = function()
						Popup1:ClosePopup()
						local Popup2 = Tab_Localscript:PopupModal({
							RelativeTo = delBtn,
						})
						Popup2:Separator({ Text = L.localscript_confirm_title2 })
						local Row2 = Popup2:Row({ Expanded = true })
						Row2:Button({
							Text = L.localscript_delete_final,
							Callback = function()
								Popup2:ClosePopup()
								local ok2, err = pcall(delfile, script.path)
								if ok2 then
									Msg:Success(L.localscript_deleted .. ": " .. script.name)
									BuildScriptList()
								else
									Msg:Warning(L.localscript_delete_error .. ": " .. tostring(err))
								end
							end,
						})
						Row2:Button({
							Text = L.localscript_confirm_no,
							Callback = function()
								Popup2:ClosePopup()
							end,
						})
					end,
				})
				Row1:Button({
					Text = L.localscript_confirm_no,
					Callback = function()
						Popup1:ClosePopup()
					end,
				})
			end,
		})
	end
end

Tab_Localscript:Label({
	Text = L.localscript_path .. Localscript.path,
	TextSize = fontSize,
})

Tab_Localscript:Separator({ Text = L.localscript_list })

local HeaderRow = Tab_Localscript:Row()

HeaderRow:Button({
	Text = L.localscript_refresh,
	Callback = function()
		BuildScriptList()
		Msg:Success(L.localscript_refreshed)
	end,
})

HeaderRow:Button({
	Text = L.localscript_save_running,
	Callback = function()
		local userId = tostring(game.Players.LocalPlayer.UserId)
		local mainPathBS = "Tsetingnil_script\\GTD\\main_" .. userId .. ".lua"
		local mainPathFW = "Tsetingnil_script/GTD/main_" .. userId .. ".lua"
		local useFW = isfile and isfile(mainPathFW) and not isfile(mainPathBS)
		local mainPath = useFW and mainPathFW or mainPathBS
		local ok3, raw = pcall(readfile, mainPath)
		if not ok3 or not raw or raw == "" then
			ok3, raw = pcall(readfile, useFW and mainPathBS or mainPathFW)
		end
		if not ok3 or not raw or raw == "" then
			Msg:Warning(L.localscript_save_no_running)
			return
		end
		local content
		local block = raw:match("%-%-%[%[(.-)%]%]")
		if block then
			local map, diff, mod, timeStr
			local towers = {}
			local inTowers = false
			for line in (block .. "\n"):gmatch("([^\n]*)\n") do
				line = line:gsub("\r", "")
				local m, d, mo
				if line:find("Modifier:") then
					m, d, mo = line:match("Map:%s*(.-)%s*|%s*Difficulty:%s*(.-)%s*|%s*Modifier:%s*(.-)%s*$")
				else
					m, d = line:match("Map:%s*(.-)%s*|%s*Difficulty:%s*(.-)%s*$")
					mo = ""
				end
				if m then
					map, diff, mod = m, d, mo
				elseif line:find("^%s*Time:") then
					timeStr = line:match("Time:%s*(.-)%s*%(") or line:match("Time:%s*(.-)%s*$")
					if timeStr then timeStr = timeStr:match("^%s*(.-)%s*$") end
				elseif line:find("Towers used") then
					inTowers = true
				elseif inTowers and line:find("%-%s+%S") then
					local tower = line:match("%-%s+(.-)%s*$")
					if tower and tower ~= "" then towers[#towers + 1] = tower end
				end
			end
			local out = {}
			if map and diff then
				local row1 = "Map: " .. map .. " | Difficulty: " .. diff
				if timeStr then row1 = row1 .. " | Time: " .. timeStr end
				out[#out + 1] = row1
			end
			if mod and mod ~= "" then
				out[#out + 1] = "<font color='#FFB347'>Modifier:</font>"
				for part in (mod .. ","):gmatch("([^,]+),") do
					local trimmed = part:match("^%s*(.-)%s*$")
					if trimmed ~= "" then out[#out + 1] = "  " .. trimmed end
				end
			end
			if #towers > 0 then
				out[#out + 1] = "<font color='#5BC8F5'>Towers used:</font>"
				for _, t in ipairs(towers) do out[#out + 1] = "  - " .. t end
			end
			content = #out > 0 and table.concat(out, "\n") or L.localscript_info_no_block
		else
			content = L.localscript_info_no_block
		end
		local scriptTitle = "main_" .. userId
		local InfoModal = TabsWindow:PopupModal({ Title = scriptTitle })
		local BtnRow = InfoModal:Row({ Expanded = true })
		BtnRow:Button({
			Text = L.localscript_save,
			Callback = function()
				local inputName = ""
				local NameModal = TabsWindow:PopupModal({ Title = L.localscript_save_name_title })
				NameModal:InputText({
					Placeholder = L.localscript_save_name_ph,
					Value = "",
					Callback = function(_, text)
						inputName = text
					end,
				})
				local NRow = NameModal:Row({ Expanded = true })
				NRow:Button({
					Text = L.localscript_confirm_yes,
					Callback = function()
						local name = inputName:match("^%s*(.-)%s*$")
						if name == "" then return end
						local sep = useFW and "/" or "\\"
						local savePath = "Tsetingnil_script" .. sep .. "GTD" .. sep .. "Script" .. sep .. name .. ".lua"
						local outerBlock = raw:match("%-%-%[%[(.-)%]%]") or ""
						local mapVal = outerBlock:match("Map:%s*([^|%\n]+)") or ""
						local diffVal = outerBlock:match("Difficulty:%s*([^|%\n]+)") or ""
						local timeVal = outerBlock:match("Time:%s*([^|%\n]+)") or ""
						
						mapVal = mapVal:gsub("^%s*(.-)%s*$", "%1")
						diffVal = diffVal:gsub("^%s*(.-)%s*$", "%1")
						timeVal = timeVal:gsub("^%s*(.-)%s*$", "%1")
						
						local newHeader = "--[[\n" ..
							"  Script By: GTD Place Tracker script \n" ..
							'  URL: loadstring(game:HttpGet("https://raw.githubusercontent.com/Tseting-nil/Garden-Tower-Defense-script/refs/heads/main/Tool/%E6%94%BE%E7%BD%AE%E8%BF%BD%E8%B9%A4%E5%99%A8.lua"))()\n'
						if mapVal ~= "" and diffVal ~= "" then
							newHeader = newHeader .. "  Map: " .. mapVal .. "  |  Difficulty: " .. diffVal .. "\n"
						end
						if timeVal ~= "" then
							newHeader = newHeader .. "  Time: " .. timeVal .. "\n"
						end
						newHeader = newHeader .. "]]"

						local wrappedContent = newHeader .. "\n\n" ..
							"local fullScript = [=[\n" ..
							raw ..
							"\n]=]\n\n" ..
							"local GTD = getgenv().GTD\n" ..
							"if not GTD or not GTD.ExecuteQueue then\n" ..
							'\tloadstring(game:HttpGet("https://raw.githubusercontent.com/Tseting-nil/Garden-Tower-Defense-script/refs/heads/main/%E5%AF%86%E9%91%B0%E7%B3%BB%E7%B5%B1.lua"))()\n' ..
							"\tGTD = getgenv().GTD\n" ..
							"end\n\n" ..
							"GTD.SaveLocalScript(fullScript)\n" ..
							"loadstring(fullScript)()\n"
						if not isfolder("Tsetingnil_script") then makefolder("Tsetingnil_script") end
						if not (isfolder("Tsetingnil_script\\GTD") or isfolder("Tsetingnil_script/GTD")) then makefolder("Tsetingnil_script" .. sep .. "GTD") end
						if not (isfolder("Tsetingnil_script\\GTD\\Script") or isfolder("Tsetingnil_script/GTD/Script")) then makefolder("Tsetingnil_script" .. sep .. "GTD" .. sep .. "Script") end
						local ok4, err = pcall(writefile, savePath, wrappedContent)
						if ok4 then
							Msg:Success(L.localscript_save_success .. ": " .. name)
							NameModal:ClosePopup()
							InfoModal:ClosePopup()
							BuildScriptList()
						else
							Msg:Warning(L.localscript_save_error .. ": " .. tostring(err))
						end
					end,
				})
				NRow:Button({
					Text = L.localscript_confirm_no,
					Callback = function()
						NameModal:ClosePopup()
					end,
				})
			end,
		})
		BtnRow:Button({
			Text = L.localscript_info_close,
			Callback = function() InfoModal:ClosePopup() end,
		})
		InfoModal:Console({
			Value    = content,
			ReadOnly = true,
			RichText = true,
			Border   = true,
			Size     = UDim2.new(1, 0, 0, isMobile and 110 or 150),
		})
	end,
})

Localscript.ScriptListTable = Tab_Localscript:Table({
	RowBackground = true,
	Border = true,
})

BuildScriptList()



-- 統計數據自動追蹤（基於 GameStartTime / GameEndTime 屬性與種子差值）
task.spawn(function()
	local lastGameStart = nil
	local initialSeeds = 0
	local trackingActive = false

	-- 獲取種子數量的輔助函數
	local function getSeeds()
		local seedsCount = 0
		local ok, data = pcall(function()
			local ClientDataHandler = require(game.Players.LocalPlayer.PlayerGui.LogicHolder.ClientLoader.Modules.ClientDataHandler)
			return type(ClientDataHandler.GetData) == "function" and ClientDataHandler.GetData() or ClientDataHandler:GetData()
		end)
		if ok and data and data.Seeds then
			seedsCount = data.Seeds
		else
			local lp = game:GetService("Players").LocalPlayer
			local leaderstats = lp:FindFirstChild("leaderstats")
			local seedsVal = leaderstats and leaderstats:FindFirstChild("Seeds")
			if seedsVal then
				seedsCount = seedsVal.Value
			end
		end
		return tonumber(seedsCount) or 0
	end

	-- 定期檢測屬性變化
	while true do
		task.wait(1)
		if getgenv().GTD_UI_InstanceId ~= myInstanceId then break end
		pcall(function()
			local gst = workspace:GetAttribute("GameStartTime")
			local get = workspace:GetAttribute("GameEndTime")
			
			-- 1. 檢測到新局開始：GameStartTime 改變且大於 0
			if type(gst) == "number" and gst > 0 and gst ~= lastGameStart then
				lastGameStart = gst
				initialSeeds = getSeeds()
				trackingActive = true
				print(string.format("[GTD統計] 🎮 新局開始！記錄初始種子數: %d", initialSeeds))
			end
			
			-- 2. 檢測到遊戲結束：有 GameEndTime 且目前處於追蹤狀態
			if trackingActive and type(get) == "number" and get > 0 then
				trackingActive = false -- 立即關閉追蹤，防止重複觸發
				
				-- 等待 2.0 秒讓伺服器結算並發放種子獎勵
				task.wait(2.0)
				
				local finalSeeds = getSeeds()
				local earned = finalSeeds - initialSeeds
				if earned < 0 then earned = 0 end
				
				-- 判斷勝負：若 BaseHP <= 0 代表基地被摧毀（失敗），否則為勝利
				local hp = workspace:GetAttribute("BaseHP")
				local isWin = true
				if type(hp) == "number" and hp <= 0 then
					isWin = false
				end
				
				-- 儲存並刷新 UI
				local pd = statsSave(isWin, earned)
				refreshStatsUI(pd)
				print(string.format("[GTD統計] 🏁 戰鬥結束！勝負: %s，賺取種子: +%d (初始: %d -> 結束: %d)", 
					isWin and "勝利" or "失敗", earned, initialSeeds, finalSeeds))

				-- 記憶體防崩潰 + 反巨集輪換：累計場數，達 interval 場時換腳本並回大廳重開
				matchCount = matchCount + 1
				print(string.format("[GTD統計] 📊 當前掛機累計場數: %d / %d", matchCount, Rotation.interval))

				if alrEnabled and matchCount >= Rotation.interval then
					print(string.format("[GTD統計] 🚨 累計達到 %d 場，自動返回大廳以釋放記憶體！", Rotation.interval))
					matchCount = 0 -- 重置計數
					
					-- 關閉 AutoReplay 以防重播核心在傳送前搶先執行 RestartGame
					if getgenv().GTD and Scripttable then
						pcall(function()
							Mainfunction.AutoReplay(false)
						end)
					end
					
					-- 反巨集輪換：從池中隨機挑一支（排除上次）覆寫進 main_<UserId>.lua，
					-- 換陣型/地圖/時序打散「每局同指紋」；resume(queue_on_teleport) 會載入新 main。
					local picked = Rotation.pickNext()
					if picked then
						if Rotation.applyToMain(picked) then
							Rotation.lastPicked = picked
							Rotation.save()
							print("[GTD統計] 🔀 " .. string.format(L.rotation_picked_msg, picked))
							if Msg and Msg.Success then
								Msg:Success(string.format(L.rotation_picked_msg, picked))
							end
						else
							warn("[GTD統計] " .. tostring(L.rotation_apply_fail))
						end
					else
						print("[GTD統計] " .. tostring(L.rotation_empty_pool))
					end

					-- 武裝 queue_on_teleport（TPChange 旗標版）：回大廳到達後自動載入 main → 大廳分支 EquipLoadout+SelectMap → 進關卡 → ExecuteQueue
					-- 用 TPChange 版讓殘留未清的普通 queue 讓位（部分執行器不清舊 queue → 兩個 queue 重疊不知執行哪個）
					if getgenv().GTD and Mainfunction then
						pcall(function()
							if Mainfunction.Queueload_TPChangeQueue then
								Mainfunction.Queueload_TPChangeQueue()
							elseif Mainfunction.Queueload then
								Mainfunction.Queueload()
							end
						end)
					end

					task.wait(1.0)
					returnToLobby()
				end
			end
		end)
	end
end)
-- === Tab_event（Event）：自動撿取 === --
-- 內嵌 自動撿取.lua 原始碼（改那檔記得同步這裡）。
do
	local COLLECT_SRC = [==[
--[[
	Garden Tower Defense — 自動撿取 (Collectables)
	================================================
	場上所有撿取物 (Lucky Block / Egg / 鑽石 等，tag = "Collectables_collectable")
	自動呼叫 CollectCollectable 收取，並持續監聽新生成的。

	呼叫鏈 (反編譯來源)：
	  ProximityPrompt.Triggered / PromptButtonHoldBegan
	    -> SharedCollectables.MapModelBehaviours.collectable  (函式 v109, Line 476)
	    -> SharedHelper.InvokeRemoteFunction("CollectCollectable", part:GetAttribute("ID"))
	    -> ReplicatedStorage.RemoteFunctions.CollectCollectable:InvokeServer(id)
	  Server handler: SharedCollectables Line 314，比對活躍清單 c.ID == id 後 c.Collect(player)

	備註：
	  - 傳入的 ID 不是道具 id，是 server 端每生成一個 +1 的流水號，
	    寫在 workspace 撿取物 part 的 "ID" 屬性上。
	  - Server 端 Collect 仍會驗 ClaimLimit / AcceptedPlayers / CollectCondition，
	    所以這支只是「自動觸發」，不繞過上限。

	停止：getgenv().__AUTO_COLLECT.stop()
]]

if getgenv().__AUTO_COLLECT then
	getgenv().__AUTO_COLLECT.stop()
end

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local RF = game:GetService("ReplicatedStorage"):WaitForChild("RemoteFunctions"):WaitForChild("CollectCollectable")

local TAG = "Collectables_collectable"
local RESWEEP_INTERVAL = 5 -- 秒，定期全場補掃，防止偶發漏接 tag 信號 (設 0 關閉)

local seen = {}   -- part -> true，避免重複呼叫
local conns = {}
local running = true

-- AcceptedPlayers 屬性是 "uid1,uid2," 格式；空 = 所有人可收
local function canCollect(part)
	local ap = part:GetAttribute("AcceptedPlayers")
	if not ap or ap == "" then return true end
	return table.find(string.split(ap, ","), tostring(LP.UserId)) ~= nil
end

local collectedCount = 0

local function tryCollect(part)
	if not running then return end
	if not part or seen[part] then return end
	local id = part:GetAttribute("ID")
	if not id then return end
	if not canCollect(part) then return end
	seen[part] = true
	-- 收取前先記下名稱 (part 收掉後屬性可能讀不到)
	local label = ("%s_%s"):format(
		tostring(part:GetAttribute("CollectionId")),
		tostring(part:GetAttribute("ItemId"))
	)
	task.spawn(function()
		local ok, result = pcall(function() return RF:InvokeServer(id) end)
		if not ok then
			seen[part] = nil -- 呼叫出錯，下次補掃再試
		elseif result == true then
			collectedCount = collectedCount + 1
			print(("[AutoCollect] ✓ 已收取 %s (ID=%s) | 累計 %d 個"):format(label, tostring(id), collectedCount))
		else
			-- server 回 false/nil：上限已滿 / 不可收 / 已被收走，不重試
			print(("[AutoCollect] ✗ 跳過 %s (ID=%s)：上限或條件不符"):format(label, tostring(id)))
		end
	end)
end

local function sweep()
	for _, part in ipairs(CollectionService:GetTagged(TAG)) do
		tryCollect(part)
	end
end

-- 1) 先掃場上現有的
sweep()

-- 2) 監聽之後新生成的
conns[#conns + 1] = CollectionService:GetInstanceAddedSignal(TAG):Connect(function(part)
	-- part 的 ID 屬性可能晚一格才寫上，等它
	if part:GetAttribute("ID") == nil then
		part:GetAttributeChangedSignal("ID"):Wait()
	end
	tryCollect(part)
end)

-- 3) part 消失時清表，避免 seen 無限長
conns[#conns + 1] = CollectionService:GetInstanceRemovedSignal(TAG):Connect(function(part)
	seen[part] = nil
end)

-- 4) 定期全場補掃 (保險)
if RESWEEP_INTERVAL > 0 then
	task.spawn(function()
		while running do
			task.wait(RESWEEP_INTERVAL)
			if running then sweep() end
		end
	end)
end

getgenv().__AUTO_COLLECT = {
	stop = function()
		running = false
		for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
		getgenv().__AUTO_COLLECT = nil
		warn("[AutoCollect] 已停止")
	end,
}

print(("[AutoCollect] 已啟動，場上現有 %d 個撿取物已嘗試收取；持續監聽 + 每 %ds 補掃。停止：getgenv().__AUTO_COLLECT.stop()")
	:format(#CollectionService:GetTagged(TAG), RESWEEP_INTERVAL))

]==]

	local function runSrc(src, label)
		local fn, err = loadstring(src)
		if not fn then
			Msg:Warning(string.format(L.event_load_failed, label, tostring(err)))
			return false
		end
		local ok, e = pcall(fn)
		if not ok then
			Msg:Warning(string.format(L.event_run_error, label, tostring(e)))
			return false
		end
		return true
	end

	Tab_event:Separator({ Text = L.event_collect_section })
	local AutoCollectToggle = Tab_event:Checkbox({
		Label = L.event_collect_toggle,
		Value = false,
		Callback = function(self, on)
			if on then
				if runSrc(COLLECT_SRC, L.event_collect_section) then
					Msg:Success(L.event_collect_started)
				else
					self:SetValue(false)
				end
			else
				if getgenv().__AUTO_COLLECT then
					pcall(function() getgenv().__AUTO_COLLECT.stop() end)
					Msg:Success(L.event_collect_stopped)
				end
			end
		end,
	})
	AutoCollectToggle:SetValue(true)
end
