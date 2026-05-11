import SwiftUI

struct MessageBubbleView: View {
    let message: Message
    @State private var showTimestamp = false

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.isFromSeller {
                Spacer(minLength: 60)
                VStack(alignment: .trailing, spacing: 3) {
                    bubble
                    if showTimestamp { timestamp }
                }
            } else {
                VStack(alignment: .leading, spacing: 3) {
                    bubble
                    if showTimestamp { timestamp }
                }
                Spacer(minLength: 60)
            }
        }
        .padding(.vertical, 2)
        .onTapGesture { withAnimation(.easeInOut(duration: 0.2)) { showTimestamp.toggle() } }
    }

    @ViewBuilder
    private var bubble: some View {
        VStack(alignment: message.isFromSeller ? .trailing : .leading, spacing: 6) {
            if let coupon = message.attachedCoupon {
                couponCard(coupon)
            }
            Text(message.text)
                .font(.body)
                .foregroundStyle(message.isFromSeller ? .white : .primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(message.isFromSeller ? Color.sentBubble : Color.receivedBubble)
        .clipShape(BubbleShape(isFromSender: message.isFromSeller))
        .shadow(color: .black.opacity(0.06), radius: 2, x: 0, y: 1)
    }

    private var timestamp: some View {
        Text(message.fullTimestamp)
            .font(.caption2)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 4)
    }

    private func couponCard(_ coupon: Coupon) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "tag.fill")
                    .foregroundStyle(.ebayYellow)
                Text("COUPON")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.ebayYellow)
            }
            Text(coupon.title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(message.isFromSeller ? .white : .primary)
            Text(coupon.formattedDiscount)
                .font(.caption)
                .fontWeight(.bold)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.ebayYellow.opacity(0.2))
                .clipShape(Capsule())
                .foregroundStyle(message.isFromSeller ? .white : .primary)
            Text("Code: \(coupon.code)")
                .font(.caption2)
                .foregroundStyle(message.isFromSeller ? .white.opacity(0.8) : .secondary)
        }
        .padding(10)
        .background((message.isFromSeller ? Color.white : Color.ebayBlue).opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct BubbleShape: Shape {
    let isFromSender: Bool

    func path(in rect: CGRect) -> Path {
        let radius: CGFloat = 18
        let tailSize: CGFloat = 6
        var path = Path()

        if isFromSender {
            path.move(to: CGPoint(x: rect.minX + radius, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
            path.addArc(center: CGPoint(x: rect.maxX - radius, y: rect.minY + radius),
                        radius: radius, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - radius - tailSize))
            path.addArc(center: CGPoint(x: rect.maxX - radius, y: rect.maxY - radius - tailSize),
                        radius: radius, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
            path.addLine(to: CGPoint(x: rect.maxX - radius + tailSize, y: rect.maxY))
            path.addQuadCurve(to: CGPoint(x: rect.maxX - radius - tailSize, y: rect.maxY - tailSize),
                              control: CGPoint(x: rect.maxX - radius + tailSize, y: rect.maxY - tailSize))
            path.addLine(to: CGPoint(x: rect.minX + radius, y: rect.maxY - tailSize))
            path.addArc(center: CGPoint(x: rect.minX + radius, y: rect.maxY - tailSize - radius),
                        radius: radius, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
            path.addArc(center: CGPoint(x: rect.minX + radius, y: rect.minY + radius),
                        radius: radius, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        } else {
            path.move(to: CGPoint(x: rect.minX + radius, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
            path.addArc(center: CGPoint(x: rect.maxX - radius, y: rect.minY + radius),
                        radius: radius, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - tailSize - radius))
            path.addArc(center: CGPoint(x: rect.maxX - radius, y: rect.maxY - tailSize - radius),
                        radius: radius, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
            path.addLine(to: CGPoint(x: rect.minX + radius + tailSize, y: rect.maxY - tailSize))
            path.addQuadCurve(to: CGPoint(x: rect.minX + radius - tailSize, y: rect.maxY),
                              control: CGPoint(x: rect.minX + radius - tailSize, y: rect.maxY - tailSize))
            path.addLine(to: CGPoint(x: rect.minX + radius, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - tailSize - radius))
            path.addArc(center: CGPoint(x: rect.minX + radius, y: rect.maxY - tailSize - radius),
                        radius: radius, startAngle: .degrees(180), endAngle: .degrees(90), clockwise: true)
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
            path.addArc(center: CGPoint(x: rect.minX + radius, y: rect.minY + radius),
                        radius: radius, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        }

        path.closeSubpath()
        return path
    }
}
