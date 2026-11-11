import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'knit.dart';
import 'theme.dart';
import 'util.dart';

/// Спрашивает «камера или галерея», сохраняет копию снимка в папке
/// приложения и возвращает путь к ней. null — если передумали.
Future<String?> pickPhoto(BuildContext context) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Фото', style: Wool.heading),
            const SizedBox(height: 14),
            PillButton(
              label: 'Сфотографировать',
              icon: Icons.photo_camera_outlined,
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            const SizedBox(height: 12),
            PillButton(
              label: 'Выбрать из галереи',
              icon: Icons.photo_library_outlined,
              color: Wool.white,
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    ),
  );
  if (source == null) return null;

  try {
    final picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
    );
    if (picked == null) return null;
    final dir = Directory(p.join(await getDatabasesPath(), 'photos'));
    await dir.create(recursive: true);
    final ext = p.extension(picked.path);
    final dest = p.join(
      dir.path,
      '${DateTime.now().millisecondsSinceEpoch}${ext.isEmpty ? '.jpg' : ext}',
    );
    await File(picked.path).copy(dest);
    return dest;
  } catch (_) {
    if (context.mounted) snack(context, 'Не получилось добавить фото');
    return null;
  }
}

/// Миниатюра: фото, а если его нет — то, что передали в [placeholder].
class PhotoThumb extends StatelessWidget {
  const PhotoThumb({
    super.key,
    required this.path,
    required this.placeholder,
    this.size = 72,
    this.radius = 14,
  });

  final String? path;
  final Widget placeholder;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final path = this.path;
    if (path == null || path.isEmpty) {
      return SizedBox.square(
          dimension: size, child: Center(child: placeholder));
    }
    final px = (size * MediaQuery.devicePixelRatioOf(context)).round();
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.file(
        File(path),
        width: size,
        height: size,
        fit: BoxFit.cover,
        cacheWidth: px,
        errorBuilder: (context, error, stack) => SizedBox.square(
          dimension: size,
          child: Center(child: placeholder),
        ),
      ),
    );
  }
}

/// Большое поле для фото в формах: нажми, чтобы добавить или заменить.
class PhotoField extends StatelessWidget {
  const PhotoField({
    super.key,
    required this.path,
    required this.onPick,
    required this.onRemove,
  });

  final String? path;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final path = this.path;
    final hasPhoto = path != null && path.isNotEmpty;
    return AspectRatio(
      aspectRatio: 16 / 10,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasPhoto)
            GestureDetector(
              onTap: onPick,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.file(
                  File(path),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) =>
                      const ColoredBox(color: Wool.oat),
                ),
              ),
            )
          else
            Patch(
              onTap: onPick,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_a_photo_outlined,
                        size: 34, color: Wool.rose),
                    SizedBox(height: 8),
                    Text('Добавить фото', style: Wool.bodyBold),
                  ],
                ),
              ),
            ),
          if (hasPhoto)
            Positioned(
              top: 8,
              right: 8,
              child: WoolButton(
                color: Wool.berry,
                size: 40,
                label: 'Убрать фото',
                onTap: onRemove,
                child: const Icon(Icons.close),
              ),
            ),
        ],
      ),
    );
  }
}
