import SwiftUI

struct MemoryTimelineCard: View {
    let item: MemoryTimelineItem
    let dayTitle: String?
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: KelinSpacing.small) {
            HStack {
                Text(dayTitle ?? " ")
                    .kelinTypography(KelinTypography.label, color: KelinColor.textSecondary)
                    .opacity(dayTitle == nil ? 0 : 1)
                Spacer()
                Text(item.typeTitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(color(for: item.tint))
                    .padding(.horizontal, KelinSpacing.small)
                    .padding(.vertical, 3)
                    .background(KelinColor.accentSurface.opacity(0.3))
                    .clipShape(Capsule())
            }

            Button(action: action) {
                HStack(spacing: KelinSpacing.standard) {
                    Image(systemName: item.symbolName)
                        .font(.system(size: KelinIconSize.standard, weight: .medium))
                        .foregroundStyle(color(for: item.tint))
                        .frame(width: MemoryLayout.iconWell, height: MemoryLayout.iconWell)
                        .background(KelinColor.accentSurface)
                        .clipShape(RoundedRectangle(cornerRadius: KelinRadius.small, style: .continuous))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("“\(item.memory.summary)”")
                            .kelinTypography(KelinTypography.cardTitle)
                            .lineLimit(1)
                        Text(String(localized: "影响 · \(item.impactTitle)"))
                            .kelinTypography(KelinTypography.secondary, color: KelinColor.textSecondary)
                            .lineLimit(1)
                    }

                    Spacer(minLength: KelinSpacing.small)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(KelinColor.textSecondary)
                }
                .padding(KelinSpacing.standard)
                .frame(minHeight: KelinSize.minimumTouchTarget)
                .background(KelinColor.surfacePrimary)
                .clipShape(RoundedRectangle(cornerRadius: MemoryLayout.cardRadius, style: .continuous))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(item.memory.summary)
            .accessibilityHint(String(localized: "影响 · \(item.impactTitle)"))
        }
        .padding(.leading, MemoryLayout.timelineGutter)
        .overlay(alignment: .topLeading) {
            ZStack {
                Circle()
                    .fill(KelinColor.backgroundBase)
                    .frame(width: 22, height: 22)
                Circle()
                    .fill(color(for: item.tint))
                    .frame(width: 10, height: 10)
                    .shadow(color: color(for: item.tint).opacity(0.35), radius: 4)
            }
            .offset(x: 0, y: 10)
        }
    }

    private func color(for tint: MemoryTypeTint) -> Color {
        switch tint {
        case .accent:
            KelinColor.accent
        case .cold:
            KelinColor.accentCold
        case .warm:
            KelinColor.accentWarm
        case .success:
            KelinColor.success
        case .secondary:
            KelinColor.textSecondary
        }
    }
}
