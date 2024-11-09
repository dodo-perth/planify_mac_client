import Foundation
import ScreenCaptureKit
import CoreGraphics
import SwiftUI

class ScreenCaptureManager: ObservableObject {
    static let shared = ScreenCaptureManager()
    
    @Published var isCapturing = false
    @Published var capturedImage: NSImage?
    @Published var error: Error?
    
    private var streamConfig: SCStreamConfiguration
    private var captureEngine: SCStream?
    private var windowList: [SCWindow]?
    private var displayList: [SCDisplay]?
    
    private init() {
        self.streamConfig = SCStreamConfiguration()
        self.streamConfig.width = 1920
        self.streamConfig.height = 1080
        self.streamConfig.minimumFrameInterval = CMTime(value: 1, timescale: 60)
        self.streamConfig.pixelFormat = kCVPixelFormatType_32BGRA
    }
    
    func requestPermission() async -> Bool {
        do {
            let status = await SCShareableContent.current().status
            switch status {
            case .authorized:
                return true
            case .denied:
                throw NSError(domain: "ScreenCapturePermissionError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Screen capture permission denied"])
            case .notDetermined:
                // Request permission
                try await SCShareableContent.requestPermission()
                return await SCShareableContent.current().status == .authorized
            @unknown default:
                return false
            }
        } catch {
            self.error = error
            return false
        }
    }
    
    func captureArea(rect: CGRect) async throws -> NSImage? {
        guard await requestPermission() else {
            throw NSError(domain: "ScreenCaptureError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Permission not granted"])
        }
        
        let content = try await SCShareableContent.current()
        guard let display = content.displays.first else {
            throw NSError(domain: "ScreenCaptureError", code: 2, userInfo: [NSLocalizedDescriptionKey: "No display found"])
        }
        
        let filter = SCContentFilter(.display(display), excludingWindows: [])
        let stream = SCStream(filter: filter, configuration: streamConfig, delegate: nil)
        
        // Capture specific area
        let captureRect = CGRect(x: rect.minX,
                               y: rect.minY,
                               width: min(rect.width, CGFloat(streamConfig.width)),
                               height: min(rect.height, CGFloat(streamConfig.height)))
        
        return try await withCheckedThrowingContinuation { continuation in
            stream.addStreamOutput(self, type: .screen, sampleHandlerQueue: .main)
            do {
                try stream.startCapture()
                self.captureEngine = stream
                
                // Capture frame after a short delay to ensure stream is ready
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    if let cgImage = self.captureFrame(in: captureRect) {
                        let image = NSImage(cgImage: cgImage, size: captureRect.size)
                        continuation.resume(returning: image)
                    } else {
                        continuation.resume(throwing: NSError(domain: "ScreenCaptureError", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to capture frame"]))
                    }
                    self.stopCapture()
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    private func captureFrame(in rect: CGRect) -> CGImage? {
        guard let displayID = CGMainDisplayID() else { return nil }
        guard let screenshot = CGDisplayCreateImage(displayID, rect: rect) else { return nil }
        return screenshot
    }
    
    func stopCapture() {
        captureEngine?.stopCapture()
        captureEngine = nil
    }
}

// MARK: - SCStreamOutput
extension ScreenCaptureManager: SCStreamOutput {
    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .screen else { return }
        
        // Handle captured frame if needed
        if let imageBuffer = sampleBuffer.imageBuffer {
            // Process the captured frame
            print("Frame captured: \(imageBuffer)")
        }
    }
}
