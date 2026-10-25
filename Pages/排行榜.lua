--[[
================================================================
                花園塔防 GTD 排行榜
================================================================
取代 Roblox 原生玩家列表，顯示：玩家 / 種子 / DPS / 金錢 / 當前總傷害（依總傷害排序）。

資料來源（客戶端已有，不送 remote）：
  - 種子：Player.leaderstats.Seeds（遊戲已格式化，例如 5.48M）
  - 金錢：Player 的 Cash 屬性（關卡內的金錢）
  - 總傷害：每座塔的 Data.StatMetrics.TotalDamage（伺服器 StatMetricBatch 會廣播給所有人，
    所以隊友的也看得到），依 Data.Owner 加總。
    賣掉的塔不會消失在統計裡（記住每座塔最後的數值）；新的一局（GameStartTime 改變）重新計算。
  - DPS：每次刷新記一筆「與上一次刷新相比的總傷害增加量 ÷ 經過秒數」，
    取最近 1 分鐘內所有資料的總和 ÷ 資料數（實際輸出，含各種加成；遊戲加速時數字也會跟著變大）。

位置在右上角；自動排到。
按 Tab 顯示 / 隱藏（同原生列表）。再執行一次 = 關閉並恢復原生玩家列表。
介面文字依 Tsetingnil_script/keysystem.json 的 script_language（同 API）切換中文 / 英文，預設中文。
================================================================
--]]

local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

local GUI_NAME = "GTD_Leaderboard"
local LocalPlayer = Players.LocalPlayer
local DPS_WINDOW = 60 -- 秒：DPS 取這段時間內的資料平均
local REFRESH = 0.5 -- 秒

local guiParent = (gethui and gethui()) or game:GetService("CoreGui")

-- ============================================================
-- i18n：語言偵測同 API（讀 Tsetingnil_script/keysystem.json 的 script_language，預設中文）
-- ============================================================
local Lang = "zh"
pcall(function()
	if isfile and isfile("Tsetingnil_script/keysystem.json") then
		local content = readfile("Tsetingnil_script/keysystem.json")
		if content then
			local scriptLang = nil
			-- 優先使用 HttpService 解析 JSON
			local ok, data = pcall(function()
				return game:GetService("HttpService"):JSONDecode(content)
			end)
			if ok and data and data.script_language then
				scriptLang = data.script_language
			else
				-- 備援：正則匹配
				scriptLang = content:match('"script_language"%s*:%s*"([^"]+)"')
			end
			if scriptLang then
				local sl = scriptLang:lower()
				if sl:find("chinese") or sl:find("zh") then
					Lang = "zh"
				elseif sl:find("english") or sl:find("en") then
					Lang = "en"
				end
			end
		end
	end
end)

local i18n = {
	zh = {
		col_name = "玩家",
		col_seeds = "種子",
		col_dps = "DPS",
		col_cash = "金錢",
		col_damage = "總傷害",
		log_closed = "[排行榜] 已關閉，恢復原生玩家列表",
		log_opened = "[排行榜] 已開啟（Tab 顯示 / 隱藏，再執行一次關閉並恢復原生列表）",
		log_update_failed = "[排行榜] 更新失敗：",
	},
	en = {
		col_name = "Player",
		col_seeds = "Seeds",
		col_dps = "DPS",
		col_cash = "Cash",
		col_damage = "Damage",
		log_closed = "[Leaderboard] Closed, native player list restored",
		log_opened = "[Leaderboard] Opened (Tab to show / hide, run again to close and restore the native list)",
		log_update_failed = "[Leaderboard] Update failed:",
	},
}

local function t(key)
	local tbl = i18n[Lang] or i18n.zh
	return tbl[key] or i18n.zh[key] or key
end

local function setNativeList(enabled)
	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, enabled)
	end)
end

-- 開關：已開啟就關閉
if getgenv().GTD_LEADERBOARD_CLEANUP then
	pcall(getgenv().GTD_LEADERBOARD_CLEANUP)
	getgenv().GTD_LEADERBOARD_CLEANUP = nil
	print(t("log_closed"))
	return
end

-- ============================================================
-- 遊戲單位模組（關卡內才有塔；大廳只顯示種子）
-- ============================================================
local UnitBase = nil
do
	local getId = getthreadidentity or getidentity
	local setId = setthreadidentity or setidentity
	local oldId = getId and getId() or 8
	if setId then
		pcall(setId, 2)
	end
	pcall(function()
		local node = LocalPlayer:WaitForChild("PlayerGui", 10)
		for _, name in ipairs({ "LogicHolder", "ClientLoader", "SharedConfig", "ItemData", "Units", "Behaviors", "base" }) do
			node = node and node:WaitForChild(name, 10)
		end
		UnitBase = node and require(node)
	end)
	if setId then
		pcall(setId, oldId)
	end
end

-- ============================================================
-- 統計
-- ============================================================
local unitDamage = {} -- [unit ID] = { owner = 名稱, damage = 最後的 TotalDamage }
local history = {} -- [玩家名] = { lastT, lastTotal, samples = { {t, dps}, ... } }（DPS 用）
local lastGameStart = workspace:GetAttribute("GameStartTime")

