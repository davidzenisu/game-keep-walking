# Keep Walking

A Flutter game app with Material 3 design, optimized for Android Play Store publication via Fastlane.

## Features

- 🎮 Interactive game mechanics
- 🎨 Material 3 design system
- 📱 Android-optimized
- 🚀 Fastlane integration for Play Store deployment
- 🐳 DevContainer support for consistent development environments

## Prerequisites

- Flutter 3.10.0 or higher
- Android SDK 21+
- Java 11 or higher
- Ruby 2.7+ (for Fastlane)

## Setup

### Local Development

```bash
# Get dependencies
flutter pub get

# Run the app
flutter run
```

### Using DevContainer

1. Install [Docker](https://www.docker.com/products/docker-desktop) and [VS Code Remote Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)
2. Open the project in VS Code
3. Click "Reopen in Container" when prompted
4. Wait for the container to build and setup complete
5. Run `flutter run` in the terminal

## Building

### Debug Build

```bash
flutter build apk
```

### Release Build (APK)

```bash
flutter build apk --release
```

### Release Build (AAB for Play Store)

```bash
flutter build appbundle --release
```

## Deployment with Fastlane

### Initial Setup

1. **Create a signing keystore:**
   ```bash
   keytool -genkey -v -keystore ~/game-keep-walking.jks -keyalg RSA -keysize 2048 -validity 10000 -alias game-keep-walking
   ```

2. **Configure Fastlane:**
   - Update `android/fastlane/Appfile` with your package name and Google Play Console key
   - Download your Google Play Console API key and place it at the path specified in Appfile

3. **Set environment variables:**
   ```bash
   export KEYSTORE_PATH=~/game-keep-walking.jks
   export KEYSTORE_PASSWORD=your_keystore_password
   export KEYSTORE_KEY_ALIAS=game-keep-walking
   export KEYSTORE_KEY_PASSWORD=your_key_password
   ```

### Deploy to Play Store

```bash
cd android
fastlane deploy
```

### Build Only

```bash
cd android
fastlane build_aab  # Build AAB
fastlane build_apk  # Build APK
```

## Project Structure

```
game-keep-walking/
├── lib/
│   └── main.dart          # App entry point with Material 3 theme
├── android/
│   ├── fastlane/
│   │   ├── Fastfile      # Fastlane configuration
│   │   └── Appfile       # Google Play Console configuration
│   └── app/
│       └── build.gradle  # Android build configuration
├── .devcontainer/         # DevContainer configuration
│   ├── devcontainer.json
│   └── post-create.sh
├── .github/workflows/     # GitHub Actions CI/CD
├── pubspec.yaml          # Flutter dependencies
└── README.md
```

## Material 3 Design

The app uses Material 3 with dynamic color theming:
- Automatic light/dark mode based on system settings
- Custom color scheme based on a seed color
- Google Fonts (Roboto) for typography
- Responsive UI components

## Testing

```bash
flutter test
```

## CI/CD

GitHub Actions workflows are configured to:
- Run tests on every push and pull request
- Build release APK automatically
- Analyze code quality

## License

MIT License

## Support

For issues and questions, please open a GitHub issue.
