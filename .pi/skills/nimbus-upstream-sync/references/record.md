# 第 5 步：更新记录、提交、标记已审查

1. 在 `.pi/upstream-sync.md` 的表格末尾按时间顺序追加本次审查的每个提交（不适用的同类提交可以合并成一行，但所有 sha 都要列出）。
2. 提交记录（以及移植的代码）：
   - 只更新了记录：`上游同步：审查至 <短 sha>，均不适用`。
   - 有移植：按 nimbus-dev 的格式（带版本号），末尾补一句「审查至上游 <短 sha>」。
3. **标记已审查**（工作区必须干净）：
   ```bash
   before=$(git rev-parse HEAD^{tree})
   git merge -s ours --no-ff <审查到的上游 sha，通常是 upstream/main> -m "上游同步：标记已审查至 <短 sha>（-s ours，仅记录历史，不合并任何内容）"
   [ "$before" = "$(git rev-parse HEAD^{tree})" ] && echo 文件未变   # 必须输出「文件未变」，否则立即 git reset --hard HEAD^ 并报告
   git rev-list --left-right --count HEAD...upstream/main          # 右边应为 0（只审了一部分时为剩余数量）
   ```
   用户要求「审到 xxx 为止」时，合并的是那个 sha，而不是 upstream/main。
4. 推送前按 nimbus-dev 的规则先确认。

`-s ours` 只在历史上把审过的提交记为已合入，文件一行不变。它让 GitHub 上 fork 的「N commits behind」归零，也让 `git merge-base HEAD upstream/main` 成为下次审查的基线。
