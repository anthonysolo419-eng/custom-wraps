import Foundation

struct Order: Identifiable, Codable, Hashable {
    let id: String
    let legacyOrderId: String?
    let creationDate: Date
    let lastModifiedDate: Date
    let orderFulfillmentStatus: OrderFulfillmentStatus
    let orderPaymentStatus: OrderPaymentStatus
    let buyer: BuyerInfo
    let lineItems: [LineItem]
    let pricingSummary: PricingSummary
    let fulfillmentStartInstructions: [FulfillmentInstruction]?
    var unreadMessageCount: Int = 0

    var totalAmount: String {
        pricingSummary.total.formattedValue ?? "\(pricingSummary.total.currency) \(pricingSummary.total.value)"
    }

    var firstItemTitle: String {
        lineItems.first?.title ?? "Unknown Item"
    }

    var firstItemImageUrl: String? {
        lineItems.first?.image?.imageUrl
    }

    var displayStatus: String {
        switch orderFulfillmentStatus {
        case .fulfilled: return "Shipped"
        case .inProgress: return "Processing"
        case .notStarted: return "Awaiting Shipment"
        }
    }

    var statusColor: String {
        switch orderFulfillmentStatus {
        case .fulfilled: return "green"
        case .inProgress: return "orange"
        case .notStarted: return "red"
        }
    }
}

enum OrderFulfillmentStatus: String, Codable {
    case fulfilled = "FULFILLED"
    case inProgress = "IN_PROGRESS"
    case notStarted = "NOT_STARTED"
}

enum OrderPaymentStatus: String, Codable {
    case fullyRefunded = "FULLY_REFUNDED"
    case paid = "PAID"
    case partiallyRefunded = "PARTIALLY_REFUNDED"
    case failed = "FAILED"
    case pending = "PENDING"
}

struct BuyerInfo: Codable, Hashable {
    let username: String
    let taxAddress: TaxAddress?
    let buyerRegistrationAddress: BuyerRegistrationAddress?

    var displayName: String { username }

    var location: String {
        if let city = buyerRegistrationAddress?.addressLine1,
           let state = buyerRegistrationAddress?.stateOrProvince {
            return "\(city), \(state)"
        }
        return taxAddress?.stateOrProvince ?? "Unknown"
    }
}

struct TaxAddress: Codable, Hashable {
    let stateOrProvince: String?
    let countryCode: String?
    let postalCode: String?
    let city: String?
}

struct BuyerRegistrationAddress: Codable, Hashable {
    let addressLine1: String?
    let addressLine2: String?
    let city: String?
    let stateOrProvince: String?
    let countryCode: String?
    let postalCode: String?
}

struct LineItem: Identifiable, Codable, Hashable {
    let lineItemId: String
    let title: String
    let quantity: Int
    let sku: String?
    let image: ItemImage?
    let lineItemCost: Amount

    var id: String { lineItemId }
}

struct ItemImage: Codable, Hashable {
    let imageUrl: String
}

struct PricingSummary: Codable, Hashable {
    let priceSubtotal: Amount
    let deliveryCost: Amount?
    let total: Amount
}

struct Amount: Codable, Hashable {
    let value: String
    let currency: String
    var convertedFromValue: String?
    var convertedFromCurrency: String?

    var formattedValue: String? {
        guard let doubleVal = Double(value) else { return nil }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.string(from: NSNumber(value: doubleVal))
    }
}

struct FulfillmentInstruction: Codable, Hashable {
    let minEstimatedDeliveryDate: Date?
    let maxEstimatedDeliveryDate: Date?
    let shipToLocation: ShipToLocation?
    let shippingStep: ShippingStep?
}

struct ShipToLocation: Codable, Hashable {
    let contactAddress: ContactAddress?
    let buyerName: String?
}

struct ContactAddress: Codable, Hashable {
    let addressLine1: String?
    let addressLine2: String?
    let city: String?
    let stateOrProvince: String?
    let postalCode: String?
    let countryCode: String?
}

struct ShippingStep: Codable, Hashable {
    let shippingCarrierCode: String?
    let shippingServiceCode: String?
    let shipTo: ShipToInfo?
}

struct ShipToInfo: Codable, Hashable {
    let contactAddress: ContactAddress?
    let fullName: String?
}

struct OrdersResponse: Codable {
    let orders: [Order]?
    let total: Int?
    let next: String?
    let prev: String?
    let limit: Int?
    let offset: Int?
}
