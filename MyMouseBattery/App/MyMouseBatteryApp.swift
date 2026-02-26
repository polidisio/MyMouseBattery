import SwiftUI
import AppKit
import os

private let logger = Logger(subsystem: "com.jmaudisio.MyMouseBattery", category: "App")

@main
struct MyMouseBatteryApp: App {
    @StateObject private var batteryService = BatteryService.shared

    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
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
            DispatchQueue.main.async {
                self?.updateStatusItemImage()
                if let self = self {
                    self.notificationService.checkBatteryLevels(for: self.batteryService.devices)
                }
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

        let lowestLevel = batteryService.devices.compactMap { $0.batteryLevel }.min() ?? 100

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

        let color: NSColor
        if lowestLevel < 15 {
            color = .systemRed
        } else if lowestLevel < 30 {
            color = .systemYellow
        } else {
            color = .labelColor
        }

        var config = NSImage.SymbolConfiguration(pointSize: 16, weight: .regular)
        config = config.applying(.init(paletteColors: [color]))
        if let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "Battery level") {
            button.image = image.withSymbolConfiguration(config)
        }

        if lowestLevel < 100 {
            button.attributedTitle = attributedTitle(for: lowestLevel)
        } else {
            button.title = ""
        }
    }

    private func attributedTitle(for level: Int) -> NSAttributedString {
        let color: NSColor
        if level < 15 {
            color = .systemRed
        } else if level < 30 {
            color = .systemYellow
        } else {
            color = .labelColor
        }

        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: color,
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
            popover.performClose(nil)
        } else {
            if let button = statusItem.button {
                batteryService.refresh()
                if #available(macOS 14.0, *) {
                    NSApp.activate()
                } else {
                    NSApp.activate(ignoringOtherApps: true)
                }
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            }
        }
    }
}
