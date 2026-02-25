import Foundation
import IOKit
import Combine
import ServiceManagement
import os

private let logger = Logger(subsystem: "com.jmaudisio.MyMouseBattery", category: "BatteryService")

class BatteryService: ObservableObject {
    static let shared = BatteryService()
    
    @Published var devices: [DeviceBattery] = []
    @Published var lastUpdate: Date?

    private var timer: Timer?
    var onDevicesUpdated: (() -> Void)?

    init() {
        refresh()
        startMonitoring()
    }

    deinit {
        timer?.invalidate()
    }

    func startMonitoring(interval: TimeInterval = 60) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.refresh()
        }
    }

    func refresh() {
        DispatchQueue.global(qos: .background).async { [weak self] in
            let detectedDevices = self?.detectDevices() ?? []
            DispatchQueue.main.async {
                self?.devices = detectedDevices
                self?.lastUpdate = Date()
                self?.onDevicesUpdated?()
            }
        }
    }

    private func detectDevices() -> [DeviceBattery] {
        var devices: [DeviceBattery] = []

        let matchingDict = IOServiceMatching("AppleDeviceManagementHIDEventService")

        var iterator: io_iterator_t = 0
        let result = IOServiceGetMatchingServices(kIOMainPortDefault, matchingDict, &iterator)

        guard result == KERN_SUCCESS else {
            logger.warning("IOKit: Failed to get matching services (result: \(result))")
            return devices
        }

        defer { IOObjectRelease(iterator) }

        var object: io_object_t = IOIteratorNext(iterator)
        while object != 0 {
            defer { IOObjectRelease(object); object = IOIteratorNext(iterator) }

            if let batteryPercent = getBatteryPercent(from: object),
               let productName = getProductName(from: object) {

                let deviceType = determineDeviceType(from: productName)
                let device = DeviceBattery(
                    id: productName.lowercased().replacingOccurrences(of: " ", with: "-"),
                    name: productName,
                    batteryLevel: batteryPercent,
                    deviceType: deviceType
                )
                devices.append(device)
            }
        }

        return devices
    }

    private func getBatteryPercent(from object: io_object_t) -> Int? {
        guard let batteryDict = IORegistryEntryCreateCFProperty(
            object,
            "BatteryPercent" as CFString,
            kCFAllocatorDefault,
            0
        )?.takeRetainedValue() else {
            return nil
        }

        return batteryDict as? Int
    }

    private func getProductName(from object: io_object_t) -> String? {
        guard let productDict = IORegistryEntryCreateCFProperty(
            object,
            "Product" as CFString,
            kCFAllocatorDefault,
            0
        )?.takeRetainedValue() else {
            return nil
        }

        if let productName = productDict as? String {
            return productName
        }

        if let productData = productDict as? Data,
           let productString = String(data: productData, encoding: .utf8) {
            return productString.trimmingCharacters(in: .controlCharacters)
        }

        return nil
    }

    private func determineDeviceType(from productName: String) -> DeviceBattery.DeviceType {
        let lowercaseName = productName.lowercased()

        if lowercaseName.contains("mouse") {
            return .mouse
        } else if lowercaseName.contains("keyboard") {
            return .keyboard
        } else if lowercaseName.contains("trackpad") {
            return .trackpad
        }

        return .unknown
    }
}

class LaunchAtLoginService: ObservableObject {
    @Published var isEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: "launchAtLogin")
            updateLaunchAtLogin()
        }
    }

    init() {
        self.isEnabled = UserDefaults.standard.bool(forKey: "launchAtLogin")
        if #available(macOS 13.0, *) {
            syncWithSystemStatus()
        }
    }

    @available(macOS 13.0, *)
    private func syncWithSystemStatus() {
        if SMAppService.mainApp.status == .enabled {
            isEnabled = true
        }
    }

    private func updateLaunchAtLogin() {
        if #available(macOS 13.0, *) {
            do {
                if isEnabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                logger.error("Error updating launch at login: \(error)")
            }
        }
    }
}
