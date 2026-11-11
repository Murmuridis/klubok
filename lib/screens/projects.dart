import 'package:flutter/material.dart';

import '../knit.dart';
import '../models.dart';
import '../photos.dart';
import '../store.dart';
import '../theme.dart';
import '../util.dart';
import 'counter_tab.dart';
import 'yarn.dart';

/// Вкладка «Проекты».
class ProjectsTab extends StatefulWidget {
  const ProjectsTab({super.key});

  @override
  State<ProjectsTab> createState() => _ProjectsTabState();
}

class _ProjectsTabState extends State<ProjectsTab> {
  final Store _store = Store.instance;

  /// null — показывать все.
  int? _status;

  void _open(Project project) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProjectScreen(projectId: project.id!),
      ),
    );
  }

  void _create() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ProjectEditScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _store,
      builder: (context, _) {
        final all = _store.projects;
        final shown = _status == null
            ? all
            : all.where((p) => p.status == _status).toList();
        return SafeArea(
          bottom: false,
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 14, 20, 0),
                    child: Text('Проекты', style: Wool.title),
                  ),
                  if (all.isNotEmpty)
                    SizedBox(
                      height: 56,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: WoolChip(
                              label: 'Все · ${all.length}',
                              selected: _status == null,
                              color: Wool.berry,
                              dense: true,
                              onTap: () => setState(() => _status = null),
                            ),
                          ),
                          for (final s in statusOrder)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: WoolChip(
                                label: statusNames[s],
                                selected: _status == s,
                                color: statusColors[s],
                                dense: true,
                                onTap: () => setState(() => _status = s),
                              ),
                            ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: all.isEmpty
                        ? EmptyState(
                            title: 'Здесь будут твои вещи',
                            text: 'Свитер, шапка, плед — заведи проект, '
                                'чтобы не терять ряды, пряжу и заметки.',
                            actionLabel: 'Новый проект',
                            onAction: _create,
                          )
                        : shown.isEmpty
                            ? const EmptyState(
                                title: 'Тут пока пусто',
                                text: 'С таким статусом проектов нет.',
                                color: Wool.sage,
                              )
                            : ListView.separated(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 6, 20, 110),
                                itemCount: shown.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, i) => _ProjectCard(
                                  project: shown[i],
                                  counter: _store.currentCounter(shown[i]),
                                  onTap: () => _open(shown[i]),
                                ),
                              ),
                  ),
                ],
              ),
              if (all.isNotEmpty)
                Positioned(
                  right: 20,
                  bottom: 20,
                  child: WoolButton(
                    color: Wool.berry,
                    size: 68,
                    label: 'Новый проект',
                    onTap: _create,
                    child: const Icon(Icons.add),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({
    required this.project,
    required this.counter,
    required this.onTap,
  });

  final Project project;
  final RowCounter? counter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = counter;
    String? progress;
    if (c != null) {
      progress = c.target == null
          ? '${c.name}: ${c.value}'
          : '${c.name}: ${c.value} из ${c.target}';
    }
    return Patch(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          PhotoThumb(
            path: project.photo,
            placeholder: YarnDot(color: statusColors[project.status]),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  project.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Wool.bodyBold.copyWith(fontSize: 17),
                ),
                const SizedBox(height: 2),
                Text(project.toolLine, style: Wool.soft),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _StatusTag(status: project.status),
                    if (progress != null) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          progress,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Wool.soft,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusTag extends StatelessWidget {
  const _StatusTag({required this.status});

  final int status;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: statusColors[status],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        child: Text(
          statusNames[status],
          style: const TextStyle(
            color: Wool.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// Карточка проекта: статус, детали, счётчики и пряжа.
class ProjectScreen extends StatelessWidget {
  const ProjectScreen({super.key, required this.projectId});

  final int projectId;

  Future<void> _delete(BuildContext context, Project project) async {
    final yes = await confirm(
      context,
      title: 'Удалить проект?',
      message: '«${project.name}» исчезнет вместе со счётчиками и фото. '
          'Пряжа в запасах останется.',
    );
    if (!yes || !context.mounted) return;
    Navigator.of(context).pop();
    await Store.instance.deleteProject(project);
  }

  Future<void> _addYarn(BuildContext context, Project project) async {
    final store = Store.instance;
    final linked = store.linksOfProject(project.id!).map((l) => l.yarnId);
    final free = store.yarns.where((y) => !linked.contains(y.id)).toList();
    if (free.isEmpty) {
      snack(
        context,
        store.yarns.isEmpty
            ? 'В запасах пока нет пряжи — добавь её на вкладке «Пряжа»'
            : 'Вся пряжа из запасов уже в этом проекте',
      );
      return;
    }
    final yarn = await showModalBottomSheet<Yarn>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.7,
          ),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            children: [
              const Text('Из какой пряжи?', style: Wool.heading),
              const SizedBox(height: 12),
              for (final y in free)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: YarnCard(
                    yarn: y,
                    onTap: () => Navigator.pop(context, y),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    if (yarn == null || !context.mounted) return;
    final skeins = await _askSkeins(context, yarn);
    if (skeins == null) return;
    await store.linkYarn(project.id!, yarn.id!, skeins);
  }

  Future<double?> _askSkeins(BuildContext context, Yarn yarn) {
    final controller = TextEditingController(text: '1');
    return showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Сколько мотков?'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Мотков на этот проект',
            helperText: 'Дома: ${skeinsText(yarn.skeins)}',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              final v = parseNum(controller.text);
              Navigator.pop(context, v == null || v <= 0 ? 1.0 : v);
            },
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = Store.instance;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final project = store.projectById(projectId);
        if (project == null) {
          return const KnitScaffold(body: SizedBox.shrink());
        }
        final counters = store.countersOf(project.id!);
        final links = store.linksOfProject(project.id!);
        final details = <(String, String)>[
          ('Инструмент', project.toolLine),
          if (project.gauge.trim().isNotEmpty) ('Плотность', project.gauge),
          if (project.pattern.trim().isNotEmpty) ('Схема', project.pattern),
          if (project.notes.trim().isNotEmpty) ('Заметки', project.notes),
        ];

        return KnitScaffold(
          appBar: AppBar(
            title: Text(project.name),
            actions: [
              IconButton(
                tooltip: 'Изменить',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ProjectEditScreen(project: project),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Удалить',
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _delete(context, project),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              if (project.photo != null && project.photo!.isNotEmpty) ...[
                AspectRatio(
                  aspectRatio: 16 / 10,
                  child: LayoutBuilder(
                    builder: (context, box) => PhotoThumb(
                      path: project.photo,
                      size: box.maxWidth,
                      radius: 18,
                      placeholder: const SizedBox.shrink(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final s in statusOrder)
                    WoolChip(
                      label: statusNames[s],
                      selected: project.status == s,
                      color: statusColors[s],
                      dense: true,
                      onTap: project.status == s
                          ? null
                          : () => store.setProjectStatus(project, s),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Patch(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < details.length; i++) ...[
                      if (i > 0) const SizedBox(height: 10),
                      Text(details[i].$1, style: Wool.soft),
                      Text(details[i].$2, style: Wool.body),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 22),
              const Text('Счётчики', style: Wool.heading),
              const SizedBox(height: 10),
              for (final c in counters)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Patch(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    onTap: () => editCounter(context, project, c),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(c.name, style: Wool.bodyBold),
                              Text(
                                [
                                  if (c.target != null) 'цель ${c.target}',
                                  if (c.repeatEvery != null)
                                    'раппорт ${c.repeatEvery}',
                                  if (c.target == null && c.repeatEvery == null)
                                    'нажми, чтобы настроить',
                                ].join(' · '),
                                style: Wool.soft,
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${c.value}',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: Wool.berry,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: PillButton(
                      label: 'Вязать',
                      icon: Icons.plus_one,
                      onTap: () {
                        store.openCounter(project);
                        Navigator.of(context)
                            .popUntil((route) => route.isFirst);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  PillButton(
                    label: 'Счётчик',
                    icon: Icons.add,
                    color: Wool.white,
                    onTap: () => editCounter(context, project, null),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              const Text('Пряжа', style: Wool.heading),
              const SizedBox(height: 10),
              for (final link in links)
                if (store.yarnById(link.yarnId) case final Yarn yarn)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: YarnCard(
                      yarn: yarn,
                      caption: 'на проект: ${skeinsText(link.skeins)}',
                      trailing: IconButton(
                        tooltip: 'Убрать из проекта',
                        icon: const Icon(Icons.close, color: Wool.brownSoft),
                        onPressed: () => store.unlinkYarn(link),
                      ),
                    ),
                  ),
              Align(
                alignment: Alignment.centerLeft,
                child: PillButton(
                  label: 'Пряжа из запасов',
                  icon: Icons.add,
                  color: Wool.white,
                  onTap: () => _addYarn(context, project),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Форма «новый проект / изменить проект».
class ProjectEditScreen extends StatefulWidget {
  const ProjectEditScreen({super.key, this.project});

  final Project? project;

  @override
  State<ProjectEditScreen> createState() => _ProjectEditScreenState();
}

class _ProjectEditScreenState extends State<ProjectEditScreen> {
  late final Project _draft;
  late final TextEditingController _name;
  late final TextEditingController _tool;
  late final TextEditingController _gauge;
  late final TextEditingController _pattern;
  late final TextEditingController _notes;
  String? _originalPhoto;
  bool _saved = false;
  bool _nameError = false;

  bool get _isNew => widget.project == null;

  @override
  void initState() {
    super.initState();
    _draft = widget.project?.copy() ?? Project();
    _originalPhoto = _draft.photo;
    _name = TextEditingController(text: _draft.name);
    _tool = TextEditingController(text: _draft.toolSize);
    _gauge = TextEditingController(text: _draft.gauge);
    _pattern = TextEditingController(text: _draft.pattern);
    _notes = TextEditingController(text: _draft.notes);
  }

  @override
  void dispose() {
    // Если вышли без сохранения — не оставляем лишний снимок.
    if (!_saved && _draft.photo != _originalPhoto) {
      Store.instance.discardPhoto(_draft.photo);
    }
    _name.dispose();
    _tool.dispose();
    _gauge.dispose();
    _pattern.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _setPhoto(String? path) {
    if (_draft.photo != _originalPhoto) {
      Store.instance.discardPhoto(_draft.photo);
    }
    setState(() => _draft.photo = path);
  }

  Future<void> _pickPhoto() async {
    final path = await pickPhoto(context);
    if (path != null && mounted) _setPhoto(path);
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = true);
      return;
    }
    _draft
      ..name = name
      ..toolSize = _tool.text.trim()
      ..gauge = _gauge.text.trim()
      ..pattern = _pattern.text.trim()
      ..notes = _notes.text.trim();
    final store = Store.instance;
    final isNew = _isNew;
    final id = await store.saveProject(_draft);
    _saved = true;
    if (_originalPhoto != _draft.photo) store.discardPhoto(_originalPhoto);
    if (isNew) await store.selectProject(id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return KnitScaffold(
      appBar: AppBar(title: Text(_isNew ? 'Новый проект' : 'Проект')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          PhotoField(
            path: _draft.photo,
            onPick: _pickPhoto,
            onRemove: () => _setPhoto(null),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) {
              if (_nameError) setState(() => _nameError = false);
            },
            decoration: InputDecoration(
              labelText: 'Что вяжем',
              hintText: 'Свитер с косами',
              errorText: _nameError ? 'Дай проекту название' : null,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              for (var i = 0; i < craftNames.length; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: WoolChip(
                    label: craftNames[i],
                    selected: _draft.craft == i,
                    onTap: () => setState(() => _draft.craft = i),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _tool,
            keyboardType: TextInputType.text,
            decoration: InputDecoration(
              labelText: _draft.craft == 0 ? 'Размер спиц' : 'Размер крючка',
              hintText: '4,5',
              suffixText: 'мм',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _gauge,
            decoration: const InputDecoration(
              labelText: 'Плотность',
              hintText: '22 петли × 30 рядов = 10 см',
            ),
          ),
          const SizedBox(height: 16),
          const Text('Статус', style: Wool.soft),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in statusOrder)
                WoolChip(
                  label: statusNames[s],
                  selected: _draft.status == s,
                  color: statusColors[s],
                  dense: true,
                  onTap: () => setState(() => _draft.status = s),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _pattern,
            minLines: 1,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Схема или описание',
              hintText: 'Ссылка, журнал и страница, пара слов',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notes,
            minLines: 2,
            maxLines: 8,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Заметки',
              hintText: 'На 34 ряду начала убавки…',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 22),
          PillButton(
            label: _isNew ? 'Создать проект' : 'Сохранить',
            icon: Icons.check,
            onTap: _save,
          ),
        ],
      ),
    );
  }
}
