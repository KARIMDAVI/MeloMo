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
                // Dark background
                Color.black
                    .ignoresSafeArea()
                
                VStack(spacing: 40) {
                    Spacer()
                    
                    // App Logo and Branding
                    VStack(spacing: 16) {
                        // Logo
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(
                                    LinearGradient(
                                        colors: [.orange, .purple, .blue],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 80, height: 80)
                                .blur(radius: 20)
                            
                            Image(systemName: "music.note")
                                .font(.system(size: 40, weight: .bold))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.pink, .cyan],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                        
                        // App Name
                        Text("MeloMo")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        // Tagline
                        Text("Unlock your full music journey")
                            .font(.headline)
                            .foregroundColor(.orange)
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
                        // Sign in with Apple
                        SignInWithAppleButton(
                            onRequest: { request in
                                request.requestedScopes = [.fullName, .email]
                            },
                            onCompletion: { result in
                                handleAppleSignIn(result: result)
                            }
                        )
                        .signInWithAppleButtonStyle(.white)
                        .frame(height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        // Continue with Google
                        Button(action: {
                            handleGoogleSignIn()
                        }) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Image("google-signin")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 20, height: 20)
                                }
                                
                                Text("Continue with Google")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(isLoading)
                        
                        // Try Demo Account
                        Button(action: {
                            handleDemoSignIn()
                        }) {
                            HStack {
                                Image(systemName: "person")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                
                                Text("Try Demo Account")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.green)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(isLoading)
                    }
                    .padding(.horizontal, 40)
                    
                    // Features
                    VStack(spacing: 20) {
                        FeatureRow(
                            icon: "chart.bar",
                            title: "Track Your Stats",
                            description: "Monitor your listening habits and achievements"
                        )
                        
                        FeatureRow(
                            icon: "trophy",
                            title: "Play Challenges",
                            description: "Test your music knowledge with trivia"
                        )
                        
                        FeatureRow(
                            icon: "gear",
                            title: "Customize Experience",
                            description: "Personalize your app settings and preferences"
                        )
                    }
                    .padding(.horizontal, 40)
                    
                    Spacer()
                    
                    // Continue as Guest
                    Button("Continue as Guest") {
                        handleGuestContinue()
                    }
                    .font(.body)
                    .foregroundColor(.orange)
                    .padding(.bottom, 20)
                }
            }
        }
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

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.orange)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.orange)
                
                Text(description)
                    .font(.body)
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
    }
}

#Preview {
    OnboardingView()
        .preferredColorScheme(.dark)
}
