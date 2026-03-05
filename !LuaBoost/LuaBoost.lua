-- ================================================================
--  LuaBoost v1.2.0 — WoW 3.3.5a Lua Runtime Optimizer
--  Author: Suprematist
--
--  Features:
--   - Faster math.floor/ceil/abs (pure Lua, auto-detect)
--   - Faster table.insert append path
--   - Per-frame GetTimeCached()
--   - Shared throttle API, table pool
--   - Smart incremental GC manager (combat + idle + loading aware)
--   - SpeedyLoad: event suppression during loading screens
--   - Optional protection hooks (intercept GC, block memory scans)
--   - DLL integration (wow_optimize.dll v1.2+)
--
--  v1.2.0 changes:
--   - Auto-detect math optimizations (bench on first run, cache result)
--   - Fixed benchmark output (shows "faster" or "slower" correctly)
--   - Expanded UI slider ranges for heavy addon setups
-- ================================================================

if _G.LUABOOST_LOADED then return end
_G.LUABOOST_LOADED = true

local ADDON_NAME    = "LuaBoost"
local ADDON_VERSION = "1.2.0"
local ADDON_COLOR   = "|cff00ccff"
local VALUE_COLOR   = "|cffffff00"

-- ================================================================
-- Localize frequently used globals
-- ================================================================
local orig_GetTime                = GetTime
local orig_format                 = string.format
local orig_tinsert                = table.insert
local orig_floor                  = math.floor
local orig_ceil                   = math.ceil
local orig_abs                    = math.abs
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
local orig_debugprofilestop       = debugprofilestop
local orig_min                    = math.min
local orig_wipe                   = wipe
local orig_getmetatable           = getmetatable
local orig_hooksecurefunc         = hooksecurefunc
local orig_geterrorhandler        = geterrorhandler
local orig_GetFramesForEvent      = GetFramesRegisteredForEvent

local hasGetFramesForEvent = (orig_type(orig_GetFramesForEvent) == "function")

-- ================================================================
-- PART A: Runtime Optimizations
-- ================================================================

-- A1. Per-frame time cache
local cachedTime  = 0
local frameNumber = 0

local timeFrame = CreateFrame("Frame")
timeFrame:SetScript("OnUpdate", function()
    frameNumber = frameNumber + 1
    cachedTime  = orig_GetTime()
end)

function _G.GetTimeCached()
    return cachedTime
end

function _G.GetFrameNumber()
    return frameNumber
end

-- A2. Faster math functions (applied eagerly; may be reverted by auto-detect)
local function fast_floor(x)
    x = x + 0
    return x - x % 1
end

local function fast_ceil(x)
    x = x + 0
    local f = x - x % 1
    if f == x then return x end
    return f + 1
end

local function fast_abs(x)
    x = x + 0
    if x < 0 then return -x end
    return x
end

-- Apply fast versions immediately (will be adjusted after DB loads)
math.floor = fast_floor
math.ceil  = fast_ceil
math.abs   = fast_abs

-- A2b. Math auto-detect: apply stored choices from SavedVariables
local function ApplyMathChoices()
    -- Called after db is available. Reverts to original if bench showed fast is slower.
    if not db then return end

    if db.mathUseFloor then
        math.floor = fast_floor
    else
        math.floor = orig_floor
    end

    if db.mathUseCeil then
        math.ceil = fast_ceil
    else
        math.ceil = orig_ceil
    end

    if db.mathUseAbs then
        math.abs = fast_abs
    else
        math.abs = orig_abs
    end
end

-- Forward declaration (db defined later)
local db

-- A2c. Math auto-detect benchmark
local MATH_BENCH_N = 200000
local MATH_BENCH_TOLERANCE = 1.05  -- keep fast if within 5% of original

