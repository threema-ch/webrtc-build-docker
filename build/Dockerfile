FROM threema/webrtc-build-base:latest

# Export env variables
ENV GYP_DEFINES="OS=android"

# Ugly workarounds for "You have unstashed changes" problem
RUN cd /webrtc/src/third_party \
        && git config user.email "docker@example.com" \
        && git config user.name "docker" \
        && git commit WebKit/Source/web/tests/data/mhtml/simple_test.mht -m 'ugly hack'

# Update code
WORKDIR /webrtc/src
RUN git checkout master && git pull && gclient sync

# Apply patches
RUN mkdir /webrtc/src/patches
COPY ["patches/*.patch", "patches/.gitdir", "patches/"]
RUN /bin/bash -c 'shopt -s nullglob && for p in patches/*.patch; do echo "Applying $p..."; git apply $p; done'

# Generate Ninja project files
RUN gn gen out/arm --args='is_debug=false target_os="android" target_cpu="arm" symbol_level=1'
RUN gn gen out/x86 --args='is_debug=false target_os="android" target_cpu="x86" symbol_level=1'

# Build for ARM
RUN /bin/bash -c 'source build/android/envsetup.sh && ninja -C out/arm'

# Build for x86
RUN /bin/bash -c 'source build/android/envsetup.sh && ninja -C out/x86'
