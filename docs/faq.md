# ❓ 常见问题

<details>
<summary><b>首次运行后没有 <code>nb</code> 命令？</b></summary>

需要以 root 运行，脚本会安装到 `~/nimbus.sh` 和 `/usr/local/bin/nb`。v1.1.0 之前通过 `bash <(curl …)` 运行时不会安装，更新到新版即可。

</details>

<details>
<summary><b>国内服务器下载慢或失败？</b></summary>

使用 README 中的国内命令（经 ghfast.top 代理）。直连 GitHub 失败时，脚本也会自动改用代理，并把本机切换为国内模式，之后的下载都会走代理。

</details>

<details>
<summary><b>换内核、更新系统后需要重启吗？</b></summary>

装了新内核就需要重启才会生效。新机开荒把顺序安排为「更新系统 → 换内核 → 重启」，这样只需重启一次；第 5 步会检测是否有待启用的新内核。

</details>

<details>
<summary><b>为什么 PVE 宿主机不装 XanMod？</b></summary>

PVE 的 ZFS、虚拟化等功能是和它自带的内核一起发布、测试的，换内核会失去官方支持，升级时也容易出问题。PVE 宿主机上只开启自带内核的 BBR + fq。

</details>

<details>
<summary><b>需要定时全量自动更新系统吗？</b></summary>

不建议。全量升级可能在无人值守时更新内核、重启服务，甚至卡在配置文件冲突上。推荐开启「自动安装安全更新」（只装安全补丁、不自动重启），再定期手动做完整更新。

</details>

<details>
<summary><b>修改 SSH 端口或禁用密码登录后连不上？</b></summary>

操作后先不要关闭当前会话，另开一个终端测试新端口或密钥登录。还要检查云厂商的安全组或防火墙是否放行了新端口；fail2ban 的端口会自动同步。

</details>

<details>
<summary><b>如何卸载？</b></summary>

系统工具 → `102. 卸载 Nimbus`，会删除 `nb` 命令、脚本文件和自动更新任务，不影响已安装的软件和配置。TG-bot 监控在系统工具 `26` 中单独卸载。

</details>
