import Carbon
import AppKit

class HotkeyManager {
    static let shared = HotkeyManager()
    private var hotKeys: [UInt32: () -> Void] = [:]
    private var nextHotkeyID: UInt32 = 1
    
    private init() {}
    
    func register(keyCode: Int, modifiers: Int, action: @escaping () -> Void) -> UInt32 {
        let hotkeyID = nextHotkeyID
        nextHotkeyID += 1
        
        var eventHotKey: EventHotKeyRef?
        var gMyHotKeyID = EventHotKeyID()
        gMyHotKeyID.id = hotkeyID
        gMyHotKeyID.signature = OSType("hk\(hotkeyID)".fourCharCodeValue)
        
        InstallEventHandler(GetApplicationEventTarget(), { (_, event, _) -> OSStatus in
            let hotkeyID = GetEventParameter(event, .eventHotKeyID, .typeEventHotKeyID)
            HotkeyManager.shared.hotKeys[hotkeyID]?()
            return noErr
        }, 1, &EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed)), nil, nil)
        
        RegisterEventHotKey(UInt32(keyCode), UInt32(modifiers), gMyHotKeyID, GetApplicationEventTarget(), 0, &eventHotKey)
        
        hotKeys[hotkeyID] = action
        return hotkeyID
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