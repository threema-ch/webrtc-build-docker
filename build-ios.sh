#!/usr/bin/env bash
set -euo pipefail

TARGETS="${WEBRTC_TARGETS:-device:arm64 simulator:arm64}"
BUILD_ARGS="${WEBRTC_BUILD_ARGS:-symbol_level=1 enable_libaom=false rtc_enable_protobuf=false rtc_include_dav1d_in_internal_decoder_factory=false}"

if [ $# -ne 1 ]; then
    echo "Usage: $0 <revision>"
    echo "Example: $0 branch-heads/4430"
    exit 1
fi
revision=$1

[[ -d ./artifacts/ios ]] && rm -r ./artifacts/ios
[[ -d ./build/ios ]] && rm -rf ./build/ios
mkdir -p ./artifacts/ios ./build/ios

cd ./build/ios

echo "Fetching tools"
[[ -d ./depot_tools ]] && rm -rf ./depot_tools
git clone --depth 1 https://chromium.googlesource.com/chromium/tools/depot_tools.git
PATH="$(pwd)/depot_tools:${PATH}"
export PATH
update_depot_tools
fetch --help > /dev/null
gclient --help > /dev/null

echo "Fetching sources"
fetch webrtc_ios
cd ./src

echo "Syncing against ${revision}"
git checkout "${revision}"
gclient sync

echo "Logging revision and build args"
git log --pretty=fuller HEAD...HEAD^ > ../../../artifacts/ios/revision.txt
echo "${BUILD_ARGS}" > ../../../artifacts/ios/build-args.txt

for patch in ../../../patches/*.patch; do
    echo "Applying patch ${patch}"
    git apply "${patch}"
done
(cd ../../../patches && printf '%s\n' *.patch > ../artifacts/ios/patches.txt)

IFS=' ' read -r -a targets <<< "${TARGETS}"
echo "Building for ${targets[*]}"
tools_webrtc/ios/build_ios_libs.py \
    --arch "${targets[@]}" \
    --output-dir ./out/ios/ \
    --extra-gn-args "${BUILD_ARGS}"
mv ./out/ios/WebRTC.xcframework ../../../artifacts/ios/

echo "Done!"
