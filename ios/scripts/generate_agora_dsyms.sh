#!/bin/sh
set -e

# Prebuilt and native-asset frameworks often ship without dSYM bundles. App Store
# Connect expects a dSYM for each embedded framework UUID. dsymutil creates
# matching stub dSYMs (no source line info, but satisfies the upload check).

if [ -z "${DWARF_DSYM_FOLDER_PATH}" ]; then
  exit 0
fi

generate_dsym_for_framework() {
  framework_path="$1"
  framework_name=$(basename "${framework_path}" .framework)
  binary="${framework_path}/${framework_name}"

  if [ ! -f "${binary}" ]; then
    return 0
  fi

  dsym_path="${DWARF_DSYM_FOLDER_PATH}/${framework_name}.framework.dSYM"
  if [ -d "${dsym_path}" ]; then
    return 0
  fi

  echo "Generating dSYM for ${framework_name}"
  xcrun dsymutil "${binary}" -o "${dsym_path}" || true
}

embedded_frameworks_dir="${BUILT_PRODUCTS_DIR}/${FRAMEWORKS_FOLDER_PATH}"
if [ -d "${embedded_frameworks_dir}" ]; then
  find "${embedded_frameworks_dir}" -maxdepth 1 -name '*.framework' -type d | while read -r framework; do
    generate_dsym_for_framework "${framework}"
  done
fi

for agora_dir in \
  "${PODS_ROOT}/AgoraRtcEngine_Special_iOS" \
  "${PODS_ROOT}/AgoraIrisRTC_iOS"; do
  if [ ! -d "${agora_dir}" ]; then
    continue
  fi

  find "${agora_dir}" -path '*/ios-arm64*/*.framework' -type d ! -path '*simulator*' | while read -r framework; do
    generate_dsym_for_framework "${framework}"
  done
done
