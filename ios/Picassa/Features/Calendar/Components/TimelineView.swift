import SwiftUI

struct TimelineView: View {
    let events: [Event]
    let onEventSelected: (Event) -> Void
    let date: Date
    
    private let hourHeight: CGFloat = 60
    @State private var currentTime = Date()
    @State private var hasScrolledToCurrentTime = false
    let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    
    private var timelineStart: Date {
        Calendar.current.startOfDay(for: date)
    }
    
    var sortedEvents: [Event] {
        events.sorted { $0.date < $1.date }
    }
    
    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                ZStack(alignment: .topLeading) {
                    // Vertikálne čiary a hodiny
                    VStack(spacing: 0) {
                        ForEach(0..<24, id: \.self) { hour in
                            VStack(alignment: .leading) {
                                HStack {
                                    Text(String(format: "%02d:00", hour))
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                        .frame(width: 40)
                                    
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(height: 1)
                                }
                                Spacer()
                            }
                            .frame(height: hourHeight)
                            .id("hour-\(hour)")
                        }
                    }
                    
                    // Udalosti
                    ForEach(sortedEvents) { event in
                        TimelineEventView(event: event, onTap: { onEventSelected(event) })
                            .position(
                                x: 120,
                                y: yPosition(for: event.date) + (eventHeight(for: event.duration) / 2)
                            )
                    }
                    
                    // Aktuálny čas
                    if isToday {
                        HStack(spacing: 4) {
                            Text(formatTime(currentTime))
                                .font(.caption)
                                .foregroundColor(.red)
                                .frame(width: 40)
                            
                            Rectangle()
                                .fill(Color.red)
                                .frame(height: 2)
                        }
                        .offset(y: yPosition(for: currentTime))
                        .id("currentTime")
                    }
                }
                .padding()
            }
            .onAppear {
                if isToday && !hasScrolledToCurrentTime {
                    let currentHour = Calendar.current.component(.hour, from: currentTime)
                    proxy.scrollTo("hour-\(max(0, currentHour - 1))", anchor: .top)
                    hasScrolledToCurrentTime = true
                }
            }
            .onReceive(timer) { time in
                currentTime = time
            }
        }
    }
    
    private func yPosition(for date: Date) -> CGFloat {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: timelineStart, to: date)
        let hours = Double(components.hour ?? 0)
        let minutes = Double(components.minute ?? 0)
        return hourHeight * CGFloat(hours + minutes / 60)
    }
    
    private func eventHeight(for duration: TimeInterval) -> CGFloat {
        let hours = duration / 3600
        return hourHeight * CGFloat(hours)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
} 