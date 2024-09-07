import SwiftUI

@main
struct planify_mac_clientApp: App {
    @StateObject var appState = AppState()
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
        .windowStyle(HiddenTitleBarWindowStyle())
        .commands {
            CommandGroup(replacing: .newItem, addition: { })
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow?
    var statusItem: NSStatusItem?
    var contentViewModel: ContentViewModel?

    func applicationDidFinishLaunching(_ notification: Notification) {
        DispatchQueue.main.async {
            if let window = NSApplication.shared.windows.first {
                self.customizeWindow(window)
            }
        }
        setupStatusBarItem()
        contentViewModel = ContentViewModel()
    }

    func customizeWindow(_ window: NSWindow) {
        let customWindow = CustomWindow(contentRect: window.frame, styleMask: window.styleMask, backing: .buffered, defer: false)
        customWindow.contentView = window.contentView
        customWindow.makeKeyAndOrderFront(nil)
        window.orderOut(nil)
        
        self.window = customWindow
        customWindow.styleMask.remove(.resizable)
        customWindow.styleMask.remove(.fullScreen)
        customWindow.standardWindowButton(.zoomButton)?.isEnabled = false
        customWindow.center()
        adjustWindowSize(isLoggedIn: false)
    }

    func adjustWindowSize(isLoggedIn: Bool) {
        let newSize = isLoggedIn ? NSSize(width: 500, height: 600) : NSSize(width: 300, height: 400)
        window?.setContentSize(newSize)
        window?.center()
    }

    func setupStatusBarItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem?.button {
            button.image = NSImage(named: "StatusBarIcon")
            button.action = #selector(togglePopover(_:))
        }
    }

    @objc func togglePopover(_ sender: AnyObject?) {
        // Implement popover logic here if needed
    }

    func hideAppFromDock() {
        NSApp.setActivationPolicy(.accessory)
    }
}

class CustomWindow: NSWindow {
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: [.titled, .closable, .miniaturizable], backing: backingStoreType, defer: flag)
        
        self.isOpaque = true
        self.backgroundColor = .white
        self.hasShadow = true
        self.titlebarAppearsTransparent = false
        self.isMovableByWindowBackground = true
        
        if let contentView = self.contentView {
            contentView.wantsLayer = true
            contentView.layer?.cornerRadius = 0
            contentView.layer?.masksToBounds = true
        }
    }
}
