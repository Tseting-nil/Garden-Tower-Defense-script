if getgenv().Islobbyguiloaded then
  return
end
getgenv().Islobbyguiloaded = true
-- 側邊通知模組
if not getgenv().NotificationModule then
	loadstring(game:HttpGet("https://gist.githubusercontent.com/Tseting-nil/08653e6aa9fc12a9f097bfb10e6654e7/raw/00001d614d928fc5dafce59133a012dd78419afd/%25E5%2581%25B4%25E9%2582%258A%25E9%2580%259A%25E7%259F%25A5%25E6%25A8%25A1%25E7%25B5%2584.lua"))()
end
local Msg = getgenv().NotificationModule

-- 移動模組
if not getgenv().MOVEAPI then
	local MoveAPI = loadstring(game:HttpGet("https://gist.githubusercontent.com/Tseting-nil/494a4830fa6d3466596e4e01ca25bdee/raw/%25E5%25B7%25A1%25E8%25B7%25AF%25E6%25A8%25A1%25E7%25B5%2584"))()
	MoveAPI:SetJumpEnabled(false)
	MoveAPI:SetDirectMovementDistance(500)
	getgenv().MOVEAPI = MoveAPI
end
local Move = getgenv().MOVEAPI

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
		title = "大廳介面",
		tab_main = "Main",
		tab_summon = "抽取",
		tab_localscript = "本地腳本",
		tab_settings = "設定",
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
		localscript_save_running    = "儲存上次運行的腳本",
		localscript_save            = "儲存",
		localscript_save_name_title = "輸入儲存名稱",
		localscript_save_name_ph    = "腳本名稱...",
		localscript_save_success    = "已儲存",
		localscript_save_error      = "儲存失敗",
		localscript_save_no_running = "無正在運行的腳本",
		rotation_pool_header = "輪換腳本池（可多選，每 N 場換一支）",
		rotation_interval_label = "每幾場輪換",
		rotation_refresh_btn = "重新整理清單",
		rotation_save_btn = "儲存輪換設定",
		rotation_no_scripts = "Script 資料夾內沒有可用腳本",
		rotation_saved_msg = "輪換設定已儲存：%d 支腳本，每 %d 場輪換",

		-- 新增大廳與金鑰資訊
		key_info_section = "密鑰資訊",
		key_time_init = "密鑰剩餘時間: ---",
		key_update_btn = "更新密鑰",
		key_no_update_needed = "密鑰剩餘時間大於 1 天，無需更新密鑰",
		script_info_section = "腳本資訊",
		gtd_env_loaded = "GTD 環境: 已加載",
    gtd_env_loading = "GTD 環境: 加載中",
    gtd_env_keysystem = "請先完成驗證密鑰系統",
		gtd_env_not_loaded = "GTD 環境: 未加載",
		equipped_towers_section = "當前裝配塔",
		empty_slot = "空",
		unequip_btn = "解除裝配",
		gtd_not_loaded_unequip = "GTD 環境未加載，無法解除裝配",
		unequip_success = "已解除裝配：",
		unequip_fail = "解除裝配失敗：",
		unequip_all_btn = "解除全部",
		gtd_not_loaded_unequip_all = "GTD 環境未加載，無法解除全部",
		unequip_all_success = "已解除全部裝配：%d 座",
		unequip_all_incomplete = "解除全部未完成（已卸 %d 座）",
		refresh_btn = "刷新",
		refresh_equipped_success = "已刷新當前裝配塔",
		key_time_format = "%d天 %02d小時 %02d分 %02d秒",
		key_time_label = "密鑰剩餘時間: ",
		key_expired = "密鑰已過期",
		key_fetch_error = "無法獲取密鑰資訊",

		-- 新增抽取 (Gacha) 資訊
		summon_box_select = "抽取箱選擇",
		summon_choose_box = "選擇箱子",
		summon_click_select = "點此選箱",
		gtd_not_loaded_parentheses = "（GTD 未加載）",
		summon_please_select = "請先選擇箱子",
		summon_available_units = "可抽取塔",
		summon_box_items = "箱子物品",
		summon_owned = "擁有",
		summon_chance = "機率",
		summon_auto_delete = "自動刪除",
		summon_lock_failed = "封鎖設定失敗",
		gtd_not_loaded = "GTD 環境未加載",
		summon_box_info_format = "%s | 貨幣: %s | x1: %s | x10: %s",
		summon_settings = "抽取設定",
		summon_qty_x1 = "x1",
		summon_qty_x10 = "x10",
		summon_start_checkbox = "開始抽取（每 0.3 秒）",
		summon_stop_failed = "抽取停止：購買失敗（貨幣不足或箱已下架）",

		-- 控制台資訊解析標籤
		info_map = "地圖",
		info_difficulty = "難度",
		info_time = "時間",
		info_modifier = "修飾符",
		info_towers_used = "使用塔",

		-- 活動 (Event) 分頁
		tab_event = "活動",
		event_flower_section = "自動採花",
		event_flower_toggle = "自動採花（走路採全場花）",
		event_flower_started = "自動採花已啟動",
		event_flower_stopped = "自動採花已停止",
		event_collect_section = "自動撿取",
		event_collect_toggle = "自動撿取（Lucky Block／蛋／鑽石…）",
		event_collect_started = "自動撿取已啟動",
		event_collect_stopped = "自動撿取已停止",
		event_load_failed = "%s 載入失敗：%s",
		event_run_error = "%s 執行錯誤：%s"
	},
	en = {
		title = "Lobby UI",
		tab_main = "Main",
		tab_summon = "Summon",
		tab_localscript = "localscript",
		tab_settings = "Setting",
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
		localscript_save_running    = "Save Last Run Script",
		localscript_save            = "Save",
		localscript_save_name_title = "Enter Save Name",
		localscript_save_name_ph    = "Script name...",
		localscript_save_success    = "Saved",
		localscript_save_error      = "Save failed",
		localscript_save_no_running = "No running script",
		rotation_pool_header = "Script Rotation Pool (multi-select, swap every N games)",
		rotation_interval_label = "Games per rotation",
		rotation_refresh_btn = "Refresh List",
		rotation_save_btn = "Save Rotation Config",
		rotation_no_scripts = "No scripts available in the Script folder",
		rotation_saved_msg = "Rotation saved: %d scripts, swap every %d games",

		-- Main & Key Info & Script Info (English)
		key_info_section = "Key Info",
		key_time_init = "Key Remaining Time: ---",
		key_update_btn = "Update Key",
		key_no_update_needed = "Key remaining time is > 1 day, no need to update",
		script_info_section = "Script Info",
		gtd_env_loaded = "GTD Env: Loaded",
		gtd_env_not_loaded = "GTD Env: Not Loaded",
    gtd_env_loading = "GTD Env: Loading",
		gtd_env_keysystem = "Please complete the key verification system first",
		equipped_towers_section = "Equipped Towers",
		empty_slot = "Empty",
		unequip_btn = "Unequip",
		gtd_not_loaded_unequip = "GTD environment not loaded, cannot unequip",
		unequip_success = "Unequipped: ",
		unequip_fail = "Unequip failed: ",
		unequip_all_btn = "Unequip All",
		gtd_not_loaded_unequip_all = "GTD environment not loaded, cannot unequip all",
		unequip_all_success = "Successfully unequipped all: %d units",
		unequip_all_incomplete = "Unequip all incomplete (unequipped %d units)",
		refresh_btn = "Refresh",
		refresh_equipped_success = "Refreshed equipped towers",
		key_time_format = "%dD %02dH %02dM %02dS",
		key_time_label = "Key Remaining: ",
		key_expired = "Key Expired",
		key_fetch_error = "Unable to get key info",

		-- Gacha info (English)
		summon_box_select = "Gacha Box Selection",
		summon_choose_box = "Select Box",
		summon_click_select = "Click to select box",
		gtd_not_loaded_parentheses = "(GTD Not Loaded)",
		summon_please_select = "Please select a box first",
		summon_available_units = "Available Units",
		summon_box_items = "Box Items",
		summon_owned = "Owned",
		summon_chance = "Chance",
		summon_auto_delete = "Auto Delete",
		summon_lock_failed = "Banning failed",
		gtd_not_loaded = "GTD environment not loaded",
		summon_box_info_format = "%s | Currency: %s | x1: %s | x10: %s",
		summon_settings = "Gacha Settings",
		summon_qty_x1 = "x1",
		summon_qty_x10 = "x10",
		summon_start_checkbox = "Start Gacha (Every 0.3s)",
		summon_stop_failed = "Gacha stopped: Purchase failed (insufficient currency or box expired)",

		-- Console info block key-value labels
		info_map = "Map",
		info_difficulty = "Difficulty",
		info_time = "Time",
		info_modifier = "Modifier",
		info_towers_used = "Towers used",

		-- Event tab
		tab_event = "Event",
		event_flower_section = "Auto Flower",
		event_flower_toggle = "Auto Flower (walk & harvest all)",
		event_flower_started = "Auto Flower started",
		event_flower_stopped = "Auto Flower stopped",
		event_collect_section = "Auto Collect",
		event_collect_toggle = "Auto Collect (Lucky Block / Egg / Diamond...)",
		event_collect_started = "Auto Collect started",
		event_collect_stopped = "Auto Collect stopped",
		event_load_failed = "%s load failed: %s",
		event_run_error = "%s run error: %s"
	}
}

