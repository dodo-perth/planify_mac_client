import SwiftUI

struct PreferencesView: View {
    @AppStorage("defaultSaveLocation") private var defaultSaveLocation: String = ""
    @AppStorage("autoSaveCaptures") private var autoSaveCaptures: Bool = false
    @AppStorage("captureQuality") private var captureQuality: CaptureQuality = .high
    @AppStorage("showMagnifier") private var showMagnifier: Bool = true
    @AppStorage("showDimensions") private var showDimensions: Bool = true
    
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            GeneralSettingsView(
                autoSaveCaptures: $autoSaveCaptures,
                defaultSaveLocation: $defaultSaveLocation,
                captureQuality: $captureQuality
            )
            .tabItem {
                Label("General", systemImage: "gear")
            }
            .tag(0)
            
            CaptureSettingsView(
                showMagnifier: $showMagnifier,
                showDimensions: $showDimensions
            )
            .tabItem {
                Label("Capture", systemImage: "camera")
            }
            .tag(1)
            
            ShortcutsView()
            .tabItem {
                Label("Shortcuts", systemImage: "keyboard")
            }
            .tag(2)
        }
        .frame(width: 500, height: 300)
        .padding()
    }
}

struct GeneralSettingsView: View {
    @Binding var autoSaveCaptures: Bool
    @Binding var defaultSaveLocation: String
    @Binding var captureQuality: CaptureQuality
    
    var body: some View {
        Form {
            Section {
                Toggle("Auto-save captures", isOn: $autoSaveCaptures)
                
                HStack {
                    Text("Save location:")
                    TextField("Default save location", text: $defaultSaveLocation)
                    Button("Choose...") {
                        selectSaveLocation()
                    }
                }
                
                Picker("Capture Quality", selection: $captureQuality) {
                    ForEach(CaptureQuality.allCases) { quality in
                        Text(quality.description).tag(quality)
                    }
                }
            }
        }
        .padding()
    }
    
    private func selectSaveLocation() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        
        if panel.runModal() == .OK {
            defaultSaveLocation = panel.url?.path ?? ""
        }
    }
}

struct CaptureSettingsView: View {
    @Binding var showMagnifier: Bool
    @Binding var showDimensions: Bool
    
    var body: some View {
        Form {
            Section {
                Toggle("Show magnifier while selecting area", isOn: $showMagnifier)
                Toggle("Show dimensions while selecting area", isOn: $showDimensions)
            }
        }
        .padding()
    }
}

struct ShortcutsView: View {
    var body: some View {
        Form {
            Section {
                HStack {
                    Text("Area capture")
                    Spacer()
                    Text("⌘⌃⌥L")
                        .font(.system(.body, design: .monospaced))
                }
                
                HStack {
                    Text("Window capture")
                    Spacer()
                    Text("⌘⌃W")
                        .font(.system(.body, design: .monospaced))
                }
                
                HStack {
                    Text("Screen capture")
                    Spacer()
                    Text("⌘⌃S")
                        .font(.system(.body, design: .monospaced))
                }
            }
        }
        .padding()
    }
}

enum CaptureQuality: String, CaseIterable, Identifiable {
    case low
    case medium
    case high
    
    var id: String { rawValue }
    
    var description: String {
        switch self {
        case .low: return "Low (Faster)"
        case .medium: return "Medium"
        case .high: return "High (Better Quality)"
        }
    }
} 