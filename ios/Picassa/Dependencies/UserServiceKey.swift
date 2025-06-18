import Foundation
import ComposableArchitecture

private enum UserServiceKey: DependencyKey {
    static let liveValue = UserService()
}

extension DependencyValues {
    var userService: UserService {
        get { self[UserServiceKey.self] }
        set { self[UserServiceKey.self] = newValue }
    }
} 