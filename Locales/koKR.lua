-- MzxRiding 한국어 / Korean

local ADDON, ns = ...
local L = ns.L

ns.localeData = ns.localeData or {}

local t = {
	["MzxRiding Settings"] = "MzxRiding 설정",
	["Enable this module"] = "이 모듈 사용",
	["Module %s error: %s"] = "모듈 %s 오류: %s",
	["Module %s options error: %s"] = "모듈 %s 설정 오류: %s",
	["Skyriding action bar fix · Mount buttons"] = "하늘비행 단축바 고정 · 탈것 버튼",
	["Drag to move the button"] = "드래그하여 버튼 이동",
	["Commands:"] = "명령어:",
	["Open settings"] = "설정 열기",
	["  /mzxr                Open settings"] = "  /mzxr                설정 열기",
	["  /mzxr list           List modules and their state"] = "  /mzxr list           모듈 및 상태 목록",
	["  /mzxr on <module>    Enable a module"] = "  /mzxr on <모듈>        모듈 켜기",
	["  /mzxr off <module>   Disable a module"] = "  /mzxr off <모듈>       모듈 끄기",
	["  Modules: %s"] = "  모듈: %s",
	["%s (%s): %s"] = "%s(%s): %s",
	["on"] = "켜짐",
	["off"] = "꺼짐",
	["%s is now %s"] = "%s %s",
	["enabled"] = "켜짐",
	["disabled"] = "꺼짐",
	["Unknown module: %s"] = "알 수 없는 모듈: %s",
	["Unknown command. Type /mzxr help"] = "알 수 없는 명령어입니다. /mzxr help 를 입력하세요",
	["Skyriding"] = "하늘비행 단축바",
	["Cannot modify action bars in combat. Try again after combat."] = "전투 중에는 단축바를 수정할 수 없습니다. 전투가 끝난 후 다시 시도하세요.",
	["Already matches the configuration; no changes needed."] = "이미 설정과 일치합니다. 변경할 필요가 없습니다.",
	["Placed %d spells into slots %d-%d."] = "%d개의 기술을 %d-%d 슬롯에 배치했습니다.",
	["Not learned (skipped): %s"] = "습득하지 못함(건너뜀): %s",
	["Use Up/Down to reorder · number = action slot"] = "위/아래로 순서 변경 · 숫자 = 기술 칸",
	["Apply Now"] = "지금 적용",
	["Restore Defaults"] = "기본값 복원",
	["Mounts"] = "탈것",
	["Mail"] = "우편",
	["Repair"] = "수리",
	["Transmog"] = "형상변환",
	["Auction House"] = "경매장",
	["Vendor"] = "잡화",
	["Cannot summon mounts in combat"] = "전투 중에는 탈것을 소환할 수 없습니다",
	["Summon failed"] = "소환 실패",
	["Mount #%d"] = "탈것 #%d",
	["You do not own this mount, cannot set as primary: %s"] = "이 탈것을 보유하고 있지 않아 주 탈것으로 설정할 수 없습니다: %s",
	["This mount is restricted to %s characters: %s"] = "이 탈것은 %s 캐릭터만 사용할 수 있습니다: %s",
	["Alliance"] = "얼라이언스",
	["Horde"] = "호드",
	["This mount is not usable on your current character: %s"] = "현재 캐릭터는 이 탈것을 사용할 수 없습니다: %s",
	["Primary functional mount set to: %s"] = "주 기능 탈것을 설정했습니다: %s",
	["Random Duo Mount"] = "무작위 2인용 탈것",
	["Random Flying Mount"] = "무작위 비행 탈것",
	["%s: You have not selected any mounts. Please choose in settings."] = "%s: 선택된 탈것이 없습니다. 설정에서 선택하세요.",
	["Randomly summoned: %s"] = "무작위 소환: %s",
	["%s: %s"] = "%s: %s",
	["You do not own any listed functional mounts."] = "목록에 있는 기능성 탈것을 보유하고 있지 않습니다.",
	["Summoned: %s"] = "소환: %s",
	["Drag: move the whole button group"] = "드래그: 버튼 그룹 전체 이동",
	["Functional Mount: %s"] = "기능 탈것: %s",
	["Functional Mount"] = "기능 탈것",
	["No listed functional mounts owned"] = "보유한 기능성 탈것 없음",
	["%d flying mounts selected"] = "비행 탈것 %d개 선택됨",
	["%d mounts selected"] = "탈것 %d개 선택됨",
	["Next summon: %s"] = "다음 소환: %s",
	["Last: %s"] = "지난번: %s",
	["Please select passenger mounts in settings first"] = "먼저 설정에서 2인용 탈것을 선택하세요",
	["Click: select · Right-click: summon (%d)"] = "클릭: 선택 · 우클릭: 소환 (%d)",
	["Select All"] = "모두 선택",
	["Deselect All"] = "모두 해제",
	["Summon Random"] = "무작위 소환",
	["Click: set primary · Right-click: summon"] = "클릭: 주 선택 · 우클릭: 소환",
	["Show floating button group"] = "떠 있는 버튼 그룹 표시",
	["Summon Primary Mount"] = "주 탈것 소환",
	["Primary"] = "주 탈것",
	["Functional"] = "기능",
	["Random Flying"] = "무작위 비행",
	["Random Duo"] = "무작위 2인용",
	["Language"] = "언어",
	["Client default"] = "클라이언트 기본값",
}

ns.localeData["koKR"] = t

-- 客户端语言即为本语言时，加载期立即套用（核心在 ADDON_LOADED 也会重跑一次，幂等）。
if GetLocale() == "koKR" then
	for k, v in pairs(t) do
		L[k] = v
	end
end
