import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'models.dart';

/// Все данные приложения: SQLite + копия в памяти для экранов.
class Store extends ChangeNotifier {
  Store._();

  static final Store instance = Store._();

  late Database _db;
  Future<void>? _initFuture;

  /// Какая вкладка открыта: 0 — счётчик, 1 — проекты, 2 — пряжа.
  final ValueNotifier<int> tab = ValueNotifier<int>(0);

  List<Project> projects = [];
  List<RowCounter> counters = [];
  List<Yarn> yarns = [];
  List<ProjectYarn> links = [];
  final Map<String, String> _settings = {};

  /// Очередь записи значений счётчика, чтобы быстрые нажатия шли по порядку.
  Future<void> _queue = Future<void>.value();

  Future<void> init() {
    return _initFuture ??= _open().then<void>(
      (_) {},
      onError: (Object error, StackTrace stack) {
        _initFuture = null; // чтобы можно было попробовать ещё раз
        Error.throwWithStackTrace(error, stack);
      },
    );
  }

  Future<void> _open() async {
    final dir = await getDatabasesPath();
    _db = await openDatabase(
      p.join(dir, 'klubok.db'),
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _create,
    );
    await _reload(notify: false);
  }

  static Future<void> _create(Database db, int version) async {
    await db.execute('''
      CREATE TABLE projects(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        craft INTEGER NOT NULL DEFAULT 0,
        status INTEGER NOT NULL DEFAULT 0,
        tool_size TEXT NOT NULL DEFAULT '',
        gauge TEXT NOT NULL DEFAULT '',
        pattern TEXT NOT NULL DEFAULT '',
        notes TEXT NOT NULL DEFAULT '',
        photo TEXT,
        created_at INTEGER NOT NULL DEFAULT 0,
        updated_at INTEGER NOT NULL DEFAULT 0
      )''');
    await db.execute('''
      CREATE TABLE counters(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        project_id INTEGER NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
        name TEXT NOT NULL,
        value INTEGER NOT NULL DEFAULT 0,
        target INTEGER,
        repeat_every INTEGER,
        position INTEGER NOT NULL DEFAULT 0
      )''');
    await db.execute('''
      CREATE TABLE yarns(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        brand TEXT NOT NULL DEFAULT '',
        name TEXT NOT NULL DEFAULT '',
        color_name TEXT NOT NULL DEFAULT '',
        color INTEGER NOT NULL DEFAULT 0,
        composition TEXT NOT NULL DEFAULT '',
        skein_weight REAL,
        skein_length REAL,
        skeins REAL NOT NULL DEFAULT 0,
        lot TEXT NOT NULL DEFAULT '',
        tool_size TEXT NOT NULL DEFAULT '',
        notes TEXT NOT NULL DEFAULT '',
        photo TEXT,
        created_at INTEGER NOT NULL DEFAULT 0,
        updated_at INTEGER NOT NULL DEFAULT 0
      )''');
    await db.execute('''
      CREATE TABLE project_yarns(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        project_id INTEGER NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
        yarn_id INTEGER NOT NULL REFERENCES yarns(id) ON DELETE CASCADE,
        skeins REAL NOT NULL DEFAULT 1,
        UNIQUE(project_id, yarn_id)
      )''');
    await db.execute('''
      CREATE TABLE settings(
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )''');
    await db
        .execute('CREATE INDEX idx_counters_project ON counters(project_id)');
  }

  Future<void> _reload({bool notify = true}) async {
    await _queue;
    final projectRows = await _db.query('projects');
    final counterRows = await _db.query('counters', orderBy: 'position, id');
    final yarnRows = await _db.query('yarns');
    final linkRows = await _db.query('project_yarns', orderBy: 'id');
    final settingRows = await _db.query('settings');

    projects = projectRows.map(Project.fromMap).toList()
      ..sort((a, b) {
        final s = statusOrder
            .indexOf(a.status)
            .compareTo(statusOrder.indexOf(b.status));
        return s != 0 ? s : b.updatedAt.compareTo(a.updatedAt);
      });
    counters = counterRows.map(RowCounter.fromMap).toList();
    yarns = yarnRows.map(Yarn.fromMap).toList()
      ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    links = linkRows.map(ProjectYarn.fromMap).toList();
    _settings
      ..clear()
      ..addEntries(settingRows
          .map((r) => MapEntry(r['key'] as String, r['value'] as String)));
    if (notify) notifyListeners();
  }

  static int get _now => DateTime.now().millisecondsSinceEpoch;

  // ---------- настройки ----------

  bool flag(String key, {bool fallback = true}) {
    final v = _settings[key];
    return v == null ? fallback : v == '1';
  }

  Future<void> setFlag(String key, bool value) =>
      _setSetting(key, value ? '1' : '0');

