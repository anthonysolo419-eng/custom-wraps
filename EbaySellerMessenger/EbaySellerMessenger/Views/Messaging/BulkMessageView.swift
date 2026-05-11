import SwiftUI

struct BulkMessageView: View {
    @ObservedObject var conversationVM: ConversationViewModel
    let selectedOrders: [Order]
    @Environment(\.dismiss) private var dismiss
    @State private var showCouponPicker = false
    @FocusState private var isBodyFocused: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    recipientsSummary
                    messageComposer
                    couponAttachButton
                    sendButton
                }
                .padding()
            }
            .navigationTitle("Bulk Message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        conversationVM.bulkMessageText = ""
                        conversationVM.bulkMessageSubject = ""
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showCouponPicker) {
                CouponPickerView(coupons: conversationVM.availableCoupons) { coupon in
                    let couponText = coupon.insertableText
                    if conversationVM.bulkMessageText.isEmpty {
                        conversationVM.bulkMessageText = couponText
                    } else {
                        conversationVM.bulkMessageText += "\n\n" + couponText
                    }
                }
            }
            .alert("Message Sent", isPresented: .constant(conversationVM.sendSuccess != nil)) {
                Button("OK") {
                    conversationVM.sendSuccess = nil
                    dismiss()
                }
            } message: {
                Text(conversationVM.sendSuccess ?? "")
            }
        }
    }

    private var recipientsSummary: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("\(selectedOrders.count) Recipient\(selectedOrders.count == 1 ? "" : "s")", systemImage: "person.2.fill")
                    .font(.headline)
                Spacer()
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(selectedOrders.prefix(8)) { order in
                        recipientChip(order.buyer.username)
                    }
                    if selectedOrders.count > 8 {
                        Text("+\(selectedOrders.count - 8) more")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color(UIColor.secondarySystemBackground))
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding()
        .cardStyle()
    }

    private func recipientChip(_ name: String) -> some View {
        HStack(spacing: 5) {
            ZStack {
                Circle()
                    .fill(Color.ebayBlue.opacity(0.15))
                    .frame(width: 22, height: 22)
                Text(name.initials)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.ebayBlue)
            }
            Text(name)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.ebayBlue.opacity(0.08))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color.ebayBlue.opacity(0.2), lineWidth: 1))
    }

    private var messageComposer: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Compose Message", systemImage: "square.and.pencil")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                Text("Subject (optional)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("e.g. Special offer just for you!", text: $conversationVM.bulkMessageSubject)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Message")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextEditor(text: $conversationVM.bulkMessageText)
                    .frame(minHeight: 140)
                    .padding(10)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(10)
                    .focused($isBodyFocused)
                    .overlay(
                        Group {
                            if conversationVM.bulkMessageText.isEmpty {
                                Text("Write a personalized message to all selected buyers...")
                                    .foregroundStyle(.tertiary)
                                    .padding(16)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                    .allowsHitTesting(false)
                            }
                        }
                    )
                HStack {
                    Spacer()
                    Text("\(conversationVM.bulkMessageText.count) characters")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .cardStyle()
    }

    private var couponAttachButton: some View {
        Button {
            isBodyFocused = false
            showCouponPicker = true
        } label: {
            HStack {
                Image(systemName: "tag.fill")
                    .foregroundStyle(.ebayYellow)
                Text("Attach a Coupon or Deal")
                    .fontWeight(.medium)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color(UIColor.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.ebayYellow.opacity(0.4), lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    private var sendButton: some View {
        Button {
            Task { await conversationVM.sendBulkMessage(to: selectedOrders) }
        } label: {
            Group {
                if conversationVM.isSending {
                    HStack(spacing: 10) {
                        ProgressView().tint(.white)
                        Text("Sending to \(selectedOrders.count) buyer\(selectedOrders.count == 1 ? "" : "s")...")
                    }
                } else {
                    Label(
                        "Send to \(selectedOrders.count) Buyer\(selectedOrders.count == 1 ? "" : "s")",
                        systemImage: "paperplane.fill"
                    )
                }
            }
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(canSend ? Color.ebayBlue : Color.gray.opacity(0.4))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(!canSend || conversationVM.isSending)
    }

    private var canSend: Bool {
        !conversationVM.bulkMessageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !selectedOrders.isEmpty
    }
}
