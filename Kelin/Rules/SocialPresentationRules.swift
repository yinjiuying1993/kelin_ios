import Foundation

enum SocialPeerKind: String, Equatable, Sendable {
    case npc
    case friend
}

enum SocialScreenPhase: Equatable, Sendable {
    case noFriends
    case friendsEmpty
    case unreadPostcard
}

enum SocialPresentationRules {
    static let sampleInviteCode = "ABCD2345"

    static func screenTitle() -> String {
        String(localized: "足迹")
    }

    static func inviteLabel() -> String {
        String(localized: "你的灵体邀请码")
    }

    static func emptyFootprintsTitle() -> String {
        String(localized: "门口还没有新的足迹")
    }

    static func emptyFootprintsBody() -> String {
        String(localized: "当雾生夜行归来，或有其他灵体路过时，会在此留下微光与明信片。")
    }

    static func noFriendsCopy() -> String {
        String(localized: "它仍会遇到雾里的那只。")
    }

    static func visitOffCopy() -> String {
        String(localized: "它仍可以去官方精灵那里，但不会进入朋友房间。")
    }

    static func unfriendTitle() -> String {
        String(localized: "不再让它们来往？")
    }

    static func unfriendMessage() -> String {
        String(localized: "已有明信片仍会保留。")
    }

    static func unfriendAction() -> String {
        String(localized: "解除")
    }

    static func normalizeInviteCode(_ raw: String) -> String {
        raw.replacingOccurrences(of: " ", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
    }

    static func validateInviteCode(_ raw: String, selfCode: String) throws -> String {
        let normalized = normalizeInviteCode(raw)
        guard !normalized.isEmpty else {
            throw AppError.invalidInput
        }
        guard normalized != normalizeInviteCode(selfCode) else {
            throw AppError.invalidInput
        }
        return normalized
    }
}
