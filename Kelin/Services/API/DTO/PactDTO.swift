import Foundation

struct CreatePactRequestDTO: Encodable, Sendable, Equatable {
    let clientID: UUID
    let theme: String
    let title: String
    let notesMemoryID: UUID?

    enum CodingKeys: String, CodingKey {
        case clientID = "client_id"
        case theme
        case title
        case notesMemoryID = "notes_memory_id"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(clientID, forKey: .clientID)
        try container.encode(theme, forKey: .theme)
        try container.encode(title, forKey: .title)
        try container.encodeIfPresent(notesMemoryID, forKey: .notesMemoryID)
    }
}

struct PactSessionRequestDTO: Encodable, Sendable, Equatable {
    let clientID: UUID
    let pactID: UUID

    enum CodingKeys: String, CodingKey {
        case clientID = "client_id"
        case pactID = "pact_id"
    }
}

struct PactAnswerRequestDTO: Encodable, Sendable, Equatable {
    let clientID: UUID
    let sessionID: UUID
    let expectedSessionVersion: Int
    let questionID: String
    let text: String

    enum CodingKeys: String, CodingKey {
        case clientID = "client_id"
        case sessionID = "session_id"
        case expectedSessionVersion = "expected_session_version"
        case questionID = "question_id"
        case text
    }
}

struct PactSkipRequestDTO: Encodable, Sendable, Equatable {
    let clientID: UUID
    let pactID: UUID
    let sessionDate: String

    enum CodingKeys: String, CodingKey {
        case clientID = "client_id"
        case pactID = "pact_id"
        case sessionDate = "session_date"
    }
}

struct PactResourceDTO: Decodable, Sendable, Equatable {
    let id: UUID
    let theme: String
    let title: String
    let status: String
    let questionBankVersion: String
    let completedSessions: Int
    let skippedSessions: Int
    let completeness: Int
    let scholarMark: String?

    enum CodingKeys: String, CodingKey {
        case id
        case theme
        case title
        case status
        case questionBankVersion = "question_bank_version"
        case completedSessions = "completed_sessions"
        case skippedSessions = "skipped_sessions"
        case completeness
        case scholarMark = "scholar_mark"
    }
}

struct PactQuestionDTO: Decodable, Sendable, Equatable {
    let questionID: String
    let text: String

    enum CodingKeys: String, CodingKey {
        case questionID = "question_id"
        case text
        case prompt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if container.contains(.prompt) {
            throw DecodingError.dataCorruptedError(
                forKey: .prompt,
                in: container,
                debugDescription: "public question uses text, not prompt"
            )
        }
        questionID = try container.decode(String.self, forKey: .questionID)
        text = try container.decode(String.self, forKey: .text)
    }
}

struct PactSessionResourceDTO: Decodable, Sendable, Equatable {
    let id: UUID
    let pactID: UUID?
    let date: String
    let explain: String?
    let questions: [PactQuestionDTO]
    let rowVersion: Int
    let status: String?
    let dayIndex: Int?
    let answeredCount: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case pactID = "pact_id"
        case date
        case explain
        case questions
        case rowVersion = "row_version"
        case status
        case dayIndex = "day_index"
        case answeredCount = "answered_count"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        pactID = try container.decodeIfPresent(UUID.self, forKey: .pactID)
        date = try container.decodeIfPresent(String.self, forKey: .date) ?? ""
        explain = try container.decodeIfPresent(String.self, forKey: .explain)
        questions = try container.decodeIfPresent([PactQuestionDTO].self, forKey: .questions) ?? []
        rowVersion = try container.decodeIfPresent(Int.self, forKey: .rowVersion) ?? 0
        status = try container.decodeIfPresent(String.self, forKey: .status)
        dayIndex = try container.decodeIfPresent(Int.self, forKey: .dayIndex)
        answeredCount = try container.decodeIfPresent(Int.self, forKey: .answeredCount)
        if !questions.isEmpty, questions.count != PactPresentationRules.dailyQuestionCount {
            throw DecodingError.dataCorruptedError(
                forKey: .questions,
                in: container,
                debugDescription: "session must contain exactly 3 questions"
            )
        }
    }
}

struct PactFeedbackDTO: Decodable, Sendable, Equatable {
    let summary: String
}

struct PactMistakeDTO: Decodable, Sendable, Equatable {
    let questionID: String?
    let summary: String

