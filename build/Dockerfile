FROM threema/webrtc-build-base:latest

# Export env variables
ENV GYP_DEFINES="OS=android"
ENV WEBRTC_COMPILE_ARGS="symbol_level=1 enable_libaom=false"

# Update code
WORKDIR /webrtc/src
RUN git checkout master && git pull && gclient sync

# Log revision and build args
RUN git log --pretty=fuller HEAD...HEAD^ > /webrtc/revision.txt
RUN echo "WEBRTC_COMPILE_ARGS: $WEBRTC_COMPILE_ARGS" >> /webrtc/build_args.txt \
 && echo "GYP_DEFINES: $GYP_DEFINES" >> /webrtc/build_args.txt

# Apply patches
RUN mkdir /webrtc/src/patches
COPY ["patches/*.patch", "patches/.gitdir", "patches/"]
RUN /bin/bash -c 'set -euo pipefail; shopt -s nullglob; for p in patches/*.patch; do echo "Applying $p..."; git apply $p; done'
RUN /bin/bash -c 'ls -lah patches/*.patch > /webrtc/patches.txt'

# Build for ARM
RUN gn gen out/arm --args="is_debug=false target_os=\"android\" target_cpu=\"arm\" $WEBRTC_COMPILE_ARGS"
RUN gn gen out/arm64 --args="is_debug=false target_os=\"android\" target_cpu=\"arm64\" $WEBRTC_COMPILE_ARGS"
RUN /bin/bash -c "source build/android/envsetup.sh && autoninja -C out/arm webrtc"
RUN /bin/bash -c "source build/android/envsetup.sh && autoninja -C out/arm64 webrtc"

# Build for x86
RUN gn gen out/x86 --args="is_debug=false target_os=\"android\" target_cpu=\"x86\" $WEBRTC_COMPILE_ARGS"
RUN gn gen out/x64 --args="is_debug=false target_os=\"android\" target_cpu=\"x64\" $WEBRTC_COMPILE_ARGS"
RUN /bin/bash -c "source build/android/envsetup.sh && autoninja -C out/x86 webrtc"
RUN /bin/bash -c "source build/android/envsetup.sh && autoninja -C out/x64 webrtc"
