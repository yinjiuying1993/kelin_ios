import SwiftUI

struct ChatEmptyStateView: View {
    var body: some View {
        VStack(spacing: KelinSpacing.compact) {
            Image(systemName: "ellipsis.message")
                .font(.system(size: KelinIconSize.emptyState))
                .foregroundStyle(KelinColor.textSecondary.opacity(0.7))

            Text(String(localized: "还没有对话"))
                .kelinTypography(KelinTypography.cardTitle)

            Text(String(localized: "想说的话，从这里开始。"))
                .kelinTypography(KelinTypography.secondary, color: KelinColor.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, KelinSpacing.largeSection)
        .accessibilityElement(children: .combine)
    }
}
