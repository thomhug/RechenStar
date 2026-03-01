#!/bin/bash
set -e
cd "$CI_PRIMARY_REPOSITORY_PATH"
echo "CURRENT_PROJECT_VERSION = $(git rev-list --count HEAD)" > BuildNumber.xcconfig
