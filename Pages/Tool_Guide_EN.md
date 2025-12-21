# 🏰 Tower Placement & Upgrade Tracker Tool - User Guide

## 📋 Introduction

This tool is designed for "Garden Tower Defense" game, capable of **automatically tracking and recording** all your in-game actions, including:

- 🗼 Tower placement positions and timing
- ⬆️ Tower upgrade timing
- ⏭️ Skip Wave actions
- 💰 Tower selling
- ⚡ Game speed adjustments (1x/2x/3x)
- 🔄 AutoSkip toggle changes

Once recording is complete, the tool will **automatically generate an executable script**.

---

## 🚀 Quick Start

### 1️⃣ Execute the Tool

Run `Tool/塔放置 & 升級追蹤工具_en.lua` in-game. The interface will appear automatically.

### 2️⃣ Enter the Game

1. Select map in lobby
2. Choose difficulty (Easy/Normal/Hard/Insane/Impossible/Apocalypse)
3. Tool auto-detects countdown and starts timer

### 3️⃣ Play Normally

Play as you normally would. **All actions are automatically recorded!**

### 4️⃣ Copy Script

After the game, click "📋 Copy Script" button to copy to clipboard.

---

## 🎮 Interface Guide

### Main Interface

| Element | Description |
|---------|-------------|
| **Title Bar** | Drag to move window |
| **Log Area** | Displays tracked actions |
| **📋 Copy Script** | Generate and copy script |
| **⚙️ Parameters** | Open settings panel |
| **- Button** | Collapse/expand interface |

### Parameter Settings

| Setting | Description |
|---------|-------------|
| **Script Speed Multiplier** | Convert 1x recordings to 2x/3x scripts |
| **Auto Round Time** | Round time values |
| **Auto-close UI** | Auto-close upgrade UI |
| **Auto Requeue** | Auto re-execute after game |
| **Custom Comment** | Script comment text |
| **Auto Scroll** | Auto-scroll to latest entry |
| **🔄 Reset** | Clear all records |
| **View Bindings** | Show tracked towers |

---

## ⌨️ Hotkeys

| Key | Function |
|-----|----------|
| **F8** | Show/hide interface |

---

## ⚠️ Important Notes

1. **Wait for Game Start** - Wait for "✅ Game Started!" message
2. **Script Multiplier** - Converted scripts may need adjustment
3. **Multiplayer** - Only tracks your own towers
4. **Path Towers** - Supports path-based units

---

## 🔧 Troubleshooting

| Issue | Solution |
|-------|----------|
| Interface gone | Press **F8** |
| Script didn't copy | Check console (F9) |
| "Untracked" upgrade | May be another player's tower |

---

## 📌 Version Info

- Currently in **beta testing**
- Scripts valid until **2026/1/1**
