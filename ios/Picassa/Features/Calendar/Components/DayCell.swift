import SwiftUI

struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let hasEvents: Bool
    let onTap: () -> Void
    
    private let calendar = Calendar.current
    private let cellSize: CGFloat = 36  // Fixná veľkosť bunky
    
    private var isInPast: Bool {
        date < calendar.startOfDay(for: Date())
    }
    
    var body: some View {
        Button(action: onTap) {
            ZStack {  // Použijeme ZStack pre lepšie zarovnanie
                // Background kruh
                Circle()
                    .fill(isSelected ? Color.blue.opacity(0.2) : Color.clear)
                    .frame(width: cellSize, height: cellSize)
                
                // Obsah
                VStack(spacing: 2) {
                    Text("\(calendar.component(.day, from: date))")
                        .font(.system(.body))
                        .fontWeight(isToday ? .bold : .regular)
                        .foregroundColor(foregroundColor)
                    
                    Circle()
                        .fill(hasEvents ? (isInPast ? Color.gray.opacity(0.5) : .blue) : .clear)
                        .frame(width: 4, height: 4)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 40)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var foregroundColor: Color {
        if isInPast {
            return .gray.opacity(0.5)
        } else if isToday {
            return .blue
        } else {
            return .primary
        }
    }
} 