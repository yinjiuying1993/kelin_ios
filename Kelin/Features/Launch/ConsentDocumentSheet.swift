import SwiftUI

enum ConsentDocumentKind: String, Identifiable {
    case userTerms
    case dataNotice

    var id: String { rawValue }

    var title: String {
        switch self {
        case .userTerms:
            String(localized: "用户说明")
        case .dataNotice:
            String(localized: "数据说明")
        }
    }

    var bodyText: String {
        switch self {
        case .userTerms:
            String(localized: "刻灵是一款人工智能陪伴产品。你在应用中的对话与互动会用于塑造精灵的性格与记忆。继续使用即表示你已阅读并理解本说明。")
        case .dataNotice:
            String(localized: "我们会按最小必要原则处理账号、偏好与互动数据，用于提供服务与改进体验。你可以在设置中管理通知、语音与数据相关选项。")
        }
    }
}

struct ConsentDocumentSheet: View {
    let kind: ConsentDocumentKind
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(kind.bodyText)
                    .kelinTypography(KelinTypography.body, color: KelinColor.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(KelinSpacing.pageHorizontal)
                    .padding(.vertical, KelinSpacing.section)
            }
            .kelinScreenBackground()
            .navigationTitle(kind.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "关闭")) {
                        onDismiss()
                    }
                }
            }
        }
    }
}
