-- LuaBoost Korean Localization  v1.9.1
-- Contributed by [nadugi]

LuaBoost_Locale_koKR = {
    -- PART A: Runtime Optimizations

    -- PART B: Smart GC Manager
    ["|cff888888[LuaBoost-DBG]|r "] = "|cff888888[LuaBoost-디버그]|r ",
    ["|cff4488ffloading|r"] = "|cff4488ff로딩|r",
    ["|cffff4444combat|r"] = "|cffff4444전투|r",
    ["|cff888888idle|r"] = "|cff888888대기|r",
    ["|cff44ff44normal|r"] = "|cff44ff44일반|r",
    -- GC core
    ["Idle mode activated"] = "대기 모드 활성화",
    -- Emergency full GC (not in combat, not loading)
    ["Emergency GC: freed %.1f MB in %.1f ms"] = "긴급 메모리 정리: %.1f MB 해제 완료 (%.1f ms 소요)",
    ["Raised threshold to %d MB"] = "정리 지연 발생으로 임계값을 %d MB로 상향 조정합니다.",

    -- GC Burst on heavy events
    ["GC burst: %s (step %d KB)"] = "GC 가속 발생: %s (단계별 %d KB)",

    -- PART C: SpeedyLoad
    ["SpeedyLoad: UnregisterEvent hook installed"] = "SpeedyLoad: 이벤트 차단 기능이 준비되었습니다.",
    ["SpeedyLoad: PLAYER_ENTERING_WORLD priority set"] = "SpeedyLoad: 지역 이동 최적화 우선순위가 설정되었습니다.",

    -- Loading state frame
    ["SpeedyLoad: suppressed %d registrations (%s)"] = "SpeedyLoad: %d개의 이벤트 등록 차단 (%s 모드)",
    ["SpeedyLoad: restored %d registrations"] = "SpeedyLoad: %d개의 이벤트 등록 복구 완료",
    ["SpeedyLoad: restored %d registrations (fallback)"] = "SpeedyLoad: %d개의 이벤트 등록 복구 (예외 복구)",

    -- PART D: UI Thrashing Protection    
    -- PART E: GUI (Interface Options)
    -- Main panel
    ["Lua runtime optimizer + smart garbage collector for WoW 3.3.5a."] = "WoW 3.3.5a를 위한 Lua 런타임 최적화 및 스마트 메모리 관리 도구",
    [" | |cff00ff00DLL|r"] = "| |cff00ff00DLL활성|r",
    ["%s  |  Mem: %s%.1f MB|r  |  %s  |  %s%d|r KB/f%s"] = "상태: %s|메모리:%s%.1f MB|r|모드:%s|정리:%s%d|r KB/f%s",
    ["|cff00ff00ON|r"] = "|cff00ff00활성|r",
    ["|cffff0000OFF|r"] = "|cffff0000중지|r",
    ["Enable GC Manager"] = "GC 관리자 활성화",
    ["Master toggle for smart GC."] = "스마트 가비지 컬렉션 기능을 켜거나 끕니다.",
    ["GC Presets (Choose based on your combat memory):"] = "GC 프리셋 (전투 시 메모리 사용량에 따라 선택):",
    ["|cffff8844Light (< 150MB)|r"] = "|cffff8844약(< 150M)|r",
    ["|cffffff44Std (150-300MB)|r"] = "|cffffff44중(150-300M)|r",
    ["|cff44ff44Heavy (> 300MB)|r"] = "|cff44ff44강(> 300M)|r",
    ["Runtime optimizations are always active."] = "런타임 최적화는 항상 활성화되어 있습니다.",

    -- SpeedyLoad section
    ["Loading Screen Optimization"] = "로딩 화면 최적화 (SpeedyLoad)",
    ["Enable Fast Loading Screens"] = "1. 빠른 로딩 화면 사용",
    ["Temporarily suppresses noisy events during loading screens.\n"] = "로딩 중 불필요한 이벤트를 일시 차단하여 CPU 부하를 줄이고\n",
    ["Reduces CPU work and speeds up zone transitions.\n"] = "지역 이동 속도를 향상시킵니다.\n",
    ["Restores all events after loading completes."] = "로딩이 끝나면 자동으로 복구됩니다.",
    ["|cff44ff44Safe|r"] = "|cff44ff44안전 모드|r",
    ["|cffff8844Aggressive|r"] = "|cffff8844공격 모드|r",
    ["Mode: %s (%d events)"] = "현재 모드: %s (이벤트: %d개)",
    ["|cffff4444GetFramesRegisteredForEvent not available — SpeedyLoad disabled.|r"] = "|cffff4444[경고] 함수 제한으로 SpeedyLoad가 비활성화되었습니다.|r",

    -- UI Thrashing Protection section
    ["UI Optimization"] = "UI 최적화",
    ["Enable UI Thrashing Protection"] = "UI 과부하 보호 활성화",
    ["Caches widget values and skips redundant engine calls.\n"] = "위젯 값을 캐시하여 불필요한 엔진 호출을 건너뜁니다.\n",
    ["Speeds up all addons that update UI every frame.\n"] = "매 프레임 UI를 갱신하는 모든 애드온의 속도를 높입니다.\n",
    ["Hooks: SetValue, SetMinMaxValues, SetStatusBarColor.\n"] = "상태 바 제어 항목: 수치 반영, 범위 설정, 바 색상 변경 기능 연결.\n",
    ["StatusBar methods only — FontString hooks removed\n"] = "상태 바의 수치 범위와 현재 값, 표시 색상을 설정합니다.\n",
    ["to prevent taint with Blizzard dropdown menus.\n"] = "기본 UI 메뉴의 오류 발생 방지 목적 조치.\n",
    ["|cff44ff44Safe — no taint, no gameplay impact.|r\n"] = "|cff44ff44안전함 — 테인드(Taint) 및 게임 플레이 영향 없음.|r\n",
    ["|cffff8844Requires /reload to take effect.|r"] = "|cffff8844변경 사항을 적용하려면 /reload가 필요합니다.|r",
    ["ThrashGuard: |cff00ff00%d|r/3 hooks | Skipped: |cffffff00%d|r | Passed: |cffffff00%d|r | Rate: |cff00ff00%.0f%%|r"] = "과부하 보호: |cff00ff00%d|r/3 연결 | 제외: |cffffff00%d|r | 통과: |cffffff00%d|r | 효율: |cff00ff00%.0f%%|r",
    ["ThrashGuard: |cffaaaaaaInactive|r"] = "과부하 보호: |cffaaaaaa비활성|r",


    -- GC Settings panel
    ["GC Settings"] = "상세 정리 설정",
    ["GC Settings|r"] = "상세 정리 설정|r",
    ["Step Sizes (KB collected per frame)"] = "단계별 정리량 (프레임당 KB)",
    ["Normal Step"] = "1. 일반 단계",
    ["GC per frame during normal gameplay."] = "평상시 게임 플레이 중 프레임당 정리량입니다.",
    ["Combat Step"] = "2. 전투 단계",
    ["GC per frame in combat (keep low to protect frametime)."] = "전투 중 프레임당 정리량입니다. (프레임 드랍 방지 권장)",
    ["Idle Step"] = "3. 대기 상태 단계",
    ["GC per frame while AFK/idle."] = "자리비움 또는 대기 상태일 때의 프레임당 정리량입니다.",
    ["Loading Step"] = "4. 로딩 중 단계",
    ["GC per frame during loading screens (no rendering)."] = "로딩 화면 중의 프레임당 정리량입니다.",
    ["Thresholds"] = "임계값 설정",
    ["Emergency Full GC (MB)"] = "5. 긴급 전체 정리 기준 (MB)",
    ["Force full GC outside combat when memory exceeds this.\n"] = "전투 중이 아닐 때 메모리가 이 수치를 초과하면 정리를 강제합니다.\n",
    ["Set higher (300-500+) if you use many addons to avoid long freezes."] = "애드온이 많다면 300-500 이상으로 설정을 권장합니다.",
    ["Idle Timeout (sec)"] = "6. 대기모드 전환시간(초)",
    ["Seconds without activity before idle mode."] = "아무 활동이 없을 때 대기 모드로 전환될 시간입니다.",

    -- Tools panel
    ["Tools"] = "도구 및 진단",
    ["Tools & Diagnostics|r"] = "도구 및 진단|r",
    ["Debug mode (GC info in chat)"] = "1. |cffffffff디버그 모드 (채팅창 알림)|r",
    ["Shows GC mode changes, SpeedyLoad activity, and emergency collections."] = "정리 모드 변경 및 긴급 정리 상황을 표시합니다.",
    ["Intercept collectgarbage() calls"] = "2. |cffffffff타 애드온의 GC 호출 차단|r",
    ["Blocks full GC calls triggered by other addons.\n"] = "다른 애드온의 강제 전체 정리 호출을 차단합니다.\n",
    ["|cffff4444WARNING:|r Causes taint with ElvUI and secure frames.\n"] = "|cffff4444주의:|r ElvUI 사용 시 '액션 차단' 오류가 발생할 수 있습니다.\n",
    ["Leave OFF if you see 'action blocked' errors."] = "오류 발생 시 이 기능을 끄세요.",
    ["Block UpdateAddOnMemoryUsage()"] = "3. |cffffffff메모리 사용량 갱신 차단|r",
    ["Blocks heavy addon memory scans.\n"] = "성능에 부하를 주는 메모리 스캔 작업을 차단합니다.\n",
    ["MemUsage Min Interval (sec)"] = "메모리 갱신 최소 간격 (초)",
    ["Minimum interval between UpdateAddOnMemoryUsage() calls."] = "메모리 스캔 사이의 최소 대기 시간입니다.",
    ["Force Full GC Now"] = "지금 전체 정리 실행",
    ["|cff44ff44Freed %.1f MB in %.1f ms|r"] = "|cff44ff44%.1f MB 해제 완료 (%.1f ms 소요)|r",
    ["Reset All to Defaults"] = "모든 설정 초기화",
    ["Reset all LuaBoost settings to defaults?"] = "모든 LuaBoost 설정을 기본값으로 초기화하시겠습니까?",
    ["Yes"] = "예",
    ["No"] = "아니오",

    -- PART F: Slash Commands
    ["  GC: %s | Mode: %s | Mem: %.1f MB | Step: %d KB/f"] = "  상태: %s | 모드: %s | 메모리: %.1f MB | 단계: %d KB/f",
    ["  Protection: interceptGC=%s, blockMemUsage=%s"] = "  보호 설정: GC 차단=%s, 메모리 갱신 차단=%s",
    ["  SpeedyLoad: %s (%s, %d events)"] = "  SpeedyLoad: %s (%s 모드, %d개 이벤트)",
    ["on"] = "사용",
    ["off"] = "미사용",
    ["aggressive"] = "공격적",
    ["safe"] = "안전",
    ["  wow_optimize.dll: |cff00ff00CONNECTED|r"] = "wow_optimize.dll: |cff00ff00감지|r",
    ["  wow_optimize.dll: |cffaaaaaaNOT DETECTED|r"] = "wow_optimize.dll: |cffaaaaaa미감지|r",
    ["  ThrashGuard: |cff00ff00ACTIVE|r (%d hooks, %.0f%% skip rate)"] = "  과부하 보호: |cff00ff00활성|r (%d개 연결, 차단율 %.0f%%)",
    ["  ThrashGuard: |cffaaaaaaOFF|r"] = "  과부하 보호(ThrashGuard): |cffaaaaaa중지|r",
    ["/lb help|r"] = "도움말은 /lb help|r를 입력하세요.",
    ["[LuaBoost]|r GC Stats:"] = "[LuaBoost]|r 가비지 컬렉션(GC) 통계:",
    ["  Memory: %.0f KB (%.1f MB)"] = "  현재 메모리: %.0f KB (%.1f MB)",
    ["  Mode: %s | Step: %d KB/f"] = "  현재 모드: %s | 단계별 정리량: %d KB/f",
    ["  Lua steps: %d | Emergency: %d | Full: %d"] = "  Lua 단계: %d | 긴급 정리: %d | 전체 정리: %d",
    ["  Loading: %s | Idle: %s | Combat: %s"] = "  로딩 중: %s | 대기: %s | 전투 중: %s",
    ["yes"] = "예",
    ["no"] = "아니오",
    ["  DLL: mem=%.0fKB steps=%d full=%d mode=%s"] = "  DLL 정보: 메모리=%.0fKB, 단계=%d, 전체정리=%d, 모드=%s",
    ["?"] = "알 수 없음",
    ["[LuaBoost]|r Pool: %d acquired, %d released, %d created, %d available"] = "[LuaBoost]|r 테이블 풀: 사용 %d, 반환 %d, 생성 %d, 가용 %d",
    ["GC Manager: "] = "GC 관리자 상태: ",
    ["Freed %.1f MB"] = "%.1f MB 해제됨",
    ["SpeedyLoad: %s (%s, %d events)"] = "SpeedyLoad: %s (%s 모드, %d개 이벤트)",
    ["SpeedyLoad: |cff00ff00ON|r (|cff44ff44safe|r, "] = "SpeedyLoad: |cff00ff00켜짐|r (|cff44ff44안전|r 모드, ",
    [" events)"] = "개 이벤트)",
    ["SpeedyLoad: |cff00ff00ON|r (|cffff8844aggressive|r, "] = "SpeedyLoad: |cff00ff00켜짐|r (|cffff8844공격적|r 모드, ",
    ["[LuaBoost]|r UI Thrashing Protection:"] = "[LuaBoost]|r UI 과부하 보호:",
    ["  Status: %s | Hooks: %d/3"] = "  상태: %s | 연결(Hooks): %d/3",
    ["  Skipped: |cffffff00%d|r | Passed: |cffffff00%d|r"] = "  차단: |cffffff00%d|r | 통과: |cffffff00%d|r",
    ["UI Thrashing Protection: |cffff0000OFF|r (hooks removed)"] = "UI 과부하 방지: |cffff0000비활성|r (연동 기능 삭제)",
    ["UI Thrashing Protection: |cff00ff00ON|r (%d hooks)"] = "UI 과부하 방지: |cff00ff00활성|r (%d개 항목 감시중)",
    ["UI Thrashing Protection: |cffff0000FAILED|r — "] = "UI 과부하 방지: |cffff0000실패|r — ",
    
    ["[LuaBoost]|r Commands:"] = "[LuaBoost]|r 명령어 도움말:",
    ["  /lb              — status"]                      = "  /lb           - 현재 상태 및 정보 표시",
    ["  /lb gc           — GC stats"]                    = "  /lb gc        - 상세 가비지 컬렉션 통계",
    ["  /lb pool         — table pool stats"]            = "  /lb pool      - 테이블 재사용 풀 상태",
    ["  /lb toggle       — enable/disable GC manager"]   = "  /lb toggle    - GC 관리자 기능 켜기/끄기",
    ["  /lb force        — force full GC now"]           = "  /lb force     - 수동으로 전체 메모리 정리",
    ["  /lb sl           — toggle SpeedyLoad"]           = "  /lb sl        - 로딩 가속(SpeedyLoad) 토글",
    ["  /lb sl safe      — SpeedyLoad safe mode"]        = "  /lb sl safe   - 로딩 가속: 안전 모드 설정",
    ["  /lb sl agg       — SpeedyLoad aggressive mode"]  = "  /lb sl agg    - 로딩 가속: 공격적 모드 설정",
    ["  /lb settings     — open GC settings"]            = "  /lb settings  - 상세 설정 창 열기",
    ["  /lb tg           — UI thrash protection stats"]  = "  /lb tg        - UI 과부하 보호 통계 확인",
    ["  /lb tg toggle    — enable/disable thrash guard"] = "  /lb tg toggle - UI 과부하 보호 기능 켜기/끄기",
    ["  /lb tg reset     — reset thrash guard counters"] = "  /lb tg reset  - UI 과부하 보호 통계 초기화",
    ["  /lb updates      — show registered update callbacks"]   = "  /lb updates   — 등록된 실시간 실행 작업 목록",
    ["  /lb events       — profile events for 10 seconds"]      = "  /lb events    — 10초간 게임 이벤트 발생 빈도 측정",
    ["  /lb fps          — FPS monitor for 10 seconds"] = "  /lb fps       - 10초간 프레임(FPS) 측정",
    ["  /lb memleak      — addon memory leak scanner (30 sec)"] = "  /lb memleak   - 30초간 애드온 메모리 누수(렉 유발) 점검",

    -- PART G: Initialization
    ["GC: "] = "정리: ",
    ["GC:|cffff0000OFF|r"] = "정리:|cffff0000OFF|r",
    ["[LuaBoost]|r |cffff8844WARNING:|r SmartGC detected. Disable SmartGC to avoid conflicts."] = "[LuaBoost]|r |cffff8844경고:|r SmartGC 애드온이 감지되었습니다. 충돌 방지를 위해 SmartGC를 비활성화하세요.",
}
