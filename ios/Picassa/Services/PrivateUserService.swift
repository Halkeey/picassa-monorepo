import Foundation
import FirebaseFirestore

actor PrivateUserService {
    private let firestoreService: FirestoreService<PrivateUser>
    
    init() {
        self.firestoreService = FirestoreService<PrivateUser>(collection: "privateUsers")
    }
    
    func getCurrentUserSettings(userId: String) async throws -> PrivateUser {
        print("📍 Fetching private user settings for userId: \(userId)")
        do {
            let privateUser = try await firestoreService.read(id: userId)
            print("✅ Successfully fetched private user: \(privateUser)")
            return privateUser
        } catch {
            print("❌ Error fetching private user: \(error)")
            throw error
        }
    }
    
    func updateUserSettings(_ settings: PrivateUser) async throws -> PrivateUser {
        print("📝 Updating private user settings: \(settings)")
        if settings.id == nil {
            let createdUser = try await firestoreService.create(settings)
            print("✅ Created new private user: \(createdUser)")
            return createdUser
        } else {
            try await firestoreService.update(settings)
            print("✅ Updated existing private user: \(settings)")
            return settings
        }
    }
} 