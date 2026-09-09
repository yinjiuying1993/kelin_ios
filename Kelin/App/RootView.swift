import SwiftUI

struct RootView: View {
    @Bindable var router: AppRouter
    @Bindable var appState: AppState

    var body: some View {
        Group {
            switch appState.phase {
            case .ready:
                readyContent
            case .needsAgreement:
                AgreementView(appState: appState)
            case .needsEggSelection:
                EggSelectionView(appState: appState)
            case let .needsFirstConversation(step):
                ZStack {
                    OnboardingConversationView(appState: appState, displayStep: step)

                    if appState.isHatching {
                        HatchTransitionOverlay()
                            .transition(.opacity)
                    }
                }
            case .recoverableError:
                LaunchGateView(phase: appState.phase) {
                    appState.retryFromError()
                }
            default:
                LaunchGateView(phase: appState.phase) {
                    appState.retryFromError()
                }
            }
        }
    }

    private var readyContent: some View {
        NavigationStack(path: $router.path) {
            VStack(spacing: KelinSpacing.section) {
                Text("刻灵")
                    .kelinTypography(KelinTypography.largeTitle)
                    .accessibilityAddTraits(.isHeader)

                Text(String(localized: "相处，会在身上留下痕迹。"))
                    .kelinTypography(KelinTypography.secondary, color: KelinColor.textSecondary)
                    .multilineTextAlignment(.center)

                #if DEBUG
                integrationStatus
                #endif

                Button {
                    router.push(.chat)
                } label: {
                    Text(String(localized: "进入对话"))
                }
                .buttonStyle(.kelinPrimary)

                Button {
                    router.present(.renameSpirit)
                } label: {
                    Text(String(localized: "打开改名"))
                }
                .buttonStyle(.kelinSecondary)

                #if DEBUG
                Button {
                    router.push(.debug)
                } label: {
                    Text(String(localized: "调试"))
                }
                .buttonStyle(.kelinSecondary)
                #endif
            }
            .padding(KelinSpacing.pageHorizontal)
            .kelinScreenBackground()
            .navigationDestination(for: Route.self) { route in
                RoutePlaceholderView(route: route)
            }
            .sheet(item: $router.sheet) { sheet in
                SheetPlaceholderView(router: router, sheet: sheet)
            }
        }
    }

    #if DEBUG
    private var integrationStatus: some View {
        let snapshot = appState.sessionStore.snapshot
        let onboarding = snapshot?.onboarding
        let source = appState.usesRemoteAPI
            ? String(localized: "真实 API")
            : String(localized: "本地 Mock")
        let spiritName = snapshot?.spirit?.name ?? String(localized: "无精灵")
        let stepText: String = {
            guard let onboarding else { return String(localized: "无快照") }
            return "step \(onboarding.step)/\(onboarding.totalSteps)"
        }()

        return VStack(alignment: .leading, spacing: KelinSpacing.small) {
            Text(String(localized: "这是孵化完成后的占位首页，房间四态在 P08。"))
                .kelinTypography(KelinTypography.secondary, color: KelinColor.textSecondary)
            Text("\(source) · \(appState.apiBaseURL?.absoluteString ?? String(localized: "未配置"))")
                .kelinTypography(KelinTypography.label, color: KelinColor.textSecondary)
            Text("\(spiritName) · \(stepText)")
                .kelinTypography(KelinTypography.label, color: KelinColor.textSecondary)
            if appState.isOffline {
                Text(String(localized: "当前在用本地缓存，服务端未同步成功。"))
                    .kelinTypography(KelinTypography.label, color: KelinColor.textSecondary)
            }

            Button {
                Task {
                    await appState.discardLocalCacheAndReload()
                }
            } label: {
                Text(String(localized: "丢弃本地缓存并重新同步"))
            }
            .buttonStyle(.kelinSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, KelinSpacing.section)
    }
    #endif
}

private struct RoutePlaceholderView: View {
    let route: Route

    var body: some View {
        Text(String(localized: "路由占位"))
            .kelinTypography(KelinTypography.pageTitle)
            .kelinScreenBackground()
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
                .kelinTypography(KelinTypography.pageTitle)

            Button {
                router.dismissSheet()
            } label: {
                Text(String(localized: "关闭"))
            }
            .buttonStyle(.kelinPrimary)
        }
        .padding(KelinSpacing.pageHorizontal)
        .kelinScreenBackground()
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
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
            String(localized: "社交")
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
        case .letter:
            String(localized: "来信")
        case .memoryDetail:
            String(localized: "记忆详情")
        case .editMemory:
            String(localized: "编辑记忆")
        case .renameSpirit:
            String(localized: "改名")
        case .addFriend:
            String(localized: "添加好友")
        case .friendDetail:
            String(localized: "好友详情")
        case .permission:
            String(localized: "权限说明")
        }
    }
}

#Preview("根视图") {
    let environment = AppEnvironment.preview
    RootView(router: AppRouter(), appState: environment.makeAppState())
}
