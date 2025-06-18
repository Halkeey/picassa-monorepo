import Foundation
import FirebaseFirestore

enum MessageType: String, Codable {
    case general
    case system
}

enum MessageSubtype: String, Codable {
    case textMessage = "text_message"
    case filesMessage = "files_message"
    case readReceipt = "read_receipt"
}

struct Message: Codable, Identifiable, FirestoreSerializable, Equatable {
    var id: String?
    let senderId: String
    let text: String
    let timestamp: Date
    let type: MessageType
    let subtype: MessageSubtype
    
    init(id: String? = nil, 
         senderId: String, 
         text: String, 
         timestamp: Date = Date(),
         type: MessageType = .general,
         subtype: MessageSubtype = .textMessage) {
        self.id = id
        self.senderId = senderId
        self.text = text
        self.timestamp = timestamp
        self.type = type
        self.subtype = subtype
    }
} 