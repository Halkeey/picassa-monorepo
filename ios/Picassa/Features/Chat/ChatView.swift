import SwiftUI
import ComposableArchitecture

struct ChatView: View {
    let store: StoreOf<ChatFeature>
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            NavigationView {
                ChatListView(store: store)
                    .sheet(
                        item: viewStore.binding(
                            get: \.selectedChat,
                            send: { _ in .dismissChat }
                        )
                    ) { _ in
                        NavigationView {
                            ChatDetailView(store: store)
                        }
                    }
            }
            .onAppear {
                viewStore.send(.onAppear)
            }
        }
    }
}

struct ChatListView: View {
    let store: StoreOf<ChatFeature>
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            List {
                if viewStore.chats.isEmpty {
                    Text("Žiadne chaty")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(viewStore.chats) { chat in
                        Button {
                            viewStore.send(.chatSelected(chat))
                        } label: {
                            ChatListItemView(
                                chat: chat,
                                currentUserId: viewStore.currentUser?.id,
                                participants: viewStore.participants
                            )
                        }
                    }
                }
            }
            .navigationTitle("Chaty")
            .overlay {
                if viewStore.isLoading {
                    ProgressView()
                }
            }
            .onChange(of: viewStore.chats) { _ in
                // Zajistíme, že sa zoznam prekreslí pri zmene chatov
                withAnimation {
                    // Prázdny blok, len pre spustenie animácie
                }
            }
        }
    }
}

struct ChatListItemView: View {
    let chat: Chat
    let currentUserId: String?
    let participants: [String: User]
    
    var daysToNextEvent: Int? {
        guard let events = chat.events,
              !events.isEmpty else { return nil }
        
        let now = Date()
        let nextEvent = events
            .filter { $0.date > now }
            .min { $0.date < $1.date }
        
        guard let eventDate = nextEvent?.date else { return nil }
        
        // Nastavíme začiatok dňa pre oba dátumy
        let calendar = Calendar.current
        let nowStartOfDay = calendar.startOfDay(for: now)
        let eventStartOfDay = calendar.startOfDay(for: eventDate)
        
        // Vypočítame rozdiel v dňoch
        let days = calendar.dateComponents([.day], from: nowStartOfDay, to: eventStartOfDay).day ?? 0
        
        // Ak je event dnes, vrátime 0
        if days == 0 && eventDate > now {
            return 0
        }
        
        return days
    }
    
    private var isUnread: Bool {
        guard let lastMessage = chat.lastMessage,
              lastMessage.type == .general else { return false }
        
        // Správa je neprečítaná len ak je od iného používateľa
        return lastMessage.senderId != currentUserId
    }
    
