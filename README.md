# libwebrtc Build Script

This contains build scripts to make libwebrtc builds for Android and iOS.

**NOTE: We do not provide any support related to building special versions, or
related to issues with your Docker installation, or with regard to bugs in the
WebRTC codebase itself. We also do not provide any support on how to integrate
the resulting build into your application.**

## Reproducible Builds

If you want to make a reproducible build on already prepared patches.

For Android:

    ./dev-android build-tools
    ./build-android.sh <revision>

For iOS:

    ./build-ios.sh <revision>

That's it. Output will be in the `./artifacts/` directory.

This guarantees the absence of a cache because it always fetches fresh code.

For Android, the builds are made in a Docker container which makes the build
more robust and leak less information about the build environment itself.

For iOS, the build is done on the local machine without any containerisation.

## Development

If you need to add new patches or update patches for a new libwebrtc revision,
then this is the guide to follow.

There are two scripts, one for Android and the other for iOS:

    ./dev-android.sh
    ./dev-ios.sh

Some commands are platform-specific.

### Build Tools Image (Android)

Most commands of `./dev-android.sh` require the tools image to be built:

    ./dev-android.sh build-tools

This will download and install necessary tools to work with the libwebrtc code
base.

### Fetch Tools (iOS)

Most commands of `./dev-ios.sh` require some tools to be available:

    ./dev-ios.sh fetch-tools

This will download necessary tools to work with the libwebrtc code base.

### Fetch libwebrtc

Fetch the libwebrtc code into the `./webrtc/` directory. This will download many
GiB and take a while.

    ./dev-<platform>.sh fetch

### Update libwebrtc

If it has been a while since you fetched the libwebrtc code, you may update the
code as such:

    ./dev-<platform>.sh update

This will work on any branch but obviously may not switch to the most recent
code revision (e.g. if on a release branch). When in detached head state, this
will automatically check out the HEAD of the main branch.

### Change libwebrtc Revision

If you want to switch to a specific revision:

    cd ./webrtc/<platform>/src
    git checkout branch-heads/<revision>
    cd -
    ./dev-<platform>.sh sync

You can find the corresponding branch head revisions for libwebrtc releases at
https://chromiumdash.appspot.com/branches

### Building

When you want to build a revision (with or without applied patches), run:

    ./dev-<platform>.sh build

Or run it for a specific target only:

    ./dev-<platform>.sh build <target>

Once the script finished, output will be in the `./artifacts/<platform>-dirty/`.

Please note that all resulting artifacts may be dirty and should not be
published. Use the explicit build scripts instead for publishing purposes.

### Apply Patches

You can apply all patches at once like so:

    ./dev-<platform>.sh patch

You can also apply individual patches:

    ./dev-<platform>.sh patch <patch-name>

Reverting patches requires undoing changes to the checked out revision:

    (cd ./webrtc/<platform>/src && git checkout . && git clean -d -f)

### Creating Patches

Create new patches on the desired libwebrtc revision by making local changes to
`./webrtc/<platform>/src/`.

Build the revision until it compiles successfully:

    ./dev-<platform>.sh build <one-target>

It's usually helpful to just start with one target. Once that builds, build all
the other targets:

    ./dev-<platform>.sh build

Finally, add the patch to the repository:

    cd ./webrtc/<platform>/src
    git add .
    git diff --cached > ../../patches/<patch-name>

### Test Patches (Android)

