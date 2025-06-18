import SwiftUI
import ComposableArchitecture

struct UserSearchView: View {
    let store: StoreOf<EventDetailFeature>
    @FocusState private var isFocused: Bool
    
    private func filteredUsers(_ viewStore: ViewStore<EventDetailFeature.State, EventDetailFeature.Action>) -> [User] {
        if viewStore.searchText.isEmpty {
            return []
        }
        return Array(viewStore.searchingUsers.values).filter { 
            $0.name.lowercased().contains(viewStore.searchText.lowercased()) 
        }
    }
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            VStack(alignment: .leading, spacing: 16) {
                // Horný riadok s vybranými používateľmi
                if let attendees = viewStore.event.attendees, !attendees.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(Array(attendees.values)) { user in
                                SelectedUserChip(
                                    user: user,
                                    onRemove: {
                                        viewStore.send(.userDeselected(user))
                                    }
                                )
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                // Search input vždy viditeľný pod zoznamom
                HStack {
                    TextField("Vyhľadať používateľov...", text: viewStore.binding(
                        get: \.searchText,
                        send: EventDetailFeature.Action.searchTextChanged
                    ))
                    .focused($isFocused)
                    
                    if !viewStore.searchText.isEmpty {
                        Button(action: {
                            viewStore.send(.searchTextChanged(""))
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.vertical, 12)
                .padding(.horizontal)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(10)
                .padding(.horizontal)
                
                // Výsledky vyhľadávania
                if !filteredUsers(viewStore).isEmpty {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 4) {
                            ForEach(filteredUsers(viewStore)) { user in
                                SearchResultRow(
                                    user: user,
                                    isSelected: viewStore.event.attendees?[user.id ?? ""] != nil,
                                    onTap: {
                                        if viewStore.event.attendees?[user.id ?? ""] != nil {
                                            viewStore.send(.userDeselected(user))
                                        } else {
                                            viewStore.send(.userSelected(user))
                                        }
                                        viewStore.send(.searchTextChanged(""))
                                    }
                                )
                                if user.id != filteredUsers(viewStore).last?.id {
                                    Divider()
                                        .padding(.leading)
                                }
                            }
                        }
                    }
                    .frame(maxHeight: 250)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    )
                    .padding(.horizontal)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Pomocné komponenty
private struct SelectedUserChip: View {
    let user: User
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            // Avatar
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
            .frame(width: 40, height: 40)
            .clipShape(Circle())
            
            // Meno
            Text(user.name)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            // Tlačidlo na odstránenie
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
                    .font(.system(size: 20))
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(20)
    }
}

private struct SearchResultRow: View {
    let user: User
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(user.name)
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .accentColor : .secondary)
            }
            .contentShape(Rectangle())
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
    }
}
