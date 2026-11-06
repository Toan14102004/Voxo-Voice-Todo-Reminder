//
//  LanguageView.swift
//  VoiceTodo
//
//  Created by Toan Nguyen on 15/10/25.
//

import SwiftUI

struct LanguageView: View {
    
    @Injected var localStorageService: LocalStorageService
    
    @ObservedObject var viewModel: ViewModel
    
    var body: some View {
        BaseView {
            VStack (spacing: Layout.Spacing.m) {
                ScrollView {
                    VStack(spacing: Layout.Spacing.m) {
                        ForEach(viewModel.languages) { language in
                            LanguageRowView(
                                language: language,
                                isSelected: viewModel.selectedLanguage?.id == language.id,
                                onTap: viewModel.selectLanguage(_:)
                            )
                        }
                    }
                    .padding(.horizontal, Layout.Spacing.m)
                    .padding(.top, Layout.Spacing.l)
                }
                
                ZStack {
                    if viewModel.showClickAd {
                        PreloadedNativeAdsView(
                            adKey: .languageClick,
                            style: .large(),
                            height: 250
                        )
                    } else {
                        PreloadedNativeAdsView(
                            adKey: .language,
                            style: .large(),
                            height: 250
                        )
                    }
                }
                .padding(.horizontal, Layout.Spacing.xs)
            }
        }
        .toolbar {
            if !viewModel.isOnboardingContext {
                BackButton {
                    viewModel.goBack()
                }
            }
        
            ToolbarTitleSetting(firstPart: "Choose Language", secondPart: "")
            
            if viewModel.hasLanguageChanged {
                ToolbarIconButton(
                    placement: .topBarTrailing,
                    icon: Asset.Icon.Commo.checkmark.image,
                    color: Asset.Color.mainColor.color,
                    action: viewModel.confirmLanguageChange,
                    sizeIcon: Layout.Icon.large
                )
            }
        }
        .trackScreen("languageVC")
    }
}

struct LanguageRowView: View {
    let language: Language
    let isSelected: Bool
    let onTap: (Language) -> Void
    
    var body: some View {
        
        Button {
            onTap(language)
        } label: {
            HStack(spacing: Layout.Spacing.l) {
                // Country flag
                language.flagAsset.image
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
                
                // Language name
                Text(language.name)
                    .font(.system(size: Layout.Text.callout, weight: .medium))
                    .foregroundColor(.primary)
                
                Spacer()
                ZStack {
                    Circle()
                        .stroke(isSelected ? Asset.Color.mainColor.color : Asset.Color.white.color.opacity(0.3), lineWidth: 1.2)
                        .frame(width: 22.iPad(24), height: 22.iPad(24))
                                    
                    if isSelected {
                        Circle()
                            .fill(Asset.Color.mainColor.color)
                            .frame(width: 16.iPad(18), height: 16.iPad(18))
                    }
                }
            }
            .padding(.horizontal, Layout.Spacing.l)
            .padding(.vertical, Layout.Spacing.m)
            .background(Asset.Color.colorBrand.color)
            .cornerRadius(Layout.CornerRadius.large)
            .overlay(
                RoundedRectangle(cornerRadius: Layout.CornerRadius.large)
                    .stroke(isSelected ? Asset.Color.mainColor.color : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    LanguageView(viewModel: .init())
        .preview()
}
