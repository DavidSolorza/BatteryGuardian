class DrainSample {
  const DrainSample({required this.level, required this.at});

  final int level;
  final DateTime at;
}

abstract final class BatteryDrainTracker {
  static const int _maxSamples = 8;
  static const Duration _minGap = Duration(minutes: 2);

  static double? ratePerHour(List<DrainSample> samples) {
    if (samples.length < 2) return null;

    final first = samples.first;
    final last = samples.last;
    final minutes = last.at.difference(first.at).inMinutes;
    if (minutes < _minGap.inMinutes) return null;

    final delta = first.level - last.level;
    if (delta <= 0) return null;

    return delta / (minutes / 60.0);
  }

  static List<DrainSample> addSample(
    List<DrainSample> samples,
    int level,
    DateTime at,
  ) {
    final updated = List<DrainSample>.from(samples);
    if (updated.isNotEmpty && updated.last.level == level) {
      return updated;
    }
    updated.add(DrainSample(level: level, at: at));
    while (updated.length > _maxSamples) {
      updated.removeAt(0);
    }
    return updated;
  }
}
