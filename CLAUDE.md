# CLAUDE.md - MagicMouseBattery

## Project Overview

**Name:** MagicMouseBattery (MyMouseBattery)  
**Type:** macOS Menu Bar App (SwiftUI + AppKit)  
**Description:** Menu bar app for monitoring Magic Mouse and Magic Keyboard battery levels in real-time. Shows low battery notifications when levels fall below configurable threshold.  
**Owner:** @polidisio  

## Tech Stack

- **Language:** Swift
- **Framework:** SwiftUI + AppKit
- **Platform:** macOS 12.0+ (Monterey)
- **Architecture:** MVVM
- **System:** IOKit (battery info), UserNotifications
- **Build System:** XcodeGen (project.yml)

## Quick Start

```bash
# Open in Xcode
open MyMouseBattery/MyMouseBattery.xcodeproj

# Build (Cmd+R)
```

## File Structure

```
MagicMouseBattery/
├── MyMouseBattery/
│   └── (Swift source files)
├── MyMouseBattery.xcodeproj
├── project.yml
├── README.md
└── CLAUDE.md
```

## Features

- ✅ Real-time battery monitoring
- ✅ Menu bar status indicator
- ✅ Low battery notifications (configurable 5-50%)
- ✅ Magic Mouse + Magic Keyboard support

## Architecture

- **Menu bar app:** No dock icon
- **Battery info:** IOKit for power source data
- **Notifications:** UserNotifications framework
- **Settings:** UserDefaults for threshold preference

## Important Rules

### ✅ Always Do
- Test on real hardware (Magic Mouse + Keyboard)
- Handle Bluetooth unavailability gracefully

### ❌ Never Do
- Request Bluetooth permissions unnecessarily

## Testing

```bash
# Build via xcodegen
xcodegen generate
xcodebuild -project MyMouseBattery.xcodeproj -scheme MyMouseBattery -configuration Debug build
```

## Resources

- Token optimization tips: `shared/claude-optimization-tips.md` (Obsidian Vault)

---

**Owner:** Jose Maudisio (@polidisio)  
**Last updated:** 2026-04-24

---

---

## Workflow

### Para tareas simples
Sé directo: "Añade validación al form" — no necesitas explicar contexto.

### Para tareas complejas (>3 pasos)
1. Agent propone plan primero
2. Usuario confirma
3. Agent ejecuta
4. Agent verifica con tests

### Para cada tarea
1. **Plan** → Si son >3 pasos, escribir en `tasks/todo.md`
2. **Verify** → Confirmar antes de cambios grandes
3. **Execute** → Cambio más pequeño posible
4. **Test** → Ejecutar tests, verificar regression
5. **Document** → Actualizar si es necesario

---

## Code Quality

### SIEMPRE
- Código legible y mantenible
- Seguir convenciones del proyecto
- DRY — no duplicar lógica
- Validar input antes de procesar

### NUNCA
- Hardcodear credenciales o tokens
- "Hacky fixes" sin justificación
- Duplicar código sin razón
- Commits sin mensaje descriptivo

---

## Security

- **NUNCA hardcodear** credenciales — usar environment variables
- **NUNCA exponer** tokens en logs o errores
- **Validar input** antes de procesar
- Si hay secrets, usar `.env` y nunca commitearlo

---

## Self-Improvement

### Si cometes un error
1. Documentar en `lessons.md` — qué salió mal, por qué, cómo evitarlo
2. Actualizar este archivo si la convención no estaba clara
3. No repetir

### Si descubres algo útil
- Documentar en notas del proyecto
- Compartir con Jose si es relevante

---

## Token Optimization

### Hacer
- Agrupar múltiples requests en uno
- Editar en vez de reply (menos historial)
- Nuevo tema = nueva conversación
- Planificar en chat, construir en workspace

### Evitar
- Subir carpetas enteras — solo archivos necesarios
- Múltiples prompts cortos seguidos
- Usar Opus para tareas simples
- Mantener contexto irrelevante

**Budget:** ~88% de tokens en conversaciones largas = solo historial. Mantenerlo limpio.

---

## Resources

**Obsidian Vault:** `~/Library/Mobile Documents/iCloud~md~obsidian/Documents/Saraiba/`

| Recurso | Ubicación en Vault |
|---------|---------------------|
| Best practices | `shared/coding-best-practices.md` |
| Optimization tips | `shared/claude-optimization-tips.md` |
| Skills docs | `shared/openclw-skills.md` |
| Guía coding agents | `shared/guia-coding-agents.md` |

---

## Contact

**Jose Maudisio** — @polidisio
**Issues:** Abrir en GitHub o preguntar en Telegram
