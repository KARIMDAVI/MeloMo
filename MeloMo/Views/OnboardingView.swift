import SwiftUI
import AuthenticationServices

struct OnboardingView: View {
    @StateObject private var authManager = AuthManager()
    @State private var showMainApp = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        if showMainApp {
            ContentView()
                .environmentObject(authManager)
        } else {
            ZStack {
                // Assuming ThemeColors is defined elsewhere in the project
                // Color.black.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Spacer()
                    
                    // App Logo and Branding
                    VStack(spacing: 12) {
                        // Assuming Text.fa and Icons are defined elsewhere
                        Image(systemName: "music.quarternote.3")
                            .font(.system(size: 50))
                            .foregroundColor(.purple)
                        
                        Text("MeloMo")
                            .font(.largeTitle).fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Find Your Vibe")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    // Error Message
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.red.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                                    )
                            )
                    }
                    
                    // Sign In Buttons
                    VStack(spacing: 16) {
                        SignInWithAppleButton(
                            onRequest: { request in request.requestedScopes = [.fullName, .email] },
                            onCompletion: { result in handleAppleSignIn(result: result) }
                        )
                        .signInWithAppleButtonStyle(.white)
                        .frame(height: 50)
                        .cornerRadius(12)
                        
                        googleSignInButton
                        demoSignInButton
                    }
                    .padding(.horizontal, 40)
                    
                    Spacer()
                    
                    guestContinueButton
                }
            }
            .background(Color.black.ignoresSafeArea())
        }
    }
    
    // MARK: - Subviews
    private var googleSignInButton: some View {
        Button(action: handleGoogleSignIn) {
            HStack {
                if isLoading {
                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    // Assuming google icon is in assets
                    Image("google-signin")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)
                }
                Text("Continue with Google")
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue) // Use Google's brand blue
            .cornerRadius(12)
        }
        .disabled(isLoading)
    }
    
    private var demoSignInButton: some View {
        Button(action: handleDemoSignIn) {
            HStack {
                Image(systemName: "person.fill")
                Text("Try Demo Account")
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.green)
            .cornerRadius(12)
        }
        .disabled(isLoading)
    }
    
    private var guestContinueButton: some View {
        Button("Continue as Guest") { handleGuestContinue() }
            .font(.body)
            .foregroundColor(.orange)
            .padding(.bottom, 20)
    }
    
    // MARK: - Sign In Handlers
    private func handleAppleSignIn(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                let user = AuthManager.User(
                    id: appleIDCredential.user,
                    name: "\(appleIDCredential.fullName?.givenName ?? "") \(appleIDCredential.fullName?.familyName ?? "")",
                    email: appleIDCredential.email ?? "",
                    profileImageURL: nil
                )
                
                authManager.currentUser = user
                authManager.isSignedIn = true
                authManager.authMethod = .apple
                showMainApp = true
            }
        case .failure(let error):
            errorMessage = "Apple Sign-In failed: \(error.localizedDescription)"
        }
    }
    
    private func handleGoogleSignIn() {
        isLoading = true
        errorMessage = nil
        
        Task {
            await authManager.signInWithGoogle()
            
            await MainActor.run {
                isLoading = false
                if authManager.isSignedIn {
                    showMainApp = true
                } else {
                    errorMessage = "Google Sign-In failed. Please try again."
                }
            }
        }
    }
    
    private func handleDemoSignIn() {
        authManager.signInWithDemo()
        showMainApp = true
    }
    
    private func handleGuestContinue() {
        authManager.continueAsGuest()
        showMainApp = true
    }
}

#Preview {
    OnboardingView()
        .preferredColorScheme(.dark)
}
