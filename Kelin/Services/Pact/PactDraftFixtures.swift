import Foundation

struct PactQuestionFixture: Equatable, Sendable, Identifiable {
    let id: UUID
    let questionID: String
    let prompt: String
    var comment: String
    var improvement: String
}

enum PactDraftFixtures {
    static let sampleDayIndex = 3
    static let sampleCompletenessPercent = 72
    static let sampleCompletedPercent = 91
    static let sampleLastNightCorrect = 2
    static let sampleLastNightTotal = 3
    static let sampleLastNightMiss = String(localized: "结果没有量化")
    static let sampleMissArchive = String(localized: "“结果指标不够量化”已于第 5 天复盘攻克")
    static let tonightTitle = String(localized: "如何讲清项目中最困难的决定")
    static let tonightHint = String(localized: "包含背景、两难权衡与最终量化产出")
    static let organizingTopic = String(localized: "它正在整理「项目经历」")
    static let todayImprovement = String(localized: "下次先把结果指标说清楚。")

    static let questions: [PactQuestionFixture] = [
        PactQuestionFixture(
            id: UUID(uuidString: "30000000-0000-4000-8000-000000000001")!,
            questionID: "interview-v1-q1",
            prompt: String(localized: "讲一个你做过的项目，最困难的决定是什么？"),
            comment: String(localized: "背景交代清楚了，两难也站得住。"),
            improvement: String(localized: "补一句可核对的结果指标。")
        ),
        PactQuestionFixture(
            id: UUID(uuidString: "30000000-0000-4000-8000-000000000002")!,
            questionID: "interview-v1-q2",
            prompt: String(localized: "如果重来一次，你会怎样量化那个结果？"),
            comment: String(localized: "你开始用数字说话了。"),
            improvement: String(localized: "把对比基线也写进去。")
        ),
        PactQuestionFixture(
            id: UUID(uuidString: "30000000-0000-4000-8000-000000000003")!,
            questionID: "interview-v1-q3",
            prompt: String(localized: "对方追问风险时，你准备先讲哪一句？"),
            comment: String(localized: "收束比昨天稳。"),
            improvement: String(localized: "风险句再短一点。")
        ),
    ]
}
