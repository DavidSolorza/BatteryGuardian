import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class SoundOption {
  const SoundOption({
    required this.path,
    required this.label,
    required this.isLocal,
  });

  final String path;
  final String label;
  final bool isLocal;
}

abstract final class CustomSoundService {
  static const String localPrefix = 'local:';
  static const List<String> audioExtensions = ['mp3', 'wav', 'ogg', 'm4a', 'aac'];

  static Future<List<SoundOption>> listBundledSounds() async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final assets = manifest
        .listAssets()
        .where(
          (asset) =>
              asset.startsWith('assets/sounds/') &&
              _isAudioFile(asset),
        )
        .toList()
      ..sort();

    return assets
        .map(
          (asset) => SoundOption(
            path: asset,
            label: p.basename(asset),
            isLocal: false,
          ),
        )
        .toList();
  }

  static Future<List<SoundOption>> listLocalSounds() async {
    final dir = await _customSoundsDir();
    if (!await dir.exists()) return [];

    final files = await dir
        .list()
        .where((entity) => entity is File && _isAudioFile(entity.path))
        .cast<File>()
        .toList();
    files.sort((a, b) => a.path.compareTo(b.path));

    return files
        .map(
          (file) => SoundOption(
            path: '$localPrefix${file.path}',
            label: p.basename(file.path),
            isLocal: true,
          ),
        )
        .toList();
  }

  static Future<String?> pickFromDevice() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: audioExtensions,
    );

    final pickedPath = result?.files.single.path;
    if (pickedPath == null) return null;

    final source = File(pickedPath);
    final dir = await _customSoundsDir();
    final fileName = p.basename(pickedPath);
    final destination = File(p.join(dir.path, fileName));

    if (await destination.exists()) {
      await destination.delete();
    }
    await source.copy(destination.path);

    return '$localPrefix${destination.path}';
  }

  static String displayName(String path) {
    if (path.startsWith(localPrefix)) {
      return p.basename(path.substring(localPrefix.length));
    }
    return p.basename(path);
  }

  static bool isLocalPath(String path) => path.startsWith(localPrefix);

  static String localFilePath(String path) =>
      path.substring(localPrefix.length);

  static Future<Directory> _customSoundsDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(appDir.path, 'custom_sounds'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static bool _isAudioFile(String path) {
    final ext = p.extension(path).replaceFirst('.', '').toLowerCase();
    return audioExtensions.contains(ext);
  }
}
