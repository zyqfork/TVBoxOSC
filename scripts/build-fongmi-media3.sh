#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "用法: $0 <github-workspace>" >&2
  exit 2
fi

workspace="$1"
media3_repo="${workspace}/media3-local-repo"
source_dir="${workspace}/fongmi-media"
init_script="${RUNNER_TEMP:-/tmp}/media3-init.gradle"

mkdir -p "$media3_repo"

git clone --depth=1 --branch=release-1.10.1-fongmi \
  https://github.com/FongMi/media "$source_dir"
cd "$source_dir"
chmod +x gradlew

# FongMi fork 引入了上游白名单中没有的依赖（如 smbj、brotli）。
# 将未知依赖按 JAR 处理，避免 missing_aar_type_workaround.gradle 直接报错。
python3 - <<'PYEOF'
import sys

path = "missing_aar_type_workaround.gradle"
with open(path, "r", encoding="utf-8") as file:
    content = file.read()

old = '''                        throw new IllegalStateException(
                            dependencyName + " is not on the JAR or AAR list in missing_aar_type_workaround.gradle")'''
new = '''                        // 未知依赖默认视为 JAR（FongMi fork 可能引入上游没有的依赖）
                        hasJar = true'''

if old not in content:
    print("未找到待修补的异常代码，源码可能已经变化：", file=sys.stderr)
    for number, line in enumerate(content.splitlines(), 1):
        if "is not on the JAR or AAR list" in line:
            print(f"  行 {number}: {line}", file=sys.stderr)
    sys.exit(1)

with open(path, "w", encoding="utf-8") as file:
    file.write(content.replace(old, new))

print("已修补 missing_aar_type_workaround.gradle：未知依赖默认按 JAR 处理")
PYEOF

echo "=== 验证修补结果 ==="
grep -n "hasJar = true\|is not on the JAR" missing_aar_type_workaround.gradle

# publish.gradle 通过该扩展属性判断是否启用。
printf '%s\n' 'gradle.ext.rootProjectIsAndroidXMedia3 = true' > "$init_script"

echo "可用的 publish 任务:"
./gradlew tasks --all 2>/dev/null |
  grep -i "publishReleasePublicationToMavenRepository" || true

./gradlew \
  :lib-common:publishReleasePublicationToMavenRepository \
  :lib-datasource:publishReleasePublicationToMavenRepository \
  :lib-datasource-okhttp:publishReleasePublicationToMavenRepository \
  :lib-session:publishReleasePublicationToMavenRepository \
  :lib-ui-danmaku:publishReleasePublicationToMavenRepository \
  --init-script "$init_script" \
  -PmavenRepo="$media3_repo" \
  -PreleaseVersion=1.10.1 \
  --no-daemon --parallel

echo "FongMi Media3 构建完成，发布到: $media3_repo"
echo "=== 发布的产物 ==="
ls -la "$media3_repo/androidx/media3/" ||
  {
    echo "错误: 发布目录为空" >&2
    exit 1
  }

for artifact in media3-common media3-session media3-ui-danmaku; do
  if ! find "$media3_repo/androidx/media3/$artifact" -name '*.aar' -print -quit |
    grep -q .; then
    echo "错误: 缺少 $artifact 产物" >&2
    exit 1
  fi
done
echo "所有必需产物验证通过"

if [[ -n "${GITHUB_ENV:-}" ]]; then
  echo "media3Repo=$media3_repo" >> "$GITHUB_ENV"
fi
