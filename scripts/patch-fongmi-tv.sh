#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "用法: $0 <fongmi-tv-source-dir>" >&2
  exit 2
fi

source_dir="$1"

python3 - "$source_dir" <<'PYEOF'
from pathlib import Path
import sys

root = Path(sys.argv[1]).resolve()
factory = root / "app/src/main/java/com/fongmi/android/tv/player/engine/PlayerEngineFactory.java"

content = factory.read_text(encoding="utf-8")
replacements = {
    "import com.fongmi.android.tv.player.mpv.MpvPlayerEngine;\n": "",
    "            case MPV -> new MpvPlayerEngine(decode, listener);":
        "            // 公开源码不包含 MPV Media3 封装，兼容构建统一回退到 ExoPlayer。\n"
        "            case MPV -> new ExoPlayerEngine(decode, listener);",
    "        return PlayerSetting.isMpv() && MpvPlayerEngine.isAvailable();":
        "        return false;",
}

for old, new in replacements.items():
    if old not in content:
        raise SystemExit(f"PlayerEngineFactory.java 结构已变化，未找到: {old.strip()}")
    content = content.replace(old, new)

factory.write_text(content, encoding="utf-8", newline="\n")

for relative in (
    "app/src/main/java/com/fongmi/android/tv/player/mpv/MpvPlayerEngine.java",
    "app/src/main/java/com/fongmi/android/tv/player/mpv/MpvUtil.java",
):
    path = root / relative
    if not path.is_file():
        raise SystemExit(f"缺少待移除的 MPV 源文件: {relative}")
    path.unlink()
    print(f"已移除不可公开构建的 MPV 源文件: {relative}")

print("MPV 引擎已安全回退到 ExoPlayer")
PYEOF

if grep -R -n -E \
  --include='*.java' \
  "androidx\.media3\.mpvplayer|MpvPlayerEngine|MpvUtil" \
  "$source_dir/app/src"; then
  echo "错误: 仍存在不可用的 MPV Media3 引用" >&2
  exit 1
fi
