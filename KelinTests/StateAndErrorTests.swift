import XCTest
@testable import Kelin

final class StateAndErrorTests: XCTestCase {
    func testLoadingAndFailurePreservePreviousValue() {
        let loading = Loadable.loading(previous: [1, 2])
        let failed = Loadable.failed(
            AppError.networkUnavailable,
            previous: [1, 2]
        )

        XCTAssertTrue(loading.isLoading)
        XCTAssertEqual(loading.value, [1, 2])
        XCTAssertFalse(failed.isLoading)
        XCTAssertEqual(failed.value, [1, 2])
    }

    func testFixedProductCopyMatchesSpecification() {
        XCTAssertEqual(ErrorCopy.asrEmptyResult, "没听清，再说一次")
        XCTAssertEqual(ErrorCopy.recordingTooShort, "说得太短了")
        XCTAssertEqual(ErrorCopy.ttsQuotaExceeded, "今天先看字吧")
        XCTAssertEqual(ErrorCopy.unreliableSource, "这件事我还不知道")
        XCTAssertEqual(ErrorCopy.sightRejected, "这件它收不下")
        XCTAssertEqual(
            ErrorCopy.app(.modelUnavailable).message,
            "它这会儿说不出话"
        )
    }

    func testErrorCopyDoesNotExposeUnknownRequestID() {
        let copy = ErrorCopy.app(.unknown(requestID: "synthetic-request-id"))

        XCTAssertFalse(copy.title.contains("synthetic-request-id"))
        XCTAssertFalse(copy.message.contains("synthetic-request-id"))
    }

    func testConfigurationFailureUsesNonRecoverableCopy() {
        let copy = ErrorCopy.configuration(
            .missingValue(key: AppConfig.Key.apiBaseURL)
        )

        XCTAssertEqual(copy.title, "应用配置错误")
        XCTAssertNil(copy.recoveryActionTitle)
    }

    @MainActor
    func testStatusCardsCanBeConstructedForLoadingAndConfigurationFailure() {
        _ = KelinStatusCard(state: .loading(title: "正在加载"))
        _ = KelinStatusCard(
            state: .failure(
                ErrorCopy.configuration(
                    .missingValue(key: AppConfig.Key.apiBaseURL)
                )
            )
        )
    }
}
