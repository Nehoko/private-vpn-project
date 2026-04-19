import SwiftUI

struct SubscriberEditorView: View {
    @EnvironmentObject private var state: AppState

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
    }
}
