import SwiftUI
import UniformTypeIdentifiers

struct ImagePicker: NSViewControllerRepresentable {
    @Binding var image: NSImage?

    func makeNSViewController(context: Context) -> NSViewController {
        return NSViewController()
    }

    func updateNSViewController(_ nsViewController: NSViewController, context: Context) {
        let picker = NSOpenPanel()
        picker.allowedContentTypes = [UTType.image]
        picker.allowsMultipleSelection = false
        picker.canChooseDirectories = false
        picker.canChooseFiles = true
        
        picker.beginSheetModal(for: nsViewController.view.window!) { result in
            if result == .OK {
                if let url = picker.url {
                    self.image = NSImage(contentsOf: url)
                }
            }
        }
    }
}
