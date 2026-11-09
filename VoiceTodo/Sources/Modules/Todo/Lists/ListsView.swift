//
//  ListsView.swift
//  VoiceTodo
//
//  Design: frame "VI / 5 Danh sách".
//

import SwiftUI
import VoxoDesign
import VoxoShared

struct ListsView: View {
    @EnvironmentObject private var store: TodoStore
    @StateObject private var viewModel = ViewModel()

    private let columns = [
        GridItem(.flexible(), spacing: VoxoSpacing.m),
        GridItem(.flexible(), spacing: VoxoSpacing.m)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: VoxoSpacing.xl) {
                header
                grid
                smartFilters
            }
            .padding(.horizontal, VoxoSpacing.screenMargin)
            .padding(.bottom, VoxoSpacing.xxl)
        }
        .background(VoxoColor.background)
        .sheet(isPresented: $viewModel.isCreating) {
            NewListView { name, colorHex, icon in
                store.addList(name: name, colorHex: colorHex, icon: icon)
            }
        }
    }

    private var header: some View {
        HStack {
            Text("Lists")
                .font(VoxoFont.display)
                .foregroundStyle(VoxoColor.textPrimary)

            Spacer()

            Button { viewModel.isCreating = true } label: {
                Image(systemName: VoxoIcon.add)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(VoxoColor.primary)
            }
            .accessibilityLabel("New list")
        }
        .padding(.top, VoxoSpacing.l)
    }

    private var grid: some View {
        LazyVGrid(columns: columns, spacing: VoxoSpacing.m) {
            ForEach(store.lists) { list in
                Button {
                    viewModel.open(list)
                } label: {
                    VoxoListCard(
                        icon: list.icon,
                        name: list.name,
                        count: store.taskCount(inList: list.id),
                        tint: Color(hexString: list.colorHex)
                    )
                }
                .buttonStyle(.plain)
            }

            VoxoNewListCard { viewModel.isCreating = true }
        }
    }

    private var smartFilters: some View {
        VStack(alignment: .leading, spacing: VoxoSpacing.m) {
            VoxoSectionHeader("Smart filters")

            VoxoDetailsCard {
                VoxoSmartFilterRow(icon: "star", title: "High priority",
                                   count: viewModel.highPriorityCount(store)) {
                    viewModel.open(.highPriority)
                }
                Divider().padding(.leading, VoxoSpacing.xl + VoxoSpacing.l)
                VoxoSmartFilterRow(icon: VoxoIcon.date, title: "Next 7 days",
                                   count: viewModel.nextSevenDaysCount(store)) {
                    viewModel.open(.nextSevenDays)
                }
                Divider().padding(.leading, VoxoSpacing.xl + VoxoSpacing.l)
                VoxoSmartFilterRow(icon: VoxoIcon.checked, title: "Completed",
                                   count: store.completed.count) {
                    viewModel.open(.completed)
                }
            }
        }
    }
}
