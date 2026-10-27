#!/usr/bin/env python3
"""列出上游 kejilion/sh 自上次审查以来的提交，并标出每个提交改动的函数在 nimbus 中是否还存在。

用法:
  python3 .pi/skills/nimbus-upstream-sync/scripts/upstream_report.py            # 报告（会先 git fetch upstream）
  python3 .pi/skills/nimbus-upstream-sync/scripts/upstream_report.py --no-fetch
  python3 .pi/skills/nimbus-upstream-sync/scripts/upstream_report.py --since <sha>

审查基线默认是 git merge-base HEAD upstream/main：每次审查完都会用 git merge -s ours 把审过的上游提交
标记为已合入（不改任何文件），所以 merge-base 就是「已审查到的位置」，GitHub 上的 behind 计数也会归零。
"""
import argparse
import pathlib
import re
import subprocess
import sys

root = pathlib.Path(__file__).resolve().parents[4]
UP = "upstream/main"
# 上游文件 → nimbus 文件；未列出且路径相同的文件按同名处理
FILE_MAP = {"kejilion.sh": "nimbus.sh"}
FUNC_RE = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*)\s*\(\)\s*\{?")
HUNK_RE = re.compile(r"^@@ -(\d+)(?:,(\d+))? \+(\d+)(?:,(\d+))? @@")


def git(*args, check=True):
    r = subprocess.run(["git", "-C", str(root), *args], capture_output=True, text=True)
    if check and r.returncode:
        sys.exit(f"git {' '.join(args)} 失败: {r.stderr.strip()}")
    return r.stdout


def func_starts(text):
    """返回 [(行号, 函数名)]，行号从 1 开始"""
    return [(i, m.group(1)) for i, line in enumerate(text.splitlines(), 1) if (m := FUNC_RE.match(line))]


def enclosing(starts, line):
    name = None
    for ln, fn in starts:
        if ln > line:
            break
        name = fn
    return name or "(顶层)"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--no-fetch", action="store_true")
    ap.add_argument("--since")
    a = ap.parse_args()

    if not a.no_fetch:
        git("fetch", "--quiet", "--no-tags", "upstream")
    since = a.since or git("merge-base", "HEAD", UP).strip()

    nimbus_src = (root / "nimbus.sh").read_text(encoding="utf-8")
    nimbus_funcs = {fn for _, fn in func_starts(nimbus_src)}
    tracked = set(git("ls-files").split())

    commits = git("rev-list", "--reverse", "--no-merges", f"{since}..{UP}").split()
    head = git("rev-parse", "--short", UP).strip()
    print(f"# 上游审查报告：{since[:7]}..{head}（{len(commits)} 个非合并提交）\n")
    if not commits:
        print("没有新的上游提交。")
        return

    for c in commits:
        meta = git("show", "-s", "--format=%h%x09%ad%x09%an%x09%s", "--date=short", c).strip().split("\t")
        files = [f for f in git("diff-tree", "--no-commit-id", "--name-only", "-r", c).split() if f]
        print(f"## {meta[0]} {meta[1]} {meta[2]}：{meta[3]}")
        missing, verdict = [], "可能不适用（改动的函数和文件 nimbus 都已删除）"
        for f in files:
            target = FILE_MAP.get(f, f)
            if target not in tracked:
                missing.append(f)
                continue
            if f != "kejilion.sh":
                print(f"- `{f}` → nimbus `{target}`（同名文件，需对比）")
                verdict = "需要人工判断"
                continue
            new = git("show", f"{c}:{f}", check=False)
            old = git("show", f"{c}^:{f}", check=False)
            ns, os_ = func_starts(new), func_starts(old)
            touched, top, fn = {}, [], None
            for line in git("diff", "-U0", f"{c}^", c, "--", f).splitlines():
                h = HUNK_RE.match(line)
                if not h:
                    if fn == "(顶层)" and line[:1] in "+-" and not line.startswith(("+++", "---")):
                        top.append(line.strip()[:80])
                    continue
                o_start, o_len, n_start, n_len = int(h.group(1)), int(h.group(2) or 1), int(h.group(3)), int(h.group(4) or 1)
                fn = enclosing(ns, n_start) if n_len else enclosing(os_, o_start)
                touched[fn] = touched.get(fn, 0) + max(o_len, n_len)
            have, gone = [], []
            for fn, n in touched.items():
                alt = fn.removeprefix("kpanel_")
                if fn == "(顶层)":
                    have.append(f"顶层代码 {n} 行")
                elif fn in nimbus_funcs:
                    have.append(f"`{fn}` {n} 行")
                elif alt != fn and alt in nimbus_funcs:
                    have.append(f"`{fn}`→`{alt}` {n} 行")
                else:
                    gone.append(fn)
            if have:
                print("- `kejilion.sh` 改动了 nimbus 仍有的部分：" + "；".join(have))
                if top:
                    print("  - 顶层改动：" + " | ".join(top[:4]) + (" …" if len(top) > 4 else ""))
                only_version = not [x for x in have if not x.startswith("顶层")] and all(re.search(r"sh_v=", t) for t in top)
                verdict = "可能不适用（只改了上游版本号）" if only_version and verdict.startswith("可能") else "需要人工判断"
            if gone:
                print(f"- `kejilion.sh` 改动了 nimbus 已删除的函数（{len(gone)} 个）：" + "、".join(f"`{g}`" for g in gone[:12]) + (" …" if len(gone) > 12 else ""))
        if missing:
            print(f"- nimbus 没有的文件（{len(missing)} 个）：" + "、".join(f"`{m}`" for m in missing[:8]) + (" …" if len(missing) > 8 else ""))
        print(f"- 初判：{verdict}\n")


if __name__ == "__main__":
    main()
