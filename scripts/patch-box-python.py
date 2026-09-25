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
    if "buildPython" in text:
        text = re.sub(r'buildPython\\(".*?"\\)', f'buildPython("{py}")', text)
    else:
        text = text.replace("python {", f'python {{\n            buildPython "{py}"', 1)
    p.write_text(text, encoding="utf-8")

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
        new = re.sub(r'pyquery[>=~!][^\s"\']*', 'pyquery==1.4.3', text)
        new = re.sub(r'"pyquery[>=~!][^"]*"', '"pyquery==1.4.3"', new)
        if new != text:
            p.write_text(new, encoding="utf-8")
            print("pinned pyquery in", p)
print("Box patches applied")
