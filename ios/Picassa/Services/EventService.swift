import Foundation
import FirebaseFirestore

actor EventService {
    private let firestoreService: FirestoreService<Event>
    
    init() {
        self.firestoreService = FirestoreService<Event>(collection: "events")
    }
    
    func createEvent(_ event: Event) async throws -> Event {
        try await firestoreService.create(event)
    }
    
    func updateEvent(_ event: Event) async throws {
        try await firestoreService.update(event)
    }
    
    func deleteEvent(_ event: Event) async throws {
        guard let id = event.id else {
            throw FirestoreError.missingId
        }
        try await firestoreService.delete(id: id)
    }
    
    func fetchEvents() async throws -> [Event] {
        let events = try await firestoreService.list()
        return events.sorted { $0.date < $1.date }
    }
    
    func fetchEventsByIds(_ ids: [String]) async throws -> [Event] {
        let events = try await firestoreService.list()
        return events.filter { event in
            guard let eventId = event.id else { return false }
            return ids.contains(eventId)
        }
    }
} 