import SwiftUI

struct KeyboardView: View {
    @EnvironmentObject var vm: GameViewModel

    private let rows: [[String]] = [
        ["Q","W","E","R","T","Y","U","I","O","P"],
        ["A","S","D","F","G","H","J","K","L"],
        ["ENTER","Z","X","C","V","B","N","M","⌫"]
    ]

    var body: some View {
        VStack(spacing: 8) {
            ForEach(rows, id: \.self) { row in
                HStack(spacing: 5) {
                    ForEach(row, id: \.self) { key in
                        KeyCell(key: key)
                    }
                }
            }
        }
        .padding(.horizontal, 6)
    }
}

// MARK: - Tecla
struct KeyCell: View {
    @EnvironmentObject var vm: GameViewModel
    let key: String

    private var isSpecial: Bool { key == "ENTER" || key == "⌫" }

    private var width: CGFloat {
        key == "ENTER" ? 52 : (key == "⌫" ? 44 : 34)
    }

    private var background: Color {
        if isSpecial { return Color(hex: "818384") }
        let state = vm.usedLetters[Character(key)] ?? .empty
        return state.keyBackground
    }

    var body: some View {
        Button(action: handleTap) {
            ZStack {
                RoundedRectangle(cornerRadius: 5)
                    .fill(background)
                    .frame(width: width, height: 56)

                if key == "⌫" {
                    Image(systemName: "delete.left.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                } else {
                    Text(key)
                        .font(.system(size: key == "ENTER" ? 11 : 16, weight: .bold))
                        .foregroundColor(.white)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func handleTap() {
        if key == "ENTER" {
            vm.submitGuess()
        } else if key == "⌫" {
            vm.removeLetter()
        } else if let char = key.first {
            vm.addLetter(char)
        }
    }
}
