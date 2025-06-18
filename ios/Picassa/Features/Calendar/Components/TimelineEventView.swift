import SwiftUI

struct TimelineEventView: View {
    let event: Event
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(event.title)
                .font(.callout)
                .bold()
            
            Text(event.description ?? "")
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .frame(width: 160)
        .padding(8)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(8)
        .onTapGesture(perform: onTap)
    }
} 
