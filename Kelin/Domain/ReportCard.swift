import Foundation

struct ReportTopTrait: Equatable, Sendable, Codable {
    let dimension: String
    let value: Int
}

struct ReportCardMemory: Equatable, Sendable, Identifiable, Codable {
    let id: UUID
    let type: String?
    let summary: String?
    let unavailable: Bool
}

struct ReportCardSpirit: Equatable, Sendable, Identifiable, Codable {
    let id: UUID
    let name: String
    let stage: SpiritStage
    let publicLayers: [String]
}

struct ReportCard: Equatable, Sendable, Identifiable, Codable {
    let id: UUID
    let status: String
    let rulesVersion: String
    let title: String
    let spirit: ReportCardSpirit
    let roomWeather: String
    let topTraits: [ReportTopTrait]
    let topMemories: [ReportCardMemory]
    let scholarMarks: [String]
    let signatureLine: String?
    let inviteCode: String
    let generatedAt: Date
    let version: Int
}

struct ReportLineMutation: Equatable, Sendable {
    let card: ReportCard
    let patch: SessionPatch
}

struct DeviceRegistration: Equatable, Sendable, Identifiable {
    var id: UUID { deviceID }
    let deviceID: UUID
    let enabled: Bool
    let updatedAt: Date
}

struct AccountDeletion: Equatable, Sendable, Identifiable {
    var id: UUID { deletionID }
    let deletionID: UUID
    let status: String
    let requestedAt: Date
}
