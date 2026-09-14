import SwiftUI
import UIKit

struct RoomMoreMenuSheet: View {
    let model: RoomMoreMenuModel
    @Bindable var router: AppRouter
    let onDismiss: () -> Void

    @State private var copiedInviteCode = false
    @State private var drawerOffset: CGFloat = RoomMoreMenuModel.drawerWidth
    @State private var isDismissing = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack(alignment: .trailing) {
            overlay
            drawer
                .offset(x: drawerOffset)
        }
        .ignoresSafeArea()
        .onAppear {
            revealDrawer()
        }
        .accessibilityAddTraits(.isModal)
    }

    private var overlay: some View {
        ZStack(alignment: .leading) {
            KelinColor.backgroundEdge.opacity(0.65)
                .background(.ultraThinMaterial.opacity(0.35))

            VStack(spacing: KelinSpacing.xSmall) {
                Image(systemName: "chevron.left")
                    .font(.system(size: KelinIconSize.standard, weight: .medium))
                Text(String(localized: "轻触收起"))
                    .font(.system(size: 11))
            }
            .foregroundStyle(KelinColor.textSecondary.opacity(0.7))
            .padding(.leading, KelinSpacing.section)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding(.trailing, RoomMoreMenuModel.drawerWidth)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            dismissDrawer()
        }
        .accessibilityLabel(String(localized: "轻触收起"))
        .accessibilityAddTraits(.isButton)
    }

    private var drawer: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            spiritBadge
                .padding(.bottom, KelinSpacing.section)
            destinationList
            Spacer(minLength: KelinSpacing.standard)
            footer
        }
        .padding(.top, 56)
        .padding(.bottom, 36)
        .padding(.horizontal, KelinSpacing.pageHorizontal)
        .frame(width: RoomMoreMenuModel.drawerWidth)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(
            LinearGradient(
                colors: [
                    KelinColor.surfaceSecondary.opacity(0.96),
                    KelinColor.backgroundBase.opacity(0.98),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .overlay(alignment: .leading) {
            Capsule()
                .fill(Color.white.opacity(0.18))
                .frame(width: 4, height: 38)
                .offset(x: -8)
        }
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(KelinColor.borderSubtle)
                .frame(width: 1)
        }
        .shadow(color: Color.black.opacity(0.45), radius: 20, x: -8, y: 0)
        .gesture(dismissDrag)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(String(localized: "房间名录"))
    }

    private var header: some View {
        HStack {
            HStack(spacing: KelinSpacing.small) {
                Text(String(localized: "房间名录"))
                    .kelinTypography(KelinTypography.secondary, color: KelinColor.textSecondary)
                Text(String(localized: "更多"))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(KelinColor.accent)
                    .padding(.horizontal, KelinSpacing.small)
                    .padding(.vertical, 3)
                    .background(KelinColor.surfaceSecondary)
                    .clipShape(Capsule())
                    .overlay {
                        Capsule().stroke(KelinColor.borderSubtle, lineWidth: 1)
                    }
            }
            Spacer()
            Button(action: dismissDrawer) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(KelinColor.textSecondary)
                    .frame(width: 28, height: 28)
                    .background(KelinColor.surfaceSecondary)
                    .clipShape(Circle())
                    .frame(
                        width: RoomHotspotRules.minimumTouchTarget,
                        height: RoomHotspotRules.minimumTouchTarget
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(String(localized: "关闭"))
        }
        .padding(.bottom, KelinSpacing.pageHorizontal)
    }

    private var spiritBadge: some View {
        HStack(spacing: KelinSpacing.compact) {
            spiritGlyph
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(model.spiritName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(KelinColor.textPrimary)
                        .lineLimit(1)
                    Text(model.stageTitle)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(KelinColor.accent)
                        .lineLimit(1)
                }
                Text(model.identityLine)
                    .font(.system(size: 12))
                    .foregroundStyle(KelinColor.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(
            LinearGradient(
                colors: [
                    KelinColor.accent.opacity(0.15),
                    KelinColor.accentSurface.opacity(0.4),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: KelinRadius.standard, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: KelinRadius.standard, style: .continuous)
                .stroke(KelinColor.accent.opacity(0.25), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }

    private var spiritGlyph: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(KelinColor.backgroundCenter)
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [KelinColor.accent.opacity(0.4), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 24, height: 28)
            HStack(spacing: 10) {
                Circle().fill(Color.white).frame(width: 4, height: 4)
                Circle().fill(Color.white).frame(width: 4, height: 4)
            }
            .offset(y: -2)
        }
        .frame(width: 40, height: 40)
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        }
        .accessibilityHidden(true)
    }

    private var destinationList: some View {
        VStack(spacing: 10) {
            ForEach(model.rows) { row in
                destinationRow(row)
            }
        }
    }

    private func destinationRow(_ row: RoomMoreMenuRow) -> some View {
        Button {
            dismissDrawer()
            router.push(row.destination.route)
        } label: {
            HStack(spacing: KelinSpacing.compact) {
                Image(systemName: row.symbolName)
                    .font(.system(size: KelinIconSize.standard, weight: .regular))
                    .foregroundStyle(color(for: row.tint))
                    .frame(width: 36, height: 36)
                    .background(KelinColor.surfaceSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(row.title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(KelinColor.textPrimary)
                        .lineLimit(1)
                    Text(row.subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(KelinColor.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }

                Spacer(minLength: KelinSpacing.small)

                if row.showsIndicator {
                    Circle()
                        .fill(KelinColor.accent)
                        .frame(width: 6, height: 6)
                        .accessibilityHidden(true)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(KelinColor.textSecondary)
                    .accessibilityHidden(true)
            }
            .padding(KelinSpacing.compact)
            .frame(minHeight: RoomHotspotRules.minimumTouchTarget)
            .background(KelinColor.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(row.title)
        .accessibilityHint(row.subtitle)
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: KelinSpacing.standard) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(String(localized: "灵体邀请码"))
                        .font(.system(size: 11))
                        .foregroundStyle(KelinColor.textSecondary)
                    Text(model.inviteCode)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundStyle(KelinColor.textPrimary)
                        .tracking(1.2)
                }
                Spacer()
                Button(action: copyInviteCode) {
                    Text(copiedInviteCode ? String(localized: "已复制") : String(localized: "复制"))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(KelinColor.accent)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .frame(minHeight: 32)
                        .background(KelinColor.surfaceSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(String(localized: "复制邀请码"))
            }
            .padding(KelinSpacing.compact)
            .background(KelinColor.backgroundBase)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
            }

            HStack {
                Text(String(localized: "版本 V0 · 刻灵"))
                Spacer()
                Text(model.companionDayText)
            }
            .font(.system(size: 11))
            .foregroundStyle(KelinColor.textSecondary)
            .padding(.horizontal, 4)
        }
        .padding(.top, KelinSpacing.standard)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.white.opacity(0.05))
                .frame(height: 1)
        }
    }

    private var dismissDrag: some Gesture {
        DragGesture(minimumDistance: 12)
            .onChanged { value in
                guard !reduceMotion else { return }
                drawerOffset = max(0, value.translation.width)
            }
            .onEnded { value in
                if value.translation.width > 80 {
                    dismissDrawer()
                } else {
                    revealDrawer()
                }
            }
    }

    private func color(for tint: RoomMoreMenuTint) -> Color {
        switch tint {
        case .accent:
            KelinColor.accent
        case .cold:
            KelinColor.accentCold
        case .warm:
            KelinColor.accentWarm
        case .secondary:
            KelinColor.textSecondary
        }
    }

    private func revealDrawer() {
        let animation: Animation? = reduceMotion ? nil : .easeOut(duration: 0.28)
        withAnimation(animation) {
            drawerOffset = 0
        }
    }

    private func dismissDrawer() {
        guard !isDismissing else { return }
        isDismissing = true
        let duration: TimeInterval = reduceMotion ? 0 : 0.22
        withAnimation(reduceMotion ? nil : .easeIn(duration: duration)) {
            drawerOffset = RoomMoreMenuModel.drawerWidth
        }
        Task {
            if duration > 0 {
                try? await Task.sleep(for: .seconds(duration))
            }
            await MainActor.run {
                onDismiss()
            }
        }
    }

    private func copyInviteCode() {
        UIPasteboard.general.string = model.inviteCode
        copiedInviteCode = true
    }
}