local function RunMathAutoDetect(silent)
    if not db then return end

    local N = MATH_BENCH_N
    local dummy = 0

    -- Warmup
    for i = 1, 5000 do dummy = orig_floor(i * 1.7) end
    for i = 1, 5000 do dummy = fast_floor(i * 1.7) end
    for i = 1, 5000 do dummy = orig_ceil(i * 1.3) end
    for i = 1, 5000 do dummy = fast_ceil(i * 1.3) end
    for i = 1, 5000 do dummy = orig_abs(i * -1.5) end
    for i = 1, 5000 do dummy = fast_abs(i * -1.5) end

    -- Floor
    debugprofilestart()
    for i = 1, N do dummy = orig_floor(i * 1.7) end
    local floor_orig_t = debugprofilestop()

    debugprofilestart()
    for i = 1, N do dummy = fast_floor(i * 1.7) end
    local floor_fast_t = debugprofilestop()

    -- Ceil
    debugprofilestart()
    for i = 1, N do dummy = orig_ceil(i * 1.3) end
    local ceil_orig_t = debugprofilestop()

    debugprofilestart()
    for i = 1, N do dummy = fast_ceil(i * 1.3) end
    local ceil_fast_t = debugprofilestop()

    -- Abs
    debugprofilestart()
    for i = 1, N do dummy = orig_abs(i * -1.5) end
    local abs_orig_t = debugprofilestop()

    debugprofilestart()
    for i = 1, N do dummy = fast_abs(i * -1.5) end
    local abs_fast_t = debugprofilestop()

    -- Decide: use fast unless it's >5% slower than original
    db.mathUseFloor = (floor_fast_t <= floor_orig_t * MATH_BENCH_TOLERANCE)
    db.mathUseCeil  = (ceil_fast_t  <= ceil_orig_t  * MATH_BENCH_TOLERANCE)
    db.mathUseAbs   = (abs_fast_t   <= abs_orig_t   * MATH_BENCH_TOLERANCE)
    db.mathBenchDone = true

    ApplyMathChoices()

    -- Report
    if not silent then
        local function tag(use, fast_t, orig_t)
            if use then
                return "|cff44ff44fast|r"
            else
                return orig_format("|cffff4444original|r (fast was %.0f%% slower)",
                    ((fast_t / orig_t) - 1) * 100)
            end
        end

        orig_print(ADDON_COLOR .. "[LuaBoost]|r Math auto-detect results (" .. N .. " iterations):")
        orig_print(orig_format("  math.floor: orig %6.1f ms, fast %6.1f ms > %s",
            floor_orig_t, floor_fast_t, tag(db.mathUseFloor, floor_fast_t, floor_orig_t)))
        orig_print(orig_format("  math.ceil:  orig %6.1f ms, fast %6.1f ms > %s",
            ceil_orig_t, ceil_fast_t, tag(db.mathUseCeil, ceil_fast_t, ceil_orig_t)))
        orig_print(orig_format("  math.abs:   orig %6.1f ms, fast %6.1f ms > %s",
            abs_orig_t, abs_fast_t, tag(db.mathUseAbs, abs_fast_t, abs_orig_t)))

        local count = 0
        if db.mathUseFloor then count = count + 1 end
        if db.mathUseCeil  then count = count + 1 end
        if db.mathUseAbs   then count = count + 1 end
        orig_print(orig_format("  Using fast versions for %d/3 functions. Saved to settings.", count))
    end
end

-- A3. Faster table.insert for append pattern
local function fast_tinsert(t, pos, value)
    if value == nil then
        t[#t + 1] = pos
    else
        orig_tinsert(t, pos, value)
    end
end

table.insert = fast_tinsert
_G.tinsert   = fast_tinsert

-- A4. Shared throttle API
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

-- A5. Shared table pool
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

-- A6. Cached date() — opt-in API (does not replace _G.date)
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

-- A7. Lua 5.0 compatibility shims
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

    -- Math auto-detect (v1.2.0)
    mathAutoDetect         = true,
    mathBenchDone          = false,
    mathUseFloor           = true,
    mathUseCeil            = true,
    mathUseAbs             = true,
}

local presets = {
    -- Light addon setup: minimal GC overhead, low CPU cost per frame
    -- Good for: few addons, no WeakAuras, simple UI
    weak = {
        frameStepKB            = 20,        
        combatStepKB           = 5,
        idleStepKB             = 80,        
        loadingStepKB          = 150,       
        fullCollectThresholdMB = 150,       
        idleTimeout            = 15,        
    },
    -- Balanced: works for most players with moderate addon setups
    -- Good for: DBM or BigWigs + one damage meter + some UI addons
    mid = {
        frameStepKB            = 50,        
        combatStepKB           = 15,        
        idleStepKB             = 150,       
        loadingStepKB          = 300,       
        fullCollectThresholdMB = 300,       
        idleTimeout            = 15,
    },
    -- Heavy addon setup: aggressive cleanup, prevents post-boss freezes
    -- Good for: DBM + WeakAuras + Skada + nameplates + everything
    strong = {
        frameStepKB            = 100,       
        combatStepKB           = 30,        
        idleStepKB             = 300,       
        loadingStepKB          = 500,      
        fullCollectThresholdMB = 500,      
        idleTimeout            = 20,
    },
}

-- db forward-declared above (local db)

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
        orig_print("|cff888888[LuaBoost-DBG]|r " .. text)
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

    -- Apply stored math choices immediately
    ApplyMathChoices()
end

local function ApplyPreset(name)
    local p = presets[name]
    if not p then return end
    for k, v in orig_pairs(p) do
        db[k] = v
    end
    db.preset = name
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
    if isLoading then return "|cff4488ffloading|r" end
    if inCombat then return "|cffff4444combat|r" end
    if isIdle then return "|cff888888idle|r" end
    return "|cff44ff44normal|r"
end

local function RefreshAllControls()
    for _, c in orig_pairs(allControls) do
        if c.Refresh then c:Refresh() end
    end
end

local function hasDLL()
    return orig_type(LuaBoostC_IsLoaded) == "function"
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

