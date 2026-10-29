# 第 2 步：逐个判断上游提交

初判为「可能不适用」的，扫一眼提交标题确认即可，不用读 diff。初判为「需要人工判断」的，读 diff：

```bash
git show <sha> -- kejilion.sh                     # 上游改动
git show <sha>^:kejilion.sh | sed -n '/^函数名() {/,/^}/p'   # 上游改动前的函数
sed -n '/^函数名() {/,/^}/p' nimbus.sh            # nimbus 现在的函数
git log --format='%h %s' -L '/^函数名() {/,/^}/:nimbus.sh' | grep -v '^$' | head   # nimbus 对它改过什么
```

## 文件对应关系

- 上游 `kejilion.sh` ↔ nimbus `nimbus.sh`。
- `TG-*.sh`、`Limiting_Shut_down1.sh`、`archive.key`、`LICENSE` 是同名文件。
- `cn/ en/ jp/ …` 多语言版、`tests/`、`apps/`、`*_manager.sh`、`kejilion_sh_log.txt` 在 nimbus 中都不存在。

## 结论分类

| 结论 | 含义 | 处理 |
|---|---|---|
| 不适用 | 改的是 nimbus 已删除的功能，或只改了上游版本号、日志、多语言版、测试 | 只记录 |
| 已覆盖 | nimbus 已经用别的方式修过或重写过（对比 CHANGELOG 和函数现状） | 只记录，注明对应的 nimbus 版本 |
| 可移植 | nimbus 的函数和上游改动前基本一致，补丁能原样套用或稍作调整 | 手动套用 |
| 需改写 | 问题在 nimbus 中同样存在，但代码结构不同，要按 nimbus 的写法重新实现 | 按 nimbus 约定重写 |
| 不采纳 | 适用，但和 nimbus 的取向冲突（遥测、广告、推广链接、Nimbus 已刻意删掉的行为、过度复杂） | 只记录原因 |

## 判断要点

- 只看意图，不照抄。上游是 bug 修复的话，先确认 nimbus 是否真有同样的 bug（可能已重写，或调用路径已删除）。
- 上游的新功能默认**不**移植，除非用户在 skill 参数里要求、或者明显属于 nimbus 已有的模块（系统工具、BBR、SSH、fail2ban、Docker 管理等）。
- 涉及菜单编号和文案的改动，以 nimbus 现有菜单为准，不要照搬上游的编号。
- 上游 `send_stats`、遥测、广告、kejilion 品牌链接一律不采纳。
