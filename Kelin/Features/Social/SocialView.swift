import SwiftUI
import UIKit

struct SocialView: View {
    @Bindable var viewModel: SocialViewModel
    let onBack: () -> Void

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
            } else if !viewModel.usesRemoteSocialAPI {
                Text(String(localized: "社交接口尚未开通，这一页先按稿展示"))
                    .kelinTypography(KelinTypography.label, color: KelinColor.accentWarm)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 6)
                    .accessibilityLabel(String(localized: "社交接口尚未开通，这一页先按稿展示"))
            }

            ScrollView {
                VStack(alignment: .leading, spacing: KelinSpacing.section) {
                    inviteCard
                    visitsSection
                    friendsSection
                    visitToggleCard
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
            SocialPresentationRules.unfriendTitle(),
            isPresented: $viewModel.showsUnfriendConfirm
        ) {
            Button(String(localized: "取消"), role: .cancel) {}
            Button(SocialPresentationRules.unfriendAction(), role: .destructive) {
                viewModel.confirmUnfriend()
            }
        } message: {
            Text(SocialPresentationRules.unfriendMessage())
        }
        .sheet(isPresented: $viewModel.showsAddFriend) {
            addFriendSheet
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

            Text(SocialPresentationRules.screenTitle())
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(KelinColor.textPrimary)
                .allowsHitTesting(false)

            Spacer(minLength: 0)

            Color.clear
                .frame(minWidth: 72, minHeight: 1)
        }
        .padding(.horizontal, KelinSpacing.pageHorizontal)
        .frame(height: SocialLayout.headerHeight)
    }

    private var inviteCard: some View {
        VStack(alignment: .leading, spacing: KelinSpacing.standard) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(SocialPresentationRules.inviteLabel())
                        .kelinTypography(KelinTypography.label, color: KelinColor.textSecondary)
                    Text(viewModel.inviteCode)
                        .font(.system(size: 17, weight: .semibold, design: .monospaced))
                        .foregroundStyle(KelinColor.textPrimary)
                        .tracking(4)
                        .accessibilityLabel(SocialPresentationRules.inviteLabel())
                        .accessibilityValue(viewModel.inviteCode)
                }
                Spacer()
                Image(systemName: "qrcode")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(KelinColor.primaryTint)
                    .frame(width: 40, height: 40)
                    .background(KelinColor.accentSurface)
                    .clipShape(Circle())
                    .accessibilityHidden(true)
            }

            HStack(spacing: KelinSpacing.small) {
                Button(action: copyInviteCode) {
                    Label(
                        viewModel.copiedInviteCode ? String(localized: "已复制") : String(localized: "复制"),
                        systemImage: "doc.on.doc"
                    )
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(KelinColor.textPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: KelinSize.secondaryButtonHeight)
                    .background(KelinColor.accent)
                    .clipShape(RoundedRectangle(cornerRadius: KelinRadius.small, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(String(localized: "复制邀请码"))

                ShareLink(item: viewModel.inviteCode) {
                    Label(String(localized: "分享"), systemImage: "square.and.arrow.up")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(KelinColor.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: KelinSize.secondaryButtonHeight)
                        .background(KelinColor.surfaceSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: KelinRadius.small, style: .continuous))
                }
                .accessibilityLabel(String(localized: "分享邀请码"))
            }

            Button {
                viewModel.showsAddFriend = true
            } label: {
                Text(SocialDraftFixtures.enterFriendCodeTitle)
                    .kelinTypography(KelinTypography.secondary, color: KelinColor.textSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: KelinSize.minimumTouchTarget)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(SocialDraftFixtures.enterFriendCodeTitle)
        }
        .padding(KelinSpacing.standard)
        .background(KelinColor.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: SocialLayout.cardRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: SocialLayout.cardRadius, style: .continuous)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        }
    }

    private var visitsSection: some View {
        VStack(alignment: .leading, spacing: KelinSpacing.compact) {
            HStack {
                Text(viewModel.visitsSectionTitle)
                    .kelinTypography(KelinTypography.label, color: KelinColor.textSecondary)
                    .textCase(.uppercase)
                Spacer()
                Text(viewModel.visitsSectionMeta)
                    .kelinTypography(KelinTypography.label, color: KelinColor.textSecondary)
            }
            .padding(.horizontal, 4)

            if let postcard = viewModel.postcard {
                postcardCard(postcard)
            } else {
                emptyVisitsCard
            }
        }
    }

    private var emptyVisitsCard: some View {
        VStack(spacing: KelinSpacing.compact) {
            Image(systemName: "figure.walk")
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(KelinColor.accent.opacity(0.8))
                .frame(width: 56, height: 56)
                .background(KelinColor.accentSurface.opacity(0.8))
                .clipShape(Circle())
                .overlay {
                    Circle().stroke(Color.white.opacity(0.1), lineWidth: 1)
                }
                .accessibilityHidden(true)

            Text(SocialPresentationRules.emptyFootprintsTitle())
                .kelinTypography(KelinTypography.cardTitle)
                .foregroundStyle(KelinColor.textPrimary)
                .multilineTextAlignment(.center)

            Text(SocialPresentationRules.emptyFootprintsBody())
                .kelinTypography(KelinTypography.secondary, color: KelinColor.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 280)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, KelinSpacing.standard)
        .padding(.vertical, 40)
        .background(KelinColor.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: SocialLayout.cardRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: SocialLayout.cardRadius, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            SocialPresentationRules.emptyFootprintsTitle()
                + "。"
                + SocialPresentationRules.emptyFootprintsBody()
        )
    }

    private func postcardCard(_ postcard: SocialPostcardFixture) -> some View {
        VStack(alignment: .leading, spacing: KelinSpacing.standard) {
            HStack {
                HStack(spacing: KelinSpacing.compact) {
                    if postcard.isUnread {
                        Circle()
                            .fill(KelinColor.accent)
                            .frame(width: SocialLayout.unreadDot, height: SocialLayout.unreadDot)
                            .accessibilityLabel(String(localized: "未读明信片"))
                    }
                    Text(postcard.senderTitle)
                        .kelinTypography(KelinTypography.cardTitle)
                        .foregroundStyle(KelinColor.textPrimary)
                }
                Spacer()
                Text(postcard.timeLabel)
                    .kelinTypography(KelinTypography.secondary, color: KelinColor.textSecondary)
            }

            ZStack {
                RoundedRectangle(cornerRadius: SocialLayout.rowRadius, style: .continuous)
                    .fill(KelinColor.backgroundBase)
                Image(systemName: "door.left.hand.closed")
                    .font(.system(size: 44, weight: .light))
                    .foregroundStyle(KelinColor.accentCold.opacity(0.4))
            }
            .frame(height: SocialLayout.postcardArtHeight)
            .clipShape(RoundedRectangle(cornerRadius: SocialLayout.rowRadius, style: .continuous))
            .accessibilityHidden(true)

            Text(postcard.body)
                .kelinTypography(KelinTypography.body, color: KelinColor.textPrimary.opacity(0.9))
                .italic()

            HStack {
                Spacer()
                Button(action: viewModel.replyToPostcard) {
                    HStack(spacing: 4) {
                        Text(SocialDraftFixtures.postcardReplyTitle)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .kelinTypography(KelinTypography.secondary, color: KelinColor.primaryTint)
                    .frame(minHeight: KelinSize.minimumTouchTarget)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(SocialDraftFixtures.postcardReplyTitle)
            }
        }
        .padding(KelinSpacing.standard)
        .background(KelinColor.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: SocialLayout.cardRadius, style: .continuous))
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.markPostcardRead()
        }
        .accessibilityElement(children: .contain)
        .accessibilityHint(postcard.isUnread ? String(localized: "点按去掉未读标记") : "")
    }

    private var friendsSection: some View {
        VStack(alignment: .leading, spacing: KelinSpacing.compact) {
            HStack {
                Text(SocialDraftFixtures.friendsSectionTitle)
                    .kelinTypography(KelinTypography.label, color: KelinColor.textSecondary)
                    .textCase(.uppercase)
                Spacer()
                if let note = viewModel.friendsSectionNote {
                    Text(note)
                        .kelinTypography(KelinTypography.label, color: KelinColor.textSecondary)
                        .italic()
                        .multilineTextAlignment(.trailing)
                }
            }
            .padding(.horizontal, 4)

            VStack(spacing: KelinSpacing.small) {
                ForEach(viewModel.visiblePeers) { peer in
                    peerRow(peer)
                }
            }
        }
    }

    private func peerRow(_ peer: SocialPeerFixture) -> some View {
        Button {
            viewModel.selectPeer(peer)
        } label: {
            HStack(spacing: KelinSpacing.compact) {
                Image(systemName: peer.symbol)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(tint(for: peer.tint).opacity(peer.kind == .npc ? 0.6 : 1))
                    .frame(width: SocialLayout.avatarWell, height: SocialLayout.avatarWell)
                    .background(peer.kind == .friend ? KelinColor.accentSurface : KelinColor.surfaceSecondary)
                    .clipShape(Circle())
                    .overlay {
                        Circle().stroke(Color.white.opacity(0.05), lineWidth: 1)
                    }
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(peer.title)
                        .kelinTypography(KelinTypography.cardTitle)
                        .foregroundStyle(KelinColor.textPrimary.opacity(peer.kind == .npc ? 0.9 : 1))
                    Text(peer.subtitle)
                        .kelinTypography(KelinTypography.secondary, color: KelinColor.textSecondary.opacity(0.85))
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(KelinColor.textSecondary.opacity(peer.kind == .npc ? 0.4 : 0.7))
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, KelinSpacing.standard)
            .frame(minHeight: 64)
            .background(KelinColor.surfacePrimary.opacity(peer.kind == .npc ? 0.7 : 1))
            .clipShape(RoundedRectangle(cornerRadius: SocialLayout.rowRadius, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(peer.kind != .friend)
        .accessibilityLabel(peer.title)
        .accessibilityHint(peer.kind == .friend ? SocialPresentationRules.unfriendTitle() : peer.subtitle)
        .accessibilityAddTraits(peer.kind == .npc ? [.isStaticText] : [])
    }

    private var visitToggleCard: some View {
        HStack(alignment: .center, spacing: KelinSpacing.compact) {
            VStack(alignment: .leading, spacing: 4) {
                Text(SocialDraftFixtures.allowVisitsTitle)
                    .kelinTypography(KelinTypography.cardTitle)
                    .foregroundStyle(KelinColor.textPrimary)
                Text(viewModel.visitHint)
                    .kelinTypography(KelinTypography.secondary, color: KelinColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 12)
            Toggle("", isOn: Binding(
                get: { viewModel.visitEnabled },
                set: { viewModel.setVisitEnabled($0) }
            ))
            .labelsHidden()
            .tint(KelinColor.accent)
            .accessibilityLabel(SocialDraftFixtures.allowVisitsTitle)
            .accessibilityValue(viewModel.visitEnabled ? String(localized: "开") : String(localized: "关"))
        }
        .padding(KelinSpacing.standard)
        .background(KelinColor.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: SocialLayout.cardRadius, style: .continuous))
    }

    private var addFriendSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: KelinSpacing.section) {
                Text(SocialDraftFixtures.enterFriendCodeTitle)
                    .kelinTypography(KelinTypography.pageTitle)

                TextField(String(localized: "好友邀请码"), text: $viewModel.draftInviteCode)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .font(.system(size: 20, weight: .semibold, design: .monospaced))
                    .padding(KelinSpacing.standard)
                    .frame(minHeight: KelinSize.inputMinimumHeight)
                    .background(KelinColor.surfaceSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: KelinRadius.standard, style: .continuous))
                    .accessibilityLabel(String(localized: "好友邀请码"))

                Button(String(localized: "加入"), action: viewModel.submitFriendCode)
                    .buttonStyle(.kelinPrimary)

                Button(String(localized: "取消")) {
                    viewModel.showsAddFriend = false
                    viewModel.draftInviteCode = ""
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

    private func tint(for tint: SocialPeerTint) -> Color {
        switch tint {
        case .accent:
            KelinColor.accent
        case .warm:
            KelinColor.accentWarm
        case .cold:
            KelinColor.accentCold
        }
    }
}

#Preview("无好友") {
    SocialView(
        viewModel: SocialViewModel(inviteCode: "ABCD2345", isOffline: false, visitEnabled: true),
        onBack: {}
    )
}

#Preview("未读明信片") {
    SocialView(
        viewModel: SocialViewModel(
            inviteCode: "ABCD2345",
            isOffline: false,
            visitEnabled: true,
            phase: .unreadPostcard
        ),
        onBack: {}
    )
}
