#!/bin/sh

#  Script.sh
#  QQApi
#
#  Created by youzy01 on 2021/11/5.
#  

FRAMEWORK_NAME="WXSDK"
FREAMEWORK_OUTPUT_DIR="./Framework"

ARCHIVE_PATH_IOS_DEVICE="./Build/ios_device.xcarchive"
ARCHIVE_PATH_IOS_SIMULATOR="./Build/ios_simulator.xcarchive"

function achivePlatforms {
    xcodebuild archive \
        -scheme ${FRAMEWORK_NAME} \
        -destination "generic/platform=iOS" \
        -archivePath ${ARCHIVE_PATH_IOS_DEVICE} \
        VALID_ARCHS="armv7 arm64" \
        BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
        SKIP_INSTALL=NO

    xcodebuild archive \
        -scheme ${FRAMEWORK_NAME} \
        -destination "generic/platform=iOS Simulator" \
        -archivePath ${ARCHIVE_PATH_IOS_SIMULATOR} \
        VALID_ARCHS="x86_64" \
        BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
        SKIP_INSTALL=NO
}

function makeXCFramework {
    FRAMEWORK_RELATIVE_PATH="Products/Library/Frameworks"

    xcodebuild -create-xcframework \
        -framework "${ARCHIVE_PATH_IOS_DEVICE}/${FRAMEWORK_RELATIVE_PATH}/${FRAMEWORK_NAME}.framework" \
        -framework "${ARCHIVE_PATH_IOS_SIMULATOR}/${FRAMEWORK_RELATIVE_PATH}/${FRAMEWORK_NAME}.framework" \
        -output "${FREAMEWORK_OUTPUT_DIR}/${FRAMEWORK_NAME}.xcframework"
}

echo "#####################"
echo "▸ Cleaning XCFramework output dir: ${FREAMEWORK_OUTPUT_DIR}"

rm -rf $FREAMEWORK_OUTPUT_DIR
rm -rf "./Build"

echo "▸ Archive framework: ${FRAMEWORK_NAME}"
achivePlatforms

echo "▸ Make framework: ${FRAMEWORK_NAME}.xcframework"
makeXCFramework

echo "▸ Make framework: ${FRAMEWORK_NAME}.xcframework Finish"

rm -rf "./Build"
