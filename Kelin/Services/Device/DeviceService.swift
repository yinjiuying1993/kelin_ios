import Foundation
import UIKit

enum DeviceAPNsEnvironment {
    static var current: String {
        #if DEBUG
        "sandbox"
        #else
        "production"
        #endif
    }
}

enum DeviceInstallationStore {
    private static let installationKey = "kelin.device.installation_id"

    static func installationID() -> UUID {
        if let raw = UserDefaults.standard.string(forKey: installationKey),
           let id = UUID(uuidString: raw) {
            return id
        }
        let id = UUID()
        UserDefaults.standard.set(id.uuidString, forKey: installationKey)
        return id
    }

    static func clientID(environment: String, enabled: Bool) -> UUID {
        let key = "kelin.device.client_id.\(environment).\(enabled ? "on" : "off")"
        if let raw = UserDefaults.standard.string(forKey: key), let id = UUID(uuidString: raw) {
            return id
        }
        let id = UUID()
        UserDefaults.standard.set(id.uuidString, forKey: key)
        return id
    }
}

@MainActor
enum DeviceTokenCenter {
    static let didUpdate = Notification.Name("kelin.device.apnsTokenDidUpdate")
    private(set) static var apnsToken: String?

    static func setToken(_ token: String) {
        guard token.count >= 16 else {
            KelinLog.api.info("device_register_skipped reason=token_too_short")
            return
        }
        apnsToken = token
        NotificationCenter.default.post(name: didUpdate, object: nil)
    }

    static func requestRemoteNotificationsIfNeeded() {
        UIApplication.shared.registerForRemoteNotifications()
    }
}

protocol DeviceServiceProtocol: Sendable {
    func register(
        installationID: UUID,
        apnsToken: String,
        environment: String,
        enabled: Bool,
        appVersion: String?,
        locale: String?,
        clientID: UUID
    ) async throws -> DeviceRegistration
}

actor APIDeviceService: DeviceServiceProtocol {
    private let client: any APIClientProtocol

    init(client: any APIClientProtocol) {
        self.client = client
    }

    func register(
        installationID: UUID,
        apnsToken: String,
        environment: String,
        enabled: Bool,
        appVersion: String?,
        locale: String?,
        clientID: UUID
    ) async throws -> DeviceRegistration {
        let dto = try await client.send(
            .post(
                "/devices",
                body: APIDecoding.encodeBody(
                    RegisterDeviceRequestDTO(
                        clientID: clientID,
                        installationID: installationID,
                        apnsToken: apnsToken,
                        environment: environment,
                        enabled: enabled,
                        appVersion: appVersion,
                        locale: locale
                    )
                )
            ),
            responseType: DeviceRegistrationDTO.self
        )
        return DeviceMapper.map(dto)
    }
}

actor MockDeviceService: DeviceServiceProtocol {
    func register(
        installationID: UUID,
        apnsToken: String,
        environment: String,
        enabled: Bool,
        appVersion: String?,
        locale: String?,
        clientID: UUID
    ) async throws -> DeviceRegistration {
        DeviceRegistration(deviceID: UUID(), enabled: enabled, updatedAt: Date())
    }
}
