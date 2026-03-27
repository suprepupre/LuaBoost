# ⚡ LuaBoost v1.9.1

**Lua runtime optimizer + GC manager + loading helpers for WoW 3.3.5a**  
Author: **Suprematist**

LuaBoost is a WoW addon that improves addon-side runtime behavior with:
- smarter garbage collection
- shared utility APIs
- loading-screen event suppression
- lightweight diagnostics
- optional integration with `wow_optimize.dll`

It is designed for **WoW 3.3.5a (build 12340)**.

---

## ⭐ Reviews

See what other players say: [**Reviews & Testimonials**](https://github.com/suprepupre/wow-optimize/discussions/10)

---

## ✅ Main Features

### Smart GC Manager
- incremental per-frame GC
- different GC step sizes for:
  - normal
  - combat
  - idle
  - loading
- emergency full GC when memory gets too high
- optional forced GC burst on certain heavy events

### Runtime Utilities
- `GetTimeCached()`
- `GetFrameNumber()`
- `LuaBoost_Throttle(id, interval)`
- reusable table pool
- cached date helper
- OnUpdate dispatcher API

### Loading-Screen Helpers
- SpeedyLoad event suppression during loading screens
- safe / aggressive modes
- restore events after loading completes

### Diagnostics / Tools
- `/lb gc`
- `/lb pool`
- `/lb fps`
- `/lb events`
- `/lb memleak`
- `/lb updates`

### DLL Integration
When `wow_optimize.dll` is loaded, LuaBoost can:
- detect DLL presence
- sync GC step settings to the DLL
- display DLL GC / fast path / runtime state

---

## 🔄 What’s New in v1.9.1

- removed DLL API cache text from `/lb` and `/lb gc`
- keeps display focused on currently relevant public DLL features
- cleaner integration with the current public wow_optimize builds

---

## 🧠 Current Public Integration Model

The current public `wow_optimize.dll` builds are intentionally conservative.

### Public DLL features still relevant to LuaBoost
- adaptive GC
- Lua allocator replacement
- string table pre-sizing
- string.format fast path
- GetItemInfo cache
- loading/runtime/system-level optimizations

### Public DLL features intentionally disabled
- UI widget cache
- GetSpellInfo cache

Because of that, LuaBoost no longer shows old “DLL API cache” user-facing lines in slash commands.

---

## 🛠 Commands

| Command | Description |
|--------|-------------|
| `/lb` | Status overview |
| `/lb gc` | GC stats + DLL GC/runtime info |
| `/lb pool` | Table pool stats |
| `/lb toggle` | Enable/disable GC manager |
| `/lb force` | Force full GC |
| `/lb sl` | Toggle SpeedyLoad |
| `/lb sl safe` | SpeedyLoad safe mode |
| `/lb sl agg` | SpeedyLoad aggressive mode |
| `/lb tg` | ThrashGuard stats |
| `/lb tg toggle` | Toggle Lua-side ThrashGuard |
| `/lb tg reset` | Reset ThrashGuard counters |
| `/lb fps` | 10-second FPS/frametime report |
| `/lb events` | 10-second event frequency report |
| `/lb memleak` | 30-second addon memory growth scan |
| `/lb updates` | Show registered update callbacks |
| `/lb settings` | Open Interface Options |
| `/lb help` | Show command list |

---

## 🔧 Runtime APIs Exposed For Addons

### Cached Time
```lua
local now = GetTimeCached()
local frame = GetFrameNumber()
```

### Shared Throttle
```lua
if LuaBoost_Throttle("MyAddon_Update", 0.2) then
    -- runs at most every 0.2 sec
end
```

### Table Pool
```lua
local t = LuaBoost_AcquireTable()
-- use table
LuaBoost_ReleaseTable(t)
```

### OnUpdate Dispatcher
```lua
LuaBoost_RegisterUpdate("MyAddon_Update", 0.1, function(now, elapsed)
    -- update logic
end)

LuaBoost_UnregisterUpdate("MyAddon_Update")
```

---

## ⚙️ Settings

Open:
`ESC → Interface → AddOns → LuaBoost`

Panels:
- **Main**
- **GC Settings**
- **Tools**

Configurable options include:
- GC enable/disable
- preset selection
- per-mode GC step sizes
- emergency GC threshold
- idle timeout
- SpeedyLoad enable/mode
- debug output
- protection hooks

---

## 📊 Presets

| Preset | Normal | Combat | Idle | Loading | Emergency GC |
|-------|--------|--------|------|---------|--------------|
| Light | 20 KB | 5 KB | 80 KB | 150 KB | 150 MB |
| Standard | 50 KB | 15 KB | 150 KB | 300 KB | 300 MB |
| Heavy | 100 KB | 30 KB | 300 KB | 500 KB | 500 MB |

---

## 🔌 wow_optimize Integration

LuaBoost works **with or without** the DLL.

### Without DLL
LuaBoost still provides:
- addon-side GC management
- table pool
- throttling
- loading helpers
- diagnostics

### With DLL
LuaBoost additionally becomes a control/visibility layer for:
- DLL GC mode/state
- DLL memory info
- Lua allocator status
- fast path stats
- general DLL connection state

---

## 🛡 Notes About ThrashGuard

LuaBoost still contains a Lua-side **StatusBar-only ThrashGuard**, but when using the current public DLL builds:

- the DLL UI widget cache is disabled
- LuaBoost ThrashGuard can still be used as a Lua-side option
- if you experience any addon-specific frame issues, keep it off

The project has moved toward a more conservative public strategy:
**stability first, aggressive caching second**.

---

## 📥 Installation

Put the addon here:

```text
Interface/AddOns/!LuaBoost/
├── !LuaBoost.toc
├── LuaBoost.lua
├── enUS.lua
├── koKR.lua
└── deDE.lua
```

---

## 🌍 Localization

Included locales:
- `enUS`
- `koKR`
- `deDE`

If your locale is unsupported, English is used as fallback.

---

## 📁 Project Structure

```text
LuaBoost/
├── !LuaBoost/
│   ├── !LuaBoost.toc
│   ├── LuaBoost.lua
│   ├── enUS.lua
│   ├── koKR.lua
│   └── deDE.lua
└── README.md
```

---

## 🔍 Troubleshooting

### “Does LuaBoost do anything without the DLL?”
Yes. The addon is still useful on its own:
- GC management
- loading optimization
- table pool
- throttling
- diagnostics

### “Why don’t I see API cache info anymore?”
Because the current public DLL no longer exposes a meaningful public spell cache path. User-facing slash command output was simplified.

### “Are there taint risks?”
Most of LuaBoost is safe.  
Potentially risky options remain optional and disabled by default.

---

## 📜 License

MIT License — use, modify, and distribute freely.