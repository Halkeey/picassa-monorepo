import Foundation

extension DateFormatter {
    static let fullDateSK: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.locale = Locale(identifier: "sk_SK")
        return formatter
    }()
} 