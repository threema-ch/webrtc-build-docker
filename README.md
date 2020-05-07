# WebRTC PeerConnection Build Script

This is a Dockerfile to build the WebRTC PeerConnection for Android
using the new GN based build system.

**NOTE: We do not provide any support related to building special versions, or
related to issues with your Docker installation, or with regard to bugs in the
WebRTC codebase itself. We also do not provide any support on how to integrate
the resulting build into your application.**

## Usage

First, build the base image:

    ./build-base.sh

This will download lots and lots of data from the Chromium project. On our test
system, it took about 1-1.5 hours with a resulting image being 47 GiB.

Then, start the actual build process based on the previously downloaded data:

    ./build.sh

This will take probably around 0.5-1 hour. Once the script finished, you'll get
the following output in the `out/` directory:

 - `base_java.jar`
 - `base_java.interface.jar`
 - `libjingle_peerconnection_java.jar`
 - `libjingle_peerconnection_java.interface.jar`
 - `audio_device_java.jar`
 - `audio_device_java.interface.jar`
 - `libwebrtc.jar`
 - `arm/libjingle_peerconnection_so.so`
 - `x86/libjingle_peerconnection_so.so`
 - `arm64/libjingle_peerconnection_so.so`
 - `x64/libjingle_peerconnection_so.so`
 - `revision.txt`

If you want a non-release build, or if you want to build for other platforms,
feel free to adjust the Dockerfiles.

To build a certain commit version, adjust the `build/Dockerfile` like this:

```diff
diff --git a/build/Dockerfile b/build/Dockerfile
index ed471e9..9198581 100644
--- a/build/Dockerfile
+++ b/build/Dockerfile
@@ -11,7 +11,7 @@ RUN cd /webrtc/src/third_party \
 
 # Update code
 WORKDIR /webrtc/src
-RUN git checkout master && git pull && gclient sync
+RUN git checkout master && git pull && git checkout branch-heads/3987 && gclient sync
 
 # Apply patches
 RUN mkdir /webrtc/src/patches
```

(Note: You can find the correct branch version at https://chromiumdash.appspot.com/branches)

You'll only have to update the base image from time to time, maybe every few
weeks to months. It's a big "upfront cost" but it will reduce the duration of
the actual build.

## Custom patches

You can also apply custom patches during the build process. Put a `.patch` file
inside the `build/patches/` directory, then it should be applied automatically.

The patch should be created using `git diff` inside the /webrtc/src directory
(checkout of the https://chromium.googlesource.com/external/webrtc.git repo):

    $ git diff > my-changes.patch

## Troubleshooting

### Docker: «No space left on device»

If you use Docker with the `devicemapper` storage driver, it's possible that
you get "no space left on device" errors even though there's still disk space
left. This has to do with the way the storage is managed by Docker.

To check the used storage driver, use the `docker info` command.

To solve this issue, either [increase the devicemapper pool
size](https://jpetazzo.github.io/2014/01/29/docker-device-mapper-resize/) or
switch to a file system based storage driver like `overlay2`.

## License

    The MIT License (MIT)
    Copyright (c) 2016-2020 Threema GmbH

    Permission is hereby granted, free of charge, to any person
    obtaining a copy of this software and associated documentation files
    (the "Software"), to deal in the Software without restriction,
    including without limitation the rights to use, copy, modify, merge,
    publish, distribute, sublicense, and/or sell copies of the Software,
    and to permit persons to whom the Software is furnished to do so,
    subject to the following conditions:

    The above copyright notice and this permission notice shall be
    included in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
    EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
    NONINFRINGEMENT.  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
    BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
    ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
    CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
