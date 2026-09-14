import SwiftUI

struct ChatMessageBubble: View {
    let message: ChatMessage
    var maxWidth: CGFloat = 290
    let onRetry: (() -> Void)?

    var body: some View {
        VStack(alignment: message.role == .spirit ? .leading : .trailing, spacing: KelinSpacing.small) {
            bubble

            if message.role == .user, message.status == .failed, let onRetry {
                Button(action: onRetry) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 12, weight: .medium))
                        Text(String(localized: "发送失败，轻触重试"))
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundStyle(KelinColor.danger)
                }
                .buttonStyle(.plain)
                .frame(minHeight: KelinSize.minimumTouchTarget, alignment: .trailing)
            }

            if message.role == .spirit, !message.sourceRefs.isEmpty {
                ForEach(message.sourceRefs) { reference in
                    ChatSourceRefPill(reference: reference)
                }
            }
        }
        .frame(maxWidth: maxWidth, alignment: message.role == .spirit ? .leading : .trailing)
    }

    private var bubble: some View {
        Text(message.content)
            .font(.system(size: 15))
            .foregroundStyle(KelinColor.textPrimary)
            .lineSpacing(6)
            .multilineTextAlignment(.leading)
            .padding(.horizontal, KelinSpacing.standard)
            .padding(.vertical, ChatLayout.bubbleVerticalPadding)
            .background(message.role == .spirit ? KelinColor.surfacePrimary : KelinColor.accentSurface)
            .clipShape(bubbleShape)
            .overlay {
                if message.role == .spirit {
                    bubbleShape.stroke(Color.white.opacity(0.05), lineWidth: 1)
                }
            }
            .shadow(color: .black.opacity(0.18), radius: 2, y: 1)
            .opacity(message.role == .user && message.status != .accepted ? 0.82 : 1)
            .accessibilityLabel(accessibilityText)
    }

    private var bubbleShape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(
            topLeadingRadius: message.role == .spirit ? KelinRadius.small : KelinRadius.standard,
            bottomLeadingRadius: KelinRadius.standard,
            bottomTrailingRadius: KelinRadius.standard,
            topTrailingRadius: message.role == .user ? KelinRadius.small : KelinRadius.standard
        )
    }

    private var accessibilityText: String {
        switch message.role {
        case .spirit:
            String(localized: "精灵说：\(message.content)")
        case .user:
            switch message.status {
            case .failed:
                String(localized: "发送失败：\(message.content)")
            case .queued, .sending:
                String(localized: "发送中：\(message.content)")
            default:
                String(localized: "你说：\(message.content)")
            }
        }
    }
}
