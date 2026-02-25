import SwiftUI

struct DeviceBatteryView: View {
    let device: DeviceBattery

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
        }
        .padding(.vertical, 4)
    }

    private var batteryColor: Color {
        let level = device.batteryPercentage
        if level >= 50 {
            return .green
        } else if level >= 20 {
            return .yellow
        } else {
            return .red
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
        if level >= 50 {
            return .green
        } else if level >= 20 {
            return .yellow
        } else {
            return .red
        }
    }
}