local Scripttable = {
	GUI = {
		Modules = {
			Tab_main = {},
			Tab_summon = {},
			Tab_Localscript = {},
			Tab_settings = {},
			Tab_event = {}
		}
	},
}
local Mainfunction = {}

local L = i18n[currentLang]
local fontSize = currentLang == "en" and 14 or 16
local UserInputService = game:GetService("UserInputService")
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
-- === GUI ==== --
local ReGui = loadstring(game:HttpGet("https://gist.githubusercontent.com/Tseting-nil/169b7303e1418cb301bad5ab427e9351/raw/93e90190f628387b545eef62b49e4ce146d1dad8/GUI:ReGui"))()
local TabsWindow = ReGui:TabsWindow({
	Title = L.title,
	Visible = true,
	Size = UDim2.fromOffset(450, 300)
})

local Tabs = {}

for _, Name in ipairs({
	L.tab_main,
	L.tab_summon,
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

local Tab_summon = Tabs[2]:ScrollingCanvas({
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

-- 獲取密鑰系統資訊 { saved_at: number, script_language: string, key: string, expires_at: number, language: string }
Mainfunction.GetkeyInfo = function()
	local API_VAR_PATH = "Tsetingnil_script/keysystem.json"
	local keyInfo = {}
	pcall(function()
		if isfile and isfile(API_VAR_PATH) and readfile then
			local raw = readfile(API_VAR_PATH)
			if raw and raw ~= "" then
				local ok, data = pcall(game:GetService("HttpService").JSONDecode, game:GetService("HttpService"), raw)
				if ok and type(data) == "table" then
					keyInfo = data
				end
			end
		end
	end)
	return keyInfo
end

-- === Tab_main === --
Tab_main:Separator({
	Text = L.key_info_section
})
Scripttable.GUI.Modules.Tab_main._keyinfo = Tab_main:Label({
	TextSize = fontSize,
	Text = L.key_time_init
})
if Mainfunction.GetkeyInfo then
	local keyInfo = Mainfunction.GetkeyInfo()
	if keyInfo and keyInfo.expires_at then
		local expires = tonumber(keyInfo.expires_at)
		if expires and expires > 9999999999 then
			expires = expires / 1000
		end
		local remainingTime = expires - os.time()
		if remainingTime < 86400 then
			Tab_main:Button({
				Text = L.key_update_btn,
				Callback = function()
					getgenv().AutoVerify = false
					if remainingTime < 86400 then
						loadstring(game:HttpGet("https://raw.githubusercontent.com/Tseting-nil/Garden-Tower-Defense-script/refs/heads/main/%E5%AF%86%E9%91%B0%E7%B3%BB%E7%B5%B1.lua"))()
					else
						Msg:Warning(L.key_no_update_needed)
						print(L.key_no_update_needed)
					end
					getgenv().AutoVerify = true
				end
			})
		end
	end
end


Tab_main:Separator({
	Text = L.script_info_section
})
Scripttable.GUI.Modules.Tab_main._ISAPIload = Tab_main:Label({
	TextSize = fontSize,
	Text = L.gtd_env_not_loaded
})

Tab_main:Separator({
	Text = L.equipped_towers_section
})

-- === 當前裝配塔：預繪 7 個空欄位（最大裝配容量），用 2 欄表格對齊；左 Label 右 解除裝配 按鈕 === --
local EQUIP_SLOT_COUNT = 7
Scripttable.GUI.Modules.Tab_main._equipSlots = {}
local EquipTable = Tab_main:Table({
	MaxColumns = 2,
	RowBackground = true
})
for i = 1, EQUIP_SLOT_COUNT do
	local Row = EquipTable:NextRow()

	-- 第 1 欄：塔名稱（不加 UIFlexItem → 自動填滿剩餘寬度）
	local nameCol = Row:NextColumn()
	local label = nameCol:Label({
		TextSize = fontSize,
		Text = string.format("%d. %s", i, L.empty_slot)
	})

	-- 第 2 欄：解除裝配按鈕（固定 80px 寬，使各列按鈕對齊）
	local btnCol = Row:NextColumn()
	local btnFrame = btnCol.RawObject
	if btnFrame then
		local flex = Instance.new("UIFlexItem")
		flex.FlexMode = Enum.UIFlexMode.None
		flex.Parent = btnFrame
		btnFrame.Size = UDim2.new(0, 80, 1, 0)
	end
	local button = btnCol:Button({
		Text = L.unequip_btn,
		Disabled = true,
		Callback = function()
			local slot = Scripttable.GUI.Modules.Tab_main._equipSlots[i]
			if not (slot and slot.Unique) then
				return
			end
			local GTD = getgenv().GTD
			if not (GTD and GTD.SetEquipped) then
				Msg:Warning(L.gtd_not_loaded_unequip)
				return
			end
			local towerName = slot.Name or slot.Unique
			slot.Button:SetDisabled(true)
			local ok = GTD.SetEquipped(slot.Unique, false)
			if ok then
				Msg:Success(L.unequip_success .. tostring(towerName))
			else
				Msg:Warning(L.unequip_fail .. tostring(towerName))
			end
			pcall(Mainfunction.RefreshEquippedTowers)
		end
	})
	-- 預設為空位 → 隱藏解除按鈕（有裝塔時由 RefreshEquippedTowers 顯示）
	button.Visible = false
	Scripttable.GUI.Modules.Tab_main._equipSlots[i] = {
		Row = Row,
		Label = label,
		Button = button,
		Unique = nil,
		Name = nil
	}
end

-- 解除全部（紅色）+ 刷新：同一橫排
local equipBtnRow = Tab_main:Row()
Scripttable.GUI.Modules.Tab_main._unequipAllBtn = equipBtnRow:Button({
	Text = L.unequip_all_btn,
	BackgroundColor3 = Color3.fromRGB(200, 55, 55),
	Callback = function()
		local GTD = getgenv().GTD
		if not (GTD and GTD.UnequipAll) then
			Msg:Warning(L.gtd_not_loaded_unequip_all)
			return
		end
		task.spawn(function()
			local ok, count = GTD.UnequipAll()
			if ok then
				Msg:Success(string.format(L.unequip_all_success, count))
			else
				Msg:Warning(string.format(L.unequip_all_incomplete, count))
			end
			pcall(Mainfunction.RefreshEquippedTowers)
		end)
	end
})
equipBtnRow:Button({
	Text = L.refresh_btn,
	Callback = function()
		pcall(Mainfunction.RefreshEquippedTowers)
		Msg:Success(L.refresh_equipped_success)
	end
})

-- 依 GTD.GetEquipped() 更新 7 個欄位（有塔顯示名稱+啟用按鈕，空位顯示「空」+禁用按鈕）
Mainfunction.RefreshEquippedTowers = function()
	local slots = Scripttable.GUI.Modules.Tab_main._equipSlots
	if not slots then
		return
	end
	local equipped = {}
	local GTD = getgenv().GTD
	if GTD and GTD.GetEquipped then
		local ok, res = pcall(GTD.GetEquipped)
		if ok and type(res) == "table" then
			equipped = res
		end
	end

	-- 取每座塔的放置金錢，依金錢由小到大排序（無金錢者排最後）
	for _, e in ipairs(equipped) do
		local cost
		if GTD and GTD.GetUnitCost and e.ID then
			local ok, c = pcall(GTD.GetUnitCost, e.ID)
			if ok then
				cost = c
			end
		end
		e.Cost = cost
	end
	table.sort(equipped, function(a, b)
		local ca, cb = a.Cost, b.Cost
		if ca == cb then
			return (a.UniqueOrder or 0) < (b.UniqueOrder or 0)
		end
		if ca == nil then
			return false
		end
		if cb == nil then
			return true
		end
		return ca < cb
	end)

	for i = 1, EQUIP_SLOT_COUNT do
		local slot = slots[i]
		local e = equipped[i]
		if e then
			slot.Unique = e.Unique
			slot.Name = e.Name or e.Unique
			slot.Label.Text = string.format("%d. %s", i, slot.Name)
			slot.Button.Visible = true
			slot.Button:SetDisabled(false)
		else
			slot.Unique = nil
			slot.Name = nil
			slot.Label.Text = string.format("%d. %s", i, L.empty_slot)
			slot.Button:SetDisabled(true)
			slot.Button.Visible = false
		end
	end
end

-- === 初始化 === --
local gtdLoadingStarted = false
local gtdLoadingTime = 0

Mainfunction.RefreshkeyInfo = function()
	local keyInfo = Mainfunction.GetkeyInfo()
	if keyInfo and keyInfo.expires_at then
		local expires = tonumber(keyInfo.expires_at)
		if expires and expires > 9999999999 then
			expires = expires / 1000
		end
		local remainingTime = expires - os.time()

		if remainingTime > 0 then
			local days = math.floor(remainingTime / 86400)
			local hours = math.floor((remainingTime % 86400) / 3600)
			local mins = math.floor((remainingTime % 3600) / 60)
			local secs = math.floor(remainingTime % 60)
			
			local timeStr = string.format(L.key_time_format, days, hours, mins, secs)
			Scripttable.GUI.Modules.Tab_main._keyinfo.Text = (L.key_time_label .. timeStr)
		else
			Scripttable.GUI.Modules.Tab_main._keyinfo.Text = (L.key_expired)
		end
	else
		Scripttable.GUI.Modules.Tab_main._keyinfo.Text = (L.key_fetch_error)
	end

	-- 檢測 GTD 環境加載狀態
	if getgenv().GTDAPI and getgenv().GTDAPI.__loaded then
		Scripttable.GUI.Modules.Tab_main._ISAPIload.Text = L.gtd_env_loaded
	else
		if not gtdLoadingStarted then
			gtdLoadingStarted = true
			gtdLoadingTime = os.time()
			Scripttable.GUI.Modules.Tab_main._ISAPIload.Text = L.gtd_env_loading
			task.spawn(function()
				pcall(function()
					loadstring(game:HttpGet("https://raw.githubusercontent.com/Tseting-nil/Garden-Tower-Defense-script/refs/heads/main/%E5%AF%86%E9%91%B0%E7%B3%BB%E7%B5%B1.lua"))()
				end)
			end)
		end

		if os.time() - gtdLoadingTime > 5 then
			Scripttable.GUI.Modules.Tab_main._ISAPIload.Text = L.gtd_env_keysystem
		else
			Scripttable.GUI.Modules.Tab_main._ISAPIload.Text = L.gtd_env_loading
		end
	end
end

-- 每秒更新密鑰與環境資訊
task.spawn(function()
	while true do
		pcall(Mainfunction.RefreshkeyInfo)
		pcall(Mainfunction.RefreshEquippedTowers)
		task.wait(1)
	end
end)

-- === Tab_summon（抽取）=== --
do
	local Summon = {
		selectedBox = nil, -- 當前選的箱 id
		qty = 1,           -- 1 或 10
		drawing = false,   -- 是否正在連抽
		bannedSet = {}     -- 當前箱已封鎖塔 set
	}
	Scripttable.GUI.Modules.Tab_summon._state = Summon

	Tab_summon:Separator({ Text = L.summon_box_select })

	-- 前向宣告（Combo 的 Callback 需要）
	local onSelectBox

	-- 下拉選單（箱清單；用 GetItems 動態取，避免 GTD 尚未載入）
	Tab_summon:Combo({
		Label = L.summon_choose_box,
		Placeholder = L.summon_click_select,
		GetItems = function()
			local items = {}
			Summon._nameToId = {}
			Summon._boxInfoById = {}
			local GTD = getgenv().GTD
			if GTD and GTD.GetBoxList then
				local ok, list = pcall(GTD.GetBoxList)
				if ok and type(list) == "table" then
					for _, b in ipairs(list) do
						local disp = b.Name or b.ID
						items[# items + 1] = disp
						Summon._nameToId[disp] = b.ID
						Summon._boxInfoById[b.ID] = b
					end
				end
			end
			if # items == 0 then
				items[1] = L.gtd_not_loaded_parentheses
			end
			return items
		end,
		Callback = function(_, name)
			local boxId = Summon._nameToId and Summon._nameToId[name]
			if boxId and onSelectBox then
				onSelectBox(boxId, Summon._boxInfoById[boxId])
			end
		end
	})

	-- 箱資訊（名稱 + 貨幣 + x1/x10 價格）
	local boxInfoLabel = Tab_summon:Label({ TextSize = fontSize, Text = L.summon_please_select })

	-- 可抽取塔表格（4 欄：箱子物品 | 是否擁有 | 機率 | 自動刪除）
	Tab_summon:Separator({ Text = L.summon_available_units })
	local itemTable = Tab_summon:Table({ MaxColumns = 4, RowBackground = true })
	Summon._itemTable = itemTable

	-- 欄寬控制：固定某欄寬度（退出 flex 平均分配）；不套用 fixCol 的欄會自動填滿剩餘。
	-- 調這三個數字即可微調：擁有/機率/自動刪除 欄寬(px)；箱子物品=填滿（最寬）。
	local W_OWN, W_CHANCE, W_BAN = 42, 72, 70
	local function fixCol(col, widthPx)
		local frame = col.RawObject
		if frame then
			local flex = Instance.new("UIFlexItem")
			flex.FlexMode = Enum.UIFlexMode.None
			flex.Parent = frame
			frame.Size = UDim2.new(0, widthPx, 1, 0)
		end
		return col
	end

	-- 重建掉落塔表
	local function rebuildItems(boxId)
		itemTable:ClearRows()
		Summon.bannedSet = {}

		-- 標題列（箱子物品欄填滿、其餘固定窄寬）
		local hdr = itemTable:NextRow()
		hdr:NextColumn():Label({ TextSize = fontSize, Bold = true, Text = L.summon_box_items })
		fixCol(hdr:NextColumn(), W_OWN):Label({ TextSize = fontSize, Bold = true, Text = L.summon_owned })
		fixCol(hdr:NextColumn(), W_CHANCE):Label({ TextSize = fontSize, Bold = true, Text = L.summon_chance })
		fixCol(hdr:NextColumn(), W_BAN):Label({ TextSize = fontSize, Bold = true, Text = L.summon_auto_delete })

		local GTD = getgenv().GTD
		if not (GTD and GTD.GetBoxItems) then
			return
		end
		-- 已封鎖塔（初始狀態）
		if GTD.GetBannedUnits then
			local ok, banned = pcall(GTD.GetBannedUnits, boxId)
			if ok and type(banned) == "table" then
				for _, u in ipairs(banned) do
					Summon.bannedSet[u] = true
				end
			end
		end
		-- 持有的 unit_id（一次掃，給「是否擁有」查詢）
		local owned = {}
		if GTD.GetOwnedUnitIDs then
			local ok, set = pcall(GTD.GetOwnedUnitIDs)
			if ok and type(set) == "table" then
				owned = set
			end
		end
		local ok, items = pcall(GTD.GetBoxItems, boxId)
		if not (ok and type(items) == "table") then
			return
		end
		for _, it in ipairs(items) do
			local unitId = it.ID
			local row = itemTable:NextRow()
			-- 第 1 欄：物品名稱（填滿，最寬）
			row:NextColumn():Label({ TextSize = fontSize, Text = it.Name or unitId })
			-- 第 2 欄：是否擁有（✓ = 已持有；窄欄）
			fixCol(row:NextColumn(), W_OWN):Label({ TextSize = fontSize, Text = owned[unitId] and "✓" or "" })
			-- 第 3 欄：機率（窄欄）
			fixCol(row:NextColumn(), W_CHANCE):Label({ TextSize = fontSize, Text = tostring(it.Chance) .. "%" })
			-- 第 4 欄：自動刪除（Radiobox 不顯示標籤，開=封鎖該塔抽不到；窄欄）
			local rbLockRow = false
			fixCol(row:NextColumn(), W_BAN):Radiobox({
				Label = "",
				Value = Summon.bannedSet[unitId] == true,
				Callback = function(self, v)
					if rbLockRow then
						return
					end
					local g = getgenv().GTD
					if not (g and g.SetUnitBanned) or not g.SetUnitBanned(boxId, unitId, v) then
						Msg:Warning(g and L.summon_lock_failed or L.gtd_not_loaded)
						rbLockRow = true
						self:SetValue(not v) -- 還原
						rbLockRow = false
						return
					end
					Summon.bannedSet[unitId] = v or nil
				end
			})
		end
	end

	-- 選箱
	onSelectBox = function(boxId, info)
		Summon.selectedBox = boxId
		-- 切箱時停止連抽
		Summon.drawing = false
		if Summon._startToggle then
			Summon._startToggle:SetValue(false)
		end
		if info then
			boxInfoLabel.Text = string.format(L.summon_box_info_format,
				info.Name or boxId, tostring(info.Currency), tostring(info.Price), tostring(info.Price10))
		else
			boxInfoLabel.Text = tostring(boxId)
		end
		rebuildItems(boxId)
	end

	-- === 抽取設定 === --
	Tab_summon:Separator({ Text = L.summon_settings })

	-- x1 / x10 單選（MaxColumns=2，必須保持一個開啟）
	local qtyRow = Tab_summon:Table({ MaxColumns = 2 }):NextRow()
	local rbX1, rbX10
	local rbLock = false
	local function selectQty(q)
		if rbLock then
			return
		end
		rbLock = true
		Summon.qty = q
		if rbX1 then rbX1:SetValue(q == 1) end
		if rbX10 then rbX10:SetValue(q == 10) end
		rbLock = false
	end
	rbX1 = qtyRow:NextColumn():Radiobox({
		Label = L.summon_qty_x1,
		Value = true,
		Callback = function(self, v)
			if rbLock then return end
			if v then selectQty(1) else self:SetValue(true) end -- 不允許關掉自己
		end
	})
	rbX10 = qtyRow:NextColumn():Radiobox({
		Label = L.summon_qty_x10,
		Value = false,
		Callback = function(self, v)
			if rbLock then return end
			if v then selectQty(10) else self:SetValue(true) end
		end
	})

	-- 開始抽取（每 0.3 秒一抽，失敗自動停）
	Summon._startToggle = Tab_summon:Checkbox({
		Label = L.summon_start_checkbox,
		Value = false,
		Callback = function(self, v)
			if v and not Summon.selectedBox then
				Msg:Warning(L.summon_please_select)
				self:SetValue(false)
				return
			end
			Summon.drawing = v
			if v then
				task.spawn(function()
					while Summon.drawing do
						local box = Summon.selectedBox
						if not box then break end
						local GTD = getgenv().GTD
						if not (GTD and GTD.BuyBox) then
							Msg:Warning(L.gtd_not_loaded)
							Summon.drawing = false
							break
						end
						local okBuy = GTD.BuyBox(box, Summon.qty)
						if not okBuy then
							Summon.drawing = false
							Msg:Warning(L.summon_stop_failed)
							break
						end
						task.wait(0.3)
					end
					Summon.drawing = false
					if Summon._startToggle then
						Summon._startToggle:SetValue(false)
					end
				end)
			end
		end
	})
end


-- === Tab_Localscript（本地腳本，從遊戲內介面複製）=== --
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
		actionsFrame.Size = UDim2.new(0, 150, 1, 0)

		local ActionRow = ActionsCol:Row({ Expanded = true })

		-- 執行（Run）：讀檔 → loadstring → 背景執行
		ActionRow:SmallButton({
			Text = L.localscript_run,
			Callback = function()
				local okR, raw = pcall(readfile, script.path)
				if not okR or not raw then
					Msg:Warning(L.localscript_error .. ": " .. script.name)
					return
				end
				local fn, lerr = loadstring(raw)
				if not fn then
					Msg:Warning(L.localscript_error .. ": " .. tostring(lerr))
					return
				end
				task.spawn(function()
					local okE, eerr = pcall(fn)
					if okE then
						Msg:Success(L.localscript_done .. ": " .. script.name)
					else
						Msg:Warning(L.localscript_error .. ": " .. tostring(eerr))
					end
				end)
			end,
		})

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
						local row1 = L.info_map .. ": " .. map .. " | " .. L.info_difficulty .. ": " .. diff
						if timeStr then row1 = row1 .. " | " .. L.info_time .. ": " .. timeStr end
						out[#out + 1] = row1
					end
					if mod and mod ~= "" then
						out[#out + 1] = "<font color='#FFB347'>" .. L.info_modifier .. ":</font>"
						for part in (mod .. ","):gmatch("([^,]+),") do
							local trimmed = part:match("^%s*(.-)%s*$")
							if trimmed ~= "" then
								out[#out + 1] = "  " .. trimmed
							end
						end
					end
					if #towers > 0 then
						out[#out + 1] = "<font color='#5BC8F5'>" .. L.info_towers_used .. ":</font>"
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
				local row1 = L.info_map .. ": " .. map .. " | " .. L.info_difficulty .. ": " .. diff
				if timeStr then row1 = row1 .. " | " .. L.info_time .. ": " .. timeStr end
				out[#out + 1] = row1
			end
			if mod and mod ~= "" then
				out[#out + 1] = "<font color='#FFB347'>" .. L.info_modifier .. ":</font>"
				for part in (mod .. ","):gmatch("([^,]+),") do
					local trimmed = part:match("^%s*(.-)%s*$")
					if trimmed ~= "" then out[#out + 1] = "  " .. trimmed end
				end
			end
			if #towers > 0 then
				out[#out + 1] = "<font color='#5BC8F5'>" .. L.info_towers_used .. ":</font>"
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

-- === Tab_settings：反巨集輪換設定（與遊戲內共用設定檔）===
-- 設定檔以「玩家 UserId」為外層 key：UserId 不隨場景變，同帳號大廳/關卡共用同一份，
-- 故大廳編輯即關卡內輪換生效；不同帳號各自獨立（多帳號）。
do
	local ROTATION_KEY = tostring(game:GetService("Players").LocalPlayer.UserId)

	local Rotation = {
		configPath = "Tsetingnil_script/GTD/Config/Rotation_Config.json",
		scriptDir  = "Tsetingnil_script/GTD/Script",
		pool       = {},
		interval   = 30,
		lastPicked = nil,
	}

	local function ensureFolder()
		pcall(function()
			if not isfolder or not makefolder then return end
			if not isfolder("Tsetingnil_script") then makefolder("Tsetingnil_script") end
			if not isfolder("Tsetingnil_script/GTD") then makefolder("Tsetingnil_script/GTD") end
			if not isfolder("Tsetingnil_script/GTD/Config") then makefolder("Tsetingnil_script/GTD/Config") end
		end)
	end

	local function load()
		local ok, data = pcall(function()
			if not (isfile and isfile(Rotation.configPath) and readfile) then return nil end
			return HttpService:JSONDecode(readfile(Rotation.configPath))
		end)
		if ok and type(data) == "table" then
			local entry = data[ROTATION_KEY]
			if type(entry) == "table" then
				Rotation.pool       = type(entry.pool) == "table" and entry.pool or {}
				Rotation.interval   = tonumber(entry.interval) or 30
				Rotation.lastPicked = entry.lastPicked
			end
		end
		if Rotation.interval < 1 then Rotation.interval = 1 end
	end

	local function save()
		pcall(function()
			if not writefile then return end
			ensureFolder()
			-- 讀回現有檔，保留其他 PlaceId 區段；lastPicked 用磁碟最新值（避免覆蓋遊戲內輪換進度）
			local all = {}
			local prevLast = Rotation.lastPicked
			local ok, existing = pcall(function()
				if isfile and isfile(Rotation.configPath) and readfile then
					return HttpService:JSONDecode(readfile(Rotation.configPath))
				end
			end)
			if ok and type(existing) == "table" then
				all = existing
				local e = existing[ROTATION_KEY]
				if type(e) == "table" and e.lastPicked ~= nil then
					prevLast = e.lastPicked
				end
			end
			all[ROTATION_KEY] = {
				pool       = Rotation.pool,
				interval   = Rotation.interval,
				lastPicked = prevLast,
			}
			writefile(Rotation.configPath, HttpService:JSONEncode(all))
		end)
	end

	local function listScripts()
		local names = {}
		local ok, files = pcall(listfiles, Rotation.scriptDir)
		if ok and files then
			for _, fp in ipairs(files) do
				local name = fp:match("([^/\\]+)$") or fp
				if name:match("%.lua$") then names[#names + 1] = name end
			end
		end
		table.sort(names)
		return names
	end

	local function inPool(name)
		for _, n in ipairs(Rotation.pool) do
			if n == name then return true end
		end
		return false
	end
	local function setInPool(name, on)
		if on then
			if not inPool(name) then Rotation.pool[#Rotation.pool + 1] = name end
		else
			for i = #Rotation.pool, 1, -1 do
				if Rotation.pool[i] == name then table.remove(Rotation.pool, i) end
			end
		end
	end

	load()

	Tab_settings:Separator({ Text = L.rotation_pool_header })

	Tab_settings:InputInt({
		Value = Rotation.interval,
		Label = L.rotation_interval_label,
		Increment = 1,
		Minimum = 1,
		Maximum = 999,
		Callback = function(_, v)
			Rotation.interval = math.max(1, math.floor(tonumber(v) or 30))
		end,
	})

	local rotTable = Tab_settings:Table()
	local function buildRotList()
		rotTable:ClearRows()
		local names = listScripts()
		if #names == 0 then
			rotTable:NextRow():Column():Label({ Text = L.rotation_no_scripts })
			return
		end
		for _, name in ipairs(names) do
			rotTable:NextRow():Column():Checkbox({
				Value = inPool(name),
				Label = name,
				Callback = function(_, on)
					setInPool(name, on)
				end,
			})
		end
	end
	buildRotList()

	local rotBtnRow = Tab_settings:Row()
	rotBtnRow:Button({
		Text = L.rotation_refresh_btn,
		Callback = function()
			buildRotList()
		end,
	})
	rotBtnRow:Button({
		Text = L.rotation_save_btn,
		Callback = function()
			save()
			if Msg and Msg.Success then
				Msg:Success(string.format(L.rotation_saved_msg, #Rotation.pool, Rotation.interval))
			end
		end,
	})
end

-- === Tab_event（活動）
