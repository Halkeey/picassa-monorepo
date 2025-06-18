import Foundation
import ComposableArchitecture

private enum AuthServiceKey: DependencyKey {
    static let liveValue = AuthService()
}

extension DependencyValues {
    var authService: AuthService {
        get { self[AuthServiceKey.self] }
        set { self[AuthServiceKey.self] = newValue }
    }
} 