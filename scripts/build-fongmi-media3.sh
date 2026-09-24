#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "usage: $0 <github-workspace>" >&2
  exit 2
fi

workspace="$1"
media3_repo="${workspace}/media3-local-repo"
source_dir="${workspace}/fongmi-media"
init_script="${RUNNER_TEMP:-/tmp}/media3-init.gradle"

mkdir -p "$media3_repo"

git clone --filter=blob:none https://github.com/FongMi/media "$source_dir"
git -C "$source_dir" checkout --detach c8a183b8ca7e57f43213c55f418d89fe45965db8
cd "$source_dir"
chmod +x gradlew

# No compatibility stubs: zyqfork/TV media3compat already provides
# PlayerSeekView / DiskPreloadManager. Injecting stubs causes R8 duplicate classes.

# Allow unknown deps to resolve as JAR (smbj/brotli etc. from FongMi fork).
python3 - <<'PYEOF'
from pathlib import Path
import sys

path = "missing_aar_type_workaround.gradle"
text = Path(path).read_text(encoding="utf-8")
old = """                        throw new IllegalStateException(
                            dependencyName + " is not on the JAR or AAR list in missing_aar_type_workaround.gradle")"""
new = """                        // Unknown dependency: treat as JAR (FongMi fork extras)
                        hasJar = true"""
if old not in text:
    print("patch target not found; source may have changed", file=sys.stderr)
    sys.exit(1)
Path(path).write_text(text.replace(old, new), encoding="utf-8")
print("patched missing_aar_type_workaround.gradle")
PYEOF

printf '%s\n' 'gradle.ext.rootProjectIsAndroidXMedia3 = true' > "$init_script"

# Publish only the fork-specific modules zyqfork/TV needs.
# lib-exoplayer etc. come from Google Maven (avoids duplicate DiskPreloadManager).
./gradlew \
  :lib-common:publishToMavenLocal \
  :lib-ui:publishToMavenLocal \
  :lib-ui-danmaku:publishToMavenLocal \
  --init-script "$init_script" \
  -PreleaseVersion=1.10.1 \
  --no-daemon --parallel

echo "FongMi Media3 built to mavenLocal"
m2="$HOME/.m2/repository"
ls -la "$m2/androidx/media3/" || { echo "publish dir empty" >&2; exit 1; }

artifacts=(media3-common media3-ui media3-ui-danmaku)
for artifact in "${artifacts[@]}"; do
  if ! find "$m2/androidx/media3/$artifact" -name '*.aar' -print -quit | grep -q .; then
    echo "missing artifact: $artifact" >&2
    exit 1
  fi
done
echo "artifacts verified"

if [[ -n "${GITHUB_ENV:-}" ]]; then
  echo "media3Repo=$media3_repo" >> "$GITHUB_ENV"
fi
