import XCTest
@testable import Kelin

final class PactPresentationTests: XCTestCase {
    func testUnsignedAndCompletedCopyMatchSpecification() {
        XCTAssertEqual(PactPresentationRules.headerTitle(for: .unsigned), "本周契约")
        XCTAssertEqual(PactPresentationRules.headerSubtitle(for: .unsigned, dayIndex: 1), "未签约")
        XCTAssertEqual(PactPresentationRules.themeTitle(.interview), "面试题")
        XCTAssertEqual(PactPresentationRules.themeTitle(.notes), "把你的笔记给我")
        XCTAssertEqual(PactPresentationRules.emptyWeekCopy(), "这一周还没有约定要学的事")
        XCTAssertEqual(PactPresentationRules.skipConfirmTitle(), "今天不学了？")
        XCTAssertEqual(PactPresentationRules.skipConfirmMessage(), "完整度会下降，但不会伤害关系。")
        XCTAssertEqual(PactPresentationRules.startTodayTitle(), "开始今天的 3 题")
        XCTAssertEqual(PactPresentationRules.todayCompletedButtonTitle(), "等它明天回来")
        XCTAssertEqual(PactPresentationRules.bringRuneHomeTitle(), "把这道纹带回房间")
        XCTAssertEqual(PactPresentationRules.headerTitle(for: .completed), "契约完成")
        XCTAssertEqual(PactPresentationRules.themeSideLabel(.interview), "晨起生成")
        XCTAssertEqual(PactPresentationRules.themeSideLabel(.notes), "晚间研读")
        XCTAssertEqual(PactPresentationRules.dailyQuestionCount, 3)
    }

    @MainActor
    func testLocalPhaseMachineDoesNotCallPactRoutes() {
        let model = PactViewModel(spiritName: "雾生", isOffline: false, usesRemotePactAPI: false)
        XCTAssertEqual(model.phase, .unsigned)
        XCTAssertFalse(P15PactContractManifest.liveHasPactWriteRoutes)
        XCTAssertFalse(P15PactContractManifest.allowsIndependentComplete)

        model.selectTheme(.notes)
        model.commitUnsigned()
        XCTAssertEqual(model.phase, .active)

        model.startToday()
        XCTAssertEqual(model.phase, .answering(index: 0))
        model.draftAnswer = "先讲背景，再讲两难。"
        model.submitAnswer()
        XCTAssertEqual(model.phase, .reviewing(index: 0))
        model.continueAfterReview()
        XCTAssertEqual(model.phase, .answering(index: 1))
    }

    @MainActor
    func testSkipTodayGoesToTodayCompletedWithoutChangingCompleteness() {
        let model = PactViewModel(spiritName: "雾生", isOffline: false)
        model.commitUnsigned()
        let before = model.completenessPercent
        model.confirmSkipToday()
        XCTAssertEqual(model.phase, .todayCompleted)
        XCTAssertEqual(model.completenessPercent, before)
    }

    @MainActor
    func testCompletedPreviewUsesDraftPercentWithoutRemoteCall() {
        let model = PactViewModel(spiritName: "雾生", isOffline: false)
        model.previewCompleted()
        XCTAssertEqual(model.phase, .completed)
        XCTAssertEqual(model.completenessPercent, PactDraftFixtures.sampleCompletedPercent)
        XCTAssertFalse(model.usesRemotePactAPI)
    }
}
