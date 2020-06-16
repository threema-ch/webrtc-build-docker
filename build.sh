#!/bin/bash
set -e
docker build --no-cache --ulimit nofile=122880:122880 -t threema/webrtc-build:latest build/
CONTAINER=$(docker create threema/webrtc-build:latest)
TARGETS='arm arm64 x86 x64'

# Copy revision and patches file
mkdir -p out/
docker cp $CONTAINER:/webrtc/revision.txt out/
docker cp $CONTAINER:/webrtc/build_args.txt out/
docker cp $CONTAINER:/webrtc/patches.txt out/

# Copy shared libraries
for target in $TARGETS; do
    mkdir -p out/$target/
    docker cp $CONTAINER:/webrtc/src/out/$target/libjingle_peerconnection_so.so out/$target/
done

# Copy Java bindings
docker cp $CONTAINER:/webrtc/src/out/arm/lib.java/sdk/android/libwebrtc.jar out/

docker rm $CONTAINER
echo "Done. You can find the generated files in the out/ directory."
