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

    git diff > ../../patches/my-changes.patch

## Updating the libwebrtc revision

When updating to another libwebrtc revision, select the most recent stable
release on https://chromiumdash.appspot.com/branches and pick the most recent
libwebrtc revision.

Check for any new PSA threads and other threads indicating gotchas on
https://groups.google.com/g/discuss-webrtc since the last update.

Update `build-tools/Dockerfile` if needed.

Run the following commands:

    rm -r ./out
    ./cli.sh update
    cd ./webrtc/src/
    git checkout <revision>
    cd ../../
    ./cli.sh sync
    WEBRTC_TARGETS="x64" ./cli.sh build-all
    cd ./webrtc/src/
    git switch -c threema-<revision>

Now, apply the patches **individually**, fix any conflicts/errors, update the
patch file, ensure it builds and then revert to a clean state before continuing
with the next patch:

    git apply ../../patches/<patch>
    (cd ../../ && ./cli.sh format && WEBRTC_TARGETS="x64" ./cli.sh build-all)
    git diff > ../../patches/<patch>
    git checkout . && git clean -d -f

When updating a patch, briefly take a look at the environment: Were there
significant changes on the feature that may defeat the purpose of the patch or
leave it in a broken state? Double check the diff of the patches, so that no
accidental mistakes are introduced. Go through it thoroughly!

Make sure that you have the
[webrtc-android](https://github.com/threema-ch/webrtc-android) repository in the
parent directory. Make the following modifications to it:

    cd ../webrtc-android
    git rm -rf libs && mkdir libs && ln -s ../../webrtc-build-docker/out/libwebrtc.jar libs/libwebrtc.jar && mkdir libs/arm64-v8a && ln -s ../../../webrtc-build-docker/out/arm64/libjingle_peerconnection_so.so libs/arm64-v8a/libjingle_peerconnection_so.so && mkdir libs/armeabi-v7a && ln -s ../../../webrtc-build-docker/out/arm/libjingle_peerconnection_so.so libs/armeabi-v7a/libjingle_peerconnection_so.so && mkdir libs/x86 && ln -s ../../../webrtc-build-docker/out/x86/libjingle_peerconnection_so.so libs/x86/libjingle_peerconnection_so.so && mkdir libs/x86_64 && ln -s ../../../webrtc-build-docker/out/x64/libjingle_peerconnection_so.so libs/x86_64/libjingle_peerconnection_so.so

Open `build.gradle` and change `webrtcVersion` and `libraryVersion` to something
absurdly high, e.g. `1337.0.0`. Comment the `signing` section.

Now, apply all patches at once and make a test build for Android (assuming an
ARM device here):

    cd ../../
    ./cli.sh patch
    WEBRTC_TARGETS="arm arm64" ./cli.sh build-all
    (cd ../webrtc-android && ./gradlew publishToMavenLocal)

Apply the resulting library to the Android codebase in the following hacky way:

- Open `build.gradle.kts` and add `mavenLocal()` to `allprojects.repositories`.
- Open `gradle/libs.versions.toml` and change the `webrtcAndroid` version to
  your chosen (absurdly high) version.

Now, build the Android codebase and test the following things:

- Make a web client smoke test.
- Make a 1:1 call smoke test with camera rotation.
- Make a group call smoke test with camera rotation.
- Run the SDP test suite in Android Studio.

If all looks good, clean up the mess you made in webrtc-android and the Android
codebase and prepare a release with `./build-final.sh <revision>`.
