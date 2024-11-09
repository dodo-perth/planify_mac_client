import Foundation
import ScreenCaptureKit
import AppKit

public class ScreenCaptureService: NSObject, CaptureService {
    public static let shared = ScreenCaptureService()
    private var streamConfig: SCStreamConfiguration
    private var captureEngine: SCStream?
    
    private override init() {
        self.streamConfig = SCStreamConfiguration()
        super.init()
        setupConfiguration()
    }
    
    private func setupConfiguration() {
        streamConfig.width = 1920
        streamConfig.height = 1080
        streamConfig.minimumFrameInterval = CMTime(value: 1, timescale: 60)
        streamConfig.pixelFormat = kCVPixelFormatType_32BGRA
    }
    
    public func captureArea(rect: CGRect) async throws -> NSImage? {
        guard await checkPermission() else {
            throw CaptureError.permissionDenied
        }
        
        let content = try await SCShareableContent.current
        guard let display = content.displays.first else {
            throw CaptureError.noDisplay
        }
        
        let filter = SCContentFilter(display: display, excludingWindows: [])
        let stream = SCStream(filter: filter, configuration: streamConfig, delegate: nil)
        
        return try await withCheckedThrowingContinuation { continuation in
            do {
                try stream.addStreamOutput(self, type: .screen, sampleHandlerQueue: .main)
                try stream.startCapture()
                
                // 캡처 지연을 주어 스트림이 준비되도록 함
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    if let image = self.captureFrame(in: rect) {
                        continuation.resume(returning: image)
                    } else {
                        continuation.resume(throwing: CaptureError.captureFailed)
                    }
                    self.stopCapture()
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    private func checkPermission() async -> Bool {
        do {
            let content = try await SCShareableContent.current
            return !content.displays.isEmpty
        } catch {
            return false
        }
    }
    
    private func captureFrame(in rect: CGRect) -> NSImage? {
        guard let displayID = CGMainDisplayID(),
              let cgImage = CGDisplayCreateImage(displayID, rect: rect) else {
            return nil
        }
        return NSImage(cgImage: cgImage, size: rect.size)
    }
    
    public func stopCapture() {
        captureEngine?.stopCapture()
        captureEngine = nil
    }
}

extension ScreenCaptureService: SCStreamOutput {
    public func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        // 필요한 경우 프레임 처리
    }
}

enum CaptureError: Error {
    case permissionDenied
    case noDisplay
    case captureFailed
} 