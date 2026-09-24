-- LuaBoost Russian Localization v1.0.0
-- Перевод на русский язык

LuaBoost_Locale_ruRU = {
    -- PART A: Runtime Optimizations

    -- PART B: Smart GC Manager
    ["|cff888888[LuaBoost-DBG]|r "] = "|cff888888[LuaBoost-DBG]|r ",
    ["|cff4488ffloading|r"] = "|cff4488ffзагрузка|r",
    ["|cffff4444combat|r"] = "|cffff4444бой|r",
    ["|cff888888idle|r"] = "|cff888888простой|r",
    ["|cff44ff44normal|r"] = "|cff44ff44нормальный|r",
    -- GC core
    ["Idle mode activated"] = "Режим простоя активирован",
    -- Emergency full GC (not in combat, not loading)
    ["Emergency GC: freed %.1f MB in %.1f ms"] = "Экстренный GC: освобождено %.1f МБ за %.1f мс",
    ["Raised threshold to %d MB"] = "Порог увеличен до %d МБ",

    -- GC Burst on heavy events
    ["GC burst: %s (step %d KB)"] = "Интенсивный GC: %s (шаг %d КБ)",

    -- PART C: SpeedyLoad
    ["SpeedyLoad: UnregisterEvent hook installed"] = "SpeedyLoad: перехватчик UnregisterEvent установлен",
    ["SpeedyLoad: PLAYER_ENTERING_WORLD priority set"] = "SpeedyLoad: приоритет для PLAYER_ENTERING_WORLD установлен",

    -- Loading state frame
    ["SpeedyLoad: suppressed %d registrations (%s)"] = "SpeedyLoad: подавлено %d регистраций (%s)",
    ["SpeedyLoad: restored %d registrations"] = "SpeedyLoad: восстановлено %d регистраций",
    ["SpeedyLoad: restored %d registrations (fallback)"] = "SpeedyLoad: восстановлено %d регистраций (резерв)",

    -- PART D: UI Thrashing Protection    
    -- PART E: GUI (Interface Options)
    -- Main panel
    ["Lua runtime optimizer + smart garbage collector for WoW 3.3.5a."] = "Оптимизатор среды выполнения Lua и умный сборщик мусора для WoW 3.3.5a.",
    [" | |cff00ff00DLL|r"] = " | |cff00ff00DLL|r",
    ["%s  |  Mem: %s%.1f MB|r  |  %s  |  %s%d|r KB/f%s"] = "%s  |  Память: %s%.1f МБ|r  |  %s  |  %s%d|r КБ/к%s",
    ["|cff00ff00ON|r"] = "|cff00ff00ВКЛ|r",
    ["|cffff0000OFF|r"] = "|cffff0000ВЫКЛ|r",
    ["Enable GC Manager"] = "Включить менеджер GC",
    ["Master toggle for smart GC."] = "Главный переключатель умного сборщика мусора.",
    ["GC Presets (Choose based on your combat memory):"] = "Пресеты GC (выбирайте в зависимости от расхода памяти в бою):",
    ["|cffff8844Light (< 150MB)|r"] = "|cffff8844Низкий (< 150 МБ)|r",
    ["|cffffff44Std (150-300MB)|r"] = "|cffffff44Стандартный (150-300 МБ)|r",
    ["|cff44ff44Heavy (> 300MB)|r"] = "|cff44ff44Высокий (> 300 МБ)|r",
    ["Runtime optimizations are always active."] = "Оптимизации рантайма активны всегда.",

    -- SpeedyLoad section
    ["Loading Screen Optimization"] = "Оптимизация экранов загрузки",
    ["Enable Fast Loading Screens"] = "Включить быструю загрузку",
    ["Temporarily suppresses noisy events during loading screens.\n"] = "Временно заглушает лишние события во время экрана загрузки.\n",
    ["Reduces CPU work and speeds up zone transitions.\n"] = "Снижает нагрузку на процессор и ускоряет смену локаций.\n",
    ["Restores all events after loading completes."] = "Восстанавливает регистрацию всех событий после завершения загрузки.",
--    ["Mode: %s (%d events)"] = "Режим: %s (%d событий)", -- Duplicate line 56
    ["|cff44ff44Safe|r"] = "|cff44ff44Безопасный|r",
    ["|cffff8844Aggressive|r"] = "|cffff8844Агрессивный|r",
    ["Mode: %s (%d events)"] = "Режим: %s (%d событий)",
    ["|cffff4444GetFramesRegisteredForEvent not available — SpeedyLoad disabled.|r"] = "|cffff4444GetFramesRegisteredForEvent недоступна — SpeedyLoad отключен.|r",

    -- UI Thrashing Protection section
    ["UI Optimization"] = "Оптимизация интерфейса",
    ["Enable UI Thrashing Protection"] = "Включить защиту интерфейса от перегрузки",
    ["Caches widget values and skips redundant engine calls.\n"] = "Кэширует значения виджетов и пропускает повторные вызовы движка.\n",
    ["Speeds up all addons that update UI every frame.\n"] = "Ускоряет работу аддонов, обновляющих интерфейс каждый кадр.\n",
    ["Hooks: SetValue, SetMinMaxValues, SetStatusBarColor.\n"] = "Хуки: SetValue, SetMinMaxValues, SetStatusBarColor.\n",
    ["StatusBar methods only — FontString hooks removed\n"] = "Только методы StatusBar — хуки FontString удалены\n",
    ["to prevent taint with Blizzard dropdown menus.\n"] = "во избежание ошибок taint в стандартных выпадающих списках.\n",
    ["|cff44ff44Safe — no taint, no gameplay impact.|r\n"] = "|cff44ff44Безопасно — нет taint-ошибок, не влияет на механику игры.|r\n",
    ["|cffff8844Requires /reload to take effect.|r"] = "|cffff8844Для применения требуется /reload.|r",
    ["ThrashGuard: |cff00ff00%d|r hooks | Skipped: |cffffff00%d|r | Passed: |cffffff00%d|r | Rate: |cff00ff00%.0f%%|r"] = "ThrashGuard: хуков: |cff00ff00%d|r | Пропущено: |cffffff00%d|r | Передано: |cffffff00%d|r | Эффективность: |cff00ff00%.0f%%|r",
    ["ThrashGuard: |cffaaaaaaInactive|r"] = "ThrashGuard: |cffaaaaaaНеактивен|r",

    -- GC Settings panel
    ["GC Settings"] = "Настройки GC",
    ["GC Settings|r"] = "Настройки GC|r",
    ["Step Sizes (KB collected per frame)"] = "Размер шага (КБ очистки за кадр)",
    ["Normal Step"] = "Обычный шаг",
    ["GC per frame during normal gameplay."] = "Объем очистки за кадр во время обычной игры.",
    ["Combat Step"] = "Шаг в бою",
    ["GC per frame in combat (keep low to protect frametime)."] = "Объем очистки за кадр в бою (держите низким для защиты фреймрейта).",
    ["Idle Step"] = "Шаг при простое",
    ["GC per frame while AFK/idle."] = "Объем очистки за кадр в режиме простоя/AFK.",
    ["Loading Step"] = "Шаг загрузки",
    ["GC per frame during loading screens (no rendering)."] = "Объем очистки за кадр во время загрузки (когда рендеринг отключен).",
    ["Thresholds"] = "Пороги срабатывания",
    ["Emergency Full GC (MB)"] = "Экстренный полный GC (МБ)",
    ["Force full GC outside combat when memory exceeds this.\n"] = "Принудительный полный сброс вне боя при превышении порога памяти.\n",
    ["Set higher (300-500+) if you use many addons to avoid long freezes."] = "Установите выше (300–500+), если много аддонов, чтобы избежать долгих фризов.",
    ["Idle Timeout (sec)"] = "Таймаут простоя (сек)",
    ["Seconds without activity before idle mode."] = "Секунды бездействия до перехода в режим простоя.",

    -- Tools panel
    ["Tools"] = "Инструменты",
    ["Tools & Diagnostics|r"] = "Инструменты и диагностика|r",
    ["Debug mode (GC info in chat)"] = "Режим отладки (инфо GC в чат)",
    ["Shows GC mode changes, SpeedyLoad activity, and emergency collections."] = "Выводит смену режимов GC, активность SpeedyLoad и экстренные очистки.",
    ["Intercept collectgarbage() calls"] = "Перехватывать вызовы collectgarbage()",
    ["Blocks full GC calls triggered by other addons.\n"] = "Блокирует принудительный полный GC, вызываемый сторонними аддонами.\n",
    ["|cffff4444WARNING:|r Causes taint with ElvUI and secure frames.\n"] = "|cffff4444ВНИМАНИЕ:|r Вызывает taint в ElvUI и защищенных фреймах (secure frames).\n",
    ["Leave OFF if you see 'action blocked' errors."] = "Оставьте ВЫКЛ, если появляются ошибки 'действие заблокировано'.",
    ["Block UpdateAddOnMemoryUsage()"] = "Блокировать UpdateAddOnMemoryUsage()",
    ["Blocks heavy addon memory scans.\n"] = "Блокирует ресурсоемкое сканирование памяти аддонов.\n",
    ["MemUsage Min Interval (sec)"] = "Мин. интервал MemUsage (сек)",
    ["Minimum interval between UpdateAddOnMemoryUsage() calls."] = "Минимальный интервал между вызовами UpdateAddOnMemoryUsage().",
    ["Force Full GC Now"] = "Очистить память сейчас",
    ["|cff44ff44Freed %.1f MB in %.1f ms|r"] = "|cff44ff44Освобождено %.1f МБ за %.1f мс|r",
    ["Reset All to Defaults"] = "Сбросить все настройки",
    ["Reset all LuaBoost settings to defaults?"] = "Сбросить все настройки LuaBoost по умолчанию?",
    ["Yes"] = "Да",
    ["No"] = "Нет",

    -- PART F: Slash Commands
    ["  GC: %s | Mode: %s | Mem: %.1f MB | Step: %d KB/f"] = "  GC: %s | Режим: %s | Память: %.1f МБ | Шаг: %d КБ/к",
    ["  Protection: interceptGC=%s, blockMemUsage=%s"] = "  Защита: interceptGC=%s, blockMemUsage=%s",
    ["  SpeedyLoad: %s (%s, %d events)"] = "  SpeedyLoad: %s (%s, событий: %d)",
    ["on"] = "вкл",
    ["off"] = "выкл",
    ["aggressive"] = "агрессивный",
    ["safe"] = "безопасный",
    ["  wow_optimize.dll: |cff00ff00CONNECTED|r"] = "  wow_optimize.dll: |cff00ff00ПОДКЛЮЧЕНО|r",
    ["  wow_optimize.dll: |cffaaaaaaNOT DETECTED|r"] = "  wow_optimize.dll: |cffaaaaaaНЕ ОБНАРУЖЕНО|r",
    ["  ThrashGuard: |cff00ff00ACTIVE|r (%d hooks, %.0f%% skip rate)"] = "  ThrashGuard: |cff00ff00АКТИВЕН|r (хуков: %d, пропуск: %.0f%%)",
    ["  ThrashGuard: |cffaaaaaaOFF|r"] = "  ThrashGuard: |cffaaaaaaВЫКЛ|r",
    ["/lb help|r"] = "/lb help|r",
    ["[LuaBoost]|r GC Stats:"] = "[LuaBoost]|r Статистика GC:",
    ["  Memory: %.0f KB (%.1f MB)"] = "  Память: %.0f КБ (%.1f МБ)",
    ["  Mode: %s | Step: %d KB/f"] = "  Режим: %s | Шаг: %d КБ/к",
    ["  Lua steps: %d | Emergency: %d | Full: %d"] = "  Шагов Lua: %d | Экстренных: %d | Полных: %d",
    ["  Loading: %s | Idle: %s | Combat: %s"] = "  Загрузка: %s | Простой: %s | Бой: %s",
    ["yes"] = "да",
    ["no"] = "нет",
    ["  DLL: mem=%.0fKB steps=%d full=%d mode=%s"] = "  DLL: память=%.0fКБ шагов=%d полных=%d режим=%s",
    ["?"] = "?",
    ["[LuaBoost]|r Pool: %d acquired, %d released, %d created, %d available"] = "[LuaBoost]|r Пул: получено: %d, освобождено: %d, создано: %d, доступно: %d",
    ["GC Manager: "] = "Менеджер GC: ",
    ["Freed %.1f MB"] = "Освобождено %.1f МБ",
    ["SpeedyLoad: %s (%s, %d events)"] = "SpeedyLoad: %s (%s, событий: %d)",
    ["SpeedyLoad: |cff00ff00ON|r (|cff44ff44safe|r, "] = "SpeedyLoad: |cff00ff00ВКЛ|r (|cff44ff44безопасный|r, ",
    [" events)"] = " событий)",
    ["SpeedyLoad: |cff00ff00ON|r (|cffff8844aggressive|r, "] = "SpeedyLoad: |cff00ff00ВКЛ|r (|cffff8844агрессивный|r, ",
    ["[LuaBoost]|r UI Thrashing Protection:"] = "[LuaBoost]|r Защита интерфейса (Thrashing Protection):",
    ["  Status: %s | Hooks: %d/3"] = "  Статус: %s | Хуков: %d/3",
    ["  Skipped: |cffffff00%d|r | Passed: |cffffff00%d|r"] = "  Пропущено: |cffffff00%d|r | Передано: |cffffff00%d|r",
    ["UI Thrashing Protection: |cffff0000OFF|r (hooks removed)"] = "Защита интерфейса: |cffff0000ВЫКЛ|r (хуки удалены)",
    ["UI Thrashing Protection: |cff00ff00ON|r (%d hooks)"] = "Защита интерфейса: |cff00ff00ВКЛ|r (%d хуков)",
    ["UI Thrashing Protection: |cffff0000FAILED|r — "] = "Защита интерфейса: |cffff0000ОШИБКА|r — ",
    
    ["[LuaBoost]|r Commands:"] = "[LuaBoost]|r Команды:",
    ["  /lb              — status"]                      = "  /lb              — статус",
    ["  /lb gc           — GC stats"]                    = "  /lb gc           — статистика GC",
    ["  /lb pool         — table pool stats"]            = "  /lb pool         — статистика пула таблиц",
    ["  /lb toggle       — enable/disable GC manager"]   = "  /lb toggle       — вкл/выкл менеджер GC",
    ["  /lb force        — force full GC now"]           = "  /lb force        — принудительный полный сброс памяти",
    ["  /lb sl           — toggle SpeedyLoad"]           = "  /lb sl           — переключить SpeedyLoad",
    ["  /lb sl safe      — SpeedyLoad safe mode"]        = "  /lb sl safe      — безопасный режим SpeedyLoad",
    ["  /lb sl agg       — SpeedyLoad aggressive mode"]  = "  /lb sl agg       — агрессивный режим SpeedyLoad",
    ["  /lb settings     — open GC settings"]            = "  /lb settings     — открыть настройки GC",
    ["  /lb tg           — UI thrash protection stats"]  = "  /lb tg           — статистика защиты интерфейса",
    ["  /lb tg toggle    — enable/disable thrash guard"] = "  /lb tg toggle    — вкл/выкл защиту интерфейса",
    ["  /lb tg reset     — reset thrash guard counters"] = "  /lb tg reset     — сбросить счетчики защиты",
    ["  /lb updates      — show registered update callbacks"] = "  /lb updates      — показать зарегистрированные функции обновления",
    ["  /lb events       — profile events for 10 seconds"] = "  /lb events       — профилирование событий (10 сек)",
    ["  /lb fps          — FPS monitor for 10 seconds"] = "  /lb fps          — мониторинг FPS (10 сек)",
    ["  /lb memleak      — addon memory leak scanner (30 sec)"] = "  /lb memleak      — поиск утечек памяти аддонов (30 сек)",

    -- PART G: Initialization
    ["GC: "] = "GC: ",
    ["GC:|cffff0000OFF|r"] = "GC:|cffff0000ВЫКЛ|r",
    ["[LuaBoost]|r |cffff8844WARNING:|r SmartGC detected. Disable SmartGC to avoid conflicts."] = "[LuaBoost]|r |cffff8844ВНИМАНИЕ:|r Обнаружен SmartGC. Отключите SmartGC во избежание конфликтов.",
}
