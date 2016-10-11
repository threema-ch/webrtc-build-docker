#!/bin/bash
docker build -t threema/webrtc-build:latest build/
CONTAINER=$(docker create threema/webrtc-build:latest)
mkdir -p out/arm out/x86
docker cp $CONTAINER:/webrtc/src/out/arm/libjingle_peerconnection_so.so out/arm/
docker cp $CONTAINER:/webrtc/src/out/x86/libjingle_peerconnection_so.so out/x86/
docker cp $CONTAINER:/webrtc/src/out/arm/lib.java/webrtc/api/libjingle_peerconnection_java.jar out/
docker rm $CONTAINER
echo "Done. You can find the generated files in the out/ directory."
