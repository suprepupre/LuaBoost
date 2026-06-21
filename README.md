# LuaBoost

**Lua runtime optimizer + GC manager + loading helpers for WoW 3.3.5a**  
Author: **Suprematist**

LuaBoost is a WoW addon that improves addon-side runtime behavior with:
- smarter garbage collection
- shared utility APIs
- loading-screen event suppression
- lightweight diagnostics
- optional integration with `wow_optimize.dll`

Designed for **WoW 3.3.5a (build 12340)**.

---

## Reviews

See what other players say: [Reviews and Testimonials](https://github.com/suprepupre/wow-optimize/discussions/10)

---

## Main Features

### Smart GC Manager
- incremental per-frame GC
- different GC step sizes for normal, combat, idle, and loading
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
- safe and aggressive modes
- restore events after loading completes

### Diagnostics
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
- display DLL GC, fast path, and runtime state

---

## What's New in v1.9.6

- aligns with the current `wow_optimize.dll` v3.11.0 build, whose headline change is the **mimalloc allocator redirect** — WoW's entire static CRT heap is routed through mimalloc to fight 32-bit virtual-address fragmentation over long sessions and repeated alt-switches
- GC control stays fully delegated to the DLL when it's present; LuaBoost remains a clean standalone fallback when it isn't
- DLL state display / diagnostics updated to match the current public feature set (event coalescing and the unit-API/spell/item caches are off in public-safe builds)

## Current Public Integration Model

The current public `wow_optimize.dll` builds are intentionally conservative.

### Public DLL features still relevant to LuaBoost
- adaptive GC (LuaBoost delegates GC stepping to the DLL when present)
- mimalloc redirect of WoW's static CRT heap (VA-fragmentation defense)
- string table pre-sizing
- string.format and Lua library fast paths
- loading and runtime optimizations

### Public DLL features intentionally disabled
- UI widget cache
- GetSpellInfo / GetItemInfo (API) caches
- Lua event coalescing

Because of that, LuaBoost no longer shows old DLL API cache lines in slash commands.

---

## Commands

| Command | Description |
|--------|-------------|
| `/lb` | Status overview |
| `/lb gc` | GC stats + DLL GC info |
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

## Runtime APIs Exposed For Addons

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

## Settings

Open: `ESC → Interface → AddOns → LuaBoost`

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

---

## Presets

| Preset | Normal | Combat | Idle | Loading | Emergency GC |
|-------|--------|--------|------|---------|--------------|
| Light | 20 KB | 5 KB | 80 KB | 150 KB | 150 MB |
| Standard | 50 KB | 15 KB | 150 KB | 300 KB | 300 MB |
| Heavy | 100 KB | 30 KB | 300 KB | 500 KB | 500 MB |

---

## wow_optimize Integration

LuaBoost works with or without the DLL.

### Without DLL
LuaBoost still provides:
- addon-side GC management
- table pool
- throttling
- loading helpers
- diagnostics

### With DLL
LuaBoost additionally becomes a control and visibility layer for:
- DLL GC mode and state
- DLL memory info
- Lua allocator status
- fast path stats

---

## Notes About ThrashGuard

LuaBoost contains a Lua-side StatusBar-only ThrashGuard. When using current public DLL builds:

- the DLL UI widget cache is disabled
- LuaBoost ThrashGuard can still be used as a Lua-side option
- if you experience addon-specific frame issues, keep it off

---

---

## Localization

Included locales:
- `enUS`
- `koKR`
- `deDE`

English is used as fallback for unsupported locales.

---

## Project Structure

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

## Troubleshooting

**Does LuaBoost do anything without the DLL?**  
Yes. GC management, loading optimization, table pool, throttling, and diagnostics all work standalone.

**Why don't I see API cache info anymore?**  
The current public DLL no longer exposes a meaningful public spell cache path. Slash command output was simplified.

**Are there taint risks?**  
Most of LuaBoost is safe. Potentially risky options remain optional and disabled by default.

---

## License

MIT License — use, modify, and distribute freely.
