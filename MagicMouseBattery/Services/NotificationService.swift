import Foundation
import UserNotifications

class NotificationService: ObservableObject {
    @Published var notificationThreshold: Int {
        didSet {
            UserDefaults.standard.set(notificationThreshold, forKey: "notificationThreshold")
        }
    }

    private var notifiedDevices: Set<String> = []
    private var devices: [DeviceBattery] = []

    init() {
        self.notificationThreshold = UserDefaults.standard.integer(forKey: "notificationThreshold")
        if notificationThreshold == 0 {
            notificationThreshold = 20
        }
        requestAuthorization()
    }

    private func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification authorization error: \(error)")
            }
        }
    }

    func checkBatteryLevels(for devices: [DeviceBattery]) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.devices = devices

            for device in devices {
                guard let level = device.batteryLevel else { continue }

                if level <= self.notificationThreshold && !self.notifiedDevices.contains(device.id) {
                    self.sendNotification(for: device)
                    self.notifiedDevices.insert(device.id)
                }

                if level > self.notificationThreshold {
                    self.notifiedDevices.remove(device.id)
                }
            }
        }
    }

    private func sendNotification(for device: DeviceBattery) {
        let content = UNMutableNotificationContent()
        content.title = "Batería Baja"
        content.body = "\(device.displayName): \(device.batteryPercentage)% de batería restante"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: device.id,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to send notification: \(error)")
            }
        }
    }

    func resetNotifiedDevices() {
        notifiedDevices.removeAll()
    }
}