  Future<void> _setSetting(String key, String value) async {
    _settings[key] = value;
    notifyListeners();
    await _db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ---------- что сейчас вяжем ----------

  Project? projectById(int? id) {
    if (id == null) return null;
    for (final x in projects) {
      if (x.id == id) return x;
    }
    return null;
  }

  Yarn? yarnById(int? id) {
    if (id == null) return null;
    for (final x in yarns) {
      if (x.id == id) return x;
    }
    return null;
  }

  Project? get currentProject {
    if (projects.isEmpty) return null;
    final saved = projectById(int.tryParse(_settings['current_project'] ?? ''));
    return saved ?? projects.first;
  }

  List<RowCounter> countersOf(int projectId) =>
      counters.where((c) => c.projectId == projectId).toList();

  RowCounter? currentCounter(Project project) {
    final list = countersOf(project.id!);
    if (list.isEmpty) return null;
    final savedId = int.tryParse(_settings['counter_${project.id}'] ?? '');
    for (final c in list) {
      if (c.id == savedId) return c;
    }
    return list.first;
  }

  Future<void> selectProject(int id) => _setSetting('current_project', '$id');

  Future<void> selectCounter(RowCounter c) =>
      _setSetting('counter_${c.projectId}', '${c.id}');

  /// Открыть счётчик этого проекта на первой вкладке.
  void openCounter(Project project) {
    selectProject(project.id!);
    tab.value = 0;
  }

  // ---------- проекты ----------

  Future<int> saveProject(Project project) async {
    project.updatedAt = _now;
    if (project.id == null) {
      project.createdAt = project.updatedAt;
      final id = await _db.insert('projects', project.toMap());
      project.id = id;
      await _db.insert(
        'counters',
        RowCounter(projectId: id, name: 'Ряды').toMap(),
      );
    } else {
      await _db.update(
        'projects',
        project.toMap(),
        where: 'id = ?',
        whereArgs: [project.id],
      );
    }
    await _reload();
    return project.id!;
  }

  Future<void> setProjectStatus(Project project, int status) async {
    await _db.update(
      'projects',
      {'status': status, 'updated_at': _now},
      where: 'id = ?',
      whereArgs: [project.id],
    );
    await _reload();
  }

  Future<void> deleteProject(Project project) async {
    await _db.delete('projects', where: 'id = ?', whereArgs: [project.id]);
    await _db.delete(
      'settings',
      where: 'key = ?',
      whereArgs: ['counter_${project.id}'],
    );
    _deleteFile(project.photo);
    await _reload();
  }

  // ---------- счётчики ----------

  /// Мгновенно меняет значение на экране, в базу пишет следом.
  void setCounterValue(RowCounter counter, int value) {
    if (value < 0) return;
    for (final c in counters) {
      if (c.id == counter.id) c.value = value;
    }
    counter.value = value;
    notifyListeners();
    final id = counter.id;
    _queue = _queue.then((_) async {
      try {
        await _db.update(
          'counters',
          {'value': value},
          where: 'id = ?',
          whereArgs: [id],
        );
      } catch (_) {
        // Не роняем очередь из-за одной неудачной записи.
      }
    });
  }

  Future<void> saveCounter(RowCounter counter) async {
    await _queue;
    if (counter.id == null) {
      final siblings = countersOf(counter.projectId);
      counter.position = siblings.isEmpty
          ? 0
          : siblings.map((c) => c.position).reduce((a, b) => a > b ? a : b) + 1;
      counter.id = await _db.insert('counters', counter.toMap());
      _settings['counter_${counter.projectId}'] = '${counter.id}';
      await _db.insert(
        'settings',
        {'key': 'counter_${counter.projectId}', 'value': '${counter.id}'},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } else {
      await _db.update(
        'counters',
        counter.toMap(),
        where: 'id = ?',
        whereArgs: [counter.id],
      );
    }
    await _reload();
  }

  Future<void> deleteCounter(RowCounter counter) async {
    await _queue;
    await _db.delete('counters', where: 'id = ?', whereArgs: [counter.id]);
    await _reload();
  }

  // ---------- пряжа ----------

  Future<int> saveYarn(Yarn yarn) async {
    yarn.updatedAt = _now;
    if (yarn.id == null) {
      yarn.createdAt = yarn.updatedAt;
      yarn.id = await _db.insert('yarns', yarn.toMap());
    } else {
      await _db.update(
        'yarns',
        yarn.toMap(),
        where: 'id = ?',
        whereArgs: [yarn.id],
      );
    }
    await _reload();
    return yarn.id!;
  }

  Future<void> deleteYarn(Yarn yarn) async {
    await _db.delete('yarns', where: 'id = ?', whereArgs: [yarn.id]);
    _deleteFile(yarn.photo);
    await _reload();
  }

  List<ProjectYarn> linksOfProject(int projectId) =>
      links.where((l) => l.projectId == projectId).toList();

  List<ProjectYarn> linksOfYarn(int yarnId) =>
      links.where((l) => l.yarnId == yarnId).toList();

  Future<void> linkYarn(int projectId, int yarnId, double skeins) async {
    await _db.insert(
      'project_yarns',
      {'project_id': projectId, 'yarn_id': yarnId, 'skeins': skeins},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await _reload();
  }

  Future<void> unlinkYarn(ProjectYarn link) async {
    await _db.delete('project_yarns', where: 'id = ?', whereArgs: [link.id]);
    await _reload();
  }

  // ---------- файлы ----------

  /// Удаляет файл фотографии, если он больше не нужен.
  void discardPhoto(String? path) => _deleteFile(path);

  static void _deleteFile(String? path) {
    if (path == null || path.isEmpty) return;
    try {
      final f = File(path);
      if (f.existsSync()) f.deleteSync();
    } catch (_) {
      // Файл уже мог исчезнуть — не страшно.
    }
  }
}
