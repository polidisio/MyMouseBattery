import SwiftUI

struct DeviceBatteryView: View {
    let device: DeviceBattery
    let history: [BatteryReading]

    @State private var showingHistory = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: device.iconName)
                .font(.title2)
                .foregroundColor(batteryColor)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(device.displayName)
                    .font(.headline)
                    .foregroundColor(.primary)

                if let level = device.batteryLevel {
                    HStack(spacing: 6) {
                        BatteryLevelIndicator(level: level)
                        Text("\(level)%")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text(NSLocalizedString("not_detected", comment: "Battery level not detected"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Button(action: { showingHistory = true }) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.borderless)
            .help(NSLocalizedString("view_history", comment: "View battery history"))
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $showingHistory) {
            BatteryHistoryView(deviceName: device.displayName, readings: history)
        }
    }

    private var batteryColor: Color {
        switch DeviceBattery.batteryCategory(for: device.batteryLevel) {
        case .critical: return .red
        case .warning: return .yellow
        case .normal: return .green
        case .unknown: return .secondary
        }
    }
}

struct BatteryLevelIndicator: View {
    let level: Int

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.gray.opacity(0.3))

                RoundedRectangle(cornerRadius: 2)
                    .fill(fillColor)
                    .frame(width: geometry.size.width * CGFloat(level) / 100)
            }
        }
        .frame(width: 60, height: 8)
    }

    private var fillColor: Color {
        switch DeviceBattery.batteryCategory(for: level) {
        case .critical: return .red
        case .warning: return .yellow
        default: return .green
        }
    }
}
