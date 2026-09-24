import SwiftUI
import Charts

struct BatteryHistoryView: View {
    let deviceName: String
    let readings: [BatteryReading]

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(deviceName)
                .font(.headline)

            if readings.isEmpty {
                Text(NSLocalizedString("no_history_data", comment: "No battery history yet"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 160, alignment: .center)
            } else {
                Chart(readings) { reading in
                    LineMark(
                        x: .value("Date", reading.date),
                        y: .value("Level", reading.level)
                    )
                    PointMark(
                        x: .value("Date", reading.date),
                        y: .value("Level", reading.level)
                    )
                }
                .chartYScale(domain: 0...100)
                .frame(height: 160)
            }

            Button(NSLocalizedString("close", comment: "Close button")) {
                dismiss()
            }
            .keyboardShortcut(.cancelAction)
        }
        .padding(16)
        .frame(width: 280)
    }
}
