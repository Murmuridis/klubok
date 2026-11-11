import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../device.dart';
import '../knit.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../util.dart';
import 'projects.dart';

/// Вкладка «Счётчик»: большой клубок, по которому стучат после каждого ряда.
class CounterTab extends StatefulWidget {
  const CounterTab({super.key});

  @override
  State<CounterTab> createState() => _CounterTabState();
}

class _CounterTabState extends State<CounterTab> {
  final Store _store = Store.instance;
  StreamSubscription<bool>? _volumeSub;

  @override
  void initState() {
    super.initState();
    _store.addListener(_refresh);
    _volumeSub = Device.volumeKeys.listen((up) {
      if (!mounted || _store.tab.value != 0) return;
      // Считаем только когда счётчик на виду, а не под окошком или другим экраном.
      if (ModalRoute.of(context)?.isCurrent ?? true) _bump(up ? 1 : -1);
    });
  }

  @override
  void dispose() {
    _store.removeListener(_refresh);
    _volumeSub?.cancel();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Color _colorOf(RowCounter counter, List<RowCounter> all) {
    final i = all.indexWhere((c) => c.id == counter.id);
    return Wool.counterColors[(i < 0 ? 0 : i) % Wool.counterColors.length];
  }

  void _bump(int delta) {
    final project = _store.currentProject;
    if (project == null) return;
    final counter = _store.currentCounter(project);
    if (counter == null) return;
    final value = counter.value + delta;
    if (value < 0) return;
    _store.setCounterValue(counter, value);

    final haptics = _store.flag('haptics');
    final repeat = counter.repeatEvery;
    if (delta > 0 && counter.target != null && value == counter.target) {
      if (haptics) HapticFeedback.heavyImpact();
      snack(context, 'Готово! Связано ${rowsText(value)} — цель достигнута');
    } else if (delta > 0 &&
        repeat != null &&
        repeat > 1 &&
        value % repeat == 0) {
      if (haptics) HapticFeedback.mediumImpact();
      snack(context, 'Раппорт закончен — это был повтор ${value ~/ repeat}');
    } else if (haptics) {
      HapticFeedback.lightImpact();
    }
  }

  Future<void> _reset(RowCounter counter) async {
    if (counter.value == 0) return;
    final yes = await confirm(
      context,
      title: 'Начать с нуля?',
      message: 'Счётчик «${counter.name}» сейчас на ${counter.value}. '
          'Обнулить его?',
      ok: 'Обнулить',
    );
    if (yes) _store.setCounterValue(counter, 0);
  }

  Future<void> _newProject() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ProjectEditScreen()),
    );
  }

  Future<void> _pickProject() async {
    final picked = await showModalBottomSheet<Object>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _ProjectPicker(store: _store),
    );
    if (!mounted) return;
    if (picked is Project) {
      await _store.selectProject(picked.id!);
    } else if (picked == 'new') {
      await _newProject();
    }
  }

  void _openSettings() {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => _SettingsSheet(store: _store),
    );
  }

  @override
  Widget build(BuildContext context) {
    final project = _store.currentProject;
    if (project == null) {
      return SafeArea(
        child: EmptyState(
          title: 'Пора что-нибудь связать',
          text: 'Заведи первый проект — и клубок начнёт считать ряды.',
          actionLabel: 'Новый проект',
          onAction: _newProject,
        ),
      );
    }

    final all = _store.countersOf(project.id!);
    final counter = _store.currentCounter(project);

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Название проекта: нажми, чтобы выбрать другой.
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 8, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _pickProject,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  project.name,
                                  style: Wool.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(Icons.expand_more, color: Wool.berry),
                            ],
                          ),
                          Text(
                            '${project.toolLine} · '
                            '${statusNames[project.status].toLowerCase()}',
                            style: Wool.soft,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Настройки счётчика',
                  onPressed: _openSettings,
                  icon: const Icon(Icons.tune),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Счётчики проекта.
          SizedBox(
            height: 62,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
              children: [
                for (final c in all)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: WoolChip(
                      label: '${c.name} · ${c.value}',
                      selected: c.id == counter?.id,
                      color: _colorOf(c, all),
                      onTap: () => _store.selectCounter(c),
                      onLongPress: () => editCounter(context, project, c),
                    ),
                  ),
                WoolChip(
                  label: '',
                  icon: Icons.add,
                  onTap: () => editCounter(context, project, null),
                ),
              ],
            ),
          ),
          if (counter == null)
            Expanded(
              child: EmptyState(
                title: 'Счётчиков пока нет',
                text: 'Добавь счётчик для рядов или раппорта.',
                actionLabel: 'Добавить счётчик',
                onAction: () => editCounter(context, project, null),
              ),
            )
          else ...[
            Expanded(
              child: _Ball(
                counter: counter,
                color: _colorOf(counter, all),
                onTap: () => _bump(1),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _InfoPatch(
                counter: counter,
                volumeKeys: _store.flag('volume_keys'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  WoolButton(
                    color: Wool.sage,
                    label: 'Минус один ряд',
                    onTap: counter.value > 0 ? () => _bump(-1) : null,
                    child: const Text('−1'),
                  ),
                  WoolButton(
                    color: Wool.mustard,
                    label: 'Настроить счётчик',
                    onTap: () => editCounter(context, project, counter),
                    child: const Icon(Icons.edit_outlined),
                  ),
                  WoolButton(
                    color: Wool.denim,
                    label: 'Обнулить счётчик',
                    onTap: () => _reset(counter),
                    child: const Icon(Icons.replay),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Клубок с числом. Нажатие — плюс один.
class _Ball extends StatelessWidget {
  const _Ball({
    required this.counter,
    required this.color,
    required this.onTap,
  });

  final RowCounter counter;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final target = counter.target;
    return LayoutBuilder(
      builder: (context, box) {
        final side = [box.maxWidth * 0.74, box.maxHeight * 0.86, 340.0]
            .reduce((a, b) => a < b ? a : b);
        // Совсем нет места (например, выехала клавиатура) — клубок не рисуем.
        if (side < 90) return const SizedBox.shrink();
        final ball = side - 26;
        return Center(
          child: Semantics(
            button: true,
            label: '${counter.name}: ${counter.value}. Нажми, чтобы прибавить',
            child: Pressable(
              onTap: onTap,
              pressedScale: 0.96,
              child: SizedBox.square(
                dimension: side,
                child: CustomPaint(
                  painter: target == null || target <= 0
                      ? null
                      : ThreadRingPainter(
                          progress: counter.value / target,
                          color: Wool.berry,
                        ),
                  child: Center(
                    child: SizedBox.square(
                      dimension: ball,
                      child: CustomPaint(
                        painter: YarnBallPainter(color: color),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: ball * 0.78,
                              height: ball * 0.42,
                              child: FittedBox(
                                fit: BoxFit.contain,
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 140),
                                  transitionBuilder: (child, animation) =>
                                      ScaleTransition(
                                    scale: Tween<double>(begin: 0.8, end: 1)
                                        .animate(animation),
                                    child: FadeTransition(
                                      opacity: animation,
                                      child: child,
                                    ),
                                  ),
                                  child: Text(
                                    '${counter.value}',
                                    key: ValueKey<int>(counter.value),
                                    style: const TextStyle(
                                      fontSize: 96,
                                      height: 1.05,
                                      fontWeight: FontWeight.w700,
                                      color: Wool.white,
                                      shadows: [
                                        Shadow(
                                          color: Color(0x8C3C1420),
                                          blurRadius: 10,
                                          offset: Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Text(
                              'нажми — плюс один',
                              style: TextStyle(
                                fontSize: ball * 0.06,
                                fontWeight: FontWeight.w700,
                                color: Wool.white,
                                shadows: const [
                                  Shadow(
                                    color: Color(0x8C3C1420),
                                    blurRadius: 6,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Подсказка под клубком: раппорт, цель или памятка про кнопки громкости.
class _InfoPatch extends StatelessWidget {
  const _InfoPatch({required this.counter, required this.volumeKeys});

  final RowCounter counter;
  final bool volumeKeys;

  @override
  Widget build(BuildContext context) {
    final lines = <Widget>[];
    final repeat = counter.repeatEvery;
    final target = counter.target;
    final value = counter.value;

    if (repeat != null && repeat > 1) {
      final inRepeat =
          value > 0 && value % repeat == 0 ? repeat : value % repeat;
      final number = value == 0 ? 1 : (value - 1) ~/ repeat + 1;
      lines.add(Text(
        'Раппорт: ряд $inRepeat из $repeat · повтор $number',
        style: Wool.body,
        textAlign: TextAlign.center,
      ));
    }
    if (target != null && target > 0) {
      final left = target - value;
      lines.add(Text(
        left > 0
            ? 'до цели ${plural(left, 'остался', 'осталось', 'осталось')} '
                '${rowsText(left)}'
            : 'цель достигнута: $target',
        style: Wool.bodyBold.copyWith(color: Wool.berry),
        textAlign: TextAlign.center,
      ));
    }
    if (lines.isEmpty) {
      lines.add(Text(
        volumeKeys
            ? 'Руки заняты? Кнопки громкости тоже считают:\n'
                'вверх — плюс один, вниз — минус один'
            : 'Подержи палец на счётчике сверху, чтобы задать цель или раппорт',
        style: Wool.soft,
        textAlign: TextAlign.center,
      ));
    }

    return Patch(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < lines.length; i++) ...[
            if (i > 0) const SizedBox(height: 4),
            lines[i],
          ],
        ],
      ),
    );
  }
}

/// Список проектов для быстрого переключения.
class _ProjectPicker extends StatelessWidget {
  const _ProjectPicker({required this.store});

  final Store store;

  @override
  Widget build(BuildContext context) {
    final current = store.currentProject;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
        ),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          children: [
            const Text('Что вяжем?', style: Wool.heading),
            const SizedBox(height: 12),
            for (final p in store.projects)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Patch(
                  color: p.id == current?.id ? Wool.rose : Wool.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  onTap: () => Navigator.pop(context, p),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          p.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Wool.bodyBold.copyWith(
                            fontSize: 16,
                            color:
                                p.id == current?.id ? Wool.white : Wool.brown,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        statusNames[p.status].toLowerCase(),
                        style: Wool.soft.copyWith(
                          color:
                              p.id == current?.id ? Wool.white : Wool.brownSoft,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 4),
            PillButton(
              label: 'Новый проект',
              icon: Icons.add,
              color: Wool.white,
              onTap: () => Navigator.pop(context, 'new'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsSheet extends StatelessWidget {
  const _SettingsSheet({required this.store});

  final Store store;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        Widget toggle(String key, String title, String subtitle) {
          return SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(title, style: Wool.bodyBold),
            subtitle: Text(subtitle, style: Wool.soft),
            value: store.flag(key),
            onChanged: (v) => store.setFlag(key, v),
          );
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Как считать', style: Wool.heading),
                const SizedBox(height: 6),
                toggle(
                  'volume_keys',
                  'Считать кнопками громкости',
                  'Вверх — плюс один, вниз — минус один. '
                      'Пока открыт счётчик, громкость они не меняют.',
                ),
                toggle(
                  'keep_awake',
                  'Экран не гаснет',
                  'Пока открыт счётчик, телефон не засыпает.',
                ),
                toggle(
                  'haptics',
                  'Отклик вибрацией',
                  'Лёгкий толчок на каждый ряд, сильнее — в конце раппорта.',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Окошко «новый счётчик / настроить счётчик».
Future<void> editCounter(
  BuildContext context,
  Project project,
  RowCounter? counter,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _CounterForm(project: project, counter: counter),
  );
}

class _CounterForm extends StatefulWidget {
  const _CounterForm({required this.project, required this.counter});

  final Project project;
  final RowCounter? counter;

  @override
  State<_CounterForm> createState() => _CounterFormState();
}

class _CounterFormState extends State<_CounterForm> {
  late final TextEditingController _name;
  late final TextEditingController _value;
  late final TextEditingController _target;
  late final TextEditingController _repeat;
  String? _error;

  bool get _isNew => widget.counter == null;

  @override
  void initState() {
    super.initState();
    final c = widget.counter;
    _name = TextEditingController(text: c?.name ?? '');
    _value = TextEditingController(text: '${c?.value ?? 0}');
    _target = TextEditingController(text: c?.target?.toString() ?? '');
    _repeat = TextEditingController(text: c?.repeatEvery?.toString() ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _value.dispose();
    _target.dispose();
    _repeat.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final value = parseInt(_value.text) ?? 0;
    final target = parseInt(_target.text);
    final repeat = parseInt(_repeat.text);
    String? error;
    if (name.isEmpty) {
      error = 'Как назвать счётчик? Например, «Ряды» или «Рукав».';
    } else if (value < 0 ||
        (_target.text.trim().isNotEmpty && (target == null || target < 1)) ||
        (_repeat.text.trim().isNotEmpty && (repeat == null || repeat < 2))) {
      error = 'Цель — от 1 ряда, раппорт — от 2 рядов, только цифрами.';
    }
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    final counter =
        widget.counter?.copy() ?? RowCounter(projectId: widget.project.id!);
    counter
      ..name = name
      ..value = value
      ..target = target
      ..repeatEvery = repeat;
    await Store.instance.saveCounter(counter);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final counter = widget.counter!;
    final yes = await confirm(
      context,
      title: 'Удалить счётчик?',
      message: '«${counter.name}» со значением ${counter.value} исчезнет '
          'насовсем.',
    );
    if (!yes) return;
    await Store.instance.deleteCounter(counter);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    const digits = TextInputType.number;
    final onlyDigits = [FilteringTextInputFormatter.digitsOnly];
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isNew ? 'Новый счётчик' : 'Счётчик',
                style: Wool.heading,
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _name,
                autofocus: _isNew,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Название',
                  hintText: 'Ряды, рукав, прибавки…',
                ),
              ),
              const SizedBox(height: 12),
              if (!_isNew) ...[
                TextField(
                  controller: _value,
                  keyboardType: digits,
                  inputFormatters: onlyDigits,
                  decoration: const InputDecoration(
                    labelText: 'Сейчас на счётчике',
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _target,
                      keyboardType: digits,
                      inputFormatters: onlyDigits,
                      decoration: const InputDecoration(
                        labelText: 'Цель, рядов',
                        helperText: 'если нужна',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _repeat,
                      keyboardType: digits,
                      inputFormatters: onlyDigits,
                      decoration: const InputDecoration(
                        labelText: 'Раппорт, рядов',
                        helperText: 'если узор повторяется',
                      ),
                    ),
                  ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(
                  _error!,
                  style: Wool.bodyBold.copyWith(color: Wool.berry),
                ),
              ],
              const SizedBox(height: 18),
              PillButton(
                label: _isNew ? 'Добавить' : 'Сохранить',
                icon: Icons.check,
                onTap: _save,
              ),
              if (!_isNew) ...[
                const SizedBox(height: 6),
                TextButton.icon(
                  onPressed: _delete,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Удалить счётчик'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
