import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/custom_sound_service.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../providers/alerts_provider.dart';
import '../../../providers/history_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../shared/widgets/responsive_content.dart';
import '../widgets/settings_tile.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  List<SoundOption> _bundledSounds = [];
  List<SoundOption> _localSounds = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SettingsProvider>().refreshServiceStatus();
      _loadSounds();
    });
  }

  Future<void> _loadSounds() async {
    final bundled = await CustomSoundService.listBundledSounds();
    final local = await CustomSoundService.listLocalSounds();
    if (!mounted) return;
    setState(() {
      _bundledSounds = bundled;
      _localSounds = local;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        final colors = context.appColors;
        final textStyles = context.textStyles;

        return ResponsiveContent(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Text('Monitoreo en segundo plano', style: textStyles.headlineMedium),
              const SizedBox(height: 12),
              SettingsTile(
                icon: Icons.sensors,
                title: 'Monitoreo permanente',
                subtitle: settings.serviceRunning
                    ? 'Activo · detecta carga siempre'
                    : 'Inactivo · solo con la app abierta',
                trailing: Switch(
                  value: settings.backgroundMonitoringEnabled,
                  onChanged: settings.setBackgroundMonitoringEnabled,
                ),
              ),
              const SizedBox(height: 8),
              SettingsTile(
                icon: Icons.power,
                title: 'Eventos de carga',
                subtitle: 'Avisar al conectar, desconectar y reconectar',
                trailing: Switch(
                  value: settings.chargingNotificationsEnabled,
                  onChanged: settings.setChargingNotificationsEnabled,
                ),
              ),
              if (!settings.batteryOptimizationIgnored) ...[
                const SizedBox(height: 8),
                SettingsTile(
                  icon: Icons.battery_alert_outlined,
                  title: 'Optimización de batería',
                  subtitle: 'Desactiva restricciones para monitoreo 24/7',
                  trailing: FilledButton(
                    onPressed: settings.requestBatteryOptimizationExemption,
                    child: const Text('Permitir'),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              SettingsTile(
                icon: Icons.verified_user_outlined,
                title: 'Verificar monitoreo',
                subtitle: settings.serviceRunning
                    ? 'Servicio activo y protegido'
                    : 'Toca para reactivar el servicio',
                trailing: FilledButton.tonal(
                  onPressed: settings.ensureBackgroundMonitoring,
                  child: Text(settings.serviceRunning ? 'OK' : 'Activar'),
                ),
              ),
              const SizedBox(height: 8),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(
                  'Consejos para cuidar la batería',
                  style: textStyles.titleMedium,
                ),
                subtitle: Text(
                  'Buenas prácticas recomendadas',
                  style: textStyles.bodyMedium,
                ),
                children: const [
                  _CareTipItem(
                    icon: Icons.battery_3_bar,
                    text: 'Mantén la carga entre 20% y 80% cuando sea posible.',
                  ),
                  _CareTipItem(
                    icon: Icons.thermostat,
                    text: 'Evita cargar con el teléfono muy caliente o al sol.',
                  ),
                  _CareTipItem(
                    icon: Icons.bedtime,
                    text: 'No dejes cargando toda la noche al 100%.',
                  ),
                  _CareTipItem(
                    icon: Icons.timer,
                    text: 'Desconecta al alcanzar tu nivel objetivo.',
                  ),
                  _CareTipItem(
                    icon: Icons.bolt,
                    text: 'Usa cargadores originales o certificados.',
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text('Datos guardados', style: textStyles.headlineMedium),
              const SizedBox(height: 12),
              SettingsTile(
                icon: Icons.history,
                title: 'Borrar historial de cargas',
                subtitle: 'Elimina todas las sesiones registradas',
                onTap: () => _confirmClearHistory(context),
              ),
              const SizedBox(height: 8),
              SettingsTile(
                icon: Icons.notifications_off_outlined,
                title: 'Borrar historial de alertas',
                subtitle: 'Elimina el registro de avisos y eventos',
                onTap: () => _confirmClearAlerts(context),
              ),
              const SizedBox(height: 20),
              Text('Alertas', style: textStyles.headlineMedium),
              const SizedBox(height: 12),
              SettingsTile(
                icon: Icons.notifications_active_outlined,
                title: 'Nivel de carga objetivo',
                subtitle: 'Sonar y vibrar al alcanzar ${settings.alertLevel}%',
                trailing: DropdownButton<int>(
                  value: settings.alertLevel,
                  dropdownColor: colors.cardElevated,
                  underline: const SizedBox.shrink(),
                  items: AppConstants.alertThresholds
                      .map(
                        (level) => DropdownMenuItem(
                          value: level,
                          child: Text('$level%'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) settings.setAlertLevel(value);
                  },
                ),
              ),
              const SizedBox(height: 8),
              SettingsTile(
                icon: Icons.battery_0_bar,
                title: 'Alerta de batería baja',
                subtitle: 'Avisar al bajar de ${settings.lowBatteryLevel}%',
                trailing: Switch(
                  value: settings.lowBatteryAlertEnabled,
                  onChanged: settings.setLowBatteryAlertEnabled,
                ),
              ),
              if (settings.lowBatteryAlertEnabled) ...[
                const SizedBox(height: 8),
                SettingsTile(
                  icon: Icons.battery_alert,
                  title: 'Umbral de batería baja',
                  subtitle: '${settings.lowBatteryLevel}%',
                  trailing: DropdownButton<int>(
                    value: settings.lowBatteryLevel,
                    dropdownColor: colors.cardElevated,
                    underline: const SizedBox.shrink(),
                    items: AppConstants.lowBatteryThresholds
                        .map(
                          (level) => DropdownMenuItem(
                            value: level,
                            child: Text('$level%'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) settings.setLowBatteryLevel(value);
                    },
                  ),
                ),
              ],
              const SizedBox(height: 8),
              SettingsTile(
                icon: Icons.battery_full,
                title: 'Carga completa (100%)',
                subtitle: 'Notificar cuando la batería esté llena',
                trailing: Switch(
                  value: settings.fullChargeAlertEnabled,
                  onChanged: settings.setFullChargeAlertEnabled,
                ),
              ),
              const SizedBox(height: 8),
              SettingsTile(
                icon: Icons.timer_outlined,
                title: 'Carga prolongada',
                subtitle: 'Avisar si sigues conectado al 95%+ por 30 min',
                trailing: Switch(
                  value: settings.overchargeAlertEnabled,
                  onChanged: settings.setOverchargeAlertEnabled,
                ),
              ),
              const SizedBox(height: 8),
              SettingsTile(
                icon: Icons.volume_up_outlined,
                title: 'Sonido de alarma',
                subtitle: 'Reproducir sonido persistente',
                trailing: Switch(
                  value: settings.soundEnabled,
                  onChanged: settings.setSoundEnabled,
                ),
              ),
              const SizedBox(height: 8),
              SettingsTile(
                icon: Icons.vibration,
                title: 'Vibración',
                subtitle: 'Vibrar durante la alarma',
                trailing: Switch(
                  value: settings.vibrationEnabled,
                  onChanged: settings.setVibrationEnabled,
                ),
              ),
              const SizedBox(height: 8),
              SettingsTile(
                icon: Icons.play_circle_outline,
                title: 'Probar alarma',
                subtitle: 'Escucha el sonido seleccionado (3 segundos)',
                trailing: FilledButton.tonal(
                  onPressed: () => context.read<AlertsProvider>().testAlarm(),
                  child: const Text('Probar'),
                ),
              ),
              const SizedBox(height: 8),
              SettingsTile(
                icon: Icons.bedtime_outlined,
                title: 'Horario silencioso',
                subtitle: settings.quietHoursEnabled
                    ? '${settings.quietHoursStart}:00 – ${settings.quietHoursEnd}:00 · sin sonido'
                    : 'Desactivado',
                trailing: Switch(
                  value: settings.quietHoursEnabled,
                  onChanged: settings.setQuietHoursEnabled,
                ),
              ),
              if (settings.quietHoursEnabled) ...[
                const SizedBox(height: 8),
                SettingsTile(
                  icon: Icons.nightlight_outlined,
                  title: 'Inicio silencio',
                  subtitle: '${settings.quietHoursStart}:00',
                  trailing: DropdownButton<int>(
                    value: settings.quietHoursStart,
                    dropdownColor: colors.cardElevated,
                    underline: const SizedBox.shrink(),
                    items: List.generate(
                      24,
                      (h) => DropdownMenuItem(value: h, child: Text('$h:00')),
                    ),
                    onChanged: (v) {
                      if (v != null) settings.setQuietHoursStart(v);
                    },
                  ),
                ),
                const SizedBox(height: 8),
                SettingsTile(
                  icon: Icons.wb_sunny_outlined,
                  title: 'Fin silencio',
                  subtitle: '${settings.quietHoursEnd}:00',
                  trailing: DropdownButton<int>(
                    value: settings.quietHoursEnd,
                    dropdownColor: colors.cardElevated,
                    underline: const SizedBox.shrink(),
                    items: List.generate(
                      24,
                      (h) => DropdownMenuItem(value: h, child: Text('$h:00')),
                    ),
                    onChanged: (v) {
                      if (v != null) settings.setQuietHoursEnd(v);
                    },
                  ),
                ),
              ],
              const SizedBox(height: 8),
              SettingsTile(
                icon: Icons.thermostat,
                title: 'Umbral de temperatura',
                subtitle: '${settings.tempThreshold.toStringAsFixed(0)}°C',
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Slider(
                  value: settings.tempThreshold,
                  min: 35,
                  max: 50,
                  divisions: 15,
                  label: '${settings.tempThreshold.toStringAsFixed(0)}°C',
                  onChanged: settings.setTempThreshold,
                ),
              ),
              const SizedBox(height: 20),
              Text('Apariencia', style: textStyles.headlineMedium),
              const SizedBox(height: 12),
              SettingsTile(
                icon: settings.darkTheme
                    ? Icons.dark_mode_outlined
                    : Icons.light_mode_outlined,
                title: 'Tema oscuro',
                subtitle: settings.darkTheme
                    ? 'Modo oscuro activo'
                    : 'Modo claro activo',
                trailing: Switch(
                  value: settings.darkTheme,
                  onChanged: settings.setDarkTheme,
                ),
              ),
              const SizedBox(height: 8),
              SettingsTile(
                icon: Icons.battery_saver_outlined,
                title: 'Modo ahorro',
                subtitle: settings.powerSavingMode
                    ? 'Actualización cada 15 segundos'
                    : 'Actualización cada 5 segundos',
                trailing: Switch(
                  value: settings.powerSavingMode,
                  onChanged: settings.setPowerSavingMode,
                ),
              ),
              const SizedBox(height: 20),
              Text('Sonido personalizado', style: textStyles.headlineMedium),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Actual: ${CustomSoundService.displayName(settings.customSound)}',
                      style: textStyles.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pon tus archivos en assets/sounds/ antes de compilar, '
                      'o elige uno desde el teléfono.',
                      style: textStyles.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Formatos: MP3, WAV, OGG, M4A, AAC',
                      style: textStyles.labelLarge,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SettingsTile(
                icon: Icons.music_note_outlined,
                title: 'Cambiar sonido',
                subtitle: 'Elegir de la app o del teléfono',
                onTap: () => _showSoundPicker(context, settings),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(
                      settings.serviceRunning
                          ? Icons.check_circle_outline
                          : Icons.info_outline,
                      color: settings.serviceRunning
                          ? colors.primary
                          : colors.textSecondary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        settings.serviceRunning
                            ? 'Battery Guardian v${AppConstants.appVersion}\nMonitoreo activo en segundo plano'
                            : 'Battery Guardian v${AppConstants.appVersion}\nActiva el monitoreo permanente para alertas 24/7',
                        style: textStyles.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmClearHistory(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Borrar historial'),
        content: const Text(
          'Se eliminarán todas las sesiones de carga. Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<HistoryProvider>().clearHistory();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Historial de cargas eliminado')),
        );
      }
    }
  }

  Future<void> _confirmClearAlerts(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Borrar alertas'),
        content: const Text(
          'Se eliminará el historial de alertas y eventos guardados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<AlertsProvider>().clearHistory();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Historial de alertas eliminado')),
        );
      }
    }
  }

  void _showSoundPicker(BuildContext context, SettingsProvider settings) {
    final colors = context.appColors;
    final textStyles = context.textStyles;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: colors.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Text('Seleccionar sonido', style: textStyles.titleLarge),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: Icon(Icons.folder_open, color: colors.primary),
                  title: const Text('Elegir del teléfono'),
                  subtitle: const Text('Copia el archivo a la app'),
                  onTap: () async {
                    Navigator.pop(context);
                    final path = await CustomSoundService.pickFromDevice();
                    if (path != null) {
                      await settings.setCustomSound(path);
                      await _loadSounds();
                    }
                  },
                ),
                if (_bundledSounds.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Incluidos en la app (assets/sounds/)',
                        style: textStyles.labelLarge,
                      ),
                    ),
                  ),
                  ..._bundledSounds.map(
                    (sound) => ListTile(
                      leading: Icon(Icons.library_music, color: colors.primary),
                      title: Text(sound.label),
                      trailing: settings.customSound == sound.path
                          ? Icon(Icons.check, color: colors.primary)
                          : null,
                      onTap: () async {
                        await settings.setCustomSound(sound.path);
                        if (context.mounted) Navigator.pop(context);
                      },
                    ),
                  ),
                ],
                if (_localSounds.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Guardados en el teléfono',
                        style: textStyles.labelLarge,
                      ),
                    ),
                  ),
                  ..._localSounds.map(
                    (sound) => ListTile(
                      leading: Icon(Icons.phone_android, color: colors.primary),
                      title: Text(sound.label),
                      trailing: settings.customSound == sound.path
                          ? Icon(Icons.check, color: colors.primary)
                          : null,
                      onTap: () async {
                        await settings.setCustomSound(sound.path);
                        if (context.mounted) Navigator.pop(context);
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CareTipItem extends StatelessWidget {
  const _CareTipItem({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textStyles = context.textStyles;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: colors.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: textStyles.bodyMedium)),
        ],
      ),
    );
  }
}
