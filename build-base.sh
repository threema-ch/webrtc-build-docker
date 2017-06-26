#!/bin/bash
set -e
docker build --pull --no-cache -t threema/webrtc-build-base:latest base/