To test patches on Android without making a full reproducible build, make sure
that you have the [webrtc-android](https://github.com/threema-ch/webrtc-android)
repository in the parent directory. Make the following modifications to it:

    cd ../webrtc-android
    git rm -rf libs && mkdir libs && ln -s ../../webrtc-build-docker/artifacts/android-dirty/libwebrtc.jar libs/libwebrtc.jar && mkdir libs/arm64-v8a && ln -s ../../../webrtc-build-docker/artifacts/android-dirty/arm64/libjingle_peerconnection_so.so libs/arm64-v8a/libjingle_peerconnection_so.so && mkdir libs/armeabi-v7a && ln -s ../../../webrtc-build-docker/artifacts/android-dirty/arm/libjingle_peerconnection_so.so libs/armeabi-v7a/libjingle_peerconnection_so.so && mkdir libs/x86 && ln -s ../../../webrtc-build-docker/artifacts/android-dirty/x86/libjingle_peerconnection_so.so libs/x86/libjingle_peerconnection_so.so && mkdir libs/x86_64 && ln -s ../../../webrtc-build-docker/artifacts/android-dirty/x64/libjingle_peerconnection_so.so libs/x86_64/libjingle_peerconnection_so.so

Open `build.gradle` and change `webrtcVersion` and `libraryVersion` to something
absurdly high, e.g. `1337.0.0`. Comment the `signing` section.

Now, apply all desired patches at once and make a test build for Android
(assuming an ARM64 device here):

    cd ../../../
    ./dev-android.sh patch
    ./dev-android.sh build arm64
    (cd ../webrtc-android && ./gradlew publishToMavenLocal)

Apply the resulting library to the Android codebase in the following hacky way:

- Open `build.gradle.kts` and add `mavenLocal()` to `allprojects.repositories`.
- Open `gradle/libs.versions.toml` and change the `webrtcAndroid` version to
  your chosen (absurdly high) version.

### Enter Container (Android)

It is also possible to just jump into the build image shell which allows to
customise the build steps entirely:

    ./dev-android.sh enter

### Clean

If you haven't updated for a longer period, it might happen that the build
tools need updating or that the code needs to be fetched again. To clean and
start from scratch, run:

    ./dev-<platform>.sh clean

## Updating the libwebrtc Revision

### Revision Selection

When updating to another libwebrtc revision, select the most recent stable
release on https://chromiumdash.appspot.com/branches and pick the most recent
libwebrtc revision.

Once a revision has been selected, run:

    rm -rf ./artifacts/<platform>-dirty
    ./dev-<platform>.sh update
    cd ./webrtc/<platform>/src/
    git checkout <revision>
    cd -
    ./dev-<platform>.sh sync
    ./dev-<platform>.sh build x64

Without any patches applied, the build should run through cleanly.

### Investigate Changes

Check for any new PSA threads and other threads indicating gotchas on
https://groups.google.com/g/discuss-webrtc since the last update.

It is helpful to additionally skim over the commits made since the last
revision. Were there any significant changes that may render a patch obsolete or
dysfunctional?

There may also be changes to the default build arguments relevant to us. Check
`./webrtc/src/tools_webrtc/android/build_aar.py` and
`./webrtc/src/tools_webrtc/ios/build_ios_libs.py`.

IMPORTANT: Build arguments must be updated in all four scripts:

- `./build-android.sh`
- `./build-ios.sh`
- `./dev-android.sh`
- `./dev-android.sh`

### Updating Tools

Update `./build-tools/Dockerfile` if needed.

For Android builds, if it has been a while since the tools image was created,
run:

    ./dev-android.sh/build-tools

Similarly, for iOS builds, run:

    ./dev-ios.sh/fetch-tools

### Updating Patches

Prepare a patch branch:

    cd ./webrtc/<platform>/src/
    git switch -c threema-<revision>

Now, apply the patches **individually**, fix any conflicts/errors, update the
patch file, ensure it builds and then revert to a clean state before continuing
with the next patch:

    git apply ../../../patches/<patch>
    (cd ../../../ && ./dev-<platform>.sh format && ./dev-<platform>.sh build <one-target>)
    git add . && git diff --cached > ../../../patches/<patch>
    git reset . && git checkout . && git clean -d -f

When updating a patch and it doesn't apply cleanly or there are changes to the
surrounding code, investigate: Were there significant changes on the feature
that may defeat the purpose of the patch or leave it in a broken state? Double
check the diff of the patches, so that no accidental mistakes are introduced. Go
through it thoroughly!

Finally, apply all patches at once and ensure it builds for all targets:

    ./dev-<platform>.sh patch
    ./dev-<platform>.sh build

Commit the combined patches into the `threema-<revision>` branch within
`./webrtc/<platform>/src/`. This can be useful when comparing changes between
revisions later.

### Test Build

For each platform, test the following things:

- Ensure it builds
- Run WebRTC related tests.
- Make a 1:1 call smoke test with camera rotation.
- Make a group call smoke test with camera rotation.
- On Android, make a web client smoke test.

It can be helpful to make a test build based on the dirty build environment
before doing the full reproducible build. This saves time in case a test fails,
requiring further changes to the patches and a subsequent build.

### Build

If all looks good, commit all patches and make a reproducible build for all
platforms.
