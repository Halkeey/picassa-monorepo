import SwiftUI

struct EventRowView: View {
    let event: Event
    
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            // Časový stĺpec
            VStack(alignment: .center, spacing: 4) {
                Text(formatEventTime(event.date))
                    .font(.system(.headline, design: .rounded))
                    .foregroundColor(.primary)
                
                Text(formatDuration(event.duration))
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.secondary)
            }
            .frame(width: 60)
            .frame(maxHeight: .infinity, alignment: .center)
            
            // Vertikálna čiara
            Rectangle()
                .fill(event.color.color.opacity(0.8))
                .frame(width: 2)
                .frame(maxHeight: .infinity)
            
            // Hlavný obsah
            VStack(alignment: .leading, spacing: 6) {
                // Horná časť s textom a účastníkmi
                HStack(alignment: .top) {
                    // Názov a popis
                    VStack(alignment: .leading, spacing: 6) {
                        Text(event.title)
                            .font(.system(.headline, design: .rounded))
                            .foregroundColor(.primary)
                        
                        if !(event.description?.isEmpty ?? true) {
                            Text(event.description ?? "")
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                    }
                    
                    Spacer()
                    
                    // Účastníci v pravom hornom rohu
                    if let attendees = event.attendees, !attendees.isEmpty {
                        HStack(spacing: -8) {
                            ForEach(Array(attendees.values).prefix(3)) { user in
                                UserAvatar(user: user, size: 24)
                            }
                            if attendees.count > 3 {
                                Text("+\(attendees.count - 3)")
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundColor(.secondary)
                                    .padding(.leading, 12)
                            }
                        }
                    }
                }
                
                Spacer(minLength: 8)
                
                // Záloha (ak existuje)
                if event.requiresDeposit ?? false {
                    HStack {
                        Image(systemName: event.isDepositPaid ?? false ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(event.isDepositPaid ?? false ? .green : .orange)
                        Text(event.isDepositPaid ?? false ? "Záloha zaplatená" : "Záloha nezaplatená")
                            .font(.caption)
                            .foregroundColor(event.isDepositPaid ?? false ? .green : .orange)
                        if let depositPrice = event.depositPrice {
                            Text(PriceFormatter.format(depositPrice, currency: event.currency ?? "CZK"))
                                .font(.caption)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func formatEventTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60
        if minutes == 0 {
            return "\(hours)h"
        }
        return "\(hours)h\n\(minutes)m"  // Nový riadok pre minúty
    }
}

private struct UserAvatar: View {
    let user: User
    let size: CGFloat
    
    var body: some View {
        Group {
            if let url = user.avatarUrl {
                AsyncImage(url: URL(string: url)) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    ProgressView()
                }
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .foregroundColor(.gray)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .background(
            Circle()
                .fill(Color(.systemBackground))
                .padding(-2)
        )
    }
} 
