import SwiftUI

struct ReportView: View {
    @Bindable var viewModel: ReportViewModel
    let onBack: () -> Void
    let onTalk: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            header
            if let bannerMessage = viewModel.bannerMessage {
                Text(bannerMessage)
                    .kelinTypography(KelinTypography.label, color: KelinColor.accentWarm)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 6)
            } else if !viewModel.usesRemoteReportAPI {
                Text(String(localized: "鉴定接口尚未开通，这一页先按资格展示"))
                    .kelinTypography(KelinTypography.label, color: KelinColor.accentWarm)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 6)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: KelinSpacing.section) {
                    switch viewModel.snapshot.status {
                    case .locked:
                        lockedBody
                    case .generating:
                        generatingBody
                    case .partial, .ready, .failed:
                        cardBody
                    }
                }
                .padding(.horizontal, KelinSpacing.pageHorizontal)
                .padding(.top, KelinSpacing.small)
                .padding(.bottom, KelinSpacing.largeSection)
            }
            .scrollIndicators(.hidden)
        }
        .background { pageBackground }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
    }

    private var header: some View {
        HStack {
            Button(action: onBack) {
                HStack(spacing: 2) {
                    Image(systemName: "chevron.left")
                    Text(String(localized: "房间"))
                }
                .foregroundStyle(KelinColor.accent)
                .frame(minHeight: KelinSize.minimumTouchTarget)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(String(localized: "返回房间"))

            Spacer()
            Text(ReportPresentationRules.screenTitle())
                .font(.system(size: 17, weight: .semibold))
            Spacer()
            Color.clear.frame(width: 72, height: 1)
        }
        .padding(.horizontal, KelinSpacing.pageHorizontal)
        .frame(height: 48)
    }

    private var lockedBody: some View {
        VStack(alignment: .leading, spacing: KelinSpacing.compact) {
            Text(ReportPresentationRules.lockedTitle())
                .kelinTypography(KelinTypography.pageTitle)
            Text(ReportPresentationRules.lockedBody())
                .kelinTypography(KelinTypography.secondary, color: KelinColor.textSecondary)

            HStack(spacing: KelinSpacing.compact) {
                metricCard(
                    title: String(localized: "相伴时间"),
                    value: ReportPresentationRules.daysRemaining(viewModel.snapshot.eligibility.daysRemaining)
                )
                metricCard(
                    title: String(localized: "深入对话"),
                    value: ReportPresentationRules.roundsRemaining(viewModel.snapshot.eligibility.dialogueRoundsRemaining)
                )
            }

            lockedPreview
            Button(ReportPresentationRules.talkTitle(spiritName: viewModel.spiritName), action: onTalk)
                .buttonStyle(.kelinPrimary)
        }
    }

    private var generatingBody: some View {
        VStack(spacing: KelinSpacing.section) {
            Image(systemName: "lock.fill")
                .font(.system(size: 28))
                .foregroundStyle(KelinColor.accent)
            Text(ReportPresentationRules.generatingTitle())
                .kelinTypography(KelinTypography.cardTitle)
            Text(String(localized: "worker 还在写这张卡，先不要连点刷新。"))
                .kelinTypography(KelinTypography.secondary, color: KelinColor.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }

    private var cardBody: some View {
        VStack(alignment: .leading, spacing: KelinSpacing.compact) {
            if let card = viewModel.snapshot.card {
                Text(card.title)
                    .kelinTypography(KelinTypography.pageTitle)
                Text(card.roomWeather)
                    .kelinTypography(KelinTypography.secondary, color: KelinColor.textSecondary)
                ForEach(card.topTraits, id: \.dimension) { trait in
                    Text("\(trait.dimension) \(trait.value)")
                        .kelinTypography(KelinTypography.body, color: KelinColor.textSecondary)
                }
                ForEach(card.topMemories) { memory in
                    if memory.unavailable {
                        Text(String(localized: "这条记忆已经不可用"))
                            .kelinTypography(KelinTypography.secondary, color: KelinColor.textSecondary)
                    } else if let summary = memory.summary {
                        Text(summary)
                            .kelinTypography(KelinTypography.body)
                    }
                }
                if viewModel.snapshot.status == .ready, let line = card.signatureLine {
                    Text(line)
                        .kelinTypography(KelinTypography.cardTitle)
                } else if viewModel.snapshot.status == .partial {
                    Button(String(localized: "补签名句")) {
                        Task { await viewModel.requestSignatureLine() }
                    }
                    .buttonStyle(.kelinSecondary)
                }
            } else {
                Text(ReportPresentationRules.generatingTitle())
                    .kelinTypography(KelinTypography.cardTitle)
            }
        }
    }

    private var lockedPreview: some View {
        VStack(spacing: KelinSpacing.compact) {
            Image(systemName: "lock.fill")
                .foregroundStyle(KelinColor.accent)
            Text(ReportPresentationRules.generatingTitle())
                .kelinTypography(KelinTypography.cardTitle)
            Text(ReportPresentationRules.shareLocked())
                .kelinTypography(KelinTypography.label, color: KelinColor.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 220)
        .background(KelinColor.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .blur(radius: 0.4)
    }

    private func metricCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .kelinTypography(KelinTypography.label, color: KelinColor.textSecondary)
            Text(value)
                .kelinTypography(KelinTypography.cardTitle)
        }
        .padding(KelinSpacing.standard)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(KelinColor.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
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
}
