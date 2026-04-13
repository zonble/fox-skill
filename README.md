# 台灣南島語系 fox-skill

這個專案提供一個可被 AI 助手載入的 Skill，目標是協助查詢台灣南島語系詞彙，並把中文句子轉寫成指定語言的句子。

## 這個 Skill 做什麼

- 讓 AI 透過本地資料庫查詢「中文詞彙 -> 台灣南島語系詞彙」對應。
- 支援先列出可用語言，再指定語言 ID 進行查詢。
- 回傳包含斷詞結果與候選詞彙的 JSON，方便 AI 組句與解釋。

主要 Skill 定義在 fox-skill/SKILL.md。

## 系統限制

本專案目前以 macOS 為主要目標環境。

- 作業系統: macOS 13 或以上
- 開發工具: Xcode 14 或以上 (需包含 Swift toolchain)
- 語言與框架: - Swift 5.7+ - Foundation - NaturalLanguage (僅 Apple 平台可用)
- 資料庫: SQLite (透過 SQLite.swift 套件)

說明:

- 建庫與查詢工具都使用 Swift Package Manager 執行。
- 由於依賴 NaturalLanguage，非 macOS 環境通常無法直接執行。

## 安裝流程

以下流程在專案根目錄執行。

1. 先用 Swift 建立 SQLite 資料庫

進入建庫工具資料夾並執行:

    cd fox-skill/tools/create_db
    swift run CreateDbTool

2. 建立 Skill 連結

回到專案根目錄後執行:

    cd <你的專案路徑>/fox-skill
    ./link-skills.sh

這個腳本會把本專案中的 Skill 目錄連結到以下位置:

- ~/.codex/skills
- ~/.claude/skills
- ~/.gemini/skills

## 驗證安裝

可用查詢工具做基本驗證:

    cd fox-skill/tools/query
    swift run QueryTool

若成功列出語言 ID，表示工具可用。

也可直接測試查詢:

    swift run QueryTool 37 "我想吃飯"

## 專案結構

- fox-skill/SKILL.md: Skill 定義
- fox-skill/tools/create_db: 建立資料庫工具
- fox-skill/tools/query: 查詢資料庫工具
- link-skills.sh: 在本機建立 Skill 符號連結
