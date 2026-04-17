import Foundation

struct Word: Identifiable, Codable, Hashable {
    let id: String
    var text: String
    var category: WordCategory
    var language: String

    init(id: String = UUID().uuidString, text: String,
         category: WordCategory, language: String = "pt") {
        self.id = id
        self.text = text
        self.category = category
        self.language = language
    }
}

enum WordCategory: String, Codable, CaseIterable, Identifiable {
    case all         = "Todas"
    case celebrities = "Celebridades"
    case movies      = "Filmes & Séries"
    case animals     = "Animais"
    case sports      = "Esportes"
    case food        = "Comida"
    case countries   = "Países"
    case objects     = "Objetos"
    case characters  = "Personagens"

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .all:         return "🌐"
        case .celebrities: return "⭐"
        case .movies:      return "🎬"
        case .animals:     return "🦁"
        case .sports:      return "⚽"
        case .food:        return "🍕"
        case .countries:   return "🗺️"
        case .objects:     return "📦"
        case .characters:  return "🦸"
        }
    }
}
