# Battery Guardian

Aplicación Flutter profesional para monitoreo inteligente de batería y salud del dispositivo Android.

## Características

- **Dashboard en tiempo real**: porcentaje, estado de carga, temperatura, voltaje y tiempo conectado
- **Alertas inteligentes**: umbrales al 80%, 90% y 95%, alertas por temperatura alta
- **Historial de cargas**: registro automático en SQLite
- **Analíticas**: estadísticas y gráficas semanales/mensuales con fl_chart
- **Configuración**: nivel de alerta, sonido, vibración, tema oscuro y modo ahorro

## Dependencias

| Paquete | Uso |
|---------|-----|
| `provider` | Gestión de estado |
| `battery_plus` | Nivel y estado de batería |
| `flutter_local_notifications` | Notificaciones locales |
| `audioplayers` | Alarma sonora persistente |
| `vibration` | Vibración durante alertas |
| `sqflite` | Base de datos local |
| `fl_chart` | Gráficas |
| `shared_preferences` | Preferencias de usuario |
| `google_fonts` | Tipografía Inter |
| `intl` | Formato de fechas en español |
| `permission_handler` | Permisos Android |
| `path_provider` | Rutas de almacenamiento |

## Estructura del proyecto

```
lib/
├── main.dart
├── core/           # Tema, constantes, servicios, utilidades
├── database/       # SQLite
├── features/       # Dashboard, alertas, historial, analíticas, ajustes
├── shared/         # Widgets reutilizables
└── providers/      # Estado global con Provider
```

## Requisitos previos

1. **Flutter SDK** (3.35+): [https://docs.flutter.dev/get-started/install](https://docs.flutter.dev/get-started/install)
2. **Android Studio** o Android SDK con `platform-tools`
3. **Dispositivo Android físico** con depuración USB habilitada
4. **Cable USB** de datos (no solo carga)

## Ejecutar en dispositivo Android físico

### Paso 1: Activar opciones de desarrollador

1. Abre **Ajustes** → **Acerca del teléfono**
2. Toca **Número de compilación** 7 veces
3. Aparecerá el mensaje "Ya eres desarrollador"

### Paso 2: Activar depuración USB

1. Ve a **Ajustes** → **Opciones de desarrollador**
2. Activa **Depuración USB**
3. (Opcional) Activa **Instalar vía USB** si tu fabricante lo requiere

### Paso 3: Conectar el teléfono

1. Conecta el teléfono al PC con cable USB
2. En el teléfono, acepta el diálogo **¿Permitir depuración USB?**
3. Marca **Permitir siempre desde este equipo**

### Paso 4: Verificar que Flutter detecta el dispositivo

```powershell
cd D:\escritorio\battery_guardian
flutter doctor
flutter devices
```

Debes ver tu dispositivo listado (ejemplo: `SM G991B • android-arm64 • Android 14`).

### Paso 5: Instalar dependencias

```powershell
flutter pub get
```

### Paso 6: Ejecutar la aplicación

```powershell
flutter run
```

Si tienes varios dispositivos conectados, especifica el ID:

```powershell
flutter run -d <device_id>
```

### Paso 7: Permisos en el dispositivo

Al abrir la app por primera vez:

1. Acepta el permiso de **notificaciones** (Android 13+)
2. Conecta el cargador para probar el monitoreo y las alertas
3. Completa el onboarding inicial

## Permisos Android configurados

- `VIBRATE` — vibración en alertas
- `POST_NOTIFICATIONS` — notificaciones locales (Android 13+)
- `WAKE_LOCK` — mantener alertas activas
- `RECEIVE_BOOT_COMPLETED` — preparado para futuros servicios en segundo plano

## Canal nativo Android

La app usa un `MethodChannel` (`com.batteryguardian/battery`) para leer temperatura y voltaje desde `BatteryManager`, datos no expuestos directamente por `battery_plus`.

## Build de release (Google Play)

```powershell
flutter build appbundle --release
```

El archivo `.aab` se genera en `build/app/outputs/bundle/release/`.

## Solución de problemas

| Problema | Solución |
|----------|----------|
| `No devices found` | Revisa cable USB, drivers ADB y depuración USB |
| `Unauthorized` | Revoca autorizaciones USB en opciones de desarrollador y reconecta |
| Notificaciones no aparecen | Concede permiso de notificaciones en Ajustes → Apps → Battery Guardian |
| Temperatura muestra N/D | Algunos dispositivos no exponen el sensor vía BatteryManager |

## Licencia

Proyecto privado — Battery Guardian v1.0.0
