import Foundation
import SwiftData

enum KelinSchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            CachedBootstrap.self,
            CachedMessage.self,
            CachedMemory.self,
            CachedPostcard.self,
            CachedPact.self,
            Draft.self,
            PendingOperation.self,
        ]
    }
}

enum KelinMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [KelinSchemaV1.self]
    }

    static var stages: [MigrationStage] {
        []
    }
}

enum KelinModelContainerFactory {
    static func makeInMemoryContainer() throws -> ModelContainer {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(
            for: Schema(versionedSchema: KelinSchemaV1.self),
            migrationPlan: KelinMigrationPlan.self,
            configurations: [configuration]
        )
    }

    static func makeDefaultContainer() throws -> ModelContainer {
        try ModelContainer(
            for: Schema(versionedSchema: KelinSchemaV1.self),
            migrationPlan: KelinMigrationPlan.self
        )
    }
}
