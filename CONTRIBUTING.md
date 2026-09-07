# 贡献指南

本仓库是刻灵 iOS 客户端仓库：`yinjiuying1993/kelin_ios`。只接受 iOS 源码、资源、客户端配置、测试和 fixture；服务端实现与共享计划不属于本仓库。

本地刻灵工作区还应阅读权威规范：

`/Users/robosen/Desktop/work/1_plan/governance/GIT_COMMIT_AND_PR_STANDARD.md`

该本机路径仅用于本项目工作区，不作为 GitHub 可访问链接。若本文与统一规范冲突，以统一规范为准。

## 开始前

- 一次只执行一个 `Pxx-Txx`；非计划缺陷使用 `BUG-<id>`。
- 检查当前分支、`git status` 和 `git diff`，保护用户已有修改。
- 从最新 `main` 创建分支，禁止直接向 `main` 提交。
- 涉及 API 时先确认经评审的 OpenAPI SHA 和 fixture，再实现 DTO 与网络逻辑。
- 不得修改工作区的 `1_plan/` 或 `0_kelin/`。

### 空仓库首次提交

当前远端尚无 `main`。允许一次性将仅包含仓库治理文件的 bootstrap 提交推送为 `main`：

```text
chore(repo): 建立仓库协作基线

Refs: GOV-001
```

首次提交不得包含业务代码。远端 `main` 建立并配置保护后，P01 及后续所有代码必须从任务分支经 PR 合并。AI 未获用户明确授权时仍不得自行 commit 或 push。

## 分支

格式：

```text
<type>/<Pxx-Txx>-<short-description>
```

`type` 可用 `feat`、`fix`、`refactor`、`test`、`docs`、`chore`、`security`、`hotfix`。描述使用小写英文和连字符。

```bash
git fetch origin
git switch main
git pull --ff-only origin main
git switch -c feat/P08-T03-room-empty-state
```

## Commit

使用 Conventional Commits：

```text
type(scope): 中文摘要

Refs: P08-T03
```

常用 scope：

`app`、`core`、`network`、`auth`、`room`、`chat`、`memory`、`feed`、`voice`、`social`、`notification`、`settings`、`persistence`、`ui`、`accessibility`、`test`、`build`

- 标题不超过 72 个字符。
- 一个 commit 表达一个可审查、可回滚的意图。
- 测试必须与对应行为在同一 PR。
- 禁止 `WIP`、`final`、`fix stuff`、`misc changes` 等无意义提交。
- Breaking change 使用 `type(scope)!:` 并添加 `BREAKING CHANGE:` footer。

示例：

```text
feat(room): 实现房间空状态渲染

Refs: P08-T03
```

## Pull Request

标题：

```text
[Pxx-Txx][iOS] 目标
```

契约专属 PR 可使用 `[Pxx-Txx][Contract] 目标`，缺陷可使用 `[BUG-<id>][iOS] 目标`。

- 一个任务一个分支、一个 PR，不捆绑无关重构或下一任务。
- 未完成实现、测试或证据时保持 Draft。
- Ready 前填写模板所有适用项，粘贴完整命令和真实退出码。
- 建议不超过 15 个业务文件或 500 行人工代码；超出需说明或拆分。初始化、生成物可合理例外。
- 跨仓变更必须链接 Server PR，并注明 `Server 兼容契约 → iOS → Server 清理` 的合并顺序。

## iOS 检查项

仓库初始为空，具体命令必须在工程建立后根据真实 scheme、脚本和 CI 发现，不得虚构。适用检查基线：

- Debug build。
- Release build，或说明限制后执行 generic iOS Simulator build。
- Unit tests。
- Swift strict concurrency 编译检查。
- DTO 编解码和契约 fixture tests。
- UI 三种代表尺寸与 Dynamic Type、VoiceOver、对比度等无障碍检查。
- 相机、麦克风、推送、后台、钥匙串或系统权限变更按需提供真机、系统版本、步骤和结果。

所有结果必须记录实际完整命令、真实退出码与关键证据。“测试通过”不能替代命令。

## Secret、隐私与仓库卫生

禁止提交：

- `.env`、令牌、密码、私钥、证书、provisioning profile、云凭据。
- 真实姓名、账号、手机号、邮箱、设备标识、聊天、记忆、语音或其他隐私数据。
- 未脱敏日志、生产数据、崩溃包。
- `DerivedData`、用户态 Xcode 数据、构建产物和 IDE/OS 临时文件。

fixture 必须使用合成、脱敏数据，并验证与指定 OpenAPI SHA 一致。

## Review 与人工验收

- 至少一次独立审查；所有 review conversation 必须解决。
- 契约、认证授权、账号删除与隐私变更需要专项审查。
- 作者不能用 AI 报告替代截图、真机操作或人工验收。
- 个人项目可记录“人工自审 + 独立 AI 只读复查”，但发布门禁仍由人工签署。

## AI 边界

AI 必须先检查 `git status`、分支和 diff，只改当前任务范围，保护用户修改，并交付 PR 草案。除非用户明确要求，AI 不得 commit、push、创建 PR；任何情况下不得自行批准、签署验收或合并，也不得声称未实际运行的构建、真机或 CI 已通过。

## 合并

- 只允许 Squash merge；PR 标题即最终 commit 标题。
- 保持 `main` 线性历史，合并后删除分支。
- 禁止 merge commit、rebase merge、直接或 force push 到 `main`。
- checks 失败、conversation 未解决、缺少人工验收、存在 P0 或安全问题时禁止合并。
- 冲突应理解双方意图后逐项解决并重跑检查；不得用 `git reset --hard` 丢弃共享改动。

仓库管理员后续应在 CI 建立后，按真实 check 名称保护 `main`，要求 conversation resolution 和 linear history，阻止 force push/deletion，开启自动删分支并只保留 Squash merge。本文不表示这些设置已经配置。
