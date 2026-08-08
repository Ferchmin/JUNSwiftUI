#!/usr/bin/env bash
#
# Syncs the canonical JUN example documents into this repository.
#
#   ./Scripts/sync-examples.sh            # refresh the committed copies
#   ./Scripts/sync-examples.sh --check    # fail if the committed copies have drifted
#
# The JUN repository is upstream for examples. Keeping a copy here rather than a submodule
# keeps the package self-contained -- a submodule would be fetched by every SPM consumer, and
# the example app needs the files physically inside its bundle either way. The --check mode is
# what stops the copy from quietly diverging, which is how this repository previously ended up
# shipping a sample containing a trailing comma.

set -euo pipefail

JUN_REPO="${JUN_REPO:-https://github.com/ferchmin/JUN.git}"
JUN_REF="${JUN_REF:-v1.2.0}"

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
destination="$root/Example/JUNSwiftUIApp/Resources/Examples"

check_only=false
if [[ "${1:-}" == "--check" ]]; then
  check_only=true
fi

workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT

echo "Fetching $JUN_REPO at $JUN_REF"
if ! git clone --quiet --depth 1 --branch "$JUN_REF" "$JUN_REPO" "$workdir/jun" 2>/dev/null; then
  echo "  ref '$JUN_REF' not found, falling back to the default branch"
  git clone --quiet --depth 1 "$JUN_REPO" "$workdir/jun"
fi

staging="$workdir/staged"
mkdir -p "$staging"

count=0
for screen in "$workdir"/jun/examples/*/screen.json; do
  [[ -e "$screen" ]] || continue
  name="$(basename "$(dirname "$screen")")"
  cp "$screen" "$staging/$name.json"
  count=$((count + 1))
done

if [[ "$count" -eq 0 ]]; then
  echo "error: no examples found upstream" >&2
  exit 1
fi

if $check_only; then
  if diff --recursive --brief "$staging" "$destination"; then
    echo "OK: $count example(s) match $JUN_REF"
    exit 0
  fi
  echo "error: committed examples differ from $JUN_REPO@$JUN_REF" >&2
  echo "       run ./Scripts/sync-examples.sh to update them" >&2
  exit 1
fi

rm -rf "$destination"
mkdir -p "$destination"
cp "$staging"/*.json "$destination/"

echo "Synced $count example(s) from $JUN_REF into ${destination#"$root"/}"
