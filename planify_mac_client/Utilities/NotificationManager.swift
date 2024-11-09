import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {
        requestAuthorization()
    }
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Error requesting notification permission: \(error.localizedDescription)")
            }
        }
    }
    
    func scheduleNotification(for plan: Plan, minutesBefore: Int = 15) {
        let content = UNMutableNotificationContent()
        content.title = "Upcoming Plan: \(plan.title)"
        content.body = """
        Location: \(plan.location)
        Time: \(formatDate(plan.startTime))
        """
        content.sound = .default
        
        let triggerDate = plan.startTime.addingTimeInterval(TimeInterval(-minutesBefore * 60))
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate),
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "plan-\(plan.id)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            }
        }
    }
    
    func showCaptureSuccessNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Screenshot Captured"
        content.body = "Your screenshot has been successfully processed"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func showCalendarSuccessNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Calendar Event Added"
        content.body = "Event has been successfully added to your Google Calendar"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func showErrorNotification(message: String) {
        let content = UNMutableNotificationContent()
        content.title = "Error"
        content.body = message
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