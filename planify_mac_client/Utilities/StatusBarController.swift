import AppKit
import SwiftUI

class StatusBarController {
    private var statusBar: NSStatusBar
    private var statusItem: NSStatusItem
    private var menu: NSMenu
    private var recentItems: [CaptureItem] = []
    private let maxRecentItems = 5
    
    init() {
        statusBar = NSStatusBar.system
        statusItem = statusBar.statusItem(withLength: NSStatusItem.variableLength)
        menu = NSMenu()
        
        setupStatusBarItem()
        setupMenu()
    }
    
    private func setupStatusBarItem() {
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "text.viewfinder", accessibilityDescription: "Planify")
            button.imagePosition = .imageLeft
        }
        statusItem.menu = menu
    }
    
    private func setupMenu() {
        // 캡처 메뉴 아이템들
        let captureArea = NSMenuItem(title: "Capture Area", action: #selector(captureArea), keyEquivalent: "l")
        captureArea.keyEquivalentModifierMask = [.command, .control, .option]
        
        let captureWindow = NSMenuItem(title: "Capture Window", action: #selector(captureWindow), keyEquivalent: "w")
        captureWindow.keyEquivalentModifierMask = [.command, .control]
        
        let captureScreen = NSMenuItem(title: "Capture Screen", action: #selector(captureScreen), keyEquivalent: "s")
        captureScreen.keyEquivalentModifierMask = [.command, .control]
        
        // 최근 캡처 서브메뉴
        let recentSubmenu = NSMenu()
        let recentMenuItem = NSMenuItem(title: "Recent Captures", action: nil, keyEquivalent: "")
        recentMenuItem.submenu = recentSubmenu
        
        // 설정 메뉴
        let preferencesItem = NSMenuItem(title: "Preferences...", action: #selector(openPreferences), keyEquivalent: ",")
        preferencesItem.keyEquivalentModifierMask = .command
        
        // 메뉴 구성
        menu.addItem(captureArea)
        menu.addItem(captureWindow)
        menu.addItem(captureScreen)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(recentMenuItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(preferencesItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit Planify", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
    }
    
    func updateRecentItems(_ item: CaptureItem) {
        recentItems.insert(item, at: 0)
        if recentItems.count > maxRecentItems {
            recentItems.removeLast()
        }
        updateRecentItemsMenu()
    }
    
    private func updateRecentItemsMenu() {
        guard let recentSubmenu = menu.item(withTitle: "Recent Captures")?.submenu else { return }
        recentSubmenu.removeAllItems()
        
        if recentItems.isEmpty {
            let emptyItem = NSMenuItem(title: "No Recent Items", action: nil, keyEquivalent: "")
            emptyItem.isEnabled = false
            recentSubmenu.addItem(emptyItem)
            return
        }
        
        for item in recentItems {
            let menuItem = NSMenuItem(title: item.title, action: #selector(openRecentItem(_:)), keyEquivalent: "")
            menuItem.representedObject = item
            menuItem.image = item.thumbnail
            recentSubmenu.addItem(menuItem)
        }
        
        recentSubmenu.addItem(NSMenuItem.separator())
        recentSubmenu.addItem(NSMenuItem(title: "Clear Recent Items", action: #selector(clearRecentItems), keyEquivalent: ""))
    }
    
    @objc private func captureArea() {
        NotificationCenter.default.post(name: .captureArea, object: nil)
    }
    
    @objc private func captureWindow() {
        NotificationCenter.default.post(name: .captureWindow, object: nil)
    }
    
    @objc private func captureScreen() {
        NotificationCenter.default.post(name: .captureScreen, object: nil)
    }
    
    @objc private func openPreferences() {
        NotificationCenter.default.post(name: .openPreferences, object: nil)
    }
    
    @objc private func openRecentItem(_ sender: NSMenuItem) {
        guard let item = sender.representedObject as? CaptureItem else { return }
        NotificationCenter.default.post(name: .openRecentItem, object: item)
    }
    
    @objc private func clearRecentItems() {
        recentItems.removeAll()
        updateRecentItemsMenu()
    }
}

// MARK: - Supporting Types
struct CaptureItem: Identifiable {
    let id = UUID()
    let title: String
    let date: Date
    let thumbnail: NSImage?
    let imageData: Data
}

// MARK: - Notification Names
extension Notification.Name {
    static let captureArea = Notification.Name("captureArea")
    static let captureWindow = Notification.Name("captureWindow")
    static let captureScreen = Notification.Name("captureScreen")
    static let openPreferences = Notification.Name("openPreferences")
    static let openRecentItem = Notification.Name("openRecentItem")
}
