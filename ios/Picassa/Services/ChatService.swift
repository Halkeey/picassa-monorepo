import Foundation
import FirebaseFirestore

final class SendableListenerRegistration: @unchecked Sendable {
    private let lock = NSLock()
    private var listener: ListenerRegistration?
    
    init(_ listener: ListenerRegistration?) {
        self.listener = listener
    }
    
    func remove() {
        lock.lock()
        defer { lock.unlock() }
        listener?.remove()
        listener = nil
    }
    
    func update(_ newListener: ListenerRegistration?) {
        lock.lock()
        defer { lock.unlock() }
        listener?.remove()
        listener = newListener
    }
    
    deinit {
        remove()
    }
}

actor ChatService {
    private let db = Firestore.firestore()
    
    func fetchChats(for userId: String) async throws -> [Chat] {
        print("DEBUG: Fetching chats for user:", userId)
        let privateUser = try await db.collection("privateUsers").document(userId).getDocument()
        let chatIds = try privateUser.data(as: PrivateUser.self).chatIds ?? []
        print("DEBUG: Found chatIds in privateUser:", chatIds)
        
        guard !chatIds.isEmpty else {
            print("DEBUG: No chatIds found for user")
            return []
        }
        
        return try await withThrowingTaskGroup(of: Chat?.self) { group in
            for chatId in chatIds {
                group.addTask {
                    print("DEBUG: Fetching chat with id:", chatId)
                    do {
                        let chat = try await self.fetchChat(id: chatId)
                        print("DEBUG: Successfully fetched chat:", chat.id ?? "no id")
                        return chat
                    } catch {
                        print("DEBUG: Error fetching chat \(chatId):", error)
                        return nil
                    }
                }
            }
            
            var chats: [Chat] = []
            for try await chat in group {
                if let chat = chat {
                    chats.append(chat)
                }
            }
            print("DEBUG: Total chats fetched:", chats.count)
            return chats.sorted { ($0.lastMessageAt ?? Date.distantPast) > ($1.lastMessageAt ?? Date.distantPast) }
        }
    }
    
    func fetchChat(id: String) async throws -> Chat {
        print("DEBUG: Attempting to fetch chat document:", id)
        let doc = try await db.collection("chats").document(id).getDocument()
        
        guard doc.exists else {
            print("DEBUG: Chat document does not exist:", id)
            throw NSError(domain: "ChatService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Chat not found"])
        }
        
        print("DEBUG: Chat document exists, attempting to decode")
        let chat = try doc.data(as: Chat.self)
        print("DEBUG: Successfully decoded chat:", chat.id ?? "no id")
        return chat
    }
    
    func fetchMessages(chatId: String) async throws -> [Message] {
        let snapshot = try await db.collection("chats").document(chatId)
            .collection("messages")
            .order(by: "timestamp")
            .getDocuments()
        
        return snapshot.documents.compactMap { doc in
            try? doc.data(as: Message.self)
        }
    }
    
    func sendMessage(_ message: Message, to chatId: String) async throws {
        print("DEBUG: Sending message type: \(message.type), subtype: \(message.subtype)")
        
        // Vytvoríme správu s ID
        var messageWithId = message
        let messageRef = try await db.collection("chats").document(chatId)
            .collection("messages")
            .addDocument(from: message)
        messageWithId.id = messageRef.documentID  // Nastavíme ID z vytvoreného dokumentu
        
        // Aktualizujeme správu s ID
        try await messageRef.setData(from: messageWithId)
        print("DEBUG: Message saved with ID:", messageRef.documentID)
        
        // Aktualizujeme hlavný dokument chatu len ak nie je to systémová správa
        if message.type != .system {
            print("DEBUG: Updating lastMessage in chat document")
            try await db.collection("chats").document(chatId).setData([
                "lastMessage": [
                    "senderId": message.senderId,
                    "text": message.text,
                    "timestamp": message.timestamp,
                    "type": message.type.rawValue,
                    "subtype": message.subtype.rawValue
                ],
                "lastMessageAt": message.timestamp
            ], merge: true)
        } else {
            print("DEBUG: Skipping lastMessage update for system message")
        }
    }
    
    func createChat(between userIds: [String]) async throws -> Chat {
        print("DEBUG: Creating chat between users:", userIds)
        let chat = Chat(participantIds: userIds)
        let chatRef = try db.collection("chats").addDocument(from: chat)
        print("DEBUG: Created chat with id:", chatRef.documentID)
        
        // Add chatId to all participants
        for userId in userIds {
            print("DEBUG: Adding chatId to user:", userId)
            try await db.collection("privateUsers").document(userId).updateData([
                "chatIds": FieldValue.arrayUnion([chatRef.documentID])
            ])
            
            // Verify the update
            let updatedUser = try await db.collection("privateUsers").document(userId).getDocument()
            let chatIds = try updatedUser.data(as: PrivateUser.self).chatIds ?? []
            print("DEBUG: Updated chatIds for user \(userId):", chatIds)
        }
        
        return try await fetchChat(id: chatRef.documentID)
    }
    
    nonisolated static func createMessagesListener(
        for chatId: String,
        in db: Firestore
    ) -> (AsyncStream<[Message]>, SendableListenerRegistration) {
        var continuation: AsyncStream<[Message]>.Continuation?
        
        let stream = AsyncStream<[Message]> { cont in
            continuation = cont
        }
        
        let listener = db.collection("chats").document(chatId)
            .collection("messages")
            .order(by: "timestamp")
            .addSnapshotListener { snapshot, error in
                guard let snapshot = snapshot else {
                    print("DEBUG: Error listening to messages:", error?.localizedDescription ?? "")
                    return
                }
                
                let messages = snapshot.documents.compactMap { doc in
                    try? doc.data(as: Message.self)
                }
                
                continuation?.yield(messages)
            }
        
        return (stream, SendableListenerRegistration(listener))
    }
    
    func listenToMessages(chatId: String) -> (AsyncStream<[Message]>, SendableListenerRegistration) {
        return Self.createMessagesListener(for: chatId, in: db)
    }
    
    nonisolated static func createChatsListener(
        for chatIds: [String],
        in db: Firestore
    ) -> (AsyncStream<[Chat]>, SendableListenerRegistration) {
        print("DEBUG: Creating chats listener with chatIds:", chatIds)
        print("DEBUG: chatIds count:", chatIds.count)
        print("DEBUG: chatIds isEmpty:", chatIds.isEmpty)
        
        var continuation: AsyncStream<[Chat]>.Continuation?
        
        let stream = AsyncStream<[Chat]> { cont in
            continuation = cont
        }
        
        // Ak je pole chatIds prázdne, vrátime prázdny stream a listener
        guard !chatIds.isEmpty else {
            print("DEBUG: chatIds is empty, returning empty stream")
            continuation?.yield([])
            return (stream, SendableListenerRegistration(nil))
        }
        
        print("DEBUG: Creating Firestore listener for chatIds")
        let listener = db.collection("chats")
            .whereField(FieldPath.documentID(), in: chatIds)
            .addSnapshotListener { snapshot, error in
                guard let snapshot = snapshot else {
                    print("DEBUG: Error listening to chats:", error?.localizedDescription ?? "")
                    return
                }
                
                let chats = snapshot.documents.compactMap { doc in
                    try? doc.data(as: Chat.self)
                }
                
                print("DEBUG: Received \(chats.count) chats from Firestore")
                continuation?.yield(chats)
            }
        
        return (stream, SendableListenerRegistration(listener))
    }
    
    func listenToChats(chatIds: [String]) -> (AsyncStream<[Chat]>, SendableListenerRegistration) {
        return Self.createChatsListener(for: chatIds, in: db)
    }
} 