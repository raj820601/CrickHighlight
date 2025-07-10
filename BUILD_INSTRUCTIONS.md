# 🏏 Cricket Highlights APK Build Instructions

## 🚀 Automatic APK Building with GitHub Actions

Your repository is now set up to automatically build APK files using GitHub Actions!

### 📋 How to Get Your APK

#### Method 1: Automatic Build (Recommended)
1. **Push code to main branch** - APK builds automatically
2. **Go to Actions tab** in your GitHub repository
3. **Click on latest workflow run**
4. **Download APK** from the "Artifacts" section
5. **Install on Android device**

#### Method 2: Manual Trigger
1. **Go to Actions tab** in your repository
2. **Click "Build Cricket Highlights APK"**
3. **Click "Run workflow"**
4. **Choose build type** (release/debug)
5. **Click "Run workflow" button**
6. **Wait for build to complete**
7. **Download APK** from artifacts

#### Method 3: Release Download
1. **Go to Releases section** of your repository
2. **Download latest release APK**
3. **Install directly on device**

### 📱 APK Installation Guide

#### Prerequisites
- Android 7.0 (API level 24) or higher
- 3GB+ RAM recommended
- 2GB+ free storage space

#### Installation Steps
1. **Download APK** from GitHub
2. **Enable Unknown Sources**:
   - Go to Settings > Security
   - Enable "Install from Unknown Sources"
   - Or go to Settings > Apps > Special Access > Install Unknown Apps
3. **Install APK**:
   - Tap the downloaded APK file
   - Follow installation prompts
   - Grant required permissions
4. **Launch App**:
   - Find "Cricket Highlights" in app drawer
   - Grant storage and camera permissions
   - Start using the app!

### 🔧 Build Configuration

#### Build Types
- **Release APK**: Optimized, smaller size, production-ready
- **Debug APK**: Larger size, includes debug info, for testing

#### Build Triggers
- **Push to main/master**: Automatic release build
- **Manual workflow**: Choose build type
- **Pull requests**: Test builds only

### 📊 Build Status

Check build status at: `https://github.com/YOUR_USERNAME/cricket-highlights-app/actions`

### 🐛 Troubleshooting

#### Build Fails
1. Check the Actions log for errors
2. Ensure all dependencies are correctly specified
3. Verify Flutter version compatibility
4. Check for syntax errors in code

#### APK Won't Install
1. Ensure Android version compatibility (7.0+)
2. Check available storage space
3. Verify "Unknown Sources" is enabled
4. Try clearing download cache

#### App Crashes
1. Check device RAM (3GB+ recommended)
2. Ensure sufficient storage space
3. Grant all required permissions
4. Try debug APK for more error info

### 📞 Support

If you encounter issues:
1. Check the build logs in GitHub Actions
2. Review the troubleshooting section
3. Create an issue in the repository
4. Include device info and error logs

### 🎯 Next Steps

After successful installation:
1. **Upload a cricket video** (MP4, MOV, or AVI)
2. **Start AI analysis** to detect highlights
3. **View detected events** and their confidence scores
4. **Generate highlight reel** from detected events
5. **Download AI models** in settings for better accuracy

Enjoy your AI-powered cricket highlights! 🏏✨
