import SwiftUI

struct RoomSightMemorySheet: View {
    var onOpenGallery: () -> Void
    var onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: KelinSpacing.standard) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "窗台见闻 · 雨夜路灯"))
                        .kelinTypography(KelinTypography.cardTitle)
                    Text(String(localized: "见闻记忆与实物形成记录"))
                        .kelinTypography(KelinTypography.label, color: KelinColor.textSecondary)
                }
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .foregroundStyle(KelinColor.textSecondary)
                        .frame(
                            width: RoomHotspotRules.minimumTouchTarget,
                            height: RoomHotspotRules.minimumTouchTarget
                        )
                        .background(KelinColor.surfaceSecondary)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(String(localized: "关闭"))
            }

            VStack(alignment: .leading, spacing: KelinSpacing.small) {
                HStack {
                    Text(String(localized: "形成时间：3天前 21:18"))
                        .kelinTypography(KelinTypography.label, color: KelinColor.textSecondary)
                    Spacer()
                    Text(String(localized: "永久藏品"))
                        .kelinTypography(KelinTypography.label, color: KelinColor.accentWarm)
                }
                Text(String(localized: "湿漉漉的青石板路旁，那盏路灯在暮雨里一直亮着。你走过时随手拍下的照片，让雾生悄悄在窗台上塑成了这盏微缩灯火。"))
                    .kelinTypography(KelinTypography.body)
            }
            .padding(KelinSpacing.compact)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(KelinColor.surfaceSecondary.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: KelinRadius.small))

            HStack {
                Button(action: onOpenGallery) {
                    Text(String(localized: "在画廊查看"))
                        .kelinTypography(KelinTypography.secondary, color: KelinColor.textSecondary)
                        .frame(minHeight: RoomHotspotRules.minimumTouchTarget)
                }
                .buttonStyle(.plain)
                Spacer()
                Button(action: onDismiss) {
                    Text(String(localized: "轻拭微光"))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(KelinColor.accent)
                        .padding(.horizontal, KelinSpacing.standard)
                        .frame(minHeight: RoomHotspotRules.minimumTouchTarget)
                        .background(KelinColor.accentSurface)
                        .clipShape(RoundedRectangle(cornerRadius: KelinRadius.small))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(KelinSpacing.pageHorizontal)
        .kelinScreenBackground()
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}
