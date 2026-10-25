--[[
================================================================
                  花園塔防 GTD｜塔效果翻譯
================================================================
【功能】
  把遊戲中英文的塔 / 敵人效果說明與詞條說明換成中文（Roblox 自動翻譯未涵蓋這部分）。
  適用於：背包 / 圖鑑的懸停說明、Info 說明面板、關卡內的塔查看器。

【使用方式】
  - 大廳或關卡內執行皆可，每場只需執行一次。
  - 執行前已打開過的卡片，關掉背包重開即會更新。
  - 語言依 Tsetingnil_script/keysystem.json 的 script_language（預設中文），
    英文則保留遊戲原文。

【原理】
  不改動 UI，直接替換遊戲資料表中的說明文字，介面顯示時就會讀到中文：
    - SharedItemData 的 Units（塔與敵人）Params.CustomDescription
    - ReplicatedStorage.Others.CustomDescriptions（建立單位時的來源表）
    - SharedItemData 的 RollableTraits（詞條）Params.Description
  翻譯以 unit id 為鍵，變種塔（如 bronze / silver / gold 系列）沿用本體的翻譯。
  尚未翻譯的項目維持英文，並列在控制台。
================================================================
--]]

-- 本場已翻譯過則略過
if getgenv().GTD_DESC_ZH_LOADED then
	return
end

-- ============================================================
-- 載入翻譯表（內容即「塔效果翻譯表.lua」，存放於 Gist）
-- ============================================================
-- 每次執行都從 Gist 載入最新版，本地不儲存。
local TRANSLATION_URL = "https://gist.githubusercontent.com/Tseting-nil/76bf5dc90cc37c46e0a469da6b58e252/raw/%25E8%258A%25B1%25E5%259C%2592%25E5%25A1%2594%25E6%2588%25BF%25E5%25A1%2594%25E7%25BF%25BB%25E8%25AD%25AF%25E8%25A1%25A8"

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

local okHttp, remoteSrc = pcall(function()
	return game:HttpGet(TRANSLATION_URL)
end)
local Translation = okHttp and runSource(remoteSrc) or nil

if not Translation then
	warn(string.format("[塔效果翻譯] 翻譯表載入失敗（%s），說明維持英文",
		okHttp and "內容無效" or tostring(remoteSrc)))
	return
end
-- 英文：翻譯表為空，保留遊戲原文
if next(Translation.Units or {}) == nil and next(Translation.Traits or {}) == nil then
	print("[Tower Description] Language: " .. tostring(Translation.Lang) .. ", keeping the original descriptions")
	return
end
local ZH_UNIT = Translation.Units or {}
local ZH_TRAIT = Translation.Traits or {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ============================================================
-- 套用翻譯
-- ============================================================
-- 暫時切到 identity 2 執行 fn（部分執行器在高 identity 下 require 遊戲模組會拿到空表或報錯）
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
	local ok, err = pcall(fn)
	if setId then
		pcall(setId, oldId)
	end
	if not ok then
		warn("[塔效果翻譯] 失敗：", err)
	end
end

-- 找到 SharedItemData 模組（遊戲的物品資料表）
local function findSharedItemData()
	local plr = Players.LocalPlayer
	local node = plr and plr:WaitForChild("PlayerGui", 10)
	for _, name in ipairs({ "LogicHolder", "ClientLoader", "Modules", "SharedItemData" }) do
		node = node and node:WaitForChild(name, 10)
	end
	return node
end

local stats = { units = 0, traits = 0, missing = {} } -- 替換筆數與未翻譯清單

withIdentity2(function()
	local cdModule = ReplicatedStorage:WaitForChild("Others", 10)
	cdModule = cdModule and cdModule:WaitForChild("CustomDescriptions", 10)
	local CD = cdModule and require(cdModule)

	-- 同步替換來源表 CustomDescriptions（之後新建的單位也是中文），
	-- 並建立「英文原文 → 中文」對照，供沒有獨立條目、但說明文字相同的單位使用
	local byText = {}
	if type(CD) == "table" then
		for id, zh in pairs(ZH_UNIT) do
			local en = CD[id]
			if type(en) == "string" then
				byText[en] = zh
				CD[id] = zh
			end
		end
	end

	local sidModule = findSharedItemData()
	local SID = sidModule and require(sidModule)
	if type(SID) ~= "table" then
		warn("[塔效果翻譯] 找不到 SharedItemData")
		return
	end

	-- 塔 / 敵人說明。查找順序：自身 id → 本體（BaseUnit，變種塔用）→ 相同原文
	for _, item in pairs(SID.GetCategory("Units") or {}) do
		local p = item.Params
		local desc = p and p.CustomDescription
		if type(desc) == "string" then
			local zh = ZH_UNIT[item.ID] or (p.BaseUnit and ZH_UNIT[p.BaseUnit]) or byText[desc]
			if zh then
				if desc ~= zh then
					p.CustomDescription = zh
					stats.units = stats.units + 1
				end
			elseif not desc:find("[\128-\255]") then -- 已是非英文（含多位元組字元）的不列入
				table.insert(stats.missing, item.ID)
			end
		end
	end

	-- 詞條說明
	for _, item in pairs(SID.GetCategory("RollableTraits") or {}) do
		local p = item.Params
		local zh = ZH_TRAIT[item.ID]
		if p and zh and p.Description ~= zh then
			p.Description = zh
			stats.traits = stats.traits + 1
		elseif p and type(p.Description) == "string" and not zh then
			table.insert(stats.missing, item.ID)
		end
	end
end)

getgenv().GTD_DESC_ZH_LOADED = true
--print(string.format("[塔效果翻譯] 完成：單位說明 %d 筆、詞條說明 %d 筆（已開過的卡片請關掉背包重開）", stats.units, stats.traits))
if #stats.missing > 0 then
	table.sort(stats.missing) -- 方便回報補表
	warn("[塔效果翻譯] 尚未翻譯（維持英文）：" .. table.concat(stats.missing, ", "))
end
