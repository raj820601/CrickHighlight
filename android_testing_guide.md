# Android Testing Guide for Cricket Highlights App

## Quick Start Options

### Option 1: APK Installation (Easiest)
1. Download the APK file
2. Enable "Install from Unknown Sources" on your Android device
3. Install the APK
4. Grant necessary permissions (Storage, Camera)

### Option 2: Flutter Development (Full Features)
1. Install Flutter SDK
2. Set up Android development environment
3. Clone project and run `flutter run`

## Required Permissions

The app requires these Android permissions:
- Storage access (for video files)
- Camera access (for video recording)
- Internet access (for model downloads)

## Testing Checklist

### Basic Functionality
- [ ] App launches successfully
- [ ] Upload video from gallery
- [ ] View uploaded videos list
- [ ] Navigate to settings screen

### AI Analysis Testing
- [ ] Start video analysis
- [ ] View analysis progress
- [ ] Complete analysis successfully
- [ ] View detected highlights

### Model Management
- [ ] Download AI models (Settings)
- [ ] Check model status
- [ ] Delete models to free space

### Video Processing
- [ ] Generate highlight reel
- [ ] Play generated highlights
- [ ] Export/share highlights

## Troubleshooting

### Common Issues:
1. **App crashes on startup**
   - Check Android version (requires Android 7.0+)
   - Ensure sufficient storage space

2. **Video upload fails**
   - Grant storage permissions
   - Check video format (MP4, MOV, AVI supported)

3. **Analysis fails**
   - Ensure AI models are downloaded
   - Check available storage space
   - Try with shorter video first

4. **Performance issues**
   - Close other apps
   - Ensure device has 3GB+ RAM
   - Use release APK instead of debug

### Device Requirements:
- Android 7.0 (API level 24) or higher
- 3GB+ RAM recommended
- 2GB+ free storage space
- ARM64 processor recommended

## Test Videos

For testing, use cricket videos with:
- Clear audio (bat hits, crowd noise)
- Visible players and celebrations
- Scoreboard visible (for OCR testing)
- Duration: 2-30 minutes (optimal)
- Format: MP4, MOV, or AVI
- Resolution: 720p or higher
