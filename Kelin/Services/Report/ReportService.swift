import Foundation

protocol ReportServiceProtocol: Sendable {
    func snapshot() async throws -> ReportSnapshot
    func requestLine(reportID: UUID, expectedVersion: Int, clientID: UUID) async throws -> ReportLineMutation
}

actor APIReportService: ReportServiceProtocol {
    private let client: any APIClientProtocol

    init(client: any APIClientProtocol) {
        self.client = client
    }

    func snapshot() async throws -> ReportSnapshot {
        let dto = try await client.send(.get("/report"), responseType: ReportSnapshotDTO.self)
        return try ReportMapper.mapSnapshot(dto)
    }

    func requestLine(reportID: UUID, expectedVersion: Int, clientID: UUID) async throws -> ReportLineMutation {
        let result = try await client.sendWithMetadata(
            .post(
                "/report/line",
                body: APIDecoding.encodeBody(
                    ReportLineRequestDTO(
                        clientID: clientID,
                        reportID: reportID,
                        expectedVersion: expectedVersion
                    )
                )
            ),
            responseType: ReportLineResultDTO.self
        )
        return try ReportMapper.mapLine(result.payload, serverTime: result.serverTime)
    }
}

actor MockReportService: ReportServiceProtocol {
    func snapshot() async throws -> ReportSnapshot {
        ReportSnapshot(
            status: .locked,
            reportID: nil,
            eligibility: ReportEligibility(
                isEligible: false,
                eligibleAt: Date(),
                daysRemaining: 7,
                requiredDialogueRounds: 10,
                completedDialogueRounds: 0,
                dialogueRoundsRemaining: 10
            )
        )
    }

    func requestLine(reportID: UUID, expectedVersion: Int, clientID: UUID) async throws -> ReportLineMutation {
        throw AppError.invalidInput
    }
}
