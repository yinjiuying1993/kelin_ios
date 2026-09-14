import Foundation

enum PactMapper {
    static func mapPact(_ dto: PactResourceDTO) throws -> PactSummary {
        guard ["interview", "notes"].contains(dto.theme) else {
            throw AppError.decoding
        }
        guard ["active", "completed", "abandoned"].contains(dto.status) else {
            throw AppError.decoding
        }
        guard (0...100).contains(dto.completeness) else {
            throw AppError.decoding
        }
        return PactSummary(
            id: dto.id,
            theme: dto.theme,
            title: dto.title,
            status: dto.status,
            questionBankVersion: dto.questionBankVersion,
            completedSessions: dto.completedSessions,
            skippedSessions: dto.skippedSessions,
            completeness: dto.completeness,
            scholarMark: dto.scholarMark
        )
    }

    static func mapSession(_ dto: PactSessionResourceDTO) throws -> PactSession {
        if !dto.questions.isEmpty, dto.questions.count != PactPresentationRules.dailyQuestionCount {
            throw AppError.decoding
        }
        return PactSession(
            id: dto.id,
            pactID: dto.pactID,
            date: dto.date,
            explain: dto.explain,
            questions: dto.questions.map { PactQuestion(id: $0.questionID, text: $0.text) },
            rowVersion: dto.rowVersion,
            status: dto.status,
            dayIndex: dto.dayIndex,
            answeredCount: dto.answeredCount
        )
    }

    static func mapAnswer(_ dto: PactAnswerResourceDTO) throws -> PactAnswer {
        if dto.finalized, dto.score == nil || dto.pactStatus == nil {
            throw AppError.decoding
        }
        return PactAnswer(
            finalized: dto.finalized,
            score: dto.score,
            pactStatus: dto.pactStatus,
            feedbackSummary: dto.feedback?.summary,
            improvement: dto.mistakes?.first?.summary,
            answeredCount: dto.answeredCount,
            rowVersion: dto.rowVersion
        )
    }

    static func mapCreate(_ dto: PactCreateResultDTO, serverTime: Date?) throws -> PactMutation {
        let pact = try mapPact(dto.resource)
        return try mutation(pact: pact, session: nil, answer: nil, patch: dto.patch, quotas: dto.quotas, events: dto.events, serverTime: serverTime)
    }

    static func mapSessionResult(_ dto: PactSessionResultDTO, serverTime: Date?) throws -> PactMutation {
        try mutation(
            pact: try dto.patch.pact.map(mapPact),
            session: try mapSession(dto.resource),
            answer: nil,
            patch: dto.patch,
            quotas: dto.quotas,
            events: dto.events,
            serverTime: serverTime
        )
    }

    static func mapAnswerResult(_ dto: PactAnswerResultDTO, serverTime: Date?) throws -> PactMutation {
        try mutation(
            pact: try dto.patch.pact.map(mapPact),
            session: nil,
            answer: try mapAnswer(dto.resource),
            patch: dto.patch,
            quotas: dto.quotas,
            events: dto.events,
            serverTime: serverTime
        )
    }

    static func mapSkip(_ dto: PactSkipResultDTO, serverTime: Date?) throws -> PactMutation {
        try mutation(
            pact: try dto.patch.pact.map(mapPact),
            session: try mapSession(dto.resource),
            answer: nil,
            patch: dto.patch,
            quotas: dto.quotas,
            events: dto.events,
            serverTime: serverTime
        )
    }

    private static func mutation(
        pact: PactSummary?,
        session: PactSession?,
        answer: PactAnswer?,
        patch: SessionPatchDTO,
        quotas: [QuotaEntryDTO]?,
        events: [MutationEventDTO],
        serverTime: Date?
    ) throws -> PactMutation {
        let mappedPatch = try SessionPatchMapper.attachingQuotas(
            try SessionPatchMapper.map(patch, serverTime: serverTime),
            from: quotas
        )
        return PactMutation(
            pact: pact ?? mappedPatch.pact,
            session: session,
            answer: answer,
            patch: mappedPatch,
            quotas: try quotas.map { try $0.map(BootstrapMapper.mapQuota) } ?? [],
            events: events.map { MutationEvent(id: $0.id, type: $0.type, occurredAt: $0.occurredAt) }
        )
    }
}
