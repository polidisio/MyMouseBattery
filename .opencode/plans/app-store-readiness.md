# Plan: Mac App Store Readiness

## FASE 1: Configuración del proyecto (project.yml + Info.plist)

### 1.1 Cambiar Bundle ID a com.jmaudisio.MagicMouseBattery

**project.yml** - 3 cambios:
- Línea 3: `bundleIdPrefix: com.magicmousebattery` -> `bundleIdPrefix: com.jmaudisio`
- Línea 23: `PRODUCT_BUNDLE_IDENTIFIER: com.magicmousebattery.app` -> `PRODUCT_BUNDLE_IDENTIFIER: com.jmaudisio.MagicMouseBattery`
- Línea 35: `CFBundleIdentifier: com.magicmousebattery.app` -> `CFBundleIdentifier: com.jmaudisio.MagicMouseBattery`

**Info.plist** - 1 cambio:
- Línea 12: `com.magicmousebattery.app` -> `com.jmaudisio.MagicMouseBattery`

### 1.2 Habilitar Hardened Runtime

**project.yml** línea 27:
- `ENABLE_HARDENED_RUNTIME: NO` -> `ENABLE_HARDENED_RUNTIME: YES`

### 1.3 Configurar Code Signing para App Store

**project.yml** líneas 25-26:
- `CODE_SIGN_IDENTITY: "-"` -> `CODE_SIGN_IDENTITY: "Apple Distribution"`
- `CODE_SIGN_STYLE: Manual` -> `CODE_SIGN_STYLE: Automatic`

Agregar nuevo setting:
- `DEVELOPMENT_TEAM: <TU_TEAM_ID>` (el usuario deberá poner su Team ID real)

### 1.4 Agregar NSHumanReadableCopyright

**Info.plist** - agregar antes de `</dict>`:
```xml
<key>NSHumanReadableCopyright</key>
<string>Copyright © 2026 JM Audisio. All rights reserved.</string>
```

**project.yml** - agregar en `info.properties`:
```yaml
NSHumanReadableCopyright: "Copyright © 2026 JM Audisio. All rights reserved."
```

### 1.5 Cambiar developmentRegion a 'es'

**project.yml** - agregar en options:
```yaml
developmentLanguage: es
```

---

## FASE 2: Crear archivo de Entitlements (App Sandbox)

### 2.1 Crear archivo de entitlements

**Nuevo archivo:** `MagicMouseBattery/MagicMouseBattery.entitlements`
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <true/>
</dict>
</plist>
```

### 2.2 Referenciar entitlements en project.yml

**project.yml** - agregar en settings.base del target:
```yaml
CODE_SIGN_ENTITLEMENTS: MagicMouseBattery/MagicMouseBattery.entitlements
```

---

## FASE 3: Bugs funcionales

### 3.1 Corregir device ID (BatteryService.swift)

**BatteryService.swift** línea 65 - Cambiar:
```swift
id: UUID().uuidString,
```
por:
```swift
id: productName.lowercased().replacingOccurrences(of: " ", with: "-"),
```

### 3.2 Eliminar instancia duplicada de NotificationService

**MagicMouseBatteryApp.swift** - Cambios:
1. Eliminar línea 10: `@StateObject private var notificationService = NotificationService()`
2. Eliminar línea 3: `import Combine` (no usado)
3. Eliminar línea 5: `// PR de prueba para issue #3...` (comentario de test)

El struct `MagicMouseBatteryApp` queda:
```swift
@main
struct MagicMouseBatteryApp: App {
    @StateObject private var batteryService = BatteryService.shared

    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
```

### 3.3 Llamar checkBatteryLevels() en onDevicesUpdated

**MagicMouseBatteryApp.swift** - En `applicationDidFinishLaunching`, cambiar el callback:
```swift
batteryService.onDevicesUpdated = { [weak self] in
    DispatchQueue.main.async {
        self?.updateStatusItemImage()
        if let self = self {
            self.notificationService.checkBatteryLevels(for: self.batteryService.devices)
        }
    }
}
```

---

## FASE 4: Reemplazar battery.png con SF Symbol

### 4.1 Cambiar updateStatusItemImage()

**MagicMouseBatteryApp.swift** - Reemplazar el método `updateStatusItemImage()` completo:

