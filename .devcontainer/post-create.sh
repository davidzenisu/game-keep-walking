#!/bin/bash
set -e

echo "Installing Flutter dependencies..."
flutter pub get

echo "Installing Fastlane..."
sudo gem install fastlane -NV

echo "Setting up Android SDK..."
echo "Android SDK is already available in the container at ${ANDROID_HOME}"

echo "Setup complete! You can now:"
echo "  - Run: flutter run"
echo "  - Test: flutter test"
echo "  - Build: flutter build apk"
echo "  - Deploy: cd android && fastlane deploy"
