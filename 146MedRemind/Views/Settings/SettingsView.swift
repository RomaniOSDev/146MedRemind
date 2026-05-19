//
//  SettingsView.swift
//  146MedRemind
//

import StoreKit
import SwiftUI
import UIKit

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                MedScreenBackdrop(style: .app)
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        Text("Settings")
                            .font(.largeTitle.bold())
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.medPending, Color.white.opacity(0.9)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: Color.medPending.opacity(0.35), radius: 10, x: 0, y: 5)

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Support")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.medPending)

                            settingsRow(
                                icon: "star.fill",
                                iconTint: .yellow,
                                title: "Rate us",
                                subtitle: "Tell us what you think on the App Store",
                                action: rateApp
                            )
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Legal")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.medPending)

                            settingsRow(
                                icon: "hand.raised.fill",
                                iconTint: .cyan,
                                title: "Privacy Policy",
                                subtitle: "How we handle your data",
                                action: { openExternalURL(.privacyPolicy) }
                            )

                            settingsRow(
                                icon: "doc.text.fill",
                                iconTint: Color.medTaken,
                                title: "Terms of Use",
                                subtitle: "Rules for using the app",
                                action: { openExternalURL(.termsOfUse) }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 32)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private func openExternalURL(_ link: MedAppExternalLink) {
        if let url = link.url {
            UIApplication.shared.open(url)
        }
    }

    private func rateApp() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }

    private func settingsRow(
        icon: String,
        iconTint: Color,
        title: String,
        subtitle: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(iconTint.opacity(0.2))
                        .frame(width: 48, height: 48)
                    Image(systemName: icon)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(iconTint)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(Color.medSecondaryLabel)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.medTertiaryLabel)
            }
            .padding(14)
            .medElevatedCard(cornerRadius: 18, accent: Color.medPending, intensity: 0.95)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SettingsView()
}
