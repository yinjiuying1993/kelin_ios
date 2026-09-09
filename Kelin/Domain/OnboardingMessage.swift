import Foundation

struct OnboardingMessage: Identifiable, Equatable, Sendable, Codable {
    enum Role: String, Codable, Sendable {
        case user
        case spirit
    }

    let id: UUID
    let role: Role
    let text: String

    init(id: UUID = UUID(), role: Role, text: String) {
        self.id = id
        self.role = role
        self.text = text
    }
}

struct OnboardingChatResult: Equatable, Sendable {
    let userMessage: OnboardingMessage
    let spiritMessage: OnboardingMessage
    let completedRounds: Int
    let snapshotVersion: Int
    let usesStubProvider: Bool
}

enum OnboardingConversationDefaults {
    static let totalSteps = 5
}