```swift
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

    let config = NSImage.SymbolConfiguration(pointSize: 16, weight: .regular)
    if let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "Battery level") {
        button.image = image.withSymbolConfiguration(config)
    }

    if lowestLevel < 100 {
        button.attributedTitle = attributedTitle(for: lowestLevel)
    } else {
        button.title = ""
    }
}
```

---

## FASE 5: Calidad de código

### 5.1 Eliminar comentario de PR de prueba
(Ya incluido en 3.2)

### 5.2 Reemplazar print() con os.Logger

**BatteryService.swift** - Agregar al inicio:
```swift
import os
private let logger = Logger(subsystem: "com.jmaudisio.MagicMouseBattery", category: "BatteryService")
```
Línea 158: `print("Error updating launch at login: \(error)")` -> `logger.error("Error updating launch at login: \(error)")`

Pero como el Logger está fuera de la clase LaunchAtLoginService, hay que agregar un logger propio:
En `LaunchAtLoginService`, agregar:
```swift
private let logger = Logger(subsystem: "com.jmaudisio.MagicMouseBattery", category: "LaunchAtLogin")
```
Y cambiar la línea de print.

**NotificationService.swift** - Agregar al inicio:
```swift
import os
private let logger = Logger(subsystem: "com.jmaudisio.MagicMouseBattery", category: "NotificationService")
```
- Línea 25: `print(...)` -> `logger.error("Notification authorization error: \(error)")`
- Línea 61: `print(...)` -> `logger.error("Failed to send notification: \(error)")`

### 5.3 Eliminar import Combine no usado
(Ya incluido en 3.2)

### 5.4 Corregir NSApp.activate deprecated

**MagicMouseBatteryApp.swift** línea 115 - Cambiar:
```swift
NSApp.activate(ignoringOtherApps: true)
```
por:
```swift
if #available(macOS 14.0, *) {
    NSApp.activate()
} else {
    NSApp.activate(ignoringOtherApps: true)
}
```

### 5.5 Eliminar batteryColor no usada

**DeviceBattery.swift** - Eliminar líneas 27-36:
```swift
var batteryColor: String {
    let level = batteryPercentage
    if level >= 50 {
        return "green"
    } else if level >= 20 {
        return "yellow"
    } else {
        return "red"
    }
}
```

---

## FASE 6: Localización (Español + Inglés)

### 6.1 Crear es.lproj/Localizable.strings

**Nuevo archivo:** `MagicMouseBattery/Resources/es.lproj/Localizable.strings`
```
/* MenuBarView */
"no_devices_detected" = "No se detectaron dispositivos";
"settings" = "Configuración...";
"quit" = "Salir";

/* SettingsView */
"settings_title" = "Configuración";
"launch_at_login" = "Iniciar al arrancar el sistema";
"launch_at_login_description" = "La aplicación se abrirá automáticamente al iniciar sesión";
"low_battery_notification" = "Notificación de batería baja";
"notification_threshold_description" = "Se notificará cuando la batería baje del %d%%";
"reset_notifications" = "Reiniciar notificaciones";
"reset_notifications_description" = "Fuerza el reinicio de las notificaciones para todos los dispositivos";
"close" = "Cerrar";

/* DeviceBatteryView */
"not_detected" = "No detectado";

/* NotificationService */
"low_battery_title" = "Batería Baja";
"low_battery_body" = "%@: %d%% de batería restante";

/* NotificationService - authorization */
"notifications_disabled" = "Notificaciones desactivadas";
"notifications_disabled_description" = "Activa las notificaciones en Preferencias del Sistema para recibir alertas de batería baja";
```

### 6.2 Crear en.lproj/Localizable.strings

**Nuevo archivo:** `MagicMouseBattery/Resources/en.lproj/Localizable.strings`
```
/* MenuBarView */
"no_devices_detected" = "No devices detected";
"settings" = "Settings...";
"quit" = "Quit";

/* SettingsView */
"settings_title" = "Settings";
"launch_at_login" = "Launch at login";
"launch_at_login_description" = "The app will open automatically when you log in";
"low_battery_notification" = "Low battery notification";
"notification_threshold_description" = "You will be notified when battery drops below %d%%";
"reset_notifications" = "Reset notifications";
"reset_notifications_description" = "Force reset notifications for all devices";
"close" = "Close";

/* DeviceBatteryView */
"not_detected" = "Not detected";

/* NotificationService */
"low_battery_title" = "Low Battery";
"low_battery_body" = "%@: %d%% battery remaining";

/* NotificationService - authorization */
"notifications_disabled" = "Notifications disabled";
"notifications_disabled_description" = "Enable notifications in System Settings to receive low battery alerts";
```

