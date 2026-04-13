import Foundation
import NaturalLanguage
import SQLite

let dbPath = "phrases.sqlite3"
let languagesTable = Table("Languages")
let languageID = Expression<Int64>("LanguageID")
let languageName = Expression<String>("LanguageName")
let phrasesTable = Table("Phrases")
let phraseID = Expression<Int64>("PhraseID")
let phraseLanguageID = Expression<Int64>("LanguageID")
let phraseText = Expression<String>("Phrase")
let explanation = Expression<String>("Explanation")
let embedding = Expression<Blob>("Embedding")

func printErrorAndExit(_ message: String) -> Never {
    FileHandle.standardError.write((message + "\n").data(using: .utf8)!)
    exit(1)
}

func listLanguages() {
    do {
        let db = try Connection(dbPath)
        var result: [[String: Any]] = []
        for row in try db.prepare(languagesTable) {
            result.append(["id": row[languageID], "name": row[languageName]])
        }
        let json = try JSONSerialization.data(
            withJSONObject: result, options: [.prettyPrinted, .sortedKeys])
        print(String(data: json, encoding: .utf8)!)
    } catch {
        printErrorAndExit("資料庫錯誤: \(error)")
    }
}

func doubleArrayFromBlob(_ blob: Blob) -> [Double] {
    let count = blob.bytes.count / MemoryLayout<Double>.size
    return blob.bytes.withUnsafeBufferPointer { ptr in
        let base = ptr.baseAddress!.withMemoryRebound(to: Double.self, capacity: count) { $0 }
        return Array(UnsafeBufferPointer(start: base, count: count))
    }
}

func cosineSimilarity(_ a: [Double], _ b: [Double]) -> Double {
    guard a.count == b.count else { return -1 }
    let dot = zip(a, b).map(*).reduce(0, +)
    let normA = sqrt(a.map { $0 * $0 }.reduce(0, +))
    let normB = sqrt(b.map { $0 * $0 }.reduce(0, +))
    return dot / (normA * normB + 1e-10)
}

func query(languageIDValue: Int64, queryText: String) {
    // let supportedLanguages = NLEmbedding.supportedRevisions(for: .simplifiedChinese)
    // print(" \(supportedLanguages)")

    guard let model = NLEmbedding.wordEmbedding(for: .simplifiedChinese) else {
        printErrorAndExit("無法取得詞嵌入模型")
    }
    let converted =
        queryText.applyingTransform(StringTransform("Hant-Hans"), reverse: false) ?? queryText

    // 將查詢詞語進行斷詞
    let tokenizer = NLTokenizer(unit: .word)
    tokenizer.string = converted
    var tokens: [String] = []
    tokenizer.enumerateTokens(in: converted.startIndex..<converted.endIndex) { range, _ in
        let token = String(converted[range]).trimmingCharacters(in: .whitespacesAndNewlines)
        if !token.isEmpty {
            tokens.append(token)
        }
        return true
    }

    do {
        let db = try Connection(dbPath)
        let filtered = phrasesTable.filter(phraseLanguageID == languageIDValue)
        var result: [[String: Any]] = []
        for token in tokens {
            guard let tokenEmbedding = model.vector(for: token) else { continue }
            var candidates: [(phrase: String, explanation: String, similarity: Double)] = []
            for row in try db.prepare(filtered) {
                let emb = doubleArrayFromBlob(row[embedding])
                let sim = cosineSimilarity(tokenEmbedding, emb)
                candidates.append((row[phraseText], row[explanation], sim))
            }
            let filteredCandidates = candidates.filter { $0.similarity >= 0.8 }
            let top5 = filteredCandidates.sorted { $0.similarity > $1.similarity }.prefix(5)
            let phrases = top5.map {
                ["phrase": $0.phrase, "explanation": $0.explanation, "similarity": $0.similarity]
            }
            result.append(["token": token, "phrases": phrases])
        }
        let json = try JSONSerialization.data(
            withJSONObject: result, options: [.prettyPrinted, .sortedKeys])
        print(String(data: json, encoding: .utf8)!)
    } catch {
        printErrorAndExit("資料庫錯誤: \(error)")
    }
}

// MARK: - Main
let args = Array(CommandLine.arguments.dropFirst(1))
if args.count == 0 || (args.count == 1 && args[0] == "--list") {
    listLanguages()
} else if args.count == 2 {
    guard let langID = Int64(args[0]) else {
        printErrorAndExit("語言代號必須是整數。用法：tool <語言代號> <中文詞語> 或 tool --list")
    }
    query(languageIDValue: langID, queryText: args[1])
} else {
    printErrorAndExit("參數錯誤。用法：tool <語言代號> <中文詞語> 或 tool --list")
}
