import Cocoa

class AppState: ObservableObject {
    @Published var appDelegate: AppDelegate?
    @Published var isLoggedIn: Bool = false {
        didSet {
            if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
                appDelegate.adjustWindowSize(isLoggedIn: isLoggedIn)
            }
        }
    }
    
    init() {
        if let delegate = NSApplication.shared.delegate as? AppDelegate {
            self.appDelegate = delegate
        }
    }
}