local function ownerName(owner)
	if typeof(owner) == "Instance" and owner:IsA("Player") then
		return owner.Name
	end
	return owner and tostring(owner) or nil
end

local function collectDamage()
	-- 新的一局：清空
	local gst = workspace:GetAttribute("GameStartTime")
	if gst ~= lastGameStart then
		lastGameStart = gst
		unitDamage = {}
		history = {}
	end
	if UnitBase and UnitBase.GetActiveUnits then
		local ok, units = pcall(UnitBase.GetActiveUnits)
		if ok and type(units) == "table" then
			for _, unit in ipairs(units) do
				local data = unit.Data
				local metrics = type(data) == "table" and data.StatMetrics
				local owner = type(data) == "table" and ownerName(data.Owner)
				if owner and type(metrics) == "table" and tonumber(metrics.TotalDamage) then
					unitDamage[unit.ID] = { owner = owner, damage = tonumber(metrics.TotalDamage) }
				end
			end
		end
	end
	local totals = {}
	for _, rec in pairs(unitDamage) do
		totals[rec.owner] = (totals[rec.owner] or 0) + rec.damage
	end
	return totals
end

-- 每次刷新記一筆 DPS 資料（與上一次相比的傷害增加量 ÷ 經過秒數），
-- 回傳最近 DPS_WINDOW 秒內所有資料的總和 ÷ 資料數
local function updateDps(name, total, now)
	local h = history[name]
	if not h then
		h = { lastT = now, lastTotal = total, samples = {} }
		history[name] = h
		return 0
	end
	local dt = now - h.lastT
	if dt > 0 then
		table.insert(h.samples, { t = now, dps = math.max(0, (total - h.lastTotal) / dt) })
	end
	h.lastT, h.lastTotal = now, total
	while h.samples[1] and now - h.samples[1].t > DPS_WINDOW do
		table.remove(h.samples, 1)
	end
	local count = #h.samples
	if count == 0 then
		return 0
	end
	local sum = 0
	for _, s in ipairs(h.samples) do
		sum = sum + s.dps
	end
	return sum / count
end

-- 1234 → 1.23K、5480000 → 5.48M
local function abbreviate(n)
	n = tonumber(n) or 0
	local units = { { 1e12, "T" }, { 1e9, "B" }, { 1e6, "M" }, { 1e3, "K" } }
	for _, u in ipairs(units) do
		if math.abs(n) >= u[1] then
			return string.format("%.2f%s", n / u[1], u[2])
		end
	end
	return tostring(math.floor(n + 0.5))
end

local function seedsOf(player)
	local ls = player:FindFirstChild("leaderstats")
	local v = ls and ls:FindFirstChild("Seeds")
	return v and tostring(v.Value) or "-"
end

-- ============================================================
-- UI（仿原生玩家列表，右上角）
-- ============================================================
local COLS = {
	{ key = "name", title = t("col_name"), width = 0.33, align = Enum.TextXAlignment.Left },
	{ key = "seeds", title = t("col_seeds"), width = 0.15, align = Enum.TextXAlignment.Right },
	{ key = "dps", title = t("col_dps"), width = 0.15, align = Enum.TextXAlignment.Right },
	{ key = "cash", title = t("col_cash"), width = 0.16, align = Enum.TextXAlignment.Right },
	{ key = "damage", title = t("col_damage"), width = 0.21, align = Enum.TextXAlignment.Right },
}
local ROW_H = 30
local WIDTH = 450

-- 遊戲主介面（座標設定要跟它一致，避讓計算才對得上）
local gameGui = LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("GameGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = GUI_NAME
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 10
if gameGui then
	screenGui.IgnoreGuiInset = gameGui.IgnoreGuiInset
	screenGui.ScreenInsets = gameGui.ScreenInsets
end
screenGui.Parent = guiParent

local frame = Instance.new("Frame")
frame.AnchorPoint = Vector2.new(1, 0)
frame.Position = UDim2.new(1, -8, 0, 4)
frame.Size = UDim2.fromOffset(WIDTH, 0)
frame.AutomaticSize = Enum.AutomaticSize.Y
frame.BackgroundTransparency = 1
frame.Parent = screenGui
local listLayout = Instance.new("UIListLayout", frame)
listLayout.Padding = UDim.new(0, 2)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder

local function makeRow(order, isHeader)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, isHeader and 26 or ROW_H)
	row.BackgroundColor3 = Color3.fromRGB(25, 27, 32)
	row.BackgroundTransparency = isHeader and 0.15 or 0.3
	row.BorderSizePixel = 0
	row.LayoutOrder = order
	row.Parent = frame
	Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)
	local pad = Instance.new("UIPadding", row)
	pad.PaddingLeft, pad.PaddingRight = UDim.new(0, 10), UDim.new(0, 10)
	local cells = {}
	local x = 0
	for _, col in ipairs(COLS) do
		local l = Instance.new("TextLabel")
		l.BackgroundTransparency = 1
		l.Position = UDim2.new(x, 0, 0, 0)
		l.Size = UDim2.new(col.width, -4, 1, 0)
		l.Font = isHeader and Enum.Font.GothamBold or Enum.Font.GothamMedium
		l.TextSize = isHeader and 13 or 14
		l.TextColor3 = isHeader and Color3.fromRGB(170, 175, 190) or Color3.new(1, 1, 1)
		l.TextXAlignment = col.align
		l.TextTruncate = Enum.TextTruncate.AtEnd
		l.Text = isHeader and col.title or ""
		l.Parent = row
		cells[col.key] = l
		x = x + col.width
	end
	return row, cells
