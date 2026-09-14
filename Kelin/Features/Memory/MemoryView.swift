import SwiftUI

struct MemoryView: View {
    @Bindable var viewModel: MemoryViewModel
    let onBack: () -> Void
    let onTalk: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            header
            filterBar
                .padding(.top, KelinSpacing.small)

            if viewModel.isOffline {
                offlineBanner
            }

            if let loadError = viewModel.loadError {
                errorBanner(loadError)
            }

            if viewModel.isEmpty {
                MemoryEmptyStateView(spiritName: viewModel.spiritName, onTalk: onTalk)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.bottom, 40)
            } else {
                timeline
            }

            if viewModel.canClearAll {
                clearAllButton
            }

            footerNote
        }
        .background { pageBackground }
        .safeAreaPadding(.bottom, KelinSpacing.small)
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .sheet(item: selectedItemBinding) { item in
            MemoryDetailSheet(item: item, viewModel: viewModel) {
                viewModel.dismissDetail()
            }
        }
        .alert(
            String(localized: "清除所有记忆？"),
            isPresented: clearAllBinding
        ) {
            Button(String(localized: "取消"), role: .cancel) {
                viewModel.confirm = nil
            }
            Button(String(localized: "全部清除"), role: .destructive) {
                Task { await viewModel.submitClearAll() }
            }
        } message: {
            Text(String(localized: "口癖、偏好、见闻和知识都会消失。"))
        }
    }

    private var clearAllBinding: Binding<Bool> {
        Binding(
            get: { viewModel.confirm == .clearAll },
            set: { isPresented in
                if !isPresented, viewModel.confirm == .clearAll {
                    viewModel.confirm = nil
                }
            }
        )
    }

    private var selectedItemBinding: Binding<MemoryTimelineItem?> {
        Binding(
            get: { viewModel.selectedItem },
            set: { item in
                if item == nil {
                    viewModel.dismissDetail()
                }
            }
        )
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

                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(KelinColor.textSecondary)
                    .frame(width: 36, height: 36)
                    .background(KelinColor.surfacePrimary.opacity(0.7))
                    .clipShape(Circle())
                    .frame(width: KelinSize.minimumTouchTarget, height: KelinSize.minimumTouchTarget)
                    .accessibilityLabel(String(localized: "筛选"))
                    .accessibilityHint(String(localized: "用上方标签筛选记忆"))
            }

            Text(String(localized: "记忆"))
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(KelinColor.textPrimary)
                .allowsHitTesting(false)
        }
        .padding(.horizontal, KelinSpacing.pageHorizontal)
        .frame(height: MemoryLayout.headerHeight)
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: KelinSpacing.small) {
                ForEach(MemoryFilter.allCases, id: \.self) { filter in
                    filterChip(filter)
                }
            }
            .padding(.horizontal, KelinSpacing.pageHorizontal)
        }
    }

    private func filterChip(_ filter: MemoryFilter) -> some View {
        let selected = viewModel.filter == filter
        return Button {
            Task { await viewModel.setFilter(filter) }
        } label: {
            Text(filter.title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(selected ? KelinColor.accent : KelinColor.textSecondary)
                .padding(.horizontal, KelinSpacing.standard)
                .frame(height: MemoryLayout.filterChipHeight)
                .background(selected ? KelinColor.accentSurface : KelinColor.surfacePrimary)
                .clipShape(Capsule())
                .overlay {
                    Capsule().stroke(
                        selected ? KelinColor.accent.opacity(0.4) : Color.white.opacity(0.05),
                        lineWidth: 1
                    )
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(filter.title)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private var timeline: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: KelinSpacing.section) {
                if viewModel.hasNoFilterMatches {
                    Text(String(localized: "这个筛选里还没有刻痕"))
                        .kelinTypography(KelinTypography.secondary, color: KelinColor.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.top, KelinSpacing.largeSection)
                }

                ForEach(viewModel.groups) { group in
                    ForEach(Array(group.items.enumerated()), id: \.element.id) { index, item in
                        MemoryTimelineCard(
                            item: item,
                            dayTitle: index == 0 ? group.section.title : nil
                        ) {
                            viewModel.select(item.id)
                        }
                        .onAppear {
                            if item.id == viewModel.memories.last?.id {
                                Task { await viewModel.loadMore() }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, KelinSpacing.pageHorizontal)
            .padding(.top, KelinSpacing.compact)
            .padding(.bottom, KelinSpacing.largeSection)
            .overlay(alignment: .leading) {
                if !viewModel.groups.isEmpty {
                    KelinColor.surfaceSecondary
                        .frame(width: 2)
                        .padding(.leading, 10)
                        .padding(.vertical, 8)
                }
            }
        }
        .scrollIndicators(.hidden)
    }

    private var clearAllButton: some View {
        Button {
            viewModel.confirm = .clearAll
        } label: {
            Text(String(localized: "清除全部记忆"))
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(KelinColor.danger)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, KelinSpacing.pageHorizontal)
        .accessibilityLabel(String(localized: "清除全部记忆"))
    }

    private func errorBanner(_ error: AppError) -> some View {
        Button {
            Task { await viewModel.refresh() }
        } label: {
            Text(ErrorCopy.app(error).message)
                .kelinTypography(KelinTypography.label, color: KelinColor.danger)
                .frame(maxWidth: .infinity)
                .padding(.vertical, KelinSpacing.xSmall)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, KelinSpacing.pageHorizontal)
        .padding(.top, KelinSpacing.small)
    }

    private var footerNote: some View {
        Text(String(localized: "记忆可以纠正、封存或删除"))
            .font(.system(size: 12))
            .foregroundStyle(KelinColor.textSecondary.opacity(0.7))
            .padding(.bottom, KelinSpacing.pageHorizontal)
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

    private var pageBackground: some View {
        KelinColor.backgroundBase
            .ignoresSafeArea()
            .overlay {
                RadialGradient(
                    colors: [
                        KelinColor.backgroundCenter,
                        KelinColor.backgroundBase,
                    ],
                    center: UnitPoint(x: 0.5, y: 0.2),
                    startRadius: 0,
                    endRadius: 420
                )
                .ignoresSafeArea()
            }
    }
}

#if DEBUG
enum MemoryPreviewFixtures {
    static var s07Samples: [MemorySummary] {
        let now = Date()
        return [
            MemorySummary(
                id: UUID(uuidString: "50000000-0000-4000-8000-000000000001")!,
                type: "preference",
                summary: "不要叫宝宝，要叫阿年",
                status: "active",
                createdAt: now
            ),
            MemorySummary(
                id: UUID(uuidString: "50000000-0000-4000-8000-000000000002")!,
                type: "sight",
                summary: "雨夜里的一盏路灯",
                status: "active",
                createdAt: now.addingTimeInterval(-86_400)
            ),
            MemorySummary(
                id: UUID(uuidString: "50000000-0000-4000-8000-000000000003")!,
                type: "knowledge",
                summary: "STAR 法则",
                status: "active",
                createdAt: now.addingTimeInterval(-172_800)
            ),
        ]
    }
}

#Preview("空态") {
    MemoryView(
        viewModel: MemoryViewModel(memories: [], spiritName: "雾生", isOffline: false),
        onBack: {},
        onTalk: {}
    )
}

#Preview("时间线") {
    MemoryView(
        viewModel: MemoryViewModel(
            memories: MemoryPreviewFixtures.s07Samples,
            spiritName: "雾生",
            isOffline: false
        ),
        onBack: {},
        onTalk: {}
    )
}
#endif
