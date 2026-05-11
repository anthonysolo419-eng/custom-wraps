import SwiftUI

struct MessageInputView: View {
    @ObservedObject var conversationVM: ConversationViewModel
    let conversation: Conversation
    var isFocused: FocusState<Bool>.Binding

    var body: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(alignment: .bottom, spacing: 10) {
                couponButton
                textEditor
                sendButton
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(UIColor.systemBackground))
        }
    }

    private var couponButton: some View {
        Button {
            conversationVM.showCouponPicker = true
        } label: {
            Image(systemName: "tag.circle.fill")
                .font(.system(size: 30))
                .foregroundStyle(Color.ebayBlue)
                .symbolRenderingMode(.hierarchical)
        }
        .padding(.bottom, 4)
    }

    private var textEditor: some View {
        ZStack(alignment: .topLeading) {
            if conversationVM.messageText.isEmpty {
                Text("Message \(conversation.buyer.username)...")
                    .foregroundStyle(.tertiary)
                    .font(.body)
                    .padding(.horizontal, 12)
                    .padding(.top, 10)
            }
            TextEditor(text: $conversationVM.messageText)
                .font(.body)
                .frame(minHeight: 40, maxHeight: 120)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 8)
                .focused(isFocused)
                .scrollContentBackground(.hidden)
        }
        .padding(.vertical, 4)
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }

    private var sendButton: some View {
        Button {
            Task { await conversationVM.sendMessage(to: conversation) }
        } label: {
            Group {
                if conversationVM.isSending {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
            .frame(width: 36, height: 36)
            .background(canSend ? Color.ebayBlue : Color.gray.opacity(0.4))
            .clipShape(Circle())
        }
        .disabled(!canSend || conversationVM.isSending)
        .padding(.bottom, 4)
        .animation(.easeInOut(duration: 0.15), value: canSend)
    }

    private var canSend: Bool {
        !conversationVM.messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
