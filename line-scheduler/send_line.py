"""透過 LINE Messaging API 推播訊息（只用 Python 標準函式庫）。

需要的環境變數：
  LINE_CHANNEL_ACCESS_TOKEN  Messaging API 的 Channel access token（long-lived）
  LINE_TO                    收件者 ID（userId 以 U 開頭、groupId 以 C 開頭）；
                             多個收件者用逗號分隔
  LINE_MESSAGE               （選填）訊息內容；沒填就讀 messages.txt
"""
import json
import os
import pathlib
import sys
import urllib.error
import urllib.request
from datetime import datetime, timedelta, timezone

PUSH_URL = "https://api.line.me/v2/bot/message/push"
TW = timezone(timedelta(hours=8))


def load_message() -> str:
    msg = os.environ.get("LINE_MESSAGE", "").strip()
    if not msg:
        path = pathlib.Path(__file__).with_name("messages.txt")
        msg = path.read_text(encoding="utf-8").strip()
    # 支援 {date} {time} {weekday} 佔位符（台灣時間）
    now = datetime.now(TW)
    weekday = "一二三四五六日"[now.weekday()]
    return msg.format(date=now.strftime("%Y/%m/%d"), time=now.strftime("%H:%M"), weekday=weekday)


def push(token: str, to: str, text: str) -> None:
    body = json.dumps({"to": to, "messages": [{"type": "text", "text": text[:5000]}]}).encode()
    req = urllib.request.Request(
        PUSH_URL,
        data=body,
        headers={"Content-Type": "application/json", "Authorization": f"Bearer {token}"},
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=30) as resp:
        print(f"Sent to {to[:5]}…: HTTP {resp.status}")


def main() -> int:
    token = os.environ.get("LINE_CHANNEL_ACCESS_TOKEN", "").strip()
    recipients = [r.strip() for r in os.environ.get("LINE_TO", "").split(",") if r.strip()]
    if not token or not recipients:
        print("缺少 LINE_CHANNEL_ACCESS_TOKEN 或 LINE_TO", file=sys.stderr)
        return 1
    text = load_message()
    failed = False
    for to in recipients:
        try:
            push(token, to, text)
        except urllib.error.HTTPError as e:
            print(f"發送給 {to[:5]}… 失敗：HTTP {e.code} {e.read().decode(errors='replace')}", file=sys.stderr)
            failed = True
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
