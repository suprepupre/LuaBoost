# ⚡ LuaBoost (WotLK 3.3.5a)

**Lua runtime optimizer + SmartGC (incremental GC) for World of Warcraft 3.3.5a (build 12340)**  
Author: **Suprematist**

LuaBoost improves addon performance by optimizing common Lua patterns and eliminating GC stutter using per-frame incremental garbage collection.

Designed for **Warmane** and other 3.3.5a servers.

---

## ✅ Features

### Runtime optimizations (automatic)
- Faster `math.floor`, `math.ceil`, `math.abs` (pure Lua)
- Faster `table.insert(t, v)` for append case
- `GetTimeCached()` — cached `GetTime()` value updated once per frame
- `LuaBoost_Throttle(id, interval)` — shared throttle helper
- Table pool:
  - `LuaBoost_AcquireTable()`
  - `LuaBoost_ReleaseTable(t)`
  - `LuaBoost_GetPoolStats()`
- `GetDateCached(fmt)` — opt-in cached date helper (**does not replace** global `date()`)

### Smart GC Manager (configurable)
- Stops Lua auto-GC and performs **incremental GC steps every frame**
- Combat-aware stepping (less GC during combat)
- Idle detection (more GC while AFK)
- Emergency full GC when Lua memory exceeds threshold (outside combat)
- Settings UI: `ESC → Interface → AddOns → LuaBoost`

### DLL integration (optional)
Works perfectly with  **[wow_optimize.dll](https://github.com/suprepupre/wow-optimize)**:
- The DLL does GC stepping from C (via the Sleep hook) - zero Lua overhead
- LuaBoost remains the UI/logic/settings/combat state
- Statuses are available via  `LuaBoostC_GetStats()` (created by the DLL)

---

## ⚠️ Conflicts

**Do NOT use SmartGC together with LuaBoost.**  
SmartGC has been integrated into LuaBoost. Using two GC managers simultaneously will conflict.

SmartGC repo: https://github.com/suprepupre/SmartGC

---

## 📦 Installation

### Recommended (early load order)
LuaBoost must be loaded first, so the `!` prefix is ​​used:
- Recommended combo: **LuaBoost + wow_optimize.dll**



Copy the addon folder:

Interface/AddOns/!LuaBoost/

├── !LuaBoost.toc

└── LuaBoost.lua


If you downloaded from GitHub, make sure the extracted folder is `!LuaBoost`.

Restart WoW or `/reload`.

---

## 🧰 Commands

| Command | Description |
|--------|-------------|
| `/lb` or `/luaboost` | Status |
| `/lb bench` | Benchmark |
| `/lb gc` | GC stats + DLL stats (if present) |
| `/lb pool` | Table pool stats |
| `/lb toggle` | Enable/disable GC manager |
| `/lb force` | Force full GC now |
| `/lb settings` | Open settings panel |

---

## 🛡️ Protection options (important)

LuaBoost includes two optional “protection” features enabled by default:

- **Intercept collectgarbage() calls**  
  Blocks other addons from forcing full GC spikes.
- **Throttle UpdateAddOnMemoryUsage()**  
  Reduces CPU spikes from frequent memory scans.

On some UI setups these hooks may cause “macro script blocked / taint” warnings.
If that happens, disable them in `Tools & Diagnostics` panel.

---

## ✅ Compatibility

- WoW: **3.3.5a** (Interface **30300**)
- Tested: Warmane (Lordaeron/Icecrown)
- Lua: 5.1 (embedded)
- Recommended combo: **LuaBoost + wow_optimize.dll**

---

## 📜 License

MIT License — do whatever you want with it.