local gcFrame = CreateFrame("Frame")
gcFrame:SetScript("OnUpdate", function()
    if not db or not db.enabled then return end

    -- Idle detection
    if not isIdle and not inCombat and not isLoading
       and (orig_GetTime() - lastActivity) > db.idleTimeout then
        isIdle = true
        WriteIdleGlobal()
        DebugMsg("Idle mode activated")
    end

    -- Periodic: re-stop GC
    gcReStopCounter = gcReStopCounter + 1
    if gcReStopCounter >= 300 then
        gcReStopCounter = 0
        orig_collectgarbage("stop")
    end

    -- Emergency full GC (not in combat, not loading)
    local memKB = orig_collectgarbage("count")
    if memKB > (db.fullCollectThresholdMB * 1024) and not inCombat and not isLoading then
        debugprofilestart()
        orig_collectgarbage("collect")
        orig_collectgarbage("collect")
        local dt = orig_debugprofilestop()

        local memAfterKB = orig_collectgarbage("count")
        gcStats.emergencyGC = gcStats.emergencyGC + 1

        DebugMsg(orig_format("Emergency GC: freed %.1f MB in %.1f ms",
            (memKB - memAfterKB) / 1024, dt))

        if dt > 50 and db.fullCollectThresholdMB < 1000 then
            db.fullCollectThresholdMB = db.fullCollectThresholdMB + 20
            DebugMsg("Raised threshold to " .. db.fullCollectThresholdMB .. " MB")
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

-- Combat tracking
local combatFrame = CreateFrame("Frame")
combatFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
combatFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
combatFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_REGEN_DISABLED" then
        inCombat = true
        lastActivity = orig_GetTime()
        if isIdle then isIdle = false; WriteIdleGlobal() end
        WriteCombatGlobal()

        if hasDLL() and LuaBoostC_SetCombat then
            LuaBoostC_SetCombat(true)
        end

    elseif event == "PLAYER_REGEN_ENABLED" then
        inCombat = false
        lastActivity = orig_GetTime()
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
end)

-- ================================================================
-- GC Burst on heavy events
-- ================================================================
local burstFrame = CreateFrame("Frame")
local burstEvents = {
    "LFG_PROPOSAL_SHOW",
    "LFG_PROPOSAL_SUCCEEDED",
    "LFG_COMPLETION_REWARD",
    "ACHIEVEMENT_EARNED",
    "CHAT_MSG_LOOT",
    "ENCOUNTER_END",
}
for _, ev in orig_ipairs(burstEvents) do
    burstFrame:RegisterEvent(ev)
end

burstFrame:SetScript("OnEvent", function(self, event)
    if not db or not db.enabled then return end

    local burstKB = 128

    DebugMsg(orig_format("GC burst: %s (step %d KB)", event, burstKB))

    if hasDLL() and LuaBoostC_GCStep then
        LuaBoostC_GCStep(burstKB)
    else
        orig_collectgarbage("step", burstKB)
    end

    gcStats.stepsLua = gcStats.stepsLua + 1
end)

-- Activity tracking (idle reset)
local activityFrame = CreateFrame("Frame")
local activityEvents = {
    "PLAYER_STARTED_MOVING", "PLAYER_STOPPED_MOVING",
    "UNIT_SPELLCAST_START", "UNIT_SPELLCAST_SUCCEEDED",
    "CHAT_MSG_SAY", "CHAT_MSG_PARTY", "CHAT_MSG_RAID",
    "CHAT_MSG_GUILD", "CHAT_MSG_WHISPER", "CHAT_MSG_WHISPER_INFORM",
    "LOOT_OPENED", "BAG_UPDATE", "ACTIONBAR_UPDATE_STATE",
    "MERCHANT_SHOW", "AUCTION_HOUSE_SHOW", "BANKFRAME_OPENED",
    "MAIL_SHOW", "QUEST_DETAIL",
}
for _, event in orig_pairs(activityEvents) do
    activityFrame:RegisterEvent(event)
end
activityFrame:SetScript("OnEvent", function()
    lastActivity = orig_GetTime()
    if isIdle then isIdle = false; WriteIdleGlobal() end
end)

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
local lastPostLoadGC = 0

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

    for k in orig_pairs(speedyTracked) do speedyTracked[k] = nil end
    orig_wipe(speedyOccurred)

    local eventList = GetSpeedyEventList()
    for i = 1, #eventList do
        speedyTracked[eventList[i]] = {}
    end

    local count = 0

    for event, frames in orig_pairs(speedyTracked) do
        for i = 1, orig_select("#", orig_GetFramesForEvent(event)) do
            local frame = orig_select(i, orig_GetFramesForEvent(event))
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
        DebugMsg("SpeedyLoad: UnregisterEvent hook installed")
    end
end

local loadFrame -- forward declaration

local function SpeedyLoad_EnsurePriority()
    if not hasGetFramesForEvent or not loadFrame then return end

    local frames = {orig_GetFramesForEvent("PLAYER_ENTERING_WORLD")}
    for i = 1, #frames do
        orig_pcall(frames[i].UnregisterEvent, frames[i], "PLAYER_ENTERING_WORLD")
    end

    loadFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

    for i = 1, #frames do
        if frames[i] ~= loadFrame then
            orig_pcall(frames[i].RegisterEvent, frames[i], "PLAYER_ENTERING_WORLD")
        end
    end

    if PetStableFrame then
        orig_pcall(PetStableFrame.UnregisterEvent, PetStableFrame, "SPELLS_CHANGED")
    end

    DebugMsg("SpeedyLoad: PLAYER_ENTERING_WORLD priority set")
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

loadFrame = CreateFrame("Frame")
loadFrame:RegisterEvent("PLAYER_LEAVING_WORLD")
loadFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
loadFrame:RegisterEvent("LOADING_SCREEN_ENABLED")
loadFrame:RegisterEvent("LOADING_SCREEN_DISABLED")
loadFrame:SetScript("OnEvent", function(self, event)

    if event == "PLAYER_LEAVING_WORLD" then
        isLoading = true
        WriteLoadingGlobal()

        if db and db.speedyLoadEnabled then
            local n = SpeedyLoad_Suppress()
            DebugMsg(orig_format("SpeedyLoad: suppressed %d registrations (%s)",
                n, db.speedyLoadMode))
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
        lastActivity = orig_GetTime()
        if isIdle then isIdle = false; WriteIdleGlobal() end

        DoPostLoadGC()

    elseif event == "LOADING_SCREEN_DISABLED" then
        if speedySuppressed then
            local n = SpeedyLoad_Restore()
            DebugMsg(orig_format("SpeedyLoad: restored %d registrations (fallback)", n))
        end

        if isLoading then
            isLoading = false
            WriteLoadingGlobal()
            lastActivity = orig_GetTime()
            if isIdle then isIdle = false; WriteIdleGlobal() end

            DoPostLoadGC()
        end
    end
end)

