import Foundation

struct BatteryReading: Codable, Identifiable {
    let date: Date
    let level: Int

    var id: Date { date }
}
