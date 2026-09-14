import Foundation

actor MockFeedService: FeedServiceProtocol {
    func createFood(clientID: UUID) async throws -> FeedMutation {
        makeAccepted(kind: "food", clientID: clientID)
    }

    func createKnowledge(text: String, clientID: UUID) async throws -> FeedMutation {
        makeAccepted(kind: "knowledge", clientID: clientID)
    }

    func createEmotion(emotion: String, note: String?, clientID: UUID) async throws -> FeedMutation {
        makeAccepted(kind: "emotion", clientID: clientID)
    }

    func createPromise(text: String, remindAt: Date, clientID: UUID) async throws -> FeedMutation {
        makeAccepted(kind: "promise", clientID: clientID, promiseStatus: "active")
    }

    func createLocationSight(
        label: String,
        city: String,
        category: String?,
        clientID: UUID
    ) async throws -> FeedMutation {
        makeAccepted(kind: "sight", clientID: clientID)
    }

    func createPhotoSight(clientID: UUID) async throws -> FeedMutation {
        makeAccepted(kind: "sight", clientID: clientID, status: "pending")
    }

    func patchPromise(
        feedID: UUID,
        expectedVersion: Int,
        text: String,
        remindAt: Date,
        clientID: UUID
    ) async throws -> FeedMutation {
        makeAccepted(kind: "promise", clientID: clientID, id: feedID, promiseStatus: "active")
    }

    func completePromise(
        feedID: UUID,
        expectedVersion: Int,
        clientID: UUID
    ) async throws -> FeedMutation {
        makeAccepted(kind: "promise", clientID: clientID, id: feedID, promiseStatus: "completed")
    }

    func cancelPromise(
        feedID: UUID,
        expectedVersion: Int,
        clientID: UUID
    ) async throws -> FeedMutation {
        makeAccepted(kind: "promise", clientID: clientID, id: feedID, status: "cancelled", promiseStatus: "cancelled")
    }

    func requestSightUploadURL(
        feedID: UUID,
        sizeBytes: Int,
        sha256: String,
        clientID: UUID
    ) async throws -> SightUploadTicket {
        SightUploadTicket(
            uploadSessionID: UUID(uuidString: "70000000-0000-4000-8000-000000000001")!,
            method: "PUT",
            url: URL(string: "https://kelin.invalid/sight")!,
            headers: ["content-type": "image/jpeg"],
            objectPath: "sight-temp/00000000-0000-4000-8000-000000000001/\(feedID.uuidString.lowercased())/00000000-0000-4000-8000-000000000002.jpg",
            expiresAt: Date().addingTimeInterval(600),
            maxSizeBytes: 5_242_880
        )
    }

    func moderateSight(
        feedID: UUID,
        uploadSessionID: UUID,
        clientID: UUID
    ) async throws -> FeedMutation {
        throw AppError.modelUnavailable
    }

    private func makeAccepted(
        kind: String,
        clientID: UUID,
        id: UUID = UUID(uuidString: "60000000-0000-4000-8000-000000000001")!,
        status: String = "accepted",
        promiseStatus: String? = nil
    ) -> FeedMutation {
        FeedMutation(
            resource: FeedResource(
                id: id,
                version: 1,
                kind: kind,
                status: status,
                promiseStatus: promiseStatus
            ),
            patch: SessionPatch(
                snapshotVersion: 1,
                spirit: nil,
                preferences: nil,
                room: nil,
                onboarding: nil,
                serverTime: Date()
            ),
            quotas: [],
            events: [],
            prop: nil
        )
    }
}
