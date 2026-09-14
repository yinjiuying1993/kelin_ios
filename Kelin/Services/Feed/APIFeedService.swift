import Foundation

actor APIFeedService: FeedServiceProtocol {
    private let client: any APIClientProtocol

    init(client: any APIClientProtocol) {
        self.client = client
    }

    func createFood(clientID: UUID) async throws -> FeedMutation {
        try await sendMutation(
            .post("/feed", body: FeedEncoding.encodeBody(FeedFoodRequestDTO(clientID: clientID)))
        )
    }

    func createKnowledge(text: String, clientID: UUID) async throws -> FeedMutation {
        try await sendMutation(
            .post(
                "/feed",
                body: FeedEncoding.encodeBody(
                    FeedKnowledgeRequestDTO(
                        clientID: clientID,
                        payload: FeedKnowledgePayloadDTO(text: text)
                    )
                )
            )
        )
    }

    func createEmotion(emotion: String, note: String?, clientID: UUID) async throws -> FeedMutation {
        try await sendMutation(
            .post(
                "/feed",
                body: FeedEncoding.encodeBody(
                    FeedEmotionRequestDTO(
                        clientID: clientID,
                        payload: FeedEmotionPayloadDTO(emotion: emotion, note: note)
                    )
                )
            )
        )
    }

    func createPromise(text: String, remindAt: Date, clientID: UUID) async throws -> FeedMutation {
        try await sendMutation(
            .post(
                "/feed",
                body: FeedEncoding.encodeBody(
                    FeedPromiseRequestDTO(
                        clientID: clientID,
                        payload: FeedPromisePayloadDTO(text: text, remindAt: remindAt)
                    )
                )
            )
        )
    }

    func createLocationSight(
        label: String,
        city: String,
        category: String?,
        clientID: UUID
    ) async throws -> FeedMutation {
        try await sendMutation(
            .post(
                "/feed",
                body: FeedEncoding.encodeBody(
                    FeedSightLocationRequestDTO(
                        clientID: clientID,
                        payload: FeedSightLocationPayloadDTO(
                            label: label,
                            city: city,
                            category: category
                        )
                    )
                )
            )
        )
    }

    func createPhotoSight(clientID: UUID) async throws -> FeedMutation {
        try await sendMutation(
            .post("/feed", body: FeedEncoding.encodeBody(FeedSightPhotoRequestDTO(clientID: clientID)))
        )
    }

    func patchPromise(
        feedID: UUID,
        expectedVersion: Int,
        text: String,
        remindAt: Date,
        clientID: UUID
    ) async throws -> FeedMutation {
        try await sendMutation(
            .patch(
                "/feeds/\(feedID.uuidString.lowercased())",
                body: FeedEncoding.encodeBody(
                    FeedPromisePatchRequestDTO(
                        clientID: clientID,
                        expectedVersion: expectedVersion,
                        text: text,
                        remindAt: remindAt
                    )
                )
            )
        )
    }

    func completePromise(
        feedID: UUID,
        expectedVersion: Int,
        clientID: UUID
    ) async throws -> FeedMutation {
        try await sendMutation(
            .post(
                "/feeds/\(feedID.uuidString.lowercased())/complete",
                body: FeedEncoding.encodeBody(
                    FeedPromiseActionRequestDTO(clientID: clientID, expectedVersion: expectedVersion)
                )
            )
        )
    }

    func cancelPromise(
        feedID: UUID,
        expectedVersion: Int,
        clientID: UUID
    ) async throws -> FeedMutation {
        try await sendMutation(
            .post(
                "/feeds/\(feedID.uuidString.lowercased())/cancel",
                body: FeedEncoding.encodeBody(
                    FeedPromiseActionRequestDTO(clientID: clientID, expectedVersion: expectedVersion)
                )
            )
        )
    }

    func requestSightUploadURL(
        feedID: UUID,
        sizeBytes: Int,
        sha256: String,
        clientID: UUID
    ) async throws -> SightUploadTicket {
        let dto = try await client.send(
            .post(
                "/storage/sight-upload-url",
                body: FeedEncoding.encodeBody(
                    SightUploadURLRequestDTO(
                        clientID: clientID,
                        feedID: feedID,
                        sizeBytes: sizeBytes,
                        sha256: sha256
                    )
                )
            ),
            responseType: SightUploadURLResultDTO.self
        )
        return try FeedMapper.mapUpload(dto)
    }

    func moderateSight(
        feedID: UUID,
        uploadSessionID: UUID,
        clientID: UUID
    ) async throws -> FeedMutation {
        try await sendMutation(
            .post(
                "/moderate-sight",
                body: FeedEncoding.encodeBody(
                    ModerateSightRequestDTO(
                        clientID: clientID,
                        feedID: feedID,
                        uploadSessionID: uploadSessionID
                    )
                )
            )
        )
    }

    private func sendMutation(_ endpoint: APIEndpoint) async throws -> FeedMutation {
        let result = try await client.sendWithMetadata(
            endpoint,
            responseType: FeedMutationResultDTO.self
        )
        return try FeedMapper.map(result.payload, serverTime: result.serverTime)
    }
}
