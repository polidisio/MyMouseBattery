import Foundation

struct DeviceBattery: Identifiable, Equatable {
    let id: String
    let name: String
    let batteryLevel: Int?
    let deviceType: DeviceType

    enum DeviceType: String {
        case mouse = "Magic Mouse"
        case keyboard = "Magic Keyboard"
        case trackpad = "Magic Trackpad"
        case unknown = "Unknown"
    }

    var displayName: String {
        if name.isEmpty {
            return deviceType.rawValue
        }
        return name
    }

    var batteryPercentage: Int {
        batteryLevel ?? 0
    }

    var iconName: String {
        switch deviceType {
        case .mouse:
            return "computermouse.fill"
        case .keyboard:
            return "keyboard.fill"
        case .trackpad:
            return "rectangle.on.rectangle"
        case .unknown:
            return "questionmark.circle"
        }
    }
}
