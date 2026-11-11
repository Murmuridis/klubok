import 'package:flutter/material.dart';

import 'theme.dart';

const craftNames = ['Спицы', 'Крючок'];

const statusNames = ['В работе', 'На паузе', 'Готово', 'В планах'];
const statusColors = <Color>[Wool.rose, Wool.mustard, Wool.sage, Wool.denim];

/// В каком порядке показывать проекты: сначала те, что в работе.
const statusOrder = [0, 1, 3, 2];

class Project {
  Project({
    this.id,
    this.name = '',
    this.craft = 0,
    this.status = 0,
    this.toolSize = '',
    this.gauge = '',
    this.pattern = '',
    this.notes = '',
    this.photo,
    this.createdAt = 0,
    this.updatedAt = 0,
  });

  int? id;
  String name;
  int craft;
  int status;
  String toolSize;
  String gauge;
  String pattern;
  String notes;
  String? photo;
  int createdAt;
  int updatedAt;

  factory Project.fromMap(Map<String, Object?> m) => Project(
        id: m['id'] as int?,
        name: (m['name'] as String?) ?? '',
        craft: (m['craft'] as int?) ?? 0,
        status: (m['status'] as int?) ?? 0,
        toolSize: (m['tool_size'] as String?) ?? '',
        gauge: (m['gauge'] as String?) ?? '',
        pattern: (m['pattern'] as String?) ?? '',
        notes: (m['notes'] as String?) ?? '',
        photo: m['photo'] as String?,
        createdAt: (m['created_at'] as int?) ?? 0,
        updatedAt: (m['updated_at'] as int?) ?? 0,
      );

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'craft': craft,
        'status': status,
        'tool_size': toolSize,
        'gauge': gauge,
        'pattern': pattern,
        'notes': notes,
        'photo': photo,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  Project copy() => Project.fromMap(toMap());

  /// «спицы 4,5 мм» / «крючок».
  String get toolLine {
    final tool = craftNames[craft.clamp(0, 1)].toLowerCase();
    final size = toolSize.trim();
    if (size.isEmpty) return tool;
    final hasUnit = RegExp(r'[a-zа-я]', caseSensitive: false).hasMatch(size);
    return hasUnit ? '$tool $size' : '$tool $size мм';
  }
}

class RowCounter {
  RowCounter({
    this.id,
    required this.projectId,
    this.name = 'Ряды',
    this.value = 0,
    this.target,
    this.repeatEvery,
    this.position = 0,
  });

  int? id;
  int projectId;
  String name;
  int value;

  /// Сколько рядов нужно связать всего (необязательно).
  int? target;

  /// Длина раппорта в рядах (необязательно).
  int? repeatEvery;
  int position;

  factory RowCounter.fromMap(Map<String, Object?> m) => RowCounter(
        id: m['id'] as int?,
        projectId: m['project_id'] as int,
        name: (m['name'] as String?) ?? '',
        value: (m['value'] as int?) ?? 0,
        target: m['target'] as int?,
        repeatEvery: m['repeat_every'] as int?,
        position: (m['position'] as int?) ?? 0,
      );

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'project_id': projectId,
        'name': name,
        'value': value,
        'target': target,
        'repeat_every': repeatEvery,
        'position': position,
      };

  RowCounter copy() => RowCounter.fromMap(toMap());
}

class Yarn {
  Yarn({
    this.id,
    this.brand = '',
    this.name = '',
    this.colorName = '',
    this.color = 0xFFC9737F,
    this.composition = '',
    this.skeinWeight,
    this.skeinLength,
    this.skeins = 1,
    this.lot = '',
    this.toolSize = '',
    this.notes = '',
    this.photo,
    this.createdAt = 0,
    this.updatedAt = 0,
  });

  int? id;
  String brand;
  String name;
  String colorName;

  /// Цвет образца, ARGB.
  int color;
  String composition;

  /// Вес одного мотка, граммы.
  double? skeinWeight;

  /// Длина нити в одном мотке, метры.
  double? skeinLength;

  /// Сколько мотков дома (можно дробно: 2,5).
  double skeins;
  String lot;
  String toolSize;
  String notes;
  String? photo;
  int createdAt;
  int updatedAt;

  factory Yarn.fromMap(Map<String, Object?> m) => Yarn(
        id: m['id'] as int?,
        brand: (m['brand'] as String?) ?? '',
        name: (m['name'] as String?) ?? '',
        colorName: (m['color_name'] as String?) ?? '',
        color: (m['color'] as int?) ?? 0xFFC9737F,
        composition: (m['composition'] as String?) ?? '',
        skeinWeight: (m['skein_weight'] as num?)?.toDouble(),
        skeinLength: (m['skein_length'] as num?)?.toDouble(),
        skeins: (m['skeins'] as num?)?.toDouble() ?? 0,
        lot: (m['lot'] as String?) ?? '',
        toolSize: (m['tool_size'] as String?) ?? '',
        notes: (m['notes'] as String?) ?? '',
        photo: m['photo'] as String?,
        createdAt: (m['created_at'] as int?) ?? 0,
        updatedAt: (m['updated_at'] as int?) ?? 0,
      );

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'brand': brand,
        'name': name,
        'color_name': colorName,
        'color': color,
        'composition': composition,
        'skein_weight': skeinWeight,
        'skein_length': skeinLength,
        'skeins': skeins,
        'lot': lot,
        'tool_size': toolSize,
        'notes': notes,
        'photo': photo,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  Yarn copy() => Yarn.fromMap(toMap());

  /// «Drops Nepal» / «Nepal».
  String get title {
    final b = brand.trim();
    final n = name.trim();
    if (b.isEmpty) return n;
    if (n.isEmpty) return b;
    return '$b $n';
  }

  double? get totalLength => skeinLength == null ? null : skeinLength! * skeins;

  double? get totalWeight => skeinWeight == null ? null : skeinWeight! * skeins;
}

class ProjectYarn {
  ProjectYarn({
    this.id,
    required this.projectId,
    required this.yarnId,
    this.skeins = 1,
  });

  int? id;
  int projectId;
  int yarnId;
  double skeins;

  factory ProjectYarn.fromMap(Map<String, Object?> m) => ProjectYarn(
        id: m['id'] as int?,
        projectId: m['project_id'] as int,
        yarnId: m['yarn_id'] as int,
        skeins: (m['skeins'] as num?)?.toDouble() ?? 1,
      );
}
