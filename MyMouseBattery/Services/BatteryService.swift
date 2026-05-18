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
    @Published var detectionError: String?

    private static let defaultMonitoringInterval: TimeInterval = 60
    private static let hiddenMonitoringInterval: TimeInterval = 300
    private let devicesQueue = DispatchQueue(label: "com.jmaudisio.MyMouseBattery.devicesQueue")

    private var timer: Timer?
    private var isRefreshing = false
    private(set) var isPopoverVisible = false
    var onDevicesUpdated: (() -> Void)?
    weak var notificationService: NotificationService?

    init() {
        refresh()
        startMonitoring()
    }

    func setPopoverVisible(_ visible: Bool) {
        isPopoverVisible = visible
        if visible {
            refresh()
        }
        restartTimer()
    }

    private func restartTimer() {
        let interval = isPopoverVisible ? Self.defaultMonitoringInterval : Self.hiddenMonitoringInterval
        startMonitoring(interval: interval)
    }

    func startMonitoring(interval: TimeInterval = defaultMonitoringInterval) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.refresh()
        }
    }

    func refresh() {
        guard !isRefreshing else { return }
        isRefreshing = true

        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            let (detectedDevices, error) = Self.detectDevices()
            self.devicesQueue.async {
                let devicesToNotify = detectedDevices
                DispatchQueue.main.async {
                    self.devices = devicesToNotify
                    self.detectionError = error
                    self.lastUpdate = Date()
                    self.isRefreshing = false
                    self.onDevicesUpdated?()
                    self.notificationService?.checkBatteryLevels(for: devicesToNotify)
                }
            }
        }
    }

    private static func detectDevices() -> ([DeviceBattery], String?) {
        var devices: [DeviceBattery] = []
        var error: String?

        let matchingDict = IOServiceMatching("AppleDeviceManagementHIDEventService")

        var iterator: io_iterator_t = 0
        let result = IOServiceGetMatchingServices(kIOMainPortDefault, matchingDict, &iterator)

        guard result == KERN_SUCCESS else {
            let errorMsg = "Could not access Bluetooth devices. Please check Bluetooth is enabled."
            logger.error("IOKit: IOServiceGetMatchingServices failed: \(Self.kernReturnToString(result))")
            return (devices, errorMsg)
        }

        defer { IOObjectRelease(iterator) }

        var object: io_object_t = IOIteratorNext(iterator)
        while object != 0 {
            defer { IOObjectRelease(object); object = IOIteratorNext(iterator) }

            if let batteryPercent = Self.getBatteryPercent(from: object),
               let productName = Self.getProductName(from: object) {

                let deviceType = Self.determineDeviceType(from: productName)
                let device = DeviceBattery(
                    id: productName.lowercased().replacingOccurrences(of: " ", with: "-"),
                    name: productName,
                    batteryLevel: batteryPercent,
                    deviceType: deviceType
                )
                devices.append(device)
            }
        }

        if devices.isEmpty {
            error = "No battery devices found. Make sure your Magic Mouse/Keyboard is connected."
        }

        return (devices, error)
    }

    private static func kernReturnToString(_ result: kern_return_t) -> String {
        switch result {
        case KERN_SUCCESS: return "Success"
        case KERN_INVALID_ADDRESS: return "Invalid address"
        case KERN_PROTECTION_FAILURE: return "Protection failure"
        case KERN_NO_SPACE: return "No space"
        case KERN_INVALID_ARGUMENT: return "Invalid argument"
        case KERN_FAILURE: return "Failure"
        case KERN_RESOURCE_SHORTAGE: return "Resource shortage"
        default: return "Unknown (\(result))"
        }
    }

    private static func getBatteryPercent(from object: io_object_t) -> Int? {
        guard let batteryValue = IORegistryEntryCreateCFProperty(
            object,
            "BatteryPercent" as CFString,
            kCFAllocatorDefault,
            0
        )?.takeRetainedValue() else {
            return nil
        }

        if let intValue = batteryValue as? Int {
            return intValue
        }
        if let doubleValue = batteryValue as? Double {
            return Int(doubleValue)
        }
        logger.warning("BatteryPercent: unexpected type \(type(of: batteryValue))")
        return nil
    }

    private static func getProductName(from object: io_object_t) -> String? {
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

    private static func determineDeviceType(from productName: String) -> DeviceBattery.DeviceType {
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

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
}

class LaunchAtLoginService: ObservableObject {
    private static let launchAtLoginHasBeenSetKey = "launchAtLoginHasBeenSet"

    @Published var isEnabled: Bool {
        didSet {
            guard oldValue != isEnabled else { return }
            UserDefaults.standard.set(isEnabled, forKey: "launchAtLogin")
            UserDefaults.standard.set(true, forKey: Self.launchAtLoginHasBeenSetKey)
            updateLaunchAtLogin()
        }
    }

    init() {
        let hasExplicitPreference = UserDefaults.standard.object(forKey: Self.launchAtLoginHasBeenSetKey) != nil
        let storedValue = UserDefaults.standard.bool(forKey: "launchAtLogin")

        if #available(macOS 13.0, *) {
            let systemEnabled = SMAppService.mainApp.status == .enabled
            if hasExplicitPreference {
                self.isEnabled = storedValue
            } else {
                self.isEnabled = systemEnabled
                if systemEnabled {
                    UserDefaults.standard.set(true, forKey: Self.launchAtLoginHasBeenSetKey)
                }
            }
        } else {
            let legacyEnabled = Self.isLegacyLaunchAtLoginEnabled()
            self.isEnabled = hasExplicitPreference ? storedValue : legacyEnabled
        }
    }

    @available(macOS 13.0, *)
    private func syncWithSystemStatus() {
        if SMAppService.mainApp.status == .enabled && UserDefaults.standard.object(forKey: Self.launchAtLoginHasBeenSetKey) == nil {
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
        } else {
            Self.setLegacyLaunchAtLogin(enabled: isEnabled)
        }
    }

    private static func isLegacyLaunchAtLoginEnabled() -> Bool {
        if let bundleIdentifier = Bundle.main.bundleIdentifier {
            return SMLoginItemSetEnabled(bundleIdentifier as CFString, false)
        }
        return false
    }

    private static func setLegacyLaunchAtLogin(enabled: Bool) {
        if let bundleIdentifier = Bundle.main.bundleIdentifier {
            SMLoginItemSetEnabled(bundleIdentifier as CFString, enabled)
        }
    }
}
