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
    pkg-config \
    software-properties-common

# Add Java 8 PPA
RUN add-apt-repository -y ppa:openjdk-r/ppa \
    && apt-get update

# Install android compile dependencies
RUN apt-get install -y --no-install-recommends \
    build-essential \
    openjdk-8-jre \
    openjdk-8-jdk \
    ant \
    libc6:i386 \
    libncurses5:i386 \
    libstdc++6:i386 \
    lib32z1 \
    libbz2-1.0:i386

# Select Java 8
RUN update-alternatives --set java /usr/lib/jvm/java-8-openjdk-amd64/jre/bin/java && \
    update-alternatives --set javac /usr/lib/jvm/java-8-openjdk-amd64/bin/javac && \
    update-alternatives --set jexec /usr/lib/jvm/java-8-openjdk-amd64/jre/lib/jexec && \
    update-alternatives --set keytool /usr/lib/jvm/java-8-openjdk-amd64/jre/bin/keytool

# Get Chromium depot tools
RUN git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git /opt/depot_tools
ENV PATH /opt/depot_tools:$PATH

# Download source code
RUN mkdir webrtc && cd webrtc && fetch --nohooks webrtc_android
WORKDIR /webrtc

# Sync
RUN yes | gclient sync
