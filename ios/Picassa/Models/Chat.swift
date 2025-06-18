import Foundation
import FirebaseFirestore

struct Chat: Codable, Identifiable, FirestoreSerializable, Equatable, Sendable {
    var id: String?
    var participantIds: [String]
    var lastMessage: Message?
    var lastMessageAt: Date?
    var eventIds: [String]?  // Uložené vo Firebase
    
    // Computed property - nebude vo Firebase
    var events: [Event]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case participantIds
        case lastMessage
        case lastMessageAt
        case eventIds
        // events nie je v CodingKeys, takže sa nebude serializovať
    }
    
    init(id: String? = nil, 
         participantIds: [String], 
         lastMessage: Message? = nil, 
         lastMessageAt: Date? = nil,
         eventIds: [String]? = nil,
         events: [Event]? = nil) {
        self.id = id
        self.participantIds = participantIds
        self.lastMessage = lastMessage
        self.lastMessageAt = lastMessageAt
        self.eventIds = eventIds
        self.events = events
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        participantIds = try container.decode([String].self, forKey: .participantIds)
        lastMessageAt = try container.decodeIfPresent(Date.self, forKey: .lastMessageAt)
        eventIds = try container.decodeIfPresent([String].self, forKey: .eventIds)
        events = nil // Toto sa načíta neskôr
        
        // Pokúsime sa dekódovať lastMessage, ale ak zlyhá, nastavíme ho na nil
        do {
            lastMessage = try container.decodeIfPresent(Message.self, forKey: .lastMessage)
        } catch {
            print("DEBUG: Error decoding lastMessage:", error)
            lastMessage = nil
        }
    }
} 
