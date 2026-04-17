import Foundation

final class WordService {
    static let shared = WordService()
    private var words: [Word] = []
    private init() { loadWords() }

    private func loadWords() {
        guard let url  = Bundle.main.url(forResource: "Words", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([Word].self, from: data) else { return }
        words = decoded
    }

    func randomWords(count: Int, category: WordCategory) -> [Word] {
        let pool: [Word]
        if category == .all {
            pool = words
        } else {
            pool = words.filter { $0.category == category }
        }
        return Array(pool.shuffled().prefix(count))
    }

    func randomWord(excluding used: [String], category: WordCategory) -> Word? {
        let pool: [Word]
        if category == .all {
            pool = words
        } else {
            pool = words.filter { $0.category == category }
        }
        return pool.filter { !used.contains($0.text.lowercased()) }.randomElement()
    }

    func allCategories() -> [WordCategory] { WordCategory.allCases }
}
