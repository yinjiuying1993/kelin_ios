import Foundation

typealias LetterID = UUID

enum Route: Hashable, Sendable {
    case chat
    case feed
    case memory
    case pact
    case social
    case report
    case settings
    #if DEBUG
    case debug
    #endif

    static var includesDebugRoute: Bool {
        #if DEBUG
        true
        #else
        false
        #endif
    }
}

enum SheetRoute: Identifiable, Equatable, Sendable {
    case letter(LetterID)
    case memoryDetail(UUID)
    case editMemory(UUID)
    case renameSpirit
    case addFriend
    case friendDetail(UUID)
    case permission(PermissionKind)

    var id: String {
        switch self {
        case let .letter(id):
            "letter-\(id.uuidString)"
        case let .memoryDetail(id):
            "memoryDetail-\(id.uuidString)"
        case let .editMemory(id):
            "editMemory-\(id.uuidString)"
        case .renameSpirit:
            "renameSpirit"
        case .addFriend:
            "addFriend"
        case let .friendDetail(id):
            "friendDetail-\(id.uuidString)"
        case let .permission(kind):
            "permission-\(kind.rawValue)"
        }
    }
}

@MainActor
@Observable
final class AppRouter {
    var path: [Route] = []
    var sheet: SheetRoute?

    func push(_ route: Route) {
        path.append(route)
    }

    func pop() {
        guard !path.isEmpty else {
            return
        }
        path.removeLast()
    }

    func present(_ sheet: SheetRoute) {
        self.sheet = sheet
    }

    func dismissSheet() {
        sheet = nil
    }

    func reset() {
        path.removeAll()
        sheet = nil
    }
}
