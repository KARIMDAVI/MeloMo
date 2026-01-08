# Google Sign-In Integration Guide for MeloMo

## Current Status
✅ **AuthManager Updated**: Now handles missing GoogleSignIn dependency gracefully
✅ **Fallback Mode**: Google Sign-In works with demo user when SDK is not available
✅ **Conditional Compilation**: Uses `#if canImport(GoogleSignIn)` for safe imports

## To Add Full Google Sign-In Support:

### 1. Add Google Sign-In SDK via Swift Package Manager

#### In Xcode:
1. **File → Add Package Dependencies**
2. **Enter URL**: `https://github.com/google/GoogleSignIn-iOS`
3. **Select Version**: Choose latest stable version
4. **Add to Target**: Select MeloMo target
5. **Click Add Package**

### 2. Configure Google Sign-In

#### Add to Info.plist:
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>REVERSED_CLIENT_ID</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>YOUR_REVERSED_CLIENT_ID</string>
        </array>
    </dict>
</array>
```

#### Add to MeloMoApp.swift:
```swift
import GoogleSignIn

@main
struct MeloMoApp: App {
    var body: some Scene {
        WindowGroup {
            OnboardingView()
        }
    }
    
    init() {
        // Configure Google Sign-In
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let clientId = plist["CLIENT_ID"] as? String else {
            print("GoogleService-Info.plist not found or CLIENT_ID missing")
            return
        }
        
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientId)
    }
}
```

### 3. Get GoogleService-Info.plist

#### From Google Cloud Console:
1. **Go to**: [Google Cloud Console](https://console.cloud.google.com/)
2. **Create Project** or select existing
3. **Enable Google Sign-In API**
4. **Create OAuth 2.0 Credentials**:
   - Application type: iOS
   - Bundle ID: Your app's bundle identifier
5. **Download GoogleService-Info.plist**
6. **Add to Xcode**: Drag into project root

### 4. Update Bundle Identifier

#### In Xcode:
1. **Select Project** → **MeloMo Target**
2. **General Tab** → **Bundle Identifier**
3. **Set to**: The bundle ID used in Google Console

### 5. Test Google Sign-In

#### Current Behavior:
- ✅ **Without SDK**: Creates demo Google user
- ✅ **With SDK**: Full Google authentication
- ✅ **Error Handling**: Graceful fallbacks

## Alternative: Use Demo Mode

If you don't want to set up Google Sign-In immediately:

### Current Demo Features:
- ✅ **Apple Sign-In**: Full native support
- ✅ **Demo Account**: Instant access
- ✅ **Guest Mode**: No authentication required
- ✅ **Google Demo**: Simulated Google user

### Demo User Details:
- **Name**: "Google User"
- **Email**: "user@gmail.com"
- **ID**: Generated unique identifier

## File Structure After Integration:
```
MeloMo/
├── GoogleService-Info.plist (after adding)
├── Core/
│   └── MeloMoApp.swift (updated)
├── Managers/
│   └── AuthManager.swift (✅ updated)
└── ...
```

## Testing Authentication:

### 1. Apple Sign-In:
- ✅ **Native Button**: Uses SignInWithAppleButton
- ✅ **Real Authentication**: Full Apple ID integration

### 2. Google Sign-In:
- 🔄 **Demo Mode**: Works without SDK
- 🎯 **Full Mode**: Works with SDK + configuration

### 3. Demo Account:
- ✅ **Instant Access**: No external dependencies
- ✅ **Full Features**: All app functionality

### 4. Guest Mode:
- ✅ **No Authentication**: Continue without sign-in
- ✅ **Limited Access**: Vibes tab only

## Next Steps:

1. **Test Current Setup**: Build and test with demo Google user
2. **Add Google SDK**: Follow integration steps above
3. **Configure OAuth**: Set up Google Cloud Console
4. **Test Full Integration**: Verify real Google authentication

The app is now ready to build and run with graceful Google Sign-In handling! 🎉


