# English | [中文說明](README.md)

# Garden Tower Defense Script (`GTD`)

Automation, action recording, and multilingual GUI project for Roblox *Garden Tower Defense*.

---

## Project Structure

```text
Garden Tower Defense/
├── 密鑰系統.lua          # Entry loader & key verification (supports Chinese / English)
├── Pages/
│   ├── 大廳介面.lua      # Lobby GUI (map selection, loadout, crates, trait rolling, daily fertilizer)
│   ├── 遊戲內介面.lua    # In-Game GUI (queue replay, auto-replay, flow control)
│   ├── QueueMonitor.lua  # Queue execution progress monitor
│   ├── 隊友塔查看.lua    # Teammate tower inspection panel
│   ├── 排行榜.lua        # Custom leaderboard GUI
│   ├── 塔效果翻譯.lua    # Tower effect translation module
│   └── 塔效果翻譯表.lua  # Tower effect translation table
├── Tool/
│   ├── 放置追蹤器.lua    # Placement Tracker for recording stage actions & exporting GTD API scripts
│   ├── API說明_zh.md     # API Documentation (Traditional Chinese)
│   └── API_Reference_en.md  # API Reference (English)
└── API/                  # API documentation directory
```

## Features

- **Placement Tracker & Queue Replay**
  - Record tower placements, upgrades, sells, abilities, plot purchases, wave skips, and speed changes via `Tool/放置追蹤器.lua`, and export replay scripts calling the `GTD` API.
  - Supports elapsed time (seconds) or cash thresholds (`"$X"`) as execution gates, with built-in `AutoReplay` for automatic match restarts.
- **Anti-Macro Jitter & Anti-AFK**
  - Supports randomized action delays, subtle placement coordinate jitter, and special tower cooldown management (`GTD.SetJitter` / `GTD.SetSpecialTowerCooldown`).
- **Lobby Automation & Multilingual GUI**
  - Supports automated map/difficulty selection, lobby start, loadout equipping, crate purchasing, daily fertilizer claiming, and trait rolling.
  - Supports Traditional Chinese and English UI switching (automatically loaded from `script_language` in `Tsetingnil_script/keysystem.json`).

---

## Quick Load

```lua
-- Placement Tracker (Recording Tool)
loadstring(game:HttpGet("https://raw.githubusercontent.com/Tseting-nil/Garden-Tower-Defense-script/refs/heads/main/Tool/%E6%94%BE%E7%BD%AE%E8%BF%BD%E8%B9%A4%E5%99%A8.lua"))()
```

```lua
-- Lobby GUI
loadstring(game:HttpGet("https://raw.githubusercontent.com/Tseting-nil/Garden-Tower-Defense-script/refs/heads/main/Pages/%E5%A4%A7%E5%BB%B3%E4%BB%8B%E9%9D%A2.lua"))()
```

```lua
-- In-Game GUI
loadstring(game:HttpGet("https://raw.githubusercontent.com/Tseting-nil/Garden-Tower-Defense-script/refs/heads/main/Pages/%E9%81%8A%E6%88%B2%E5%85%A7%E4%BB%8B%E9%9D%A2.lua"))()
```

---

## API Overview

Loading the core script registers the global `GTD` table. Common categories include:

- **Scene & Version Info**: `GTD.IsLobby()`, `GTD.IsInGame()`, `GTD.GetAPIinfo()`
- **Game-End Detection**: `GTD.IsGameOver()`, `GTD.IsGameEndVisible()`, `GTD.GetGameResult()`
- **Action Queue & Execution**: `GTD.AddPlaceTower(...)`, `GTD.AddUpgradeTower(...)`, `GTD.AddSellTower(...)`, `GTD.AddTowerAbility(...)`, `GTD.AddBuyPlot(...)`, `GTD.AddSetSpeed(...)`, `GTD.AddEnd(...)`, `GTD.ExecuteQueue()`, `GTD.AutoReplay(...)`
- **Anti-Macro & Cooldowns**: `GTD.SetJitter(...)`, `GTD.SetSpecialTowerCooldown(...)`, `GTD.SetEquipToolOnPlace(...)`
- **Lobby & Unit Management**: `GTD.SelectMap(...)`, `GTD.SelectDifficulty(...)`, `GTD.StartLobby(...)`, `GTD.EquipLoadout(...)`, `GTD.BuyBox(...)`, `GTD.ClaimFertilizerDaily()`

For detailed usage, see the [API Reference](Tool/API_Reference_en.md).

---

## Disclaimer

- This project is provided strictly for educational, research, and personal automation testing purposes, and is not affiliated with Roblox Corporation or the developers of *Garden Tower Defense*.
- Using scripts from this project may violate the game's or platform's Terms of Service (ToS). Any account suspension, penalty (such as macro nerfs), data loss, or other risks resulting from use of this project are solely the user's responsibility.
- This project is provided **"AS IS"** without any warranty of stability, availability, or compatibility. The author assumes no liability for any direct or indirect damages, and game updates may break part or all of its functionality at any time.
- Commercial redistribution, malicious use, or disrupting other players' gameplay experience is strictly prohibited.
