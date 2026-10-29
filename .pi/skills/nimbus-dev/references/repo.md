# 仓库结构与关键位置

| 路径 | 说明 |
|---|---|
| `nimbus.sh` | 主脚本，约 7600 行，所有功能都在这里。用户机器上是 `~/nimbus.sh` 和 `/usr/local/bin/nb` |
| `res/config/` | 运行时从 GitHub main 下载的配置（fail2ban、tmux、blesh） |
| `TG-*.sh`、`Limiting_Shut_down1.sh` | 部署到服务器上的独立脚本 |
| `CHANGELOG.md` | 更新日志，「脚本更新」菜单会读取最后 30 行 |
| `README.md`、`docs/{wizard,features,commands,faq}.md` | 文档 |
| `.pi/upstream-sync.md` | 上游同步记录（归 `nimbus-upstream-sync` skill 管） |
| `.github/workflows/sync-cnb.yml`、`.github/scripts/cnb_build.py` | 每次 push 同步到国内镜像 cnb.cool/zidou-kiyn/nimbus：去掉 XBoard-node 相关内容，加入 `vendor/<原下载路径>`（ble.sh、xwPF、realm）。改 XBoard 函数、开荒数组或新增要给无国际出口机器用的第三方下载时，要同步修改 `cnb_build.py`，否则同步任务会报错停止 |

## nimbus.sh 里的关键位置

行号会变，用 ffgrep 搜函数名。

- 通用函数：`install` / `remove`（包管理器适配）、`break_end`、`root_use`、`nb_download`（GitHub 下载，自动走代理）、`nb_in_cn`、`nb_service_active`、`nb_is_pve`
- 菜单：主菜单在文件末尾的 `nimbus_home` 循环；`linux_tools`（基础工具）、`linux_Settings`（系统工具）
- 新机开荒：`nb_wz_status`（每一步的状态检测）、`nb_wizard`（`keys` / `titles` / `funcs` / `opts` 四个数组 + 阶段标题的编号）
- 命令行：文件末尾的 `case $1 in` 分发，帮助文本在 `nb_help`
- 自更新：`nb_self_update`、`nimbus_update`；`sh_v="x.y.z"` 在第 4 行

## 新增新机开荒步骤

1. `keys` / `titles` / `funcs` / `opts` 四个数组在同一位置同步插入；标题固定 35 列显示宽度。
2. `nb_wz_status` 加上该步骤的状态检测。
3. 插入位置之后的阶段标题编号（`case $((i + 1))` 里的数字）顺延。
4. `docs/wizard.md` 的表格、`docs/features.md` 里「开荒 N」的引用一起改。
5. 涉及 XBoard 或第三方下载时同步改 `.github/scripts/cnb_build.py`。
6. 跑 `scripts/check.py`，它会检查四个数组长度一致。
