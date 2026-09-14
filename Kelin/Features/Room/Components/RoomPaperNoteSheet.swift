import SwiftUI

struct RoomPaperNoteSheet: View {
    let letter: RoomLetter?
    var initialTab: RoomPaperNoteTab
    let onDismiss: () -> Void

    @State private var selectedTab: RoomPaperNoteTab

    init(
        letter: RoomLetter?,
        initialTab: RoomPaperNoteTab? = nil,
        onDismiss: @escaping () -> Void
    ) {
        self.letter = letter
        let tab = initialTab ?? RoomHotspotRules.defaultPaperNoteTab(for: letter)
        self.initialTab = tab
        self.onDismiss = onDismiss
        _selectedTab = State(initialValue: tab)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: KelinSpacing.standard) {
            header
            tabBar
            tabContent
            footer
        }
        .padding(KelinSpacing.pageHorizontal)
        .kelinScreenBackground()
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(String(localized: "地上的一折字条"))
                    .kelinTypography(KelinTypography.cardTitle)
                Text(String(localized: "地板缝隙里夹着的日常留信"))
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
    }

    private var tabBar: some View {
        HStack(spacing: 4) {
            ForEach(RoomPaperNoteTab.allCases, id: \.self) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    Text(tab.title)
                        .font(.system(size: 12, weight: selectedTab == tab ? .medium : .regular))
                        .foregroundStyle(selectedTab == tab ? KelinColor.accent : KelinColor.textSecondary)
                        .frame(maxWidth: .infinity, minHeight: RoomHotspotRules.minimumTouchTarget)
                }
                .buttonStyle(.plain)
                .background(selectedTab == tab ? KelinColor.accentSurface : .clear)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .accessibilityLabel(tab.title)
                .accessibilityAddTraits(selectedTab == tab ? [.isSelected] : [])
            }
        }
        .padding(4)
        .background(Color(hex: 0x121622))
        .clipShape(RoundedRectangle(cornerRadius: KelinRadius.small))
    }

    private var tabContent: some View {
        let copy = selectedTab.copy
        return VStack(alignment: .leading, spacing: KelinSpacing.small) {
            HStack {
                Text(copy.headline)
                    .kelinTypography(KelinTypography.label, color: copy.tint)
                Spacer()
                Text(copy.caption)
                    .kelinTypography(KelinTypography.label, color: KelinColor.textSecondary)
            }
            Text(copy.body)
                .kelinTypography(KelinTypography.body)
        }
        .padding(KelinSpacing.compact)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(KelinColor.surfaceSecondary.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: KelinRadius.small))
    }

    private var footer: some View {
        HStack {
            Text(String(localized: "折起字条放回原地"))
                .kelinTypography(KelinTypography.label, color: KelinColor.textSecondary)
            Spacer()
            Button(action: onDismiss) {
                Text(String(localized: "收起折好"))
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
}

private extension RoomPaperNoteTab {
    var title: String {
        switch self {
        case .contract:
            String(localized: "约定")
        case .study:
            String(localized: "求知")
        case .visit:
            String(localized: "串门")
        case .lost:
            String(localized: "走丢")
        }
    }

    var copy: (headline: String, caption: String, body: String, tint: Color) {
        switch self {
        case .contract:
            (
                String(localized: "今晚 22:30 共读约定"),
                String(localized: "今日未完成"),
                String(localized: "约定好今晚继续整理第三章面试知识点。如果我先睡着了，你记得敲敲桌子叫醒我。"),
                KelinColor.accentWarm
            )
        case .study:
            (
                String(localized: "正在梳理项目经历"),
                String(localized: "STAR契约"),
                String(localized: "利用STAR法则重构‘高并发架构优化’案例，形成结构化回答卡片与学者纹。"),
                KelinColor.accentCold
            )
        case .visit:
            (
                String(localized: "去看看守灯的那只"),
                String(localized: "来自邻屋"),
                String(localized: "对门的灵体‘星火’下午在门口晃了晃，留下一张微光便签，邀请你带雾生去串门。"),
                KelinColor.accent
            )
        case .lost:
            (
                String(localized: "我想起那盏坏掉的灯"),
                String(localized: "留信寻回"),
                String(localized: "有一回它在雨夜走到旧巷拐角，望着坏掉的路灯站了很久。如果它走丢了，去路灯下看看。"),
                KelinColor.danger
            )
        }
    }
}

private extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}
