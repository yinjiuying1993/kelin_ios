import Foundation

actor BootstrapCoordinator {
    private var inFlightTask: Task<BootstrapSnapshot, Error>?

    func fetch(using service: any BootstrapServiceProtocol) async throws -> BootstrapSnapshot {
        if let inFlightTask {
            return try await inFlightTask.value
        }

        let task = Task {
            try await service.fetchBootstrap()
        }
        inFlightTask = task
        defer { inFlightTask = nil }
        return try await task.value
    }
}
