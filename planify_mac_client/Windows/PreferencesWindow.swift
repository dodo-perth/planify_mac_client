import SwiftUI

class PreferencesWindow: NSWindow {
    static func show() {
        let contentView = PreferencesView()
        let hostingController = NSHostingController(rootView: contentView)
        
        let window = PreferencesWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 300),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        
        window.contentViewController = hostingController
        window.title = "Preferences"
        window.center()
        window.makeKeyAndOrderFront(nil)
    }
    
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)
        
        self.isReleasedWhenClosed = false
        self.center()
    }
} 