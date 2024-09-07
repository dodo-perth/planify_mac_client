import SwiftUI
import HotKey
import Vision

import ScreenCaptureKit

class ContentViewModel: NSObject, ObservableObject {
    @Published var processedImage: NSImage?
    @Published var isProcessing = false
    @Published var processedText = ""
    @Published var errorMessage: String?
    @Published var apiResponse: [String: Any]?
    @Published var showPlanForm = false
    @Published var isSelectingArea = false
    @Published var selectionRect: CGRect = .zero
    @Published var isDragging = false
    @Published var isLoadingAPIResponse = false

    func startAreaSelection() {
        isSelectingArea = true
    }

    func pasteFromClipboard() {
        getImageFromPasteboard()
    }
    private var areaScreenshotHotKey: HotKey?
    
    enum ScreenshotType {
        case full, window, area
    }
    
    override init() {
        super.init()
        setupHotKeys()
        requestScreenCaptureAccess()
    }
    
    private func setupHotKeys() {
        areaScreenshotHotKey = HotKey(key: .l, modifiers: [.command, .control, .option])
        areaScreenshotHotKey?.keyDownHandler = { [weak self] in
            self?.takeScreenshot(.area)
        }
    }
    
    func takeScreenshot(_ type: ScreenshotType) {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
        
        switch type {
        case .full:
            task.arguments = ["-c"]
        case .window:
            task.arguments = ["-cw"]
        case .area:
            task.arguments = ["-cis"]  // Interactive, silent mode
        }
        
        do {
            isProcessing = true
            try task.run()
            task.waitUntilExit()
            getImageFromPasteboard()
            isProcessing = false
            
            if let image = processedImage {
                performOCR(on: image)
            }
        } catch {
            print("Could not take screenshot: \(error)")
            isProcessing = false
        }
    }
    
    private func getImageFromPasteboard() {
        guard NSPasteboard.general.canReadItem(withDataConformingToTypes: NSImage.imageTypes) else { return }
        guard let image = NSImage(pasteboard: NSPasteboard.general) else { return }
        self.processedImage = image
    }
    
    func performOCR(on image: NSImage) {
        isProcessing = true
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            isProcessing = false
            return
        }

        let request = VNRecognizeTextRequest { [weak self] request, error in
            guard let self = self else { return }
            self.isProcessing = false
            
            if let error = error {
                self.errorMessage = "OCR failed: \(error.localizedDescription)"
                return
            }
            
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                self.errorMessage = "No text found in the image"
                return
            }
            
            let recognizedText = observations.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
            DispatchQueue.main.async {
                self.processedText = recognizedText
                self.sendTextToAPI(text: recognizedText)
            }
        }
        
        request.recognitionLevel = .accurate
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
        } catch {
            self.errorMessage = "OCR processing failed: \(error.localizedDescription)"
        }
    }
    
    func sendTextToAPI(text: String) {
        guard let token = UserDefaults.standard.string(forKey: "authToken") else {
            self.errorMessage = "Authentication token not found. Please log in."
            return
        }
        
        APIService.shared.processText(text, token: token, timezone: TimeZone.current.identifier) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let extractedInfo):
                    self.apiResponse = extractedInfo
                    WindowManager.shared.showPlanFormWindow(apiResponse: extractedInfo, screenshot: self.processedImage)
                case .failure(let error):
                    self.errorMessage = "API Error: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func requestScreenCaptureAccess() {
        Task {
            do {
                try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
            } catch {
                print("Failed to request screen capture access: \(error)")
            }
        }
    }
}
