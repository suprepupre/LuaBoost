# ⚡️ LuaBoost v1.8.0 (WotLK 3.3.5a)

**Lua runtime optimizer + SmartGC + SpeedyLoad + diagnostics for World of Warcraft 3.3.5a (build 12340)**
Author: **Suprematist**

LuaBoost improves addon performance by eliminating GC stutter with per-frame incremental garbage collection, speeding up loading screens by suppressing noisy events, and providing diagnostic tools for addon memory analysis.

Designed for **Warmane** and other 3.3.5a servers.

---

## ⭐ Reviews

See what other players say: [**Reviews & Testimonials**](https://github.com/suprepupre/wow-optimize/discussions/10)

---

## 🆕 What's New in v1.8.0

| Feature | Description |
|---------|-------------|
| **API Cache Stats** | `/lb` and `/lb gc` display DLL GetSpellInfo cache hit rate when wow_optimize.dll v2.0.0+ is installed. |
| **LuaBoostC_GetApiStats()** | New function exposed by DLL for API cache diagnostics. |

---

## 🌍 Localization

- **English (`enUS`)**: Default
- **Korean (`koKR`)**: Translated by [**nadugi**](https://github.com/nadugi)
- **German (`deDE`)**: Translated by [**Raz0r1337**](https://github.com/Raz0r1337)

*Want to translate? Copy `enUS.lua`, rename to your locale, translate, add to TOC, submit PR!*

---

## ✅ Features

### 📊 API Cache Stats (NEW in v1.8.0)

When wow_optimize.dll v2.0.0+ is active, `/lb` and `/lb gc` display GetSpellInfo cache performance:

```
  API Cache: 97% hit (14523 hits, 412 misses)
```

### 🔍 Memory Leak Scanner

Type `/lb memleak` to start a 30-second memory scan:

```
[LuaBoost] Memory Growth (30 sec):
  Recount                    +342 KB  (11.4 KB/sec)
  DBM-Core                   +89 KB  (3.0 KB/sec)
  Skada                      +45 KB  (1.5 KB/sec)
  No significant memory growth detected.
```

Color-coded: 🟡 yellow (<2 KB/sec), 🟠 orange (2-10 KB/sec), 🔴 red (>10 KB/sec — likely leak).

### 🔄 GC Step Sync

When wow_optimize.dll is installed, slider changes propagate to DLL within ~250ms. With v1.9.0+ DLL, adaptive GC adjusts step sizes automatically — slider values serve as starting points.

### 📊 UI Cache Stats

When the DLL is active, `/lb` and `/lb gc` display skip rates and GC step timing:

```
  UI Cache: 72% skip (14523 skipped, 5621 passed)
  DLL GC step: 0.84ms avg (budget: 2.0ms)
```

### 🎯 Tooltip Throttle

Throttles `GameTooltip:SetSpell` and `SetHyperlink` to max 10/sec per target. Same-target repeats pass through immediately. SetUnit not throttled (fixes Grid1 tooltips).

### 🛡️ UI Thrashing Protection

StatusBar metatable hooks — auto-disabled when DLL detected. Lua-side fallback when no DLL.

### Safe Runtime Optimizations (automatic, always active)

- `GetTimeCached()` — cached `GetTime()` value updated once per frame
- `LuaBoost_Throttle(id, interval)` — shared throttle helper
- Table pool: `LuaBoost_AcquireTable()` / `LuaBoost_ReleaseTable(t)`
- `GetDateCached(fmt)` — opt-in cached date helper

### Smart GC Manager (configurable)

- Per-frame incremental GC with **4-tier stepping**: loading → combat → idle → normal
- Emergency full GC when memory exceeds threshold (guarded by frame time)
- GC burst on heavy events (boss kill, LFG popup, achievement)
- **3 presets**: Light / Standard / Heavy
- GUI: `ESC → Interface → AddOns → LuaBoost`

### SpeedyLoad — Fast Loading Screens

- Suppresses noisy events during loading screens
- **Safe** (11 events) or **Aggressive** (23 events) mode

### 📊 Event Profiler

`/lb events` — 10-second event capture. Top 15 by frequency, color-coded.

### 📈 FPS Monitor

`/lb fps` — 10-second frametime capture with avg/median/min/max/1% low/stutter detection.

### 🔄 OnUpdate Dispatcher API

```lua
LuaBoost_RegisterUpdate("MyAddon_Update", 0.1, function(now, elapsed)
    -- runs every 0.1 seconds
end)
LuaBoost_UnregisterUpdate("MyAddon_Update")
LuaBoost_GetUpdateCount()
```

---

## 🔧 Recommended Optimization Ecosystem

| Layer | Tool | What It Does |
|-------|------|--------------|
| **C / Engine** | [wow_optimize.dll](https://github.com/suprepupre/wow-optimize) | Faster memory, I/O, network, timers, adaptive GC from C, combat log fix, UI widget cache (10 hooks), GetSpellInfo cache |
| **Lua / Runtime** | **!LuaBoost** | GC step sync, SpeedyLoad, memory leak scanner, diagnostics, table pool, GUI |

> 💡 **With wow_optimize.dll v2.0.0+**: DLL caches GetSpellInfo results permanently (95%+ hit rate). DLL uses adaptive GC that auto-adjusts step sizes. Addon sliders set the starting point — DLL tunes from there. ThrashGuard auto-disables.

---

## ⚙️ Settings Reference

Open settings: `ESC → Interface → AddOns → LuaBoost → GC Settings`

### Presets Comparison

| Setting | Light (<150MB) | Standard (150-300MB) | Heavy (>300MB) |
|---------|------|-----|--------|
| Normal Step (KB/f) | 20 | 50 | 100 |
| Combat Step (KB/f) | 5 | 15 | 30 |
| Idle Step (KB/f) | 80 | 150 | 300 |
| Loading Step (KB/f) | 150 | 300 | 500 |
| Emergency GC (MB) | 150 | 300 | 500 |
| Idle Timeout (sec) | 15 | 15 | 20 |

When wow_optimize.dll v1.9.0+ is installed, these values serve as starting points. The DLL will adapt them based on measured GC step time.

---

## 🔧 Fixing Freezes After Boss Kills

**Symptom:** 5-10 second freeze after boss kill or dungeon queue pop.

**Quick Fix:** `/lb settings` → click **Heavy (> 300MB)** preset.

**Manual Fix:** Set Emergency Full GC to 500+ MB, Combat Step to 30+ KB/f.

---

## ⚠️ Conflicts

- **SmartGC** — Do NOT use together. SmartGC is integrated into LuaBoost.
- **KPack SpeedyLoad** — Disable KPack's SpeedyLoad if using LuaBoost's.

---

## 📦 Installation

```text
Interface/AddOns/!LuaBoost/
├── !LuaBoost.toc
├── LuaBoost.lua
├── enUS.lua
├── koKR.lua
└── deDE.lua
```

---

## 🧰 Commands

| Command | Description |
|---------|-------------|
| `/lb` or `/luaboost` | Status overview + UI cache + API cache stats |
| `/lb gc` | GC stats + DLL stats + UI cache + API cache + GC timing |
| `/lb pool` | Table pool stats |
| `/lb toggle` | Enable/disable GC manager |
| `/lb force` | Force full GC now |
| `/lb sl` | Toggle SpeedyLoad |
| `/lb sl safe` | SpeedyLoad safe mode |
| `/lb sl agg` | SpeedyLoad aggressive mode |
| `/lb tg` | UI Thrashing Protection stats |
| `/lb tg toggle` | Enable/disable ThrashGuard |
| `/lb tg reset` | Reset ThrashGuard counters |
| `/lb events` | Profile events for 10 seconds |
| `/lb fps` | FPS monitor for 10 seconds |
| `/lb memleak` | Addon memory leak scanner (30 sec) |
| `/lb updates` | Show registered update callbacks |
| `/lb settings` | Open GC settings panel |
| `/lb help` | Show all commands |

---

## 📜 License

MIT License — do whatever you want with it.