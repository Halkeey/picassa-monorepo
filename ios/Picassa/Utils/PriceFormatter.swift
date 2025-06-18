import Foundation

enum PriceFormatter {
    static func format(_ price: Decimal, currency: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        
        if let formattedPrice = formatter.string(from: price as NSDecimalNumber) {
            return "\(formattedPrice) \(currency)"
        }
        return "\(price) \(currency)"
    }
} 