    enum CodingKeys: String, CodingKey {
        case questionID = "question_id"
        case summary
    }
}

struct PactAnswerResourceDTO: Decodable, Sendable, Equatable {
    let finalized: Bool
    let score: Int?
    let pactStatus: String?
    let feedback: PactFeedbackDTO?
    let mistakes: [PactMistakeDTO]?
    let answeredCount: Int?
    let rowVersion: Int?

    enum CodingKeys: String, CodingKey {
        case finalized
        case score
        case pactStatus = "pact_status"
        case feedback
        case mistakes
        case answeredCount = "answered_count"
        case rowVersion = "row_version"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        finalized = try container.decode(Bool.self, forKey: .finalized)
        score = try container.decodeIfPresent(Int.self, forKey: .score)
        pactStatus = try container.decodeIfPresent(String.self, forKey: .pactStatus)
        feedback = try container.decodeIfPresent(PactFeedbackDTO.self, forKey: .feedback)
        mistakes = try container.decodeIfPresent([PactMistakeDTO].self, forKey: .mistakes)
        answeredCount = try container.decodeIfPresent(Int.self, forKey: .answeredCount)
        rowVersion = try container.decodeIfPresent(Int.self, forKey: .rowVersion)
        if finalized {
            guard score != nil, let pactStatus, !pactStatus.isEmpty else {
                throw DecodingError.dataCorruptedError(
                    forKey: .finalized,
                    in: container,
                    debugDescription: "finalized answer must include score and pact_status"
                )
            }
        }
    }
}

struct PactCreateResultDTO: Decodable, Sendable, Equatable {
    let resource: PactResourceDTO
    let patch: SessionPatchDTO
    let quotas: [QuotaEntryDTO]?
    let events: [MutationEventDTO]

    enum CodingKeys: String, CodingKey {
        case resource
        case patch
        case quotas
        case events
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        resource = try container.decode(PactResourceDTO.self, forKey: .resource)
        patch = try container.decode(SessionPatchDTO.self, forKey: .patch)
        quotas = try container.decodeIfPresent([QuotaEntryDTO].self, forKey: .quotas)
        events = try container.decodeIfPresent([MutationEventDTO].self, forKey: .events) ?? []
    }
}

struct PactSessionResultDTO: Decodable, Sendable, Equatable {
    let resource: PactSessionResourceDTO
    let patch: SessionPatchDTO
    let quotas: [QuotaEntryDTO]?
    let events: [MutationEventDTO]

    enum CodingKeys: String, CodingKey {
        case resource
        case patch
        case quotas
        case events
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        resource = try container.decode(PactSessionResourceDTO.self, forKey: .resource)
        patch = try container.decode(SessionPatchDTO.self, forKey: .patch)
        quotas = try container.decodeIfPresent([QuotaEntryDTO].self, forKey: .quotas)
        events = try container.decodeIfPresent([MutationEventDTO].self, forKey: .events) ?? []
    }
}

struct PactAnswerResultDTO: Decodable, Sendable, Equatable {
    let resource: PactAnswerResourceDTO
    let patch: SessionPatchDTO
    let quotas: [QuotaEntryDTO]?
    let events: [MutationEventDTO]

    enum CodingKeys: String, CodingKey {
        case resource
        case patch
        case quotas
        case events
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        resource = try container.decode(PactAnswerResourceDTO.self, forKey: .resource)
        patch = try container.decode(SessionPatchDTO.self, forKey: .patch)
        quotas = try container.decodeIfPresent([QuotaEntryDTO].self, forKey: .quotas)
        events = try container.decodeIfPresent([MutationEventDTO].self, forKey: .events) ?? []
    }
}

struct PactSkipResultDTO: Decodable, Sendable, Equatable {
    let resource: PactSessionResourceDTO
    let patch: SessionPatchDTO
    let quotas: [QuotaEntryDTO]?
    let events: [MutationEventDTO]

    enum CodingKeys: String, CodingKey {
        case resource
        case patch
        case quotas
        case events
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        resource = try container.decode(PactSessionResourceDTO.self, forKey: .resource)
        patch = try container.decode(SessionPatchDTO.self, forKey: .patch)
        quotas = try container.decodeIfPresent([QuotaEntryDTO].self, forKey: .quotas)
        events = try container.decodeIfPresent([MutationEventDTO].self, forKey: .events) ?? []
    }
}
