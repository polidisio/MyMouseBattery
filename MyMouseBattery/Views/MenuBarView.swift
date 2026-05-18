import SwiftUI
import AppKit

struct MenuBarView: View {
    @ObservedObject var batteryService: BatteryService
    @ObservedObject var notificationService: NotificationService
    @ObservedObject var launchAtLoginService: LaunchAtLoginService
    @State private var showingSettings = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let error = batteryService.detectionError {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.yellow)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(8)
                .background(Color.yellow.opacity(0.1))
                .cornerRadius(6)
                .padding(.horizontal, 12)
                .padding(.top, 8)
            }

            if batteryService.devices.isEmpty && batteryService.detectionError == nil {
                Text(NSLocalizedString("no_devices_detected", comment: "Message when no Bluetooth devices found"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
            } else {
                ForEach(batteryService.devices) { device in
                    DeviceBatteryView(device: device)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)

                    if device.id != batteryService.devices.last?.id {
                        Divider()
                            .padding(.horizontal, 12)
                    }
                }
            }

            HStack {
                Text("Battery Status")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Button(action: {
                    batteryService.refresh()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
                .keyboardShortcut("r", modifiers: .command)
                .help("Refresh battery levels")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)

            Divider()
                .padding(.vertical, 4)

            Button(action: {
                showingSettings = true
            }) {
                HStack {
                    Image(systemName: "gearshape")
                    Text(NSLocalizedString("settings", comment: "Settings button"))
                }
            }
            .buttonStyle(.borderless)
            .keyboardShortcut(",", modifiers: .command)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)

            Divider()
                .padding(.vertical, 4)

            Button(action: {
                NSApplication.shared.terminate(nil)
            }) {
                HStack {
                    Image(systemName: "power")
                    Text(NSLocalizedString("quit", comment: "Quit button"))
                }
            }
            .buttonStyle(.borderless)
            .keyboardShortcut("q", modifiers: .command)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
        }
        .frame(width: 260)
        .sheet(isPresented: $showingSettings) {
            SettingsView(notificationService: notificationService, launchAtLoginService: launchAtLoginService)
        }
    }
}
