import SwiftUI

enum LetterState: Equatable {
    case empty
    case filled
    case correct   // Verde — letra certa, posição certa
    case present   // Amarelo — letra certa, posição errada
    case absent    // Cinza — letra não está na palavra

    var tileBackground: Color {
        switch self {
        case .empty:   return .clear
        case .filled:  return .clear
        case .correct: return Color(hex: "538D4E")
        case .present: return Color(hex: "B59F3B")
        case .absent:  return Color(hex: "3A3A3C")
        }
    }

    var tileBorder: Color {
        switch self {
        case .empty:  return Color(hex: "3A3A3C")
        case .filled: return Color(hex: "565758")
        default:      return .clear
        }
    }

    var keyBackground: Color {
        switch self {
        case .empty, .filled: return Color(hex: "818384")
        case .correct:        return Color(hex: "538D4E")
        case .present:        return Color(hex: "B59F3B")
        case .absent:         return Color(hex: "3A3A3C")
        }
    }
}

struct Letter: Identifiable, Equatable {
    let id = UUID()
    var character: Character = " "
    var state: LetterState = .empty

    var isEmpty: Bool { character == " " }
}

extension Color {
    init(hex: String) {
        var hex = hex
        if hex.hasPrefix("#") { hex.removeFirst() }
        var rgb: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&rgb)
        self.init(
            red:   Double((rgb >> 16) & 0xFF) / 255.0,
            green: Double((rgb >>  8) & 0xFF) / 255.0,
            blue:  Double( rgb        & 0xFF) / 255.0
        )
    }
}
