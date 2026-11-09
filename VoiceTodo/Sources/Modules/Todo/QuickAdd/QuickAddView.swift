//
//  QuickAddView.swift
//  VoiceTodo
//
//  Design: frame "VI / 3 Thêm nhanh" — a bottom sheet over Today.
//

import SwiftUI
import VoxoDesign
import VoxoShared

struct QuickAddView: View {
    @EnvironmentObject private var store: TodoStore
    @Navigation private var navigation
    @StateObject private var viewModel = ViewModel()
    @FocusState private var titleFocused: Bool

    var body: some View {
        // Sized by its content via detents: filling the sheet and pushing content down with a
        // Spacer rendered as a blank screen with everything jammed at the bottom.
        VoxoQuickAddSheet(
            title: $viewModel.title,
            note: $viewModel.note,
            chips: viewModel.chips(store: store),
            canSubmit: viewModel.canSubmit,
            onSubmit: submit
        )
        .frame(maxWidth: .infinity, alignment: .top)
        .background(VoxoColor.surfaceRaised)
        .presentationDetents([.height(Self.sheetHeight)])
        .presentationDragIndicator(.hidden)
        .onAppear { titleFocused = true }
    }

    /// Matches the design's 344pt sheet, plus room for the home indicator.
    private static let sheetHeight: CGFloat = 380

    private func submit() {
        viewModel.submit(into: store)
        navigation.goBack()
    }
}
