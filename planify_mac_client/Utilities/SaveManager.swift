import Foundation
import AppKit

class SaveManager {
    static let shared = SaveManager()
    
    private let fileManager = FileManager.default
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter
    }()
    
    private init() {
        createDirectoryIfNeeded()
    }
    
    private var defaultDirectory: URL? {
        get {
            if let path = UserDefaults.standard.string(forKey: "defaultSaveLocation") {
                return URL(fileURLWithPath: path)
            }
            return fileManager.urls(for: .picturesDirectory, in: .userDomainMask).first?.appendingPathComponent("Planify")
        }
    }
    
    private func createDirectoryIfNeeded() {
        guard let directory = defaultDirectory else { return }
        
        if !fileManager.fileExists(atPath: directory.path) {
            try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }
    }
    
    func saveScreenshot(_ image: NSImage, title: String? = nil) throws -> URL {
        guard let directory = defaultDirectory else {
            throw SaveError.noDefaultDirectory
        }
        
        let filename = title?.replacingOccurrences(of: " ", with: "_") ?? dateFormatter.string(from: Date())
        let fileURL = directory.appendingPathComponent("\(filename).png")
        
        guard let data = image.pngData() else {
            throw SaveError.imageConversionFailed
        }
        
        try data.write(to: fileURL)
        return fileURL
    }
    
    func saveWithMetadata(_ image: NSImage, metadata: CaptureMetadata) throws -> URL {
        guard let directory = defaultDirectory else {
            throw SaveError.noDefaultDirectory
        }
        
        // 메타데이터 저장을 위한 디렉토리 생성
        let captureDir = directory.appendingPathComponent(metadata.id.uuidString)
        try fileManager.createDirectory(at: captureDir, withIntermediateDirectories: true)
        
        // 이미지 저장
        let imageURL = captureDir.appendingPathComponent("capture.png")
        guard let imageData = image.pngData() else {
            throw SaveError.imageConversionFailed
        }
        try imageData.write(to: imageURL)
        
        // 메타데이터 저장
        let metadataURL = captureDir.appendingPathComponent("metadata.json")
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let metadataData = try encoder.encode(metadata)
        try metadataData.write(to: metadataURL)
        
        return imageURL
    }
    
    func loadRecentCaptures(limit: Int = 10) throws -> [CaptureMetadata] {
        guard let directory = defaultDirectory else {
            throw SaveError.noDefaultDirectory
        }
        
        let contents = try fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.creationDateKey],
            options: [.skipsHiddenFiles]
        )
        
        return try contents
            .filter { try $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory == true }
            .compactMap { dir -> CaptureMetadata? in
                let metadataURL = dir.appendingPathComponent("metadata.json")
                guard let data = try? Data(contentsOf: metadataURL) else { return nil }
                return try? JSONDecoder().decode(CaptureMetadata.self, from: data)
            }
            .sorted { $0.timestamp > $1.timestamp }
            .prefix(limit)
            .map { $0 }
    }
}

// MARK: - Supporting Types
struct CaptureMetadata: Codable {
    let id: UUID
    let title: String
    let timestamp: Date
    let extractedText: String
    let plans: [Plan]
    
    var thumbnailURL: URL {
        SaveManager.shared.defaultDirectory?
            .appendingPathComponent(id.uuidString)
            .appendingPathComponent("capture.png") ?? URL(fileURLWithPath: "")
    }
}

enum SaveError: Error {
    case noDefaultDirectory
    case imageConversionFailed
    case metadataEncodingFailed
    case fileOperationFailed
}

extension NSImage {
    func pngData() -> Data? {
        guard let tiffRepresentation = tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffRepresentation) else { return nil }
        return bitmapImage.representation(using: .png, properties: [:])
    }
} 