import SwiftUI

class WindowManager: ObservableObject {
    static let shared = WindowManager()
    private init() {}
    
    func showPlanFormWindow(apiResponse: [String: Any], screenshot: NSImage?) {
        let contentView = PlanFormView(screenshot: screenshot, apiResponse: apiResponse, isLoading: false)
        let hostingController = NSHostingController(rootView: contentView)
        let window = NSWindow(contentViewController: hostingController)
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.title = "Plan Form"
        window.setContentSize(NSSize(width: 400, height: 500))
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
