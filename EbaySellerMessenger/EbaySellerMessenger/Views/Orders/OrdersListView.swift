import SwiftUI

struct OrdersListView: View {
    @ObservedObject var ordersVM: OrdersViewModel
    @ObservedObject var conversationVM: ConversationViewModel
    @State private var showBulkMessage = false
    @State private var selectedOrder: Order?
    @State private var showOrderDetail = false

    var body: some View {
        NavigationStack {
            ZStack {
                if ordersVM.isLoading && ordersVM.orders.isEmpty {
                    LoadingView(message: "Loading orders...")
                } else if ordersVM.orders.isEmpty && !ordersVM.isLoading {
                    EmptyStateView(
                        icon: "shippingbox",
                        title: "No Active Orders",
                        subtitle: "You have no orders at this time. Pull to refresh.",
                        actionTitle: "Refresh",
                        action: { Task { await ordersVM.refresh() } }
                    )
                } else {
                    orderList
                }
            }
            .navigationTitle("Orders")
            .navigationBarTitleDisplayMode(.large)
            .toolbar { toolbarContent }
            .searchable(text: $ordersVM.searchText, prompt: "Search by buyer, item, or order ID")
            .refreshable { await ordersVM.refresh() }
            .sheet(isPresented: $showBulkMessage) {
                BulkMessageView(
                    conversationVM: conversationVM,
                    selectedOrders: ordersVM.selectedOrderObjects
                )
            }
            .sheet(item: $selectedOrder) { order in
                OrderDetailView(order: order)
            }
            .alert("Error", isPresented: .constant(ordersVM.error != nil)) {
                Button("OK") { ordersVM.error = nil }
            } message: {
                Text(ordersVM.error ?? "")
            }
        }
    }

    private var orderList: some View {
        List {
            if ordersVM.isMultiSelectMode && !ordersVM.selectedOrders.isEmpty {
                multiSelectBanner
                    .listRowBackground(Color.ebayBlue.opacity(0.1))
                    .listRowInsets(EdgeInsets())
            }

            ForEach(ordersVM.filteredOrders) { order in
                OrderRowView(
                    order: order,
                    isSelected: ordersVM.selectedOrders.contains(order.id),
                    isMultiSelectMode: ordersVM.isMultiSelectMode
                ) {
                    if ordersVM.isMultiSelectMode {
                        ordersVM.toggleSelection(for: order.id)
                    } else {
                        selectedOrder = order
                    }
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button {
                        ordersVM.selectedOrders = [order.id]
                        showBulkMessage = true
                    } label: {
                        Label("Message", systemImage: "message.fill")
                    }
                    .tint(.ebayBlue)
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
            }
        }
        .listStyle(.plain)
        .background(Color(UIColor.systemGroupedBackground))
    }

    private var multiSelectBanner: some View {
        HStack {
            Text("\(ordersVM.selectedOrders.count) selected")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.ebayBlue)
            Spacer()
            Button("Message All") {
                showBulkMessage = true
            }
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(Color.ebayBlue)
            .clipShape(Capsule())
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            if ordersVM.isMultiSelectMode {
                Button("Done") { ordersVM.clearSelection() }
                    .fontWeight(.semibold)
            } else {
                Menu {
                    Button {
                        ordersVM.toggleMultiSelect()
                    } label: {
                        Label("Select Multiple", systemImage: "checkmark.circle")
                    }
                    Button {
                        Task { await ordersVM.refresh() }
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }

        ToolbarItem(placement: .topBarLeading) {
            if ordersVM.isMultiSelectMode {
                Button("Select All") { ordersVM.selectAll() }
            }
        }
    }
}
