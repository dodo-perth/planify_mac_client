import Foundation

public struct Plan: Codable, Identifiable {
    public let id: UUID
    public var title: String
    public var location: String
    public var startTime: Date
    public var endTime: Date
    public var details: String
    
    public init(id: UUID = UUID(), title: String = "", location: String = "", startTime: Date = Date(), endTime: Date = Date(), details: String = "") {
        self.id = id
        self.title = title
        self.location = location
        self.startTime = startTime
        self.endTime = endTime
        self.details = details
    }
} 