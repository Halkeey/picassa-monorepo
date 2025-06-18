import SwiftUI
import ComposableArchitecture

struct CalendarView: View {
    let store: StoreOf<CalendarFeature>
    @State private var shouldScroll = true  // Pridáme state pre kontrolu scrollovania
    @State private var loadedOffsets: Set<Int> = []  // Sledujeme, ktoré offsety sme už načítali
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            let _ = print("Calendar store", viewStore.currentUser)
            NavigationStack(path: viewStore.binding(
                get: \.selectedEventPath,
                send: CalendarFeature.Action.navigationPathChanged
            )) {
                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: false) {
                        if viewStore.isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            LazyVStack(spacing: 32) {
                                ForEach(viewStore.monthRange, id: \.self) { monthOffset in
                                    let date = Calendar.current.date(
                                        byAdding: .month,
                                        value: monthOffset,
                                        to: viewStore.referenceDate
                                    ) ?? Date()
                                    
                                    VerticalMonthView(
                                        baseDate: date,
                                        selectedDate: viewStore.binding(
                                            get: \.selectedDate,
                                            send: { .daySelected($0 ?? Date()) }
                                        ),
                                        events: viewStore.events.elements
                                    )
                                    .id(monthOffset)
                                }
                            }
                            .padding()
                            .task {
                                try? await Task.sleep(nanoseconds: 100_000_000)
                                proxy.scrollTo(0, anchor: .top)
                            }
                        }
                    }
                    .task {
                        viewStore.send(.initializeMonthRange)
                        if !viewStore.hasLoadedEvents {  // Načítame len ak ešte nemáme
                            viewStore.send(.loadEvents)
                        }
                    }
                }
                .sheet(isPresented: viewStore.binding(
                    get: \.isShowingDayDetail,
                    send: CalendarFeature.Action.dismissDayDetail
                )) {
                    DayDetailView(
                        date: viewStore.selectedDate ?? Date(),
                        events: viewStore.events
                            .elements
                            .filter { event in
                                let selectedStartOfDay = Calendar.current.startOfDay(for: viewStore.selectedDate ?? Date())
                                let eventStartOfDay = Calendar.current.startOfDay(for: event.date)
                                return selectedStartOfDay == eventStartOfDay
                            },
                        onEventSelected: { event in
                            viewStore.send(.showEventDetail(event))
                        },
                        onAddEvent: {
                            viewStore.send(.dismissDayDetail)
                            viewStore.send(.eventDetail(.addEvent(viewStore.selectedDate ?? Date())))
                        }
                    )
                    .navigationTitle(formatDate(viewStore.selectedDate ?? Date()))
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(String(localized: "calendar.close")) {
                                viewStore.send(.dismissDayDetail)
                            }
                        }
                    }
                    .presentationDetents([.medium])
                    .presentationBackground(.background)
                    .presentationBackgroundInteraction(.enabled)
                    .presentationDragIndicator(.visible)
                }
                .navigationDestination(
                    for: String.self,
                    destination: { path in
                        if path == "eventDetail", let eventDetail = viewStore.eventDetail {
                            EventDetailView(
                                store: store.scope(
                                    state: { _ in eventDetail },
                                    action: CalendarFeature.Action.eventDetail
                                )
                            )
                        }
                    }
                )
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.locale = Locale(identifier: "sk_SK")
        return formatter.string(from: date)
    }
}

// Pomocná štruktúra pre sledovanie pozície mesiaca
private struct MonthOffsetPreferenceKey: PreferenceKey {
    nonisolated static let defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