-- ================================================================
-- PART D: Benchmark
-- ================================================================

-- [v1.2.0] Correct faster/slower formatting
local function FormatBenchLine(label, orig_t, fast_t, suffix)
    suffix = suffix or ""
    if orig_t <= 0 then
        return orig_format("  %-14s %7.1f ms -> %7.1f ms%s", label, orig_t, fast_t, suffix)
    end
    local p = (1 - fast_t / orig_t) * 100
    if p >= 0 then
        return orig_format("  %-14s %7.1f ms -> %7.1f ms  (|cff44ff44%.0f%% faster|r)%s",
            label, orig_t, fast_t, p, suffix)
    else
        return orig_format("  %-14s %7.1f ms -> %7.1f ms  (|cffff4444%.0f%% slower|r)%s",
            label, orig_t, fast_t, -p, suffix)
    end
end

local function RunBenchmark()
    local N = 1000000
    local dummy = 0

    orig_print(ADDON_COLOR .. "[LuaBoost]|r Running benchmark (" .. N .. " iterations)...")

    debugprofilestart()
    for i = 1, N do dummy = orig_floor(i * 1.7) end
    local floor_orig = debugprofilestop()

    debugprofilestart()
    for i = 1, N do dummy = fast_floor(i * 1.7) end
    local floor_fast = debugprofilestop()

    debugprofilestart()
    for i = 1, N do dummy = orig_ceil(i * 1.3) end
    local ceil_orig = debugprofilestop()

    debugprofilestart()
    for i = 1, N do dummy = fast_ceil(i * 1.3) end
    local ceil_fast = debugprofilestop()

    debugprofilestart()
    for i = 1, N do dummy = orig_abs(i * -1.5) end
    local abs_orig = debugprofilestop()

    debugprofilestart()
    for i = 1, N do dummy = fast_abs(i * -1.5) end
    local abs_fast = debugprofilestop()

    local K = 100000
    local benchTable = {}
    debugprofilestart()
    for i = 1, K do orig_tinsert(benchTable, i) end
    local insert_orig = debugprofilestop()

    benchTable = {}
    debugprofilestart()
    for i = 1, K do benchTable[#benchTable + 1] = i end
    local insert_fast = debugprofilestop()

    -- [v1.2.0] Show active status for each math function
    local function activeTag(use)
        if use then return " |cff44ff44[active]|r" else return " |cff888888[original]|r" end
    end

    orig_print(ADDON_COLOR .. "[LuaBoost]|r Results (lower ms = better):")
    orig_print(FormatBenchLine("math.floor:",   floor_orig,  floor_fast,
        db and activeTag(db.mathUseFloor) or ""))
    orig_print(FormatBenchLine("math.ceil:",    ceil_orig,   ceil_fast,
        db and activeTag(db.mathUseCeil) or ""))
    orig_print(FormatBenchLine("math.abs:",     abs_orig,    abs_fast,
        db and activeTag(db.mathUseAbs) or ""))
    orig_print(FormatBenchLine("table.insert:", insert_orig, insert_fast, " (100k)"))
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

    function cb:Refresh() self:SetChecked(get()) end
    cb:SetScript("OnClick", function(self) set(self:GetChecked() and true or false) end)

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
    if self.built then RefreshAllControls() return end
    self.built = true

    Label(self, ADDON_COLOR .. "LuaBoost|r v" .. ADDON_VERSION, 16, -16, "GameFontNormalLarge")

    Label(self, "Lua runtime optimizer + smart garbage collector for WoW 3.3.5a.", 16, -36, "GameFontHighlightSmall")

    local statusLabel = Label(self, "", 16, -56, "GameFontNormal")
    statusLabel:SetWidth(500)

    local timer = 0
    self:SetScript("OnUpdate", function(_, el)
        timer = timer + el
        if timer < 0.5 then return end
        timer = 0
        if not db then return end

        local dllTag = hasDLL() and " | |cff00ff00DLL|r" or ""
        statusLabel:SetText(orig_format(
            "%s  |  Mem: %s%.1f MB|r  |  %s  |  %s%d|r KB/f%s",
            db.enabled and "|cff00ff00ON|r" or "|cffff0000OFF|r",
            VALUE_COLOR, GetMemoryMB(),
            GetModeString(),
            VALUE_COLOR, GetCurrentStepKB(),
            dllTag
        ))
    end)

    Checkbox(self, "Enable GC Manager",
        "Master toggle for smart GC.",
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

    Label(self, "GC Presets:", 16, -106, "GameFontNormal")

    local pdata = {
        { k = "weak",   l = "|cffff8844Weak|r",   x = 95 },
        { k = "mid",    l = "|cffffff44Mid|r",    x = 205 },
        { k = "strong", l = "|cff44ff44Strong|r", x = 315 },
    }

    for _, p in orig_pairs(pdata) do
        local b = CreateFrame("Button", nil, self, "UIPanelButtonTemplate")
        b:SetSize(100, 22)
        b:SetPoint("TOPLEFT", p.x, -103)
        b:SetText(p.l)
        b:SetScript("OnClick", function()
            ApplyPreset(p.k)
            RefreshAllControls()
        end)
    end

    Label(self, "Runtime optimizations are always active.", 16, -138, "GameFontHighlightSmall")

    -- SpeedyLoad section
    Label(self, "Loading Screen Optimization", 16, -170, "GameFontNormal")

    Checkbox(self, "Enable Fast Loading Screens",
        "Temporarily suppresses noisy events during loading screens.\n"
        .. "Reduces CPU work and speeds up zone transitions.\n"
        .. "Restores all events after loading completes.",
        14, -190,
        function() return db.speedyLoadEnabled end,
        function(v) db.speedyLoadEnabled = v end
    )

    local speedyModeLabel = Label(self, "", 16, -218, "GameFontHighlightSmall")
    speedyModeLabel:SetWidth(300)

    local function UpdateSpeedyModeLabel()
        if not db then return end
        if db.speedyLoadMode == "aggressive" then
            speedyModeLabel:SetText("Mode: |cffff8844Aggressive|r (" .. #SPEEDY_AGGRESSIVE_EVENTS .. " events)")
        else
            speedyModeLabel:SetText("Mode: |cff44ff44Safe|r (" .. #SPEEDY_SAFE_EVENTS .. " events)")
        end
    end

    local safeBtn = CreateFrame("Button", nil, self, "UIPanelButtonTemplate")
    safeBtn:SetSize(100, 22)
    safeBtn:SetPoint("TOPLEFT", 220, -188)
    safeBtn:SetText("|cff44ff44Safe|r")
    safeBtn:SetScript("OnClick", function()
        db.speedyLoadMode = "safe"
        UpdateSpeedyModeLabel()
    end)

    local aggBtn = CreateFrame("Button", nil, self, "UIPanelButtonTemplate")
    aggBtn:SetSize(100, 22)
    aggBtn:SetPoint("TOPLEFT", 320, -188)
    aggBtn:SetText("|cffff8844Aggressive|r")
    aggBtn:SetScript("OnClick", function()
        db.speedyLoadMode = "aggressive"
        UpdateSpeedyModeLabel()
    end)

    UpdateSpeedyModeLabel()

    if not hasGetFramesForEvent then
        Label(self, "|cffff4444GetFramesRegisteredForEvent not available — SpeedyLoad disabled.|r",
            16, -238, "GameFontHighlightSmall")
    end
end)

InterfaceOptions_AddCategory(panelMain)

-- GC Settings panel
local panelSettings = CreateFrame("Frame", "LuaBoostPanelSettings", InterfaceOptionsFramePanelContainer)
panelSettings.name = "GC Settings"
panelSettings.parent = "LuaBoost"
panelSettings:Hide()

panelSettings:SetScript("OnShow", function(self)
    if self.built then RefreshAllControls() return end
    self.built = true

    Label(self, ADDON_COLOR .. "GC Settings|r", 16, -16, "GameFontNormalLarge")

    Label(self, "Step Sizes (KB collected per frame)", 16, -56, "GameFontNormal")

    -- [v1.2.0] Expanded slider ranges for heavy addon setups
    Slider(self, "Normal Step", "GC per frame during normal gameplay.", 20, -86,
        1, 500, 5,                                                          -- was 1-200
        function() return db.frameStepKB end,
        function(v) db.frameStepKB = v; db.preset = "custom" end
    )

    Slider(self, "Combat Step", "GC per frame in combat (keep low to protect frametime).", 20, -138,
        0, 100, 1,                                                          -- was 0-50
        function() return db.combatStepKB end,
        function(v) db.combatStepKB = v; db.preset = "custom" end
    )

    Slider(self, "Idle Step", "GC per frame while AFK/idle.", 20, -190,
        10, 1000, 10,                                                       -- was 10-500
        function() return db.idleStepKB end,
        function(v) db.idleStepKB = v; db.preset = "custom" end
    )

    Slider(self, "Loading Step", "GC per frame during loading screens (no rendering).", 20, -242,
        50, 1000, 25,                                                       -- was 50-500
        function() return db.loadingStepKB end,
        function(v) db.loadingStepKB = v; db.preset = "custom" end
    )

    Label(self, "Thresholds", 16, -296, "GameFontNormal")

    Slider(self, "Emergency Full GC (MB)",
        "Force full GC outside combat when memory exceeds this.\n"
        .. "Set higher (300-500+) if you use many addons to avoid long freezes.", 20, -326,
        20, 1000, 10,                                                       -- was 20-300
        function() return db.fullCollectThresholdMB end,
        function(v) db.fullCollectThresholdMB = v; db.preset = "custom" end
    )

    Slider(self, "Idle Timeout (sec)", "Seconds without activity before idle mode.", 20, -378,
        5, 120, 5,
        function() return db.idleTimeout end,
        function(v) db.idleTimeout = v end
    )
end)

InterfaceOptions_AddCategory(panelSettings)

-- Tools panel
local panelTools = CreateFrame("Frame", "LuaBoostPanelTools", InterfaceOptionsFramePanelContainer)
panelTools.name = "Tools"
panelTools.parent = "LuaBoost"
panelTools:Hide()

panelTools:SetScript("OnShow", function(self)
    if self.built then RefreshAllControls() return end
    self.built = true

    Label(self, ADDON_COLOR .. "Tools & Diagnostics|r", 16, -16, "GameFontNormalLarge")

    Checkbox(self, "Debug mode (GC info in chat)",
        "Shows GC mode changes, SpeedyLoad activity, and emergency collections.",
        14, -40,
        function() return db.debugMode end,
        function(v) db.debugMode = v end
    )

    Checkbox(self, "Intercept collectgarbage() calls",
        "Blocks full GC calls triggered by other addons.\n"
        .. "|cffff4444WARNING:|r Causes taint with ElvUI and secure frames.\n"
        .. "Leave OFF if you see 'action blocked' errors.",
        14, -66,
        function() return db.interceptGC end,
        function(v) db.interceptGC = v and true or false; ApplyProtectionHooks() end
    )

    Checkbox(self, "Block UpdateAddOnMemoryUsage()",
        "Blocks heavy addon memory scans.\n"
        .. "|cffff4444WARNING:|r Causes taint with ElvUI and secure frames.\n"
        .. "Leave OFF if you see 'action blocked' errors.",
        14, -92,
        function() return db.blockMemoryUsage end,
        function(v) db.blockMemoryUsage = v and true or false; ApplyProtectionHooks() end
    )

    Slider(self, "MemUsage Min Interval (sec)", "Minimum interval between UpdateAddOnMemoryUsage() calls.", 20, -132,
        0, 10, 1,
        function() return db.memoryUsageMinInterval end,
        function(v) db.memoryUsageMinInterval = v end
    )

    local resultLabel = Label(self, "", 200, -175, "GameFontHighlightSmall")
    resultLabel:SetWidth(300)

    local forceBtn = CreateFrame("Button", nil, self, "UIPanelButtonTemplate")
    forceBtn:SetSize(170, 22)
    forceBtn:SetPoint("TOPLEFT", 16, -172)
    forceBtn:SetText("Force Full GC Now")
    forceBtn:SetScript("OnClick", function()
        local before = orig_collectgarbage("count")
        debugprofilestart()

        if hasDLL() and LuaBoostC_GCCollect then
            LuaBoostC_GCCollect()
        else
            orig_collectgarbage("collect")
            orig_collectgarbage("collect")
        end

        local dt = orig_debugprofilestop()
        local after = orig_collectgarbage("count")
        local freed = (before - after) / 1024

        resultLabel:SetText(orig_format("|cff44ff44Freed %.1f MB in %.1f ms|r", freed, dt))
        gcStats.fullCollects = gcStats.fullCollects + 1
        orig_collectgarbage("stop")
    end)

    local benchBtn = CreateFrame("Button", nil, self, "UIPanelButtonTemplate")
    benchBtn:SetSize(170, 22)
    benchBtn:SetPoint("TOPLEFT", 16, -200)
    benchBtn:SetText("Run Benchmark")
    benchBtn:SetScript("OnClick", function() RunBenchmark() end)

    local resetBtn = CreateFrame("Button", nil, self, "UIPanelButtonTemplate")
    resetBtn:SetSize(170, 22)
    resetBtn:SetPoint("TOPLEFT", 16, -228)
    resetBtn:SetText("Reset All to Defaults")
    resetBtn:SetScript("OnClick", function()
        StaticPopupDialogs["LUABOOST_RESET"] = {
            text = "Reset all LuaBoost settings to defaults?\n(Math auto-detect will re-run on next login)",
            button1 = "Yes", button2 = "No",
            OnAccept = function()
                LuaBoostDB = nil
                InitDB()
                ApplyProtectionHooks()
                RefreshAllControls()
                resultLabel:SetText("")
            end,
            timeout = 0, whileDead = true, hideOnEscape = true,
        }
        StaticPopup_Show("LUABOOST_RESET")
    end)

    -- [v1.2.0] Math auto-detect section
    Label(self, "Math Optimizations", 16, -268, "GameFontNormal")

    local mathStatusLabel = Label(self, "", 16, -288, "GameFontHighlightSmall")
    mathStatusLabel:SetWidth(500)

    local function UpdateMathStatus()
        if not db then return end
        local function fn_status(use, name)
            if use then return "|cff44ff44fast|r" else return "|cff888888original|r" end
        end
        local benchTag = db.mathBenchDone and "|cff44ff44done|r" or "|cffffff44pending|r"
        mathStatusLabel:SetText(orig_format(
            "floor: %s  |  ceil: %s  |  abs: %s  |  bench: %s",
            fn_status(db.mathUseFloor, "floor"),
            fn_status(db.mathUseCeil, "ceil"),
            fn_status(db.mathUseAbs, "abs"),
            benchTag
        ))
    end

    Checkbox(self, "Auto-detect math on first run",
        "Runs a quick micro-benchmark on first login to determine\n"
        .. "whether fast math replacements are actually faster on your CPU.\n"
        .. "Result is saved — bench only runs once.",
        14, -304,
        function() return db.mathAutoDetect end,
        function(v) db.mathAutoDetect = v end
    )

    local mathBenchBtn = CreateFrame("Button", nil, self, "UIPanelButtonTemplate")
    mathBenchBtn:SetSize(170, 22)
    mathBenchBtn:SetPoint("TOPLEFT", 16, -332)
    mathBenchBtn:SetText("Re-run Math Auto-detect")
    mathBenchBtn:SetScript("OnClick", function()
        db.mathBenchDone = false
        RunMathAutoDetect(false)
        UpdateMathStatus()
        RefreshAllControls()
    end)

    -- Initial update
    UpdateMathStatus()

    -- Refresh math status when panel shows
    local origRefresh = self.Refresh
    function self:Refresh()
        if origRefresh then origRefresh(self) end
        UpdateMathStatus()
    end
end)

InterfaceOptions_AddCategory(panelTools)


-- ================================================================
-- PART F: Slash Commands
-- ================================================================
local function ShowStatus()
    orig_print(ADDON_COLOR .. "[LuaBoost]|r v" .. ADDON_VERSION)
    if db then
        orig_print(orig_format("  GC: %s | Mode: %s | Mem: %.1f MB | Step: %d KB/f",
            db.enabled and "|cff00ff00ON|r" or "|cffff0000OFF|r",
            GetModeString(), GetMemoryMB(), GetCurrentStepKB()))
        orig_print(orig_format("  Protection: interceptGC=%s, blockMemUsage=%s",
            db.interceptGC and "on" or "off",
            db.blockMemoryUsage and "on" or "off"))
        orig_print(orig_format("  SpeedyLoad: %s (%s, %d events)",
            db.speedyLoadEnabled and "|cff00ff00ON|r" or "|cffaaaaaaOFF|r",
            db.speedyLoadMode,
            #GetSpeedyEventList()))
        -- [v1.2.0] Math status
        local mathCount = 0
        if db.mathUseFloor then mathCount = mathCount + 1 end
        if db.mathUseCeil  then mathCount = mathCount + 1 end
        if db.mathUseAbs   then mathCount = mathCount + 1 end
        orig_print(orig_format("  Math: %d/3 fast | bench: %s",
            mathCount,
            db.mathBenchDone and "done" or "pending"))
    end
    if hasDLL() then
        orig_print("  wow_optimize.dll: |cff00ff00CONNECTED|r")
    else
        orig_print("  wow_optimize.dll: |cffaaaaaaNOT DETECTED|r")
    end
    orig_print("  " .. VALUE_COLOR .. "/lb help|r")
end

SLASH_LUABOOST1 = "/luaboost"
SLASH_LUABOOST2 = "/lb"
SlashCmdList["LUABOOST"] = function(input)
    if not db then InitDB() end
    input = (input or ""):lower():trim()

    if input == "bench" or input == "benchmark" then
        RunBenchmark()

    elseif input == "gc" then
        local memKB = orig_collectgarbage("count")
        orig_print(ADDON_COLOR .. "[LuaBoost]|r GC Stats:")
        orig_print(orig_format("  Memory: %.0f KB (%.1f MB)", memKB, memKB / 1024))
        orig_print(orig_format("  Mode: %s | Step: %d KB/f", GetModeString(), GetCurrentStepKB()))
        orig_print(orig_format("  Lua steps: %d | Emergency: %d | Full: %d",
            gcStats.stepsLua, gcStats.emergencyGC, gcStats.fullCollects))
        orig_print(orig_format("  Loading: %s | Idle: %s | Combat: %s",
            isLoading and "yes" or "no", isIdle and "yes" or "no", inCombat and "yes" or "no"))

        if hasDLL() and LuaBoostC_GetStats then
            local mem, steps, fulls, pause, stepmul, combat, mode, idle, loading = LuaBoostC_GetStats()
            if mem then
                orig_print(orig_format("  DLL: mem=%.0fKB steps=%d full=%d mode=%s",
                    mem or 0, steps or 0, fulls or 0, mode or "?"))
            end
        end

    elseif input == "pool" then
        local acq, rel, cre, cur = LuaBoost_GetPoolStats()
        orig_print(orig_format(ADDON_COLOR .. "[LuaBoost]|r Pool: %d acquired, %d released, %d created, %d available",
            acq, rel, cre, cur))

    elseif input == "toggle" then
        db.enabled = not db.enabled
        if db.enabled then orig_collectgarbage("stop") else orig_collectgarbage("restart") end
        ApplyProtectionHooks()
        Msg("GC Manager: " .. (db.enabled and "|cff00ff00ON|r" or "|cffff0000OFF|r"))

    elseif input == "force" then
        local b = orig_collectgarbage("count")
        if hasDLL() and LuaBoostC_GCCollect then
            LuaBoostC_GCCollect()
        else
            orig_collectgarbage("collect")
            orig_collectgarbage("collect")
        end
        local a = orig_collectgarbage("count")
        Msg(orig_format("Freed %.1f MB", (b - a) / 1024))
        gcStats.fullCollects = gcStats.fullCollects + 1
        orig_collectgarbage("stop")

    elseif input == "sl" or input == "speedyload" then
        db.speedyLoadEnabled = not db.speedyLoadEnabled
        Msg("SpeedyLoad: " .. (db.speedyLoadEnabled and "|cff00ff00ON|r" or "|cffff0000OFF|r")
            .. " (" .. db.speedyLoadMode .. ", " .. #GetSpeedyEventList() .. " events)")

    elseif input == "sl safe" or input == "speedyload safe" then
        db.speedyLoadEnabled = true
        db.speedyLoadMode = "safe"
        Msg("SpeedyLoad: |cff00ff00ON|r (|cff44ff44safe|r, " .. #SPEEDY_SAFE_EVENTS .. " events)")

    elseif input == "sl agg" or input == "sl aggressive"
        or input == "speedyload aggressive" then
        db.speedyLoadEnabled = true
        db.speedyLoadMode = "aggressive"
        Msg("SpeedyLoad: |cff00ff00ON|r (|cffff8844aggressive|r, " .. #SPEEDY_AGGRESSIVE_EVENTS .. " events)")

    -- [v1.2.0] Math auto-detect commands
    elseif input == "mathbench" or input == "math bench" then
        db.mathBenchDone = false
        RunMathAutoDetect(false)

    elseif input == "math" then
        orig_print(ADDON_COLOR .. "[LuaBoost]|r Math functions:")
        local function fn_line(name, use)
            return orig_format("  %s: %s", name,
                use and "|cff44ff44fast (LuaBoost)|r" or "|cff888888original (Lua/C)|r")
        end
        orig_print(fn_line("math.floor", db.mathUseFloor))
        orig_print(fn_line("math.ceil",  db.mathUseCeil))
        orig_print(fn_line("math.abs",   db.mathUseAbs))
        orig_print(orig_format("  Auto-detect: %s | Bench: %s",
            db.mathAutoDetect and "on" or "off",
            db.mathBenchDone and "done" or "pending"))
        orig_print("  " .. VALUE_COLOR .. "/lb mathbench|r to re-run detection")

    elseif input == "settings" then
        InterfaceOptionsFrame_OpenToCategory(panelSettings)
        InterfaceOptionsFrame_OpenToCategory(panelSettings)

    elseif input == "help" then
        orig_print(ADDON_COLOR .. "[LuaBoost]|r Commands:")
        orig_print("  /lb              — status")
        orig_print("  /lb bench        — benchmark")
        orig_print("  /lb gc           — GC stats")
        orig_print("  /lb pool         — table pool stats")
        orig_print("  /lb toggle       — enable/disable GC manager")
        orig_print("  /lb force        — force full GC now")
        orig_print("  /lb sl           — toggle SpeedyLoad")
        orig_print("  /lb sl safe      — SpeedyLoad safe mode")
        orig_print("  /lb sl agg       — SpeedyLoad aggressive mode")
        orig_print("  /lb math         — math optimization status")
        orig_print("  /lb mathbench    — re-run math auto-detect")
        orig_print("  /lb settings     — open GC settings")
    else
        ShowStatus()
    end
end

-- ================================================================
-- PART G: Initialization
-- ================================================================
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 ~= ADDON_NAME and arg1 ~= ("!" .. ADDON_NAME) then return end

        InitDB()           -- also calls ApplyMathChoices() for saved results
        ApplyProtectionHooks()

        lastActivity = orig_GetTime()
        cachedTime   = orig_GetTime()

        _G.LUABOOST_ADDON_COMBAT  = false
        _G.LUABOOST_ADDON_IDLE    = false
        _G.LUABOOST_ADDON_LOADING = false

        if db.enabled then
            orig_collectgarbage("stop")
        end

    elseif event == "PLAYER_LOGIN" then
        self:UnregisterEvent("ADDON_LOADED")
        self:UnregisterEvent("PLAYER_LOGIN")

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

        -- SpeedyLoad: hook UnregisterEvent and ensure priority
        SpeedyLoad_HookUnregister()
        SpeedyLoad_EnsurePriority()

        -- [v1.2.0] Schedule math auto-detect if needed (5 sec delay to avoid login lag)
        if db.mathAutoDetect and not db.mathBenchDone then
            local benchDelay = CreateFrame("Frame")
            local elapsed = 0
            benchDelay:SetScript("OnUpdate", function(f, dt)
                elapsed = elapsed + dt
                if elapsed >= 5 then
                    f:SetScript("OnUpdate", nil)
                    RunMathAutoDetect(false)
                end
            end)
        end

        -- Login message
        local parts = {}
        parts[#parts + 1] = ADDON_COLOR .. "[LuaBoost]|r v" .. ADDON_VERSION
        parts[#parts + 1] = db.enabled
            and ("GC:" .. VALUE_COLOR .. (db.preset or "custom") .. "|r")
            or "GC:|cffff0000OFF|r"
        if db.speedyLoadEnabled then
            parts[#parts + 1] = "SL:|cff00ff00" .. db.speedyLoadMode .. "|r"
        end
        if hasDLL() then parts[#parts + 1] = "|cff00ff00DLL|r" end

        -- [v1.2.0] Math status in login message
        if db.mathBenchDone then
            local mc = 0
            if db.mathUseFloor then mc = mc + 1 end
            if db.mathUseCeil  then mc = mc + 1 end
            if db.mathUseAbs   then mc = mc + 1 end
            parts[#parts + 1] = orig_format("Math:%s%d/3|r", VALUE_COLOR, mc)
        else
            parts[#parts + 1] = "Math:|cffffff44detecting...|r"
        end

        parts[#parts + 1] = VALUE_COLOR .. "/lb|r help"
        orig_print(table.concat(parts, " | "))

        if orig_type(SmartGCDB) == "table"
            or (IsAddOnLoaded and (IsAddOnLoaded("SmartGC") or IsAddOnLoaded("!SmartGC"))) then
            orig_print(ADDON_COLOR .. "[LuaBoost]|r |cffff8844WARNING:|r SmartGC detected. Disable SmartGC to avoid conflicts.")
        end
    end
end)