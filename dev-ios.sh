#!/bin/bash
set -euo pipefail

TARGETS="${WEBRTC_TARGETS:-device:arm64 simulator:arm64}"
BUILD_ARGS="${WEBRTC_BUILD_ARGS:-symbol_level=1 enable_libaom=false rtc_enable_protobuf=false rtc_include_dav1d_in_internal_decoder_factory=false}"

PATH="$(pwd)/build/ios/depot_tools:${PATH}"
export PATH

function print_usage {
    echo "Usage: $0 <command> [<args>]"
    echo ""
    echo "  clean"
    echo "  fetch-tools"
    echo ""
    echo "  fetch [<revision>]"
    echo "  update"
    echo "  sync"
    echo "  patch [<patch-glob>]"
    echo "  format"
    echo "  build [<${TARGETS}>]"
    exit 1
}

case ${1-} in
    clean)
        echo "Removing artifacts and build files"
        [[ -d ./artifacts ]] && rm -r ./artifacts
        [[ -d ./build ]] && rm -rf ./build

        echo "Removing source files"
        [[ -d ./webrtc ]] && rm -rf ./webrtc
        ;;

    fetch-tools)
        echo "Fetching tools"
        [[ -d ./build/ios/depot_tools ]] && rm -rf ./build/ios/depot_tools
        mkdir -p ./build/ios/depot_tools
        cd ./build/ios
        git clone --depth 1 https://chromium.googlesource.com/chromium/tools/depot_tools.git
        update_depot_tools
        fetch --help > /dev/null
        gclient --help > /dev/null
        ;;

    fetch)
        if [[ -d ./webrtc/ios ]]; then
            echo "Cannot fetch, source directory \"webrtc/ios\" already exists"
            echo "Run \"$0 clean\" to start from scratch"
            exit 3;
        fi

        # Fetch sources
        mkdir -p ./webrtc/ios
        cd ./webrtc/ios

        revision="${2:-main}"
        echo "Fetching sources"
        fetch webrtc_ios

        echo "Syncing against ${revision}"
        (cd ./src && git checkout "${revision}")
        gclient sync -D
        ;;

    update)
        if [[ ! -d ./webrtc/ios ]]; then
            echo "Cannot update, source directory \"webrtc/ios\" does not exist"
            echo "Did you forget to run \"$0 fetch\"?"
            exit 4;
        fi

        # Stash existing patches/uncommitted changes
        (cd ./webrtc/ios/src && git stash push -u)

        # Update sources
        cd ./webrtc/ios

        echo "Updating source files and tracking branches"
        echo "Note: This will leave all untracked branches untouched!"
        (cd ./src && git rebase-update)
        gclient sync -D
        echo "Done. Any patches and uncommited changes to libwebrtc need to be reapplied."
        ;;

    sync)
        if [[ ! -d ./webrtc/ios ]]; then
            echo "Cannot update, source directory \"webrtc/ios\" does not exist"
            echo "Did you forget to run \"$0 fetch\"?"
            exit 4;
        fi

        # Sync sources
        cd ./webrtc/ios
        echo "Syncing third party repos and running pre-compile hooks"
        gclient sync -D
        ;;

    patch)
        if [[ ! -d ./webrtc/ios ]]; then
            echo "Cannot patch, source directory \"webrtc/ios\" does not exist"
            echo "Did you forget to run \"$0 fetch\"?"
            exit 4;
        fi

        # Stash existing patches/uncommitted changes
        (cd ./webrtc/ios/src && git stash push -u)

        # Apply patches
        pattern=${2-*.patch}
        cd ./webrtc/ios/src
        shopt -s nullglob
        patch_count=0
        for patch in ../../../patches/${pattern}; do
            echo "Applying patch ${patch}"
            git apply "${patch}"
            patch_count=$((patch_count+1))
        done
        echo "Applied ${patch_count} patches"
        ;;

    format)
        if [[ ! -d ./webrtc/ios ]]; then
            echo "Cannot format, source directory \"webrtc/ios\" does not exist"
            echo "Did you forget to run \"$0 fetch\"?"
            exit 4;
        fi

        # Format
        cd ./webrtc/ios/src
        git cl format
        ;;

    build)
        if [[ ! -d ./webrtc/ios ]]; then
            echo "Cannot build, source directory \"webrtc/ios\" does not exist"
            echo "Did you forget to run \"$0 fetch\"?"
            exit 4;
        fi

        [[ -d ./artifacts/ios-dirty ]] && rm -r ./artifacts/ios-dirty

        # Log revision, status and build args
        echo "Logging revision, status and build args"
        mkdir -p ./artifacts/ios-dirty
        (
            cd ./webrtc/ios/src
            git log --pretty=fuller HEAD...HEAD^ > ../../../artifacts/ios-dirty/revision.txt
            echo "" >> ../../../artifacts/ios-dirty/revision.txt
            git status --short >> ../../../artifacts/ios-dirty/revision.txt
        )
        echo "${BUILD_ARGS}" > ./artifacts/ios-dirty/build-args.txt

        # Build all targets
        cd ./webrtc/ios/src
        if [ -n "${2-}" ]; then
            targets=("${@:2}")
        else
            IFS=' ' read -r -a targets <<< "${TARGETS}"
        fi
        echo "Building for ${targets[*]}"
        tools_webrtc/ios/build_ios_libs.py \
            --arch "${targets[@]}" \
            --output-dir ./out/ios/ \
            --extra-gn-args "${BUILD_ARGS}"
        mv ./out/ios/WebRTC.xcframework ../../../artifacts/ios-dirty/
        ;;

    *)
        print_usage "$0"
esac
