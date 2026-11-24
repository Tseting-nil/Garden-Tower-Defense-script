# 花園塔防 GTD 花園塔房 API 說明文件

花園塔防（Garden Tower Defense）的「放置追蹤器」與自動化腳本專用 API。追蹤器錄製關卡內操作後，會生成呼叫本 API 的腳本來重現流程。

> [!NOTE]
> - 載入密鑰系統：`loadstring(game:HttpGet("https://raw.githubusercontent.com/Tseting-nil/Garden-Tower-Defense-script/refs/heads/main/%E5%AF%86%E9%91%B0%E7%B3%BB%E7%B5%B1.lua"))()`
> - 載入密鑰系統後會回傳全域表 `GTD`，亦可透過 `getgenv().GTD` 或 `getgenv().GTDAPI` 確認是否已經加載。

---

## 1. 場景判斷與版本資訊

| API | 回傳值 | 說明 |
| :--- | :--- | :--- |
| `GTD.IsLobby()` | `boolean` | 是否在大廳（PlaceId `108533757090220`） |
| `GTD.IsInGame()` | `boolean` | 是否在關卡內（PlaceId `123516946198836`） |
| `GTD.GetAPIinfo()` | `table` | 回傳 `{ LastUpdateTime, LastUpdateVersion, CurrentGameVersion }`（最後更新時間、最後更新版本、遊戲當前版本） |

---

## 2. 遊戲結束檢測

| API | 回傳值 | 說明 |
| :--- | :--- | :--- |
| `GTD.IsGameOver()` | `boolean` | 主要以 `workspace.GameEndTime` 屬性判定（伺服器權威，不受 UI 面板切換影響），備援檢查 `GameEnd.Visible` |
| `GTD.IsGameEndVisible()` | `boolean` | 僅檢查 `GameGui.Screen.Middle.GameEnd.Visible` |
| `GTD.GetGameResult()` | `"victory" \| "defeat" \| "unknown"` | 先讀 `Victory/Defeat.Visible`，若 UI 被遮擋則以 `BaseHP <= 0` 推斷 |

### AutoReplay 流程說明
1. 等待遊戲結束（`GameEndTime` 被設值或 `GameEnd.Visible`，事件 + polling）。
2. 判斷 Victory / Defeat 並記錄結果。
3. 等待 `GameEnd.Items.Frame.Actions.Visible == true`（最多 12 秒，若被遮住則直接重開）。
4. 呼叫 `RestartGame:InvokeServer()`（最多重送 3 次防丟包）。
5. 等待 `GameStartTime` 改變以確認新一局開始。

---

## 3. 操作佇列（Queue）與關卡操作

先透過 `GTD.Add*` 將操作排入佇列，最後呼叫 `GTD.ExecuteQueue()` 依序執行。

- **閘門 `gate`**：`number` 代表開局後秒數；`string` 代表金錢門檻（如 `"$500"`，Cash 足夠才動作）。

| API | 說明 |
| :--- | :--- |
| `GTD.AddPlaceTower(unitId, gate, x, y, z, rotation [, pathIndex, distanceAlongPath])` | 加入放置塔操作，回傳遞增的 `order` 序號供後續升級/賣出參照；一般塔可略過 `pathIndex`/`distanceAlongPath`，沿路塔（如 `unit_wheel_bush`）才需帶入 |
| `GTD.AddUpgradeTower(order, gate)` | 加入升級操作（失敗時會等待金錢增加後重試） |
| `GTD.AddSellTower(order, gate)` | 加入賣出操作 |
| `GTD.AddTowerAbility(order, gate)` | 加入觸發塔能力操作（依 `order` 指定塔） |
| `GTD.AddSellAll(gate)` | 加入一鍵清場（清空場上所有塔與當輪 `order` 綁定） |
| `GTD.AddSetTargeting(order, mode, gate)` | 加入調整塔攻擊目標策略 |
| `GTD.AddToggleAutoUpgrade(order, gate)` | 加入切換自動升級操作 |
| `GTD.AddSkipWave(gate)` | 加入跳波操作 |
| `GTD.AddBuyPlot(plotId, gate)` | 加入購買活動地塊操作（自動裝備鐮刀並尋路至地塊旁，錢不夠會等待） |
| `GTD.AddSetAutoSkip(value, gate)` | 加入設定 Auto Skip 開關操作 |
| `GTD.AddSetSpeed(speed, gate)` | 加入變速操作（`speed = 1 / 2 / 3`） |
| `GTD.AddEnd(elapsed)` | 加入結束時間標記（開局後總秒數），確保重播時間軸忠於錄製 |
| `GTD.ExecuteQueue()` | 等待開局後依序執行佇列中的所有操作 |
| `GTD.GetQueueElapsed()` | 回傳開局後已過秒數；尚未開局回傳 `nil` |
| `GTD.GetQueueRemaining()` | 回傳距 `AddEnd` 結束點的剩餘秒數（負值代表已超過）；尚未開局或未呼叫 `AddEnd` 回傳 `nil` |

### 即時控制與自動重開

