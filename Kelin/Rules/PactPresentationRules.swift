import Foundation

enum PactTheme: String, CaseIterable, Equatable, Sendable {
    case interview
    case notes
}

enum PactScreenPhase: Equatable, Sendable {
    case unsigned
    case active
    case answering(index: Int)
    case reviewing(index: Int)
    case todayCompleted
    case completed
}

enum PactPresentationRules {
    static let weekDays = 7
    static let dailyQuestionCount = 3

    static func headerTitle(for phase: PactScreenPhase) -> String {
        switch phase {
        case .completed:
            String(localized: "契约完成")
        default:
            String(localized: "本周契约")
        }
    }

    static func headerSubtitle(for phase: PactScreenPhase, dayIndex: Int) -> String {
        switch phase {
        case .unsigned:
            String(localized: "未签约")
        case .completed:
            String(localized: "七日共学契约达成")
        default:
            String(localized: "第 \(dayIndex) 天 / \(weekDays) 天")
        }
    }

    static func themeTitle(_ theme: PactTheme) -> String {
        switch theme {
        case .interview:
            String(localized: "面试题")
        case .notes:
            String(localized: "把你的笔记给我")
        }
    }

    static func themeKindLabel(_ theme: PactTheme) -> String {
        switch theme {
        case .interview:
            String(localized: "契约类型 · 系统题库")
        case .notes:
            String(localized: "契约类型 · 自定义知识")
        }
    }

    static func themeBody(_ theme: PactTheme) -> String {
        switch theme {
        case .interview:
            String(localized: "精选经典技术与项目复盘，雾生每日为你提炼 3 题，梳理两难权衡与量化结果。")
        case .notes:
            String(localized: "粘贴你正在看的书摘、工作笔记或行业词条，雾生将把它们拆解为睡前探讨。")
        }
    }

    static func themeMeta(_ theme: PactTheme) -> String {
        switch theme {
        case .interview:
            String(localized: "周期 7 天 · 每日约 5 分钟")
        case .notes:
            String(localized: "周期 7 天 · 需投喂一段知识")
        }
    }

    static func themeSideLabel(_ theme: PactTheme) -> String {
        switch theme {
        case .interview:
            String(localized: "晨起生成")
        case .notes:
            String(localized: "晚间研读")
        }
    }

    static func commitTitle(for theme: PactTheme) -> String {
        switch theme {
        case .interview:
            String(localized: "定下本周契约 · 面试题")
        case .notes:
            String(localized: "定下本周契约 · 自定义笔记")
        }
    }

    static func skipConfirmTitle() -> String {
        String(localized: "今天不学了？")
    }

    static func skipConfirmMessage() -> String {
        String(localized: "完整度会下降，但不会伤害关系。")
    }

    static func emptyWeekCopy() -> String {
        String(localized: "这一周还没有约定要学的事")
    }

    static func todayCompletedButtonTitle() -> String {
        String(localized: "等它明天回来")
    }

    static func startTodayTitle() -> String {
        String(localized: "开始今天的 3 题")
    }

    static func bringRuneHomeTitle() -> String {
        String(localized: "把这道纹带回房间")
    }
}
