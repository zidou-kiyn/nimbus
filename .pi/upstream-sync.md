# 上游同步记录

Nimbus 从 [kejilion/sh](https://github.com/kejilion/sh) 的 `5edce6d`（2026-10-25）分出，之后大幅删改，**不能直接 git merge 上游**，只能逐个审查后手动移植。
本文件由 `nimbus-upstream-sync` skill 维护。每次审查完用 `git merge -s ours` 把审过的上游提交标记为已合入（不改任何文件），
所以 `git merge-base HEAD upstream/main` 就是已审查到的位置，GitHub 上的 behind 计数也会归零。下表记录每个提交的结论。

## 审查记录

| 日期 | 上游提交 | 内容 | 结论 | Nimbus 处理 |
|---|---|---|---|---|
| 2026-10-25 | `5edce6d` | 分叉点 | — | — |
| 2026-10-26 | `681388f` `d9ee024` | fix(waf)：固定共享 WAF 版本与缓存兼容策略 | 不适用 | WAF 随 LDNMP 已删除 |
| 2026-10-26 | `8d7761a` | fix(harness)：DeepSeek Messages 地址与认证就绪检测 | 不适用 | AI / Harness 已删除；kejilion.sh 只改了上游版本号 |
| 2026-10-26 | `76bc0aa` `9b42d61` | fix(ldnmp)：保留安装错误、接受 KPanel 安装回执 | 不适用 | LDNMP / KPanel 已删除 |
