import Foundation
import FirebaseFirestore
import FirebaseAuth

final class NotificationService {
    static let shared = NotificationService()
    private let db = Firestore.firestore()
    private init() {}

    func updateFCMToken(_ token: String) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        db.collection("users").document(uid).updateData(["fcmToken": token])
    }

    func scheduleLocalTurnNotification(playerName: String) {
        let content = UNMutableNotificationContent()
        content.title = "Quem Sou Eu?"
        content.body  = "É a sua vez de perguntar!"
        content.sound = .default
        content.badge = 1

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "turn-\(UUID().uuidString)",
                                             content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func scheduleLocalVoteNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Vote agora!"
        content.body  = "Um jogador fez uma pergunta. Vote Sim ou Não."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "vote-\(UUID().uuidString)",
                                             content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func clearBadge() {
        UNUserNotificationCenter.current().setBadgeCount(0)
    }
}
