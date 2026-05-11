import Foundation

struct Coupon: Identifiable, Codable, Hashable {
    let id: String
    let code: String
    let title: String
    let description: String
    let discountType: DiscountType
    let discountValue: Double
    let minimumPurchase: Double?
    let expirationDate: Date?
    let isActive: Bool
    var usageCount: Int
    let maxUsage: Int?

    var formattedDiscount: String {
        switch discountType {
        case .percentage:
            return "\(Int(discountValue))% OFF"
        case .fixedAmount:
            return "$\(String(format: "%.2f", discountValue)) OFF"
        case .freeShipping:
            return "FREE SHIPPING"
        }
    }

    var isExpired: Bool {
        guard let expDate = expirationDate else { return false }
        return expDate < Date()
    }

    var isUsable: Bool {
        guard isActive && !isExpired else { return false }
        if let max = maxUsage { return usageCount < max }
        return true
    }

    var expirationDisplay: String {
        guard let expDate = expirationDate else { return "No expiration" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return "Expires \(formatter.string(from: expDate))"
    }

    var insertableText: String {
        var lines = [
            "🎁 SPECIAL OFFER FOR YOU",
            "Use code: \(code)",
            formattedDiscount
        ]
        if let min = minimumPurchase {
            lines.append("Min. purchase: $\(String(format: "%.2f", min))")
        }
        lines.append(expirationDisplay)
        return lines.joined(separator: "\n")
    }
}

enum DiscountType: String, Codable, CaseIterable {
    case percentage = "PERCENTAGE"
    case fixedAmount = "FIXED_AMOUNT"
    case freeShipping = "FREE_SHIPPING"

    var displayName: String {
        switch self {
        case .percentage: return "Percentage Off"
        case .fixedAmount: return "Dollar Amount Off"
        case .freeShipping: return "Free Shipping"
        }
    }
}

extension Coupon {
    static var samples: [Coupon] {
        [
            Coupon(
                id: "1",
                code: "SAVE10",
                title: "10% Off Your Next Purchase",
                description: "Get 10% off on any item in my store",
                discountType: .percentage,
                discountValue: 10,
                minimumPurchase: 20,
                expirationDate: Calendar.current.date(byAdding: .day, value: 30, to: Date()),
                isActive: true,
                usageCount: 0,
                maxUsage: 100
            ),
            Coupon(
                id: "2",
                code: "FREESHIP",
                title: "Free Shipping",
                description: "Free shipping on your next order",
                discountType: .freeShipping,
                discountValue: 0,
                minimumPurchase: nil,
                expirationDate: Calendar.current.date(byAdding: .day, value: 14, to: Date()),
                isActive: true,
                usageCount: 5,
                maxUsage: 50
            ),
            Coupon(
                id: "3",
                code: "LOYAL5",
                title: "$5 Loyalty Discount",
                description: "Thank you for your loyalty - $5 off",
                discountType: .fixedAmount,
                discountValue: 5,
                minimumPurchase: 25,
                expirationDate: Calendar.current.date(byAdding: .month, value: 2, to: Date()),
                isActive: true,
                usageCount: 2,
                maxUsage: nil
            )
        ]
    }
}
