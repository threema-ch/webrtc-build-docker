FROM threema/webrtc-build-base:latest

# Export env variables
ENV GYP_DEFINES="OS=android"

# Update code
WORKDIR /webrtc/src
RUN git checkout master && git pull && gclient sync

# Log revision
RUN git log --pretty=fuller HEAD...HEAD^ > /webrtc/revision.txt

# Apply patches
RUN mkdir /webrtc/src/patches
COPY ["patches/*.patch", "patches/.gitdir", "patches/"]
RUN /bin/bash -c 'shopt -s nullglob && for p in patches/*.patch; do echo "Applying $p..."; git apply $p; done'

# Build for ARM
RUN gn gen out/arm --args='is_debug=false target_os="android" target_cpu="arm" symbol_level=1'
RUN gn gen out/arm64 --args='is_debug=false target_os="android" target_cpu="arm64" symbol_level=1'
RUN /bin/bash -c 'source build/android/envsetup.sh && ninja -C out/arm'
RUN /bin/bash -c 'source build/android/envsetup.sh && ninja -C out/arm64'

# Build for x86
RUN gn gen out/x86 --args='is_debug=false target_os="android" target_cpu="x86" symbol_level=1'
RUN gn gen out/x64 --args='is_debug=false target_os="android" target_cpu="x64" symbol_level=1'
RUN /bin/bash -c 'source build/android/envsetup.sh && ninja -C out/x86'
RUN /bin/bash -c 'source build/android/envsetup.sh && ninja -C out/x64'
