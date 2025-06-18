import Foundation
import ComposableArchitecture
import SwiftUI

struct CalendarFeature: Reducer {
    struct State: Equatable {
        var selectedDate: Date?  // Potrebné pre zobrazenie detailu dňa
        var events: IdentifiedArrayOf<Event> = []  // Prázdne pole, budeme načítavať z Firestore
        var isShowingDayDetail: Bool = false
        var selectedEventPath: NavigationPath = NavigationPath()
        var isLoading: Bool = false
        var error: String?
        var hasScrolledToToday: Bool = false  // Pridáme do store
        var currentMonthOffset: Int = 0  // Pridáme sledovanie aktuálneho mesiaca
        var monthRange: ClosedRange<Int> = -12...12  // Fixný rozsah 25 mesiacov
        var referenceDate: Date = Date()
        var eventDetail: EventDetailFeature.State?
        var hasLoadedEvents: Bool = false  // Nový flag
        var currentUser: MyUser?
    }
    
    enum ScrollDirection {
        case forward
        case backward
    }
    
    enum Action {
        case daySelected(Date)
        case dismissDayDetail
        case eventSelected(Event)
        case navigationPathChanged(NavigationPath)
        case showEventDetail(Event)
        case deleteEvent(Event)
        case eventsLoaded([Event])
        case eventError(String)
        case eventDeleted(Event)
        case loadEvents
        case initializeMonthRange
        case eventDetail(EventDetailFeature.Action)
        case eventUpdated(Event)
        case loadEventUsers([Event])
        case eventUsersLoaded(String, [String: User])
        case eventUsersError(String)
        case removeOptimisticEvent(String)
    }
    
    @Dependency(\.eventService) var eventService
    @Dependency(\.userService) var userService
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .daySelected(date):
                state.selectedDate = date
                state.isShowingDayDetail = true
                // Získame všetky eventy pre vybraný deň
                let dayEvents = state.events.elements.filter { event in
                    let selectedStartOfDay = Calendar.current.startOfDay(for: date)
                    let eventStartOfDay = Calendar.current.startOfDay(for: event.date)
                    return selectedStartOfDay == eventStartOfDay
                }
                // Načítame používateľov pre všetky eventy
                return .send(.loadEventUsers(dayEvents))
                
            case .dismissDayDetail:
                state.isShowingDayDetail = false
                return .none
                
            case let .eventSelected(event):
                state.eventDetail = EventDetailFeature.State(
                    event: event,
                    currentUser: state.currentUser
                )
                state.selectedEventPath.append("eventDetail")
                return .none
                
            case let .navigationPathChanged(path):
                state.selectedEventPath = path
                if path.isEmpty {
                    state.eventDetail = nil
                }
                return .none
                
            case let .showEventDetail(event):
                state.isShowingDayDetail = false
                state.eventDetail = EventDetailFeature.State(
                    event: event,
                    currentUser: state.currentUser
                )
                state.selectedEventPath.append("eventDetail")
                return .none
                
            case let .deleteEvent(event):
                return .run { send in
                    do {
                        try await eventService.deleteEvent(event)
                        await send(.eventDeleted(event))
                    } catch {
                        await send(.eventError(error.localizedDescription))
                    }
                }
                
            case let .eventsLoaded(events):
                state.isLoading = false
                state.events = IdentifiedArrayOf(uniqueElements: events)
                state.hasLoadedEvents = true  // Označíme, že máme eventy
                return .none
                
            case let .eventError(message):
                state.isLoading = false
                state.error = message
                return .none
                
            case let .eventDeleted(event):
                state.events.remove(id: event.id)
                state.eventDetail = nil
                state.selectedEventPath = NavigationPath()
                return .none
                
            case .loadEvents:
                if state.hasLoadedEvents { return .none }  // Ak už máme eventy, nič nerobíme
                state.isLoading = true
                return .run { send in
                    do {
                        let events = try await eventService.fetchEvents()
                        await send(.eventsLoaded(events))
                    } catch {
                        await send(.eventError(error.localizedDescription))
                    }
                }
                
            case .initializeMonthRange:
                let calendar = Calendar.current
                let components = calendar.dateComponents([.year, .month], from: Date())
                state.referenceDate = calendar.date(from: components) ?? Date()
                state.monthRange = -12...12  // Fixný rozsah
                return .none
                
