import SwiftUI

struct FeedLocationSheet: View {
    @Bindable var viewModel: FeedViewModel

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: KelinSpacing.section) {
                Text(String(localized: "只记城市和地点名称，不保存精确位置。"))
                    .kelinTypography(KelinTypography.secondary, color: KelinColor.textSecondary)

                field(String(localized: "城市"), text: $viewModel.locationCity)
                field(String(localized: "地点名称"), text: $viewModel.locationLabel)

                VStack(alignment: .leading, spacing: KelinSpacing.xSmall) {
                    Text(String(localized: "类别"))
                        .kelinTypography(KelinTypography.label, color: KelinColor.textSecondary)
                    Picker(String(localized: "类别"), selection: $viewModel.locationCategory) {
                        Text(String(localized: "不选")).tag(Optional<FeedLocationCategory>.none)
                        ForEach(FeedLocationCategory.allCases, id: \.self) { category in
                            Text(category.title).tag(Optional(category))
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(KelinColor.accent)
                }

                Button {
                    viewModel.submitLocation()
                } label: {
                    Text(String(localized: "确认地点"))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(KelinColor.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: FeedLayout.actionHeight)
                        .background(KelinColor.accent)
                        .clipShape(RoundedRectangle(cornerRadius: KelinRadius.small, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(viewModel.sightState == .submitting)
                .accessibilityLabel(String(localized: "确认地点"))

                Spacer(minLength: 0)
            }
            .padding(KelinSpacing.pageHorizontal)
            .kelinScreenBackground()
            .navigationTitle(String(localized: "选地点"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "取消")) {
                        viewModel.isShowingLocationSheet = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private func field(_ title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: KelinSpacing.xSmall) {
            Text(title)
                .kelinTypography(KelinTypography.label, color: KelinColor.textSecondary)
            TextField(title, text: text)
                .kelinTypography(KelinTypography.body)
                .padding(KelinSpacing.compact)
                .background(KelinColor.surfaceSecondary)
                .clipShape(RoundedRectangle(cornerRadius: KelinRadius.small, style: .continuous))
        }
    }
}