### 6.3 Reemplazar strings hardcodeados

Todas las vistas y NotificationService: reemplazar strings literales por `NSLocalizedString("key", comment: "")` o en SwiftUI usar `Text(String(localized: "key"))`.

Ejemplos:
- `Text("No se detectaron dispositivos")` -> `Text(NSLocalizedString("no_devices_detected", comment: ""))`
- `Text("Configuración...")` -> `Text(NSLocalizedString("settings", comment: ""))`
- `content.title = "Batería Baja"` -> `content.title = NSLocalizedString("low_battery_title", comment: "")`

Para strings con formato:
- `"Se notificará cuando la batería baje del \(threshold)%"` -> `String(format: NSLocalizedString("notification_threshold_description", comment: ""), threshold)`
- `"\(device.displayName): \(device.batteryPercentage)% de batería restante"` -> `String(format: NSLocalizedString("low_battery_body", comment: ""), device.displayName, device.batteryPercentage)`

**project.yml** - agregar referencia a lproj:
```yaml
knownRegions:
  - es
  - en
```

---

## FASE 7: Manejo de edge cases

### 7.1 Agregar feedback cuando notificaciones están denegadas

**NotificationService.swift** - Agregar propiedad published:
```swift
@Published var isAuthorized: Bool = true
```

En `requestAuthorization()`, actualizar:
```swift
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
```

**SettingsView.swift** - Agregar banner de aviso si notificaciones están denegadas (antes de la sección del slider):
```swift
if !notificationService.isAuthorized {
    HStack {
        Image(systemName: "exclamationmark.triangle.fill")
            .foregroundColor(.yellow)
        Text(NSLocalizedString("notifications_disabled_description", comment: ""))
            .font(.caption)
    }
    .padding(8)
    .background(Color.yellow.opacity(0.1))
    .cornerRadius(8)
}
```

### 7.2 Agregar logging cuando IOKit falla

**BatteryService.swift** - En `detectDevices()`, cambiar:
```swift
guard result == KERN_SUCCESS else {
    return devices
}
```
por:
```swift
guard result == KERN_SUCCESS else {
    logger.warning("IOKit: Failed to get matching services (result: \(result))")
    return devices
}
```

---

## Archivos modificados (resumen)

| Archivo | Tipo |
|---------|------|
| `project.yml` | Modificado |
| `MagicMouseBattery/Info.plist` | Modificado |
| `MagicMouseBattery/MagicMouseBattery.entitlements` | **Nuevo** |
| `MagicMouseBattery/App/MagicMouseBatteryApp.swift` | Modificado |
| `MagicMouseBattery/Models/DeviceBattery.swift` | Modificado |
| `MagicMouseBattery/Services/BatteryService.swift` | Modificado |
| `MagicMouseBattery/Services/NotificationService.swift` | Modificado |
| `MagicMouseBattery/Views/MenuBarView.swift` | Modificado |
| `MagicMouseBattery/Views/DeviceBatteryView.swift` | Modificado |
| `MagicMouseBattery/Views/SettingsView.swift` | Modificado |
| `MagicMouseBattery/Resources/es.lproj/Localizable.strings` | **Nuevo** |
| `MagicMouseBattery/Resources/en.lproj/Localizable.strings` | **Nuevo** |

## Nota importante: DEVELOPMENT_TEAM

El usuario necesitará agregar su Team ID de Apple Developer en project.yml. Se puede encontrar en:
- https://developer.apple.com/account -> Membership -> Team ID
- O en Xcode -> Signing & Capabilities -> Team

## Nota importante: IOKit + Sandbox

Después de implementar todos los cambios, es IMPRESCINDIBLE probar la app en modo sandbox para verificar que IOKit sigue funcionando. Si no funciona, habrá que investigar alternativas (IOHIDManager, temporary exception entitlement, o distribución fuera del App Store).
