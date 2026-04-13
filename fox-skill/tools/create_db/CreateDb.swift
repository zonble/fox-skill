import Foundation
import NaturalLanguage
import SQLite

// MARK: - Constants
let sourceDirectory = "../source"
let dbPath = "../query/phrases.sqlite3"

// MARK: - Database Table Definitions
let languagesTable = Table("Languages")
let languageID = Expression<Int64>("LanguageID")
let languageName = Expression<String>("LanguageName")

let phrasesTable = Table("Phrases")
let phraseID = Expression<Int64>("PhraseID")
let phraseLanguageID = Expression<Int64>("LanguageID")
let phraseText = Expression<String>("Phrase")
let explanation = Expression<String>("Explanation")
let embedding = Expression<Blob>("Embedding")

// MARK: - Helper Functions
func getAllJSONFiles(in directory: String) -> [URL] {
    let fm = FileManager.default
    let dirURL = URL(fileURLWithPath: directory, isDirectory: true)
    guard let files = try? fm.contentsOfDirectory(at: dirURL, includingPropertiesForKeys: nil)
    else { return [] }
    return files.filter { $0.pathExtension == "json" }
}

func loadJSON(from url: URL) -> (String, [[String]])? {
    guard let data = try? Data(contentsOf: url) else { return nil }
    guard let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
        return nil
    }
    guard let name = obj["name"] as? String, let dataArr = obj["data"] as? [[Any]] else {
        return nil
    }
    let phrases = dataArr.compactMap { arr in
        if arr.count >= 2, let phrase = arr[0] as? String, let explanation = arr[1] as? String {
            return [phrase, explanation]
        }
        return nil
    }
    return (name, phrases)
}

func computeEmbedding(for text: String) -> [Double]? {
    guard let embedding = NLEmbedding.wordEmbedding(for: .simplifiedChinese) else { return nil }
    return embedding.vector(for: text)
}

func doubleArrayToBlob(_ array: [Double]) -> Blob {
    var arr = array
    let data = Data(bytes: &arr, count: arr.count * MemoryLayout<Double>.size)
    return Blob(bytes: [UInt8](data))
}

// MARK: - Main

do {
    let db = try Connection(dbPath)
    // Create tables
    try db.run(
        languagesTable.create(ifNotExists: true) { t in
            t.column(languageID, primaryKey: .autoincrement)
            t.column(languageName)
        })
    try db.run(
        phrasesTable.create(ifNotExists: true) { t in
            t.column(phraseID, primaryKey: .autoincrement)
            t.column(phraseLanguageID)
            t.column(phraseText)
            t.column(explanation)
            t.column(embedding)
        })
    // 建立索引
    try db.run(languagesTable.createIndex(languageName, unique: false, ifNotExists: true))
    try db.run(phrasesTable.createIndex(phraseLanguageID, unique: false, ifNotExists: true))

    let jsonFiles = getAllJSONFiles(in: sourceDirectory)
    var langIDMap: [String: Int64] = [:]
    var nextLangID: Int64 = 0
    for file in jsonFiles {
        guard let (langName, phrases) = loadJSON(from: file) else { continue }
        let insert = languagesTable.insert(languageName <- langName)
        let rowid = try db.run(insert)
        langIDMap[langName] = rowid
        for pair in phrases {
            let phrase = pair[0]
            let expl = pair[1]
            // Note: NLUEmbedding Supports only Simplified Chinese, so we
            // convert Traditional to Simplified before embedding
            let converted = expl.applyingTransform(StringTransform("Hant-Hans"), reverse: false)
            let emb = computeEmbedding(for: converted ?? expl) ?? []
            let embBlob = doubleArrayToBlob(emb)
            try db.run(
                phrasesTable.insert(
                    phraseLanguageID <- rowid,
                    phraseText <- phrase,
                    explanation <- expl,
                    embedding <- embBlob
                ))
        }
        nextLangID += 1
    }
    print("Database created at \(dbPath)")
} catch {
    print("Error: \(error)")
}