            case .eventDetail(.addEvent(let date)):
                let newEvent = Event(
                    title: "",
                    date: date,
                    duration: 3600
                )
                state.eventDetail = EventDetailFeature.State(
                    event: newEvent,
                    isNewEvent: true,
                    currentUser: state.currentUser
                )
                state.selectedEventPath.append("eventDetail")
                return .none
                
            case .eventDetail(.delegate(.createEvent(let event))):
                // Optimisticky pridáme event do UI
                var optimisticEvent = event
                optimisticEvent.id = UUID().uuidString // Dočasné ID
                let optimisticId = optimisticEvent.id! // Uložíme ID do konštanty
                
                state.events.append(optimisticEvent)
                state.eventDetail = EventDetailFeature.State(event: optimisticEvent, currentUser: state.currentUser)
                
                return .run { [optimisticId] send in
                    do {
                        let createdEvent = try await eventService.createEvent(event)
                        // Nahradíme optimistický event skutočným
                        await send(.eventDetail(.eventCreated(createdEvent)))
                    } catch {
                        // V prípade chyby odstránime optimistický event
                        await send(.eventError(error.localizedDescription))
                        await send(.removeOptimisticEvent(optimisticId))
                    }
                }
                
            case .eventDetail(.eventCreated(let event)):
                // Nahradíme optimistický event skutočným
                if let index = state.events.firstIndex(where: { $0.id == event.id }) {
                    state.events[index] = event
                } else {
                    state.events.append(event)
                }
                state.eventDetail = EventDetailFeature.State(event: event, currentUser: state.currentUser)
                return .none
                
            case .eventDetail(.dismissEdit):
                return .none
                
            case .eventDetail(.delegate(.updateEvent(let event))):
                // Optimisticky aktualizujeme UI
                let originalEvent = state.events.first(where: { $0.id == event.id })
                
                if let index = state.events.firstIndex(where: { $0.id == event.id }) {
                    state.events[index] = event
                    state.eventDetail = EventDetailFeature.State(event: event, currentUser: state.currentUser)
                }
                
                // Potom aktualizujeme v Firebase
                return .run { [originalEvent] send in
                    do {
                        try await eventService.updateEvent(event)
                    } catch {
                        // V prípade chyby vrátime pôvodný stav
                        await send(.eventError(error.localizedDescription))
                        if let originalEvent {
                            await send(.eventUpdated(originalEvent))
                        }
                    }
                }
                
            case let .eventUpdated(event):
                // Už nemusíme aktualizovať UI, lebo sme to urobili optimisticky
                return .none
                
            case .eventDetail(.delegate(.deleteEvent(let event))):
                return .run { send in
                    do {
                        try await eventService.deleteEvent(event)
                        await send(.eventDeleted(event))
                    } catch {
                        await send(.eventError(error.localizedDescription))
                    }
                }
                
            case let .loadEventUsers(events):
                // Načítame používateľov pre každý event samostatne
                return .merge(
                    events.compactMap { event in
                        guard 
                            let eventId = event.id,  // Pridáme unwrapping event.id
                            let attendeeIds = event.attendeeIds, 
                            !attendeeIds.isEmpty 
                        else {
                            return .none
                        }
                        
                        return .run { send in
                            do {
                                let users = try await userService.fetchUsers(attendeeIds)
                                await send(.eventUsersLoaded(eventId, users))
                            } catch {
                                await send(.eventUsersError(error.localizedDescription))
                            }
                        }
                    }
                )
                
            case let .eventUsersLoaded(eventId, users):
                // Aktualizujeme event s načítanými používateľmi
                if var event = state.events[id: eventId] {
                    event.attendees = users
                    state.events[id: eventId] = event
                }
                return .none
                
            case let .eventUsersError(message):
                state.isLoading = false
                state.error = message
                return .none
                
            case let .removeOptimisticEvent(id):
                state.events.removeAll { $0.id == id }
                return .none
                
            case .eventDetail:
                return .none
                
            }
        }
        .ifLet(\.eventDetail, action: /Action.eventDetail) {
            EventDetailFeature()
        }
    }
}
