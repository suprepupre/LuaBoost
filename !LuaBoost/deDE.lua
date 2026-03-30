-- LuaBoost German Localization (Base) v1.3.0
-- This file serves as the default reference for all translations.

LuaBoost_Locale_deDE = {
    -- PART A: Runtime Optimizations

    -- PART B: Smart GC Manager
    ["|cff888888[LuaBoost-DBG]|r "] = "|cff888888[LuaBoost-DBG]|r ",
    ["|cff4488ffloading|r"] = "|cff4488fflade|r",
    ["|cffff4444combat|r"] = "|cffff4444kampf|r",
    ["|cff888888idle|r"] = "|cff888888idle|r",
    ["|cff44ff44normal|r"] = "|cff44ff44normal|r",
    -- GC core
    ["Idle mode activated"] = "Idle Modus aktiviert",
    -- Emergency full GC (not in combat, not loading)
    ["Emergency GC: freed %.1f MB in %.1f ms"] = "Notfall GC: %.1f MB in %.1f ms befreit",
    ["Raised threshold to %d MB"] = "Schwellenwert auf %d MB angehoben",

    -- GC Burst on heavy events
    ["GC burst: %s (step %d KB)"] = "GC burst: %s (step %d KB)",

    -- PART C: SpeedyLoad
    ["SpeedyLoad: UnregisterEvent hook installed"] = "SpeedyLoad: UnregisterEvent-Hook installiert",
    ["SpeedyLoad: PLAYER_ENTERING_WORLD priority set"] = "SpeedyLoad: Priorität PLAYER_ENTERING_WORLD festgelegt",

    -- Loading state frame
    ["SpeedyLoad: suppressed %d registrations (%s)"] = "SpeedyLoad: unterdrückte %d Registrierungen (%s)",
    ["SpeedyLoad: restored %d registrations"] = "SpeedyLoad: %d Registrierungen wiederhergestellt",
    ["SpeedyLoad: restored %d registrations (fallback)"] = "SpeedyLoad: %d Registrierungen wiederhergestellt (Fallback)",

    -- PART D: UI Thrashing Protection    
    -- PART E: GUI (Interface Options)
    -- Main panel
    ["Lua runtime optimizer + smart garbage collector for WoW 3.3.5a."] = "Lua-Laufzeitoptimierer + intelligenter Garbage Collector für WoW 3.3.5a.",
    [" | |cff00ff00DLL|r"] = " | |cff00ff00DLL|r",
    ["%s  |  Mem: %s%.1f MB|r  |  %s  |  %s%d|r KB/f%s"] = "%s  |  Mem: %s%.1f MB|r  |  %s  |  %s%d|r KB/f%s",
    ["|cff00ff00ON|r"] = "|cff00ff00AN|r",
    ["|cffff0000OFF|r"] = "|cffff0000AUS|r",
    ["Enable GC Manager"] = "Aktiviere GC Manager",
    ["Master toggle for smart GC."] = "Hautpschalter für Smart GC.",
    ["GC Presets (Choose based on your combat memory):"] = "GC-Voreinstellungen (Wählen Sie entsprechend Ihrer Kampferfahrung):",
    ["|cffff8844Light (< 150MB)|r"] = "|cffff8844Light (< 150MB)|r",
    ["|cffffff44Std (150-300MB)|r"] = "|cffffff44Std (150-300MB)|r",
    ["|cff44ff44Heavy (> 300MB)|r"] = "|cff44ff44Heavy (> 300MB)|r",
    ["Runtime optimizations are always active."] = "Laufzeitoptimierungen sind immer aktiv.",

    -- SpeedyLoad section
    ["Loading Screen Optimization"] = "Optimierung des Ladebildschirms",
    ["Enable Fast Loading Screens"] = "Schnelle Ladebildschirme aktivieren",
    ["Temporarily suppresses noisy events during loading screens.\n"] = "Unterdrückt vorübergehend störende Ereignisse während des Ladens von Bildschirmen.\n",
    ["Reduces CPU work and speeds up zone transitions.\n"] = "Reduziert die CPU-Auslastung und beschleunigt Zonenübergänge.\n",
    ["Restores all events after loading completes."] = "Stellt alle Ereignisse nach Abschluss des Ladevorgangs wieder her.",
    ["Mode: %s (%d events)"] = "Modus: %s (%d Ereignisse)",
    ["|cff44ff44Safe|r"] = "|cff44ff44Sicher|r",
    ["|cffff8844Aggressive|r"] = "|cffff8844Aggressiv|r",
    ["Mode: %s (%d events)"] = "Modus: %s (%d events)",
    ["|cffff4444GetFramesRegisteredForEvent not available — SpeedyLoad disabled.|r"] = "|cffff4444GetFramesRegisteredForEvent nicht verfügbar – SpeedyLoad deaktiviert.|r",

    -- UI Thrashing Protection section
    ["UI Optimization"] = "UI-Optimierung",
    ["Enable UI Thrashing Protection"] = "UI-Thrashing-Schutz aktivieren",
    ["Caches widget values and skips redundant engine calls.\n"] = "Speichert Widget-Werte zwischen und überspringt redundante Engine-Aufrufe.\n",
    ["Speeds up all addons that update UI every frame.\n"] = "Beschleunigt alle Add-ons, die die Benutzeroberfläche bei jedem Frame aktualisieren.\n",
    ["Hooks: SetValue, SetMinMaxValues, SetStatusBarColor.\n"] = "Hooks: SetValue, SetMinMaxValues, SetStatusBarColor.\n",
    ["StatusBar methods only — FontString hooks removed\n"] = "Nur StatusBar-Methoden – FontString-Hooks entfernt\n",
    ["to prevent taint with Blizzard dropdown menus.\n"] = "um eine Verfälschung durch die Dropdown-Menüs von Blizzard zu verhindern.\n",
    ["|cff44ff44Safe — no taint, no gameplay impact.|r\n"] = "|cff44ff44Sicher – keine Beeinträchtigung, keine Auswirkungen auf das Gameplay.|r\n",
    ["|cffff8844Requires /reload to take effect.|r"] = "|cffff8844Erfordert /reload, um wirksam zu werden.|r",
    ["ThrashGuard: |cff00ff00%d|r hooks | Skipped: |cffffff00%d|r | Passed: |cffffff00%d|r | Rate: |cff00ff00%.0f%%|r"] = "ThrashGuard: |cff00ff00%d|r hooks | Übersprungen: |cffffff00%d|r | Durchgeleitet : |cffffff00%d|r | Rate: |cff00ff00%.0f%%|r",
    ["ThrashGuard: |cffaaaaaaInactive|r"] = "ThrashGuard: |cffaaaaaaInaktiv|r",


    -- GC Settings panel
    ["GC Settings"] = "GC Einstellungen",
    ["GC Settings|r"] = "GC Einstellungen|r",
    ["Step Sizes (KB collected per frame)"] = "Schrittgrößen (pro Frame gesammelte KB)",
    ["Normal Step"] = "Normalmodus",
    ["GC per frame during normal gameplay."] = "GC pro Frame während des normalen Spiels.",
    ["Combat Step"] = "Kampfmodus",
    ["GC per frame in combat (keep low to protect frametime)."] = "GC pro Frame im Kampf (niedrig halten, um die Framezeit zu schützen).",
    ["Idle Step"] = "Leerlaufmodus",
    ["GC per frame while AFK/idle."] = "GC pro Frame bei AFK/Leerlauf.",
    ["Loading Step"] = "Loademodus",
    ["GC per frame during loading screens (no rendering)."] = "GC pro Frame während des Ladens von Bildschirmen (kein Rendering).",
    ["Thresholds"] = "Schwellenwerte",
    ["Emergency Full GC (MB)"] = "Vollständige Notfall-GC (MB)",
    ["Force full GC outside combat when memory exceeds this.\n"] = "Erzwinge eine vollständige GC außerhalb des Kampfes, wenn der Speicher diesen Wert überschreitet.\n",
    ["Set higher (300-500+) if you use many addons to avoid long freezes."] = "Stellen Sie einen höheren Wert (300-500+) ein, wenn Sie viele Add-ons verwenden, um lange Einfrierungen zu vermeiden.",
    ["Idle Timeout (sec)"] = "Leerlauf-Zeitlimit (Sek.)",
    ["Seconds without activity before idle mode."] = "Sekunden ohne Aktivität vor dem Leerlaufmodus.",

    -- Tools panel
    ["Tools"] = "Tools",
    ["Tools & Diagnostics|r"] = "Werkzeuge & Diagnose|r",
    ["Debug mode (GC info in chat)"] = "Debug-Modus (GC-Informationen im Chat)",
    ["Shows GC mode changes, SpeedyLoad activity, and emergency collections."] = "Zeigt Änderungen im GC-Modus, SpeedyLoad-Aktivitäten und Notfall-Sammlungen an.",
    ["Intercept collectgarbage() calls"] = "Aufrufe von collectgarbage() abfangen",
    ["Blocks full GC calls triggered by other addons.\n"] = "Blöcke voller GC-Aufrufe, die durch andere Add-ons ausgelöst werden.\n",
    ["|cffff4444WARNING:|r Causes taint with ElvUI and secure frames.\n"] = "|cffff4444WARNUNG:|r Verursacht Probleme mit ElvUI und sicheren Frames.\n",
    ["Leave OFF if you see 'action blocked' errors."] = "Lassen Sie die Option deaktiviert, wenn Sie Fehlermeldungen wie „Aktion blockiert“ sehen.",
    ["Block UpdateAddOnMemoryUsage()"] = "Blockiert UpdateAddOnMemoryUsage()",
    ["Blocks heavy addon memory scans.\n"] = "Blockiert umfangreiche Add-on-Speicherscans.\n",
    ["MemUsage Min Interval (sec)"] = "Min Intervall für Speicherverbrauch (Sek.)",
    ["Minimum interval between UpdateAddOnMemoryUsage() calls."] = "Mindestintervall zwischen Aufrufen von UpdateAddOnMemoryUsage().",
    ["Force Full GC Now"] = "Volles GC jetzt erzwingen",
    ["|cff44ff44Freed %.1f MB in %.1f ms|r"] = "|cff44ff44%.1f MB in %.1f ms befreit|r",
    ["Reset All to Defaults"] = "Auf Standard zurücksetzen",
    ["Reset all LuaBoost settings to defaults?"] = "Alle LuaBoost-Einstellungen auf die Standardeinstellungen zurücksetzen?",
    ["Yes"] = "Ja",
    ["No"] = "Nein",

    -- PART F: Slash Commands
    ["  GC: %s | Mode: %s | Mem: %.1f MB | Step: %d KB/f"] = "  GC: %s | Modus: %s | Mem: %.1f MB | Schritt: %d KB/f",
    ["  Protection: interceptGC=%s, blockMemUsage=%s"] = "  Schutz: interceptGC=%s, blockMemUsage=%s",
    ["  SpeedyLoad: %s (%s, %d events)"] = "  SpeedyLoad: %s (%s, %d Ereignisse)",
    ["on"] = "An",
    ["off"] = "Aus",
    ["aggressive"] = "aggressiv",
    ["safe"] = "sicher",
    ["  wow_optimize.dll: |cff00ff00CONNECTED|r"] = "  wow_optimize.dll: |cff00ff00VERBUNDEN|r",
    ["  wow_optimize.dll: |cffaaaaaaNOT DETECTED|r"] = "  wow_optimize.dll: |cffaaaaaaNICHT ERKANNT|r",
    ["  ThrashGuard: |cff00ff00ACTIVE|r (%d hooks, %.0f%% skip rate)"] = "  ThrashGuard: |cff00ff00AKTIV|r (%d hooks, %.0f%% (übersprungen)-Rate)",
    ["  ThrashGuard: |cffaaaaaaOFF|r"] = "  ThrashGuard: |cffaaaaaaAUS|r",
    ["/lb help|r"] = "/lb help|r",
    ["[LuaBoost]|r GC Stats:"] = "[LuaBoost]|r GC Stats:",
    ["  Memory: %.0f KB (%.1f MB)"] = "  Speicher: %.0f KB (%.1f MB)",
    ["  Mode: %s | Step: %d KB/f"] = "  Modus: %s | Schritt: %d KB/f",
    ["  Lua steps: %d | Emergency: %d | Full: %d"] = "  Lua Schritte: %d | Notfall: %d | Voll: %d",
    ["  Loading: %s | Idle: %s | Combat: %s"] = "  Lade: %s | Idle: %s | Kampf: %s",
    ["yes"] = "ja",
    ["no"] = "nein",
    ["  DLL: mem=%.0fKB steps=%d full=%d mode=%s"] = "  DLL: mem=%.0fKB steps=%d full=%d mode=%s",
    ["?"] = "?",
    ["[LuaBoost]|r Pool: %d acquired, %d released, %d created, %d available"] = "[LuaBoost]|r Pool: %d acquired, %d released, %d created, %d available",
    ["GC Manager: "] = "GC Manager: ",
    ["Freed %.1f MB"] = "%.1f MB befreit",
    ["SpeedyLoad: %s (%s, %d events)"] = "SpeedyLoad: %s (%s, %d Ereignisse)",
    ["SpeedyLoad: |cff00ff00ON|r (|cff44ff44safe|r, "] = "SpeedyLoad: |cff00ff00AN|r (|cff44ff44Sicher|r, ",
    [" events)"] = " Ereignisse)",
    ["SpeedyLoad: |cff00ff00ON|r (|cffff8844aggressive|r, "] = "SpeedyLoad: |cff00ff00AN|r (|cffff8844aggressiv|r, ",
    ["[LuaBoost]|r UI Thrashing Protection:"] = "[LuaBoost]|r UI-Thrashing-Schutz:",
    ["  Status: %s | Hooks: %d/6"] = "  Status: %s | Hooks: %d/6",
    ["  Skipped: |cffffff00%d|r | Passed: |cffffff00%d|r"] = "  Übersprungen: |cffffff00%d|r | Durchgeleitet : |cffffff00%d|r",
    ["UI Thrashing Protection: |cffff0000OFF|r (hooks removed)"] = "UI Thrashing Protection: |cffff0000AUS|r (hooks entfernt)",
    ["UI Thrashing Protection: |cff00ff00ON|r (%d hooks)"] = "UI Thrashing Protection: |cff00ff00AN|r (%d hooks)",
    ["UI Thrashing Protection: |cffff0000FAILED|r — "] = "UI Thrashing Protection: |cffff0000FEHLER|r — ",
	
    ["[LuaBoost]|r Commands:"] = "[LuaBoost]|r Befehle:",
    ["  /lb               — status"] = "  /lb               — Status",
    ["  /lb gc            — GC stats"] = "  /lb gc            — GC Status",
    ["  /lb pool          — table pool stats"] = "  /lb pool          — Tabelle Pool-Statistiken",
    ["  /lb toggle        — enable/disable GC manager"] = "  /lb toggle        — GC-Manager aktivieren/deaktivieren",
    ["  /lb force         — force full GC now"] = "  /lb force         — Volles GC jetzt erzwingen",
    ["  /lb sl            — toggle SpeedyLoad"] = "  /lb sl            — SpeedyLoad umschalten",
    ["  /lb sl safe       — SpeedyLoad safe mode"] = "  /lb sl safe       — SpeedyLoad-Sicherheitsmodus",
    ["  /lb sl agg        — SpeedyLoad aggressive mode"] = "  /lb sl agg        — SpeedyLoad-Aggressivmodus",
    ["  /lb settings      — open GC settings"] = "  /lb settings      — GC-Einstellungen öffnen",
    ["  /lb tg            — UI thrash protection stats"] = "  /lb tg            — UI-Thrash-Schutz-Statistiken",
    ["  /lb tg toggle     — enable/disable thrash guard"] = "  /lb tg toggle     — Thrash Guard aktivieren/deaktivieren",
    ["  /lb tg reset      — reset thrash guard counters"] = "  /lb tg reset      — Thrash Guard-Zähler zurücksetzen",
    ["  /lb updates      — show registered update callbacks"] = "  /lb updates      — Registrierte Update-Callbacks anzeigen",
    ["  /lb events       — profile events for 10 seconds"] = "  /lb events       — Ereignisse 10 Sekunden lang protokollieren",
    ["  /lb fps          — FPS monitor for 10 seconds"] = "  /lb fps          — FPS-Anzeige für 10 Sekunden",
    ["  /lb memleak      — addon memory leak scanner (30 sec)"] = "  /lb memleak      — Add-on-Speicherleck-Scanner (30 Sek.)",

    -- PART G: Initialization
    ["GC: "] = "GC: ",
    ["GC:|cffff0000OFF|r"] = "GC:|cffff0000AUS|r",
    ["[LuaBoost]|r |cffff8844WARNING:|r SmartGC detected. Disable SmartGC to avoid conflicts."] = "[LuaBoost]|r |cffff8844WARNUNG:|r SmartGC erkannt. Deaktivieren Sie SmartGC, um Konflikte zu vermeiden.",
}
