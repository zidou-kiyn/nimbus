# 编码约定

- bash，缩进用 **Tab**；新函数用 `nb_` 前缀，局部变量一律 `local`。
- 颜色变量：`gl_lv` 成功、`gl_huang` 提示/警告、`gl_hong` 错误、`gl_hui` 次要说明、`gl_cyan` 编号、`gl_bai` 复位。
- 子菜单写法参考 `tmux_setup`、`blesh_setup`、`komari_agent_menu`：`clear` → 标题 → `------` 分隔线 → 当前状态 → 选项 → `read -r -e -p "请输入你的选择: "`。
- 双列菜单的左列要**按显示宽度**补齐（中文算 2 列），和同一菜单的其他行一致，一般是 35 列；新机开荒的标题固定 35 列。`scripts/check.py` 会检查。
- **GitHub 下载一律用 `nb_download <不带 https:// 的路径> <目标文件>`**：国内 / IPv6 模式先走 `gh_proxy`，失败了依次试直连、ghfast 镜像，最后是国内镜像 cnb.cool（本仓库文件按原路径，第三方文件在 `vendor/<原路径>`）。不要直接 `curl github.com`。
- 多发行版：Debian / Ubuntu / RHEL 系 / Alpine。包名不一样的要分开处理（例如 `xz-utils` 和 `xz`）。注意 `install` 在 dnf/yum 上会先做全量 `update`，非必要不调用。
- 改系统配置之前先备份（`*.bak.$(date +%Y%m%d-%H%M%S)`），并且要幂等，重复执行结果相同。写入用户文件的内容用 `# >>> nimbus xxx >>>` / `# <<< nimbus xxx <<<` 标记块包起来，方便检测和移除。
- 涉及 SSH、防火墙、fail2ban 这类可能把人锁在外面的操作：先放行、再修改、最后校验，失败了要还原，并提示「保持当前会话」。
- 依赖 `res/` 下文件的功能要 **push 到 main 之后才能在服务器上用**（脚本运行时从 GitHub 下载）。
- 不加遥测、广告和外部宣传链接。
- 新功能想清楚放在哪些入口：子菜单、系统工具编号、新机开荒步骤、`nb <命令>`（`case $1 in` + `nb_help`）。每个入口都要接上。
