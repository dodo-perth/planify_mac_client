import AppKit

public protocol CaptureService {
    func captureArea(rect: CGRect) async throws -> NSImage?
    func stopCapture()
}

public protocol NotificationService {
    func showCaptureSuccess()
    func showError(_ message: String)
    func scheduleReminder(for plan: Plan)
}

public protocol StorageService {
    func saveCapture(_ image: NSImage, metadata: CaptureMetadata) async throws -> URL
    func loadRecentCaptures() async throws -> [CaptureMetadata]
} 