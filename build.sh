#!/bin/bash
set -e
docker build --no-cache -t threema/webrtc-build:latest build/
CONTAINER=$(docker create threema/webrtc-build:latest)
TARGETS='arm arm64 x86 x64'

# Copy revision file
mkdir -p out/
docker cp $CONTAINER:/webrtc/revision.txt out/

# Copy shared libraries
for target in $TARGETS; do
    mkdir -p out/$target/
    docker cp $CONTAINER:/webrtc/src/out/$target/libjingle_peerconnection_so.so out/$target/
done

# Copy Java bindings
docker cp $CONTAINER:/webrtc/src/out/arm/lib.java/rtc_base/base_java.jar out/
docker cp $CONTAINER:/webrtc/src/out/arm/lib.java/rtc_base/base_java.interface.jar out/
docker cp $CONTAINER:/webrtc/src/out/arm/lib.java/sdk/android/libjingle_peerconnection_java.jar out/
docker cp $CONTAINER:/webrtc/src/out/arm/lib.java/sdk/android/libjingle_peerconnection_java.interface.jar out/
docker cp $CONTAINER:/webrtc/src/out/arm/lib.java/sdk/android/libwebrtc.jar out/
docker cp $CONTAINER:/webrtc/src/out/arm/lib.java/modules/audio_device/audio_device_java.jar out/
docker cp $CONTAINER:/webrtc/src/out/arm/lib.java/modules/audio_device/audio_device_java.interface.jar out/

docker rm $CONTAINER
echo "Done. You can find the generated files in the out/ directory."
