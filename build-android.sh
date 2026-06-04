#!/usr/bin/env bash
set -euo pipefail

TARGETS="${WEBRTC_TARGETS:-arm arm64 x86 x64}"
BUILD_ARGS="${WEBRTC_BUILD_ARGS:-symbol_level=1 enable_libaom=false rtc_enable_protobuf=false rtc_include_dav1d_in_internal_decoder_factory=false}"

if [ $# -ne 1 ]; then
    echo "Usage: $0 <revision>"
    echo "Example: $0 branch-heads/4430"
    exit 1
fi
revision=$1

[[ -d ./artifacts/android ]] && rm -r ./artifacts/android
[[ -d ./build/android ]] && rm -rf ./build/android
mkdir -p ./artifacts/android ./build/android

docker run --rm -ti \
    -v "$(pwd)/artifacts/android:/artifacts" \
    -v "$(pwd)/build/android:/build" \
    -v "$(pwd)/patches:/patches" \
    threema/webrtc-build-tools:latest \
    /bin/bash -ci "

    set -euo pipefail
    shopt -s nullglob

    cd /build

    echo \"Fetching sources\"
    fetch webrtc_android
    cd ./src

    echo \"Syncing against ${revision}\"
    git checkout \"${revision}\"
    gclient sync

    echo \"Logging revision and build args\"
    git log --pretty=fuller HEAD...HEAD^ > /artifacts/revision.txt
    echo \"${BUILD_ARGS}\" > /artifacts/build-args.txt

    for patch in /patches/*.patch; do
        echo \"Applying patch \${patch}\"
        git apply \"\${patch}\"
    done
    (cd /patches && printf '%s\n' *.patch > /artifacts/patches.txt)

    for target in $TARGETS; do
        echo \"Building for \${target}\"

        gn gen \"./out/android/\${target}\" --args=\"target_os=\\\"android\\\" is_debug=false debuggable_apks=false is_component_build=false rtc_include_tests=false target_cpu=\\\"\${target}\\\" android_static_analysis=\\\"off\\\" use_siso=true ${BUILD_ARGS}\"
        bash -c \"source ./build/android/envsetup.sh && autoninja -C \\\"./out/android/\${target}\\\" sdk/android:libwebrtc sdk/android:libjingle_peerconnection_so\"

        mkdir -p \"/artifacts/\${target}\"
        cp \"./out/android/\${target}/libjingle_peerconnection_so.so\" \"/artifacts/\${target}/\"
        cp \"./out/android/\${target}/lib.java/sdk/android/libwebrtc.jar\" /artifacts/
    done

    echo \"Done!\"
"
