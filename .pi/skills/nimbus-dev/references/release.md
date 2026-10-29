# 发版清单

每次面向用户的改动都要发一个版本（只改文档的除外）。

1. 版本号：修复递增 patch，新功能视大小递增 minor 或 patch。要改的地方：`nimbus.sh` 第 4 行 `sh_v`、README 徽章 `version-x.y.z-`、README 菜单预览 `v x.y.z`、CHANGELOG 新条目。
2. `CHANGELOG.md` 末尾追加，格式和已有条目一致：
   ```
   2026-10-27   v1.2.6
   一句话概述。
   1.具体改动（用户能感知到的行为、原因、入口）。
   2.……
   ------------------------
   ```
3. 文档：入口和编号写进 `docs/features.md`、`docs/commands.md`、`docs/wizard.md`，README 特性列表视情况更新。
4. `python3 .pi/skills/nimbus-dev/scripts/check.py` 通过（会核对四处版本号一致）。
5. 提交信息用中文，一句话概括并带版本号，例如 `新增 xxx：入口…，要点…（v1.2.6）`。
6. **push 前先确认**：用户在需求里说了要推送才直接推，否则提交后问一句。已部署的服务器用 `nb self-update` 更新。
