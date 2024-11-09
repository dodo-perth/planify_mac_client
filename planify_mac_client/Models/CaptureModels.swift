import AppKit

public struct CaptureMetadata: Codable {
    public let id: UUID
    public let title: String
    public let timestamp: Date
    public let extractedText: String
    public let plans: [Plan]
    
    public init(id: UUID, title: String, timestamp: Date, extractedText: String, plans: [Plan]) {
        self.id = id
        self.title = title
        self.timestamp = timestamp
        self.extractedText = extractedText
        self.plans = plans
    }
}

public struct CaptureItem: Identifiable {
    public let id: UUID
    public let title: String
    public let date: Date
    public let thumbnail: NSImage?
    public let imageData: Data
} 