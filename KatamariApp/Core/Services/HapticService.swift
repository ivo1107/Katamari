import UIKit
import CoreHaptics

final class HapticService {
    static let shared = HapticService()
    private var engine: CHHapticEngine?

    private init() { prepareEngine() }

    private func prepareEngine() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            engine = try CHHapticEngine()
            try engine?.start()
            engine?.stoppedHandler = { [weak self] _ in self?.prepareEngine() }
            engine?.resetHandler  = { [weak self] in try? self?.engine?.start() }
        } catch {}
    }

    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }

    func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }

    func playVoteSuccess() {
        notification(.success)
    }

    func playCorrectGuess() {
        guard let engine,
              CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            notification(.success)
            return
        }
        let events: [CHHapticEvent] = [
            CHHapticEvent(eventType: .hapticTransient,
                          parameters: [CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                                       CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)],
                          relativeTime: 0),
            CHHapticEvent(eventType: .hapticTransient,
                          parameters: [CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8),
                                       CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)],
                          relativeTime: 0.15),
            CHHapticEvent(eventType: .hapticTransient,
                          parameters: [CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                                       CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)],
                          relativeTime: 0.3)
        ]
        guard let pattern = try? CHHapticPattern(events: events, parameters: []),
              let player  = try? engine.makePlayer(with: pattern) else { return }
        try? player.start(atTime: CHHapticTimeImmediate)
    }

    func playWrongGuess() {
        notification(.error)
    }

    func playRoundAdvance() {
        impact(.medium)
    }

    func playGameStart() {
        impact(.heavy)
    }
}
