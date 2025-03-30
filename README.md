# YouTube Downloader

A Flutter desktop application for downloading YouTube videos with a modern and user-friendly interface.

## Features

- Download YouTube videos in various formats and qualities
- Support for multiple downloads simultaneously
- Progress tracking and notifications
- Cross-platform support (macOS, Windows, Linux)
- Modern and intuitive user interface

## Prerequisites

Before you begin, ensure you have the following installed:
- [Flutter](https://flutter.dev/docs/get-started/install) (version 3.19.0 or higher)
- [Python](https://www.python.org/downloads/) (for the backend functionality)
- [Git](https://git-scm.com/downloads)

### Platform-specific Requirements

#### macOS
- Xcode (latest version)
- CocoaPods (`sudo gem install cocoapods`)
- create-dmg (`brew install create-dmg`) - for creating release builds

#### Windows
- Visual Studio (with Desktop development with C++)
- Windows 10 SDK

#### Linux
- Required packages:
  ```bash
  sudo apt-get update
  sudo apt-get install clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev
  ```

## Getting Started

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/youtube-downloader.git
   cd youtube-downloader
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app in debug mode:
   ```bash
   flutter run
   ```

## Building Release Versions

### macOS

1. Build the release version:
   ```bash
   ./scripts/build_macos.sh
   ```
   This will:
   - Clean previous builds
   - Get dependencies
   - Build the release version
   - Create a DMG installer

The DMG file will be available at: `build/macos/Build/Products/Release/YouTube Downloader.dmg`

### Windows

1. Build the release version:
   ```bash
   flutter build windows --release
   ```

The executable will be available in `build/windows/runner/Release/`

### Linux

1. Build the release version:
   ```bash
   flutter build linux --release
   ```

The executable will be available in `build/linux/x64/release/bundle/`

## Development

### Project Structure

```
youtube-downloader/
├── lib/               # Flutter application code
├── macos/             # macOS specific configuration
├── windows/           # Windows specific configuration
├── linux/            # Linux specific configuration
├── assets/           # Application assets
├── python_app/       # Python backend code
└── scripts/          # Build and utility scripts
```

### Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## CI/CD

The project uses GitHub Actions for continuous integration and deployment:

- Automated builds for macOS releases
- Release creation on tag push
- Artifact uploading to GitHub releases

To create a new release:
1. Tag your release:
   ```bash
   git tag v1.x.x
   git push origin v1.x.x
   ```
2. The GitHub Actions workflow will automatically:
   - Build the release
   - Create installers
   - Upload artifacts
   - Create a GitHub release

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Flutter team for the amazing framework
- All contributors who have helped with the project
