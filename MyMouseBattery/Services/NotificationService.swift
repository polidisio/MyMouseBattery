import Foundation
import UserNotifications
import os

private let logger = Logger(subsystem: "com.jmaudisio.MyMouseBattery", category: "NotificationService")

class NotificationService: ObservableObject {
    @Published var notificationThreshold: Int {
        didSet {
            UserDefaults.standard.set(notificationThreshold, forKey: "notificationThreshold")
        }
    }

    @Published var isAuthorized: Bool = true

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
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.isAuthorized = granted
            }
            if let error = error {
                logger.error("Notification authorization error: \(error)")
            }
        }
    }

    func checkBatteryLevels(for devices: [DeviceBattery]) {
        self.devices = devices

        for device in devices {
            guard let level = device.batteryLevel else { continue }

            if level <= notificationThreshold && !notifiedDevices.contains(device.id) {
                sendNotification(for: device)
                notifiedDevices.insert(device.id)
            }

            if level > notificationThreshold {
                notifiedDevices.remove(device.id)
            }
        }
    }

    private func sendNotification(for device: DeviceBattery) {
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("low_battery_title", comment: "Low battery notification title")
        content.body = String(format: NSLocalizedString("low_battery_body", comment: "Low battery notification body"), device.displayName, device.batteryPercentage)
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: device.id,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                logger.error("Failed to send notification: \(error)")
            }
        }
    }

    func resetNotifiedDevices() {
        notifiedDevices.removeAll()
    }
}
