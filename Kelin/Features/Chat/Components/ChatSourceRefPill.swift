import SwiftUI

struct ChatSourceRefPill: View {
    let reference: MessageSourceRef

    var body: some View {
        Button {
            // P10+: open MemoryDetailSheet when memory is available.
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: ChatLayout.sourceRefIconSize, weight: .medium))
                Text(String(localized: "它想起了 · \(reference.title)"))
                    .font(.system(size: 12, weight: .medium))
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .opacity(0.7)
            }
            .foregroundStyle(KelinColor.accent)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(KelinColor.accent.opacity(0.1))
            .overlay {
                Capsule().stroke(KelinColor.accent.opacity(0.2), lineWidth: 1)
            }
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .accessibilityLabel(String(localized: "记忆引用：\(reference.title)"))
    }
}
