import Carbon
import AppKit

public protocol HotkeyService {
    func register(keyCode: Int, modifiers: Int, action: @escaping () -> Void) -> UInt32
    func unregister(id: UInt32)
}

public class HotkeyManager: NSObject, HotkeyService {
    public static let shared = HotkeyManager()
    private var hotKeys: [UInt32: () -> Void] = [:]
    private var nextHotkeyID: UInt32 = 1
    
    private override init() {
        super.init()
        setupEventHandler()
    }
    
    private func setupEventHandler() {
        let eventSpec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        
        InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, event, userData) -> OSStatus in
                guard let manager = userData?.assumingMemoryBound(to: HotkeyManager.self).pointee else {
                    return noErr
                }
                
                var hotkeyID = EventHotKeyID()
                let size = MemoryLayout<EventHotKeyID>.size
                let status = GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    size,
                    nil,
                    &hotkeyID
                )
                
                if status == noErr {
                    manager.hotKeys[hotkeyID.id]?()
                }
                
                return noErr
            },
            1,
            &eventSpec,
            UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()),
            nil
        )
    }
    
    public func register(keyCode: Int, modifiers: Int, action: @escaping () -> Void) -> UInt32 {
        let hotkeyID = nextHotkeyID
        nextHotkeyID += 1
        
        var eventHotKey: EventHotKeyRef?
        var gMyHotKeyID = EventHotKeyID()
        gMyHotKeyID.id = hotkeyID
        gMyHotKeyID.signature = OSType("PLNF".fourCharCodeValue)
        
        let status = RegisterEventHotKey(
            UInt32(keyCode),
            UInt32(modifiers),
            gMyHotKeyID,
            GetApplicationEventTarget(),
            0,
            &eventHotKey
        )
        
        if status == noErr {
            hotKeys[hotkeyID] = action
        }
        
        return hotkeyID
    }
    
    public func unregister(id: UInt32) {
        hotKeys.removeValue(forKey: id)
    }
}

extension String {
    var fourCharCodeValue: OSType {
        guard self.count == 4 else { return 0 }
        var result: OSType = 0
        for char in self.utf8 {
            result = result << 8 + OSType(char)
        }
        return result
    }
} 