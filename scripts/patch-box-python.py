#!/usr/bin/env python3
"""Patch takagen99/Box for Chaquopy CI: buildPython path + pin pyquery."""
import re
import sys
from pathlib import Path

py = sys.argv[1] if len(sys.argv) > 1 else ""

for p in [Path("pyramid/build.gradle"), Path("chaquo/build.gradle")]:
    if not p.is_file():
        continue
    text = p.read_text(encoding="utf-8")
    # 兼容 buildPython("...") / buildPython "..." / buildPython '...'
    text, n = re.subn(
        r"""buildPython\s*\(?\s*(['"])[^'"]*\1\s*\)?""",
        f'buildPython("{py}")',
        text,
    )
    if n == 0:
        text = text.replace("python {", f'python {{\n            buildPython "{py}"', 1)
    p.write_text(text, encoding="utf-8")
    print(f"patched {p} ({n} replacements)")

for base in (Path("pyramid"), Path("chaquo")):
    if not base.is_dir():
        continue
    for p in base.rglob("*"):
        if not p.is_file() or p.suffix not in {".txt", ".gradle"}:
            continue
        try:
            text = p.read_text(encoding="utf-8")
        except Exception:
            continue
        # 覆盖 install "pyquery" / install "pyquery>=..." / "pyquery==..." 等写法
        new = re.sub(
            r"""(["'])pyquery(?:[>=~!].*?)?\1""",
            r'\1pyquery==1.4.3\1',
            text,
        )
        # 裸写（无引号）：pyquery / pyquery>=1.4 等
        new = re.sub(r'\bpyquery(?:[>=~!][^\s"\']*)?\b', 'pyquery==1.4.3', new)
        if new != text:
            p.write_text(new, encoding="utf-8")
            print("pinned pyquery in", p)
print("Box patches applied")