    private var lastMessageText: String? {
        guard let lastMessage = chat.lastMessage,
              lastMessage.type == .general,
              lastMessage.subtype == .textMessage else { return nil }
        return lastMessage.text
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(chat.participantIds
                    .filter { $0 != currentUserId }
                    .compactMap { id in
                        participants[id]?.name ?? id
                    }
                    .joined(separator: ", "))
                    .font(.headline)
                if let text = lastMessageText {
                    Text(text)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            if isUnread {
                Circle()
                    .fill(Color.red)
                    .frame(width: 10, height: 10)
            }
            
            if chat.eventIds?.isEmpty == false {
                VStack(alignment: .center) {
                    Image(systemName: "calendar")
                        .foregroundColor(.blue)
                    
                    if let days = daysToNextEvent {
                        Text("\(days)d")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .contentShape(Rectangle())
    }
}

struct ParticipantView: View {
    let user: User?
    let isLarge: Bool
    
    var body: some View {
        if isLarge {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    avatarView
                        .frame(width: 48, height: 48)
                    
                    Text(user?.name ?? "Unknown")
                        .font(.headline)
                        .lineLimit(1)
                }
                .padding(.leading)
                
                Spacer()
                
                Button {
                    // TODO: Akcia pre kalendár
                } label: {
                    Image(systemName: "calendar")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                .padding(.trailing)
            }
        } else {
            // Horizontálny layout pre viacerých participantov
            HStack(spacing: 8) {
                avatarView
                    .frame(width: 32, height: 32)
                
                Text(user?.name ?? "Unknown")
                    .font(.headline)
                    .lineLimit(1)
            }
        }
    }
    
    private var avatarView: some View {
        Group {
            if let avatarUrl = user?.avatarUrl {
                AsyncImage(url: URL(string: avatarUrl)) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(.gray)
                }
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .foregroundColor(.gray)
            }
        }
        .clipShape(Circle())
    }
}

struct ChatDetailView: View {
    let store: StoreOf<ChatFeature>
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            VStack {
                let filteredParticipants = viewStore.selectedChat?.participantIds
                    .filter { $0 != viewStore.currentUser?.id } ?? []
                
                if filteredParticipants.count == 1 {
                    // Jeden participant - vertikálny layout
                    ParticipantView(
                        user: viewStore.participants[filteredParticipants[0]],
                        isLarge: true
                    )
                    .padding(.vertical, 8)
                } else {
                    // Viacero participantov - horizontálny scrollovateľný layout
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(filteredParticipants, id: \.self) { participantId in
                                ParticipantView(
                                    user: viewStore.participants[participantId],
                                    isLarge: false
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    .frame(height: 60)
                }
                
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack {
                            ForEach(viewStore.messages) { message in
                                MessageBubble(
                                    message: message,
                                    currentUserId: viewStore.currentUser?.id
                                )
                                .padding(.horizontal)
                                .id(message.id)
                            }
                        }
                        .padding(.vertical)
                    }
                    .onChange(of: viewStore.messages) { _ in
                        if let lastMessageId = viewStore.messages.last?.id {
                            withAnimation {
                                proxy.scrollTo(lastMessageId, anchor: .bottom)
                            }
                        }
                    }
                    .onAppear {
                        if let lastMessageId = viewStore.messages.last?.id {
                            withAnimation {
                                proxy.scrollTo(lastMessageId, anchor: .bottom)
                            }
                        }
                    }
                }
                
                HStack {
                    TextField("Správa", text: viewStore.binding(
                        get: \.newMessageText,
                        send: ChatFeature.Action.newMessageChanged
                    ))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onSubmit {
                        if !viewStore.newMessageText.isEmpty {
                            viewStore.send(.sendMessageTapped)
                        }
                    }
                    .submitLabel(.send)
                    
                    Button {
                        viewStore.send(.sendMessageTapped)
                    } label: {
                        Image(systemName: "paperplane.fill")
                    }
                    .disabled(viewStore.newMessageText.isEmpty)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)  // Zmenené na inline
            .navigationBarItems(trailing: Button("Zavrieť") {
                viewStore.send(.dismissChat)
            })
            .overlay {
                if viewStore.isLoading {
                    ProgressView()
                }
            }
        }
    }
}

struct MessageBubble: View {
    let message: Message
    let currentUserId: String?
    
    init(message: Message, currentUserId: String?) {
        self.message = message
        self.currentUserId = currentUserId
    }
    
    private var shouldShowReadReceipt: Bool {
        message.type == .system && 
        message.subtype == .readReceipt && 
        message.senderId == currentUserId
    }
    
    var body: some View {
        HStack {
            if message.senderId == currentUserId {
                Spacer()
            }
            
            switch message.type {
            case .general:
                switch message.subtype {
                case .textMessage:
                    Text(message.text)
                        .padding()
                        .background(
                            message.senderId == currentUserId 
                            ? Color.blue 
                            : Color(.systemGray5)
                        )
                        .foregroundColor(
                            message.senderId == currentUserId 
                            ? .white 
                            : .primary
                        )
                        .cornerRadius(15)
                case .filesMessage:
                    HStack {
                        Image(systemName: "paperclip")
                        Text("Súbory")
                    }
                    .padding()
                    .background(
                        message.senderId == currentUserId 
                        ? Color.blue 
                        : Color(.systemGray5)
                    )
                    .foregroundColor(
                        message.senderId == currentUserId 
                        ? .white 
                        : .primary
                    )
                    .cornerRadius(15)
                case .readReceipt:
                    if shouldShowReadReceipt {
                        Text("Prečítané")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            case .system:
                if shouldShowReadReceipt {
                    Text("Prečítané")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if message.senderId != currentUserId {
                Spacer()
            }
        }
    }
} 
