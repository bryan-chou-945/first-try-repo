# 排程發送 LINE 訊息

用 GitHub Actions 定時呼叫 LINE Messaging API 推播訊息。

## 設定步驟

1. **建立 LINE 官方帳號 + Messaging API channel**
   到 [LINE Developers Console](https://developers.line.biz/console/) → 建立 Provider → 建立 Messaging API channel。
2. **取得 Channel access token**
   channel 的「Messaging API」分頁最下方 → Channel access token (long-lived) → Issue。
3. **取得收件者 ID**
   - 傳給自己：「Basic settings」分頁的 **Your user ID**（U 開頭）。
   - 傳給別人／群組：對方要先加這個官方帳號好友（或把帳號邀進群組），再透過 webhook 取得 userId / groupId。
   - 記得先用手機加你的官方帳號為好友，否則收不到。
4. **在 GitHub 設定 Secrets**
   repo → Settings → Secrets and variables → Actions → New repository secret：
   - `LINE_CHANNEL_ACCESS_TOKEN`
   - `LINE_TO`（多個收件者用逗號分隔）
5. **測試**：Actions → Scheduled LINE message → Run workflow。

## 自訂

- **訊息內容**：編輯 `messages.txt`，可用 `{date}`、`{time}`、`{weekday}`。
- **時間**：編輯 `.github/workflows/line-schedule.yml` 的 `cron`（UTC 時間，台灣時間減 8 小時）。
  - 每天 08:00 → `0 0 * * *`
  - 平日 21:30 → `30 13 * * 1-5`
  - 每週一 09:00 → `0 1 * * 1`

## 注意

- GitHub 排程可能延遲 5–30 分鐘，不保證準時到秒。
- 公開 repo 60 天沒有 commit，排程會被自動停用。
- LINE 免費方案每月推播額度有限（約 200 則），超過需升級。
