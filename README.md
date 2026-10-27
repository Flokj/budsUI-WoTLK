# budsUI (WotLK 3.3.5a)

A comprehensive user interface replacement for **World of Warcraft 3.3.5a (Interface 30300)**.
Fork of [budsUI by Budtender3000](https://github.com/Budtender3000/budsUI) (originally based on **KkthnxUI**, **ShestakUI**, and **DuffedUI**), refined and enhanced for classic WotLK private servers (including Warmane and WowCircle with Cross-BG support and 3rd talent spec compatibility).

---

## 🎮 About the Project

**budsUI** combines a clean, pixel-perfect minimalist aesthetic with high performance and deep customizability. The repository includes two addons:
1. `budsUI` — Core UI framework, modules, and addon skins.
2. `budsUI_Config` — Graphical in-game configuration interface (`/buds`).

### Key Features & Fork Improvements

- 🎯 **Action Bars** — 5 customizable action bars, pet bar, stance/shapeshift bar, and shaman totem bar (featuring pulse bars and right-click totem cancel). Includes custom scaling, cooldown countdowns, and range fading.
- 👤 **Unit Frames (oUF)** — Player, Target, Focus, Pet, Party, Boss, and Arena frames. Features talent specialization icons, incoming heal prediction (HealPrediction / LibHealComm-4.0), built-in internal cooldowns (ICD), and player proc tracking.
- 💬 **Chat System** — Restyled chat free of combat dock taints: class-colored player mentions in chat and chat bubbles, URL/chat copying (`/copychat`), spam filters, and whisper notifications.
- 🏷️ **Nameplates** — Streamlined nameplates with optimized aura tracking (CLEU filtering and sleeping tickers), castbars, and healer role badges (including Cross-BG compatibility).
- 🗺️ **Minimap** — Minimap button collector (dropdown for addon icons), farm mode, right-click menu, coordinates, and ping notifications ("Who pinged?").
- 🎒 **Bags & Loot** — All-in-one bags with item quality borders and free repositioning, automated junk vendor/repair (with guild bank support), enhanced group loot and master loot frames.
- 💡 **Tooltips** — Enhanced tooltips showing item levels (iLvl), spell IDs, inventory item counts, achievement progress, talent specs (including WowCircle's 3rd talent tree), and PvP ratings.
- ⚙️ **budsUI_Config & Movers** — Built-in GUI configuration with real-time search, navigation icons, sub-tabs, dedicated Movers page, and free drag-and-drop frame positioning (`/moveui`).
- 🎨 **Addon Skins** — Native reskinning for popular addons: DBM, Skada, Recount, WeakAuras, Spy, and CLCRet.
- ⚡ **Automation & QoL** — Auto-invite, auto-release in BGs/arenas, achievement screenshots, bad gear alerts, pull countdown timer, and interrupt/sap announcements.

---

## 📦 Installation

1. Copy both the `budsUI` and `budsUI_Config` folders into your World of Warcraft AddOns directory:
   ```text
   World of Warcraft/Interface/AddOns/
   ```
2. Verify the folder structure:
   - `World of Warcraft/Interface/AddOns/budsUI/`
   - `World of Warcraft/Interface/AddOns/budsUI_Config/`
3. Launch World of Warcraft (or reload the interface if the game is running). In the AddOns menu at character selection, ensure both addons are enabled and check **"Load out of date AddOns"**.
4. On your first character login, the interactive **Installation Wizard** will automatically guide you through interface and CVars setup.

---

## ⌨️ Slash Commands

### Primary Commands
- `/buds` — Open the graphical configuration menu.
- `/moveui` — Toggle UI frame positioning mode (drag and drop).
- `/moveui reset` — Reset frame positions to their default layout.
- `/rl` — Quick UI reload (`/reload`).
- `/installui` — Re-run the initial installation wizard.
- `/resetui` — Reset all addon settings to defaults.

### Utility Commands
- `/align` — Toggle on-screen alignment grid for precision layout tuning.
- `/rc` — Initiate a Ready Check.
- `/frame` — Frame inspector tool (displays mouseover frame details for development and tweaking).
- `/boost` — Set graphics to minimum settings for maximum performance.
- `/cc` — Clear the active chat window.
- `/copychat` — Open a popup dialog to copy chat text.
- `/tt` — Send a whisper to your current target (Tell Target).

---

## ⚙️ Configuration

### Via GUI (budsUI_Config)
1. Type `/buds` in chat.
2. Use the search bar or select categories from the left navigation panel.
3. Most settings update live; certain core layout modifications require `/rl` to take effect.

### Via Configuration File
Advanced users can adjust default values directly in:
`budsUI/Config/Settings.lua`.

---

## 💖 Credits & License

- **Base Project:** [budsUI](https://github.com/Budtender3000/budsUI) by **Budtender3000**.
- **Original Codebase Ancestry:**
  - [KkthnxUI](https://github.com/kkthnx-wow/KkthnxUI) (Josh "Kkthnx" Russell)
  - [ShestakUI](https://github.com/Shestak/ShestakUI) (Shestak)
  - [DuffedUI](http://www.duffed.net)
- License: [MIT License](LICENSE).
