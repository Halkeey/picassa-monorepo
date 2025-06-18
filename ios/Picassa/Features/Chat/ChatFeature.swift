import Foundation
import ComposableArchitecture
import FirebaseFirestore



struct ChatFeature: Reducer {
    struct State: Equatable, Sendable {
        var chats: [Chat] = []
        var selectedChat: Chat?
        var messages: [Message] = []
        var newMessageText: String = ""
        var isLoading = false
        var error: String?
        var currentUser: MyUser?
        var participants: [String: User] = [:]
        var messageListener: SendableListenerRegistration?
        var chatListener: SendableListenerRegistration?
        
        static func == (lhs: State, rhs: State) -> Bool {
            lhs.chats == rhs.chats &&
            lhs.selectedChat == rhs.selectedChat &&
            lhs.messages == rhs.messages &&
            lhs.newMessageText == rhs.newMessageText &&
            lhs.isLoading == rhs.isLoading &&
            lhs.error == rhs.error &&
            lhs.currentUser == rhs.currentUser &&
            lhs.participants == rhs.participants
            // messageListener a chatListener sú vynechané z porovnávania, keďže nie sú relevantné pre UI stav
        }
    }
    
    enum Action {
        case onAppear
        case chatsResponse(TaskResult<[Chat]>)
        case chatSelected(Chat)
        case messagesResponse(TaskResult<[Message]>)
        case newMessageChanged(String)
        case sendMessageTapped
        case messageSent(TaskResult<Message>)
        case chatUpdated(Chat)
        case dismissChat
        case participantsLoaded(String, [String: User])
        case chatsUpdatedWithEvents([Chat])
        case removeOptimisticMessage(String)
        case messagesUpdated([Message])
        case setMessageListener(SendableListenerRegistration)
        case setChatListener(SendableListenerRegistration)
        case chatsUpdated([Chat])
    }
    
    @Dependency(\.chatService) private var chatService
    @Dependency(\.authService) private var authService
    @Dependency(\.userService) private var userService
    @Dependency(\.eventService) private var eventService
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard let userId = state.currentUser?.id else {
                    print("DEBUG: No currentUser in ChatFeature")
                    return .none 
                }
                
                print("DEBUG: Loading chats for user:", userId)
                state.isLoading = true
                return .run { send in
                    do {
                        let chats = try await chatService.fetchChats(for: userId)
                        
                        let allParticipantIds = Set(chats.flatMap { $0.participantIds })
                        
                        let users = try await userService.fetchUsers(Array(allParticipantIds))
                        
                        await send(.participantsLoaded("", users))
                        await send(.chatsResponse(.success(chats)))
                        
                        // Nastavíme listener pre chaty
                        let (stream, listener) = await chatService.listenToChats(chatIds: chats.compactMap { $0.id })
                        await send(.setChatListener(listener))
                        
                        for await updatedChats in stream {
                            await send(.chatsUpdated(updatedChats))
                        }
                    } catch {
                        print("DEBUG: Error loading chats:", error)
                        await send(.chatsResponse(.failure(error)))
                    }
                }
                
            case let .chatsResponse(.success(chats)):
                print("DEBUG: Setting chats in state:", chats)
                state.isLoading = false
                state.chats = chats
                
                return .run { [chats] send in
                    var updatedChats = chats
                    for (index, chat) in chats.enumerated() {
                        if let eventIds = chat.eventIds {
                            let chatEvents = try await eventService.fetchEventsByIds(eventIds)
                            updatedChats[index].events = chatEvents
                        }
                    }
                    
                    await send(.chatsUpdatedWithEvents(updatedChats))
                } catch: { error, send in
                    print("DEBUG: Error loading events:", error)
                }
                
            case let .chatsResponse(.failure(error)):
                state.isLoading = false
                state.error = error.localizedDescription
                return .none
                
            case let .chatSelected(chat):
                state.messageListener?.remove()
                
                state.selectedChat = chat
                state.isLoading = true
                
                let chatId = chat.id!
                
