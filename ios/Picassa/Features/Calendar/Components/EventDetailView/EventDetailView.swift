import SwiftUI
import ComposableArchitecture

struct EventDetailView: View {
    let store: StoreOf<EventDetailFeature>
    @State private var showingDeleteAlert = false
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            if viewStore.isEditing || viewStore.isNewEvent {
                EditEventView(
                    event: viewStore.event,
                    onSave: { event in
                        if viewStore.isNewEvent {
                            viewStore.send(.createEvent(event))
                        } else {
                            viewStore.send(.updateEvent(event))
                        }
                    },
                    onCancel: {
                        viewStore.send(.dismissEdit)
                    },
                    store: store
                )
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Hlavička
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(alignment: .top) {
                                Text(viewStore.event.title)
                                    .font(.title)
                                    .bold()
                                
                                Spacer()
                                
                                HStack {
                                    Image(systemName: "timer")
                                        .font(.system(size: 24))
                                    Text(formatDuration(viewStore.event.duration))
                                        .font(.title2)
                                }
                                .foregroundColor(.secondary)
                            }
                            
                            // Čas a dátum
                            HStack(alignment: .center, spacing: 24) {
                                // Dátum
                                HStack {
                                    Image(systemName: "calendar")
                                        .font(.system(size: 24))
                                    Text(formatDate(viewStore.event.date))
                                        .font(.title2)
                                }
                                
                                Spacer()
                                
                                // Čas
                                HStack {
                                    Image(systemName: "clock")
                                        .font(.system(size: 24))
                                    Text(formatTime(viewStore.event.date))
                                        .font(.title2)
                                }
                            }
                            .foregroundColor(.secondary)
                        }

                        // Upravený divider s farbou eventu
                        Rectangle()
                            .fill(viewStore.event.color.color.opacity(0.8))
                            .frame(height: 2)

                        // Účastníci
                        if let attendees = viewStore.event.attendees, !attendees.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(String(localized: "event.attendees"))
                                    .font(.headline)
                                
                                UserHorizontalListView(
                                    users: Array(attendees.values)
                                )
                            }
                            
                            Divider()
                        }
                        
                        // Kontakt sekcia
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 12) {
                                Spacer()
                                Button {
                                    // Chat logika
                                } label: {
                                    VStack {
                                        Image(systemName: "message.fill")
                                            .font(.system(size: 24))
                                        Text(String(localized: "event.contact.chat"))
                                            .font(.caption)
                                    }
                                }
                                Spacer()
                                Button {
                                    // Phone logika
                                } label: {
                                    VStack {
                                        Image(systemName: "phone.fill")
                                            .font(.system(size: 24))
                                        Text(String(localized: "event.contact.call"))
                                            .font(.caption)
                                    }
                                }
                                Spacer()
                                Button {
                                    // Notifications logika
                                } label: {
                                    VStack {
                                        Image(systemName: "bell.fill")
                                            .font(.system(size: 24))
                                        Text(String(localized: "event.contact.notifications"))
                                            .font(.caption)
                                    }
                                }
                                Spacer()
                            }
                            .foregroundColor(.accentColor)
                        }
                        
                        if viewStore.event.requiresDeposit ?? false {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Záloha")
                                    .font(.headline)
                                
                                HStack {
                                    Image(systemName: viewStore.event.isDepositPaid ?? false ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(viewStore.event.isDepositPaid ?? false ? .green : .orange)
                                    Text(viewStore.event.isDepositPaid ?? false ? "Záloha zaplatená" : "Záloha nezaplatená")
                                        .foregroundColor(viewStore.event.isDepositPaid ?? false ? .green : .orange)
                                    Spacer()
                                    if let price = viewStore.event.depositPrice {
                                        Text(PriceFormatter.format(price, currency: viewStore.event.currency ?? "CZK"))
                                            .bold()
                                    }
                                }
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(10)
                            }
                            
                            Divider()
                        }
                        
                        // Popis
                        if !(viewStore.event.description?.isEmpty ?? true) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(LocalizedString.Calendar.description.localized())
                                    .font(.headline)
                                Text(viewStore.event.description ?? "")
                                    .foregroundColor(.secondary)
                            }
                        }

                        Button(role: .destructive) {
                            showingDeleteAlert = true
                        } label: {
                            HStack {
                                Spacer()
                                Image(systemName: "trash")
                                Text(LocalizedString.Calendar.delete.localized())
                                Spacer()
                            }
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(10)
                        }
                        .padding(.top)
                        .alert("Vymazať udalosť?", isPresented: $showingDeleteAlert) {
                            Button("Zrušiť", role: .cancel) { }
                            Button("Vymazať", role: .destructive) {
                                viewStore.send(.deleteEvent(viewStore.event))
                            }
                        } message: {
                            Text("Naozaj chcete vymazať udalosť '\(viewStore.event.title)'?")
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            viewStore.send(.editEvent)
                        } label: {
                            Label(LocalizedString.Calendar.edit.localized(), systemImage: "pencil")
                        }
                    }
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d. M. yyyy"
        formatter.locale = Locale(identifier: "sk_SK")
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
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
        return "\(hours)h \(minutes)m"
    }
} 
