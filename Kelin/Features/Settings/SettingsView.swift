import SwiftUI
import UIKit

struct SettingsView: View {
    @Bindable var viewModel: SettingsViewModel
    let onBack: () -> Void
    let onFriends: () -> Void
    let onMemory: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            header
            if viewModel.isOffline {
                offlineBanner
            }
            if let bannerMessage = viewModel.bannerMessage {
                Text(bannerMessage)
                    .kelinTypography(KelinTypography.label, color: KelinColor.accentWarm)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 6)
                    .accessibilityLabel(bannerMessage)
            } else if !viewModel.usesRemoteSettingsAPI {
                Text(String(localized: "设置接口尚未开通，这一页先按稿展示"))
                    .kelinTypography(KelinTypography.label, color: KelinColor.accentWarm)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 6)
                    .accessibilityLabel(String(localized: "设置接口尚未开通，这一页先按稿展示"))
            }

            ScrollView {
                VStack(alignment: .leading, spacing: KelinSpacing.section) {
                    group(title: SettingsPresentationRules.spiritGroupTitle()) {
                        navigationRow(
                            title: SettingsPresentationRules.renameTitle(),
                            value: viewModel.spiritName
                        ) {
                            viewModel.draftName = viewModel.spiritName
                            viewModel.presentedSheet = .rename
                        }
                        rowDivider()
                        staticRow(
                            title: SettingsPresentationRules.spiritIDTitle(),
                            value: viewModel.spiritIDDisplay,
                            monospaced: true
                        )
                        rowDivider()
                        copyRow
                    }

                    group(title: SettingsPresentationRules.companionGroupTitle()) {
                        toggleRow(
                            title: SettingsPresentationRules.ttsTitle(),
                            isOn: viewModel.ttsOn,
                            set: viewModel.setTTSOn
                        )
                        rowDivider()
                        toggleRow(
                            title: SettingsPresentationRules.notificationTitle(),
                            isOn: viewModel.effectivePushOn,
                            set: viewModel.setPushOn
                        )
                        rowDivider()
                        navigationRow(
                            title: SettingsPresentationRules.dndTitle(),
                            value: viewModel.dndDisplay
                        ) {
                            viewModel.draftDNDStart = SettingsPresentationRules.date(fromHHMM: viewModel.dndStart)
                            viewModel.draftDNDEnd = SettingsPresentationRules.date(fromHHMM: viewModel.dndEnd)
                            viewModel.presentedSheet = .dnd
                        }
                        rowDivider()
                        toggleRow(
                            title: SettingsPresentationRules.locationWeatherTitle(),
                            isOn: viewModel.effectiveLocationWeatherOn,
                            set: viewModel.setLocationWeatherOn
                        )
                        rowDivider()
                        toggleRow(
                            title: SettingsPresentationRules.remoteSearchTitle(),
                            isOn: viewModel.remoteSearchOn,
                            set: viewModel.setRemoteSearchOn
                        )
                    }

                    group(title: SettingsPresentationRules.socialGroupTitle()) {
                        toggleRow(
                            title: SettingsPresentationRules.visitTitle(),
                            isOn: viewModel.visitOn,
                            set: viewModel.setVisitOn
                        )
                        rowDivider()
                        navigationRow(
                            title: SettingsPresentationRules.friendsTitle(),
                            value: "\(viewModel.friendCount)",
                            action: onFriends
                        )
                    }

                    group(title: SettingsPresentationRules.dataGroupTitle()) {
                        navigationRow(
                            title: SettingsPresentationRules.memoryCenterTitle(),
                            action: onMemory
                        )
                        rowDivider()
                        navigationRow(
                            title: SettingsPresentationRules.clearAllTitle(),
                            titleColor: KelinColor.textSecondary
                        ) {
                            viewModel.pendingDanger = .clearAllMemories
                        }
                        rowDivider()
                        navigationRow(
                            title: SettingsPresentationRules.deleteAccountTitle(),
                            titleColor: KelinColor.danger
                        ) {
                            viewModel.pendingDanger = .deleteAccount
                        }
                    }

                    group(title: SettingsPresentationRules.aboutGroupTitle()) {
                        navigationRow(title: SettingsPresentationRules.aiDisclosureTitle()) {
                            viewModel.presentedSheet = .aiDisclosure
                        }
                        rowDivider()
                        staticRow(
                            title: SettingsPresentationRules.versionTitle(),
                            value: viewModel.appVersion
                        )
                    }

                    Text(SettingsPresentationRules.footerCopy())
                        .kelinTypography(KelinTypography.secondary, color: KelinColor.textSecondary.opacity(0.6))
                        .frame(maxWidth: .infinity)
                        .padding(.top, KelinSpacing.small)
                        .padding(.bottom, KelinSpacing.standard)
                        .accessibilityLabel(SettingsPresentationRules.footerCopy())

                }
                .padding(.horizontal, KelinSpacing.pageHorizontal)
                .padding(.top, KelinSpacing.small)
                .padding(.bottom, KelinSpacing.largeSection)
            }
            .scrollIndicators(.hidden)
        }
        .background { pageBackground }
        .safeAreaPadding(.bottom, KelinSpacing.small)
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .alert(
            viewModel.pendingDanger.map(SettingsPresentationRules.confirmTitle(for:)) ?? "",
            isPresented: $viewModel.showsDangerConfirm
        ) {
            Button(String(localized: "取消"), role: .cancel) {}
            Button(
                viewModel.pendingDanger.map(SettingsPresentationRules.confirmAction(for:)) ?? "",
                role: .destructive
            ) {
                viewModel.confirmDanger()
            }
        } message: {
            Text(viewModel.pendingDanger.map(SettingsPresentationRules.confirmMessage(for:)) ?? "")
        }
        .alert(
            ErrorCopy.app(.permissionDenied(viewModel.pendingPermission ?? .notifications)).title,
            isPresented: $viewModel.showsPermissionHelp
        ) {
            Button(SettingsPresentationRules.laterTitle(), role: .cancel) {}
            Button(SettingsPresentationRules.goSettingsTitle()) {
                openSystemSettings()
            }
        } message: {
            Text(ErrorCopy.app(.permissionDenied(viewModel.pendingPermission ?? .notifications)).message)
        }
        .sheet(item: $viewModel.presentedSheet) { sheet in
            switch sheet {
            case .rename:
                renameSheet
            case .dnd:
                dndSheet
            case .aiDisclosure:
                aiDisclosureSheet
            }
        }
    }

    private var header: some View {
        HStack(spacing: 0) {
            Button(action: onBack) {
                HStack(spacing: 2) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 22, weight: .regular))
                    Text(String(localized: "房间"))
                        .font(.system(size: 16, weight: .regular))
                }
                .foregroundStyle(KelinColor.accent)
                .frame(minHeight: KelinSize.minimumTouchTarget, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(String(localized: "返回房间"))
            .frame(minWidth: 72, alignment: .leading)

            Spacer(minLength: 0)

            Text(SettingsPresentationRules.screenTitle())
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(KelinColor.textPrimary)
                .allowsHitTesting(false)

            Spacer(minLength: 0)

            Color.clear
                .frame(minWidth: 72, minHeight: 1)
        }
        .padding(.horizontal, KelinSpacing.pageHorizontal)
        .frame(height: SettingsLayout.headerHeight)
    }

    private var copyRow: some View {
        Button(action: copyInviteCode) {
            HStack {
                Text(SettingsPresentationRules.inviteCodeTitle())
                    .kelinTypography(KelinTypography.body)
                Spacer(minLength: 12)
                Text(viewModel.inviteCode)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(KelinColor.textSecondary)
                    .tracking(1.2)
                Image(systemName: viewModel.copiedInviteCode ? "checkmark" : "doc.on.doc")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(viewModel.copiedInviteCode ? KelinColor.primaryTint : KelinColor.textSecondary)
            }
            .padding(.horizontal, KelinSpacing.standard)
            .frame(minHeight: SettingsLayout.rowHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(SettingsPresentationRules.inviteCodeTitle())
        .accessibilityValue(viewModel.inviteCode)
        .accessibilityHint(String(localized: "复制邀请码"))
    }

    private func rowDivider() -> some View {
        Rectangle()
            .fill(Color.white.opacity(SettingsLayout.dividerOpacity))
            .frame(height: 1)
            .padding(.leading, KelinSpacing.standard)
            .accessibilityHidden(true)
    }

    private func group<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: KelinSpacing.compact) {
            Text(title)
                .kelinTypography(KelinTypography.secondary, color: KelinColor.textSecondary)
                .padding(.horizontal, KelinSpacing.standard)

            VStack(spacing: 0) {
                content()
            }
            .background(KelinColor.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: SettingsLayout.groupRadius, style: .continuous))
        }
    }

    private func navigationRow(
        title: String,
        value: String? = nil,
        titleColor: Color = KelinColor.textPrimary,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.system(size: 15, weight: titleColor == KelinColor.danger ? .medium : .regular))
                    .foregroundStyle(titleColor)
                Spacer(minLength: 12)
                if let value {
                    Text(value)
                        .kelinTypography(KelinTypography.body, color: KelinColor.textSecondary)
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(KelinColor.textSecondary.opacity(0.55))
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, KelinSpacing.standard)
            .frame(minHeight: SettingsLayout.rowHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityValue(value ?? "")
    }

    private func staticRow(title: String, value: String, monospaced: Bool = false) -> some View {
        HStack {
            Text(title)
                .kelinTypography(KelinTypography.body)
            Spacer(minLength: 12)
            Text(value)
                .font(monospaced ? .system(size: 13, design: .monospaced) : .system(size: 13))
                .foregroundStyle(KelinColor.textSecondary)
                .tracking(monospaced ? 1.0 : 0)
        }
        .padding(.horizontal, KelinSpacing.standard)
        .frame(minHeight: SettingsLayout.rowHeight)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityValue(value)
    }

    private func toggleRow(title: String, isOn: Bool, set: @escaping (Bool) -> Void) -> some View {
        HStack {
            Text(title)
                .kelinTypography(KelinTypography.body)
            Spacer(minLength: 12)
            Toggle("", isOn: Binding(get: { isOn }, set: set))
                .labelsHidden()
                .tint(KelinColor.accent)
                .accessibilityLabel(title)
                .accessibilityValue(isOn ? String(localized: "开") : String(localized: "关"))
        }
        .padding(.horizontal, KelinSpacing.standard)
        .frame(minHeight: SettingsLayout.rowHeight)
    }

    private var renameSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: KelinSpacing.section) {
                Text(SettingsPresentationRules.renameTitle())
                    .kelinTypography(KelinTypography.pageTitle)

                TextField(SettingsDraftFixtures.sampleName, text: $viewModel.draftName)
                    .textInputAutocapitalization(.never)
                    .padding(KelinSpacing.standard)
                    .frame(minHeight: KelinSize.inputMinimumHeight)
                    .background(KelinColor.surfaceSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: KelinRadius.standard, style: .continuous))
                    .accessibilityLabel(SettingsPresentationRules.renameTitle())

                Button(String(localized: "保存"), action: viewModel.commitRename)
                    .buttonStyle(.kelinPrimary)

                Button(String(localized: "取消")) {
                    viewModel.presentedSheet = nil
                }
                .buttonStyle(.kelinSecondary)

                Spacer()
            }
            .padding(KelinSpacing.pageHorizontal)
            .kelinScreenBackground()
            .toolbar(.hidden, for: .navigationBar)
        }
        .presentationDetents([.medium])
    }

    private var dndSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: KelinSpacing.section) {
                Text(SettingsPresentationRules.dndTitle())
                    .kelinTypography(KelinTypography.pageTitle)

                DatePicker(
                    String(localized: "开始"),
                    selection: $viewModel.draftDNDStart,
                    displayedComponents: .hourAndMinute
                )
                .tint(KelinColor.accent)
                .frame(minHeight: SettingsLayout.rowHeight)

                DatePicker(
                    String(localized: "结束"),
                    selection: $viewModel.draftDNDEnd,
                    displayedComponents: .hourAndMinute
                )
                .tint(KelinColor.accent)
                .frame(minHeight: SettingsLayout.rowHeight)

                Button(String(localized: "保存"), action: viewModel.commitDND)
                    .buttonStyle(.kelinPrimary)

                Button(String(localized: "取消")) {
                    viewModel.presentedSheet = nil
                }
                .buttonStyle(.kelinSecondary)

                Spacer()
            }
            .padding(KelinSpacing.pageHorizontal)
            .kelinScreenBackground()
            .toolbar(.hidden, for: .navigationBar)
        }
        .presentationDetents([.medium])
    }

    private var aiDisclosureSheet: some View {
        NavigationStack {
            ScrollView {
                Text(SettingsPresentationRules.aiDisclosureBody())
                    .kelinTypography(KelinTypography.body, color: KelinColor.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(KelinSpacing.pageHorizontal)
                    .padding(.vertical, KelinSpacing.section)
            }
            .kelinScreenBackground()
            .navigationTitle(SettingsPresentationRules.aiDisclosureTitle())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "关闭")) {
                        viewModel.presentedSheet = nil
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var offlineBanner: some View {
        Text(String(localized: "连不上，房间还在"))
            .kelinTypography(KelinTypography.label, color: KelinColor.accentWarm)
            .frame(maxWidth: .infinity)
            .padding(.vertical, KelinSpacing.small)
            .background(KelinColor.surfaceSecondary.opacity(0.72))
    }

    private var pageBackground: some View {
        KelinColor.backgroundBase
            .ignoresSafeArea()
            .overlay {
                RadialGradient(
                    colors: [KelinColor.backgroundCenter, KelinColor.backgroundBase],
                    center: UnitPoint(x: 0.5, y: 0.28),
                    startRadius: 0,
                    endRadius: 460
                )
                .ignoresSafeArea()
            }
    }

    private func copyInviteCode() {
        UIPasteboard.general.string = viewModel.inviteCode
        viewModel.copyInviteCode()
    }

    private func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

extension SettingsSheet: Identifiable {
    var id: String {
        switch self {
        case .rename: "rename"
        case .dnd: "dnd"
        case .aiDisclosure: "aiDisclosure"
        }
    }
}

#Preview("设置稿") {
    SettingsView(
        viewModel: SettingsViewModel(
            spiritName: SettingsDraftFixtures.sampleName,
            spiritID: SettingsDraftFixtures.sampleSpiritID,
            inviteCode: SettingsDraftFixtures.sampleInviteCode,
            preferences: SettingsDraftFixtures.defaultPreferences,
            friendCount: SettingsDraftFixtures.sampleFriendCount,
            isOffline: false
        ),
        onBack: {},
        onFriends: {},
        onMemory: {}
    )
}
