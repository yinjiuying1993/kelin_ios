import PhotosUI
import SwiftUI

struct FeedView: View {
    @Bindable var viewModel: FeedViewModel
    let onBack: () -> Void
    @State private var photoItem: PhotosPickerItem?

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
                    .padding(.top, KelinSpacing.small)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: KelinSpacing.standard) {
                    Text(String(localized: "食物会消失，经历会留下"))
                        .kelinTypography(KelinTypography.secondary, color: KelinColor.textSecondary)
                        .padding(.horizontal, 4)

                    foodCard
                    sightCard
                    knowledgeCard
                    emotionCard
                    promiseCard
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
        .sheet(isPresented: $viewModel.isShowingLocationSheet) {
            FeedLocationSheet(viewModel: viewModel)
        }
        .onChange(of: photoItem) { _, item in
            Task { await loadPhoto(item) }
        }
    }

    private var header: some View {
        ZStack {
            HStack {
                Button(action: onBack) {
                    HStack(spacing: 2) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 24, weight: .regular))
                        Text(String(localized: "房间"))
                            .font(.system(size: 16, weight: .regular))
                    }
                    .foregroundStyle(KelinColor.accent)
                    .frame(minHeight: KelinSize.minimumTouchTarget, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(String(localized: "返回房间"))
                Spacer()
            }

            Text(String(localized: "投喂"))
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(KelinColor.textPrimary)
                .allowsHitTesting(false)
        }
        .padding(.horizontal, KelinSpacing.pageHorizontal)
        .frame(height: FeedLayout.headerHeight)
    }

    private var foodCard: some View {
        feedCard {
            cardHeader(
                title: String(localized: "口粮"),
                subtitle: String(localized: "恢复饱食和精力"),
                symbol: "leaf.fill",
                tint: KelinColor.accent,
                trailing: {
                    Text(viewModel.foodQuotaText)
                        .kelinTypography(KelinTypography.label, color: KelinColor.accentWarm)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(KelinColor.accentWarm.opacity(0.1))
                        .clipShape(Capsule())
                }
            )

            HStack {
                Spacer()
                Button(action: viewModel.feedFood) {
                    HStack(spacing: KelinSpacing.small) {
                        Image(systemName: foodSymbol)
                        Text(foodTitle)
                    }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(viewModel.foodPhase == .idle ? KelinColor.textPrimary : KelinColor.textSecondary)
                    .padding(.horizontal, 20)
                    .frame(height: FeedLayout.actionHeight)
                    .background(viewModel.foodPhase == .idle ? KelinColor.accent : KelinColor.surfaceSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: KelinRadius.small, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(viewModel.foodPhase != .idle || viewModel.foodState == .submitting)
                .accessibilityLabel(String(localized: "喂一块温石"))
            }
            .padding(.top, KelinSpacing.small)
        }
    }

    private var foodTitle: String {
        switch viewModel.foodPhase {
        case .idle:
            String(localized: "喂一块温石")
        case .feeding:
            String(localized: "投喂中...")
        case .warmed:
            String(localized: "已温热")
        }
    }

    private var foodSymbol: String {
        switch viewModel.foodPhase {
        case .idle:
            "carrot.fill"
        case .feeding:
            "ellipsis"
        case .warmed:
            "checkmark"
        }
    }

    private var sightCard: some View {
        feedCard {
            cardHeader(
                title: String(localized: "见闻"),
                subtitle: String(localized: "照片或地点会变成房间里的东西"),
                symbol: "photo.fill",
                tint: KelinColor.accentCold
            )

            if viewModel.hasPhotoPreview {
                HStack(spacing: KelinSpacing.compact) {
                    RoundedRectangle(cornerRadius: KelinRadius.small, style: .continuous)
                        .fill(KelinColor.surfaceSecondary)
                        .frame(width: 64, height: 64)
                        .overlay {
                            Image(systemName: "photo")
                                .foregroundStyle(KelinColor.accentCold)
                        }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(String(localized: "已选择照片"))
                            .kelinTypography(KelinTypography.cardTitle)
                        Text(String(localized: "确认后才会变成房间里的东西"))
                            .kelinTypography(KelinTypography.secondary, color: KelinColor.textSecondary)
                    }
                    Spacer()
                }
                .padding(.top, KelinSpacing.small)

                HStack(spacing: KelinSpacing.compact) {
                    Button(action: viewModel.clearPhotoPreview) {
                        Text(String(localized: "删除"))
                            .frame(maxWidth: .infinity)
                            .frame(height: FeedLayout.actionHeight)
                            .background(KelinColor.surfaceSecondary)
                            .clipShape(RoundedRectangle(cornerRadius: KelinRadius.small, style: .continuous))
                    }
                    Button(action: viewModel.confirmSight) {
                        Text(String(localized: "确认投喂"))
                            .frame(maxWidth: .infinity)
                            .frame(height: FeedLayout.actionHeight)
                            .background(KelinColor.accent)
                            .clipShape(RoundedRectangle(cornerRadius: KelinRadius.small, style: .continuous))
                    }
                    .disabled(viewModel.sightState == .submitting)
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(KelinColor.textPrimary)
                .buttonStyle(.plain)
                .padding(.top, KelinSpacing.small)
            } else {
                HStack(spacing: KelinSpacing.compact) {
                    PhotosPicker(selection: $photoItem, matching: .images) {
                        Label(String(localized: "选照片"), systemImage: "camera.fill")
                            .frame(maxWidth: .infinity)
                            .frame(height: FeedLayout.actionHeight)
                            .background(KelinColor.surfaceSecondary)
                            .clipShape(RoundedRectangle(cornerRadius: KelinRadius.small, style: .continuous))
                    }
                    Button {
                        viewModel.isShowingLocationSheet = true
                    } label: {
                        Label(String(localized: "选地点"), systemImage: "mappin.and.ellipse")
                            .frame(maxWidth: .infinity)
                            .frame(height: FeedLayout.actionHeight)
                            .background(KelinColor.surfaceSecondary)
                            .clipShape(RoundedRectangle(cornerRadius: KelinRadius.small, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(KelinColor.textPrimary)
                .padding(.top, KelinSpacing.small)
            }

            if let location = viewModel.locationDraft {
                Text(location.category.map { "\(location.city) · \(location.label) · \($0.title)" } ?? "\(location.city) · \(location.label)")
                    .kelinTypography(KelinTypography.secondary, color: KelinColor.textSecondary)
                    .padding(.top, 4)
            }

            Text(viewModel.sightQuotaText)
                .kelinTypography(KelinTypography.label, color: KelinColor.textSecondary)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    private var knowledgeCard: some View {
        feedCard {
            cardHeader(
                title: String(localized: "知识"),
                subtitle: String(localized: "把一段内容教给它"),
                symbol: "book.fill",
                tint: KelinColor.accentWarm
            )

            ZStack(alignment: .bottomTrailing) {
                TextField(
                    String(localized: "粘贴笔记或知识"),
                    text: $viewModel.knowledgeDraft,
                    axis: .vertical
                )
                .kelinTypography(KelinTypography.secondary)
                .lineLimit(3...6)
                .padding(KelinSpacing.compact)
                .padding(.trailing, 40)
                .background(KelinColor.surfaceSecondary)
                .clipShape(RoundedRectangle(cornerRadius: KelinRadius.small, style: .continuous))

                Button(action: viewModel.submitKnowledge) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(KelinColor.textPrimary)
                        .frame(width: FeedLayout.sendButton, height: FeedLayout.sendButton)
                        .background(KelinColor.accent)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .padding(10)
                .disabled(!viewModel.canSubmitKnowledge)
                .accessibilityLabel(String(localized: "投喂知识"))
            }
            .padding(.top, 4)

            Text(viewModel.knowledgeCountText)
                .kelinTypography(KelinTypography.label, color: KelinColor.textSecondary)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    private var emotionCard: some View {
        feedCard {
            cardHeader(
                title: String(localized: "情绪"),
                subtitle: String(localized: "传递此刻的心境与感知"),
                symbol: "brain.head.profile",
                tint: KelinColor.accent
            )

            WrappingChipRow(spacing: KelinSpacing.small, lineSpacing: KelinSpacing.small) {
                ForEach(FeedEmotion.allCases, id: \.self) { emotion in
                    emotionChip(emotion)
                }
            }
            .padding(.top, 4)
        }
    }

    private var promiseCard: some View {
        feedCard {
            cardHeader(
                title: String(localized: "约定"),
                subtitle: String(localized: "同时只能有一个"),
                symbol: "calendar",
                tint: KelinColor.accentWarm
            )

            if viewModel.promisePhase != .empty {
                TextField(String(localized: "一句话描述"), text: $viewModel.promiseText)
                    .kelinTypography(KelinTypography.body)
                    .padding(KelinSpacing.compact)
                    .background(KelinColor.surfaceSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: KelinRadius.small, style: .continuous))
                    .padding(.top, KelinSpacing.small)

                DatePicker(
                    String(localized: "时间"),
                    selection: $viewModel.promiseDate,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .tint(KelinColor.accent)
            }

            HStack(spacing: KelinSpacing.compact) {
                if viewModel.promisePhase != .empty {
                    Button(action: viewModel.cancelPromise) {
                        Text(String(localized: "取消"))
                            .frame(maxWidth: .infinity)
                            .frame(height: FeedLayout.actionHeight)
                            .background(KelinColor.surfaceSecondary)
                            .clipShape(RoundedRectangle(cornerRadius: KelinRadius.small, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.promiseState == .submitting)
                }

                if viewModel.promisePhase == .locked {
                    Button(action: viewModel.completePromise) {
                        Text(String(localized: "完成"))
                            .frame(maxWidth: .infinity)
                            .frame(height: FeedLayout.actionHeight)
                            .background(KelinColor.accent)
                            .clipShape(RoundedRectangle(cornerRadius: KelinRadius.small, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.promiseState == .submitting)
                }

                Button {
                    if viewModel.promisePhase == .empty {
                        viewModel.beginPromise()
                    } else {
                        viewModel.lockPromise()
                    }
                } label: {
                    HStack(spacing: KelinSpacing.small) {
                        Image(systemName: "clock")
                        Text(promiseActionTitle)
                    }
                    .frame(maxWidth: viewModel.promisePhase == .empty ? nil : .infinity)
                    .padding(.horizontal, 20)
                    .frame(height: FeedLayout.actionHeight)
                    .background(KelinColor.surfaceSecondary)
                    .foregroundStyle(KelinColor.accent)
                    .clipShape(RoundedRectangle(cornerRadius: KelinRadius.small, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(viewModel.promiseState == .submitting)
                .frame(maxWidth: viewModel.promisePhase == .empty ? .infinity : nil, alignment: .trailing)
            }
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(KelinColor.textPrimary)
            .padding(.top, KelinSpacing.small)
        }
    }

    private var promiseActionTitle: String {
        switch viewModel.promisePhase {
        case .empty:
            String(localized: "定一个时间")
        case .editing:
            String(localized: "定一个时间")
        case .locked:
            String(localized: "修改")
        }
    }

    private var offlineBanner: some View {
        Text(String(localized: "连不上，房间还在"))
            .kelinTypography(KelinTypography.label, color: KelinColor.accentWarm)
            .frame(maxWidth: .infinity)
            .padding(.vertical, KelinSpacing.xSmall)
            .background(KelinColor.surfaceSecondary.opacity(0.85))
            .clipShape(Capsule())
            .padding(.horizontal, KelinSpacing.pageHorizontal)
            .padding(.top, KelinSpacing.small)
    }

    private func feedCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: KelinSpacing.compact) {
            content()
        }
        .padding(KelinSpacing.standard)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(KelinColor.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: FeedLayout.cardRadius, style: .continuous))
    }

    private func cardHeader<Trailing: View>(
        title: String,
        subtitle: String,
        symbol: String,
        tint: Color,
        @ViewBuilder trailing: () -> Trailing
    ) -> some View {
        HStack(spacing: KelinSpacing.standard) {
            Image(systemName: symbol)
                .font(.system(size: KelinIconSize.standard, weight: .medium))
                .foregroundStyle(tint)
                .frame(width: FeedLayout.iconWell, height: FeedLayout.iconWell)
                .background(KelinColor.accentSurface)
                .clipShape(RoundedRectangle(cornerRadius: KelinRadius.small, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .kelinTypography(KelinTypography.cardTitle)
                Text(subtitle)
                    .kelinTypography(KelinTypography.secondary, color: KelinColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: KelinSpacing.small)
            trailing()
        }
    }

    private func cardHeader(
        title: String,
        subtitle: String,
        symbol: String,
        tint: Color
    ) -> some View {
        cardHeader(title: title, subtitle: subtitle, symbol: symbol, tint: tint) {
            EmptyView()
        }
    }

    private var pageBackground: some View {
        KelinColor.backgroundBase
            .ignoresSafeArea()
            .overlay {
                RadialGradient(
                    colors: [KelinColor.backgroundCenter, KelinColor.backgroundBase],
                    center: .center,
                    startRadius: 0,
                    endRadius: 420
                )
                .ignoresSafeArea()
            }
    }

    private func emotionChip(_ emotion: FeedEmotion) -> some View {
        let isSelected = viewModel.selectedEmotion == emotion
        return Button {
            viewModel.selectEmotion(emotion)
        } label: {
            Text(emotion.title)
                .font(.system(size: 12, weight: isSelected ? .medium : .regular))
                .foregroundStyle(isSelected ? KelinColor.accent : KelinColor.textSecondary)
                .padding(.horizontal, KelinSpacing.compact)
                .frame(height: FeedLayout.chipHeight)
                .background(isSelected ? KelinColor.accentSurface : KelinColor.surfaceSecondary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(emotion.title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func loadPhoto(_ item: PhotosPickerItem?) async {
        guard let item else {
            if viewModel.consumePhotoClearFlag() {
                return
            }
            await viewModel.processPickedPhoto(nil)
            return
        }
        let data = try? await item.loadTransferable(type: Data.self)
        await viewModel.processPickedPhoto(data)
    }
}

private struct WrappingChipRow: Layout {
    var spacing: CGFloat
    var lineSpacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        layout(proposal: proposal, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        for (index, frame) in layout(proposal: proposal, subviews: subviews).frames.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                proposal: ProposedViewSize(frame.size)
            )
        }
    }

    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, frames: [CGRect]) {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxRowWidth: CGFloat = 0
        var frames: [CGRect] = []

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > maxWidth {
                x = 0
                y += rowHeight + lineSpacing
                rowHeight = 0
            }
            frames.append(CGRect(origin: CGPoint(x: x, y: y), size: size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            maxRowWidth = max(maxRowWidth, x - spacing)
        }

        let width = maxWidth.isFinite ? maxWidth : max(maxRowWidth, 0)
        return (CGSize(width: width, height: y + rowHeight), frames)
    }
}

#if DEBUG
#Preview("投喂") {
    FeedView(
        viewModel: FeedViewModel(quotas: [], isOffline: false),
        onBack: {}
    )
}
#endif
