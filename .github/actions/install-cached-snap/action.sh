#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: Canonical Ltd.

set -euo pipefail

SNAP_NAME="${SNAP_NAME:?SNAP_NAME not set}"
CHANNEL="${CHANNEL:?CHANNEL not set}"
CLASSIC="${CLASSIC:?CLASSIC not set}"
CACHE_DIR="${CACHE_DIR:?CACHE_DIR not set}"
COMPONENTS="${COMPONENTS:-}"

declare -a COMPONENT_NAMES=()
if [ -n "$COMPONENTS" ]; then
	IFS=',' read -r -a RAW_COMPONENTS <<<"$COMPONENTS"
	for component in "${RAW_COMPONENTS[@]}"; do
		component="${component//[[:space:]]/}"
		if [ -n "$component" ]; then
			COMPONENT_NAMES+=("$component")
		fi
	done
fi

mkdir -p "$CACHE_DIR"

find_snap_file() {
	local snap_file=""
	for snap in "$CACHE_DIR"/"${SNAP_NAME}"_*.snap; do
		if [ -f "$snap" ]; then
			snap_file="$snap"
			break
		fi
	done
	printf '%s\n' "$snap_file"
}

find_component_file() {
	local component_name="$1"
	local component_file=""
	for comp in "$CACHE_DIR"/"${SNAP_NAME}+${component_name}"_*.comp; do
		if [ -f "$comp" ]; then
			component_file="$comp"
			break
		fi
	done
	printf '%s\n' "$component_file"
}

SNAP_FILE="$(find_snap_file)"
declare -a COMPONENT_FILES=()
CACHE_MISS=0

if [ -z "$SNAP_FILE" ]; then
	CACHE_MISS=1
fi

for component_name in "${COMPONENT_NAMES[@]}"; do
	component_file="$(find_component_file "$component_name")"
	if [ -z "$component_file" ]; then
		CACHE_MISS=1
	fi
	COMPONENT_FILES+=("$component_file")
done

if [ "$CACHE_MISS" -eq 1 ]; then
	rm -f \
		"$CACHE_DIR"/"${SNAP_NAME}"_*.snap \
		"$CACHE_DIR"/"${SNAP_NAME}"_*.assert \
		"$CACHE_DIR"/"${SNAP_NAME}"+*.comp

	SNAP_DOWNLOAD_TARGET="$SNAP_NAME"
	for component_name in "${COMPONENT_NAMES[@]}"; do
		SNAP_DOWNLOAD_TARGET+="+${component_name}"
	done

	if [ -n "$CHANNEL" ]; then
		snap download --target-directory "$CACHE_DIR" --channel "$CHANNEL" "$SNAP_DOWNLOAD_TARGET"
	else
		snap download --target-directory "$CACHE_DIR" "$SNAP_DOWNLOAD_TARGET"
	fi

	SNAP_FILE="$(find_snap_file)"
	COMPONENT_FILES=()
	for component_name in "${COMPONENT_NAMES[@]}"; do
		COMPONENT_FILES+=("$(find_component_file "$component_name")")
	done
fi

if [ -z "$SNAP_FILE" ]; then
	echo "::error::Unable to locate or download snap for $SNAP_NAME"
	exit 1
fi

for idx in "${!COMPONENT_NAMES[@]}"; do
	if [ -z "${COMPONENT_FILES[$idx]}" ]; then
		echo "::error::Unable to locate or download component ${COMPONENT_NAMES[$idx]} for $SNAP_NAME"
		exit 1
	fi
done

# Acknowledge assertion if present
ASSERT_FILE="${SNAP_FILE%.snap}.assert"
if [ -f "$ASSERT_FILE" ]; then
	sudo snap ack "$ASSERT_FILE"
fi

INSTALL_ARGS=("$SNAP_FILE")
for component_file in "${COMPONENT_FILES[@]}"; do
	INSTALL_ARGS+=("$component_file")
done

if [ "$CLASSIC" = "true" ]; then
	sudo snap install --classic "${INSTALL_ARGS[@]}"
else
	sudo snap install "${INSTALL_ARGS[@]}"
fi
