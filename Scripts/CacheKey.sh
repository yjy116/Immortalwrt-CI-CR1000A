#!/bin/bash
# SPDX-License-Identifier: MIT
set -euo pipefail

# Run inside the source checkout. Only compatible host tools/toolchains are reused.
: "${GITHUB_WORKSPACE:?}" "${WRT_CONFIG:?}" "${WRT_SOURCE:?}" "${WRT_BRANCH:?}"
: "${WRT_TARGET:?}" "${WRT_SUBTARGET:?}" "${WRT_HOST_ID:?}" "${RUNNER_ARCH:?}"

git cat-file -e HEAD:tools
git cat-file -e HEAD:toolchain
git cat-file -e "HEAD:target/linux/$WRT_TARGET"

COMPAT_HASH=$({
	git ls-tree HEAD -- Makefile rules.mk config include scripts tools toolchain \
		target/linux/generic "target/linux/$WRT_TARGET" || exit 1
	for FILE in "Config/$WRT_CONFIG.txt" Config/GENERAL.txt Scripts/Settings.sh Scripts/CacheKey.sh; do
		printf '%s\n' "$FILE"
		sha256sum < "$GITHUB_WORKSPACE/$FILE" || exit 1
	done
	if [ -f "$GITHUB_WORKSPACE/Config/PRIVATE.txt" ]; then
		sha256sum < "$GITHUB_WORKSPACE/Config/PRIVATE.txt" || exit 1
	fi
	printf '%s\n' "${WRT_PACKAGE-}" "$WRT_HOST_ID" "$RUNNER_ARCH"
} | sha256sum | cut -d ' ' -f 1)

printf 'wrt-v2-%s-%s-%s-%s-%s\n' \
	"${WRT_SOURCE//\//-}" "${WRT_BRANCH//\//-}" \
	"$WRT_TARGET" "$WRT_SUBTARGET" "$COMPAT_HASH"