end

makeRow(0, true)
local rows = {} -- [玩家名] = { row, cells }

local function render(totals, dpsByName)
	-- 每位玩家的資料（離開的玩家移除）
	local entries = {}
	for _, p in ipairs(Players:GetPlayers()) do
		table.insert(entries, {
			player = p,
			damage = totals[p.Name] or 0,
			dps = dpsByName[p.Name] or 0,
		})
	end
	table.sort(entries, function(a, b)
		if a.damage ~= b.damage then
			return a.damage > b.damage
		end
		return a.player.Name:lower() < b.player.Name:lower()
	end)
	local present = {}
	for i, e in ipairs(entries) do
		local name = e.player.Name
		present[name] = true
		local r = rows[name]
		if not r then
			local row, cells = makeRow(i, false)
			r = { row = row, cells = cells }
			rows[name] = r
		end
		r.row.LayoutOrder = i
		local isMe = e.player == LocalPlayer
		r.row.BackgroundColor3 = isMe and Color3.fromRGB(40, 70, 120) or Color3.fromRGB(25, 27, 32)
		r.cells.name.Text = e.player.DisplayName ~= name and (e.player.DisplayName .. " (@" .. name .. ")") or name
		r.cells.seeds.Text = seedsOf(e.player)
		r.cells.dps.Text = abbreviate(e.dps)
		local cash = tonumber(e.player:GetAttribute("Cash"))
		r.cells.cash.Text = cash and ("$" .. abbreviate(cash)) or "-"
		r.cells.damage.Text = abbreviate(e.damage)
		r.cells.damage.TextColor3 = (i == 1 and e.damage > 0) and Color3.fromRGB(255, 205, 80) or Color3.new(1, 1, 1)
	end
	for name, r in pairs(rows) do
		if not present[name] then
			r.row:Destroy()
			rows[name] = nil
		end
	end
end

-- ============================================================
-- 避開遊戲右上角的塔能力欄（UnitAbilities：關閉鈕、能力卡片）
-- 原生玩家列表不會擋到它；自建排行榜放右上角會重疊 → 有能力欄時排到它左邊。
-- ============================================================
local function isShown(o)
	while o and o:IsA("GuiObject") do
		if not o.Visible then
			return false
		end
		o = o.Parent
	end
	return true
end

local function updatePosition()
	local abilities = gameGui and gameGui:FindFirstChild("Screen")
	abilities = abilities and abilities:FindFirstChild("Right")
	abilities = abilities and abilities:FindFirstChild("UnitAbilities")
	local top = frame.AbsolutePosition.Y
	local bottom = top + frame.AbsoluteSize.Y
	local minX = nil
	if abilities and gameGui.Enabled and isShown(abilities) then
		for _, d in ipairs(abilities:GetDescendants()) do
			-- 只看有實際大小、且與排行榜同高度範圍的可見元件
			if d:IsA("GuiObject") and d.AbsoluteSize.X > 20 and d.AbsoluteSize.Y > 20 and d.AbsoluteSize.X < 400 then
				local y = d.AbsolutePosition.Y
				if y < bottom and y + d.AbsoluteSize.Y > top and isShown(d) then
					local x = d.AbsolutePosition.X
					if not minX or x < minX then
						minX = x
					end
				end
			end
		end
	end
	if minX then
		frame.AnchorPoint = Vector2.new(1, 0)
		frame.Position = UDim2.fromOffset(minX - screenGui.AbsolutePosition.X - 8, 4)
	else
		frame.AnchorPoint = Vector2.new(1, 0)
		frame.Position = UDim2.new(1, -8, 0, 4)
	end
end

-- ============================================================
-- 啟動 / 關閉
-- ============================================================
setNativeList(false)

local alive = true
local inputConn = UserInputService.InputBegan:Connect(function(input, processed)
	if not processed and input.KeyCode == Enum.KeyCode.Tab then
		frame.Visible = not frame.Visible
	end
end)

task.spawn(function()
	while alive and screenGui.Parent do
		local ok, err = pcall(function()
			local totals = collectDamage()
			local now = os.clock()
			local dpsByName = {}
			for _, p in ipairs(Players:GetPlayers()) do
				dpsByName[p.Name] = updateDps(p.Name, totals[p.Name] or 0, now)
			end
			render(totals, dpsByName)
			updatePosition()
		end)
		if not ok then
			warn(t("log_update_failed"), err)
		end
		task.wait(REFRESH)
	end
end)

getgenv().GTD_LEADERBOARD_CLEANUP = function()
	alive = false
	inputConn:Disconnect()
	screenGui:Destroy()
	setNativeList(true)
end

print(t("log_opened"))
