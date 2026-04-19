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
        .safeAreaInset(edge: .top, spacing: 0) {
            if let bannerMessage = state.bannerMessage {
                BannerView(message: bannerMessage) {
                    state.dismissBanner()
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    state.openCreateSubscriber()
                } label: {
                    Label("Add", systemImage: "plus")
                }
                .labelStyle(.iconOnly)
                .help("Add subscriber")
                .keyboardShortcut("n", modifiers: [.command])

                Button {
                    state.openEditSubscriber()
                } label: {
                    Label("Edit", systemImage: "slider.horizontal.3")
                }
                .labelStyle(.iconOnly)
                .help("Edit selected subscriber")
                .disabled(!state.toolbarCanEdit)

                Button {
                    state.promptDeleteSelected()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                .labelStyle(.iconOnly)
                .help("Delete selected subscriber")
                .disabled(!state.toolbarCanEdit)
            }

            ToolbarItem {
                Menu {
                    Picker("Filter", selection: $state.selectedFilter) {
                        ForEach(SubscriberFilter.allCases) { filter in
                            Label(filter.rawValue, systemImage: filter.symbolName)
                                .tag(filter)
                        }
                    }
                } label: {
                    Label("Filter", systemImage: state.selectedFilter.symbolName)
                }
                .help("Filter subscriber list")
            }

            ToolbarItem {
                Button {
                    Task { await state.syncCalendarEvents() }
                } label: {
                    Label("Sync Calendar", systemImage: state.isCalendarSyncing ? "arrow.trianglehead.2.clockwise.rotate.90" : "calendar.badge.clock")
                }
                .help("Sync all reminders to \(CalendarService.managedCalendarTitle)")
                .disabled(state.isCalendarSyncing)
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

private struct BannerView: View {
    let message: BannerMessage
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: message.tone == .success ? "checkmark.seal.fill" : "info.circle.fill")
                .foregroundStyle(message.tone == .success ? .green : .blue)

            Text(message.text)
                .font(.callout)
                .lineLimit(2)

            Spacer(minLength: 0)

            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder((message.tone == .success ? Color.green : Color.blue).opacity(0.18))
        }
    }
}
