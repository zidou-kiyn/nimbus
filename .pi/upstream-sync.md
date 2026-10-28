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
| 2026-10-27 | `93ddb82` `176d5dc` | fix(waf)：更新共享 WAF 兼容包 | 不适用 | WAF 随 LDNMP 已删除 |
| 2026-10-28 | `175e3f9` `4b27064` `3da035b` | 站点防护：WAF 事件封禁接入 CF 模式、向 KPanel 暴露防御状态、识别带前缀的 jail 列表 | 不适用 | `web_security` / `kpanel_*` 等已删除；`175e3f9` 另外只改了上游版本号 |
| 2026-10-28 | `594138a` | fix：站点 DDoS 规则幂等 | 需改写 | v1.2.26：`enable/disable_ddos_defense` 按 Nimbus 写法重写；没有 DOCKER-USER 链时跳过（上游会在第一条规则 return），规则不全时清掉重加以保证顺序；去掉 send_stats |
| 2026-10-28 | `254c0ad` | fix(fail2ban)：安装前先准备 Debian auth.log | 已覆盖 | v1.1.0 已在 `f2b_install_sshd` 中补建 auth.log（在安装之后，随后 enable --now / reload 会重新加载） |
| 2026-10-28 | `bcb22fc` `9618a86` | docs：上游 v4.5.16 更新日志 | 不适用 | 只改 `kejilion_sh_log.txt` |
| 2026-10-28 ~ 10-29 | `5728268` `af49b12` `2e64113` `492b491` `79c9fda` `b5bb5e9` `cbc5381` `f47c373` `32ff596` `20295c9` `63b02de` `0ff4bc6` `b408d60` | WAF 缓存/迁移、CF 盾安装与清理、nginx 配置升级固定版本 | 不适用 | WAF、CF 盾、nginx 均随 LDNMP 已删除 |
