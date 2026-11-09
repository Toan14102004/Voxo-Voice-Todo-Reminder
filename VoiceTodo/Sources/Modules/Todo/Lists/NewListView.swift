//
//  NewListView.swift
//  VoiceTodo
//
//  The "Danh sách mới · Chọn màu & emoji" modal from the Lists design.
//

import SwiftUI
import VoxoDesign
import VoxoShared

struct NewListView: View {
    let onCreate: (String, String, String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var colorHex = TodoListDTO.paletteHex[0]
    @State private var icon = TodoListDTO.iconChoices[0]
    @FocusState private var nameFocused: Bool

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: VoxoSpacing.xl) {
                preview

                TextField("List name", text: $name)
                    .font(VoxoFont.title)
                    .focused($nameFocused)
                    .submitLabel(.done)

                picker("Colour") {
                    ForEach(TodoListDTO.paletteHex, id: \.self) { hex in
                        swatch(hex)
                    }
                }

                picker("Icon") {
                    ForEach(TodoListDTO.iconChoices, id: \.self) { name in
                        iconChoice(name)
                    }
                }

                Spacer()
            }
            .padding(.horizontal, VoxoSpacing.screenMargin)
            .padding(.top, VoxoSpacing.l)
            .background(VoxoColor.background)
            .navigationTitle("New list")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        onCreate(trimmedName, colorHex, icon)
                        dismiss()
                    }
                    .disabled(trimmedName.isEmpty)
                }
            }
            .onAppear { nameFocused = true }
        }
    }

    /// Shows the card exactly as it will look in the grid, so the choices are judged in context.
    private var preview: some View {
        VoxoListCard(
            icon: icon,
            name: trimmedName.isEmpty ? String(localized: "New list") : trimmedName,
            count: 0,
            tint: Color(hexString: colorHex)
        )
        .frame(maxWidth: 180)
        .frame(maxWidth: .infinity, alignment: .center)
    }

    @ViewBuilder
    private func picker(_ title: LocalizedStringKey, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: VoxoSpacing.m) {
            VoxoSectionHeader(title)
            HStack(spacing: VoxoSpacing.m) { content() }
        }
    }

    private func swatch(_ hex: String) -> some View {
        let isSelected = hex == colorHex

        return Button { colorHex = hex } label: {
            Circle()
                .fill(Color(hexString: hex))
                .frame(width: 36, height: 36)
                .overlay {
                    if isSelected {
                        Image(systemName: VoxoIcon.check)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .overlay {
                    Circle().strokeBorder(VoxoColor.textPrimary.opacity(isSelected ? 0.35 : 0),
                                          lineWidth: 2)
                }
        }
        .buttonStyle(.plain)
        .frame(minWidth: VoxoHitTarget.minimum, minHeight: VoxoHitTarget.minimum)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private func iconChoice(_ symbol: String) -> some View {
        let isSelected = symbol == icon

        return Button { icon = symbol } label: {
            Image(systemName: symbol)
                .font(.system(size: 20, weight: .regular))
                .foregroundStyle(isSelected ? VoxoColor.textOnAccent : VoxoColor.textSecondary)
                .frame(width: 40, height: 40)
                .background(isSelected ? VoxoColor.primary : VoxoColor.surface)
                .clipShape(RoundedRectangle(cornerRadius: VoxoRadius.chipSmall, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}
