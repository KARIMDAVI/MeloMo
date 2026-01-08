import SwiftUI
import AuthenticationServices

#if canImport(GoogleSignIn)
import GoogleSignIn
#endif

// MARK: - Authentication Manager
class AuthManager: ObservableObject {
    @Published var isSignedIn = false
    @Published var currentUser: User?
    @Published var authMethod: AuthMethod = .none
    
    enum AuthMethod {
        case none
        case apple
        case google
        case demo
        case guest
    }
    
    struct User {
        let id: String
        let name: String
        let email: String
        let profileImageURL: String?
    }
    
    func signInWithApple() async {
        // Note: Apple Sign-In should be handled through SignInWithAppleButton in the UI
        // This method is kept for compatibility but the actual sign-in flow
        // should be handled in OnboardingView using SignInWithAppleButton
        print("Apple Sign-In should be handled through SignInWithAppleButton in the UI")
    }
    
    func signInWithGoogle() async {
        #if canImport(GoogleSignIn)
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let presentingViewController = windowScene.windows.first?.rootViewController else {
            return
        }
        
        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController)
            let user = result.user
            
            let meloMoUser = User(
                id: user.userID ?? "",
                name: user.profile?.name ?? "",
                email: user.profile?.email ?? "",
                profileImageURL: user.profile?.imageURL(withDimension: 100)?.absoluteString
            )
            
            await MainActor.run {
                self.currentUser = meloMoUser
                self.isSignedIn = true
                self.authMethod = .google
            }
        } catch {
            print("Google Sign-In failed: \(error)")
        }
        #else
        // Fallback for when GoogleSignIn is not available
        await MainActor.run {
            let fallbackUser = User(
                id: "google_user_\(UUID().uuidString)",
                name: "Google User",
                email: "user@gmail.com",
                profileImageURL: nil
            )
            self.currentUser = fallbackUser
            self.isSignedIn = true
            self.authMethod = .google
        }
        #endif
    }
    
    func signInWithDemo() {
        let demoUser = User(
            id: "demo_user_123",
            name: "Demo User",
            email: "demo@melomo.app",
            profileImageURL: nil
        )
        
        currentUser = demoUser
        isSignedIn = true
        authMethod = .demo
    }
    
    func continueAsGuest() {
        currentUser = nil
        isSignedIn = false
        authMethod = .guest
    }
    
    func signOut() {
        let currentAuthMethod = authMethod
        
        currentUser = nil
        isSignedIn = false
        authMethod = .none
        
        // Sign out from Google if needed
        if currentAuthMethod == .google {
            #if canImport(GoogleSignIn)
            GIDSignIn.sharedInstance.signOut()
            #endif
        }
    }
}
