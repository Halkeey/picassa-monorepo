import Foundation
import FirebaseFirestore

public struct MyUser: Equatable, Identifiable, Sendable {
    public var id: String?
    public var publicUser: User
    public var privateUser: PrivateUser?
    
    // Computed properties pre jednoduchší prístup k častým hodnotám
    public var name: String { publicUser.name }
    public var avatarUrl: String? { publicUser.avatarUrl }
    public var lengthOfTheWorkingDay: Double { privateUser?.lengthOfTheWorkingDay ?? 8.0 }
    
    public init(publicUser: User, privateUser: PrivateUser? = nil) {
        self.id = publicUser.id
        self.publicUser = publicUser
        self.privateUser = privateUser
    }
} 
