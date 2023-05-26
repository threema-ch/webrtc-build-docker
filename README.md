# libwebrtc Build Script

This is a Dockerfile to build libwebrtc for Android using the new GN based
build system.

**NOTE: We do not provide any support related to building special versions, or
related to issues with your Docker installation, or with regard to bugs in the
WebRTC codebase itself. We also do not provide any support on how to integrate
the resulting build into your application.**

## TL;DR

For an initial local build:

    ./cli.sh build-tools
    ./cli.sh fetch
    ./cli.sh patch
    ./cli.sh build-all

For subsequent builds after an update:

    ./cli.sh update
    ./cli.sh patch
    ./cli.sh build-all

For a (somewhat) reproducible build, created from within a temporary Docker container:

    ./cli.sh build-tools
    ./build-final.sh <revision>

## Usage: cli.sh

First, build the tools image:

    ./cli.sh build-tools

This will download and install necessary tools to work with the libwebrtc code
base.

Then, fetch the libwebrtc code into the `webrtc` directory. This will download
~24 GiB and may take a while.

    ./cli.sh fetch

Optionally switch to a specific (release) branch:

    cd webrtc/src
    git checkout branch-heads/<revision>
    cd -

You can find the corresponding branch head revisions for libwebrtc releases at
https://chromiumdash.appspot.com/branches

If it has been a while since you fetched the code, you may update the code as
such:

    ./cli.sh update

This will work on any branch but obviously may not switch to the most recent
code revision (e.g. if on a release branch). When in detached head state, this
will automatically check out the HEAD of the main branch.

If you just want to sync libwebrtc source against the current commit/branch
you've checked out, run:

    ./cli.sh sync

This is particularly useful when in detached head state.

As an optional step, apply our patches:

    ./cli.sh patch

To create a build for all targets, run:

    ./cli.sh build-all

This will take probably around half an hour on a modern computer. Once the
script finished, you'll get the following output in the `out/` directory:

 - `libwebrtc.jar`
 - `arm/libjingle_peerconnection_so.so`
 - `x86/libjingle_peerconnection_so.so`
 - `arm64/libjingle_peerconnection_so.so`
 - `x64/libjingle_peerconnection_so.so`
 - `revision.txt`
 - `patches.txt` (may not exist if no patch has been applied)
 - `build_args.txt`

It is also possible to just jump into the build image shell which allows to
customise the build steps entirely:

    ./cli.sh run

If you haven't updated for a longer period, it might happen that the build
tools need updating or that the code needs to be fetched again. To clean and
start from scratch, run:

    ./cli.sh clean

## Usage: build-final.sh

To generate a (somewhat) reproducible build, without any caching and with the
whole process being done from within a temporary, deterministic Docker
container:

    ./cli.sh build-tools
    ./build-final.sh <revision>

This guarantees the absence of a cache (because it always fetches fresh code),
consistent permissions and filesystem paths (so that your username and workdir
isn't included in the binary's debug info) and will ensure that you don't
forget to apply patches (because it always applies all patches at
`patches/*.patch`).


## Patches

Patches should be created using `git diff` inside the webrtc/src directory and
stored in the /patches directory to be applied automatically when running
`./cli.sh patch`.

    $ git diff > ../../patches/my-changes.patch

## License

    The MIT License (MIT)
    Copyright (c) 2016-2022 Threema GmbH

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
