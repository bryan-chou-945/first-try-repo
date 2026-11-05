; =====================================================================
;  LINE 防傳錯小幫手（Windows 電腦版 LINE 專用）
;  需要安裝 AutoHotkey v2：https://www.autohotkey.com/
;
;  功能：
;   1. 切換到不同聊天室時，左上角會短暫顯示「目前聊天室：XXX」
;   2. 剛切換聊天室後的第一次傳送，或太久沒傳訊息時，會跳出確認視窗
;      → 按 Y 才會送出，按 N 或 Enter 會取消（避免習慣性連按 Enter）
;   3. 名稱含有「需特別確認」關鍵字的聊天室，每一則訊息都要確認
;   4. Ctrl + Alt + L：暫停 / 恢復本程式
;   5. Shift + Enter 換行不受影響
; =====================================================================
#Requires AutoHotkey v2.0
#SingleInstance Force

; ========================== 設定區（可自行修改） ==========================

; 在同一個聊天室連續聊天時，幾秒內不再重複確認
SAFE_SECONDS := 120

; 聊天室名稱只要包含這些字，每一則訊息都會要求確認
ALWAYS_CONFIRM := ["公司", "老闆", "主管", "客戶", "工作"]

; LINE 電腦版的程式名稱（一般不需要改）
LINE_EXE := "LINE.exe"

; =========================================================================

global paused := false
global lastChat := ""
global lastSendTick := 0
global shownChat := ""

A_IconTip := "LINE 防傳錯小幫手"
TrayTip "已啟動，按 Ctrl+Alt+L 可暫停", "LINE 防傳錯小幫手"
SetTimer WatchChat, 500

; 暫停 / 恢復
^!l:: {
    global paused
    paused := !paused
    TrayTip paused ? "已暫停（Enter 恢復一般行為）" : "已恢復保護", "LINE 防傳錯小幫手"
}

#HotIf !paused && WinActive("ahk_exe " LINE_EXE)
$Enter:: HandleEnter("{Enter}")
$NumpadEnter:: HandleEnter("{NumpadEnter}")
#HotIf

; 按下 Enter 時：判斷要不要確認，再決定是否送出
HandleEnter(key) {
    global lastChat, lastSendTick
    hwnd := WinExist("A")
    chat := WinGetTitle(hwnd)

    if NeedsConfirm(chat) {
        shown := IsUnknown(chat)
            ? "（無法從視窗標題辨識，請看 LINE 畫面上的聊天室名稱）"
            : chat
        ; 0x4 = 是/否, 0x30 = 驚嘆號圖示, 0x100 = 預設選「否」, 0x40000 = 置頂
        answer := MsgBox(
            "確定要傳送到這個聊天室嗎？`n`n👉  " shown "`n`n按 Y 傳送，按 N 或 Enter 取消",
            "LINE 防傳錯確認",
            0x4 | 0x30 | 0x100 | 0x40000)
        WinActivate hwnd
        if answer != "Yes"
            return
        WinWaitActive hwnd, , 1
    }

    Send key
    lastChat := chat
    lastSendTick := A_TickCount
}

NeedsConfirm(chat) {
    global ALWAYS_CONFIRM, SAFE_SECONDS, lastChat, lastSendTick
    for kw in ALWAYS_CONFIRM
        if kw != "" && InStr(chat, kw)
            return true
    if chat != lastChat
        return true          ; 剛換聊天室
    if A_TickCount - lastSendTick > SAFE_SECONDS * 1000
        return true          ; 太久沒傳訊息
    return false
}

IsUnknown(chat) => (chat = "" || chat = "LINE")

; 切換聊天室時，在視窗左上角提示目前的聊天室
WatchChat() {
    global shownChat, LINE_EXE
    if !WinActive("ahk_exe " LINE_EXE)
        return
    chat := WinGetTitle("A")
    if chat = shownChat
        return
    shownChat := chat
    if IsUnknown(chat)
        return
    ToolTip "目前聊天室：" chat, 20, 20
    SetTimer () => ToolTip(), -2500
}
