import SwiftUI

struct ConnectionSettingsView: View {
    @EnvironmentObject private var state: AppState
    @FocusState private var focusedField: Field?

    private enum Field {
        case baseURL
        case token
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Welcome to Private VPN Admin")
                    .font(.title2.weight(.semibold))
                Text("Enter backend URL and admin token. App stores these values locally for future launches.")
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("API URL")
                        .font(.headline)
                    TextField("http://127.0.0.1:8080", text: $state.connectionSettings.baseURL)
                        .textFieldStyle(.roundedBorder)
                        .focused($focusedField, equals: .baseURL)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Admin Token")
                        .font(.headline)
                    SecureField("change-me", text: $state.connectionSettings.token)
                        .textFieldStyle(.roundedBorder)
                        .focused($focusedField, equals: .token)
                }
            }

            if let lastError = state.lastError {
                Label(lastError, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }

            HStack {
                Button("Use Current Values") {
                    state.saveConnectionSettings()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!state.connectionSettings.canSave)

                Button("Cancel") {
                    state.isShowingConnectionSheet = false
                }
                .disabled(state.subscribers.isEmpty && !state.connectionSettings.canSave)
            }
        }
        .padding(24)
        .frame(width: 460)
        .onAppear {
            focusedField = .baseURL
        }
    }
}
