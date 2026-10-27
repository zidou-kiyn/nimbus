#!/usr/bin/env python3
"""生成 cnb.cool 国内镜像的内容（在 GitHub Actions 的工作区里原地修改，不提交回 GitHub）。

1. 去掉 XBoard-node 相关内容：cnb.cool 是需实名的国内平台，代理节点安装工具的代码可能触发平台规则；
   镜像只服务于无国际出口的机器，这类机器本来也用不上 XBoard-node。
2. 把无国际出口机器装不上的第三方文件放进 vendor/<原下载路径>，nb_download 在 GitHub 和代理都失败时从这里取。

任何一步替换没有命中、或最终检查不通过都会报错退出，避免把半成品推到镜像。
"""
import pathlib
import re
import shutil
import subprocess
import sys
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parents[2]
BANNED = re.compile(r"xboard|xray|sing-box|xbctl", re.I)


def fail(msg):
    print(f"::error::{msg}")
    sys.exit(1)


def replace_once(text, old, new, what):
    if text.count(old) != 1:
        fail(f"{what}: 期望命中 1 次，实际 {text.count(old)} 次（nimbus.sh 结构可能已变化，请更新 cnb_build.py）")
    return text.replace(old, new)


# ---------------------------------------------------------------- 去掉 XBoard
def strip_nimbus():
    p = ROOT / "nimbus.sh"
    s = p.read_text(encoding="utf-8")

    # 函数块：从它上方的分隔线注释到函数结束
    m = re.search(r"# -{70,}\n# XBoard-node[^\n]*\n# -{70,}\nxboard_node_menu\(\) \{\n.*?\n\}\n\n", s, re.S)
    if not m:
        fail("没有找到 xboard_node_menu 函数块")
    s = s[: m.start()] + s[m.end():]

    # 标记为国内镜像版：菜单标题显示「国内镜像版」
    s = replace_once(s, 'nb_edition="github"\n', 'nb_edition="cnb"\n', "版本来源 nb_edition")

    # 新机开荒：状态检测
    s = replace_once(
        s,
        '\t\txboard)\n\t\t\tif nb_service_active xboard-node; then WZ_DONE=true; WZ_TEXT="运行中"; else WZ_TEXT="未安装"; fi ;;\n',
        "", "开荒状态检测 xboard")

    # 新机开荒：四个数组的最后一项（XBoard 是最后一步，去掉后不影响其他步骤编号）
    lines = s.split("\n")
    arrays = {}
    for i, line in enumerate(lines):
        mm = re.match(r"^\tlocal -a (keys|titles|funcs|opts)=\((.*)\)$", line)
        if mm:
            arrays[mm.group(1)] = (i, re.findall(r'"[^"]*"', mm.group(2)))
    if set(arrays) != {"keys", "titles", "funcs", "opts"}:
        fail(f"开荒数组没找全: {sorted(arrays)}")
    expect_last = {"keys": '"xboard"', "funcs": '"xboard_node_menu"'}
    for name, (i, items) in arrays.items():
        if name in expect_last and items[-1] != expect_last[name]:
            fail(f"开荒数组 {name} 的最后一项不是 {expect_last[name]}: {items[-1]}")
        if name == "titles" and "XBoard" not in items[-1]:
            fail(f"开荒数组 titles 的最后一项不是 XBoard: {items[-1]}")
        lines[i] = f"\tlocal -a {name}=(" + " ".join(items[:-1]) + ")"
    counts = {n: len(re.findall(r'"[^"]*"', lines[i])) for n, (i, _) in arrays.items()}
    if len(set(counts.values())) != 1:
        fail(f"开荒数组长度不一致: {counts}")
    s = "\n".join(lines)
    p.write_text(s, encoding="utf-8")
    return counts["keys"]


def strip_docs(steps):
    # README：特性列表里的 XBoard、开荒步数
    p = ROOT / "README.md"
    s = p.read_text(encoding="utf-8")
    s = replace_once(s, "Realm 转发、XBoard-node 的安装", "Realm 转发的安装", "README 特性列表")
    s = re.sub(r"\d+ 步初始化", f"{steps} 步初始化", s)
    p.write_text(s, encoding="utf-8")

    # docs：删掉含 XBoard 的行（功能表格的一行、开荒表格的一行）
    for p in (ROOT / "docs").glob("*.md"):
        s = p.read_text(encoding="utf-8")
        p.write_text("".join(l for l in s.splitlines(True) if not BANNED.search(l)), encoding="utf-8")

    # 更新日志：整条删掉提到 XBoard 的版本
    p = ROOT / "CHANGELOG.md"
    blocks = re.split(r"(?<=------------------------\n)", p.read_text(encoding="utf-8"))
    p.write_text("".join(b for b in blocks if not BANNED.search(b)), encoding="utf-8")

    # 同步任务本身和开发用的 .pi/（含上面这些关键词，服务器也用不到）不放进镜像
    shutil.rmtree(ROOT / ".github")
    shutil.rmtree(ROOT / ".pi", ignore_errors=True)


# ---------------------------------------------------------------- 第三方文件
def fetch(path):
    """下载 https://<path> 到 vendor/<path>，返回内容"""
    url = "https://" + path
    req = urllib.request.Request(url, headers={"User-Agent": "nimbus-cnb-sync"})
    with urllib.request.urlopen(req, timeout=120) as r:
        data = r.read()
    if not data:
        fail(f"下载为空: {url}")
    dest = ROOT / "vendor" / path
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_bytes(data)
    print(f"vendor: {path} ({len(data) // 1024} KB)")
    return data


def vendor():
    # ble.sh nightly（nb_blesh_install）
    fetch("github.com/akinomyoga/ble.sh/releases/download/nightly/ble-nightly.tar.xz")

    # xwPF 脚本与模块（realm_xwpf_fetch_scripts），模块列表以入口脚本的 LIB_FILES 为准
    repo = "raw.githubusercontent.com/zywe03/realm-xwPF/main"
    entry = fetch(f"{repo}/xwPF.sh").decode()
    m = re.search(r"^LIB_FILES=\((.*)\)", entry, re.M)
    libs = m.group(1).replace('"', "").split() if m else ["core.sh", "rules.sh", "server.sh", "realm.sh", "ui.sh"]
    core = ""
    for f in libs:
        data = fetch(f"{repo}/lib/{f}").decode()
        if f == "core.sh":
            core = data

    # xwPF 适配的 realm 版本（realm_xwpf_fetch_realm）
    m = re.search(r'^REALM_VERSION="v?([0-9.]+)"', core, re.M)
    if not m:
        fail("core.sh 中没有 REALM_VERSION")
    ver = m.group(1)
    for arch in ("x86_64-unknown-linux-musl", "aarch64-unknown-linux-musl", "armv7-unknown-linux-musleabihf"):
        fetch(f"github.com/zhboner/realm/releases/download/v{ver}/realm-{arch}.tar.gz")


# ---------------------------------------------------------------- 检查
def check():
    subprocess.run(["bash", "-n", str(ROOT / "nimbus.sh")], check=True)
    out = subprocess.run(["grep", "-rIilE", BANNED.pattern, "--exclude-dir=.git", "."],
                         cwd=ROOT, capture_output=True, text=True).stdout.strip()
    if out:
        fail(f"镜像中仍有 XBoard 相关内容:\n{out}")


if __name__ == "__main__":
    steps = strip_nimbus()
    strip_docs(steps)
    vendor()
    check()
    print(f"cnb 镜像内容已生成（新机开荒 {steps} 步）")
