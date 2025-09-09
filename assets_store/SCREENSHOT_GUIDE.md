# App Store Screenshots Guide for AAC Communication Helper

## Overview
This guide helps you capture all required screenshots for Google Play Store and Apple App Store submission.

## Required Screenshots

### Google Play Store Requirements

#### Phone Screenshots (Required)
- **Minimum:** 2 screenshots
- **Maximum:** 8 screenshots
- **Dimensions:** 16:9 or 9:16 aspect ratio
- **Min resolution:** 320px
- **Max resolution:** 3840px

#### Tablet Screenshots (Optional but Recommended)
- **Minimum:** 1 screenshot
- **Maximum:** 8 screenshots
- **Dimensions:** 16:10, 16:9, or 3:2 aspect ratio

#### Feature Graphic (Required)
- **Dimensions:** 1024 x 500 pixels
- **Format:** JPG or 24-bit PNG (no alpha)

### Apple App Store Requirements

#### iPhone Screenshots (Required)
- **6.7" Display:** 1290 x 2796 pixels or 2796 x 1290 pixels
- **6.5" Display:** 1242 x 2688 pixels or 2688 x 1242 pixels
- **5.5" Display:** 1242 x 2208 pixels or 2208 x 1242 pixels

#### iPad Screenshots (If supporting iPad)
- **12.9" Display:** 2048 x 2732 pixels or 2732 x 2048 pixels
- **11" Display:** 1668 x 2388 pixels or 2388 x 1668 pixels

## Screenshot Content Strategy

### Screenshot 1: Home Screen with Communication Grid
**Purpose:** Show the main AAC interface
**Elements to highlight:**
- Colorful communication symbols
- Clear, accessible design
- User-friendly layout

### Screenshot 2: Symbol Selection in Action
**Purpose:** Demonstrate ease of use
**Elements to highlight:**
- Selected symbols in the communication bar
- Visual feedback
- Touch-friendly interface

### Screenshot 3: Voice/Audio Features
**Purpose:** Show TTS and voice capabilities
**Elements to highlight:**
- Speech output visualization
- Voice settings
- Audio feedback indicators

### Screenshot 4: Personalization Features
**Purpose:** Show customization options
**Elements to highlight:**
- User profiles
- Customizable settings
- Personal preferences

### Screenshot 5: Learning/Practice Mode
**Purpose:** Highlight educational aspects
**Elements to highlight:**
- Practice exercises
- Learning games
- Progress tracking

### Screenshot 6: Accessibility Features
**Purpose:** Show inclusive design
**Elements to highlight:**
- Large text options
- High contrast mode
- Easy navigation

## Screenshot Automation Script

Run the following script to capture screenshots automatically:

```python
# See assets_store/capture_screenshots.py
```

## Manual Screenshot Instructions

### For Android (Using Android Studio/Device)
1. Open the app on your Android device or emulator
2. Navigate to each key screen
3. Use `adb shell screencap` or device screenshot function
4. Ensure screenshots are in the correct resolution

### For iOS (Using Xcode Simulator)
1. Open the app in iOS Simulator
2. Navigate to each key screen
3. Use `Cmd + S` to save screenshots
4. Screenshots will be saved to Desktop

## Screenshot Editing Tips

### Required Text Overlays (Optional but Recommended)
- Keep text minimal and impactful
- Use high contrast colors
- Ensure text is readable on mobile displays
- Highlight key features with callouts

### Brand Consistency
- Use consistent color scheme
- Include app logo where appropriate
- Maintain professional appearance

## Screenshots Storage Structure
```
assets_store/
├── promotional/
│   ├── screenshots/
│   │   ├── android/
│   │   │   ├── phone/
│   │   │   └── tablet/
│   │   └── ios/
│   │       ├── iphone/
│   │       └── ipad/
│   └── feature_graphics/
└── marketing/
```

## Quality Checklist
- [ ] All screenshots are in correct dimensions
- [ ] Images are crisp and clear (not blurry)
- [ ] App content is fully visible
- [ ] No personal information is shown
- [ ] Screenshots show diverse use cases
- [ ] Text is readable at small sizes
- [ ] Colors are vibrant and appealing
- [ ] Screenshots tell a cohesive story

## Next Steps After Screenshot Capture
1. Review all screenshots for quality
2. Create feature graphic for Google Play
3. Prepare marketing copy
4. Upload to respective app stores
5. Test store listings with different devices

## Pro Tips
- Use the app in different scenarios (morning, afternoon, different lighting)
- Show the app being used by different user personas
- Capture both portrait and landscape orientations where applicable
- Include captions that highlight accessibility features
- Test how screenshots look in store listings before submission
