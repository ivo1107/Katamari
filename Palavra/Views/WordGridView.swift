import SwiftUI

struct WordGridView: View {
    @EnvironmentObject var vm: GameViewModel

    var body: some View {
        VStack(spacing: 5) {
            ForEach(0..<6, id: \.self) { row in
                HStack(spacing: 5) {
                    ForEach(0..<5, id: \.self) { col in
                        LetterCellView(
                            letter:       vm.gameState.rows[row].letters[col],
                            isCurrentRow: row == vm.gameState.currentRow,
                            isShaking:    vm.isShaking
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Célula individual
struct LetterCellView: View {
    let letter: Letter
    let isCurrentRow: Bool
    let isShaking: Bool

    @State private var shakeOffset: CGFloat = 0
    @State private var bounceScale: CGFloat = 1.0
    @State private var flipAngle: Double = 0

    var body: some View {
        ZStack {
            // Fundo
            RoundedRectangle(cornerRadius: 3)
                .fill(letter.state.tileBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(letter.state.tileBorder, lineWidth: 2)
                )

            // Letra
            if !letter.isEmpty {
                Text(String(letter.character))
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .scaleEffect(bounceScale)
            }
        }
        .frame(width: 58, height: 58)
        .rotation3DEffect(.degrees(flipAngle), axis: (x: 1, y: 0, z: 0))
        .offset(x: shakeOffset)
        // Bounce ao digitar
        .onChange(of: letter.character) { char in
            guard char != " " else { return }
            withAnimation(.spring(response: 0.1, dampingFraction: 0.4)) { bounceScale = 1.15 }
            withAnimation(.spring(response: 0.1, dampingFraction: 0.4).delay(0.1)) { bounceScale = 1.0 }
        }
        // Flip ao revelar
        .onChange(of: letter.state) { state in
            guard state != .empty, state != .filled else { return }
            withAnimation(.easeInOut(duration: 0.35)) { flipAngle = 90 }
            withAnimation(.easeInOut(duration: 0.35).delay(0.35)) { flipAngle = 0 }
        }
        // Shake em palavra inválida
        .onChange(of: isShaking) { shaking in
            guard isCurrentRow, shaking else { return }
            withAnimation(.easeInOut(duration: 0.07).repeatCount(5, autoreverses: true)) {
                shakeOffset = 8
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { shakeOffset = 0 }
        }
    }
}
