FROM ubuntu:14.04

# Update apt cache
RUN dpkg --add-architecture i386 && apt-get update

# Install base dependencies
RUN apt-get install -y --no-install-recommends \
    vim \
    git \
    curl \
    wget \
    apt-utils \
    ca-certificates \
    python \
    lbzip2 \
    pkg-config

# Install android compile dependencies
RUN apt-get install -y --no-install-recommends \
    build-essential \
    openjdk-7-jre \
    openjdk-7-jdk \
    ant \
    libc6:i386 \
    libncurses5:i386 \
    libstdc++6:i386 \
    lib32z1 \
    libbz2-1.0:i386

# Get Chromium depot tools
RUN git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git /opt/depot_tools
ENV PATH /opt/depot_tools:$PATH

# Download source code
RUN mkdir webrtc && cd webrtc && fetch --nohooks webrtc_android
WORKDIR /webrtc

# Ugly workarounds for "You have unstashed changes" problem
RUN cd src/third_party \
        && git config user.email "docker@example.com" \
        && git config user.name "docker" \
        && git commit WebKit/Source/web/tests/data/mhtml/simple_test.mht -m 'ugly hack'

# Sync
RUN yes | gclient sync
