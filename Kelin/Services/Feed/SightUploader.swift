import Foundation

actor SightUploader {
    private let session: URLSession

    init(session: URLSession = SightUploader.makeSession()) {
        self.session = session
    }

    func put(ticket: SightUploadTicket, jpeg: Data) async throws {
        guard ticket.method == "PUT" else {
            throw AppError.invalidInput
        }
        guard jpeg.count <= ticket.maxSizeBytes else {
            throw AppError.invalidInput
        }
        guard FeedPresentationRules.isReachableSightUploadHost(ticket.url) else {
            let host = ticket.url.host ?? "missing"
            KelinLog.api.error("sight_put_skipped reason=unreachable_host host=\(host)")
            throw AppError.sightUploadUnavailable
        }

        var request = URLRequest(url: ticket.url)
        request.httpMethod = "PUT"
        request.timeoutInterval = 30
        request.httpShouldHandleCookies = false
        request.setValue(nil, forHTTPHeaderField: "Authorization")
        for (header, value) in ticket.headers {
            request.setValue(value, forHTTPHeaderField: header)
        }

        let host = ticket.url.host ?? "unknown"
        KelinLog.api.info("sight_put_start host=\(host) bytes=\(jpeg.count)")

        let response: URLResponse
        do {
            (_, response) = try await session.upload(for: request, from: jpeg)
        } catch is CancellationError {
            throw AppError.cancelled
        } catch let error as URLError where error.code == .timedOut {
            KelinLog.api.error("sight_put_failed host=\(host) error_code=TIMED_OUT")
            throw AppError.timedOut
        } catch {
            KelinLog.api.error("sight_put_failed host=\(host) error_code=NETWORK_UNAVAILABLE")
            throw AppError.networkUnavailable
        }

        guard let http = response as? HTTPURLResponse else {
            throw AppError.networkUnavailable
        }
        guard (200...299).contains(http.statusCode) else {
            KelinLog.api.error("sight_put_failed host=\(host) http_status=\(http.statusCode)")
            throw AppError.networkUnavailable
        }
        KelinLog.api.info("sight_put_ok host=\(host) http_status=\(http.statusCode)")
    }

    private static func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.httpCookieStorage = nil
        configuration.httpShouldSetCookies = false
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 45
        return URLSession(configuration: configuration)
    }
}
