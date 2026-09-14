import SwiftUI

struct MemoryEmptyStateView: View {
    let spiritName: String
    let onTalk: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(KelinColor.surfacePrimary)
                .overlay {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        Image(systemName: "square.stack.3d.up")
                            .font(.system(size: KelinIconSize.emptyState, weight: .regular))
                            .foregroundStyle(KelinColor.accent.opacity(0.6))
                    }
                }
                .frame(width: 64, height: 64)
                .shadow(color: Color.black.opacity(0.2), radius: 12, y: 6)

            Text(String(localized: "还没有刻痕"))
                .kelinTypography(KelinTypography.pageTitle)
                .padding(.top, 20)

            Text(String(localized: "与\(spiritName)日常对话、投喂或共学后，会逐渐在身上留下相处的记忆与痕迹。"))
                .font(.system(size: 14))
                .foregroundStyle(KelinColor.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 280)
                .padding(.top, 10)

            Button(action: onTalk) {
                HStack(spacing: KelinSpacing.small) {
                    Image(systemName: "bubble.left.fill")
                        .font(.system(size: 17, weight: .semibold))
                    Text(String(localized: "去说一句话"))
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundStyle(KelinColor.textPrimary)
                .frame(width: MemoryLayout.emptyActionWidth, height: MemoryLayout.emptyActionHeight)
                .background(KelinColor.accent)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.top, KelinSpacing.section)
            .accessibilityLabel(String(localized: "去说一句话"))
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .contain)
    }
}
