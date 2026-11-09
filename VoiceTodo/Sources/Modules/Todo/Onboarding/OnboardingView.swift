//
//  OnboardingView.swift
//  VoiceTodo
//
//  Design: frame "VI / 1 Onboarding". Shown once, on first launch.
//

import SwiftUI
import VoxoDesign

struct OnboardingView: View {
    @StateObject private var viewModel = ViewModel()
    let onFinish: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Image("TidyLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 96, height: 96)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

            Text(verbatim: "Tidy")
                .font(VoxoFont.display)
                .foregroundStyle(VoxoColor.textPrimary)
                .padding(.top, VoxoSpacing.l)

            Text("Capture tasks fast. Live light.")
                .font(VoxoFont.body)
                .foregroundStyle(VoxoColor.textSecondary)
                .padding(.top, VoxoSpacing.s)

            Spacer()

            languagePicker

            Spacer()

            Button("Start") {
                viewModel.apply()
                onFinish()
            }
            .buttonStyle(VoxoPrimaryButtonStyle())
            .padding(.bottom, VoxoSpacing.xl)
        }
        .padding(.horizontal, VoxoSpacing.screenMargin)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(VoxoColor.background)
    }

    private var languagePicker: some View {
        VStack(alignment: .leading, spacing: VoxoSpacing.m) {
            Text("Choose a language")
                .font(VoxoFont.headline)
                .foregroundStyle(VoxoColor.textPrimary)

            ForEach(OnboardingView.ViewModel.Language.allCases) { language in
                row(language)
            }

            Text("You can change the language any time in Settings")
                .font(VoxoFont.caption)
                .foregroundStyle(VoxoColor.textMuted)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, VoxoSpacing.xs)
        }
    }

    private func row(_ language: OnboardingView.ViewModel.Language) -> some View {
        let isSelected = viewModel.selected == language

        return Button {
            viewModel.selected = language
        } label: {
            HStack {
                // The language's own name, never translated.
                Text(verbatim: language.nativeName)
                    .font(VoxoFont.bodyEmphasis)
                    .foregroundStyle(VoxoColor.textPrimary)

                Spacer()

                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(isSelected ? VoxoColor.primary : VoxoColor.textMuted)
            }
            .padding(.horizontal, VoxoSpacing.l)
            .frame(minHeight: 60)
            .background(isSelected ? VoxoColor.primaryTint : VoxoColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: VoxoRadius.card, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: VoxoRadius.card, style: .continuous)
                    .strokeBorder(isSelected ? VoxoColor.primary : VoxoColor.border, lineWidth: 1.5)
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}