| API | 說明 |
| :--- | :--- |
| `GTD.SetAutoSkip(value)` | 立即設定 Auto Skip 開關 |
| `GTD.ActivateAbility(...)` | 立即觸發塔能力 |
| `GTD.SetTargeting(...)` | 立即設定塔攻擊目標策略 |
| `GTD.SellAll()` | 立即賣出所有塔 |
| `GTD.AutoReplay(value)` | 設定遊戲結束後是否自動重開 |
| `GTD.ResumeAutoReplay()` | 恢復自動重開監控 |
| `GTD.SetRetryOptions(...)` | 設定重試選項 |

---

## 4. 活動地塊（Plot）操作

| API | 回傳值 / 說明 |
| :--- | :--- |
| `GTD.BuyPlot(plotId [, waitCash])` | `ok, reason` — 立即購買活動地塊（`RemoteEvents.BuyPlot`） |
| `GTD.GetPlotInfo(plotId)` | `{Id, Unlocked, Buyable, Price, Centre, Size, Model}?` — 查詢地塊資訊 |
| `GTD.GetBuyablePlots()` | `{ plotId, ... }` — 取得目前可購買（鄰接已解鎖）的地塊 ID 列表 |
| `GTD.IsPlotMode()` | `boolean` — 判斷當前地圖是否為地塊模式 |
| `GTD.WaitForStartPlots([timeout])` | `ok, n` — 等待伺服器開啟初始地塊（`ExecuteQueue` 開局會自動等待） |

---

## 5. 反巨集抖動與特殊塔冷卻

### 反巨集抖動（預設開啟）
伺服器端無法取得滑鼠資訊，反巨集啟發式檢測主要針對 Remote 呼叫頻率、參數重複性與間隔規律。

```lua
GTD.SetJitter(false) -- 全關
GTD.SetJitter(true)  -- 全開（使用預設值）
GTD.SetJitter({
    actionDelayMin = 0.05,   -- 每個動作前隨機延遲下限（秒）
    actionDelayMax = 0.35,   -- 每個動作前隨機延遲上限（秒）
    placeOffsetStuds = 0.15, -- 非路徑塔放置水平微抖半徑（studs），0 為關閉
    pathDistJitter = 0,      -- 路徑塔沿路徑距離微抖量，0 為關閉
})
```

### 其他監控與冷卻設定
- `GTD.SetSpecialTowerCooldown(unitId, cooldownSeconds)`：設定或清除特殊塔放置冷卻（遊戲時間秒數，預設 `unit_ice_dragon = 10`；設為 `nil` 或 `<= 0` 清除）。
- `GTD.SetEquipToolOnPlace(enabled)`：設定放置前是否自動將對應塔 Tool 拿到手上（預設開啟）。
- `GTD.StartMacroNerfMonitor()` / `GTD.GetMacroNerf()`：啟動／讀取巨集檢測狀態。

---

## 6. 大廳選圖與傳送輔助

| API | 說明 |
| :--- | :--- |
| `GTD.SelectMap(...)` / `GTD.RawSelectMap(...)` | 選擇關卡地圖 |
| `GTD.SelectDifficulty(...)` | 選擇關卡難度 |
| `GTD.NavigateToLobbyForMap(...)` | 導航至支援指定地圖的大廳 |
| `GTD.SetLobbyMaxPlayers(...)` | 設定大廳人數上限 |
| `GTD.StartLobby(...)` | 開始大廳戰鬥 |
| `GTD.RejoinViaLobby()` | 透過大廳重連 |
| `GTD.SaveLocalScript(...)` | 儲存本地腳本 |
| `GTD.DeBug(enabled)` | 當 `enabled == true` 時載入放置追蹤器除錯工具 |

---

## 7. 裝備、單位查詢、抽箱、附魔與刷特性

### 裝備與單位轉換
- `GTD.EquipLoadout({ "unit_corn", ... })`：依 unit id 列表裝備隊伍
- `GTD.EquipTower(...)` / `GTD.Equip(...)` / `GTD.Unequip(...)` / `GTD.UnequipAll()`
- `GTD.GetEquipped()` / `GTD.SetEquipped(...)` / `GTD.GetHotbarTools()`
- `GTD.GetOwnedUniques()` / `GTD.GetOwnedUnitIDs()` / `GTD.ResolveUnique(...)`
- `GTD.ToID(...)` / `GTD.ToName(...)` / `GTD.GetUnit(...)` / `GTD.GetUnitCost(...)`
- `GTD.Search(...)` / `GTD.Reload()`

### 抽取箱子系統
- `GTD.GetBoxList()` / `GTD.GetBoxItems(...)` / `GTD.BuyBox(...)`
- `GTD.SetUnitBanned(...)` / `GTD.GetBannedUnits()`

### 每日附魔材料（大廳／關卡內皆可使用）
- `GTD.GetFertilizerStatus()` / `GTD.GetFertilizerDaily()` / `GTD.GetFertilizerResetTime()` / `GTD.ClaimFertilizerDaily()`

### 自動刷特性（僅大廳）
- `GTD.SpoofAutoRollPass()` / `GTD.EnableAutoRollHook()` / `GTD.OwnsAutoRollPass()`
- `GTD.RollTrait(...)` / `GTD.StopTraitRoll()` / `GTD.AutoRollTrait(...)` / `GTD.StopAutoRollTrait()`
- `GTD.SetTraitListener(...)`
- `GTD.TraitRollConfig`（設定表）
