#!/bin/bash

echo "🏏 Cricket Highlights App - GitHub Repository Setup"
echo "===================================================="

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}This script will help you set up your GitHub repository for automatic APK building.${NC}"
echo ""

# Get repository details
read -p "Enter your GitHub username: " USERNAME
read -p "Enter your repository name (default: cricket-highlights-app): " REPO_NAME
REPO_NAME=${REPO_NAME:-cricket-highlights-app}

echo ""
echo -e "${YELLOW}Repository URL: https://github.com/$USERNAME/$REPO_NAME${NC}"
echo ""

# Check if git is initialized
if [ ! -d ".git" ]; then
    echo "Initializing git repository..."
    git init
    git branch -M main
fi

# Add remote if not exists
if ! git remote get-url origin &> /dev/null; then
    echo "Adding remote origin..."
    git remote add origin https://github.com/$USERNAME/$REPO_NAME.git
fi

# Create .gitignore if not exists
if [ ! -f ".gitignore" ]; then
    cat > .gitignore << 'EOF'
# Miscellaneous
*.class
*.log
*.pyc
*.swp
.DS_Store
.atom/
.buildlog/
.history
.svn/
migrate_working_dir/

# IntelliJ related
*.iml
*.ipr
*.iws
.idea/

# The .vscode folder contains launch configuration and tasks you configure in
# VS Code which you may wish to be included in version control, so this line
# is commented out by default.
#.vscode/

# Flutter/Dart/Pub related
**/doc/api/
**/ios/Flutter/.last_build_id
.dart_tool/
.flutter-plugins
.flutter-plugins-dependencies
.packages
.pub-cache/
.pub/
/build/

# Symbolication related
app.*.symbols

# Obfuscation related
app.*.map.json

# Android Studio will place build artifacts here
/android/app/debug
/android/app/profile
/android/app/release

# APK output
apk_output/
EOF
fi

# Create README
cat > README.md << EOF
# 🏏 Cricket Highlights Generator

AI-powered cricket highlight detection app that works offline on Android devices.

## Features

- **AI-Powered Analysis**: Uses TensorFlow Lite models for cricket event detection
- **Offline Processing**: Works without internet connection
- **Multi-Modal Detection**: Analyzes audio, video, and scoreboard OCR
- **Automatic Highlights**: Generates highlight reels automatically
- **User-Friendly**: Simple interface for video upload and analysis

## Download

### Latest Release
Download the latest APK from the [Releases](https://github.com/$USERNAME/$REPO_NAME/releases) page.

### Automatic Builds
Every push to the main branch automatically builds a new APK available in:
- GitHub Actions artifacts
- GitHub Releases (tagged builds)

## Installation

1. Download the APK file
2. Enable "Install from unknown sources" on your Android device
3. Install the APK
4. Grant storage and camera permissions

## Requirements

- Android 7.0 (API level 24) or higher
- 3GB+ RAM recommended
- 2GB+ free storage space
- ARM64 processor recommended

## Usage

1. **Upload Video**: Select a cricket video from your device
2. **Download Models**: Go to Settings and download AI models (recommended)
3. **Analyze**: Tap "Analyze" to detect highlights
4. **Generate**: Create highlight reels from detected events

## Development

### Building APK

\`\`\`bash
# Make the build script executable
chmod +x build_apk.sh

# Run the build
./build_apk.sh
\`\`\`

### Using Docker

\`\`\`bash
# Build using Docker
docker build -t cricket-highlights-builder -f Dockerfile.apk-builder .
docker run -v \$(pwd)/output:/output cricket-highlights-builder
\`\`\`

### GitHub Actions

APKs are automatically built on every push using GitHub Actions. Check the Actions tab for build status.

## Tech Stack

- **Flutter**: Cross-platform mobile development
- **TensorFlow Lite**: On-device AI inference
- **FFmpeg**: Video processing
- **Hive**: Local database
- **Riverpod**: State management

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

This project is licensed under the MIT License.

## Support

For issues or questions, please create an issue in this repository.
EOF

echo "Setting up project files..."

# Make build script executable
chmod +x build_apk.sh

# Add all files
git add .

# Commit
git commit -m "Initial commit: Cricket Highlights App with GitHub Actions APK building"

echo ""
echo -e "${GREEN}Setup complete!${NC}"
echo ""
echo "🚀 Next steps:"
echo "1. Create the repository on GitHub: https://github.com/new"
echo "2. Push the code:"
echo "   git push -u origin main"
echo ""
echo "3. APK will be automatically built and available at:"
echo "   - Actions tab: https://github.com/$USERNAME/$REPO_NAME/actions"
echo "   - Releases: https://github.com/$USERNAME/$REPO_NAME/releases"
echo ""
echo "4. Manual build (if needed):"
echo "   ./build_apk.sh"
echo ""
echo "📱 The APK will be ready for download once the GitHub Action completes!"
