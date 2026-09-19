#!/bin/sh
set -eu

swift package resolve
swift build
swift test
