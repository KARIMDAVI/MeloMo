// MeloMo/Views/Tabs/SettingsView.swift
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var authManager: AuthManager
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Account")) {
                    if let user = authManager.currentUser {
                        HStack {
                            Text.fa(Icons.user, size: 20)
                                .frame(width: 30)
                            Text(user.name)
                        }
                        HStack {
                            Text.fa(.envelope, size: 20)
                                .frame(width: 30)
                            Text(user.email)
                        }
                    } else {
                        Text("Not signed in")
                    }
                }
                
                Section(header: Text("Actions")) {
                    Button(action: { authManager.signOut() }) {
                        HStack {
                            Text.fa(.signOutAlt, size: 20)
                                .frame(width: 30)
                            Text("Sign Out")
                        }
                        .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Settings")
            .background(ThemeColors.background)
            .scrollContentBackground(.hidden)
        }
    }
}

