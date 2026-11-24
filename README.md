# 中文說明 | [English](README_en.md)

適用於 Roblox《花園塔防》（Garden Tower Defense）的自動化腳本、操作錄製與多語系介面專案。

---

## 目錄結構 / Project Structure

```text
Garden Tower Defense/
├── 密鑰系統.lua          # 啟動入口與密鑰驗證（支援中／英文語言設定）
├── Pages/
│   ├── 大廳介面.lua      # 大廳輔助介面（選圖、隊伍裝備、抽箱、刷特性、每日附魔）
│   ├── 遊戲內介面.lua    # 關卡內控制介面（佇列重播、自動重開、流程控制）
│   ├── QueueMonitor.lua  # 佇列執行進度監視器
│   ├── 隊友塔查看.lua    # 隊友場上單位查看面板
│   ├── 排行榜.lua        # 自訂排行榜介面
│   ├── 塔效果翻譯.lua    # 塔效果翻譯模組
│   └── 塔效果翻譯表.lua  # 塔效果翻譯對照表
├── Tool/
│   ├── 放置追蹤器.lua    # 關卡操作錄製器，可匯出 GTD API 重播腳本
│   ├── API說明_zh.md     # API 說明文件
│   └── API_Reference_en.md  # API Reference
└── API/                  # API 說明文件目錄
```

## 核心功能 / Features

- **關卡錄製與自動重播（Placement Tracker & Queue Replay）**
  - 透過 `Tool/放置追蹤器.lua` 錄製放塔、升級、賣出、技能施放、買地塊、跳波與變速操作，並生成呼叫 `GTD` API 的重播腳本。
  - 支援以時間（秒數）或金錢門檻（`"$X"`）作為執行閘門，並提供 `AutoReplay` 自動重開局機制。
- **反巨集抖動與防 AFK（Anti-Macro Jitter & Anti-AFK）**
  - 支援動作隨機延遲、放置座標微抖動與特殊塔放置冷卻控管（`GTD.SetJitter` / `GTD.SetSpecialTowerCooldown`）。
- **大廳自動化與輔助介面（Lobby & In-Game GUI）**
  - 支援自動選圖／選難度／開局、隊伍裝備切換、箱子抽取、每日附魔材料領取與特性刷取。
  - 支援繁體中文與英文雙語介面切換（依 `Tsetingnil_script/keysystem.json` 的 `script_language` 設定自動載入）。

---

## 快速載入 / Quick Load

```lua
-- 錄製工具
loadstring(game:HttpGet("https://raw.githubusercontent.com/Tseting-nil/Garden-Tower-Defense-script/refs/heads/main/Tool/%E6%94%BE%E7%BD%AE%E8%BF%BD%E8%B9%A4%E5%99%A8.lua"))()
```

```lua
-- 大廳介面
loadstring(game:HttpGet("https://raw.githubusercontent.com/Tseting-nil/Garden-Tower-Defense-script/refs/heads/main/Pages/%E5%A4%A7%E5%BB%B3%E4%BB%8B%E9%9D%A2.lua"))()
```

```lua
-- 遊戲內介面
loadstring(game:HttpGet("https://raw.githubusercontent.com/Tseting-nil/Garden-Tower-Defense-script/refs/heads/main/Pages/%E9%81%8A%E6%88%B2%E5%85%A7%E4%BB%8B%E9%9D%A2.lua"))()
```
---

## API 概覽 / API Overview

載入核心腳本會註冊全域 `GTD` 表，常用分類如下：

- **場景與版本查詢**：`GTD.IsLobby()`、`GTD.IsInGame()`、`GTD.GetAPIinfo()`
- **遊戲結束檢測**：`GTD.IsGameOver()`、`GTD.IsGameEndVisible()`、`GTD.GetGameResult()`
- **操作佇列與執行**：`GTD.AddPlaceTower(...)`、`GTD.AddUpgradeTower(...)`、`GTD.AddSellTower(...)`、`GTD.AddTowerAbility(...)`、`GTD.AddBuyPlot(...)`、`GTD.AddSetSpeed(...)`、`GTD.AddEnd(...)`、`GTD.ExecuteQueue()`、`GTD.StopQueue()`、`GTD.AutoReplay(...)`
- **反巨集與冷卻設定**：`GTD.SetJitter(...)`、`GTD.SetSpecialTowerCooldown(...)`、`GTD.SetEquipToolOnPlace(...)`
- **大廳與單位管理**：`GTD.SelectMap(...)`、`GTD.SelectDifficulty(...)`、`GTD.StartLobby(...)`、`GTD.EquipLoadout(...)`、`GTD.BuyBox(...)`、`GTD.ClaimFertilizerDaily()`

詳細使用可參考[API 說明文件](Tool\API說明_zh.md)

---

## 免責條款 / Disclaimer

- 本專案僅供學習、研究與個人自動化測試用途，與 Roblox 官方及《花園塔防》（Garden Tower Defense）開發團隊無任何關聯。
- 使用本專案腳本可能違反遊戲或平台之服務條款（ToS），任何因使用本專案所導致的帳號封禁、收益懲罰（如 Macro Nerf）、資料遺失或其他風險，均由使用者自行承擔。
- 本專案以「現況（AS IS）」提供，作者不對腳本的穩定性、可用性、相容性或任何直接／間接損害負任何責任；遊戲更新亦可能導致部分或全部功能失效。
- 嚴禁將本專案用於商業販售、惡意攻擊或破壞其他玩家遊戲體驗之用途。