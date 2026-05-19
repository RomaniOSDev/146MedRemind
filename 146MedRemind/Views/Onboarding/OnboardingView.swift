//
//  OnboardingView.swift
//  146MedRemind
//

import SwiftUI

struct OnboardingView: View {
    var onFinished: () -> Void

    @State private var page = 0

    var body: some View {
        ZStack {
            MedScreenBackdrop(style: .sheet)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button("Skip") {
                        onFinished()
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.medPending)
                    .padding(.trailing, 20)
                    .padding(.top, 12)
                }

                TabView(selection: $page) {
                    OnboardingPageView(
                        systemImages: ["calendar.badge.clock", "bell.badge.fill"],
                        iconColors: [.medPending, .orange],
                        title: "Plan every dose",
                        subtitle: "See what is due today and get nudges when it is time."
                    )
                    .tag(0)

                    OnboardingPageView(
                        systemImages: ["pills.fill", "shippingbox.fill"],
                        iconColors: [.cyan, .medTaken],
                        title: "Track supply",
                        subtitle: "Log refills and low-stock alerts so you never run out."
                    )
                    .tag(1)

                    OnboardingPageView(
                        systemImages: ["flame.fill", "chart.bar.fill"],
                        iconColors: [.orange, .medTaken],
                        title: "Stay consistent",
                        subtitle: "History and streaks help you keep momentum."
                    )
                    .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))

                VStack(spacing: 12) {
                    if page < 2 {
                        Button {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.86)) {
                                page += 1
                            }
                        } label: {
                            Text("Continue")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        colors: [.medPending, .medPending.opacity(0.78)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .foregroundStyle(Color.medBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(Color.white.opacity(0.22), lineWidth: 1)
                                )
                                .medFloatingButtonShadow(accent: .medPending)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 24)
                    } else {
                        Button {
                            onFinished()
                        } label: {
                            Text("Get started")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        colors: [.medTaken, .medTaken.opacity(0.75)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .foregroundStyle(Color.medBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(Color.white.opacity(0.25), lineWidth: 1)
                                )
                                .shadow(color: Color.medTaken.opacity(0.45), radius: 18, x: 0, y: 10)
                                .shadow(color: Color.black.opacity(0.35), radius: 12, x: 0, y: 6)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 24)
                    }
                }
                .padding(.bottom, 28)
                .padding(.top, 8)
            }
        }
    }
}

private struct OnboardingPageView: View {
    let systemImages: [String]
    let iconColors: [Color]
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 28) {
            Spacer(minLength: 20)

            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.medPending.opacity(0.25), Color.clear],
                            center: .center,
                            startRadius: 20,
                            endRadius: 140
                        )
                    )
                    .frame(width: 260, height: 260)

                HStack(spacing: -8) {
                    ForEach(Array(systemImages.enumerated()), id: \.offset) { index, name in
                        ZStack {
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.12),
                                            Color.white.opacity(0.04)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 108, height: 108)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                                        .stroke(iconColors[index].opacity(0.55), lineWidth: 1.5)
                                )
                                .shadow(color: Color.black.opacity(0.45), radius: 16, x: 0, y: 10)
                                .shadow(color: iconColors[index].opacity(0.35), radius: 20, x: 0, y: 6)

                            Image(systemName: name)
                                .font(.system(size: 44, weight: .semibold))
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [iconColors[index], iconColors[index].opacity(0.65)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                        .rotationEffect(.degrees(index == 0 ? -6 : 6))
                    }
                }
            }

            VStack(spacing: 12) {
                Text(title)
                    .font(.title.bold())
                    .multilineTextAlignment(.center)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, Color.white.opacity(0.85)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text(subtitle)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.medSecondaryLabel)
                    .padding(.horizontal, 32)
            }

            Spacer(minLength: 40)
        }
        .padding(.horizontal, 8)
    }
}

#Preview {
    OnboardingView(onFinished: {})
}
