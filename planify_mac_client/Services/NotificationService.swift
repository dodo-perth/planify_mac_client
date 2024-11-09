import Foundation
import UserNotifications

public class NotificationService: NSObject {
    public static let shared = NotificationService()
    
    private override init() {
        super.init()
        requestAuthorization()
    }
    
    private func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Error requesting notification permission: \(error.localizedDescription)")
            }
        }
    }
    
    public func showCaptureSuccess() {
        showNotification(title: "Screenshot Captured", body: "Your screenshot has been successfully processed")
    }
    
    public func showError(_ message: String) {
        showNotification(title: "Error", body: message)
    }
    
    public func scheduleReminder(for plan: Plan) {
        let content = UNMutableNotificationContent()
        content.title = "Upcoming Plan: \(plan.title)"
        content.body = """
        Location: \(plan.location)
        Time: \(formatDate(plan.startTime))
        """
        
        let triggerDate = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: plan.startTime.addingTimeInterval(-15 * 60)
        )
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        let request = UNNotificationRequest(
            identifier: "plan-\(plan.id)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    private func showNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

extension NotificationService: NotificationService {
    // Protocol conformance is already satisfied by the class implementation
} 