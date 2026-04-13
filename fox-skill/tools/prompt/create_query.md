# Create Query

你現在要寫一個 Swift script。

這個 script 會兩種用法：

- 標準用法
- 查詢語言列表

## 標準用法

接受兩個參數，一個是語言代號，一個是中文詞語。比方說

```bash
tool 0 "不客氣"
```

這個 script 就會從剛剛建立的 sqlite 資料庫中，找到語言代號為 0 的資料庫，然後在 Phrases 資料庫中，找到與「不客氣」在 embedding 分數上最接近的五組詞語，並且回傳這些詞語。回傳格式為 JSON。例如

```json
[
  { "phrase": "Aka kangudu", "explanation": "不客氣" },
  { "phrase": "Aka kangudu", "explanation": "不客氣" },
  { "phrase": "Aka kangudu", "explanation": "不客氣" },
  { "phrase": "Aka kangudu", "explanation": "不客氣" },
  { "phrase": "Aka kangudu", "explanation": "不客氣" }
]
```

如果找不到就會回傳空 array。

參數不正確會在 std error 顯示錯誤訊息。

## 查詢語言列表

如果什麼參數都不加，或者加上 `--list` 參數，就會回傳目前資料庫中有哪些語言。回傳格式為 JSON。例如

```json
[
  { "id": 0, "name": "南勢阿美語" },
  { "id": 1, "name": "南勢阿美語" },
  { "id": 2, "name": "南勢阿美語" }
]
```
