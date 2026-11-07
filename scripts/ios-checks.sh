#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
mode="${1:-fast}"
case "$mode" in
    fast|smoke|full) ;;
    *) echo "Usage: $0 [fast|smoke|full]" >&2; exit 2 ;;
esac

export PATH="$repo_root/.tools/bin:$repo_root/.tools/xcodegen/bin:$PATH"
for tool in swift xcrun xcodebuild xcodegen swiftlint git python3 rg; do
    command -v "$tool" >/dev/null || { echo "Missing tool: $tool" >&2; exit 1; }
done
[[ "$(swiftlint version)" == 0.65.1 ]] || { echo "SwiftLint 0.65.1 required" >&2; exit 1; }
[[ "$(xcodegen --version)" == 'Version: 2.46.0' ]] || { echo "XcodeGen 2.46.0 required" >&2; exit 1; }
[[ "$(xcrun swift-format --version)" == 6.4.4 ]] || { echo "swift-format 6.4.4 required" >&2; exit 1; }
[[ "$(xcodebuild -version | head -n 1)" == 'Xcode 27.2' ]] || { echo "Xcode 27.2 required" >&2; exit 1; }

echo "Xcode: $(xcodebuild -version | tr '\n' ' ')"
echo "SwiftLint: $(swiftlint version); XcodeGen: $(xcodegen --version)"
cd "$repo_root"
rg --files -0 ios -g '*.swift' | xargs -0 xcrun swift-format lint --strict
swiftlint lint --config .swiftlint.yml --strict --no-cache --quiet
(cd ios && swift test -j 1)
(cd ios && xcodegen generate --spec project.yml)
git diff HEAD --exit-code -- ios/Kstati.xcodeproj/project.pbxproj || {
    echo "Generated Xcode project differs from the committed project" >&2
    exit 1
}

if [[ "$mode" == fast ]]; then
    exit 0
fi

simulator_name="${KSTATI_SIMULATOR_NAME:-iPhone 17e}"
simulator_runtime="${KSTATI_SIMULATOR_RUNTIME:-iOS-27-2}"
simulator_id="$(xcrun simctl list devices available -j | python3 -c '
import json, os, sys
name = os.environ.get("KSTATI_SIMULATOR_NAME", "iPhone 17e")
runtime = os.environ.get("KSTATI_SIMULATOR_RUNTIME", "iOS-27-2")
for key, devices in json.load(sys.stdin)["devices"].items():
    if key.endswith(runtime):
        for device in devices:
            if device["name"] == name and device.get("isAvailable", True):
                print(device["udid"])
                raise SystemExit(0)
raise SystemExit(f"No available {name} on {runtime}")
')"
echo "Simulator: $simulator_name ($simulator_runtime, $simulator_id)"
destination="platform=iOS Simulator,id=$simulator_id"
xcodebuild -project ios/Kstati.xcodeproj -scheme Kstati -destination "$destination" build

result_dir="${KSTATI_RESULT_DIR:-$repo_root/.artifacts}"
mkdir -p "$result_dir"
plan="Smoke"
if [[ "$mode" == full ]]; then plan="Full"; fi
result_path="$result_dir/kstati-$plan-$(date -u +%Y%m%dT%H%M%SZ)-$$.xcresult"
echo "Result bundle: $result_path"
xcodebuild -project ios/Kstati.xcodeproj -scheme Kstati -destination "$destination" \
    -testPlan "$plan" -parallel-testing-enabled NO -resultBundlePath "$result_path" test
