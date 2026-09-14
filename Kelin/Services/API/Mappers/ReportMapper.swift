import Foundation

enum ReportMapper {
    static func mapSnapshot(_ dto: ReportSnapshotDTO) throws -> ReportSnapshot {
        guard let status = ReportStatus(rawValue: dto.status) else {
            throw AppError.decoding
        }
        return ReportSnapshot(
            status: status,
            reportID: dto.reportID,
            eligibility: ReportEligibility(
                isEligible: dto.eligibility.isEligible,
                eligibleAt: dto.eligibility.eligibleAt,
                daysRemaining: dto.eligibility.daysRemaining,
                requiredDialogueRounds: dto.eligibility.requiredDialogueRounds,
                completedDialogueRounds: dto.eligibility.completedDialogueRounds,
                dialogueRoundsRemaining: dto.eligibility.dialogueRoundsRemaining
            ),
            card: try dto.card.map(mapCard)
        )
    }

    static func mapCard(_ dto: ReportCardDTO) throws -> ReportCard {
        guard let stage = SpiritStage(rawValue: dto.spirit.stage) else {
            throw AppError.decoding
        }
        let signature: String?
        if dto.status == "ready" {
            signature = dto.signatureLine
        } else {
            signature = nil
        }
        return ReportCard(
            id: dto.id,
            status: dto.status,
            rulesVersion: dto.rulesVersion,
            title: dto.title,
            spirit: ReportCardSpirit(
                id: dto.spirit.id,
                name: dto.spirit.name,
                stage: stage,
                publicLayers: dto.spirit.publicLayers
            ),
            roomWeather: dto.roomWeather,
            topTraits: dto.topTraits.map { ReportTopTrait(dimension: $0.dimension, value: $0.value) },
            topMemories: dto.topMemories.map {
                ReportCardMemory(id: $0.id, type: $0.type, summary: $0.summary, unavailable: $0.unavailable)
            },
            scholarMarks: dto.scholarMarks,
            signatureLine: signature,
            inviteCode: dto.inviteCode,
            generatedAt: dto.generatedAt,
            version: dto.version
        )
    }

    static func mapLine(_ dto: ReportLineResultDTO, serverTime: Date?) throws -> ReportLineMutation {
        ReportLineMutation(
            card: try mapCard(dto.resource),
            patch: try SessionPatchMapper.map(dto.patch, serverTime: serverTime)
        )
    }
}
