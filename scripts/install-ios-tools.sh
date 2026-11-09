#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tools_dir="$repo_root/.tools"
swiftlint_version=0.65.1
xcodegen_version=2.46.0
swiftlint_sha=c1e429b0599cf1b516f369a2d9ec04eaf0e436f3c12b637df8851fa52ff694d0
xcodegen_sha=4d9e34b62172d645eed6457cac13fc222569974098ef4ee9c3368bedf0196806

if [[ -x "$tools_dir/bin/swiftlint" && -x "$tools_dir/xcodegen/bin/xcodegen" ]] &&
   [[ "$("$tools_dir/bin/swiftlint" version)" == "$swiftlint_version" ]] &&
   [[ "$("$tools_dir/xcodegen/bin/xcodegen" --version)" == "Version: $xcodegen_version" ]]; then
    exit 0
fi

temporary_dir="$(mktemp -d)"
trap 'rm -rf "$temporary_dir"' EXIT
mkdir -p "$tools_dir/bin"

download_asset() {
    local url="$1" asset="$2" destination="$3"
    if curl --fail --location --silent --show-error --retry 3 "$url" -o "$destination"; then
        return 0
    fi
    if [[ -n "${GH_TOKEN:-}" ]] && command -v gh >/dev/null; then
        gh api -H 'Accept: application/octet-stream' "repos/$asset" > "$destination"
        return 0
    fi
    return 1
}

download_asset \
    "https://github.com/realm/SwiftLint/releases/download/$swiftlint_version/portable_swiftlint.zip" \
    realm/SwiftLint/releases/assets/524187565 "$temporary_dir/swiftlint.zip"
printf '%s  %s\n' "$swiftlint_sha" "$temporary_dir/swiftlint.zip" | shasum -a 256 -c -
unzip -q "$temporary_dir/swiftlint.zip" -d "$temporary_dir/swiftlint"
install -m 755 "$temporary_dir/swiftlint/swiftlint" "$tools_dir/bin/swiftlint"

download_asset \
    "https://github.com/yonaskolb/XcodeGen/releases/download/$xcodegen_version/xcodegen.zip" \
    yonaskolb/XcodeGen/releases/assets/478866069 "$temporary_dir/xcodegen.zip"
printf '%s  %s\n' "$xcodegen_sha" "$temporary_dir/xcodegen.zip" | shasum -a 256 -c -
unzip -q "$temporary_dir/xcodegen.zip" -d "$temporary_dir/xcodegen"
rm -rf "$tools_dir/xcodegen"
mv "$temporary_dir/xcodegen/xcodegen" "$tools_dir/xcodegen"
chmod +x "$tools_dir/xcodegen/bin/xcodegen"

"$tools_dir/bin/swiftlint" version
"$tools_dir/xcodegen/bin/xcodegen" --version
