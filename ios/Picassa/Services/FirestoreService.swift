import Foundation
import FirebaseFirestore

protocol FirestoreSerializable: Codable {
    var id: String? { get set }
}

actor FirestoreService<T: FirestoreSerializable> {
    private let db = Firestore.firestore()
    private let collection: String
    
    init(collection: String) {
        self.collection = collection
    }
    
    func create(_ item: T) async throws -> T {
        var data = try JSONEncoder().encode(item)
        var dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        dict.removeValue(forKey: "id")
        
        // Konvertujeme Date na Firestore Timestamp
        if let date = dict["date"] as? TimeInterval {
            dict["date"] = Timestamp(date: Date(timeIntervalSince1970: date))
        }
        
        let docRef = db.collection(collection).document()
        try await docRef.setData(dict)
        
        var updatedItem = item
        updatedItem.id = docRef.documentID
        return updatedItem
    }
    
    func read(id: String) async throws -> T {
        print("📍 Reading document with id: \(id) from collection: \(collection)")
        let document = try await db.collection(collection).document(id).getDocument()
        
        guard let data = document.data() else {
            print("❌ No data found for document: \(id)")
            throw FirestoreError.documentNotFound
        }
        
        print("📄 Raw Firestore data: \(data)")
        
        var dict = data
        dict["id"] = document.documentID
        
        let jsonData = try JSONSerialization.data(withJSONObject: dict)
        print("🔄 Converted to JSON data: \(String(data: jsonData, encoding: .utf8) ?? "")")
        
        do {
            let decodedData = try JSONDecoder().decode(T.self, from: jsonData)
            print("✅ Successfully decoded data: \(decodedData)")
            return decodedData
        } catch {
            print("❌ Decoding error: \(error)")
            throw error
        }
    }
    
    func update(_ item: T) async throws {
        guard let id = item.id else {
            throw FirestoreError.missingId
        }
        
        var data = try JSONEncoder().encode(item)
        var dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        dict.removeValue(forKey: "id")
        
        // Konvertujeme Date na Firestore Timestamp
        if let date = dict["date"] as? TimeInterval {
            dict["date"] = Timestamp(date: Date(timeIntervalSince1970: date))
        }
        
        try await db.collection(collection).document(id).updateData(dict)
    }
    
    func delete(id: String) async throws {
        try await db.collection(collection).document(id).delete()
    }
    
    func list() async throws -> [T] {
        let snapshot = try await db.collection(collection)
            .order(by: "date", descending: false)  // Zoradíme podľa dátumu
            .getDocuments()
        
        return try snapshot.documents.compactMap { document in
            var dict = document.data()
            dict["id"] = document.documentID
            
            if let timestamp = dict["date"] as? Timestamp {
                dict["date"] = timestamp.dateValue().timeIntervalSince1970
            }
            
            let jsonData = try JSONSerialization.data(withJSONObject: dict)
            return try JSONDecoder().decode(T.self, from: jsonData)
        }
    }
    
    func query(_ queryBuilder: @Sendable (Query) -> Query) async throws -> [T] {
        let collection = db.collection(collection)
        let query = queryBuilder(collection)
        
        print("Executing Firestore query on collection: '\(self.collection)'")
        
        do {
            let snapshot = try await query.getDocuments()
            print("Query returned \(snapshot.documents.count) documents")
            
            return try snapshot.documents.compactMap { document in
                print("Processing document: \(document.documentID)")
                var item = try document.data(as: T.self)
                item.id = document.documentID
                return item
            }
        } catch {
            print("❌ Firestore query error: \(error)")
            throw error
        }
    }
}

enum FirestoreError: Error {
    case documentNotFound
    case encodingError
    case decodingError
    case missingId
}
