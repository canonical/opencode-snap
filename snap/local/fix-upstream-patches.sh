#!/bin/sh
# Replace malformed patch files in the opencode source tree with repaired
# copies from snap/local/patches. Bun 1.4.4 applies patches strictly and
# rejects these upstream files (wrong context indentation in photon-node, a
# hunk with no trailing context in @ai-sdk/google). A repaired copy is only
# installed while the upstream file still has the known-broken hash, so a
# newer upstream patch is never silently overwritten.
#
# Usage: fix-upstream-patches.sh <opencode source dir>
set -eu

src_dir="$1"
fixed_dir="$(dirname "$0")/patches"

while read -r broken_sha name; do
	target="$src_dir/patches/$name"
	[ -f "$target" ] || continue
	actual_sha="$(sha256sum "$target" | cut -d ' ' -f 1)"
	if [ "$actual_sha" = "$broken_sha" ]; then
		echo "Replacing malformed upstream patch $name"
		cp "$fixed_dir/$name" "$target"
	else
		echo "Upstream patch $name changed, keeping it (drop the repaired copy if it applies)"
	fi
done <<EOF
2f276dcd71b0c6c2c6b77ce56b764e57ee323211e4ccd2c22524b28e8fc4a0f4 @silvia-odwyer%2Fphoton-node@0.3.4.patch
891e385c92e0bbda8172dc495bba7ca5c7f33a33a117e2c453354fce483dc682 @ai-sdk%2Fgoogle@3.0.73.patch
EOF
