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
| 2026-10-29 | `3e92db2` | fix：网站备份容忍备份过程中变动的文件 | 不适用 | 只改 `beifen.sh`，nimbus 没有 |
| 2026-10-29 ~ 11-02 | `6f6d844` `8a37071` `4d2e363` `07db5c6` `4856750` `108ccf2` `e527daf` `afa0330` `4682366` `777908e` `d8c41e0` `00709e1` `9951a8d` `c2993d5` | WAF：固定共享包版本（渐进封禁、Fail2Ban / CF 同步、HTTP/3、公开文件例外、KPanel 兼容等），共享包改为签名通道热更新 | 不适用 | WAF 随 LDNMP 已删除；`c2993d5` 另外只改了 README 的 WAF 说明和上游版本号 |
| 2026-10-29 | `4236dd1` | docs：站点防御维护入口 | 不适用 | 只改上游 `.codex-workflows` |
| 2026-10-29 | `606c89d` | fix：一条龙调优跳过装不上的基础工具 | 不适用 | KPanel 一条龙调优已删除；nimbus 的 `install` 逐个装包，单个失败不中断 |
| 2026-10-30 | `ed58dea` `9872766` | fix：保留 Armbian 系统源 | 可移植 | v1.2.27：系统工具 20「更新源」检测到 Armbian（`/etc/armbian-release` 或 os-release）时提示并跳过。`switch_mirror` 只有这里调用，上游的三个函数在 nimbus 里简化为一处判断 |
| 2026-10-30 ~ 11-01 | `54a337d` `496d363` `779baed` `5b8327f` `f8f7270` `19fceee` `fb67ca6` `32c9937` `d215644` | LDNMP：重复安装保留 nginx 配置、FastAdmin 站点、反代失败处理、卸载时清理缺失的 jail | 不适用 | LDNMP / KPanel 已删除 |
| 2026-10-31 | `38b9fcd` `36ad597` | fix：LinuxMirrors `[[:ascii:]]` 正则兼容 | 可移植 | v1.2.27：上游两个函数合并为 `nb_linuxmirrors`，替换 9 处 `bash <(curl …linuxmirrors.cn…)`。实测 glibc 不支持该字符类，bash 5.3（Ubuntu 26.04）下精简模式进度条刷屏报错；替换成的 `[\ -~]` 在 C / C.UTF-8 以外的语言环境不含字母，只是走 LinuxMirrors 的慢速分支 |
| 2026-11-03 | `9110407` | fix(web)：清理端口时不误杀出站连接 | 不适用 | `stop_containers_or_kill_process` 随 LDNMP 已删除，nimbus 没有按端口杀进程 |
| 2026-11-05 ~ 11-06 | `91c4902` `c589d05` `37df2ea` `68f8455` `022f294` `8561216` `0d3eed2` `ee444be` `9836a92` `cfd9f24` `0fff141` `1faee13` | KPanel 站点访问密码：结构化操作、继承策略检查、加载失败时拒绝访问、受保护站点校验后重载 | 不适用 | KPanel / LDNMP 已删除 |
