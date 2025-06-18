import Foundation
import ComposableArchitecture

private enum PrivateUserServiceKey: DependencyKey {
    static let liveValue = PrivateUserService()
}

extension DependencyValues {
    var privateUserService: PrivateUserService {
        get { self[PrivateUserServiceKey.self] }
        set { self[PrivateUserServiceKey.self] = newValue }
    }
} 