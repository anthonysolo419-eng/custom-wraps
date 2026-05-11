import SwiftUI

struct CouponPickerView: View {
    let coupons: [Coupon]
    let onSelect: (Coupon) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var showCreateCoupon = false
    @State private var previewCoupon: Coupon?

    var body: some View {
        NavigationStack {
            Group {
                if coupons.isEmpty {
                    EmptyStateView(
                        icon: "tag.slash",
                        title: "No Coupons",
                        subtitle: "Create your first coupon to send to buyers.",
                        actionTitle: "Create Coupon",
                        action: { showCreateCoupon = true }
                    )
                } else {
                    couponList
                }
            }
            .navigationTitle("Select Coupon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showCreateCoupon = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showCreateCoupon) {
                CreateCouponView { newCoupon in
                    onSelect(newCoupon)
                    dismiss()
                }
            }
        }
    }

    private var couponList: some View {
        List {
            ForEach(coupons.filter { $0.isUsable }) { coupon in
                CouponCardView(coupon: coupon) {
                    onSelect(coupon)
                    dismiss()
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
            }

            let expired = coupons.filter { !$0.isUsable }
            if !expired.isEmpty {
                Section("Expired / Inactive") {
                    ForEach(expired) { coupon in
                        CouponCardView(coupon: coupon, isDisabled: true) {}
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                    }
                }
            }
        }
        .listStyle(.plain)
    }
}

struct CouponCardView: View {
    let coupon: Coupon
    var isDisabled: Bool = false
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                discountBadge
                couponInfo
                Spacer()
                if !isDisabled {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.ebayBlue)
                }
            }
            .padding(14)
            .background(Color(UIColor.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.ebayYellow.opacity(isDisabled ? 0.2 : 0.5), lineWidth: 1.5)
            )
            .opacity(isDisabled ? 0.5 : 1)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }

    private var discountBadge: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.ebayYellow.opacity(0.15))
                .frame(width: 60, height: 60)
            VStack(spacing: 2) {
                Image(systemName: discountIcon)
                    .font(.system(size: 18))
                    .foregroundStyle(Color.ebayYellow)
                Text(coupon.formattedDiscount)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
    }

    private var discountIcon: String {
        switch coupon.discountType {
        case .percentage: return "percent"
        case .fixedAmount: return "dollarsign"
        case .freeShipping: return "shippingbox.fill"
        }
    }

    private var couponInfo: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(coupon.title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(1)

            HStack(spacing: 6) {
                Text(coupon.code)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.ebayBlue.opacity(0.1))
                    .foregroundStyle(.ebayBlue)
                    .clipShape(Capsule())
            }

            Text(coupon.expirationDisplay)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

struct CreateCouponView: View {
    let onCreate: (Coupon) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var code = ""
    @State private var title = ""
    @State private var discountType: DiscountType = .percentage
    @State private var discountValue = ""
    @State private var minimumPurchase = ""
    @State private var expirationDate = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
    @State private var hasExpiration = true
    @State private var hasMinimum = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Coupon Details") {
                    TextField("Title (e.g. 10% Off Next Order)", text: $title)
                    TextField("Code (e.g. SAVE10)", text: $code)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                }

                Section("Discount") {
                    Picker("Type", selection: $discountType) {
                        ForEach(DiscountType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    if discountType != .freeShipping {
                        TextField(
                            discountType == .percentage ? "Discount %" : "Amount ($)",
                            text: $discountValue
                        )
                        .keyboardType(.decimalPad)
                    }
                }

                Section("Conditions") {
                    Toggle("Minimum Purchase", isOn: $hasMinimum)
                    if hasMinimum {
                        TextField("Minimum ($)", text: $minimumPurchase)
                            .keyboardType(.decimalPad)
                    }
                    Toggle("Expiration Date", isOn: $hasExpiration)
                    if hasExpiration {
                        DatePicker("Expires", selection: $expirationDate, displayedComponents: .date)
                    }
                }

                if let error = error {
                    Section {
                        Label(error, systemImage: "exclamationmark.circle.fill")
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Create Coupon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") { createCoupon() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func createCoupon() {
        guard !title.isEmpty else { error = "Title is required"; return }
        guard !code.isEmpty else { error = "Coupon code is required"; return }

        let value: Double
        if discountType == .freeShipping {
            value = 0
        } else {
            guard let v = Double(discountValue), v > 0 else {
                error = "Enter a valid discount value"
                return
            }
            value = v
        }

        let coupon = Coupon(
            id: UUID().uuidString,
            code: code.uppercased(),
            title: title,
            description: title,
            discountType: discountType,
            discountValue: value,
            minimumPurchase: hasMinimum ? Double(minimumPurchase) : nil,
            expirationDate: hasExpiration ? expirationDate : nil,
            isActive: true,
            usageCount: 0,
            maxUsage: nil
        )
        onCreate(coupon)
        dismiss()
    }
}
