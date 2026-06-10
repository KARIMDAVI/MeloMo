
import SwiftUI

struct SignInRequiredView: View {
    @EnvironmentObject private var authManager: AuthManager
    
    let title: String
    let icon: String
    let description: String
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Current Vibe Card
                currentVibeCard
                
                // Sign in prompt
                VStack(spacing: 16) {
                    Image(systemName: icon)
                        .font(.system(size: 48))
                        .foregroundColor(.yellow)
                    
                    Text("Sign in to access \(title.lowercased())")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text(description)
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                    
                            Button("Sign In") {
                                // Handle sign in
                                authManager.signInWithDemo() // For demo purposes
                            }
                    .font(.headline)
                    .foregroundColor(.black)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(Color.yellow)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .padding(.top, 40)
                
                Spacer()
            }
            .padding(.vertical, 20)
        }
    }
    
    // MARK: - Current Vibe Card
    private var currentVibeCard: some View {
        HStack(spacing: 16) {
            // Magical stars
            HStack(spacing: 4) {
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundColor(.yellow)
                
                Image(systemName: "star.fill")
                    .font(.title3)
                    .foregroundColor(.yellow)
                
                Image(systemName: "sparkles")
                    .font(.caption)
                    .foregroundColor(.yellow)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Current Vibe")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Text("Magical")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            // Music note
            Image(systemName: "music.note")
                .font(.title2)
                .foregroundColor(.yellow)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.1, green: 0.15, blue: 0.25))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal, 20)
    }
}
