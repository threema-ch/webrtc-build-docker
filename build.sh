#!/bin/bash
set -e
docker build --no-cache -t threema/webrtc-build:latest build/
CONTAINER=$(docker create threema/webrtc-build:latest)
mkdir -p out/arm out/x86

docker cp $CONTAINER:/webrtc/src/out/arm/libjingle_peerconnection_so.so out/arm/
docker cp $CONTAINER:/webrtc/src/out/x86/libjingle_peerconnection_so.so out/x86/
docker cp $CONTAINER:/webrtc/src/out/arm/lib.java/webrtc/rtc_base/base_java.jar out/
docker cp $CONTAINER:/webrtc/src/out/arm/lib.java/webrtc/rtc_base/base_java.interface.jar out/
docker cp $CONTAINER:/webrtc/src/out/arm/lib.java/webrtc/sdk/android/libjingle_peerconnection_java.jar out/
docker cp $CONTAINER:/webrtc/src/out/arm/lib.java/webrtc/sdk/android/libjingle_peerconnection_java.interface.jar out/
docker cp $CONTAINER:/webrtc/src/out/arm/lib.java/webrtc/sdk/android/libwebrtc.jar out/
docker cp $CONTAINER:/webrtc/src/out/arm/lib.java/webrtc/modules/audio_device/audio_device_java.jar out/
docker cp $CONTAINER:/webrtc/src/out/arm/lib.java/webrtc/modules/audio_device/audio_device_java.interface.jar out/
docker rm $CONTAINER
echo "Done. You can find the generated files in the out/ directory."
