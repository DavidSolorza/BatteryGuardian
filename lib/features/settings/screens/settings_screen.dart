import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../providers/settings_provider.dart';
import '../widgets/settings_tile.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SettingsProvider>().refreshServiceStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Monitoreo en segundo plano', style: AppTextStyles.headlineMedium),
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
            const SizedBox(height: 20),
            Text('Alertas', style: AppTextStyles.headlineMedium),
            const SizedBox(height: 12),
            SettingsTile(
              icon: Icons.notifications_active_outlined,
              title: 'Nivel de carga objetivo',
              subtitle: 'Sonar y vibrar al alcanzar ${settings.alertLevel}%',
              trailing: DropdownButton<int>(
                value: settings.alertLevel,
                dropdownColor: AppColors.cardElevated,
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
            Text('Preferencias', style: AppTextStyles.headlineMedium),
            const SizedBox(height: 12),
            SettingsTile(
              icon: Icons.dark_mode_outlined,
              title: 'Tema oscuro',
              subtitle: 'Interfaz optimizada para batería',
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
            const SizedBox(height: 8),
            SettingsTile(
              icon: Icons.music_note_outlined,
              title: 'Sonido personalizado',
              subtitle: settings.customSound.split('/').last,
              onTap: () => _showSoundPicker(context, settings),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(
                    settings.serviceRunning
                        ? Icons.check_circle_outline
                        : Icons.info_outline,
                    color: settings.serviceRunning
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      settings.serviceRunning
                          ? 'Battery Guardian v1.1.0\nMonitoreo activo en segundo plano'
                          : 'Battery Guardian v1.1.0\nActiva el monitoreo permanente para alertas 24/7',
                      style: AppTextStyles.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSoundPicker(BuildContext context, SettingsProvider settings) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Alarma predeterminada'),
                trailing: settings.customSound.contains('alarm.wav')
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () {
                  settings.setCustomSound('assets/sounds/alarm.wav');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
