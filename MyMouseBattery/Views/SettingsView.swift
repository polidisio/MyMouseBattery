import SwiftUI

private enum SettingsConfig {
    static let minThreshold = 5
    static let maxThreshold = 50
    static let thresholdStep = 5
}

struct SettingsView: View {
    @ObservedObject var notificationService: NotificationService
    @ObservedObject var launchAtLoginService: LaunchAtLoginService
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(NSLocalizedString("settings_title", comment: "Settings title"))
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }

            VStack(alignment: .leading, spacing: 8) {
                Toggle(NSLocalizedString("launch_at_login", comment: "Launch at login toggle"), isOn: $launchAtLoginService.isEnabled)

                Text(NSLocalizedString("launch_at_login_description", comment: "Launch at login description"))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text(NSLocalizedString("low_battery_notification", comment: "Low battery notification section title"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                if !notificationService.isAuthorized {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.yellow)
                        Text(NSLocalizedString("notifications_disabled_description", comment: "Notifications disabled warning"))
                            .font(.caption)
                    }
                    .padding(8)
                    .background(Color.yellow.opacity(0.1))
                    .cornerRadius(8)
                }

                HStack {
                    Slider(
                        value: Binding(
                            get: { Double(notificationService.notificationThreshold) },
                            set: { notificationService.notificationThreshold = Int($0.rounded()) }
                        ),
                        in: Double(SettingsConfig.minThreshold)...Double(SettingsConfig.maxThreshold),
                        step: Double(SettingsConfig.thresholdStep)
                    )

                    Text("\(notificationService.notificationThreshold)%")
                        .font(.system(.body, design: .monospaced))
                        .frame(width: 40)
                }

                Text(String(format: NSLocalizedString("notification_threshold_description", comment: "Notification threshold description"), notificationService.notificationThreshold))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Button(NSLocalizedString("reset_notifications", comment: "Reset notifications button")) {
                    notificationService.resetNotifiedDevices()
                }
                .buttonStyle(.borderless)

                Text(NSLocalizedString("reset_notifications_description", comment: "Reset notifications description"))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider()

            Button(NSLocalizedString("close", comment: "Close button")) {
                dismiss()
            }
            .buttonStyle(.bordered)

            Spacer()
        }
        .padding()
        .frame(width: 280)
    }
}
