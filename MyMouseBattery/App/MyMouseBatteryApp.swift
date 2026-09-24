import SwiftUI
import AppKit
import os

private let logger = Logger(subsystem: "com.jmaudisio.MyMouseBattery", category: "App")

@main
struct MyMouseBatteryApp: App {
    @StateObject private var batteryService = BatteryService.shared

    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // SwiftUI requires a non-empty Scene body; this LSUIElement app has no
        // app menu to host it, so it's unreachable, kept only to satisfy the type.
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    var popover: NSPopover!
    var statusItem: NSStatusItem!

    private let batteryService = BatteryService.shared
    private let notificationService = NotificationService()
    private let launchAtLoginService = LaunchAtLoginService()

    override init() {
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        setupPopover()

        batteryService.notificationService = notificationService

        batteryService.startMonitoring(interval: 60)

        batteryService.onDevicesUpdated = { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.updateStatusItemImage()
            }
        }
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            updateStatusItemImage()
            button.action = #selector(togglePopover)
            button.target = self
        }
    }

    private func updateStatusItemImage() {
        guard let button = statusItem.button else { return }

        let levels = batteryService.devices.compactMap { $0.batteryLevel }

        guard let lowestLevel = levels.min() else {
            var config = NSImage.SymbolConfiguration(pointSize: 16, weight: .regular)
            config = config.applying(.init(paletteColors: [.secondaryLabelColor]))
            if let image = NSImage(systemSymbolName: "questionmark.circle", accessibilityDescription: "No battery data") {
                button.image = image.withSymbolConfiguration(config)
            }
            button.title = ""
            return
        }

        let symbolName: String
        if lowestLevel > 75 {
            symbolName = "battery.100"
        } else if lowestLevel > 50 {
            symbolName = "battery.75"
        } else if lowestLevel > 25 {
            symbolName = "battery.50"
        } else if lowestLevel > 10 {
            symbolName = "battery.25"
        } else {
            symbolName = "battery.0"
        }

        var config = NSImage.SymbolConfiguration(pointSize: 16, weight: .regular)
        config = config.applying(.init(paletteColors: [nsColor(for: lowestLevel)]))
        if let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "Battery level") {
            button.image = image.withSymbolConfiguration(config)
        }
        button.attributedTitle = attributedTitle(for: lowestLevel)
    }

    private func nsColor(for level: Int) -> NSColor {
        switch DeviceBattery.batteryCategory(for: level) {
        case .critical: return .systemRed
        case .warning: return .systemYellow
        default: return .labelColor
        }
    }

    private func attributedTitle(for level: Int) -> NSAttributedString {
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: nsColor(for: level),
            .font: NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium)
        ]

        return NSAttributedString(string: "\(level)%", attributes: attributes)
    }

    private func setupPopover() {
        popover = NSPopover()
        popover.contentSize = NSSize(width: 260, height: 300)
        popover.behavior = .transient
        popover.delegate = self

        let menuBarView = MenuBarView(
            batteryService: batteryService,
            notificationService: notificationService,
            launchAtLoginService: launchAtLoginService
        )
        popover.contentViewController = NSHostingController(rootView: menuBarView)
    }

    @objc func togglePopover() {
        if popover.isShown {
            batteryService.setPopoverVisible(false)
            popover.performClose(nil)
        } else {
            if let button = statusItem.button {
                batteryService.setPopoverVisible(true)
                launchAtLoginService.syncWithSystemStatus()
                NSApp.activate()
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            }
        }
    }
}
