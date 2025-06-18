import Foundation
import FirebaseFirestore

public struct PrivateUser: Equatable, Codable, Identifiable, FirestoreSerializable, Sendable {
    public var id: String?
    public var lengthOfTheWorkingDay: Double?
    public var chatIds: [String]?
    
    public enum CodingKeys: String, CodingKey {
        case id
        case lengthOfTheWorkingDay
        case chatIds
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(lengthOfTheWorkingDay, forKey: .lengthOfTheWorkingDay)
        try container.encode(chatIds, forKey: .chatIds)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        
        // Skúsime dekódovať ako Double alebo Int
        if let doubleValue = try? container.decodeIfPresent(Double.self, forKey: .lengthOfTheWorkingDay) {
            lengthOfTheWorkingDay = doubleValue
        } else if let intValue = try? container.decodeIfPresent(Int.self, forKey: .lengthOfTheWorkingDay) {
            lengthOfTheWorkingDay = Double(intValue)
        } else {
            lengthOfTheWorkingDay = nil
        }
        chatIds = try container.decodeIfPresent([String].self, forKey: .chatIds)
    }
    
    public init(id: String? = nil, lengthOfTheWorkingDay: Double?, chatIds: [String]? = nil) {
        self.id = id
        self.lengthOfTheWorkingDay = lengthOfTheWorkingDay
        self.chatIds = chatIds
    }
} 
