import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var state: AppState

    var body: some View {
        NavigationSplitView {
            SidebarView()
                .environmentObject(state)
        } detail: {
            SubscriberDetailContainer()
                .environmentObject(state)
        }
        .navigationSplitViewStyle(.balanced)
        .frame(minWidth: 1080, minHeight: 720)
        .toolbar {
            ToolbarItemGroup {
                Button {
                    state.openCreateSubscriber()
                } label: {
                    Label("Add", systemImage: "plus")
                }
                .keyboardShortcut("n", modifiers: [.command])

                Button {
                    state.openEditSubscriber()
                } label: {
                    Label("Edit", systemImage: "slider.horizontal.3")
                }
                .disabled(!state.toolbarCanEdit)

                Button {
                    state.promptDeleteSelected()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                .disabled(!state.toolbarCanEdit)

                Divider()

                Picker("Filter", selection: $state.selectedFilter) {
                    ForEach(SubscriberFilter.allCases) { filter in
                        Label(filter.rawValue, systemImage: filter.symbolName)
                            .tag(filter)
                    }
                }
                .pickerStyle(.menu)

                Button {
                    Task { await state.syncCalendarEvents() }
                } label: {
                    Label("Sync Calendar", systemImage: "calendar.badge.clock")
                }

                Button {
                    state.load()
                } label: {
                    Label("Reload", systemImage: "arrow.clockwise")
                }
                .keyboardShortcut("r", modifiers: [.command])
            }
        }
        .onAppear {
            state.selectFirstVisibleSubscriber()
        }
        .onChange(of: state.selectedFilter) { _, _ in
            state.selectFirstVisibleSubscriber()
        }
        .sheet(isPresented: $state.isShowingEditor) {
            SubscriberEditorView()
                .environmentObject(state)
        }
        .alert(
            state.deleteConfirmationTitle,
            isPresented: $state.isDeleteConfirmationPresented
        ) {
            Button("Delete", role: .destructive) {
                Task { await state.deleteSelectedSubscriber() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(state.deleteConfirmationMessage)
        }
    }
}
