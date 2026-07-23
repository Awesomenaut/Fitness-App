import Foundation
import UserNotifications
import Combine

/// Drives the between-set rest countdown and fires a local notification so the
/// alert still lands if the app is backgrounded when the timer completes.
@MainActor
final class RestTimerManager: ObservableObject {
    static let shared = RestTimerManager()

    @Published private(set) var remainingSeconds: Int = 0
    @Published private(set) var totalSeconds: Int = 0
    @Published private(set) var isRunning: Bool = false

    private var timer: Timer?
    private let notificationID = "repforge.rest-timer"

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func start(seconds: Int) {
        cancel()
        totalSeconds = seconds
        remainingSeconds = seconds
        isRunning = true
        scheduleNotification(in: seconds)

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }

    func addSeconds(_ delta: Int) {
        guard isRunning else { return }
        remainingSeconds = max(0, remainingSeconds + delta)
        totalSeconds = max(totalSeconds, remainingSeconds)
        scheduleNotification(in: remainingSeconds)
    }

    func cancel() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        remainingSeconds = 0
        totalSeconds = 0
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationID])
    }

    private func tick() {
        guard remainingSeconds > 0 else {
            cancel()
            return
        }
        remainingSeconds -= 1
        if remainingSeconds == 0 {
            isRunning = false
            timer?.invalidate()
            timer = nil
        }
    }

    private func scheduleNotification(in seconds: Int) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [notificationID])
        guard seconds > 0 else { return }

        let content = UNMutableNotificationContent()
        content.title = "Rest complete"
        content.body = "Time for your next set."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(seconds), repeats: false)
        let request = UNNotificationRequest(identifier: notificationID, content: content, trigger: trigger)
        center.add(request)
    }
}
