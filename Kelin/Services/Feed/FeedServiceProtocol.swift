import Foundation

protocol FeedServiceProtocol: Sendable {
    func createFood(clientID: UUID) async throws -> FeedMutation
    func createKnowledge(text: String, clientID: UUID) async throws -> FeedMutation
    func createEmotion(emotion: String, note: String?, clientID: UUID) async throws -> FeedMutation
    func createPromise(text: String, remindAt: Date, clientID: UUID) async throws -> FeedMutation
    func createLocationSight(
        label: String,
        city: String,
        category: String?,
        clientID: UUID
    ) async throws -> FeedMutation
    func createPhotoSight(clientID: UUID) async throws -> FeedMutation
    func patchPromise(
        feedID: UUID,
        expectedVersion: Int,
        text: String,
        remindAt: Date,
        clientID: UUID
    ) async throws -> FeedMutation
    func completePromise(
        feedID: UUID,
        expectedVersion: Int,
        clientID: UUID
    ) async throws -> FeedMutation
    func cancelPromise(
        feedID: UUID,
        expectedVersion: Int,
        clientID: UUID
    ) async throws -> FeedMutation
    func requestSightUploadURL(
        feedID: UUID,
        sizeBytes: Int,
        sha256: String,
        clientID: UUID
    ) async throws -> SightUploadTicket
    func moderateSight(
        feedID: UUID,
        uploadSessionID: UUID,
        clientID: UUID
    ) async throws -> FeedMutation
}
