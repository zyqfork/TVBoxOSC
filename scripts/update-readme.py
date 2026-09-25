#!/usr/bin/env python3
"""Record a build in README.md.

Usage:
    update-readme.py <readme> <owner/repo> <branch> <commit> <time>

Updates (or appends) the row for <owner>/<repo> + <branch> in the credits table,
re-aligns every column and refreshes the "Last updated" line. Owning the format
here means the workflow no longer has to sed a markdown table, and the table
stays aligned no matter which matrix job writes last.
"""

import re
import sys

HEADER = ["Repository", "Branch", "Last built commit", "Build time"]
LINK = "https://github.com/{}"
UPDATED_RE = re.compile(r"^_Last updated: .*_$", re.M)


def split_row(line):
    return [cell.strip() for cell in line.strip().strip("|").split("|")]


def find_table(lines):
    """Return (header_index, body_start, body_end), or None when absent."""
    for i, line in enumerate(lines):
        cells = split_row(line)
        if len(cells) >= 2 and cells[0] == HEADER[0] and cells[1] == HEADER[1]:
            j = i + 1
            if j < len(lines) and set(lines[j].strip()) <= set("|-: "):
                j += 1
            start = j
            while j < len(lines) and lines[j].lstrip().startswith("|"):
                j += 1
            return i, start, j
    return None


def render(rows):
    all_rows = [HEADER] + rows
    widths = [max(len(row[c]) for row in all_rows) for c in range(len(HEADER))]
    out = []
    for index, row in enumerate(all_rows):
        out.append("| " + " | ".join(row[c].ljust(widths[c]) for c in range(len(HEADER))) + " |")
        if index == 0:
            out.append("| " + " | ".join("-" * widths[c] for c in range(len(HEADER))) + " |")
    return out


def main():
    if len(sys.argv) != 6:
        print(__doc__, file=sys.stderr)
        return 2

    readme, target, branch, commit, timestamp = sys.argv[1:]

    with open(readme, encoding="utf-8") as handle:
        lines = handle.read().split("\n")

    found = find_table(lines)
    if found is None:
        print(f"{readme}: credits table not found", file=sys.stderr)
        return 1
    header_index, body_start, body_end = found

    rows = [row for row in (split_row(l) for l in lines[body_start:body_end]) if len(row) == len(HEADER)]

    url = LINK.format(target)
    new_row = [f"[{target}]({url})", f"`{branch}`", f"`{commit}`", timestamp]

    for index, row in enumerate(rows):
        if url in row[0] and row[1].strip("`") == branch:
            rows[index] = new_row
            break
    else:
        rows.append(new_row)

    lines[header_index:body_end] = render(rows)

    text = "\n".join(lines)
    updated = f"_Last updated: {timestamp}_"
    if UPDATED_RE.search(text):
        text = UPDATED_RE.sub(updated, text)
    else:
        text = text.rstrip("\n") + "\n\n" + updated + "\n"

    if not text.endswith("\n"):
        text += "\n"

    with open(readme, "w", encoding="utf-8", newline="\n") as handle:
        handle.write(text)

    print(f"{readme}: {target} {branch} -> {commit[:7]} @ {timestamp}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
