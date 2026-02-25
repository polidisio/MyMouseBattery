import SwiftUI
import AppKit

struct MenuBarView: View {
    @ObservedObject var batteryService: BatteryService
    @ObservedObject var notificationService: NotificationService
    @ObservedObject var launchAtLoginService: LaunchAtLoginService
    @State private var showingSettings = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if batteryService.devices.isEmpty {
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
