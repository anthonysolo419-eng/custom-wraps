import Foundation

final class OrdersService {
    static let shared = OrdersService()
    private init() {}

    private let api = EbayAPIService.shared

    func fetchOrders(
        filter: OrderFilter = .active,
        limit: Int = 50,
        offset: Int = 0
    ) async throws -> OrdersResponse {
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "offset", value: "\(offset)")
        ]

        if let filterString = filter.queryString {
            queryItems.append(URLQueryItem(name: "filter", value: filterString))
        }

        return try await api.request(
            path: "/sell/fulfillment/v1/order",
            queryItems: queryItems,
            responseType: OrdersResponse.self
        )
    }

    func fetchOrder(orderId: String) async throws -> Order {
        return try await api.request(
            path: "/sell/fulfillment/v1/order/\(orderId)",
            responseType: Order.self
        )
    }

    func fetchAllActiveOrders() async throws -> [Order] {
        var allOrders: [Order] = []
        var offset = 0
        let limit = 50
        var hasMore = true

        while hasMore {
            let response = try await fetchOrders(filter: .active, limit: limit, offset: offset)
            let orders = response.orders ?? []
            allOrders.append(contentsOf: orders)

            if orders.count < limit || response.next == nil {
                hasMore = false
            } else {
                offset += limit
            }
        }

        return allOrders.sorted { $0.lastModifiedDate > $1.lastModifiedDate }
    }
}

enum OrderFilter {
    case active
    case all
    case awaiting
    case shipped
    case custom(String)

    var queryString: String? {
        switch self {
        case .active:
            return "orderfulfillmentstatus:{NOT_STARTED|IN_PROGRESS}"
        case .awaiting:
            return "orderfulfillmentstatus:NOT_STARTED"
        case .shipped:
            return "orderfulfillmentstatus:FULFILLED"
        case .all:
            return nil
        case .custom(let filter):
            return filter
        }
    }
}
