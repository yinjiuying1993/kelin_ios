import SwiftUI

struct RootView: View {
    @Bindable var router: AppRouter

    var body: some View {
        NavigationStack(path: $router.path) {
            VStack(spacing: KelinSpacing.section) {
                Text("刻灵")
                    .font(KelinTypography.largeTitle.font)
                    .foregroundStyle(KelinColor.textPrimary)
                    .accessibilityAddTraits(.isHeader)

                Button {
                    router.push(.chat)
                } label: {
                    Text(String(localized: "进入对话"))
                }
                .kelinPrimaryAction()

                Button {
                    router.present(.renameSpirit)
                } label: {
                    Text(String(localized: "打开改名"))
                }
                .kelinPrimaryAction()

                #if DEBUG
                Button {
                    router.push(.debug)
                } label: {
                    Text(String(localized: "调试"))
                }
                .kelinPrimaryAction()
                #endif
            }
            .padding(KelinSpacing.pageHorizontal)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(KelinColor.backgroundBase.ignoresSafeArea())
            .navigationDestination(for: Route.self) { route in
                RoutePlaceholderView(route: route)
            }
            .sheet(item: $router.sheet) { sheet in
                SheetPlaceholderView(router: router, sheet: sheet)
            }
        }
    }
}

private struct RoutePlaceholderView: View {
    let route: Route

    var body: some View {
        Text(String(localized: "路由占位"))
            .font(KelinTypography.pageTitle.font)
            .foregroundStyle(KelinColor.textPrimary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(KelinColor.backgroundBase.ignoresSafeArea())
            .navigationTitle(route.placeholderTitle)
            .navigationBarTitleDisplayMode(.inline)
    }
}

private struct SheetPlaceholderView: View {
    @Bindable var router: AppRouter
    let sheet: SheetRoute

    var body: some View {
        VStack(spacing: KelinSpacing.section) {
            Text(String(localized: "弹层占位"))
                .font(KelinTypography.pageTitle.font)
                .foregroundStyle(KelinColor.textPrimary)

            Button {
                router.dismissSheet()
            } label: {
                Text(String(localized: "关闭"))
            }
            .kelinPrimaryAction()
        }
        .padding(KelinSpacing.pageHorizontal)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(KelinColor.backgroundBase.ignoresSafeArea())
        .accessibilityElement(children: .contain)
        .accessibilityLabel(sheet.placeholderTitle)
    }
}

private extension Route {
    var placeholderTitle: String {
        switch self {
        case .chat:
            String(localized: "对话")
        case .feed:
            String(localized: "投喂")
        case .memory:
            String(localized: "记忆")
        case .pact:
            String(localized: "共学")
        case .social:
            String(localized: "足迹")
        case .report:
            String(localized: "鉴定")
        case .settings:
            String(localized: "设置")
        #if DEBUG
        case .debug:
            String(localized: "调试")
        #endif
        }
    }
}

private extension SheetRoute {
    var placeholderTitle: String {
        switch self {
        case .renameSpirit:
            String(localized: "改名")
        default:
            String(localized: "弹层占位")
        }
    }
}

private extension View {
    func kelinPrimaryAction() -> some View {
        buttonStyle(.plain)
            .font(KelinTypography.body.font.weight(.semibold))
            .foregroundStyle(KelinColor.textPrimary)
            .frame(maxWidth: .infinity, minHeight: KelinSize.minimumTouchTarget)
            .contentShape(Rectangle())
            .background(KelinColor.accent)
            .clipShape(RoundedRectangle(cornerRadius: KelinRadius.small))
    }
}

#Preview("根视图") {
    RootView(router: AppRouter())
        .environment(AppEnvironment.preview)
}
