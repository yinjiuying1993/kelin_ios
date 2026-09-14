import SwiftUI

struct MemoryDetailSheet: View {
    let item: MemoryTimelineItem
    @Bindable var viewModel: MemoryViewModel
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: KelinSpacing.section) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.typeTitle)
                        .kelinTypography(KelinTypography.label, color: KelinColor.accent)
                    Text(String(localized: "记忆详情"))
                        .kelinTypography(KelinTypography.cardTitle)
                }
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(KelinColor.textSecondary)
                        .frame(width: 28, height: 28)
                        .background(KelinColor.surfaceSecondary)
                        .clipShape(Circle())
                        .frame(
                            width: KelinSize.minimumTouchTarget,
                            height: KelinSize.minimumTouchTarget
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(String(localized: "关闭"))
            }

            Text("“\(item.memory.summary)”")
                .kelinTypography(KelinTypography.pageTitle)

            detailRow(title: String(localized: "时间"), value: MemoryPresentationRules.formattedTime(item.memory.createdAt))
            detailRow(title: String(localized: "影响"), value: item.impactTitle)
            detailRow(title: String(localized: "状态"), value: MemoryPresentationRules.statusTitle(item.memory.status))

            if viewModel.confirm == .correct {
                TextField(String(localized: "纠正这段记忆"), text: $viewModel.correctionDraft, axis: .vertical)
                    .kelinTypography(KelinTypography.body)
                    .lineLimit(3...8)
                    .padding(KelinSpacing.compact)
                    .background(KelinColor.surfaceSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .accessibilityLabel(String(localized: "纠正这段记忆"))
            }

            if let mutationError = viewModel.mutationError {
                Text(ErrorCopy.app(mutationError).message)
                    .kelinTypography(KelinTypography.secondary, color: KelinColor.danger)
            }

            Text(String(localized: "记忆可以纠正、封存或删除"))
                .kelinTypography(KelinTypography.secondary, color: KelinColor.textSecondary)

            HStack(spacing: KelinSpacing.compact) {
                actionChip(String(localized: "纠正"), tint: KelinColor.accent) {
                    viewModel.confirm = .correct
                }
                actionChip(String(localized: "封存"), tint: KelinColor.accentWarm) {
                    viewModel.confirm = .seal
                }
                actionChip(String(localized: "删除"), tint: KelinColor.danger) {
                    viewModel.confirm = .delete
                }
            }

            if viewModel.confirm != nil {
                confirmBar
            }

            Spacer(minLength: 0)
        }
        .padding(KelinSpacing.pageHorizontal)
        .kelinScreenBackground()
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .disabled(viewModel.isMutating)
    }

    @ViewBuilder
    private var confirmBar: some View {
        VStack(alignment: .leading, spacing: KelinSpacing.small) {
            Text(confirmTitle)
                .kelinTypography(KelinTypography.cardTitle)
            Text(confirmMessage)
                .kelinTypography(KelinTypography.secondary, color: KelinColor.textSecondary)

            HStack(spacing: KelinSpacing.compact) {
                Button(String(localized: "取消")) {
                    viewModel.confirm = nil
                }
                .buttonStyle(.plain)
                .foregroundStyle(KelinColor.textSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(KelinColor.surfaceSecondary)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                Button(confirmActionTitle) {
                    Task {
                        switch viewModel.confirm {
                        case .correct:
                            await viewModel.submitCorrect()
                        case .seal:
                            await viewModel.submitSeal()
                        case .delete:
                            await viewModel.submitDelete()
                        default:
                            break
                        }
                    }
                }
                .buttonStyle(.plain)
                .foregroundStyle(KelinColor.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(confirmActionColor)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
    }

    private var confirmTitle: String {
        switch viewModel.confirm {
        case .correct:
            String(localized: "纠正这段记忆？")
        case .seal:
            String(localized: "暂时不再提起？")
        case .delete:
            String(localized: "删除这段记忆？")
        default:
            ""
        }
    }

    private var confirmMessage: String {
        switch viewModel.confirm {
        case .correct:
            String(localized: "只会改摘要，不会改它记得有多深。")
        case .seal:
            String(localized: "它不会再提起，对应刻痕会逐渐淡化。")
        case .delete:
            String(localized: "删除后，它不会再用这件事回应你。")
        default:
            ""
        }
    }

    private var confirmActionTitle: String {
        switch viewModel.confirm {
        case .correct:
            String(localized: "纠正")
        case .seal:
            String(localized: "封存")
        case .delete:
            String(localized: "删除")
        default:
            ""
        }
    }

    private var confirmActionColor: Color {
        switch viewModel.confirm {
        case .delete:
            KelinColor.danger
        case .seal:
            KelinColor.accentWarm
        default:
            KelinColor.accent
        }
    }

    private func detailRow(title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .kelinTypography(KelinTypography.secondary, color: KelinColor.textSecondary)
                .frame(width: 56, alignment: .leading)
            Text(value)
                .kelinTypography(KelinTypography.body)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func actionChip(_ title: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(tint)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(tint.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}
