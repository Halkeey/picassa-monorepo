import Foundation
import ComposableArchitecture

private enum ChatServiceKey: DependencyKey {
    static let liveValue = ChatService()
}

extension DependencyValues {
    var chatService: ChatService {
        get { self[ChatServiceKey.self] }
        set { self[ChatServiceKey.self] = newValue }
    }
} 