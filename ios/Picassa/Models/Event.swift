import Foundation
import SwiftUI

enum EventColor: String, Codable, CaseIterable {
    case red = "red"
    case orange = "orange"
    case yellow = "yellow"
    case green = "green"
    case blue = "blue"
    case purple = "purple"
    case pink = "pink"
    case gray = "gray"
    
    var color: Color {
        switch self {
        case .red: return .red
        case .orange: return .orange
        case .yellow: return .yellow
        case .green: return .green
        case .blue: return .blue
        case .purple: return .purple
        case .pink: return .pink
        case .gray: return .gray
        }
    }
}

struct Event: Equatable, Identifiable, FirestoreSerializable {
    var id: String?  // Musí zostať optional kvôli FirestoreSerializable
    var title: String
    var description: String?
    var date: Date
    var duration: TimeInterval
    var attendeeIds: [String]?
    var attendees: [String: User]?  // Toto nepôjde do Firestore
    var color: EventColor = .blue  // Default farba
    
    // Záloha
    var requiresDeposit: Bool? = false
    var isDepositPaid: Bool? = false
    var depositPrice: Decimal?
    var currency: String? = "CZK"
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case date
        case duration
        case attendeeIds
        case color = "eventColor"  // Explicitne pomenujeme pole v Firestore
        case requiresDeposit
        case isDepositPaid
        case depositPrice
        case currency
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(description, forKey: .description)
        try container.encode(date.timeIntervalSince1970, forKey: .date)
        try container.encode(duration, forKey: .duration)
        try container.encodeIfPresent(attendeeIds, forKey: .attendeeIds)
        try container.encode(color.rawValue, forKey: .color)
        
        // Platobné údaje enkódujeme len ak je požadovaná platba
        if requiresDeposit == true {
            try container.encode(requiresDeposit, forKey: .requiresDeposit)
            try container.encode(isDepositPaid, forKey: .isDepositPaid)
            try container.encodeIfPresent(depositPrice, forKey: .depositPrice)
            try container.encode(currency, forKey: .currency)
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Existujúce polia
        id = try container.decode(String?.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        let timestamp = try container.decode(Double.self, forKey: .date)
        date = Date(timeIntervalSince1970: timestamp)
        duration = try container.decode(TimeInterval.self, forKey: .duration)
        attendeeIds = try container.decodeIfPresent([String].self, forKey: .attendeeIds)
        
        // Farba
        if let colorString = try container.decodeIfPresent(String.self, forKey: .color),
           let decodedColor = EventColor(rawValue: colorString) {
            color = decodedColor
        } else {
            color = .blue
        }
        
        attendees = nil
        
        // Nové polia - všetky ako optional
        requiresDeposit = try container.decodeIfPresent(Bool.self, forKey: .requiresDeposit)
        isDepositPaid = try container.decodeIfPresent(Bool.self, forKey: .isDepositPaid)
        depositPrice = try container.decodeIfPresent(Decimal.self, forKey: .depositPrice)
        currency = try container.decodeIfPresent(String.self, forKey: .currency) ?? "CZK"
    }
    
    init(
        id: String? = nil,
        title: String,
        description: String? = nil,
        date: Date,
        duration: TimeInterval,
        attendeeIds: [String]? = nil,
        attendees: [String: User]? = nil,
        color: EventColor = .blue,
        requiresDeposit: Bool = false,
        isDepositPaid: Bool = false,
        depositPrice: Decimal? = nil,
        currency: String = "CZK"
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.date = date
        self.duration = duration
        self.attendeeIds = attendeeIds
        self.attendees = attendees
        self.color = color
        self.requiresDeposit = requiresDeposit
        self.isDepositPaid = isDepositPaid
        self.depositPrice = depositPrice
        self.currency = currency
    }
} 
