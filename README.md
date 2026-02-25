# Input Battery

Menu bar app para monitorear la batería de Mouse y Keyboard en macOS.

## Funcionalidades

- **Monitorización en tiempo real** de la batería del Mouse y Keyboard
- **Notificaciones** cuando la batería baja del umbral configurado
- **Menú bar** con indicador visual del nivel de batería
- **Configuración editable** del umbral de notificación (5-50%)

## Requisitos

- macOS 12.0 (Monterey) o superior
- Xcode 15.0 o superior

## Instalación

1. Clona el repositorio:
   ```bash
   git clone https://github.com/polidisio/MyMouseBattery.git
   ```

2. Abre el proyecto en Xcode:
   ```bash
   open MyMouseBattery/MyMouseBattery.xcodeproj
   ```

3. Compila y ejecuta (Cmd + R)

## Uso

- La app aparece como un icono en la barra de menú
- Haz clic para ver los niveles de batería de los dispositivos conectados
- Configura el umbral de notificación en Configuración > Notificación de batería baja

## Configuración

El umbral de notificación se guarda en las preferencias del usuario y se puede ajustar entre 5% y 50%.

## Tecnologías

- SwiftUI
- AppKit
- IOKit
- UserNotifications
