-- ================================================================
--  LuaBoost v1.9.2 — WoW 3.3.5a Lua Runtime Optimizer (Taint-Free)
--  Author: Suprematist
--
--  Features:
--   - Per-frame GetTimeCached()
--   - Shared throttle API, table pool
--   - Smart incremental GC manager (combat + idle + loading aware)
--   - SpeedyLoad: event suppression during loading screens
--   - Optional protection hooks (intercept GC, block memory scans)
--   - DLL integration (wow_optimize.dll v1.4+)
-- ================================================================

local addonName, addonTable = ...

if _G.LUABOOST_LOADED then return end
_G.LUABOOST_LOADED = true

local L = setmetatable({}, {
    __index = function(t, k)
        return k
    end
})

if _G.LuaBoost_Locale_enUS then
    for k, v in pairs(_G.LuaBoost_Locale_enUS) do
        L[k] = v
    end
end

local locale = GetLocale()
local localeData = _G["LuaBoost_Locale_" .. locale]

if locale ~= "enUS" then
    if localeData then
        for k, v in pairs(localeData) do
            L[k] = v
        end
    end
end

addonTable.L = L

local ADDON_NAME    = "LuaBoost"
local ADDON_VERSION = "1.9.2
local ADDON_COLOR   = "|cff00ccff"
local VALUE_COLOR   = "|cffffff00"

-- ================================================================
-- Localize frequently used globals
-- ================================================================
local orig_GetTime                = GetTime
local orig_format                 = string.format
local orig_pairs                  = pairs
local orig_ipairs                 = ipairs
local orig_type                   = type
local orig_next                   = next
local orig_date                   = date
local orig_print                  = print
local orig_pcall                  = pcall
local orig_select                 = select
local orig_collectgarbage         = collectgarbage
local orig_UpdateAddOnMemoryUsage = UpdateAddOnMemoryUsage
local orig_GetAddOnMemoryUsage    = GetAddOnMemoryUsage
local orig_debugprofilestart      = debugprofilestart
local orig_debugprofilestop       = debugprofilestop
local orig_min                    = math.min
local orig_wipe                   = wipe
local orig_getmetatable           = getmetatable
local orig_hooksecurefunc         = hooksecurefunc
local orig_geterrorhandler        = geterrorhandler
local orig_GetFramesForEvent      = GetFramesRegisteredForEvent
local orig_floor                  = math.floor

local hasGetFramesForEvent = (orig_type(orig_GetFramesForEvent) == "function")

-- ================================================================
-- PART A: Safe Runtime Optimizations
-- ================================================================

-- A1. Per-frame time cache
local cachedTime  = 0
local frameNumber = 0

function _G.GetTimeCached()
    return cachedTime
end

function _G.GetFrameNumber()
    return frameNumber
end

-- A2. Shared throttle API
local throttles = {}

function _G.LuaBoost_Throttle(id, interval)
    local now = cachedTime
    if now == 0 then now = orig_GetTime() end
    local last = throttles[id]
    if not last or (now - last) >= interval then
        throttles[id] = now
        return true
    end
    return false
end

-- A3. Shared table pool
local pool      = {}
local poolCount = 0
local POOL_MAX  = 200
local poolStats = { acquired = 0, released = 0, created = 0 }

function _G.LuaBoost_AcquireTable()
    poolStats.acquired = poolStats.acquired + 1
    if poolCount > 0 then
        local t = pool[poolCount]
        pool[poolCount] = nil
        poolCount = poolCount - 1
        return t
    end
    poolStats.created = poolStats.created + 1
    return {}
end

function _G.LuaBoost_ReleaseTable(t)
    if orig_type(t) ~= "table" then return end
    if poolCount >= POOL_MAX then return end
    if orig_getmetatable(t) then return end

    poolStats.released = poolStats.released + 1

    local k = orig_next(t)
    while k ~= nil do
        t[k] = nil
        k = orig_next(t)
    end

    poolCount = poolCount + 1
    pool[poolCount] = t
end

function _G.LuaBoost_GetPoolStats()
    return poolStats.acquired, poolStats.released, poolStats.created, poolCount
end

-- A3b. OnUpdate Dispatcher API
-- Addons can register throttled callbacks here instead of creating
-- their own Frame + OnUpdate. Saves C++ Frame objects and reduces
-- per-frame dispatch overhead from the engine.
--
-- Usage:
--   LuaBoost_RegisterUpdate("MyAddon_Health", 0.1, function(now, elapsed)
--       -- runs every 0.1 sec, 'now' = cachedTime, 'elapsed' = frame elapsed
--   end)
--   LuaBoost_UnregisterUpdate("MyAddon_Health")

local updateCallbacks = {}
local updateCount = 0

function _G.LuaBoost_RegisterUpdate(id, interval, callback)
    if orig_type(id) ~= "string" or orig_type(callback) ~= "function" then
        return false
    end
    interval = interval or 0
    if updateCallbacks[id] then
        updateCallbacks[id].interval = interval
        updateCallbacks[id].fn = callback
        return true
    end
    updateCallbacks[id] = {
        interval = interval,
        last = 0,
        fn = callback,
    }
    updateCount = updateCount + 1
    return true
end

function _G.LuaBoost_UnregisterUpdate(id)
    if updateCallbacks[id] then
        updateCallbacks[id] = nil
        updateCount = updateCount - 1
        return true
    end
    return false
end

function _G.LuaBoost_GetUpdateCount()
    return updateCount
end

-- A3c. Tooltip Throttle
-- GameTooltip:SetUnit() is one of the heaviest Lua operations.
-- Moving mouse over a crowd calls it 30-60 times/sec.
-- throttle to max 10/sec — imperceptible visually.

local tooltipThrottleInterval = 0.1
local lastTooltipSpellTime = 0
local lastTooltipSpellArg = nil
local lastTooltipItemTime = 0
local lastTooltipItemArg = nil

do
    local gt = GameTooltip
    if gt then
        local origSetSpell = gt.SetSpell
        if origSetSpell then
            gt.SetSpell = function(self, id, bookType)
                local now = cachedTime
                if now == 0 then now = orig_GetTime() end
                if id == lastTooltipSpellArg then
                    return origSetSpell(self, id, bookType)
                end
                if (now - lastTooltipSpellTime) < tooltipThrottleInterval then return end
                lastTooltipSpellTime = now
                lastTooltipSpellArg = id
                return origSetSpell(self, id, bookType)
            end
        end

        local origSetHyperlink = gt.SetHyperlink
        if origSetHyperlink then
            gt.SetHyperlink = function(self, link)
                local now = cachedTime
                if now == 0 then now = orig_GetTime() end
                if link == lastTooltipItemArg then
                    return origSetHyperlink(self, link)
                end
                if (now - lastTooltipItemTime) < tooltipThrottleInterval then return end
                lastTooltipItemTime = now
                lastTooltipItemArg = link
                return origSetHyperlink(self, link)
            end
        end
    end
end

-- A4. Cached date() — opt-in API (does not replace _G.date)
local cachedDate       = ""
local cachedDateFormat = ""
local cachedDateTime   = 0

function _G.GetDateCached(fmt, t)
    if t then return orig_date(fmt, t) end
    fmt = fmt or "%c"
    local now = cachedTime
    if now == 0 then now = orig_GetTime() end
    if fmt == cachedDateFormat and (now - cachedDateTime) < 1 then
        return cachedDate
    end
    cachedDateFormat = fmt
    cachedDateTime   = now
    cachedDate       = orig_date(fmt)
    return cachedDate
end

