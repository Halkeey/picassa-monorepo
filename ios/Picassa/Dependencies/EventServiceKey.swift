import Foundation
import Dependencies

private enum EventServiceKey: DependencyKey {
    static let liveValue = EventService()
}

extension DependencyValues {
    var eventService: EventService {
        get { self[EventServiceKey.self] }
        set { self[EventServiceKey.self] = newValue }
    }
} 