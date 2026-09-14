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
    let spirit: Spirit?

    init(
        userMessage: OnboardingMessage,
        spiritMessage: OnboardingMessage,
        completedRounds: Int,
        snapshotVersion: Int,
        usesStubProvider: Bool,
        spirit: Spirit? = nil
    ) {
        self.userMessage = userMessage
        self.spiritMessage = spiritMessage
        self.completedRounds = completedRounds
        self.snapshotVersion = snapshotVersion
        self.usesStubProvider = usesStubProvider
        self.spirit = spirit
    }
}

enum OnboardingConversationDefaults {
    static let totalSteps = 5
}
