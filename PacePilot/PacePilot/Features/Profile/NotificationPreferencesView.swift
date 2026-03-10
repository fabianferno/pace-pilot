import SwiftUI

struct NotificationPreferencesView: View {
    @StateObject private var notifications = NotificationService.shared

    var body: some View {
        Form {
            if !notifications.isAuthorized {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notifications are disabled")
                            .font(.headline)
                        Text("Enable notifications in Settings to receive workout reminders and updates.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Button("Open Settings") {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                        .foregroundColor(.accentColor)
                    }
                }
            }

            Section("Notification Types") {
                ForEach(NotificationCategory.allCases, id: \.rawValue) { category in
                    Toggle(isOn: Binding(
                        get: { notifications.isEnabled(category) },
                        set: { notifications.setEnabled(category, enabled: $0) }
                    )) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(category.displayName)
                            Text(category.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .disabled(!notifications.isAuthorized)
                }
            }
        }
        .navigationTitle("Notifications")
        .task {
            await notifications.checkAuthorizationStatus()
        }
    }
}

#if DEBUG
#Preview("Notification Preferences") {
    NavigationStack {
        NotificationPreferencesView()
    }
    .preferredColorScheme(.dark)
}
#endif
