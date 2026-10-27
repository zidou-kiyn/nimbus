#!/usr/bin/env python3
"""Nimbus 提交前检查：语法、版本号一致性、新机开荒数组、菜单对齐。

用法: python3 .pi/skills/nimbus-dev/scripts/check.py   （在仓库任意目录执行）
退出码非 0 表示有问题。
"""
import pathlib
import re
import subprocess
import sys
import unicodedata

root = pathlib.Path(__file__).resolve().parents[4]  # 仓库根目录
problems = []


def width(s):
    return sum(2 if unicodedata.east_asian_width(c) in "WF" else 1 for c in s)


# 1. bash 语法
for sh in sorted(root.glob("*.sh")):
    r = subprocess.run(["bash", "-n", str(sh)], capture_output=True, text=True)
    if r.returncode:
        problems.append(f"bash -n {sh.name}: {r.stderr.strip()}")

src = (root / "nimbus.sh").read_text(encoding="utf-8")
readme = (root / "README.md").read_text(encoding="utf-8")
changelog = (root / "CHANGELOG.md").read_text(encoding="utf-8")

# 2. 版本号一致性
m = re.search(r'^sh_v="([0-9.]+)"', src, re.M)
sh_v = m.group(1) if m else None
badge = re.search(r"badge/version-([0-9.]+)-", readme)
banner = re.search(r"云服务器工具箱 v([0-9.]+)", readme)
logs = re.findall(r"^\d{4}-\d{2}-\d{2}\s+v([0-9.]+)", changelog, re.M)
found = {
    "nimbus.sh sh_v": sh_v,
    "README 徽章": badge.group(1) if badge else None,
    "README 菜单预览": banner.group(1) if banner else None,
    "CHANGELOG 最后一条": logs[-1] if logs else None,
}
if len(set(found.values())) != 1:
    problems.append("版本号不一致: " + ", ".join(f"{k}={v}" for k, v in found.items()))

# 3. 新机开荒数组
wz = re.search(r"^nb_wizard\(\) \{(.*?)^\}", src, re.M | re.S)
if wz:
    arrays = {}
    for name in ("keys", "titles", "funcs", "opts"):
        a = re.search(rf"local -a {name}=\((.*?)\)\n", wz.group(1))
        arrays[name] = re.findall(r'"([^"]*)"', a.group(1)) if a else []
    lens = {k: len(v) for k, v in arrays.items()}
    if len(set(lens.values())) != 1:
        problems.append(f"新机开荒数组长度不一致: {lens}")
    for t in arrays["titles"]:
        if width(t) != 35:
            problems.append(f"新机开荒标题显示宽度应为 35，实际 {width(t)}: {t!r}")
    for f in arrays["funcs"]:
        if not re.search(rf"^{re.escape(f)}\(\)", src, re.M):
            problems.append(f"新机开荒引用的函数不存在: {f}")
    status = re.search(r"^nb_wz_status\(\) \{(.*?)^\}", src, re.M | re.S)
    for k in arrays["keys"]:
        if status and not re.search(rf"^\s+{re.escape(k)}\)", status.group(1), re.M):
            problems.append(f"nb_wz_status 缺少 key 的状态检测: {k}")
else:
    problems.append("找不到 nb_wizard()")

# 4. 双列菜单对齐：同一个函数里的双列菜单，左列（编号后到下一个编号前）显示宽度应一致
pat = re.compile(r'echo -e "\$\{gl_cyan\}\d+\.\s*\$\{gl_bai\}(.*?)\$\{gl_cyan\}\d+\.')
func_pat = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*)\(\)\s*\{")
groups = {}
func = "(顶层)"
for i, line in enumerate(src.splitlines(), 1):
    fm = func_pat.match(line)
    if fm:
        func = fm.group(1)
    m = pat.search(line)
    if m:
        left = re.sub(r"\$\{gl_[a-z]+\}", "", m.group(1))
        groups.setdefault(func, []).append((i, width(left), left.rstrip()))
for func, rows in groups.items():
    widths = [w for _, w, _ in rows]
    common = max(set(widths), key=widths.count)
    for i, w, left in rows:
        if w != common:
            problems.append(f"nimbus.sh:{i}（{func}）双列菜单左列宽度 {w}，同菜单其他行为 {common}: {left!r}")

if problems:
    print("✗ 发现问题:")
    for p in problems:
        print("  -", p)
    sys.exit(1)
print(f"✓ 检查通过（v{sh_v}）")