                return .run { [chatService, currentUser = state.currentUser] send in
                    let messages = try await chatService.fetchMessages(chatId: chatId)
                    await send(.messagesResponse(.success(messages)))
                    
                    // Pošleme systémovú správu o prečítaní len ak posledná správa nie je naše potvrdenie
                    if let userId = currentUser?.id,
                       let lastMessage = messages.last,
                       !(lastMessage.type == .system && 
                         lastMessage.subtype == .readReceipt && 
                         lastMessage.senderId == userId) {
                        let readReceipt = Message(
                            senderId: userId,
                            text: "",
                            type: .system,
                            subtype: .readReceipt
                        )
                        try? await chatService.sendMessage(readReceipt, to: chatId)
                        
                        // Aktualizujeme lokálny stav chatu
                        var updatedChat = chat
                        updatedChat.lastMessage = readReceipt
                        updatedChat.lastMessageAt = readReceipt.timestamp
                        await send(.chatUpdated(updatedChat))
                    }
                    
                    let (stream, listener) = await chatService.listenToMessages(chatId: chatId)
                    await send(.setMessageListener(listener))
                    
                    for await messages in stream {
                        await send(.messagesUpdated(messages))
                    }
                }
                
            case let .messagesResponse(.success(messages)):
                state.isLoading = false
                state.messages = messages
                return .none
                
            case let .messagesResponse(.failure(error)):
                state.isLoading = false
                state.error = error.localizedDescription
                return .none
                
            case let .newMessageChanged(text):
                state.newMessageText = text
                return .none
                
            case .sendMessageTapped:
                guard let chatId = state.selectedChat?.id,
                      let userId = state.currentUser?.id,
                      !state.newMessageText.isEmpty else { return .none }
                
                let text = state.newMessageText
                state.newMessageText = ""
                
                let optimisticMessage = Message(
                    id: UUID().uuidString,
                    senderId: userId,
                    text: text,
                    timestamp: Date(),
                    type: .general,
                    subtype: .textMessage
                )
                
                state.messages.append(optimisticMessage)
                
                let optimisticId = optimisticMessage.id!
                
                return .run { [optimisticId] send in
                    do {
                        let message = Message(
                            senderId: userId,
                            text: text,
                            type: .general,
                            subtype: .textMessage
                        )
                        try await chatService.sendMessage(message, to: chatId)
                        
                        let updatedChat = try await chatService.fetchChat(id: chatId)
                        await send(.chatUpdated(updatedChat))
                        await send(.messageSent(.success(message)))
                    } catch {
                        await send(.messageSent(.failure(error)))
                        await send(.removeOptimisticMessage(optimisticId))
                    }
                }
                
            case .messageSent(.success):
                return .none
                
            case let .messageSent(.failure(error)):
                state.error = error.localizedDescription
                return .none
                
            case .dismissChat:
                state.messageListener?.remove()
                state.messageListener = nil
                state.selectedChat = nil
                state.messages = []
                return .none
                
            case let .participantsLoaded(chatId, users):
                state.participants.merge(users) { current, _ in current }
                return .none
                
            case let .chatsUpdatedWithEvents(chats):
                state.chats = chats
                return .none
                
            case let .removeOptimisticMessage(id):
                state.messages.removeAll { $0.id == id }
                return .none
                
            case let .chatUpdated(chat):
                if let index = state.chats.firstIndex(where: { $0.id == chat.id }) {
                    var updatedChat = chat
                    
                    if updatedChat.events == nil {
                        updatedChat.events = state.chats[index].events
                    }
                    
                    state.chats[index] = updatedChat
                    
                    if state.selectedChat?.id == chat.id {
                        state.selectedChat = updatedChat
                    }
                }
                return .none
                
            case let .messagesUpdated(messages):
                state.messages = messages
                return .none
                
            case let .setMessageListener(listener):
                state.messageListener = listener
                return .none
                
            case let .setChatListener(listener):
                state.chatListener = listener
                return .none
                
            case let .chatsUpdated(chats):
                state.chats = chats.sorted { ($0.lastMessageAt ?? Date.distantPast) > ($1.lastMessageAt ?? Date.distantPast) }
                return .run { [chats] send in
                    var updatedChats = chats
                    for (index, chat) in chats.enumerated() {
                        if let eventIds = chat.eventIds {
                            let chatEvents = try await eventService.fetchEventsByIds(eventIds)
                            updatedChats[index].events = chatEvents
                        }
                    }
                    
                    await send(.chatsUpdatedWithEvents(updatedChats))
                } catch: { error, send in
                    print("DEBUG: Error loading events:", error)
                }
            }
        }
    }
}
