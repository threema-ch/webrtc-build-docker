FROM threema/webrtc-build-base:latest

# Export env variables
ENV GYP_DEFINES="OS=android"

# Update code
WORKDIR /webrtc/src
#RUN git checkout master && git pull && gclient sync
RUN git fetch && git checkout ac9f876bc06b8152ecc3a328147cdab19136361b && gclient sync

# Generate Ninja project files
RUN gn gen out/arm --args='is_debug=false target_os="android" target_cpu="arm"' \
 && gn gen out/x86 --args='is_debug=false target_os="android" target_cpu="x86"'

# Build for ARM
RUN /bin/bash -c 'source build/android/envsetup.sh && ninja -C out/arm'

# Build for x86
RUN /bin/bash -c 'source build/android/envsetup.sh && ninja -C out/x86'
