import Foundation
import AppKit

class StorageService: NSObject, StorageService {
    static let shared = StorageService()
    
    private let fileManager = FileManager.default
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter
    }()
    
    private override init() {
        super.init()
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
    
    func saveCapture(_ image: NSImage, metadata: CaptureMetadata) async throws -> URL {
        guard let directory = defaultDirectory else {
            throw StorageError.noDefaultDirectory
        }
        
        // 메타데이터 저장을 위한 디렉토리 생성
        let captureDir = directory.appendingPathComponent(metadata.id.uuidString)
        try fileManager.createDirectory(at: captureDir, withIntermediateDirectories: true)
        
        // 이미지 저장
        let imageURL = captureDir.appendingPathComponent("capture.png")
        guard let imageData = image.pngData() else {
            throw StorageError.imageConversionFailed
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
    
    func loadRecentCaptures() async throws -> [CaptureMetadata] {
        guard let directory = defaultDirectory else {
            throw StorageError.noDefaultDirectory
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
    }
}

enum StorageError: Error {
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