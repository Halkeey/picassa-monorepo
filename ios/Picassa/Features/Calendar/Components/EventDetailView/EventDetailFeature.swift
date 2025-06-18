import Foundation
import ComposableArchitecture

struct EventDetailFeature: Reducer {
    struct State: Equatable {
        var event: Event
        var searchingUsers: [String: User] = [:]
        var searchText = ""
        var isLoading: Bool = false
        var error: String?
        var isEditing: Bool = false
        var isNewEvent: Bool = false
        var isSearching: Bool = false
        var currentUser: MyUser?
        
        init(event: Event, isNewEvent: Bool = false, currentUser: MyUser?) {
            self.event = event
            self.isNewEvent = isNewEvent
            self.currentUser = currentUser
        }
    }
    
    enum Action {
        case editEvent
        case deleteEvent(Event)
        case addEvent(Date)
        case createEvent(Event)
        case updateEvent(Event)
        case eventCreated(Event)
        //case eventUpdated(Event)
        case dismissEdit
        case searchTextChanged(String)
        case userSelected(User)
        case userDeselected(User)
        case searchUsers(String)
        case searchUsersResponse([String: User])
        case searchUsersError(String)
        case delegate(Delegate)
    }
    
    enum Delegate {
        case updateEvent(Event)
        case createEvent(Event)
        case deleteEvent(Event)
    }
    
    @Dependency(\.eventService) var eventService
    @Dependency(\.userService) var userService
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .addEvent:
                state.isEditing = true
                state.isNewEvent = true
                return .none
                
            case let .deleteEvent(event):
                return .send(.delegate(.deleteEvent(event)))
                
            case let .createEvent(event):
                let updatedEvent = Event(
                    id: event.id,
                    title: event.title,
                    description: event.description,
                    date: event.date,
                    duration: event.duration,
                    attendeeIds: event.attendees?.keys.map { $0 } ?? [],
                    attendees: event.attendees,
                    color: event.color,
                    requiresDeposit: event.requiresDeposit ?? false,
                    isDepositPaid: event.isDepositPaid ?? false,
                    depositPrice: event.depositPrice,
                    currency: event.currency ?? "CZK"
                )
                print("DEBUG: Creating event with deposit:", updatedEvent.requiresDeposit, updatedEvent.isDepositPaid, updatedEvent.depositPrice, updatedEvent.currency)
                state.isEditing = false
                state.isNewEvent = false
                return .send(.delegate(.createEvent(updatedEvent)))
                
            case .editEvent:
                state.isEditing = true
                return .none
                
            case .dismissEdit:
                state.isEditing = false
                state.isNewEvent = false
                return .none
                
            case .eventCreated:
                state.isEditing = false
                state.isNewEvent = false
                return .none
                
            case let .updateEvent(event):
                let updatedEvent = Event(
                    id: event.id,
                    title: event.title,
                    description: event.description,
                    date: event.date,
                    duration: event.duration,
                    attendeeIds: event.attendees?.keys.map { $0 } ?? [],
                    attendees: event.attendees,
                    color: event.color,
                    requiresDeposit: event.requiresDeposit ?? false,
                    isDepositPaid: event.isDepositPaid ?? false,
                    depositPrice: event.depositPrice,
                    currency: event.currency ?? "CZK"
                )
                print("DEBUG: Updating event with color:", updatedEvent.color)
                state.isEditing = false
                return .send(.delegate(.updateEvent(updatedEvent)))
                
            case let .searchTextChanged(text):
                state.searchText = text
                state.isSearching = !text.isEmpty
                
                if text.isEmpty || text.count < 3 {
                    state.searchingUsers = [:]
                    return .none
                }
                
                return .run { send in
                    try await Task.sleep(for: .milliseconds(300))
                    await send(.searchUsers(text))
                }
                
            case let .searchUsers(query):
                return .run { send in
                    do {
                        let users = try await userService.searchUsers(query)
                        await send(.searchUsersResponse(users))
                    } catch {
                        await send(.searchUsersError(error.localizedDescription))
                    }
                }
                
            case let .searchUsersResponse(users):
                state.searchingUsers = users
                return .none
                
            case let .searchUsersError(message):
                state.error = message
                return .none
                
            case let .userSelected(user):
                var updatedEvent = state.event
                var attendees = updatedEvent.attendees ?? [:]
                attendees[user.id ?? ""] = user
                updatedEvent.attendees = attendees
                updatedEvent.attendeeIds = Array(attendees.keys)
                state.event = updatedEvent
                
                state.searchText = ""
                state.searchingUsers = [:]
                state.isSearching = false
                return .none
                
            case let .userDeselected(user):
                var updatedEvent = state.event
                var attendees = updatedEvent.attendees ?? [:]
                attendees.removeValue(forKey: user.id ?? "")
                updatedEvent.attendees = attendees
                updatedEvent.attendeeIds = Array(attendees.keys)
                state.event = updatedEvent
                return .none
                
            case .delegate:
            return .none
                // Delegát akcie sa spracuje v rodičovi (CalendarFeature)
            }
        }
    }
}
