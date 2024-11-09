import SwiftUI
import Vision
import ScreenCaptureKit
import Carbon
import AppKit
import UserNotifications

// MARK: - Types
enum ScreenshotType {
    case full, window, area
}

class ContentViewModel: NSObject, ObservableObject {
    // MARK: - Published Properties
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

    @AppStorage("autoSaveCaptures") private var autoSaveCaptures: Bool = false

    // MARK: - Private Properties
    private var areaScreenshotHotkeyID: UInt32?
    
    // MARK: - Services
    private let screenCapture: ScreenCaptureService
    private let notification: NotificationService
    private let storage: StorageService
    private let hotkey: HotkeyService
    
    override init() {
        self.screenCapture = ScreenCaptureService.shared
        self.notification = NotificationService.shared
        self.storage = StorageService.shared
        self.hotkey = HotkeyManager.shared
        
        super.init()
        setupHotKeys()
        setupNotifications()
    }
    
    // MARK: - Public Methods
    func startAreaSelection() {
        isSelectingArea = true
    }
    
    func takeScreenshot(_ type: ScreenshotType) {
        Task {
            do {
                isProcessing = true
                switch type {
                case .area:
                    if let image = try await screenCapture.captureArea(rect: selectionRect) {
                        await handleCapturedImage(image)
                    }
                case .full, .window:
                    // Legacy screenshot code
                    let task = Process()
                    task.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
                    task.arguments = type == .full ? ["-c"] : ["-cw"]
                    
                    try task.run()
                    task.waitUntilExit()
                    if let image = NSImage(pasteboard: .general) {
                        await handleCapturedImage(image)
                    }
                }
            } catch {
                await handleError(error)
            }
        }
    }
    
    // MARK: - Private Methods
    private func setupHotKeys() {
        areaScreenshotHotkeyID = hotkey.register(
            keyCode: kVK_ANSI_L,
            modifiers: cmdKey | controlKey | optionKey
        ) { [weak self] in
            self?.takeScreenshot(.area)
        }
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAreaCapture),
            name: .captureArea,
            object: nil
        )
    }
    
    @objc private func handleAreaCapture() {
        takeScreenshot(.area)
    }
    
    @MainActor
    private func handleCapturedImage(_ image: NSImage) {
        processedImage = image
        isProcessing = false
        notification.showCaptureSuccess()
        
        if autoSaveCaptures {
            Task {
                do {
                    let metadata = CaptureMetadata(
                        id: UUID(),
                        title: "Screenshot \(Date())",
                        timestamp: Date(),
                        extractedText: processedText,
                        plans: []
                    )
                    let url = try await storage.saveCapture(image, metadata: metadata)
                    print("Screenshot saved to: \(url)")
                } catch {
                    handleError(error)
                }
            }
        }
        
        // OCR 처리
        let request = VNRecognizeTextRequest { [weak self] request, error in
            guard let self = self else { return }
            if let error = error {
                self.errorMessage = error.localizedDescription
                return
            }
            
            if let observations = request.results as? [VNRecognizedTextObservation] {
                let recognizedText = observations.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
                DispatchQueue.main.async {
                    self.processedText = recognizedText
                }
            }
        }
        
        if let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) {
            try? VNImageRequestHandler(cgImage: cgImage, options: [:]).perform([request])
        }
    }
    
    @MainActor
    private func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
        isProcessing = false
        notification.showError(error.localizedDescription)
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let captureArea = Notification.Name("captureArea")
    static let captureWindow = Notification.Name("captureWindow")
    static let captureScreen = Notification.Name("captureScreen")
    static let openPreferences = Notification.Name("openPreferences")
    static let openRecentItem = Notification.Name("openRecentItem")
}
