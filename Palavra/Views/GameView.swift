import SwiftUI

struct GameView: View {
    @EnvironmentObject var vm: GameViewModel

    var body: some View {
        ZStack(alignment: .top) {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // ── Header ──────────────────────────────────────
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("PALAVRA")
                            .font(.system(size: 26, weight: .black))
                            .foregroundColor(.white)
                            .tracking(5)
                        Text("palavra do dia")
                            .font(.caption2)
                            .foregroundColor(Color(hex: "818384"))
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(vm.score)")
                            .font(.title2.bold())
                            .foregroundColor(Color(hex: "538D4E"))
                        Text("pontos")
                            .font(.caption2)
                            .foregroundColor(Color(hex: "818384"))
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 10)

                Divider().background(Color(hex: "3A3A3C"))

                Spacer(minLength: 16)

                // ── Grade ────────────────────────────────────────
                WordGridView()
                    .padding(.horizontal, 24)

                Spacer()

                // ── Teclado ──────────────────────────────────────
                KeyboardView()
                    .padding(.bottom, 12)
            }

            // ── Banner de mensagem ────────────────────────────────
            if vm.showMessage {
                Text(vm.message)
                    .font(.footnote.bold())
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(Color.white)
                    .foregroundColor(.black)
                    .clipShape(Capsule())
                    .shadow(radius: 4)
                    .padding(.top, 80)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.spring(), value: vm.showMessage)
            }
        }
        .sheet(isPresented: $vm.showResult) {
            ResultView()
                .environmentObject(vm)
        }
    }
}
