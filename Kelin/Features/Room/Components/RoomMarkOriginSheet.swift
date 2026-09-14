import SwiftUI

struct RoomMarkOriginSheet: View {
    let kind: RoomMarkKind
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: KelinSpacing.standard) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "灵体刻痕溯源"))
                        .kelinTypography(KelinTypography.cardTitle)
                    Text(String(localized: "雾生身上自然凝结的阅历与学识印记"))
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

            markCard(
                highlighted: kind == .eye,
                tint: KelinColor.accentWarm,
                title: String(localized: "眼光刻痕 · 雨夜路灯凝视"),
                badge: String(localized: "外显特征"),
                body: String(localized: "成因：雨夜在窗台连续凝视「旧路灯」达 42 分钟，右眼梢汇聚出温暖的金色光晕微粒。")
            )

            markCard(
                highlighted: kind == .scholar,
                tint: KelinColor.accent,
                title: String(localized: "学者纹 · STAR法则脉络"),
                badge: String(localized: "学识沉淀"),
                body: String(localized: "成因：完成5篇深度结构化共学复盘后，腹腔核心形成的淡紫色星轨纹路，伴随呼吸律动微亮。")
            )

            HStack {
                Spacer()
                Button(action: onDismiss) {
                    Text(String(localized: "确认感知"))
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
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func markCard(
        highlighted: Bool,
        tint: Color,
        title: String,
        badge: String,
        body: String
    ) -> some View {
        VStack(alignment: .leading, spacing: KelinSpacing.small) {
            HStack {
                Text(title)
                    .kelinTypography(KelinTypography.secondary, color: KelinColor.textPrimary)
                Spacer()
                Text(badge)
                    .kelinTypography(KelinTypography.label, color: tint)
            }
            Text(body)
                .kelinTypography(KelinTypography.label, color: KelinColor.textSecondary)
        }
        .padding(KelinSpacing.compact)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(KelinColor.surfaceSecondary.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: KelinRadius.small))
        .overlay {
            RoundedRectangle(cornerRadius: KelinRadius.small)
                .stroke(highlighted ? tint.opacity(0.45) : Color.white.opacity(0.06), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }
}
