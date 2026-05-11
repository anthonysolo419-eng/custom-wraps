import Foundation
import SwiftUI

@MainActor
final class OrdersViewModel: ObservableObject {
    @Published var orders: [Order] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var selectedFilter: OrderFilter = .active
    @Published var searchText = ""
    @Published var selectedOrders: Set<String> = []
    @Published var isMultiSelectMode = false

    private let ordersService = OrdersService.shared

    var filteredOrders: [Order] {
        guard !searchText.isEmpty else { return orders }
        return orders.filter {
            $0.buyer.username.localizedCaseInsensitiveContains(searchText) ||
            $0.firstItemTitle.localizedCaseInsensitiveContains(searchText) ||
            $0.id.localizedCaseInsensitiveContains(searchText)
        }
    }

    var selectedOrderObjects: [Order] {
        orders.filter { selectedOrders.contains($0.id) }
    }

    func loadOrders() async {
        isLoading = true
        error = nil
        do {
            orders = try await ordersService.fetchAllActiveOrders()
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func refresh() async {
        await loadOrders()
    }

    func toggleSelection(for orderId: String) {
        if selectedOrders.contains(orderId) {
            selectedOrders.remove(orderId)
        } else {
            selectedOrders.insert(orderId)
        }
    }

    func selectAll() {
        selectedOrders = Set(filteredOrders.map { $0.id })
    }

    func clearSelection() {
        selectedOrders.removeAll()
        isMultiSelectMode = false
    }

    func toggleMultiSelect() {
        isMultiSelectMode.toggle()
        if !isMultiSelectMode { selectedOrders.removeAll() }
    }

    var totalUnread: Int { orders.reduce(0) { $0 + $1.unreadMessageCount } }
}
