import Foundation

@MainActor
@Observable
final class ReportViewModel {
    private(set) var snapshot: ReportSnapshot
    private(set) var bannerMessage: String?
    private(set) var isLoading = false

    let spiritName: String
    let isOffline: Bool
    let usesRemoteReportAPI: Bool
    private let reportService: (any ReportServiceProtocol)?
    private let clientIDs: P16P20ClientIDStore?
    private let accountUserID: UUID?
    private let onPatch: ((SessionPatch) -> Void)?
    private let onSnapshot: ((ReportSnapshot) -> Void)?

    init(
        snapshot: ReportSnapshot,
        spiritName: String,
        isOffline: Bool,
        usesRemoteReportAPI: Bool,
        reportService: (any ReportServiceProtocol)? = nil,
        clientIDs: P16P20ClientIDStore? = nil,
        accountUserID: UUID? = nil,
        onPatch: ((SessionPatch) -> Void)? = nil,
        onSnapshot: ((ReportSnapshot) -> Void)? = nil
    ) {
        self.snapshot = snapshot
        self.spiritName = spiritName
        self.isOffline = isOffline
        self.usesRemoteReportAPI = usesRemoteReportAPI && reportService != nil
        self.reportService = reportService
        self.clientIDs = clientIDs
        self.accountUserID = accountUserID
        self.onPatch = onPatch
        self.onSnapshot = onSnapshot
    }

    func refresh() async {
        guard usesRemoteReportAPI, let reportService else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let fresh = try await reportService.snapshot()
            snapshot = fresh
            onSnapshot?(fresh)
        } catch {
            bannerMessage = ErrorCopy.app(error as? AppError ?? .unknown(requestID: "")).message
        }
    }

    func requestSignatureLine() async {
        guard usesRemoteReportAPI, let reportService else {
            bannerMessage = ReportPresentationRules.signatureMissing()
            return
        }
        guard snapshot.status == .partial, let reportID = snapshot.reportID, let version = snapshot.card?.version else {
            bannerMessage = ReportPresentationRules.signatureMissing()
            return
        }
        do {
            let clientID = try await lineClientID(reportID: reportID)
            let mutation = try await sendLine(
                reportService: reportService,
                reportID: reportID,
                expectedVersion: version,
                clientID: clientID
            )
            onPatch?(mutation.patch)
            if let report = mutation.patch.report {
                snapshot = report
            }
        } catch let error as AppError where error == .conflict {
            await refresh()
            guard snapshot.status == .partial, let reportID = snapshot.reportID, let version = snapshot.card?.version else {
                bannerMessage = ErrorCopy.app(.conflict).message
                return
            }
            do {
                let clientID = try await lineClientID(reportID: reportID)
                let mutation = try await sendLine(
                    reportService: reportService,
                    reportID: reportID,
                    expectedVersion: version,
                    clientID: clientID
                )
                onPatch?(mutation.patch)
                if let report = mutation.patch.report {
                    snapshot = report
                }
            } catch {
                bannerMessage = ErrorCopy.app(error as? AppError ?? .unknown(requestID: "")).message
            }
        } catch {
            bannerMessage = ErrorCopy.app(error as? AppError ?? .unknown(requestID: "")).message
        }
    }

    private func sendLine(
        reportService: any ReportServiceProtocol,
        reportID: UUID,
        expectedVersion: Int,
        clientID: UUID
    ) async throws -> ReportLineMutation {
        try await reportService.requestLine(
            reportID: reportID,
            expectedVersion: expectedVersion,
            clientID: clientID
        )
    }

    private func lineClientID(reportID: UUID) async throws -> UUID {
        if let clientIDs, let accountUserID {
            return try await clientIDs.clientID(
                for: P16P20ClientIDStore.reportLineKey(reportID),
                accountUserID: accountUserID
            )
        }
        return UUID()
    }
}
