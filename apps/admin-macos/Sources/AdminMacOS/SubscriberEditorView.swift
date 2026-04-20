import SwiftUI
import UniformTypeIdentifiers

struct SubscriberEditorView: View {
    @EnvironmentObject private var state: AppState
    @State private var isImportingVPNConfig = false

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(state.editorMode.rawValue)
                .font(.title2.weight(.semibold))

            Form {
                TextField("First name", text: $state.editorDraft.firstName)
                TextField("Last name", text: $state.editorDraft.lastName)
                TextField("Telegram username", text: $state.editorDraft.telegramUsername)
                TextField("Telegram ID", text: $state.editorDraft.telegramId)
                DatePicker("Start date", selection: $state.editorDraft.startDate, displayedComponents: .date)
                DatePicker("Next payup date", selection: $state.editorDraft.nextPayupDate, displayedComponents: .date)
                Toggle("Active", isOn: $state.editorDraft.active)

                Section("Calendar") {
                    Text(state.editorDraft.active
                        ? "Save creates or updates one-day all-day event in \(CalendarService.managedCalendarTitle) calendar with D-3 alert."
                        : "Inactive subscriber removes reminder from \(CalendarService.managedCalendarTitle) calendar."
                    )
                    .font(.callout)
                    .foregroundStyle(.secondary)
                }

                Section("VPN Configuration") {
                    HStack {
                        Text(state.editorDraft.vpnConfigFileName ?? "No file attached")
                            .foregroundStyle(state.editorDraft.vpnConfigFileName == nil ? .secondary : .primary)
                            .lineLimit(1)

                        Spacer()

                        Button(state.editorDraft.vpnConfigFileName == nil ? "Attach File" : "Replace File") {
                            isImportingVPNConfig = true
                        }

                        if state.editorDraft.vpnConfigFileName != nil {
                            Button("Remove") {
                                state.removeEditorVPNConfig()
                            }
                        }
                    }
                }
            }
            .formStyle(.grouped)

            HStack {
                Spacer()

                Button("Cancel") {
                    state.closeEditor()
                }

                Button("Save") {
                    Task { await state.saveEditor() }
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(minWidth: 460, minHeight: 360)
        .fileImporter(
            isPresented: $isImportingVPNConfig,
            allowedContentTypes: [.item],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                state.attachEditorVPNConfig(from: url)
            case .failure(let error):
                state.lastError = error.localizedDescription
            }
        }
    }
}
