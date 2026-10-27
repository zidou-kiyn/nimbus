---
name: nimbus-upstream-sync
description: 审查上游 kejilion/sh 自上次同步以来的新提交，逐个判断对 Nimbus 是不适用、已覆盖、可移植还是需要按 Nimbus 结构手动改写，经用户确认后手动移植并记录。用户提到同步上游、检查上游更新、kejilion 有新提交时使用。
---

# 同步上游 kejilion/sh

Nimbus 从 kejilion/sh 的 `5edce6d` 分出，之后删掉了大半功能（KPanel、LDNMP、AI/Harness、多语言等），菜单和许多函数也重写了。所以：

- **绝对不要 `git merge` / `git rebase` / `git cherry-pick` 上游**：会带回大量已删除的文件，`kejilion.sh` 和 `nimbus.sh` 也对不上。只能逐个审查后**手动移植**。
- 上游的 `kejilion.sh` 对应 nimbus 的 `nimbus.sh`；`TG-*.sh`、`Limiting_Shut_down1.sh`、`archive.key`、`LICENSE` 是同名文件；`cn/ en/ jp/ …` 多语言版、`tests/`、`apps/`、`*_manager.sh`、`kejilion_sh_log.txt` 在 nimbus 中都不存在。
- 审查进度记在 `.pi/upstream-sync.md`：`last_reviewed:` 行是基线，表格是每个提交的结论。

用户在本 skill 后面附加的话（例如「只看 fail2ban 相关」「审到 xxx 为止」）优先执行。

## 第 1 步：生成报告

```bash
python3 .pi/skills/nimbus-upstream-sync/scripts/upstream_report.py
```

脚本会 `git fetch --no-tags upstream`，列出 `last_reviewed..upstream/main` 中所有非合并提交。每个提交给出：改动了 nimbus 仍有的哪些函数（带行数）、已删除的函数、nimbus 没有的文件，以及一个初步判断。

没有新提交就直接告诉用户，结束。

## 第 2 步：逐个判断

初判为「可能不适用」的，扫一眼提交标题确认即可，不用读 diff。初判为「需要人工判断」的，读 diff：

```bash
git show <sha> -- kejilion.sh                     # 上游改动
git show <sha>^:kejilion.sh | sed -n '/^函数名() {/,/^}/p'   # 上游改动前的函数
sed -n '/^函数名() {/,/^}/p' nimbus.sh            # nimbus 现在的函数
git log --format='%h %s' -L '/^函数名() {/,/^}/:nimbus.sh' | grep -v '^$' | head   # nimbus 对它改过什么
```

每个提交归入一类：

| 结论 | 含义 | 处理 |
|---|---|---|
| 不适用 | 改的是 nimbus 已删除的功能，或只改了上游版本号、日志、多语言版、测试 | 只记录 |
| 已覆盖 | nimbus 已经用别的方式修过或重写过（对比 CHANGELOG 和函数现状） | 只记录，注明对应的 nimbus 版本 |
| 可移植 | nimbus 的函数和上游改动前基本一致，补丁能原样套用或稍作调整 | 手动套用 |
| 需改写 | 问题在 nimbus 中同样存在，但代码结构不同，要按 nimbus 的写法重新实现 | 按 nimbus 约定重写 |
| 不采纳 | 适用，但和 nimbus 的取向冲突（遥测、广告、推广链接、Nimbus 已刻意删掉的行为、过度复杂） | 只记录原因 |

判断要点：
- 只看意图，不照抄。上游是 bug 修复的话，先确认 nimbus 是否真有同样的 bug（可能已重写，或调用路径已删除）。
- 上游的新功能默认**不**移植，除非用户在 skill 参数里要求、或者明显属于 nimbus 已有的模块（系统工具、BBR、SSH、fail2ban、Docker 管理等）。
- 涉及菜单编号和文案的改动，以 nimbus 现有菜单为准，不要照搬上游的编号。
- 上游 `send_stats`、遥测、广告、kejilion 品牌链接一律不采纳。

## 第 3 步：向用户汇报并确认

用一张表列出全部提交：`提交 | 日期 | 标题 | 结论 | 理由（一句话）`。「不适用」的多时可以合并成一行，例如「20 个 LDNMP / KPanel 提交：不适用」。

如果有「可移植」或「需改写」的，用 `ask_user_question` 让用户勾选要做哪些（multiSelect），并给出推荐。全是不适用就不用问，直接进第 5 步。

## 第 4 步：移植

**加载 `nimbus-dev` skill**（`.pi/skills/nimbus-dev/SKILL.md`），按它的编码约定、测试方法和发版清单来做：
- 一次同步只发**一个版本**，CHANGELOG 的条目写「同步上游修复：……」，每一项注明来源，例如 `（上游 76bc0aa）`。
- 改动必须通过 `scripts/check.py`，并按 nimbus-dev 的方法测试。真机测试同样要先问用户在哪几台测。

## 第 5 步：更新记录并提交

1. 在 `.pi/upstream-sync.md` 的表格末尾按时间顺序追加本次审查的每个提交（不适用的同类提交可以合并成一行，但所有 sha 都要列出），并把 `last_reviewed:` 改成本次审查到的最后一个上游提交的**完整 sha**（`git rev-parse <sha>`）。
2. 只更新了记录：提交信息写 `上游同步：审查至 <短 sha>，均不适用`。有移植：和代码改动一起提交，提交信息按 nimbus-dev 的格式（带版本号），末尾补一句「审查至上游 <短 sha>」。
3. 推送前按 nimbus-dev 的规则先确认。

## 注意

- `upstream` 远程已设置 `tagOpt --no-tags`，不要拉上游的 tag 到本仓库；`gh` 默认仓库是 `zidou-kiyn/nimbus`。对上游只读，不要对 kejilion/sh 执行任何写操作（issue、PR、release 都不行）。
- 用户只想看看有什么新东西、不打算移植时，做完第 1–3 步就停，但仍然可以问用户要不要把审查结果记进 `.pi/upstream-sync.md`。
