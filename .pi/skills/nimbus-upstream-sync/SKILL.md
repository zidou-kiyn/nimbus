---
name: nimbus-upstream-sync
description: 审查上游 kejilion/sh 自上次同步以来的新提交，逐个判断对 Nimbus 是不适用、已覆盖、可移植还是需要按 Nimbus 结构手动改写，经用户确认后手动移植并记录。用户提到同步上游、检查上游更新、kejilion 有新提交时使用。
---

# 同步上游 kejilion/sh

Nimbus 从 kejilion/sh 的 `5edce6d` 分出，之后删掉了大半功能（KPanel、LDNMP、AI/Harness、多语言等），菜单和许多函数也重写了，所以只能逐个审查后**手动移植**。审查基线 = `git merge-base HEAD upstream/main`；结论记在 `.pi/upstream-sync.md`。

用户在本 skill 后面附加的话（例如「只看 fail2ban 相关」「审到 xxx 为止」）优先执行。

| 步骤 | 读 / 运行 |
|---|---|
| 1. 生成报告 | `python3 .pi/skills/nimbus-upstream-sync/scripts/upstream_report.py`（`--since <sha>` 手动指定基线，`--no-fetch` 跳过拉取） |
| 2. 逐个判断 | `references/review.md` |
| 3. 汇报并确认 | 见下文 |
| 4. 移植 | 加载 `nimbus-dev` skill |
| 5. 记录、提交、标记已审查 | `references/record.md` |

## 流程

1. **报告**：脚本会 fetch upstream，列出 `merge-base..upstream/main` 的非合并提交，标出改动了 nimbus 仍有的哪些函数、已删除的函数、nimbus 没有的文件，并给初步判断。没有新提交就告诉用户，结束。
2. **判断**：按 `references/review.md` 把每个提交归入 不适用 / 已覆盖 / 可移植 / 需改写 / 不采纳。
3. **汇报**：一张表 `提交 | 日期 | 标题 | 结论 | 理由（一句话）`，同类不适用可合并成一行（如「20 个 LDNMP / KPanel 提交：不适用」）。有「可移植」或「需改写」的，用 `ask_user_question`（multiSelect）让用户勾选并给出推荐；全是不适用直接进第 5 步。用户只想看看时，做完第 3 步就停，问一句要不要把结果记进 `.pi/upstream-sync.md`。
4. **移植**：按 `nimbus-dev` 的约定、测试和发版清单做。一次同步只发**一个版本**，CHANGELOG 写「同步上游修复：……」，每项注明来源，如 `（上游 76bc0aa）`。真机测试同样先问在哪几台测。
5. **记录**：按 `references/record.md` 追加记录、提交，再用 `merge -s ours` 标记已审查并校验文件未变。

## 硬规则

- **绝对不要**普通 `git merge` / `git rebase` / `git cherry-pick` 上游：会带回大量已删除的文件。唯一允许的是第 5 步的 `git merge -s ours`，且必须校验 tree 未变。
- 上游新功能默认不移植；`send_stats`、遥测、广告、kejilion 品牌链接一律不采纳；菜单编号以 nimbus 为准。
- `upstream` 远程已设 `tagOpt --no-tags`，不要拉上游 tag；`gh` 默认仓库是 `zidou-kiyn/nimbus`。对 kejilion/sh 只读，不做任何写操作（issue、PR、release 都不行）。
- 推送前按 nimbus-dev 的规则先确认。
