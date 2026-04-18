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
        .frame(minWidth: 1080, minHeight: 680)
        .toolbar {
            ToolbarItemGroup {
                Button {
                    state.openConnectionSettings()
                } label: {
                    Label("Connection", systemImage: "server.rack")
                }

                Picker("Filter", selection: $state.selectedFilter) {
                    ForEach(SubscriberFilter.allCases) { filter in
                        Label(filter.rawValue, systemImage: filter.symbolName)
                            .tag(filter)
                    }
                }
                .pickerStyle(.menu)

                Button {
                    Task { await state.refresh() }
                } label: {
                    Label(state.isRefreshing ? "Refreshing" : "Refresh", systemImage: "arrow.clockwise")
                }
                .keyboardShortcut("r", modifiers: [.command])
                .disabled(state.isRefreshing)
            }
        }
        .onAppear {
            state.selectFirstVisibleSubscriber()
        }
        .onChange(of: state.selectedFilter) { _, _ in
            state.selectFirstVisibleSubscriber()
        }
        .sheet(isPresented: $state.isShowingConnectionSheet) {
            ConnectionSettingsView()
                .environmentObject(state)
        }
    }
}
