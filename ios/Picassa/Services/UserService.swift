import Foundation
import FirebaseFirestore

actor UserService {
    private let firestoreService: FirestoreService<User>
    
    init() {
        self.firestoreService = FirestoreService<User>(collection: "users")
    }
    
    func createUser(_ user: User) async throws -> User {
        try await firestoreService.create(user)
    }
    
    func fetchUser(id: String) async throws -> User {
        try await firestoreService.read(id: id)
    }
    
    func updateUser(_ user: User) async throws -> User {
        try await firestoreService.update(user)
        return user
    }
    
    func fetchUsers(_ ids: [String]) async throws -> [String: User] {
        var users: [String: User] = [:]
        
        for id in ids {
            do {
                let user = try await firestoreService.read(id: id)
                users[id] = user
            } catch {
                print("Failed to fetch user with id: \(id), error: \(error)")
                continue
            }
        }
        
        return users
    }
    
    func searchUsers(_ searchText: String) async throws -> [String: User] {
        print("Searching for users with query: \(searchText)")
        
        do {
            let users = try await firestoreService.query { queryRef in
                queryRef
                    .whereField("name", isGreaterThanOrEqualTo: searchText)
                    .limit(to: 10)
            }
            return Dictionary(uniqueKeysWithValues: users.map { ($0.id ?? "", $0) })
        } catch {
            print("❌ Search error: \(error)")
            throw error
        }
    }
} 
