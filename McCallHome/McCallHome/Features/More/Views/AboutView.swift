//
//  AboutView.swift
//  McCallHome
//
//  Created by Claude on 12/2/25.
//

import SwiftUI

struct AboutView: View {
    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        return "\(version) (\(build))"
    }

    var body: some View {
        List {
            // App Icon and Name
            Section {
                HStack {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "house.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.blue)

                        Text("McCall Home")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Your household hub")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical)
                    Spacer()
                }
            }

            // Version Info
            Section("Version") {
                HStack {
                    Text("App Version")
                    Spacer()
                    Text(appVersion)
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("iOS Version")
                    Spacer()
                    Text(UIDevice.current.systemVersion)
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("Device")
                    Spacer()
                    Text(UIDevice.current.model)
                        .foregroundStyle(.secondary)
                }
            }

            // Features
            Section("Features") {
                FeatureRow(icon: "calendar", color: .blue, title: "Meal Planning", description: "Plan your weekly meals")
                FeatureRow(icon: "cart.fill", color: .green, title: "Grocery Lists", description: "Smart shopping lists from recipes")
                FeatureRow(icon: "checkmark.circle.fill", color: .orange, title: "Honeydew Tasks", description: "Household to-do lists")
                FeatureRow(icon: "fork.knife", color: .red, title: "Recipe Book", description: "Store and manage your recipes")
            }

            // Credits
            Section("Credits") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Built with")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("SwiftUI")
                        Text("Supabase")
                        Text("Claude AI")
                    }
                    .font(.subheadline)
                }
                .padding(.vertical, 4)
            }

            // Legal
            Section {
                if let privacyURL = URL(string: "https://mccall-family.github.io/mccall-home/privacy") {
                    Link(destination: privacyURL) {
                        Label("Privacy Policy", systemImage: "hand.raised")
                    }
                }

                if let termsURL = URL(string: "https://mccall-family.github.io/mccall-home/terms") {
                    Link(destination: termsURL) {
                        Label("Terms of Service", systemImage: "doc.text")
                    }
                }
            }

            // Copyright
            Section {
                HStack {
                    Spacer()
                    Text("© \(Calendar.current.component(.year, from: Date())) McCall Family")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct FeatureRow: View {
    let icon: String
    let color: Color
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    NavigationStack {
        AboutView()
    }
}
