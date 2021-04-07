#!/bin/bash
set -euo pipefail
TARGETS="${WEBRTC_TARGETS:-arm arm64 x86 x64}"
BUILD_ARGS="${WEBRTC_BUILD_ARGS:-symbol_level=1 enable_libaom=false}"

function print_usage {
    echo "Usage: $0 <command> [<args>]"
    echo ""
    echo "  clean"
    echo "  build-tools"
    echo ""
    echo "  fetch [<flags>]"
    echo "  update [<flags>]"
    echo "  patch"
    echo "  build <${TARGETS}>"
    echo "  build-all"
    echo "  run"
    exit 1
}

function require_tools_image {
    docker image inspect threema/webrtc-build-tools &>/dev/null || (
        echo "Build tools image must be built first: '$0 build-tools'"
        exit 2
    )
}

function build_target {
    target=$1
    build_args=${@:2}

    docker run -it -v ${PWD}/webrtc:/webrtc threema/webrtc-build-tools:latest bash -c "
        set -euo pipefail
        cd src
        gn gen out/android-${target} --args='cc_wrapper=\"ccache\" target_os=\"android\" target_cpu=\"${target}\" ${build_args}'
        source build/android/envsetup.sh
        autoninja -C out/android-${target} webrtc
    "
}

function after_build_target {
    target=$1

    # Copy shared library
    mkdir -p out/${target}/
    cp webrtc/src/out/android-${target}/libjingle_peerconnection_so.so out/${target}/
}

function after_build_common {
    target=$1
    build_args=${@:2}

    # Copy Java library
    mkdir -p out/
    cp webrtc/src/out/android-${target}/lib.java/sdk/android/libwebrtc.jar out/

    # Log revision and build args
    mkdir -p out/
    (cd webrtc/src && git log --pretty=fuller HEAD...HEAD^ > ../../out/revision.txt)
    echo "${build_args}" > out/build_args.txt
}

case ${1-} in
    clean)
        echo "Removing built files"
        rm -r out
        echo "Removing tools image"
        docker rmi threema/webrtc-build-tools:latest || true
        echo "Removing source files"
        rm -rf webrtc
        ;;

    build-tools)
        echo "Building tools image"
        docker build --build-arg UID=$(id -u) --build-arg GID=$(id -g) \
                     --pull --no-cache -t \
                     threema/webrtc-build-tools:latest build-tools/
        ;;

    fetch)
        require_tools_image
        if [[ -d "webrtc" ]]; then
            echo "Cannot fetch, source directory 'webrtc' already exists"
            echo "Run '$0 clean' to start from scratch"
            exit 3;
        fi
        
        # Fetch sources
        mkdir webrtc
        docker run -it -v ${PWD}/webrtc:/webrtc threema/webrtc-build-tools:latest bash -c "
            set -euo pipefail
            echo 'Fetching source files'
            fetch webrtc_android
            echo 'Updating third party repos and running pre-compile hooks'
            gclient sync
        "
        ;;
    
    update)
        require_tools_image
        if [[ ! -d "webrtc" ]]; then
            echo "Cannot update, source directory 'webrtc' does not exist"
            echo "Did you forget to run an initial '$0 fetch'?"
            exit 4;
        fi
        
        # Stash existing patches/uncommitted changes
        (cd webrtc/src && git stash push -u)

        # Update sources
        docker run -it -v ${PWD}/webrtc:/webrtc threema/webrtc-build-tools:latest bash -c "
            set -euo pipefail
            echo \"Updating current branch (\$(cd src && git branch --show-current))\"
            (cd src && git rebase-update --current)
            echo 'Updating third party repos and running pre-compile hooks'
            gclient sync
            echo 'Done. Any patches and uncommited changes to libwebrtc need to be reapplied.'
        "
        ;;

    patch)
        if [[ ! -d "webrtc" ]]; then
            echo "Cannot patch, source directory 'webrtc' does not exist"
            echo "Did you forget to run an initial '$0 fetch'?"
            exit 4;
        fi
    
        # Stash existing patches/uncommitted changes
        (cd webrtc/src && git stash push -u)

        # Apply patches
        pattern=${2-*.patch}
        cd webrtc/src
        shopt -s nullglob
        for patch in ../../patches/${pattern}; do
            echo "Applying ${patch}..."
            git apply ${patch}
        done
        cd ../../

        # Log patches
        mkdir -p out/
        ls -la patches/${pattern} > out/patches.txt
        ;;

    build)
        require_tools_image
        if [[ ! -d "webrtc" ]]; then
            echo "Cannot build, source directory 'webrtc' does not exist"
            echo "Did you forget to run an initial '$0 fetch'?"
            exit 4;
        fi

        # Build target and copy files into out/
        if [ -z "${2-}" ]; then
            print_usage
        fi
        target=$2
        echo "Building ${target}"
        build_target ${target} ${BUILD_ARGS}
        after_build_target ${target}
        after_build_common ${target} ${BUILD_ARGS}
        echo "Built ${target} into out/${target}"
        ;;
    
    build-all)
        require_tools_image
        if [[ ! -d "webrtc" ]]; then
            echo "Cannot build, source directory 'webrtc' does not exist"
            echo "Did you forget to run an initial '$0 fetch'?"
            exit 4;
        fi

        # Build all targets and copy files into out/
        for target in $TARGETS; do
            echo "Building ${target}"
            build_target ${target} ${BUILD_ARGS}
            after_build_target ${target}
            echo "Built ${target} into out/${target}"
        done
        after_build_common ${target} ${BUILD_ARGS}
        ;;

    run)
        require_tools_image
        
        # Run an interactive shell
        docker run -it -v ${PWD}/webrtc:/webrtc threema/webrtc-build-tools:latest
        ;;

    *)
        print_usage $0
esac
