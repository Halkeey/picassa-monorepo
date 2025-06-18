import SwiftUI

struct DayDetailView: View {
    let date: Date
    let events: [Event]
    let onEventSelected: (Event) -> Void
    let onAddEvent: () -> Void
    
    @State private var selectedView = ViewType.agenda
    
    enum ViewType {
        case agenda
        case timeline
        
        var title: String {
            switch self {
            case .agenda: return String(localized: "view.agenda")
            case .timeline: return String(localized: "view.timeline")
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Prepínač zobrazenia
            HStack {
                Picker("View", selection: $selectedView) {
                    Text(ViewType.agenda.title).tag(ViewType.agenda)
                    Text(ViewType.timeline.title).tag(ViewType.timeline)
                }
                .pickerStyle(.segmented)
                
                Button(action: onAddEvent) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                }
                .padding(.leading, 8)
            }
            .padding()
            
            if events.isEmpty {
                // Prázdny stav
                VStack(spacing: 16) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text(LocalizedString.Calendar.noEvents.localized())
                        .font(.system(.headline, design: .rounded))
                    Text(LocalizedString.Calendar.noEventsDescription.localized())
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                // Zoznam eventov
                switch selectedView {
                case .agenda:
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(events) { event in
                                EventRowView(event: event)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        onEventSelected(event)
                                    }
                            }
                        }
                        .padding()
                    }
                case .timeline:
                    TimelineView(
                        events: events,
                        onEventSelected: onEventSelected,
                        date: date
                    )
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func formatDayName(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        formatter.locale = Locale(identifier: "sk_SK")
        return formatter.string(from: date).capitalized
    }
    
    private func formatDayNumber(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d. MMMM yyyy"
        formatter.locale = Locale(identifier: "sk_SK")
        return formatter.string(from: date)
    }
} 