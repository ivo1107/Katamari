# Palavra — Setup no Xcode

## Como abrir no Xcode

1. Abra o **Xcode** (versão 15 ou superior)
2. **File → New → Project** → App (iOS)
3. Configure:
   - **Product Name:** Palavra
   - **Bundle Identifier:** com.seuNome.palavra
   - **Interface:** SwiftUI
   - **Language:** Swift
   - **Minimum Deployments:** iOS 16.0
4. **Apague** o `ContentView.swift` e `AppName.swift` gerados pelo template
5. **Arraste** toda a pasta `Palavra/` (este repositório) para dentro do projeto no Xcode
6. Marque **"Copy items if needed"** e **"Create groups"**
7. **Build & Run** no simulador de iPhone (⌘R)

## Estrutura do projeto

```
Palavra/
├── PalavraApp.swift          ← Ponto de entrada @main
├── ContentView.swift         ← TabView + SetupView (nome do jogador)
├── Models/
│   ├── Letter.swift          ← LetterState (correct/present/absent) + Color extension
│   ├── GameState.swift       ← Estado da partida (grid 6×5)
│   └── LeaderboardEntry.swift← Modelo do jogador + PlayerStats
├── ViewModels/
│   ├── GameViewModel.swift   ← Lógica do jogo, pontuação, persistência
│   └── LeaderboardViewModel.swift
├── Views/
│   ├── GameView.swift        ← Tela principal do jogo
│   ├── WordGridView.swift    ← Grade 6×5 + animações
│   ├── KeyboardView.swift    ← Teclado QWERTY colorido
│   ├── ResultView.swift      ← Sheet de resultado (ganhou/perdeu)
│   ├── LeaderboardView.swift ← Ranking global
│   └── ProfileView.swift     ← Perfil, estatísticas, como jogar
└── Services/
    ├── WordService.swift     ← Lista de palavras + palavra do dia
    └── LeaderboardService.swift ← Mock local (pronto para Firebase/Supabase)
```

## Sistema de pontuação

| Tentativas | Pontos |
|-----------|--------|
| 1ª        | 100    |
| 2ª        | 80     |
| 3ª        | 60     |
| 4ª        | 40     |
| 5ª        | 20     |
| 6ª        | 10     |

## Conectar um backend real

O `LeaderboardService.swift` implementa o protocolo `LeaderboardServiceProtocol`.
Para usar Firebase Firestore basta criar uma nova classe:

```swift
class FirebaseLeaderboardService: LeaderboardServiceProtocol {
    func fetchLeaderboard() async -> [LeaderboardEntry] {
        // Firestore.firestore().collection("leaderboard").getDocuments()
    }
    func updatePlayerScore(id: String, name: String, score: Int, stats: PlayerStats) async {
        // Firestore.firestore().collection("leaderboard").document(id).setData(...)
    }
}
```

E injetar no `LeaderboardViewModel` e `GameViewModel`.

## Requisitos

- iOS 16.0+
- Xcode 15+
- Swift 5.9+
