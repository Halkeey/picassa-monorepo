import Foundation
import FirebaseAuth
import FirebaseFirestore

actor AuthService {
    private let auth = Auth.auth()
    private let userService: UserService
    private let privateUserService: PrivateUserService
    
    init(
        userService: UserService = UserService(),
        privateUserService: PrivateUserService = PrivateUserService()
    ) {
        self.userService = userService
        self.privateUserService = privateUserService
    }
    
    var currentUserId: String {
        get throws {
            guard let userId = auth.currentUser?.uid else {
                throw AuthError.notAuthenticated
            }
            return userId
        }
    }
    
    func signIn(email: String, password: String) async throws -> MyUser {
        let userId = try await withUnsafeThrowingContinuation { (continuation: UnsafeContinuation<String, Error>) in
            auth.signIn(withEmail: email, password: password) { result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let userId = result?.user.uid else {
                    continuation.resume(throwing: AuthError.invalidCredentials)
                    return
                }
                continuation.resume(returning: userId)
            }
        }
        return try await getCurrentUser()
    }
    
    func register(email: String, password: String, name: String) async throws -> MyUser {
        let userId = try await withUnsafeThrowingContinuation { (continuation: UnsafeContinuation<String, Error>) in
            auth.createUser(withEmail: email, password: password) { result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let userId = result?.user.uid else {
                    continuation.resume(throwing: AuthError.invalidCredentials)
                    return
                }
                continuation.resume(returning: userId)
            }
        }
        
        // Vytvoríme nového public user
        let newUser = User(
            id: userId,
            name: name,
            avatarUrl: nil,
            nickname: nil
        )
        let createdUser = try await userService.createUser(newUser)
        
        // Vytvoríme nového private user s default hodnotami
        let newPrivateUser = PrivateUser(
            id: userId,
            lengthOfTheWorkingDay: 8.0
        )
        let createdPrivateUser = try await privateUserService.updateUserSettings(newPrivateUser)
        
        return MyUser(publicUser: createdUser, privateUser: createdPrivateUser)
    }
    
    func getCurrentUser() async throws -> MyUser {
        let userId = try currentUserId
        let publicUser = try await userService.fetchUser(id: userId)
        let privateUser = try? await privateUserService.getCurrentUserSettings(userId: userId)
        return MyUser(publicUser: publicUser, privateUser: privateUser)
    }
    
    func signOut() async throws {
        try auth.signOut()
    }
}

enum AuthError: Error {
    case notAuthenticated
    case invalidCredentials
    case unknown
} 
