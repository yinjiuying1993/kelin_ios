import SwiftUI

struct PactView: View {
    @Bindable var viewModel: PactViewModel
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            header
            if viewModel.isOffline {
                offlineBanner
            }
            if let statusMessage = viewModel.statusMessage {
                Text(statusMessage)
                    .kelinTypography(KelinTypography.label, color: KelinColor.accentWarm)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 6)
                    .accessibilityLabel(statusMessage)
            } else if !viewModel.usesRemotePactAPI {
                Text(String(localized: "共学接口尚未开通，这一页先按稿展示"))
                    .kelinTypography(KelinTypography.label, color: KelinColor.accentWarm)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 6)
                    .accessibilityLabel(String(localized: "共学接口尚未开通，这一页先按稿展示"))
            }

            Group {
                switch viewModel.phase {
                case .unsigned:
                    unsignedBody
                case .active:
                    activeBody
                case .answering, .reviewing:
                    quizBody
                case .todayCompleted:
                    todayCompletedBody
                case .completed:
                    completedBody
                }
            }
        }
        .background { pageBackground }
        .safeAreaPadding(.bottom, KelinSpacing.small)
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .alert(
            PactPresentationRules.skipConfirmTitle(),
            isPresented: $viewModel.showsSkipConfirm
        ) {
            Button(String(localized: "取消"), role: .cancel) {}
            Button(String(localized: "跳过今天"), role: .destructive) {
                viewModel.confirmSkipToday()
            }
        } message: {
            Text(PactPresentationRules.skipConfirmMessage())
        }
        .sheet(isPresented: $viewModel.showsWeekRecap) {
            weekRecapSheet
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

            Text(PactPresentationRules.headerTitle(for: viewModel.phase))
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(KelinColor.textPrimary)
                .allowsHitTesting(false)

            Spacer(minLength: 0)

            headerTrailing
                .frame(minWidth: 72, alignment: .trailing)
        }
        .padding(.horizontal, KelinSpacing.pageHorizontal)
        .frame(height: PactLayout.headerHeight)
    }

    @ViewBuilder
    private var headerTrailing: some View {
        switch viewModel.phase {
        case .unsigned:
            Text(PactPresentationRules.headerSubtitle(for: .unsigned, dayIndex: viewModel.dayIndex))
                .kelinTypography(KelinTypography.secondary, color: KelinColor.textSecondary.opacity(0.75))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(KelinColor.surfaceSecondary.opacity(0.7))
                .clipShape(Capsule())
        case .completed:
            Image(systemName: "sparkle")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(KelinColor.accent)
                .frame(width: 32, height: 32)
                .accessibilityHidden(true)
        default:
            Text(PactPresentationRules.headerSubtitle(for: viewModel.phase, dayIndex: viewModel.dayIndex))
                .kelinTypography(KelinTypography.secondary, color: KelinColor.textSecondary)
                .multilineTextAlignment(.trailing)
        }
    }

    private var unsignedBody: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: KelinSpacing.section) {
                VStack(alignment: .leading, spacing: KelinSpacing.small) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(KelinColor.accent)
                            .frame(width: 6, height: 6)
                        Text(String(localized: "Pact of the Week"))
                            .kelinTypography(KelinTypography.label, color: KelinColor.textSecondary)
                    }
                    Text(String(localized: "立下一周的约定"))
                        .kelinTypography(KelinTypography.largeTitle)
                        .foregroundStyle(KelinColor.textPrimary)
                    Text(PactPresentationRules.emptyWeekCopy() + "。")
                        .kelinTypography(KelinTypography.body, color: KelinColor.textSecondary)
                    Text(String(localized: "选择一个方向，雾生会在每晚与你回讲并点亮学者纹。"))
                        .kelinTypography(KelinTypography.secondary, color: KelinColor.textSecondary.opacity(0.8))
                }

                VStack(spacing: KelinSpacing.compact) {
                    themeCard(.interview)
                    themeCard(.notes)
                }

                HStack(alignment: .top, spacing: KelinSpacing.compact) {
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(KelinColor.accentWarm)
                    Text(String(localized: "静候心绪落定。每周初定契，七日共此灯火。"))
                        .kelinTypography(KelinTypography.secondary, color: KelinColor.textSecondary)
                }
                .padding(KelinSpacing.compact)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(KelinColor.surfacePrimary.opacity(0.4))
                .clipShape(RoundedRectangle(cornerRadius: KelinRadius.small, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: KelinRadius.small, style: .continuous)
                        .stroke(Color.white.opacity(0.04), lineWidth: 1)
                }

                VStack(spacing: KelinSpacing.small) {
                    Button(viewModel.commitTitle, action: viewModel.commitUnsigned)
                        .buttonStyle(.kelinPrimary)
                        .accessibilityLabel(viewModel.commitTitle)

                    HStack(spacing: 4) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 11))
                        Text(String(localized: "契约一旦立下，7日内不可更换内容"))
                    }
                    .kelinTypography(KelinTypography.label, color: KelinColor.textSecondary.opacity(0.75))
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, KelinSpacing.pageHorizontal)
            .padding(.top, KelinSpacing.small)
            .padding(.bottom, KelinSpacing.largeSection)
        }
        .scrollIndicators(.hidden)
    }

    private func themeCard(_ theme: PactTheme) -> some View {
        let selected = viewModel.selectedTheme == theme
        return Button {
            viewModel.selectTheme(theme)
        } label: {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text(PactPresentationRules.themeKindLabel(theme))
                        .kelinTypography(KelinTypography.label, color: selected ? KelinColor.primaryTint : KelinColor.textSecondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(selected ? KelinColor.accentSurface.opacity(0.9) : KelinColor.surfaceSecondary.opacity(0.7))
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    Spacer()
                    ZStack {
                        Circle()
                            .stroke(selected ? Color.clear : KelinColor.textSecondary.opacity(0.4), lineWidth: 1.5)
                            .background(Circle().fill(selected ? KelinColor.accent : Color.clear))
                        if selected {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(KelinColor.backgroundBase)
                        }
                    }
                    .frame(width: 20, height: 20)
                }

                HStack(alignment: .top, spacing: 14) {
                    Image(systemName: theme == .interview ? "book.fill" : "doc.text.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(selected ? KelinColor.primaryTint : KelinColor.textSecondary)
                        .frame(width: PactLayout.themeIconWell, height: PactLayout.themeIconWell)
                        .background(selected ? KelinColor.accentSurface.opacity(0.8) : KelinColor.surfaceSecondary.opacity(0.8))
                        .clipShape(RoundedRectangle(cornerRadius: KelinRadius.small, style: .continuous))
                    VStack(alignment: .leading, spacing: 4) {
                        Text(PactPresentationRules.themeTitle(theme))
                            .kelinTypography(KelinTypography.cardTitle)
                            .foregroundStyle(KelinColor.textPrimary)
                        Text(PactPresentationRules.themeBody(theme))
                            .kelinTypography(KelinTypography.secondary, color: KelinColor.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                HStack {
                    Text(PactPresentationRules.themeMeta(theme))
                        .kelinTypography(KelinTypography.label, color: KelinColor.textSecondary)
                    Spacer()
                    Text(PactPresentationRules.themeSideLabel(theme))
                        .kelinTypography(
                            KelinTypography.label,
                            color: selected ? KelinColor.primaryTint.opacity(0.8) : KelinColor.textSecondary.opacity(0.6)
                        )
                }
                .padding(.top, 4)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(Color.white.opacity(selected ? 0.06 : 0.04))
                        .frame(height: 1)
                }
            }
            .padding(KelinSpacing.standard)
            .background(selected ? Color(red: 28 / 255, green: 32 / 255, blue: 50 / 255) : KelinColor.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: PactLayout.cardRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: PactLayout.cardRadius, style: .continuous)
                    .stroke(selected ? KelinColor.accent : Color.white.opacity(0.08), lineWidth: selected ? 1.5 : 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(PactPresentationRules.themeTitle(theme))
        .accessibilityAddTraits(selected ? [.isSelected] : [])
    }

    private var activeBody: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: KelinSpacing.section) {
                heroCard
                tonightSection
                if !viewModel.usesRemotePactAPI {
                    lastNightCard
                }
            }
            .padding(.horizontal, KelinSpacing.pageHorizontal)
            .padding(.top, KelinSpacing.small)
            .padding(.bottom, KelinSpacing.largeSection)
        }
        .scrollIndicators(.hidden)
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: KelinSpacing.section) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(PactPresentationRules.themeTitle(viewModel.selectedTheme))
                        .kelinTypography(KelinTypography.cardTitle)
                        .foregroundStyle(KelinColor.textPrimary)
                    HStack(spacing: 6) {
                        Circle()
                            .fill(KelinColor.accent)
                            .frame(width: 6, height: 6)
                        Text(
                            viewModel.usesRemotePactAPI
                                ? String(localized: "题目与进度以服务端为准")
                                : PactDraftFixtures.organizingTopic
                        )
                            .kelinTypography(KelinTypography.secondary, color: KelinColor.textSecondary)
                    }
                }
                Spacer()
                Image(systemName: "book")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(KelinColor.accent)
                    .frame(width: PactLayout.themeIconWell, height: PactLayout.themeIconWell)
                    .background(KelinColor.surfaceSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: KelinRadius.small, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: KelinRadius.small, style: .continuous)
                            .stroke(Color.white.opacity(0.05), lineWidth: 1)
                    }
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(String(localized: "完成进度"))
                        .kelinTypography(KelinTypography.label, color: KelinColor.textSecondary)
                    Spacer()
                    Text(String(localized: "完整度 \(viewModel.completenessPercent)%"))
                        .kelinTypography(KelinTypography.secondary, color: KelinColor.textSecondary)
                }
                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule().fill(KelinColor.surfaceSecondary)
                        Capsule()
                            .fill(KelinColor.accent)
                            .frame(width: proxy.size.width * CGFloat(viewModel.completenessPercent) / 100)
                    }
                }
                .frame(height: PactLayout.progressHeight)
            }
        }
        .padding(KelinSpacing.standard)
        .background(KelinColor.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: PactLayout.cardRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: PactLayout.cardRadius, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        }
    }

    private var tonightSection: some View {
        VStack(alignment: .leading, spacing: KelinSpacing.compact) {
            Text(String(localized: "今晚的回讲"))
                .kelinTypography(KelinTypography.secondary, color: KelinColor.textSecondary)
                .padding(.horizontal, 4)

            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(viewModel.tonightPrompt ?? String(localized: "开始今天的回讲"))
                        .kelinTypography(KelinTypography.cardTitle)
                        .foregroundStyle(KelinColor.textPrimary)
                    if !viewModel.usesRemotePactAPI {
                        Text(PactDraftFixtures.tonightHint)
                            .kelinTypography(KelinTypography.body, color: KelinColor.textSecondary)
                    }
                }

                VStack(spacing: 4) {
                    Button(PactPresentationRules.startTodayTitle(), action: viewModel.startToday)
                        .buttonStyle(.kelinPrimary)

                    Button(String(localized: "跳过今天")) {
                        viewModel.showsSkipConfirm = true
                    }
                    .font(.system(size: 15))
                    .foregroundStyle(KelinColor.textSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: KelinSize.minimumTouchTarget)
                    .contentShape(Rectangle())
                    .buttonStyle(.plain)
                    .accessibilityLabel(String(localized: "跳过今天"))
                }
            }
            .padding(KelinSpacing.standard)
            .background(KelinColor.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: PactLayout.cardRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: PactLayout.cardRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            }
        }
    }

    private var lastNightCard: some View {
        VStack(alignment: .leading, spacing: KelinSpacing.compact) {
            HStack {
                Text(String(localized: "昨晚"))
                    .kelinTypography(KelinTypography.secondary, color: KelinColor.textSecondary)
                Spacer()
                Text(String(localized: "昨日记录"))
                    .kelinTypography(KelinTypography.label, color: KelinColor.textSecondary.opacity(0.75))
            }
            .padding(.horizontal, 4)

            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text(String(localized: "正确 \(PactDraftFixtures.sampleLastNightCorrect)/\(PactDraftFixtures.sampleLastNightTotal)"))
                        .kelinTypography(KelinTypography.body)
                        .foregroundStyle(KelinColor.textPrimary)
                    Spacer()
                    HStack(spacing: 6) {
                        Circle()
                            .fill(KelinColor.accent)
                            .frame(width: 6, height: 6)
                        Text(String(localized: "已归档"))
                            .kelinTypography(KelinTypography.label, color: KelinColor.primaryTint)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(KelinColor.accentSurface)
                    .clipShape(Capsule())
                }

                Rectangle()
                    .fill(Color.white.opacity(0.04))
                    .frame(height: 1)

                HStack(spacing: 8) {
                    Image(systemName: "note.text")
                        .font(.system(size: 16))
                        .foregroundStyle(KelinColor.textSecondary)
                    Text(String(localized: "主要错题 · \(PactDraftFixtures.sampleLastNightMiss)"))
                        .kelinTypography(KelinTypography.body, color: KelinColor.textSecondary)
                        .lineLimit(1)
                }
            }
            .padding(KelinSpacing.standard)
            .background(KelinColor.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: PactLayout.cardRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: PactLayout.cardRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            }
        }
    }

    private var quizBody: some View {
        VStack(alignment: .leading, spacing: KelinSpacing.standard) {
            if let question = viewModel.currentQuestion {
                let index: Int = {
                    if case let .answering(value) = viewModel.phase { return value }
                    if case let .reviewing(value) = viewModel.phase { return value }
                    return 0
                }()
                Text(String(localized: "第 \(index + 1) 题 / \(PactPresentationRules.dailyQuestionCount) 题"))
                    .kelinTypography(KelinTypography.label, color: KelinColor.accent)
                Text(question.prompt)
                    .kelinTypography(KelinTypography.cardTitle)
                    .foregroundStyle(KelinColor.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                if case .answering = viewModel.phase {
                    TextEditor(text: $viewModel.draftAnswer)
                        .font(.system(size: 15))
                        .foregroundStyle(KelinColor.textPrimary)
                        .scrollContentBackground(.hidden)
                        .padding(KelinSpacing.compact)
                        .frame(minHeight: 140)
                        .background(KelinColor.surfacePrimary)
                        .clipShape(RoundedRectangle(cornerRadius: KelinRadius.standard, style: .continuous))
                        .accessibilityLabel(String(localized: "回答"))

                    Button(String(localized: "提交")) {
                        viewModel.submitAnswer()
                    }
                    .buttonStyle(.kelinPrimary)
                    .disabled(!viewModel.canSubmitAnswer)
                    .opacity(viewModel.canSubmitAnswer ? 1 : 0.45)
                } else {
                    feedbackCard(question)
                    Button(index + 1 < viewModel.questions.count ? String(localized: "下一题") : String(localized: "结束今天")) {
                        viewModel.continueAfterReview()
                    }
                    .buttonStyle(.kelinPrimary)
                }
            }
            Spacer()
        }
        .padding(.horizontal, KelinSpacing.pageHorizontal)
        .padding(.top, KelinSpacing.small)
        .padding(.bottom, KelinSpacing.standard)
    }

    private func feedbackCard(_ question: PactQuestionFixture) -> some View {
        VStack(alignment: .leading, spacing: KelinSpacing.compact) {
            Text(String(localized: "它说"))
                .kelinTypography(KelinTypography.label, color: KelinColor.accent)
            Text(question.comment)
                .kelinTypography(KelinTypography.body)
                .foregroundStyle(KelinColor.textPrimary)
            Text(String(localized: "改进点"))
                .kelinTypography(KelinTypography.label, color: KelinColor.textSecondary)
            Text(question.improvement)
                .kelinTypography(KelinTypography.body)
                .foregroundStyle(KelinColor.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(KelinSpacing.standard)
        .background(KelinColor.surfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: PactLayout.cardRadius, style: .continuous))
    }

    private var todayCompletedBody: some View {
        VStack(alignment: .leading, spacing: KelinSpacing.standard) {
            Text(PactPresentationRules.todayCompletedButtonTitle())
                .kelinTypography(KelinTypography.pageTitle)
                .foregroundStyle(KelinColor.textPrimary)
            Text(String(localized: "今天的一个改进点"))
                .kelinTypography(KelinTypography.secondary, color: KelinColor.textSecondary)
            Text(viewModel.latestImprovement ?? String(localized: "今天的回讲已经记下。"))
                .kelinTypography(KelinTypography.body)
                .foregroundStyle(KelinColor.textPrimary)
                .padding(KelinSpacing.standard)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(KelinColor.surfaceSecondary)
                .clipShape(RoundedRectangle(cornerRadius: PactLayout.cardRadius, style: .continuous))

            Spacer()

            Button(PactPresentationRules.todayCompletedButtonTitle()) {}
                .buttonStyle(.kelinPrimary)
                .disabled(true)
                .opacity(0.45)
        }
        .padding(.horizontal, KelinSpacing.pageHorizontal)
        .padding(.top, KelinSpacing.small)
        .padding(.bottom, KelinSpacing.standard)
    }

    private var completedBody: some View {
        ScrollView {
            VStack(spacing: KelinSpacing.standard) {
                scholarMarkHero
                completedStats
                impactNote
                VStack(spacing: KelinSpacing.compact) {
                    Button {
                        onBack()
                    } label: {
                        HStack(spacing: 8) {
                            Text(PactPresentationRules.bringRuneHomeTitle())
                            Image(systemName: "arrow.right")
                                .font(.system(size: 16, weight: .semibold))
                        }
                    }
                    .buttonStyle(.kelinPrimary)

                    Button(String(localized: "回顾 7 日答卷")) {
                        viewModel.showsWeekRecap = true
                    }
                    .buttonStyle(.kelinSecondary)
                }
            }
            .padding(.horizontal, KelinSpacing.pageHorizontal)
            .padding(.top, KelinSpacing.small)
            .padding(.bottom, KelinSpacing.largeSection)
        }
        .scrollIndicators(.hidden)
    }

    private var scholarMarkHero: some View {
        VStack(spacing: KelinSpacing.compact) {
            ScholarMarkEmblem()
                .frame(width: PactLayout.scholarMarkSize, height: PactLayout.scholarMarkSize)
                .padding(.bottom, 4)
            Text(PactPresentationRules.headerSubtitle(for: .completed, dayIndex: viewModel.dayIndex))
                .kelinTypography(KelinTypography.label, color: KelinColor.accent.opacity(0.9))
            Text(String(localized: "STAR 学者纹 · 已点亮"))
                .kelinTypography(KelinTypography.largeTitle)
                .foregroundStyle(KelinColor.textPrimary)
                .multilineTextAlignment(.center)
            Text(String(localized: "相处，在身上留下了痕迹。\n雾生已将这段思考凝结入体。"))
                .kelinTypography(KelinTypography.secondary, color: KelinColor.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, KelinSpacing.standard)
    }

    private var completedStats: some View {
        VStack(alignment: .leading, spacing: KelinSpacing.standard) {
            HStack {
                HStack(spacing: 8) {
                    Capsule()
                        .fill(KelinColor.accent)
                        .frame(width: 6, height: 14)
                    Text(String(localized: "共学答卷沉淀"))
                        .kelinTypography(KelinTypography.cardTitle)
                        .foregroundStyle(KelinColor.textPrimary)
                }
                Spacer()
                Text(String(localized: "已结契"))
                    .kelinTypography(KelinTypography.label, color: KelinColor.primaryTint)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(KelinColor.accentSurface)
                    .clipShape(Capsule())
            }

            completedMetric(
                title: String(localized: "契约周期"),
                value: viewModel.usesRemotePactAPI
                    ? String(localized: "7 日共学")
                    : String(localized: "7 天全勤完成（共 21 题）"),
                symbol: "calendar"
            )
            completedMetric(
                title: String(localized: "最终完整度"),
                value: "\(viewModel.completenessPercent)%",
                symbol: "chart.line.uptrend.xyaxis",
                symbolColor: KelinColor.accentCold
            )
            if !viewModel.usesRemotePactAPI {
                completedMetric(
                    title: String(localized: "主要沉淀"),
                    value: String(localized: "面试题 · 项目两难权衡与量化结果"),
                    symbol: "brain.head.profile",
                    symbolColor: KelinColor.accentWarm,
                    stacked: true
                )
                completedMetric(
                    title: String(localized: "留存错题归档"),
                    value: PactDraftFixtures.sampleMissArchive,
                    symbol: "checkmark.circle",
                    symbolColor: KelinColor.success,
                    stacked: true
                )
            }

            if !viewModel.usesRemotePactAPI {
                HStack(alignment: .top, spacing: KelinSpacing.compact) {
                    Image(systemName: "quote.opening")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(KelinColor.accent)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.spiritName)
                            .kelinTypography(KelinTypography.label, color: KelinColor.primaryTint)
                        Text(String(localized: "“你的思路比第一天更清晰了，今晚灯火下，我们把它带回房间吧。”"))
                            .kelinTypography(KelinTypography.body)
                            .foregroundStyle(KelinColor.textPrimary)
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(KelinColor.accentSurface.opacity(0.4))
                .clipShape(RoundedRectangle(cornerRadius: KelinRadius.small, style: .continuous))
            }
        }
        .padding(KelinSpacing.standard)
        .background(KelinColor.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: PactLayout.cardRadius, style: .continuous))
    }

    private func completedMetric(
        title: String,
        value: String,
        symbol: String,
        symbolColor: Color = KelinColor.textSecondary,
        stacked: Bool = false
    ) -> some View {
        Group {
            if stacked {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 10) {
                        Image(systemName: symbol)
                            .font(.system(size: 16))
                            .foregroundStyle(symbolColor)
                        Text(title)
                            .kelinTypography(KelinTypography.body, color: KelinColor.textSecondary)
                    }
                    Text(value)
                        .kelinTypography(KelinTypography.body)
                        .foregroundStyle(KelinColor.textPrimary)
                        .padding(.leading, 26)
                }
            } else {
                HStack(alignment: .top) {
                    HStack(spacing: 10) {
                        Image(systemName: symbol)
                            .font(.system(size: 16))
                            .foregroundStyle(symbolColor)
                        Text(title)
                            .kelinTypography(KelinTypography.body, color: KelinColor.textSecondary)
                    }
                    Spacer()
                    Text(value)
                        .kelinTypography(KelinTypography.body)
                        .foregroundStyle(KelinColor.textPrimary)
                        .multilineTextAlignment(.trailing)
                }
            }
        }
        .padding(KelinSpacing.compact)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(KelinColor.surfaceSecondary.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: KelinRadius.small, style: .continuous))
    }

    private var impactNote: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "bookmark.fill")
                .font(.system(size: 15))
                .foregroundStyle(KelinColor.accent)
            Text(String(localized: "这道学者纹将常驻在雾生的灵体表面，并沉淀入房间书架记忆库。"))
                .kelinTypography(KelinTypography.secondary, color: KelinColor.textSecondary)
        }
        .padding(.horizontal, 4)
    }

    private var weekRecapSheet: some View {
        NavigationStack {
            List(viewModel.questions) { question in
                VStack(alignment: .leading, spacing: 6) {
                    Text(question.prompt)
                        .font(.system(size: 15, weight: .semibold))
                    Text(question.comment)
                        .font(.system(size: 13))
                        .foregroundStyle(KelinColor.textSecondary)
                }
                .listRowBackground(KelinColor.surfaceSecondary)
            }
            .scrollContentBackground(.hidden)
            .background(KelinColor.backgroundBase)
            .navigationTitle(String(localized: "回顾 7 日答卷"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "关闭")) {
                        viewModel.showsWeekRecap = false
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
}

private struct ScholarMarkEmblem: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(KelinColor.accent.opacity(0.12))
                .blur(radius: 18)
            Circle()
                .stroke(KelinColor.accent.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                .padding(2)
            Circle()
                .stroke(KelinColor.accent.opacity(0.35), lineWidth: 1.2)
                .padding(18)
            Image(systemName: "sparkle")
                .font(.system(size: 36, weight: .medium))
                .foregroundStyle(KelinColor.accent)
                .shadow(color: KelinColor.accent.opacity(0.55), radius: 16)
            Circle()
                .fill(KelinColor.textPrimary)
                .frame(width: 8, height: 8)
        }
        .accessibilityHidden(true)
    }
}

#Preview("未签约") {
    PactView(
        viewModel: PactViewModel(spiritName: "雾生", isOffline: false),
        onBack: {}
    )
}

#Preview("进行中") {
    let model = PactViewModel(spiritName: "雾生", isOffline: false)
    model.previewActive()
    return PactView(viewModel: model, onBack: {})
}

#Preview("契约完成") {
    let model = PactViewModel(spiritName: "雾生", isOffline: false)
    model.previewCompleted()
    return PactView(viewModel: model, onBack: {})
}
