import Foundation

protocol SettingsServiceProtocol: Sendable {
    func patchSpirit(
        expectedVersion: Int,
        name: String?,
        preferences: PreferencesPatchDTO?,
        clientID: UUID
    ) async throws -> SessionPatch

    func deleteAccount(clientID: UUID) async throws -> AccountDeletion
}

actor APISettingsService: SettingsServiceProtocol {
    private let client: any APIClientProtocol

    init(client: any APIClientProtocol) {
        self.client = client
    }

    func patchSpirit(
        expectedVersion: Int,
        name: String?,
        preferences: PreferencesPatchDTO?,
        clientID: UUID
    ) async throws -> SessionPatch {
        let result = try await client.sendWithMetadata(
            .patch(
                "/spirit",
                body: APIDecoding.encodeBody(
                    PatchSpiritRequestDTO(
                        clientID: clientID,
                        expectedVersion: expectedVersion,
                        name: name,
                        preferences: preferences
                    )
                )
            ),
            responseType: SpiritPatchResultDTO.self
        )
        return try SettingsMapper.mapPatch(result.payload, serverTime: result.serverTime)
    }

    func deleteAccount(clientID: UUID) async throws -> AccountDeletion {
        let dto = try await client.send(
            .delete(
                "/account",
                body: APIDecoding.encodeBody(
                    DeleteAccountRequestDTO(
                        clientID: clientID,
                        confirm: P16P20ContractManifest.accountDeleteConfirm
                    )
                )
            ),
            responseType: AccountDeletionDTO.self
        )
        return SettingsMapper.mapDeletion(dto)
    }
}

actor MockSettingsService: SettingsServiceProtocol {
    func patchSpirit(
        expectedVersion: Int,
        name: String?,
        preferences: PreferencesPatchDTO?,
        clientID: UUID
    ) async throws -> SessionPatch {
        throw AppError.networkUnavailable
    }

    func deleteAccount(clientID: UUID) async throws -> AccountDeletion {
        throw AppError.networkUnavailable
    }
}
