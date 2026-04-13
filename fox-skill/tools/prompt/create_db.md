## Create DB Tool

你現在要寫一個 Swift script。

在這個目錄下的 source 目錄中，有一些 JSON 檔案。裡頭的格式是；

```json
// TW_00.json
{"name":"南勢阿美語","data":[["Aka kangudu","不客氣"]]{}
```

你的 Swift script，就是要將這些資料，透過蘋果的 FFoundation Models，根據其中的中文解釋，算好 Embedding 分數，整理成一個 sqlite 檔案。這個檔案中有兩個資料庫。

## Lnaguages 資料庫

- Language ID (Integer, Primary Key), 例如 0 是南勢阿美語
- Language Name (Text)，例如「南勢阿美語」

## Phrases 資料庫

- Phrase ID (Integer, Primary Key)
- Language ID (Integer, Foreign Key)
- Phrase (Text)
- Explanation (Text)
- Embedding (BLOB)

## Swift 套件

你可以使用以下 Swif 套件來完成這個任務：

- SQLite.swift：用於操作 SQLite 資料庫。
- Foundation：用於處理 JSON 和其他基本功能。
- FoundationModels：用於計算 Embedding 分數。

您可以使用 NLEmbedding 的 wordEmbeddingForLanguage: 方法來計算 Embedding 分數。

在這兩個表格上再加上 index。
