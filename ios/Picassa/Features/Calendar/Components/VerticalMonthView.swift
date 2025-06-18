import SwiftUI

struct VerticalMonthView: View {
    let baseDate: Date
    @Binding var selectedDate: Date?
    let events: [Event]
    
    private let calendar = Calendar.current
    private let daysInWeek = 7
    
    init(baseDate: Date, selectedDate: Binding<Date?>, events: [Event]) {
        // Zabezpečíme, že baseDate je prvý deň mesiaca
        let components = calendar.dateComponents([.year, .month], from: baseDate)
        self.baseDate = calendar.date(from: components) ?? baseDate
        self._selectedDate = selectedDate
        self.events = events
    }
    
    private let daysInWeekLocalized = [
        String(localized: "calendar.weekday.monday"),
        String(localized: "calendar.weekday.tuesday"),
        String(localized: "calendar.weekday.wednesday"),
        String(localized: "calendar.weekday.thursday"),
        String(localized: "calendar.weekday.friday"),
        String(localized: "calendar.weekday.saturday"),
        String(localized: "calendar.weekday.sunday")
    ]
    
    var body: some View {
        VStack(spacing: 12) {
            Text(monthYearString(from: baseDate))
                .font(.title3)
                .fontWeight(.medium)
            
            VStack(spacing: 8) {
                HStack {
                    ForEach(daysInWeekLocalized, id: \.self) { day in
                        Text(day)
                            .font(.caption)
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.gray)
                    }
                }
                
                VStack(spacing: 4) {
                    ForEach(weeksInMonth().indices, id: \.self) { weekIndex in
                        let week = weeksInMonth()[weekIndex]
                        HStack {
                            ForEach(week.indices, id: \.self) { dayIndex in
                                let date = week[dayIndex]
                                if let date = date {
                                    DayCell(
                                        date: date,
                                        isSelected: selectedDate.map { calendar.isDate($0, inSameDayAs: date) } ?? false,
                                        isToday: calendar.isDateInToday(date),
                                        hasEvents: hasEvents(for: date),
                                        onTap: { selectedDate = date }
                                    )
                                } else {
                                    Color.clear
                                        .frame(maxWidth: .infinity)
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(.vertical)
    }
    
    private func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = Locale(identifier: "sk_SK")
        return formatter.string(from: date)
    }
    
    private func weeksInMonth() -> [[Date?]] {
        guard let interval = calendar.dateInterval(of: .month, for: baseDate),
              let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: interval.start))
        else { return [] }
        
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        let offsetDays = (firstWeekday + 5) % 7 // Upravené pre slovenský kalendár (Pondelok = 1)
        
        let daysInMonth = calendar.range(of: .day, in: .month, for: firstDayOfMonth)?.count ?? 0
        
        var days: [Date?] = Array(repeating: nil, count: offsetDays)
        
        for day in 1...daysInMonth {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDayOfMonth) {
                days.append(date)
            }
        }
        
        while days.count % 7 != 0 {
            days.append(nil)
        }
        
        return stride(from: 0, to: days.count, by: 7).map {
            Array(days[$0..<min($0 + 7, days.count)])
        }
    }
    
    private func hasEvents(for date: Date) -> Bool {
        let startOfDay = calendar.startOfDay(for: date)
        return events.contains { event in
            let eventStartOfDay = calendar.startOfDay(for: event.date)
            return startOfDay == eventStartOfDay
        }
    }
}
