import Foundation
import FirebaseFirestore

public struct User: Equatable, FirestoreSerializable, Identifiable, Sendable {
    public var id: String?
    public let name: String
    public let avatarUrl: String?
    public let nickname: String?
    
    public enum CodingKeys: String, CodingKey {
        case id
        case name
        case avatarUrl
        case nickname
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(avatarUrl, forKey: .avatarUrl)
        try container.encodeIfPresent(nickname, forKey: .nickname)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String?.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        avatarUrl = try container.decodeIfPresent(String.self, forKey: .avatarUrl)
        nickname = try container.decodeIfPresent(String.self, forKey: .nickname)
    }
    
    public init(id: String? = nil, name: String, avatarUrl: String? = nil, nickname: String? = nil) {
        self.id = id
        self.name = name
        self.avatarUrl = avatarUrl
        self.nickname = nickname
    }
} 
