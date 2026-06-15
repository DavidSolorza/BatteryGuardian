abstract final class BatteryHealthHelper {
  static String healthLabel(int? health) {
    if (health == null) return 'Desconocido';
    return switch (health) {
      2 => 'Buena', // BATTERY_HEALTH_GOOD
      3 => 'Sobrecalentada',
      4 => 'Muerta',
      5 => 'Sobrevoltaje',
      6 => 'Error desconocido',
      7 => 'Fría',
      _ => 'Desconocido',
    };
  }

  static String technologyLabel(String? technology) {
    if (technology == null || technology.isEmpty) return 'N/D';
    return technology;
  }
}
