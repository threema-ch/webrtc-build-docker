#!/bin/bash
set -euo pipefail

TARGETS="${WEBRTC_TARGETS:-arm arm64 x86 x64}"
BUILD_ARGS="${WEBRTC_BUILD_ARGS:-symbol_level=1 enable_libaom=false rtc_enable_protobuf=false rtc_include_dav1d_in_internal_decoder_factory=false}"

function print_usage {
    echo "Usage: $0 <command> [<args>]"
    echo ""
    echo "  clean"
    echo "  build-tools"
    echo ""
    echo "  fetch [<revision>]"
    echo "  update"
    echo "  sync"
    echo "  patch [<patch-glob>]"
    echo "  format"
    echo "  build [<${TARGETS}>]"
    echo "  enter"
    exit 1
}

function require_tools_image {
    docker image inspect threema/webrtc-build-tools &>/dev/null || (
        echo "Build tools image must be built first: \"$0 build-tools\""
        exit 2
    )
}

case ${1-} in
    clean)
        echo "Removing artifacts and build files"
        [[ -d ./artifacts ]] && rm -r ./artifacts
        [[ -d ./build ]] && rm -rf ./build

        echo "Removing source files"
        [[ -d ./webrtc ]] && rm -rf ./webrtc

        echo "Removing tools image"
        docker rmi --force threema/webrtc-build-tools:latest || true
        ;;

    build-tools)
        echo "Building tools image"
        docker build --build-arg UID="$(id -u)" --build-arg GID="$(id -g)" --pull --no-cache -t \
            threema/webrtc-build-tools:latest build-tools/
        ;;

    fetch)
        require_tools_image
        if [[ -d ./webrtc/android ]]; then
            echo "Cannot fetch, source directory \"webrtc/android\" already exists"
            echo "Run \"$0 clean\" to start from scratch"
            exit 3;
        fi

        # Fetch sources
        mkdir -p ./webrtc/android
        revision="${2:-main}"
        docker run --rm -ti -v "$(pwd)/webrtc/android:/webrtc" threema/webrtc-build-tools:latest bash -c "
            set -euo pipefail

            echo \"Fetching sources\"
            fetch webrtc_android

            echo \"Syncing against ${revision}\"
            (cd ./src && git checkout \"${revision}\")
            gclient sync -D
        "
        ;;

    update)
        require_tools_image
        if [[ ! -d ./webrtc/android ]]; then
            echo "Cannot update, source directory \"webrtc/android\" does not exist"
            echo "Did you forget to run \"$0 fetch\"?"
            exit 4;
        fi

        # Stash existing patches/uncommitted changes
        (cd ./webrtc/android/src && git stash push -u)

        # Update sources
        docker run --rm -ti -v "$(pwd)/webrtc/android:/webrtc" threema/webrtc-build-tools:latest bash -c "
            set -euo pipefail

            echo \"Updating source files and tracking branches\"
            echo \"Note: This will leave all untracked branches untouched!\"
            (cd ./src && git rebase-update)
            gclient sync -D
            echo \"Done. Any patches and uncommited changes to libwebrtc need to be reapplied.\"
        "
        ;;

    sync)
        require_tools_image
        if [[ ! -d ./webrtc/android ]]; then
            echo "Cannot update, source directory \"webrtc/android\" does not exist"
            echo "Did you forget to run \"$0 fetch\"?"
            exit 4;
        fi

        # Sync sources
        docker run --rm -ti -v "$(pwd)/webrtc/android:/webrtc" threema/webrtc-build-tools:latest bash -c "
            set -euo pipefail

            echo \"Syncing third party repos and running pre-compile hooks\"
            gclient sync -D
        "
        ;;

    patch)
        if [[ ! -d ./webrtc/android ]]; then
            echo "Cannot patch, source directory \"webrtc/android\" does not exist"
            echo "Did you forget to run \"$0 fetch\"?"
            exit 4;
        fi

        # Stash existing patches/uncommitted changes
        (cd ./webrtc/android/src && git stash push -u)

        # Apply patches
        pattern=${2-*.patch}
        cd ./webrtc/android/src
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
        require_tools_image
        if [[ ! -d ./webrtc/android ]]; then
            echo "Cannot format, source directory \"webrtc/android\" does not exist"
            echo "Did you forget to run \"$0 fetch\"?"
            exit 4;
        fi

        # Format
        docker run --rm -ti -v "$(pwd)/webrtc/android:/webrtc" threema/webrtc-build-tools:latest bash -c "
            set -euo pipefail

            cd ./src
            git cl format
        "
        ;;

    build)
        require_tools_image
        if [[ ! -d ./webrtc/android ]]; then
            echo "Cannot build, source directory \"webrtc/android\" does not exist"
            echo "Did you forget to run \"$0 fetch\"?"
            exit 4;
        fi

        # Log revision, status and build args
        echo "Logging revision, status and build args"
        mkdir -p ./artifacts/android-dirty
        (
            cd ./webrtc/android/src
            git log --pretty=fuller HEAD...HEAD^ > ../../../artifacts/android-dirty/revision.txt
            echo "" >> ../../../artifacts/android-dirty/revision.txt
            git status --short >> ../../../artifacts/android-dirty/revision.txt
        )
        echo "${BUILD_ARGS}" > ./artifacts/android-dirty/build-args.txt

        # Build each target and copy artifacts
        if [ -n "${2-}" ]; then
            targets=("${@:2}")
        else
            IFS=' ' read -r -a targets <<< "${TARGETS}"
        fi
        for target in "${targets[@]}"; do
            echo "Building for ${target}"

            docker run --rm -ti -v "$(pwd)/webrtc/android:/webrtc" threema/webrtc-build-tools:latest bash -ci "
                set -euo pipefail

                cd ./src
                gn gen \"./out/android/${target}\" --args=\"cc_wrapper=\\\"ccache\\\" target_os=\\\"android\\\" debuggable_apks=false is_component_build=false rtc_include_tests=false target_cpu=\\\"${target}\\\" android_static_analysis=\\\"off\\\" use_siso=true ${BUILD_ARGS}\"
                source ./build/android/envsetup.sh
                autoninja -C \"./out/android/${target}\" sdk/android:libwebrtc sdk/android:libjingle_peerconnection_so
            "

            mkdir -p "./artifacts/android-dirty/${target}/"
            cp "./webrtc/android/src/out/android/${target}/libjingle_peerconnection_so.so" "./artifacts/android-dirty/${target}/"
            cp "./webrtc/android/src/out/android/${target}/lib.java/sdk/android/libwebrtc.jar" ./artifacts/android-dirty/
        done
        ;;

    enter)
        require_tools_image

        # Enter an interactive shell
        docker run --rm -ti -v "$(pwd)/webrtc/android:/webrtc" -v "$(pwd)/patches:/patches" threema/webrtc-build-tools:latest
        ;;

    *)
        print_usage "$0"
esac
