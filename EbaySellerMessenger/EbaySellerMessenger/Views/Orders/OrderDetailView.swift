import SwiftUI

struct OrderDetailView: View {
    let order: Order
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    statusHeader
                    buyerCard
                    itemsCard
                    shippingCard
                    pricingCard
                }
                .padding()
            }
            .navigationTitle("Order Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
        }
    }

    private var statusHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Order #\(order.id.prefix(16))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(order.displayStatus)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(statusColor)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(order.totalAmount)
                    .font(.title2)
                    .fontWeight(.bold)
                Text(order.creationDate.conversationTimestamp)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .cardStyle()
    }

    private var buyerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Buyer", icon: "person.fill")

            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.ebayBlue.opacity(0.15))
                        .frame(width: 50, height: 50)
                    Text(order.buyer.username.initials)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(.ebayBlue)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(order.buyer.username)
                        .font(.headline)
                    if let addr = order.buyer.buyerRegistrationAddress {
                        Text([addr.city, addr.stateOrProvince, addr.countryCode]
                            .compactMap { $0 }
                            .joined(separator: ", "))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
            }

            if let shipTo = order.fulfillmentStartInstructions?.first?.shipToLocation {
                Divider()
                VStack(alignment: .leading, spacing: 4) {
                    Label("Ship to", systemImage: "location.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let name = shipTo.buyerName {
                        Text(name).font(.subheadline).fontWeight(.medium)
                    }
                    if let addr = shipTo.contactAddress {
                        Text([addr.addressLine1, addr.city, addr.stateOrProvince, addr.postalCode]
                            .compactMap { $0 }
                            .joined(separator: ", "))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
        .cardStyle()
    }

    private var itemsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Items (\(order.lineItems.count))", icon: "shippingbox.fill")
            ForEach(order.lineItems) { item in
                HStack(spacing: 12) {
                    if let url = item.image?.imageUrl, let imageUrl = URL(string: url) {
                        AsyncImage(url: imageUrl) { phase in
                            if case .success(let img) = phase {
                                img.resizable().aspectRatio(contentMode: .fill)
                            } else {
                                Color.gray.opacity(0.2)
                            }
                        }
                        .frame(width: 52, height: 52)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title)
                            .font(.subheadline)
                            .lineLimit(2)
                        HStack {
                            Text("Qty: \(item.quantity)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if let sku = item.sku {
                                Text("SKU: \(sku)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    Spacer()
                    Text(item.lineItemCost.formattedValue ?? item.lineItemCost.value)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
            }
        }
        .padding()
        .cardStyle()
    }

    private var shippingCard: some View {
        Group {
            if let instruction = order.fulfillmentStartInstructions?.first,
               let step = instruction.shippingStep {
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Shipping", icon: "truck.box.fill")
                    if let carrier = step.shippingCarrierCode {
                        InfoRow(label: "Carrier", value: carrier)
                    }
                    if let service = step.shippingServiceCode {
                        InfoRow(label: "Service", value: service)
                    }
                    if let minDate = instruction.minEstimatedDeliveryDate {
                        InfoRow(label: "Est. Delivery", value: minDate.conversationTimestamp)
                    }
                }
                .padding()
                .cardStyle()
            }
        }
    }

    private var pricingCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Payment", icon: "creditcard.fill")
            InfoRow(label: "Subtotal",
                    value: order.pricingSummary.priceSubtotal.formattedValue ?? order.pricingSummary.priceSubtotal.value)
            if let delivery = order.pricingSummary.deliveryCost {
                InfoRow(label: "Shipping", value: delivery.formattedValue ?? delivery.value)
            }
            Divider()
            HStack {
                Text("Total").font(.headline)
                Spacer()
                Text(order.totalAmount).font(.headline).fontWeight(.bold)
            }
        }
        .padding()
        .cardStyle()
    }

    private var statusColor: Color {
        switch order.orderFulfillmentStatus {
        case .fulfilled: return .ebayGreen
        case .inProgress: return .orange
        case .notStarted: return .ebayRed
        }
    }
}

struct SectionHeader: View {
    let title: String
    let icon: String

    var body: some View {
        Label(title, systemImage: icon)
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
    }
}

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}
