import Foundation

enum DeviceMapper {
    static func map(_ dto: DeviceRegistrationDTO) -> DeviceRegistration {
        DeviceRegistration(deviceID: dto.deviceID, enabled: dto.enabled, updatedAt: dto.updatedAt)
    }
}

enum SettingsMapper {
    static func mapPatch(_ dto: SpiritPatchResultDTO, serverTime: Date?) throws -> SessionPatch {
        let patch = try SessionPatchMapper.map(dto.patch, serverTime: serverTime)
        return try SessionPatchMapper.attachingQuotas(patch, from: dto.quotas)
    }

    static func mapDeletion(_ dto: AccountDeletionDTO) -> AccountDeletion {
        AccountDeletion(
            deletionID: dto.deletionID,
            status: dto.status,
            requestedAt: dto.requestedAt
        )
    }
}
