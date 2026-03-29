-- LuaBoost English Localization (Base) v1.9.1
-- This file serves as the default reference for all translations.

LuaBoost_Locale_enUS = {
    -- PART A: Runtime Optimizations

    -- PART B: Smart GC Manager
    ["|cff888888[LuaBoost-DBG]|r "] = "|cff888888[LuaBoost-DBG]|r ",
    ["|cff4488ffloading|r"] = "|cff4488ffloading|r",
    ["|cffff4444combat|r"] = "|cffff4444combat|r",
    ["|cff888888idle|r"] = "|cff888888idle|r",
    ["|cff44ff44normal|r"] = "|cff44ff44normal|r",
    -- GC core
    ["Idle mode activated"] = "Idle mode activated",
    -- Emergency full GC (not in combat, not loading)
    ["Emergency GC: freed %.1f MB in %.1f ms"] = "Emergency GC: freed %.1f MB in %.1f ms",
    ["Raised threshold to %d MB"] = "Raised threshold to %d MB",

    -- GC Burst on heavy events
    ["GC burst: %s (step %d KB)"] = "GC burst: %s (step %d KB)",

    -- PART C: SpeedyLoad
    ["SpeedyLoad: UnregisterEvent hook installed"] = "SpeedyLoad: UnregisterEvent hook installed",
    ["SpeedyLoad: PLAYER_ENTERING_WORLD priority set"] = "SpeedyLoad: PLAYER_ENTERING_WORLD priority set",

    -- Loading state frame
    ["SpeedyLoad: suppressed %d registrations (%s)"] = "SpeedyLoad: suppressed %d registrations (%s)",
    ["SpeedyLoad: restored %d registrations"] = "SpeedyLoad: restored %d registrations",
    ["SpeedyLoad: restored %d registrations (fallback)"] = "SpeedyLoad: restored %d registrations (fallback)",

    -- PART D: UI Thrashing Protection    
    -- PART E: GUI (Interface Options)
    -- Main panel
    ["Lua runtime optimizer + smart garbage collector for WoW 3.3.5a."] = "Lua runtime optimizer + smart garbage collector for WoW 3.3.5a.",
    [" | |cff00ff00DLL|r"] = " | |cff00ff00DLL|r",
    ["%s  |  Mem: %s%.1f MB|r  |  %s  |  %s%d|r KB/f%s"] = "%s  |  Mem: %s%.1f MB|r  |  %s  |  %s%d|r KB/f%s",
    ["|cff00ff00ON|r"] = "|cff00ff00ON|r",
    ["|cffff0000OFF|r"] = "|cffff0000OFF|r",
    ["Enable GC Manager"] = "Enable GC Manager",
    ["Master toggle for smart GC."] = "Master toggle for smart GC.",
    ["GC Presets (Choose based on your combat memory):"] = "GC Presets (Choose based on your combat memory):",
    ["|cffff8844Light (< 150MB)|r"] = "|cffff8844Light (< 150MB)|r",
    ["|cffffff44Std (150-300MB)|r"] = "|cffffff44Std (150-300MB)|r",
    ["|cff44ff44Heavy (> 300MB)|r"] = "|cff44ff44Heavy (> 300MB)|r",
    ["Runtime optimizations are always active."] = "Runtime optimizations are always active.",

    -- SpeedyLoad section
    ["Loading Screen Optimization"] = "Loading Screen Optimization",
    ["Enable Fast Loading Screens"] = "Enable Fast Loading Screens",
    ["Temporarily suppresses noisy events during loading screens.\n"] = "Temporarily suppresses noisy events during loading screens.\n",
    ["Reduces CPU work and speeds up zone transitions.\n"] = "Reduces CPU work and speeds up zone transitions.\n",
    ["Restores all events after loading completes."] = "Restores all events after loading completes.",
--    ["Mode: %s (%d events)"] = "Mode: %s (%d events)", -- Duplicate line 56
    ["|cff44ff44Safe|r"] = "|cff44ff44Safe|r",
    ["|cffff8844Aggressive|r"] = "|cffff8844Aggressive|r",
    ["Mode: %s (%d events)"] = "Mode: %s (%d events)",
    ["|cffff4444GetFramesRegisteredForEvent not available — SpeedyLoad disabled.|r"] = "|cffff4444GetFramesRegisteredForEvent not available — SpeedyLoad disabled.|r",

    -- UI Thrashing Protection section
    ["UI Optimization"] = "UI Optimization",
    ["Enable UI Thrashing Protection"] = "Enable UI Thrashing Protection",
    ["Caches widget values and skips redundant engine calls.\n"] = "Caches widget values and skips redundant engine calls.\n",
    ["Speeds up all addons that update UI every frame.\n"] = "Speeds up all addons that update UI every frame.\n",
    ["Hooks: SetValue, SetMinMaxValues, SetStatusBarColor.\n"] = "Hooks: SetValue, SetMinMaxValues, SetStatusBarColor.\n",
    ["StatusBar methods only — FontString hooks removed\n"] = "StatusBar methods only — FontString hooks removed\n",
    ["to prevent taint with Blizzard dropdown menus.\n"] = "to prevent taint with Blizzard dropdown menus.\n",
    ["|cff44ff44Safe — no taint, no gameplay impact.|r\n"] = "|cff44ff44Safe — no taint, no gameplay impact.|r\n",
    ["|cffff8844Requires /reload to take effect.|r"] = "|cffff8844Requires /reload to take effect.|r",
    ["ThrashGuard: |cff00ff00%d|r hooks | Skipped: |cffffff00%d|r | Passed: |cffffff00%d|r | Rate: |cff00ff00%.0f%%|r"] = "ThrashGuard: |cff00ff00%d|r hooks | Skipped: |cffffff00%d|r | Passed: |cffffff00%d|r | Rate: |cff00ff00%.0f%%|r",
    ["ThrashGuard: |cffaaaaaaInactive|r"] = "ThrashGuard: |cffaaaaaaInactive|r",


    -- GC Settings panel
    ["GC Settings"] = "GC Settings",
    ["GC Settings|r"] = "GC Settings|r",
    ["Step Sizes (KB collected per frame)"] = "Step Sizes (KB collected per frame)",
    ["Normal Step"] = "Normal Step",
    ["GC per frame during normal gameplay."] = "GC per frame during normal gameplay.",
    ["Combat Step"] = "Combat Step",
    ["GC per frame in combat (keep low to protect frametime)."] = "GC per frame in combat (keep low to protect frametime).",
    ["Idle Step"] = "Idle Step",
    ["GC per frame while AFK/idle."] = "GC per frame while AFK/idle.",
    ["Loading Step"] = "Loading Step",
    ["GC per frame during loading screens (no rendering)."] = "GC per frame during loading screens (no rendering).",
    ["Thresholds"] = "Thresholds",
    ["Emergency Full GC (MB)"] = "Emergency Full GC (MB)",
    ["Force full GC outside combat when memory exceeds this.\n"] = "Force full GC outside combat when memory exceeds this.\n",
    ["Set higher (300-500+) if you use many addons to avoid long freezes."] = "Set higher (300-500+) if you use many addons to avoid long freezes.",
    ["Idle Timeout (sec)"] = "Idle Timeout (sec)",
    ["Seconds without activity before idle mode."] = "Seconds without activity before idle mode.",

    -- Tools panel
    ["Tools"] = "Tools",
    ["Tools & Diagnostics|r"] = "Tools & Diagnostics|r",
    ["Debug mode (GC info in chat)"] = "Debug mode (GC info in chat)",
    ["Shows GC mode changes, SpeedyLoad activity, and emergency collections."] = "Shows GC mode changes, SpeedyLoad activity, and emergency collections.",
    ["Intercept collectgarbage() calls"] = "Intercept collectgarbage() calls",
    ["Blocks full GC calls triggered by other addons.\n"] = "Blocks full GC calls triggered by other addons.\n",
    ["|cffff4444WARNING:|r Causes taint with ElvUI and secure frames.\n"] = "|cffff4444WARNING:|r Causes taint with ElvUI and secure frames.\n",
    ["Leave OFF if you see 'action blocked' errors."] = "Leave OFF if you see 'action blocked' errors.",
    ["Block UpdateAddOnMemoryUsage()"] = "Block UpdateAddOnMemoryUsage()",
    ["Blocks heavy addon memory scans.\n"] = "Blocks heavy addon memory scans.\n",
    ["MemUsage Min Interval (sec)"] = "MemUsage Min Interval (sec)",
    ["Minimum interval between UpdateAddOnMemoryUsage() calls."] = "Minimum interval between UpdateAddOnMemoryUsage() calls.",
    ["Force Full GC Now"] = "Force Full GC Now",
    ["|cff44ff44Freed %.1f MB in %.1f ms|r"] = "|cff44ff44Freed %.1f MB in %.1f ms|r",
    ["Reset All to Defaults"] = "Reset All to Defaults",
    ["Reset all LuaBoost settings to defaults?"] = "Reset all LuaBoost settings to defaults?",
    ["Yes"] = "Yes",
    ["No"] = "No",

    -- PART F: Slash Commands
    ["  GC: %s | Mode: %s | Mem: %.1f MB | Step: %d KB/f"] = "  GC: %s | Mode: %s | Mem: %.1f MB | Step: %d KB/f",
    ["  Protection: interceptGC=%s, blockMemUsage=%s"] = "  Protection: interceptGC=%s, blockMemUsage=%s",
    ["  SpeedyLoad: %s (%s, %d events)"] = "  SpeedyLoad: %s (%s, %d events)",
    ["on"] = "on",
    ["off"] = "off",
    ["aggressive"] = "aggressive",
    ["safe"] = "safe",
    ["  wow_optimize.dll: |cff00ff00CONNECTED|r"] = "  wow_optimize.dll: |cff00ff00CONNECTED|r",
    ["  wow_optimize.dll: |cffaaaaaaNOT DETECTED|r"] = "  wow_optimize.dll: |cffaaaaaaNOT DETECTED|r",
    ["  ThrashGuard: |cff00ff00ACTIVE|r (%d hooks, %.0f%% skip rate)"] = "  ThrashGuard: |cff00ff00ACTIVE|r (%d hooks, %.0f%% skip rate)",
    ["  ThrashGuard: |cffaaaaaaOFF|r"] = "  ThrashGuard: |cffaaaaaaOFF|r",
    ["/lb help|r"] = "/lb help|r",
    ["[LuaBoost]|r GC Stats:"] = "[LuaBoost]|r GC Stats:",
    ["  Memory: %.0f KB (%.1f MB)"] = "  Memory: %.0f KB (%.1f MB)",
    ["  Mode: %s | Step: %d KB/f"] = "  Mode: %s | Step: %d KB/f",
    ["  Lua steps: %d | Emergency: %d | Full: %d"] = "  Lua steps: %d | Emergency: %d | Full: %d",
    ["  Loading: %s | Idle: %s | Combat: %s"] = "  Loading: %s | Idle: %s | Combat: %s",
    ["yes"] = "yes",
    ["no"] = "no",
    ["  DLL: mem=%.0fKB steps=%d full=%d mode=%s"] = "  DLL: mem=%.0fKB steps=%d full=%d mode=%s",
    ["?"] = "?",
    ["[LuaBoost]|r Pool: %d acquired, %d released, %d created, %d available"] = "[LuaBoost]|r Pool: %d acquired, %d released, %d created, %d available",
    ["GC Manager: "] = "GC Manager: ",
    ["Freed %.1f MB"] = "Freed %.1f MB",
    ["SpeedyLoad: %s (%s, %d events)"] = "SpeedyLoad: %s (%s, %d events)",
    ["SpeedyLoad: |cff00ff00ON|r (|cff44ff44safe|r, "] = "SpeedyLoad: |cff00ff00ON|r (|cff44ff44safe|r, ",
    [" events)"] = " events)",
    ["SpeedyLoad: |cff00ff00ON|r (|cffff8844aggressive|r, "] = "SpeedyLoad: |cff00ff00ON|r (|cffff8844aggressive|r, ",
    ["[LuaBoost]|r UI Thrashing Protection:"] = "[LuaBoost]|r UI Thrashing Protection:",
    ["  Status: %s | Hooks: %d/3"] = "  Status: %s | Hooks: %d/3",
    ["  Skipped: |cffffff00%d|r | Passed: |cffffff00%d|r"] = "  Skipped: |cffffff00%d|r | Passed: |cffffff00%d|r",
    ["UI Thrashing Protection: |cffff0000OFF|r (hooks removed)"] = "UI Thrashing Protection: |cffff0000OFF|r (hooks removed)",
    ["UI Thrashing Protection: |cff00ff00ON|r (%d hooks)"] = "UI Thrashing Protection: |cff00ff00ON|r (%d hooks)",
    ["UI Thrashing Protection: |cffff0000FAILED|r — "] = "UI Thrashing Protection: |cffff0000FAILED|r — ",
    
    ["[LuaBoost]|r Commands:"] = "[LuaBoost]|r Commands:",
    ["  /lb              — status"]                      = "  /lb              — status",
    ["  /lb gc           — GC stats"]                    = "  /lb gc           — GC stats",
    ["  /lb pool         — table pool stats"]            = "  /lb pool         — table pool stats",
    ["  /lb toggle       — enable/disable GC manager"]   = "  /lb toggle       — enable/disable GC manager",
    ["  /lb force        — force full GC now"]           = "  /lb force        — force full GC now",
    ["  /lb sl           — toggle SpeedyLoad"]           = "  /lb sl           — toggle SpeedyLoad",
    ["  /lb sl safe      — SpeedyLoad safe mode"]        = "  /lb sl safe      — SpeedyLoad safe mode",
    ["  /lb sl agg       — SpeedyLoad aggressive mode"]  = "  /lb sl agg       — SpeedyLoad aggressive mode",
    ["  /lb settings     — open GC settings"]            = "  /lb settings     — open GC settings",
    ["  /lb tg           — UI thrash protection stats"]  = "  /lb tg           — UI thrash protection stats",
    ["  /lb tg toggle    — enable/disable thrash guard"] = "  /lb tg toggle    — enable/disable thrash guard",
    ["  /lb tg reset     — reset thrash guard counters"] = "  /lb tg reset     — reset thrash guard counters",
    ["  /lb updates      — show registered update callbacks"] = "  /lb updates      — show registered update callbacks",
    ["  /lb events       — profile events for 10 seconds"] = "  /lb events       — profile events for 10 seconds",
    ["  /lb fps          — FPS monitor for 10 seconds"] = "  /lb fps          — FPS monitor for 10 seconds",
    ["  /lb memleak      — addon memory leak scanner (30 sec)"] = "  /lb memleak      — addon memory leak scanner (30 sec)",

    -- PART G: Initialization
    ["GC: "] = "GC: ",
    ["GC:|cffff0000OFF|r"] = "GC:|cffff0000OFF|r",
    ["[LuaBoost]|r |cffff8844WARNING:|r SmartGC detected. Disable SmartGC to avoid conflicts."] = "[LuaBoost]|r |cffff8844WARNING:|r SmartGC detected. Disable SmartGC to avoid conflicts.",
}