-- A5. Lua 5.0 compatibility shims (Safe, as they don't replace existing 5.1 functions)
if not table.getn then table.getn = function(t) return #t end end
if not table.setn then table.setn = function() end end
if not table.foreach then
    table.foreach = function(t, f)
        for k, v in orig_pairs(t) do
            local r = f(k, v)
            if r ~= nil then return r end
        end
    end
end
if not table.foreachi then
    table.foreachi = function(t, f)
        for i = 1, #t do
            local r = f(i, t[i])
            if r ~= nil then return r end
        end
    end
end

-- ================================================================
-- Master Event Frame — single frame for all event handling
-- Replaces: combatFrame, burstFrame, activityFrame, loadFrame, initFrame
-- Saves ~4-5 C++ Frame objects + their dispatch overhead
-- ================================================================

local eventFrame = CreateFrame("Frame")
local eventHandlers = {}

local function RegisterHandler(event, handler)
    if not eventHandlers[event] then
        eventHandlers[event] = {}
        eventFrame:RegisterEvent(event)
    end
    local handlers = eventHandlers[event]
    handlers[#handlers + 1] = handler
end

eventFrame:SetScript("OnEvent", function(self, event, ...)
    local handlers = eventHandlers[event]
    if handlers then
        for i = 1, #handlers do
            handlers[i](event, ...)
        end
    end
end)

-- ================================================================
-- Event Profiler — counts event frequency for diagnostics
-- Usage: /lb events — shows top events in last 10 seconds
-- ================================================================

local eventProfiler = {
    enabled   = false,
    counts    = {},
    startTime = 0,
}

local profilerFrame = CreateFrame("Frame")

local function StartEventProfiler()
    eventProfiler.enabled = true
    eventProfiler.startTime = orig_GetTime()
    for k in orig_pairs(eventProfiler.counts) do
        eventProfiler.counts[k] = nil
    end
    profilerFrame:RegisterAllEvents()
    orig_print(ADDON_COLOR .. "[LuaBoost]|r Event profiler |cff00ff00STARTED|r — collecting for 10 seconds...")
end

local function StopEventProfiler()
    eventProfiler.enabled = false
    profilerFrame:UnregisterAllEvents()

    local elapsed = orig_GetTime() - eventProfiler.startTime
    if elapsed < 0.1 then elapsed = 0.1 end

    local sorted = {}
    for event, count in orig_pairs(eventProfiler.counts) do
        sorted[#sorted + 1] = { event = event, count = count }
    end
    table.sort(sorted, function(a, b) return a.count > b.count end)

    orig_print(ADDON_COLOR .. "[LuaBoost]|r Event Profile (" .. orig_format("%.1f", elapsed) .. " sec):")

    local shown = 0
    for i = 1, #sorted do
        if shown >= 15 then break end
        local e = sorted[i]
        local perSec = e.count / elapsed
        local color = "|cffffff00"
        if perSec > 50 then
            color = "|cffff4444"
        elseif perSec > 20 then
            color = "|cffff8844"
        end
        orig_print(orig_format("  %s%-30s|r  %s%d|r total  (%s%.1f|r/sec)",
            color, e.event, VALUE_COLOR, e.count, color, perSec))
        shown = shown + 1
    end

    if shown == 0 then
        orig_print("  No events recorded.")
    end

    local total = 0
    for _, e in orig_ipairs(sorted) do
        total = total + e.count
    end
    orig_print(orig_format("  Total: |cffffff00%d|r events (|cffffff00%.0f|r/sec) across |cffffff00%d|r unique types",
        total, total / elapsed, #sorted))
end

profilerFrame:SetScript("OnEvent", function(self, event)
    if not eventProfiler.enabled then return end
    eventProfiler.counts[event] = (eventProfiler.counts[event] or 0) + 1
end)

profilerFrame:SetScript("OnUpdate", function(self, elapsed)
    if not eventProfiler.enabled then return end
    if (orig_GetTime() - eventProfiler.startTime) >= 10 then
        StopEventProfiler()
    end
end)

-- ================================================================
-- PART B: Smart GC Manager
-- ================================================================

local defaults = {
    enabled                = true,
    frameStepKB            = 50,        
    combatStepKB           = 15,        
    idleStepKB             = 150,       
    loadingStepKB          = 300,       
    fullCollectThresholdMB = 300,       
    idleTimeout            = 15,
    preset                 = "mid",
    debugMode              = false,

    -- Protection (OFF by default — prevents taint with ElvUI/secure frames)
    interceptGC            = false,
    blockMemoryUsage       = false,
    memoryUsageMinInterval = 1,

    speedyLoadEnabled      = false,
    speedyLoadMode         = "safe",

    thrashGuardEnabled     = true,
}

local presets = {
    weak = {
        frameStepKB            = 20,        
        combatStepKB           = 5,
        idleStepKB             = 80,        
        loadingStepKB          = 150,       
        fullCollectThresholdMB = 150,       
        idleTimeout            = 15,        
    },
    mid = {
        frameStepKB            = 50,        
        combatStepKB           = 15,        
        idleStepKB             = 150,       
        loadingStepKB          = 300,       
        fullCollectThresholdMB = 300,       
        idleTimeout            = 15,
    },
    strong = {
        frameStepKB            = 100,       
        combatStepKB           = 30,        
        idleStepKB             = 300,       
        loadingStepKB          = 500,      
        fullCollectThresholdMB = 500,      
        idleTimeout            = 20,
    },
}

local db

local inCombat     = false
local isIdle       = false
local isLoading    = false
local lastActivity = 0

local allControls = {}

local gcStats = {
    stepsLua     = 0,
    fullCollects = 0,
    emergencyGC  = 0,
}

local function Msg(text)
    orig_print(ADDON_COLOR .. "[LuaBoost]|r " .. text)
end

local function DebugMsg(text)
    if db and db.debugMode then
        orig_print(L["|cff888888[LuaBoost-DBG]|r "] .. text)
    end
end

local function InitDB()
    if orig_type(LuaBoostDB) ~= "table" then
        LuaBoostDB = {}
    end

    if orig_type(SmartGCDB) == "table" and not LuaBoostDB._migrated then
        for k, v in orig_pairs(SmartGCDB) do
            if defaults[k] ~= nil then
                LuaBoostDB[k] = v
            end
        end
        LuaBoostDB._migrated = true
    end

    for k, v in orig_pairs(defaults) do
        if LuaBoostDB[k] == nil then
            LuaBoostDB[k] = v
        end
    end

    db = LuaBoostDB
end

local function SyncStepsToDLL()
    if not db then return end
    _G.LUABOOST_ADDON_STEP_NORMAL  = db.frameStepKB
    _G.LUABOOST_ADDON_STEP_COMBAT  = db.combatStepKB
    _G.LUABOOST_ADDON_STEP_IDLE    = db.idleStepKB
    _G.LUABOOST_ADDON_STEP_LOADING = db.loadingStepKB
end

local function ApplyPreset(name)
    local p = presets[name]
    if not p then return end
    for k, v in orig_pairs(p) do
        db[k] = v
    end
    db.preset = name
    SyncStepsToDLL()
end

local function GetPresetNameDisplay(p)
    if p == "weak" then return "Light" end
    if p == "mid" then return "Standard" end
    if p == "strong" then return "Heavy" end
    return p or "Custom"
end

local function GetMemoryMB()
    return orig_collectgarbage("count") / 1024
end

local function GetCurrentStepKB()
    if not db then return 30 end
    if isLoading then return db.loadingStepKB end
    if inCombat then return db.combatStepKB end
    if isIdle then return db.idleStepKB end
    return db.frameStepKB
end

local function GetModeString()
    if isLoading then return L["|cff4488ffloading|r"] end
    if inCombat then return L["|cffff4444combat|r"] end
    if isIdle then return L["|cff888888idle|r"] end
    return L["|cff44ff44normal|r"]
end

local function RefreshAllControls()
    for _, c in orig_pairs(allControls) do
        if c.Refresh then c:Refresh() end
    end
end

local function hasDLL()
    return orig_type(_G.LuaBoostC_IsLoaded) == "function" and _G.LUABOOST_DLL_LOADED == true
end

-- DLL communication globals
local function WriteCombatGlobal()
    _G.LUABOOST_ADDON_COMBAT = inCombat
end

local function WriteIdleGlobal()
    _G.LUABOOST_ADDON_IDLE = isIdle
end

local function WriteLoadingGlobal()
    _G.LUABOOST_ADDON_LOADING = isLoading
end

-- ================================================================
-- Protection hooks
-- ================================================================

local function CollectGarbage_Proxy(opt, arg)
    if not db or not db.enabled or not db.interceptGC then
        return orig_collectgarbage(opt, arg)
    end
    if opt == "count" then
        return orig_collectgarbage("count")
    end
    if opt == nil or opt == "collect" then
        return 0
    end
    if opt == "step" then
        local limit = inCombat and 5 or 20
        arg = arg and orig_min(arg, limit) or limit
        return orig_collectgarbage("step", arg)
    end
    if opt == "stop" or opt == "restart" or opt == "setpause" or opt == "setstepmul" then
        return 0
    end
    return orig_collectgarbage(opt, arg)
end

local function UpdateAddOnMemoryUsage_Proxy(...)
    if not db or not db.enabled or not db.blockMemoryUsage then
        return orig_UpdateAddOnMemoryUsage(...)
    end
    return
end

local function GetAddOnMemoryUsage_Proxy(index)
    if not db or not db.enabled or not db.blockMemoryUsage then
        return orig_GetAddOnMemoryUsage(index)
    end
    return 0
end

local function ApplyProtectionHooks()
    if not db then return end

    if db.enabled and db.interceptGC then
        _G.collectgarbage = CollectGarbage_Proxy
    else
        _G.collectgarbage = orig_collectgarbage
    end

    if db.enabled and db.blockMemoryUsage then
        _G.UpdateAddOnMemoryUsage = UpdateAddOnMemoryUsage_Proxy
        _G.GetAddOnMemoryUsage    = GetAddOnMemoryUsage_Proxy
    else
        _G.UpdateAddOnMemoryUsage = orig_UpdateAddOnMemoryUsage
        _G.GetAddOnMemoryUsage    = orig_GetAddOnMemoryUsage
    end
end

-- ================================================================
-- GC core
-- ================================================================
orig_collectgarbage("stop")
orig_collectgarbage("collect")
orig_collectgarbage("collect")

local gcReStopCounter = 0
local gcMemCheckCounter = 0


local coreFrame = CreateFrame("Frame")
coreFrame:SetScript("OnUpdate", function(self, elapsed)
    -- Update time cache (every frame, always)
    frameNumber = frameNumber + 1
    cachedTime  = orig_GetTime()

    -- Dispatch registered update callbacks
    if updateCount > 0 then
        for id, data in orig_pairs(updateCallbacks) do
            if data.interval <= 0 or (cachedTime - data.last) >= data.interval then
                data.last = cachedTime
                local ok, err = orig_pcall(data.fn, cachedTime, elapsed)
                if not ok then
                    orig_geterrorhandler()(err)
                end
            end
        end
    end

    if not db or not db.enabled then return end

    -- Idle detection
    if not isIdle and not inCombat and not isLoading and (cachedTime - lastActivity) > db.idleTimeout then
        isIdle = true
        WriteIdleGlobal()
        DebugMsg(L["Idle mode activated"])
    end

    -- Periodic: re-stop GC
    gcReStopCounter = gcReStopCounter + 1
    if gcReStopCounter >= 300 then
        gcReStopCounter = 0
        orig_collectgarbage("stop")
    end

    -- Emergency full GC check (every 60 frames, not every frame)
    -- collectgarbage("count") is not free — it walks internal GC lists
    -- Memory threshold is in hundreds of MB — no need to check 60x/sec
    local memKB
    gcMemCheckCounter = gcMemCheckCounter + 1
    if gcMemCheckCounter >= 60 then
        gcMemCheckCounter = 0
        memKB = orig_collectgarbage("count")
    end
    if memKB and memKB > (db.fullCollectThresholdMB * 1024) and not inCombat and not isLoading and elapsed < 0.033 then
        orig_debugprofilestart()
        orig_collectgarbage("collect")
        orig_collectgarbage("collect")
        local dt = orig_debugprofilestop()

        local memAfterKB = orig_collectgarbage("count")
        gcStats.emergencyGC = gcStats.emergencyGC + 1

        DebugMsg(orig_format(L["Emergency GC: freed %.1f MB in %.1f ms"], (memKB - memAfterKB) / 1024, dt))

        if dt > 50 and db.fullCollectThresholdMB < 1000 then
            db.fullCollectThresholdMB = db.fullCollectThresholdMB + 20
            DebugMsg(string.format(L["Raised threshold to %d MB"], db.fullCollectThresholdMB))
        end

        orig_collectgarbage("stop")
        return
    end

    -- DLL handles per-frame stepping if present
    if hasDLL() then return end

    local step = orig_floor(GetCurrentStepKB())
    if step > 0 then
        orig_collectgarbage("step", step)
        gcStats.stepsLua = gcStats.stepsLua + 1
    end
end)

-- ================================================================
-- FPS / Frametime Monitor
-- Usage: /lb fps — shows min/max/avg FPS and 1% low over 10 seconds
-- ================================================================

local fpsMonitor = {
    enabled    = false,
    startTime  = 0,
    frameTimes = {},
    frameCount = 0,
    maxFrames  = 2000,  -- 10 sec at 200fps max
}

local function StartFPSMonitor()
    fpsMonitor.enabled   = true
    fpsMonitor.startTime = orig_GetTime()
    fpsMonitor.frameCount = 0
    for i = 1, fpsMonitor.maxFrames do
        fpsMonitor.frameTimes[i] = nil
    end
    orig_print(ADDON_COLOR .. "[LuaBoost]|r FPS monitor |cff00ff00STARTED|r — collecting for 10 seconds...")
end

local function StopFPSMonitor()
    fpsMonitor.enabled = false

    local count = fpsMonitor.frameCount
    if count < 2 then
        orig_print(ADDON_COLOR .. "[LuaBoost]|r Not enough frames captured.")
        return
    end

    local elapsed = orig_GetTime() - fpsMonitor.startTime
    if elapsed < 0.1 then elapsed = 0.1 end

    -- Calculate stats
    local totalMs = 0
    local minMs = 9999
    local maxMs = 0

    -- Copy for sorting
    local sorted = {}
    for i = 1, count do
        local ms = fpsMonitor.frameTimes[i]
        if ms then
            sorted[#sorted + 1] = ms
            totalMs = totalMs + ms
            if ms < minMs then minMs = ms end
            if ms > maxMs then maxMs = ms end
        end
    end

    table.sort(sorted)

    local avgMs = totalMs / #sorted
    local avgFPS = 1000 / avgMs
    local minFPS = 1000 / maxMs  -- worst frame = lowest FPS
    local maxFPS = 1000 / minMs  -- best frame = highest FPS

    -- 1% low: average of worst 1% frames
    local onePercentCount = orig_floor(#sorted * 0.01)
    if onePercentCount < 1 then onePercentCount = 1 end
    local onePercentTotal = 0
    for i = #sorted, #sorted - onePercentCount + 1, -1 do
        onePercentTotal = onePercentTotal + sorted[i]
    end
    local onePercentMs = onePercentTotal / onePercentCount
    local onePercentFPS = 1000 / onePercentMs

    -- Median
    local medianMs = sorted[orig_floor(#sorted / 2)]
    local medianFPS = 1000 / medianMs

    orig_print(ADDON_COLOR .. "[LuaBoost]|r FPS Report (" .. orig_format("%.1f", elapsed) .. " sec, " .. #sorted .. " frames):")
    orig_print(orig_format("  Average:  |cff00ff00%.1f|r FPS  (%.2f ms)", avgFPS, avgMs))
    orig_print(orig_format("  Median:   |cff00ff00%.1f|r FPS  (%.2f ms)", medianFPS, medianMs))
    orig_print(orig_format("  Max:      |cff00ff00%.1f|r FPS  (%.2f ms)", maxFPS, minMs))
    orig_print(orig_format("  Min:      |cffff4444%.1f|r FPS  (%.2f ms)", minFPS, maxMs))
    orig_print(orig_format("  1%% Low:   |cffff8844%.1f|r FPS  (%.2f ms)", onePercentFPS, onePercentMs))

    -- Stutter detection
    local stutterCount = 0
    local stutterThreshold = avgMs * 3
    for i = 1, #sorted do
        if sorted[i] > stutterThreshold then
            stutterCount = stutterCount + 1
        end
    end

    if stutterCount > 0 then
        orig_print(orig_format("  Stutters: |cffff4444%d|r frames > %.0fms (3x avg)",
            stutterCount, stutterThreshold))
    else
        orig_print("  Stutters: |cff00ff00none|r")
    end
end

local fpsLastTime = 0

coreFrame:HookScript("OnUpdate", function()
    if not fpsMonitor.enabled then return end

    local now = orig_GetTime()
    if fpsLastTime > 0 then
        local dt = (now - fpsLastTime) * 1000  -- ms
        fpsMonitor.frameCount = fpsMonitor.frameCount + 1
        if fpsMonitor.frameCount <= fpsMonitor.maxFrames then
            fpsMonitor.frameTimes[fpsMonitor.frameCount] = dt
        end
    end
    fpsLastTime = now

    if (now - fpsMonitor.startTime) >= 10 then
        StopFPSMonitor()
        fpsLastTime = 0
    end
end)


-- Combat tracking
local function OnCombatEvent(event)
    if event == "PLAYER_REGEN_DISABLED" then
        lastActivity = cachedTime > 0 and cachedTime or orig_GetTime()
        if isIdle then isIdle = false; WriteIdleGlobal() end
        WriteCombatGlobal()

        if hasDLL() and LuaBoostC_SetCombat then
            LuaBoostC_SetCombat(true)
        end

    elseif event == "PLAYER_REGEN_ENABLED" then
        lastActivity = cachedTime > 0 and cachedTime or orig_GetTime()
        WriteCombatGlobal()

        if hasDLL() and LuaBoostC_SetCombat then
            LuaBoostC_SetCombat(false)
        end

        if db and db.enabled then
            if hasDLL() and LuaBoostC_GCStep then
                LuaBoostC_GCStep(256)
            else
                orig_collectgarbage("step", 50)
            end
        end
    end
end

RegisterHandler("PLAYER_REGEN_DISABLED", OnCombatEvent)
RegisterHandler("PLAYER_REGEN_ENABLED", OnCombatEvent)

-- GC Burst on heavy events
local burstEvents = {
    "LFG_PROPOSAL_SHOW",
    "LFG_PROPOSAL_SUCCEEDED",
    "LFG_COMPLETION_REWARD",
    "ACHIEVEMENT_EARNED",
    "CHAT_MSG_LOOT",
    "ENCOUNTER_END",
}

local function OnBurstEvent(event)
    if not db or not db.enabled then return end

    local burstKB = 128

    if db.debug and event ~= "CHAT_MSG_LOOT" then
        DebugMsg(orig_format("GC burst: %s (step %d KB)", event, burstKB))
    end

    if hasDLL() and LuaBoostC_GCStep then
        LuaBoostC_GCStep(burstKB)
    else
        orig_collectgarbage("step", burstKB)
    end

    gcStats.stepsLua = gcStats.stepsLua + 1
end

for _, ev in orig_ipairs(burstEvents) do
    RegisterHandler(ev, OnBurstEvent)
end

-- Activity tracking (idle reset)
local activityEvents = {
    "PLAYER_STARTED_MOVING", "PLAYER_STOPPED_MOVING",
    "UNIT_SPELLCAST_START", "UNIT_SPELLCAST_SUCCEEDED",
    "CHAT_MSG_SAY", "CHAT_MSG_PARTY", "CHAT_MSG_RAID",
    "CHAT_MSG_GUILD", "CHAT_MSG_WHISPER", "CHAT_MSG_WHISPER_INFORM",
    "LOOT_OPENED", "BAG_UPDATE", "ACTIONBAR_UPDATE_STATE",
    "MERCHANT_SHOW", "AUCTION_HOUSE_SHOW", "BANKFRAME_OPENED",
    "MAIL_SHOW", "QUEST_DETAIL",
}

local function OnActivityEvent()
    lastActivity = cachedTime > 0 and cachedTime or orig_GetTime()
    if isIdle then
        isIdle = false
        WriteIdleGlobal()
    end
end

for _, event in orig_pairs(activityEvents) do
    RegisterHandler(event, OnActivityEvent)
end

-- ================================================================
-- PART C: SpeedyLoad — Event Suppression During Loading Screens
-- ================================================================

local SPEEDY_SAFE_EVENTS = {
    "SPELLS_CHANGED",
    "SPELL_UPDATE_USABLE",
    "ACTIONBAR_SLOT_CHANGED",
    "USE_GLYPH",
    "PLAYER_TALENT_UPDATE",
    "PET_TALENT_UPDATE",
    "WORLD_MAP_UPDATE",
    "UPDATE_WORLD_STATES",
    "UPDATE_FACTION",
    "CRITERIA_UPDATE",
    "RECEIVED_ACHIEVEMENT_LIST",
}

local SPEEDY_AGGRESSIVE_EVENTS = {}
do
    local safe = SPEEDY_SAFE_EVENTS
    for i = 1, #safe do
        SPEEDY_AGGRESSIVE_EVENTS[#SPEEDY_AGGRESSIVE_EVENTS + 1] = safe[i]
    end
    local extra = {
        "ACTIONBAR_UPDATE_STATE",
        "ACTIONBAR_UPDATE_USABLE",
        "ACTIONBAR_UPDATE_COOLDOWN",
        "SPELL_UPDATE_COOLDOWN",
        "UNIT_AURA",
        "UNIT_INVENTORY_CHANGED",
        "BAG_UPDATE",
        "QUEST_LOG_UPDATE",
        "COMPANION_UPDATE",
        "PET_BAR_UPDATE",
        "TRADE_SKILL_UPDATE",
        "MERCHANT_UPDATE",
    }
    for i = 1, #extra do
        SPEEDY_AGGRESSIVE_EVENTS[#SPEEDY_AGGRESSIVE_EVENTS + 1] = extra[i]
    end
end

local speedyTracked    = {}
local speedyOccurred   = {}
local speedySuppressed = false
local speedyListenUnreg = false
local speedyHooked     = false
local lastPostLoadGC   = 0

local speedyFrame = hasGetFramesForEvent and CreateFrame("Frame") or nil

local speedyValidUnreg = {}
if speedyFrame then
    speedyValidUnreg[speedyFrame.UnregisterEvent] = true
end

local function GetSpeedyEventList()
    if db and db.speedyLoadMode == "aggressive" then
        return SPEEDY_AGGRESSIVE_EVENTS
    end
    return SPEEDY_SAFE_EVENTS
end

local function SpeedyLoad_Suppress()
    if not hasGetFramesForEvent or not speedyFrame then return 0 end

    for k in orig_pairs(speedyTracked) do
        speedyTracked[k] = nil
    end
    orig_wipe(speedyOccurred)

    local eventList = GetSpeedyEventList()
    for i = 1, #eventList do
        speedyTracked[eventList[i]] = {}
    end

    local count = 0

    for event, frames in orig_pairs(speedyTracked) do
        local registered = {orig_GetFramesForEvent(event)}
        for i = 1, #registered do
            local frame = registered[i]
            if frame and frame ~= speedyFrame then
                local unreg = frame.UnregisterEvent
                if unreg then
                    orig_pcall(unreg, frame, event)
                    frames[frame] = 1
                    count = count + 1
                end
            end
        end
        speedyFrame:RegisterEvent(event)
    end

    speedySuppressed = true
    speedyListenUnreg = true
    return count
end

local function SpeedyLoad_Restore()
    if not speedySuppressed then return 0 end

    speedyListenUnreg = false
    speedySuppressed = false

    local count = 0

    for event, frames in orig_pairs(speedyTracked) do
        if speedyFrame then
            orig_pcall(speedyFrame.UnregisterEvent, speedyFrame, event)
        end

        for frame in orig_pairs(frames) do
            orig_pcall(frame.RegisterEvent, frame, event)
            count = count + 1

            if speedyOccurred[event] then
                local OnEvent = frame:GetScript("OnEvent")
                if OnEvent then
                    local a1 = (event == "ACTIONBAR_SLOT_CHANGED") and 0 or nil
                    local ok, err = orig_pcall(OnEvent, frame, event, a1)
                    if not ok then
                        orig_geterrorhandler()(err, 1)
                    end
                end
            end
        end
        orig_wipe(frames)
    end

    orig_wipe(speedyOccurred)
    return count
end

if speedyFrame then
    speedyFrame:SetScript("OnEvent", function(self, event)
        if speedyTracked[event] then
            speedyOccurred[event] = true
            self:UnregisterEvent(event)
        end
    end)
end

local function SpeedyLoad_HookUnregister()
    if speedyHooked or not speedyFrame then return end

    local meta = orig_getmetatable(speedyFrame)
    if not meta or not meta.__index then return end

    local ok = orig_pcall(orig_hooksecurefunc, meta.__index, "UnregisterEvent",
        function(frame, event)
            if speedyListenUnreg then
                local frames = speedyTracked[event]
                if frames then
                    frames[frame] = nil
                end
            end
        end
    )

    if ok then
        speedyHooked = true
        DebugMsg(L["SpeedyLoad: UnregisterEvent hook installed"])
    end
end

local function SpeedyLoad_EnsurePriority()
    if not hasGetFramesForEvent then return end

    local frames = {orig_GetFramesForEvent("PLAYER_ENTERING_WORLD")}
    for i = 1, #frames do
        orig_pcall(frames[i].UnregisterEvent, frames[i], "PLAYER_ENTERING_WORLD")
    end

    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

    for i = 1, #frames do
        if frames[i] ~= eventFrame then
            orig_pcall(frames[i].RegisterEvent, frames[i], "PLAYER_ENTERING_WORLD")
        end
    end

    if PetStableFrame then
        orig_pcall(PetStableFrame.UnregisterEvent, PetStableFrame, "SPELLS_CHANGED")
    end

    DebugMsg(L["SpeedyLoad: PLAYER_ENTERING_WORLD priority set"])
end

-- ================================================================
-- Loading state frame
-- ================================================================

local function DoPostLoadGC()
    local now = orig_GetTime()
    if (now - lastPostLoadGC) < 2 then return end
    lastPostLoadGC = now

    if db and db.enabled then
        if hasDLL() and LuaBoostC_GCCollect then
            LuaBoostC_GCCollect()
        else
            orig_collectgarbage("collect")
            orig_collectgarbage("collect")
        end
        gcStats.fullCollects = gcStats.fullCollects + 1
        orig_collectgarbage("stop")
    end
end

local function OnLoadingEvent(event)
    if event == "PLAYER_LEAVING_WORLD" then
        isLoading = true
        WriteLoadingGlobal()

        if db and db.speedyLoadEnabled then
            local n = SpeedyLoad_Suppress()
            DebugMsg(orig_format("SpeedyLoad: suppressed %d registrations (%s)", n, db.speedyLoadMode))
        end

    elseif event == "LOADING_SCREEN_ENABLED" then
        if not isLoading then
            isLoading = true
            WriteLoadingGlobal()
        end

    elseif event == "PLAYER_ENTERING_WORLD" then
        if speedySuppressed then
            local n = SpeedyLoad_Restore()
            DebugMsg(orig_format("SpeedyLoad: restored %d registrations", n))
        end

        isLoading = false
        WriteLoadingGlobal()
        lastActivity = cachedTime > 0 and cachedTime or orig_GetTime()
        if isIdle then
            isIdle = false
            WriteIdleGlobal()
        end

        DoPostLoadGC()

    elseif event == "LOADING_SCREEN_DISABLED" then
        if speedySuppressed then
            local n = SpeedyLoad_Restore()
            DebugMsg(orig_format("SpeedyLoad: restored %d registrations (fallback)", n))
        end

        if isLoading then
            isLoading = false
            WriteLoadingGlobal()
            lastActivity = cachedTime > 0 and cachedTime or orig_GetTime()
            if isIdle then
                isIdle = false
                WriteIdleGlobal()
            end

            DoPostLoadGC()
        end
    end
end

RegisterHandler("PLAYER_LEAVING_WORLD", OnLoadingEvent)
RegisterHandler("PLAYER_ENTERING_WORLD", OnLoadingEvent)
RegisterHandler("LOADING_SCREEN_ENABLED", OnLoadingEvent)
RegisterHandler("LOADING_SCREEN_DISABLED", OnLoadingEvent)

-- ================================================================
-- PART D: UI Thrashing Protection
--
-- Hooks StatusBar metatable methods to cache last-set values.
-- If the new value is identical to the cached one, the engine
-- call is skipped entirely — saving bar fill recomputation.
--
-- StatusBar methods ONLY — FontString methods (SetText etc.)
-- cause taint with Blizzard secure frames (dropdown menus,
-- action bars) and are NOT hooked.
--
-- Hooked (3 methods):
--   StatusBar: SetValue, SetMinMaxValues, SetStatusBarColor
-- ================================================================

local thrashCache = setmetatable({}, { __mode = "k" })

local thrashStats = {
    skipped  = 0,
    passed   = 0,
    hooked   = 0,
    active   = false,
}

local K_VALUE   = 1
local K_MIN     = 2
local K_MAX     = 3
local K_SBC_R   = 4
local K_SBC_G   = 5
local K_SBC_B   = 6
local K_SBC_A   = 7

local originals = {}
local barMeta

-- Guard flag: only cache after we're fully in-game
local thrashGuardReady = false

-- ----------------------------------------------------------------
local function InstallThrashGuard()
    if thrashStats.active then return end
    if not db or not db.thrashGuardEnabled then return end

    local tmpBar = CreateFrame("StatusBar")
    local barMT  = orig_getmetatable(tmpBar)

    if not barMT or not barMT.__index then
        DebugMsg("ThrashGuard: StatusBar metatable not found")
        return
    end

    barMeta = barMT.__index
    tmpBar:Hide()

    local hookCount = 0

    -- ============================================================
    -- StatusBar:SetValue(value)
    -- ============================================================
    if barMeta.SetValue then
        originals.Bar_SetValue = barMeta.SetValue
        local orig = originals.Bar_SetValue

        local ok = orig_pcall(function()
            barMeta.SetValue = function(self, value)
                if not thrashGuardReady then
                    return orig(self, value)
                end
                if orig_type(value) ~= "number" then
                    return orig(self, value)
                end
                local c = thrashCache[self]
                if c then
                    if c[K_VALUE] == value then
                        thrashStats.skipped = thrashStats.skipped + 1
                        return
                    end
                else
                    c = LuaBoost_AcquireTable()
                    thrashCache[self] = c
                end
                c[K_VALUE] = value
                thrashStats.passed = thrashStats.passed + 1
                return orig(self, value)
            end
        end)

        if ok then
            hookCount = hookCount + 1
            DebugMsg("ThrashGuard: StatusBar:SetValue hooked")
        else
            barMeta.SetValue = orig
        end
    end

    -- ============================================================
    -- StatusBar:SetMinMaxValues(min, max)
    -- ============================================================
    if barMeta.SetMinMaxValues then
        originals.Bar_SetMinMaxValues = barMeta.SetMinMaxValues
        local orig = originals.Bar_SetMinMaxValues

        local ok = orig_pcall(function()
            barMeta.SetMinMaxValues = function(self, lo, hi)
                if not thrashGuardReady then
                    return orig(self, lo, hi)
                end
                local c = thrashCache[self]
                if c then
                    if c[K_MIN] == lo and c[K_MAX] == hi then
                        thrashStats.skipped = thrashStats.skipped + 1
                        return
                    end
                else
                    c = LuaBoost_AcquireTable()
                    thrashCache[self] = c
                end
                c[K_MIN] = lo
                c[K_MAX] = hi
                c[K_VALUE] = nil
                thrashStats.passed = thrashStats.passed + 1
                return orig(self, lo, hi)
            end
        end)

        if ok then
            hookCount = hookCount + 1
            DebugMsg("ThrashGuard: StatusBar:SetMinMaxValues hooked")
        else
            barMeta.SetMinMaxValues = orig
        end
    end

    -- ============================================================
    -- StatusBar:SetStatusBarColor(r, g, b [, a])
    -- ============================================================
    if barMeta.SetStatusBarColor then
        originals.Bar_SetStatusBarColor = barMeta.SetStatusBarColor
        local orig = originals.Bar_SetStatusBarColor

        local ok = orig_pcall(function()
            barMeta.SetStatusBarColor = function(self, r, g, b, a)
                if not thrashGuardReady then
                    return orig(self, r, g, b, a)
                end
                local c = thrashCache[self]
                if c then
                    if c[K_SBC_R] == r and c[K_SBC_G] == g
                       and c[K_SBC_B] == b and c[K_SBC_A] == a then
                        thrashStats.skipped = thrashStats.skipped + 1
                        return
                    end
                else
                    c = LuaBoost_AcquireTable()
                    thrashCache[self] = c
                end
                c[K_SBC_R] = r
                c[K_SBC_G] = g
                c[K_SBC_B] = b
                c[K_SBC_A] = a
                thrashStats.passed = thrashStats.passed + 1
                return orig(self, r, g, b, a)
            end
        end)

        if ok then
            hookCount = hookCount + 1
            DebugMsg("ThrashGuard: StatusBar:SetStatusBarColor hooked")
        else
            barMeta.SetStatusBarColor = orig
        end
    end

    -- ============================================================
    thrashStats.hooked = hookCount
    thrashStats.active = true
    
    -- Enable caching only after hooks are installed and we're in-game
    thrashGuardReady = true

    DebugMsg(orig_format("ThrashGuard: installed %d/3 hooks (StatusBar only)", hookCount))
end

-- ----------------------------------------------------------------
local function UninstallThrashGuard()
    if not thrashStats.active then return end

    thrashGuardReady = false

    if barMeta then
        if originals.Bar_SetValue          then barMeta.SetValue          = originals.Bar_SetValue end
        if originals.Bar_SetMinMaxValues   then barMeta.SetMinMaxValues   = originals.Bar_SetMinMaxValues end
        if originals.Bar_SetStatusBarColor then barMeta.SetStatusBarColor = originals.Bar_SetStatusBarColor end
    end

    for k, v in orig_pairs(thrashCache) do
        LuaBoost_ReleaseTable(v)
        thrashCache[k] = nil
    end

    thrashStats.active = false
    thrashStats.hooked = 0
    DebugMsg("ThrashGuard: all hooks removed")
end

-- ----------------------------------------------------------------
function _G.LuaBoost_GetThrashStats()
    local widgets = 0
    for _ in orig_pairs(thrashCache) do
        widgets = widgets + 1
    end
    return thrashStats.skipped, thrashStats.passed, thrashStats.hooked,
           thrashStats.active, widgets
end

function _G.LuaBoost_InvalidateWidget(widget)
    if widget then
        thrashCache[widget] = nil
    end
end

-- ================================================================
-- PART E: GUI (Interface Options)
-- ================================================================
local function Label(parent, text, x, y, template)
    local fs = parent:CreateFontString(nil, "ARTWORK", template or "GameFontHighlight")
    fs:SetPoint("TOPLEFT", x, y)
    fs:SetText(text)
    fs:SetJustifyH("LEFT")
    return fs
end

local function Checkbox(parent, label, tip, x, y, get, set)
    local name = "LuaBoost_CB_" .. label:gsub("[^%w]", "")
    local cb = CreateFrame("CheckButton", name, parent, "InterfaceOptionsCheckButtonTemplate")
    cb:SetPoint("TOPLEFT", x, y)

    local t = _G[name .. "Text"]
    if t then t:SetText(label) end

    cb.tooltipText = label
    cb.tooltipRequirement = tip

    function cb:Refresh()
        self:SetChecked(get())
    end

    cb:SetScript("OnClick", function(self)
        set(self:GetChecked() and true or false)
    end)

    cb:Refresh()
    allControls[#allControls + 1] = cb
    return cb
end

local function Slider(parent, label, tip, x, y, lo, hi, st, get, set)
    local name = "LuaBoost_S_" .. label:gsub("[^%w]", "")
    local s = CreateFrame("Slider", name, parent, "OptionsSliderTemplate")
    s:SetPoint("TOPLEFT", x, y)
    s:SetWidth(220)
    s:SetHeight(17)
    s:SetMinMaxValues(lo, hi)
    s:SetValueStep(st)

    local tT = _G[name .. "Text"]
    local tL = _G[name .. "Low"]
    local tH = _G[name .. "High"]
    if tT then tT:SetText(label) end
    if tL then tL:SetText(lo) end
    if tH then tH:SetText(hi) end

    s.tooltipText = label
    s.tooltipRequirement = tip

    local val = s:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    val:SetPoint("LEFT", s, "RIGHT", 8, 0)
    s.valText = val

    function s:Refresh()
        self:SetValue(get())
        self.valText:SetText(VALUE_COLOR .. get() .. "|r")
    end

    s:SetScript("OnValueChanged", function(self, v)
        v = orig_floor(v / st + 0.5) * st
        set(v)
        self.valText:SetText(VALUE_COLOR .. v .. "|r")
    end)

    s:Refresh()
    allControls[#allControls + 1] = s
    return s
end

-- Main panel
local panelMain = CreateFrame("Frame", "LuaBoostPanelMain", InterfaceOptionsFramePanelContainer)
panelMain.name = "LuaBoost"
panelMain:Hide()

panelMain:SetScript("OnShow", function(self)
    if self.built then
        RefreshAllControls()
        return
    end
    self.built = true

    Label(self, ADDON_COLOR .. "LuaBoost|r v" .. ADDON_VERSION, 16, -16, "GameFontNormalLarge")

    Label(self, L["Lua runtime optimizer + smart garbage collector for WoW 3.3.5a."], 16, -36, "GameFontHighlightSmall")

    local statusLabel = Label(self, "", 16, -56, "GameFontNormal")
    statusLabel:SetWidth(500)

    local timer = 0
    self:SetScript("OnUpdate", function(_, el)
        timer = timer + el
        if timer < 0.5 then return end
        timer = 0
        if not db then return end

        local dllTag = hasDLL() and L[" | |cff00ff00DLL|r"] or ""
        statusLabel:SetText(orig_format(
            L["%s  |  Mem: %s%.1f MB|r  |  %s  |  %s%d|r KB/f%s"],
            db.enabled and L["|cff00ff00ON|r"] or L["|cffff0000OFF|r"],
            VALUE_COLOR, GetMemoryMB(),
            GetModeString(),
            VALUE_COLOR, GetCurrentStepKB(),
            dllTag
        ))
    end)

    Checkbox(self, L["Enable GC Manager"],
        L["Master toggle for smart GC."],
        14, -76,
        function() return db.enabled end,
        function(v)
            db.enabled = v
            if v then
                orig_collectgarbage("stop")
            else
                orig_collectgarbage("restart")
            end
            ApplyProtectionHooks()
        end
    )

    Label(self, L["GC Presets (Choose based on your combat memory):"], 16, -106, "GameFontNormal")

    local pdata = {
        { k = "weak",   l = L["|cffff8844Light (< 150MB)|r"],   x = 16 },
        { k = "mid",    l = L["|cffffff44Std (150-300MB)|r"],   x = 136 },
        { k = "strong", l = L["|cff44ff44Heavy (> 300MB)|r"],   x = 256 },
    }

    for _, p in orig_pairs(pdata) do
        local b = CreateFrame("Button", nil, self, "UIPanelButtonTemplate")
        b:SetSize(115, 22)
        b:SetPoint("TOPLEFT", p.x, -130)
        b:SetText(p.l)
        b:SetScript("OnClick", function()
            ApplyPreset(p.k)
            RefreshAllControls()
        end)
    end

    Label(self, L["Runtime optimizations are always active."], 16, -165, "GameFontHighlightSmall")

    -- SpeedyLoad section
    Label(self, L["Loading Screen Optimization"], 16, -195, "GameFontNormal")

    Checkbox(self, L["Enable Fast Loading Screens"],
        L["Temporarily suppresses noisy events during loading screens.\n"]
        .. L["Reduces CPU work and speeds up zone transitions.\n"]
        .. L["Restores all events after loading completes."],
        14, -215,
        function() return db.speedyLoadEnabled end,
        function(v) db.speedyLoadEnabled = v end
    )

    local speedyModeLabel = Label(self, "", 16, -275, "GameFontHighlightSmall")
    speedyModeLabel:SetWidth(400)

    local function UpdateSpeedyModeLabel()
        if not db or not speedyModeLabel then return end
        local isAggressive = (db.speedyLoadMode == "aggressive")
        local modeStr = isAggressive and L["|cffff8844Aggressive|r"] or L["|cff44ff44Safe|r"]
        local count = isAggressive and #SPEEDY_AGGRESSIVE_EVENTS or #SPEEDY_SAFE_EVENTS
        speedyModeLabel:SetText(string.format(L["Mode: %s (%d events)"], modeStr, count))
    end

    local safeBtn = CreateFrame("Button", nil, self, "UIPanelButtonTemplate")
    safeBtn:SetSize(100, 22)
    safeBtn:SetPoint("TOPLEFT", 16, -245)
    safeBtn:SetText(L["|cff44ff44Safe|r"])
    safeBtn:SetScript("OnClick", function()
        db.speedyLoadMode = "safe"
        UpdateSpeedyModeLabel()
    end)

    local aggBtn = CreateFrame("Button", nil, self, "UIPanelButtonTemplate")
    aggBtn:SetSize(100, 22)
    aggBtn:SetPoint("TOPLEFT", 126, -245)
    aggBtn:SetText(L["|cffff8844Aggressive|r"])
    aggBtn:SetScript("OnClick", function()
        db.speedyLoadMode = "aggressive"
        UpdateSpeedyModeLabel()
    end)

    UpdateSpeedyModeLabel()

    if not hasGetFramesForEvent then
        Label(self, L["|cffff4444GetFramesRegisteredForEvent not available — SpeedyLoad disabled.|r"],
            16, -300, "GameFontHighlightSmall")
    end

    -- UI Thrashing Protection section
    Label(self, L["UI Optimization"], 16, -320, "GameFontNormal")

    Checkbox(self, L["Enable UI Thrashing Protection"],
        L["Caches widget values and skips redundant engine calls.\n"]
        .. L["Speeds up all addons that update UI every frame.\n"]
        .. L["Hooks: SetValue, SetMinMaxValues, SetStatusBarColor.\n"]
        .. L["StatusBar methods only — FontString hooks removed\n"]
        .. L["to prevent taint with Blizzard dropdown menus.\n"]
        .. L["|cff44ff44Safe — no taint, no gameplay impact.|r\n"]
        .. L["|cffff8844Requires /reload to take effect.|r"],
        14, -340,
        function() return db.thrashGuardEnabled end,
        function(v)
            db.thrashGuardEnabled = v
        end
    )

    local tgStatsLabel = Label(self, "", 16, -410, "GameFontHighlightSmall")
    tgStatsLabel:SetWidth(500)

    local origOnUpdate = self:GetScript("OnUpdate")
    self:SetScript("OnUpdate", function(s, el)
        if origOnUpdate then origOnUpdate(s, el) end

        if thrashStats.active then
            local sk, ps = thrashStats.skipped, thrashStats.passed
            local total = sk + ps
            local rate = total > 0 and (sk / total * 100) or 0
            tgStatsLabel:SetText(orig_format(
                L["ThrashGuard: |cff00ff00%d|r/3 hooks | Skipped: |cffffff00%d|r | Passed: |cffffff00%d|r | Rate: |cff00ff00%.0f%%|r"],
                thrashStats.hooked, sk, ps, rate))
        elseif db and db.thrashGuardEnabled and hasDLL() then
            tgStatsLabel:SetText("ThrashGuard: |cff88aaffhandled by DLL (C-level UI cache)|r")
        else
            tgStatsLabel:SetText(L["ThrashGuard: |cffaaaaaaInactive|r"])
        end
    end)    
end)

InterfaceOptions_AddCategory(panelMain)

-- GC Settings panel
local panelSettings = CreateFrame("Frame", "LuaBoostPanelSettings", InterfaceOptionsFramePanelContainer)
panelSettings.name = L["GC Settings"]
panelSettings.parent = "LuaBoost"
panelSettings:Hide()

panelSettings:SetScript("OnShow", function(self)
    if self.built then
        RefreshAllControls()
        return
    end
    self.built = true

    Label(self, ADDON_COLOR .. L["GC Settings|r"], 16, -16, "GameFontNormalLarge")

    Label(self, L["Step Sizes (KB collected per frame)"], 16, -46, "GameFontNormal")

    Slider(self, L["Normal Step"], L["GC per frame during normal gameplay."], 20, -86,
        1, 500, 5,
        function() return db.frameStepKB end,
        function(v) db.frameStepKB = v; db.preset = "custom"; SyncStepsToDLL() end
    )

    Slider(self, L["Combat Step"], L["GC per frame in combat (keep low to protect frametime)."], 20, -138,
        0, 100, 1,
        function() return db.combatStepKB end,
        function(v) db.combatStepKB = v; db.preset = "custom"; SyncStepsToDLL() end
    )

    Slider(self, L["Idle Step"], L["GC per frame while AFK/idle."], 20, -190,
        10, 1000, 10,
        function() return db.idleStepKB end,
        function(v) db.idleStepKB = v; db.preset = "custom"; SyncStepsToDLL() end
    )

    Slider(self, L["Loading Step"], L["GC per frame during loading screens (no rendering)."], 20, -242,
        50, 1000, 25,
        function() return db.loadingStepKB end,
        function(v) db.loadingStepKB = v; db.preset = "custom"; SyncStepsToDLL() end
    )

    Label(self, L["Thresholds"], 16, -286, "GameFontNormal")

    Slider(self, L["Emergency Full GC (MB)"],
        L["Force full GC outside combat when memory exceeds this.\n"]
        .. L["Set higher (300-500+) if you use many addons to avoid long freezes."], 20, -326,
        20, 1000, 10,
        function() return db.fullCollectThresholdMB end,
        function(v) db.fullCollectThresholdMB = v; db.preset = "custom" end
    )

    Slider(self, L["Idle Timeout (sec)"], L["Seconds without activity before idle mode."], 20, -378,
        5, 120, 5,
        function() return db.idleTimeout end,
        function(v) db.idleTimeout = v end
    )
end)

InterfaceOptions_AddCategory(panelSettings)

-- Tools panel
local panelTools = CreateFrame("Frame", "LuaBoostPanelTools", InterfaceOptionsFramePanelContainer)
panelTools.name = L["Tools"]
panelTools.parent = "LuaBoost"
panelTools:Hide()

panelTools:SetScript("OnShow", function(self)
    if self.built then
        RefreshAllControls()
        return
    end
    self.built = true

    Label(self, ADDON_COLOR .. L["Tools & Diagnostics|r"], 16, -16, "GameFontNormalLarge")

    Checkbox(self, L["Debug mode (GC info in chat)"],
        L["Shows GC mode changes, SpeedyLoad activity, and emergency collections."],
        14, -40,
        function() return db.debugMode end,
        function(v) db.debugMode = v end
    )

    Checkbox(self, L["Intercept collectgarbage() calls"],
        L["Blocks full GC calls triggered by other addons.\n"]
        .. L["|cffff4444WARNING:|r Causes taint with ElvUI and secure frames.\n"]
        .. L["Leave OFF if you see 'action blocked' errors."],
        14, -66,
        function() return db.interceptGC end,
        function(v) db.interceptGC = v and true or false; ApplyProtectionHooks() end
    )

    Checkbox(self, L["Block UpdateAddOnMemoryUsage()"],
        L["Blocks heavy addon memory scans.\n"]
        .. L["|cffff4444WARNING:|r Causes taint with ElvUI and secure frames.\n"]
        .. L["Leave OFF if you see 'action blocked' errors."],
        14, -92,
        function() return db.blockMemoryUsage end,
        function(v) db.blockMemoryUsage = v and true or false; ApplyProtectionHooks() end
    )

    Slider(self, L["MemUsage Min Interval (sec)"], L["Minimum interval between UpdateAddOnMemoryUsage() calls."], 20, -138,
        0, 10, 1,
        function() return db.memoryUsageMinInterval end,
        function(v) db.memoryUsageMinInterval = v end
    )

    local resultLabel = Label(self, "", 200, -180, "GameFontHighlightSmall")
    resultLabel:SetWidth(300)

    local forceBtn = CreateFrame("Button", nil, self, "UIPanelButtonTemplate")
    forceBtn:SetSize(170, 22)
    forceBtn:SetPoint("TOPLEFT", 16, -172)
    forceBtn:SetText(L["Force Full GC Now"])
    forceBtn:SetScript("OnClick", function()
        local before = orig_collectgarbage("count")
        orig_debugprofilestart()

        if hasDLL() and LuaBoostC_GCCollect then
            LuaBoostC_GCCollect()
        else
            orig_collectgarbage("collect")
            orig_collectgarbage("collect")
        end

        local dt = orig_debugprofilestop()
        local after = orig_collectgarbage("count")
        local freed = (before - after) / 1024

        resultLabel:SetText(orig_format(L["|cff44ff44Freed %.1f MB in %.1f ms|r"], freed, dt))
        gcStats.fullCollects = gcStats.fullCollects + 1
        orig_collectgarbage("stop")
    end)

    local resetBtn = CreateFrame("Button", nil, self, "UIPanelButtonTemplate")
    resetBtn:SetSize(170, 22)
    resetBtn:SetPoint("TOPLEFT", 16, -200)
    resetBtn:SetText(L["Reset All to Defaults"])
    resetBtn:SetScript("OnClick", function()
        StaticPopupDialogs["LUABOOST_RESET"] = {
            text = L["Reset all LuaBoost settings to defaults?"],
            button1 = L["Yes"],
            button2 = L["No"],
            OnAccept = function()
                LuaBoostDB = nil
                InitDB()
                ApplyProtectionHooks()
                RefreshAllControls()
                resultLabel:SetText("")
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
        }
        StaticPopup_Show("LUABOOST_RESET")
    end)
end)

InterfaceOptions_AddCategory(panelTools)

-- ================================================================
-- PART F: Slash Commands
-- ================================================================
local function ShowStatus()
    orig_print(ADDON_COLOR .. "[LuaBoost]|r v" .. ADDON_VERSION)
    if db then
        orig_print(orig_format(L["  GC: %s | Mode: %s | Mem: %.1f MB | Step: %d KB/f"],
            db.enabled and L["|cff00ff00ON|r"] or L["|cffff0000OFF|r"],
            GetModeString(), GetMemoryMB(), GetCurrentStepKB()))

        orig_print(orig_format(L["  Protection: interceptGC=%s, blockMemUsage=%s"],
            db.interceptGC and L["on"] or L["off"],
            db.blockMemoryUsage and L["on"] or L["off"]))

        orig_print(orig_format(L["  SpeedyLoad: %s (%s, %d events)"],
            db.speedyLoadEnabled and L["|cff00ff00ON|r"] or L["|cffaaaaaaOFF|r"],
            db.speedyLoadMode == "aggressive" and L["aggressive"] or L["safe"],
            #GetSpeedyEventList()))
    end

    if hasDLL() then
        orig_print(L["  wow_optimize.dll: |cff00ff00CONNECTED|r"])
        if _G.LUABOOST_DLL_FASTPATH_ACTIVE then
            local fpH = _G.LUABOOST_DLL_FASTPATH_HITS or 0
            local fpF = _G.LUABOOST_DLL_FASTPATH_FALLBACKS or 0
            local fpTotal = fpH + fpF
            local fpRate = fpTotal > 0 and (fpH / fpTotal * 100) or 0
            orig_print(orig_format("  Fast Path: |cff00ff00%.0f%%|r format (%d fast, %d fallback)",
                fpRate, fpH, fpF))
        end                
        if _G.LUABOOST_DLL_UICACHE_ACTIVE then
            local uiSk = _G.LUABOOST_DLL_UICACHE_SKIPPED or 0
            local uiPs = _G.LUABOOST_DLL_UICACHE_PASSED or 0
            local total = uiSk + uiPs
            local rate = total > 0 and (uiSk / total * 100) or 0
            orig_print(orig_format("  UI Cache: |cff00ff00%.0f%%|r skip (%d skipped, %d passed)",
                rate, uiSk, uiPs))
        end
    else
        orig_print(L["  wow_optimize.dll: |cffaaaaaaNOT DETECTED|r"])
    end

    if thrashStats.active then
        local sk, ps = thrashStats.skipped, thrashStats.passed
        local rate = (sk + ps) > 0 and (sk / (sk + ps) * 100) or 0
        orig_print(orig_format("  ThrashGuard: |cff00ff00ACTIVE|r (%d hooks, %.0f%% skip rate)",
            thrashStats.hooked, rate))
    elseif db and db.thrashGuardEnabled and hasDLL() then
        orig_print("  ThrashGuard: |cff88aaff handled by DLL (C-level UI cache)|r")
    else
        orig_print("  ThrashGuard: |cffaaaaaaOFF|r")
    end

    if updateCount > 0 then
        orig_print("  Tooltip throttle: |cff00ff00ACTIVE|r (max 10/sec)")
        orig_print(orig_format("  OnUpdate Dispatcher: |cffffff00%d|r callbacks", updateCount))
    end
    orig_print("  " .. VALUE_COLOR .. L["/lb help|r"])
end

-- ================================================================
-- Memory Leak Scanner
-- ================================================================

local memLeakData = nil

local function StartMemLeakScan()
    if memLeakData then
        Msg("Memory scan already in progress...")
        return
    end

    orig_UpdateAddOnMemoryUsage()
    local snap1 = {}
    local numAddons = GetNumAddOns()
    for i = 1, numAddons do
        local name = GetAddOnInfo(i)
        if name and IsAddOnLoaded(i) then
            snap1[name] = orig_GetAddOnMemoryUsage(i)
        end
    end

    memLeakData = {
        snap1 = snap1,
        startTime = orig_GetTime(),
    }

    Msg("Memory scan |cff00ff00STARTED|r — will report in 30 seconds. Play normally.")

    LuaBoost_RegisterUpdate("LuaBoost_MemLeak", 1, function(now)
        if not memLeakData then
            LuaBoost_UnregisterUpdate("LuaBoost_MemLeak")
            return
        end
        if (now - memLeakData.startTime) < 30 then return end

        LuaBoost_UnregisterUpdate("LuaBoost_MemLeak")

        orig_UpdateAddOnMemoryUsage()
        local elapsed = now - memLeakData.startTime

        local growth = {}
        local numAddons = GetNumAddOns()
        for i = 1, numAddons do
            local name = GetAddOnInfo(i)
            if name and IsAddOnLoaded(i) then
                local mem2 = orig_GetAddOnMemoryUsage(i)
                local mem1 = memLeakData.snap1[name] or 0
                local delta = mem2 - mem1
                if delta > 10 then
                    growth[#growth + 1] = {
                        name = name,
                        delta = delta,
                        rate = delta / elapsed,
                    }
                end
            end
        end

        table.sort(growth, function(a, b) return a.delta > b.delta end)

        orig_print(ADDON_COLOR .. orig_format("[LuaBoost]|r Memory Growth (%.0f sec):", elapsed))
        local shown = 0
        for i = 1, #growth do
            if shown >= 10 then break end
            local g = growth[i]
            local color = g.rate > 10 and "|cffff4444" or
                          g.rate > 2 and "|cffff8844" or "|cffffff00"
            orig_print(orig_format("  %s%-25s|r  +%.0f KB  (%.1f KB/sec)",
                color, g.name, g.delta, g.rate))
            shown = shown + 1
        end
        if #growth == 0 then
            orig_print("  |cff00ff00No significant memory growth detected.|r")
        end

        memLeakData = nil
    end)
end

SLASH_LUABOOST1 = "/luaboost"
SLASH_LUABOOST2 = "/lb"
SlashCmdList["LUABOOST"] = function(input)
    if not db then InitDB() end
    input = (input or ""):lower():trim()

    if input == "gc" then
        local memKB = orig_collectgarbage("count")
        orig_print(ADDON_COLOR .. L["[LuaBoost]|r GC Stats:"])
        orig_print(orig_format(L["  Memory: %.0f KB (%.1f MB)"], memKB, memKB / 1024))
        orig_print(orig_format(L["  Mode: %s | Step: %d KB/f"], GetModeString(), GetCurrentStepKB()))
        orig_print(orig_format(L["  Lua steps: %d | Emergency: %d | Full: %d"],
            gcStats.stepsLua, gcStats.emergencyGC, gcStats.fullCollects))
        orig_print(orig_format(L["  Loading: %s | Idle: %s | Combat: %s"],
            isLoading and L["yes"] or L["no"], isIdle and L["yes"] or L["no"], inCombat and L["yes"] or L["no"]))

        if hasDLL() and LuaBoostC_GetStats then
            local mem, steps, fulls, pause, stepmul, combat, mode, idle, loading = LuaBoostC_GetStats()
            if mem then
                orig_print(orig_format(L["  DLL: mem=%.0fKB steps=%d full=%d mode=%s"],
                    mem or 0, steps or 0, fulls or 0, mode or L["?"]))
            end
            local gcMs = _G.LUABOOST_DLL_GC_MS
            if gcMs then
                orig_print(orig_format("  DLL GC step: %.2fms avg (budget: 2.0ms)", gcMs))
            end                  
            if LuaBoostC_GetUIStats then
                local sk, ps, active = LuaBoostC_GetUIStats()
                if active then
                    local total = sk + ps
                    local rate = total > 0 and (sk / total * 100) or 0
                    orig_print(orig_format("  DLL UI Cache: %.0f%% skip (%d skipped, %d passed)",
                        rate, sk, ps))
                end
            end
            if LuaBoostC_GetFastPathStats then
                local fpH, fpF, fpActive = LuaBoostC_GetFastPathStats()
                if fpActive then
                    local fpTotal = fpH + fpF
                    local fpRate = fpTotal > 0 and (fpH / fpTotal * 100) or 0
                    orig_print(orig_format("  DLL Fast Path: %.0f%% format (%d fast, %d fallback)",
                        fpRate, fpH, fpF))
                end
            end                                  
        end

    elseif input == "pool" then
        local acq, rel, cre, cur = LuaBoost_GetPoolStats()
        orig_print(orig_format(ADDON_COLOR .. L["[LuaBoost]|r Pool: %d acquired, %d released, %d created, %d available"],
            acq, rel, cre, cur))

    elseif input == "toggle" then
        db.enabled = not db.enabled
        if db.enabled then
            orig_collectgarbage("stop")
        else
            orig_collectgarbage("restart")
        end
        ApplyProtectionHooks()
        Msg(L["GC Manager: "] .. (db.enabled and L["|cff00ff00ON|r"] or L["|cffff0000OFF|r"]))

    elseif input == "force" then
        local b = orig_collectgarbage("count")
        if hasDLL() and LuaBoostC_GCCollect then
            LuaBoostC_GCCollect()
        else
            orig_collectgarbage("collect")
            orig_collectgarbage("collect")
        end
        local a = orig_collectgarbage("count")
        Msg(orig_format(L["Freed %.1f MB"], (b - a) / 1024))
        gcStats.fullCollects = gcStats.fullCollects + 1
        orig_collectgarbage("stop")

    elseif input == "sl" or input == "speedyload" then
        db.speedyLoadEnabled = not db.speedyLoadEnabled
        local status = db.speedyLoadEnabled and L["|cff00ff00ON|r"] or L["|cffff0000OFF|r"]
        local mode = db.speedyLoadMode == "aggressive" and L["aggressive"] or L["safe"]
        local count = #GetSpeedyEventList()
        Msg(string.format(L["SpeedyLoad: %s (%s, %d events)"], status, mode, count))

    elseif input == "sl safe" or input == "speedyload safe" then
        db.speedyLoadEnabled = true
        db.speedyLoadMode = "safe"
        Msg(L["SpeedyLoad: |cff00ff00ON|r (|cff44ff44safe|r, "] .. #SPEEDY_SAFE_EVENTS .. L[" events)"])

    elseif input == "sl agg" or input == "sl aggressive"
        or input == "speedyload aggressive" then
        db.speedyLoadEnabled = true
        db.speedyLoadMode = "aggressive"
        Msg(L["SpeedyLoad: |cff00ff00ON|r (|cffff8844aggressive|r, "] .. #SPEEDY_AGGRESSIVE_EVENTS .. L[" events)"])
        
    elseif input == "thrash" or input == "tg" then
        local sk, ps, hk, act, wid = LuaBoost_GetThrashStats()
        orig_print(ADDON_COLOR .. L["[LuaBoost]|r UI Thrashing Protection:"])
        orig_print(orig_format(L["  Status: %s | Hooks: %d/3"],
            act and "|cff00ff00ACTIVE|r" or "|cffff0000OFF|r", hk))
        orig_print(orig_format(L["  Skipped: |cffffff00%d|r | Passed: |cffffff00%d|r"],
            sk, ps))
        if (sk + ps) > 0 then
            orig_print(orig_format("  Hit rate: |cff00ff00%.1f%%|r",
                sk / (sk + ps) * 100))
        end
        orig_print(orig_format("  Cached widgets: %d", wid))

    elseif input == "tg toggle" or input == "thrash toggle" then
        if thrashStats.active then
            UninstallThrashGuard()
            db.thrashGuardEnabled = false
            Msg(L["UI Thrashing Protection: |cffff0000OFF|r (hooks removed)"])
        else
            db.thrashGuardEnabled = true
            local ok, err = orig_pcall(InstallThrashGuard)
            if ok and thrashStats.active then
                Msg(orig_format(L["UI Thrashing Protection: |cff00ff00ON|r (%d hooks)"],
                    thrashStats.hooked))
            else
                Msg(L["UI Thrashing Protection: |cffff0000FAILED|r — "] .. tostring(err))
            end
        end

    elseif input == "tg reset" or input == "thrash reset" then
        thrashStats.skipped = 0
        thrashStats.passed  = 0
        Msg("ThrashGuard stats reset")

    elseif input == "fps" then
        if fpsMonitor.enabled then
            StopFPSMonitor()
            fpsLastTime = 0
        else
            StartFPSMonitor()
        end
       

    elseif input == "events" then
        if eventProfiler.enabled then
            StopEventProfiler()
        else
            StartEventProfiler()
        end

    elseif input == "memleak" then
        StartMemLeakScan()
        
    elseif input == "updates" then
        orig_print(ADDON_COLOR .. "[LuaBoost]|r OnUpdate Dispatcher:")
        orig_print(orig_format("  Registered callbacks: |cffffff00%d|r", updateCount))
        if updateCount > 0 then
            for id, data in orig_pairs(updateCallbacks) do
                orig_print(orig_format("  - %s (every %.2fs)", id, data.interval))
            end
        end    

    elseif input == "settings" then
        InterfaceOptionsFrame_OpenToCategory(panelSettings)
        InterfaceOptionsFrame_OpenToCategory(panelSettings)

    elseif input == "help" then
        orig_print(ADDON_COLOR .. L["[LuaBoost]|r Commands:"])
        orig_print(L["  /lb              — status"])
        orig_print(L["  /lb gc           — GC stats"])
        orig_print(L["  /lb pool         — table pool stats"])
        orig_print(L["  /lb toggle       — enable/disable GC manager"])
        orig_print(L["  /lb force        — force full GC now"])
        orig_print(L["  /lb sl           — toggle SpeedyLoad"])
        orig_print(L["  /lb sl safe      — SpeedyLoad safe mode"])
        orig_print(L["  /lb sl agg       — SpeedyLoad aggressive mode"])
        orig_print(L["  /lb settings     — open GC settings"])
        orig_print(L["  /lb tg           — UI thrash protection stats"])
        orig_print(L["  /lb tg toggle    — enable/disable thrash guard"])
        orig_print(L["  /lb tg reset     — reset thrash guard counters"])
        orig_print(L["  /lb updates      — show registered update callbacks"])
        orig_print(L["  /lb events       — profile events for 10 seconds"])   
        orig_print(L["  /lb fps          — FPS monitor for 10 seconds"])        
        orig_print(L["  /lb memleak      — addon memory leak scanner (30 sec)"])        
    else
        ShowStatus()
    end
end

-- ================================================================
-- PART G: Initialization
-- ================================================================
local function OnAddonLoaded(event, arg1)
    if arg1 ~= ADDON_NAME and arg1 ~= ("!" .. ADDON_NAME) then return end

    InitDB()
    ApplyProtectionHooks()

    lastActivity = orig_GetTime()
    cachedTime   = orig_GetTime()

    _G.LUABOOST_ADDON_COMBAT  = false
    _G.LUABOOST_ADDON_IDLE    = false
    _G.LUABOOST_ADDON_LOADING = false

    if db.enabled then
        orig_collectgarbage("stop")
    end

    SyncStepsToDLL()
end

local function OnPlayerLogin(event)
    -- Unregister init events — no longer needed
    eventFrame:UnregisterEvent("ADDON_LOADED")
    eventFrame:UnregisterEvent("PLAYER_LOGIN")

    if not db then
        InitDB()
        ApplyProtectionHooks()
        lastActivity = orig_GetTime()
        cachedTime   = orig_GetTime()
        _G.LUABOOST_ADDON_COMBAT  = false
        _G.LUABOOST_ADDON_IDLE    = false
        _G.LUABOOST_ADDON_LOADING = false
        if db.enabled then orig_collectgarbage("stop") end
    end

    SpeedyLoad_HookUnregister()
    if db.speedyLoadEnabled then
        SpeedyLoad_EnsurePriority()
    end

    -- Install UI Thrashing Protection
    -- After /reload, the DLL needs a few seconds to re-register its Lua globals.
    -- delay ThrashGuard installation to give the DLL time to set LUABOOST_DLL_LOADED.
    if db.thrashGuardEnabled then
        if hasDLL() then
            DebugMsg("ThrashGuard: skipped — DLL C-level hooks handle StatusBar caching")
        else
            -- Schedule a delayed check: if DLL appears within 8 seconds, skip ThrashGuard
            local tgCheckFrame = CreateFrame("Frame")
            local tgElapsed = 0
            local tgInstalled = false
            tgCheckFrame:SetScript("OnUpdate", function(self, el)
                tgElapsed = tgElapsed + el
                if hasDLL() then
                    -- DLL showed up (e.g. after /reload re-init)
                    DebugMsg("ThrashGuard: skipped — DLL detected after delay")
                    if tgInstalled then
                        UninstallThrashGuard()
                        DebugMsg("ThrashGuard: uninstalled — DLL took over")
                    end
                    self:SetScript("OnUpdate", nil)
                    return
                end
                if tgElapsed >= 8 then
                    -- DLL didn't appear — install Lua-side ThrashGuard
                    if not tgInstalled then
                        local tgOk, tgErr = orig_pcall(InstallThrashGuard)
                        if tgOk then
                            tgInstalled = true
                        else
                            DebugMsg("ThrashGuard install error: " .. tostring(tgErr))
                        end
                    end
                    self:SetScript("OnUpdate", nil)
                end
            end)
        end
    end

    local parts = {}
    parts[#parts + 1] = ADDON_COLOR .. "[LuaBoost]|r v" .. ADDON_VERSION
    parts[#parts + 1] = db.enabled
        and (L["GC: "] .. VALUE_COLOR .. GetPresetNameDisplay(db.preset) .. "|r")
        or L["GC:|cffff0000OFF|r"]

    if hasDLL() then
        parts[#parts + 1] = "|cff00ff00DLL|r"
    end

    if thrashStats.active then
        parts[#parts + 1] = "|cff00ff00TG:" .. thrashStats.hooked .. "|r"
    elseif db.thrashGuardEnabled then
        parts[#parts + 1] = "|cffffff00TG:wait|r"
    end

    parts[#parts + 1] = VALUE_COLOR .. L["/lb help|r"]
    orig_print(table.concat(parts, " | "))

    if orig_type(SmartGCDB) == "table"
        or (IsAddOnLoaded and (IsAddOnLoaded("SmartGC") or IsAddOnLoaded("!SmartGC"))) then
        orig_print(ADDON_COLOR .. L["[LuaBoost]|r |cffff8844WARNING:|r SmartGC detected. Disable SmartGC to avoid conflicts."])
    end
end

RegisterHandler("ADDON_LOADED", OnAddonLoaded)
RegisterHandler("PLAYER_LOGIN", OnPlayerLogin)
