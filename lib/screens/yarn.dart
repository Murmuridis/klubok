import 'package:flutter/material.dart';

import '../knit.dart';
import '../models.dart';
import '../photos.dart';
import '../store.dart';
import '../theme.dart';
import '../util.dart';

/// Вкладка «Пряжа»: что лежит дома.
class YarnTab extends StatefulWidget {
  const YarnTab({super.key});

  @override
  State<YarnTab> createState() => _YarnTabState();
}

class _YarnTabState extends State<YarnTab> {
  final Store _store = Store.instance;
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _edit(Yarn? yarn) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => YarnEditScreen(yarn: yarn)),
    );
  }

  bool _matches(Yarn y, String query) {
    if (query.isEmpty) return true;
    final text = [y.brand, y.name, y.colorName, y.composition, y.lot]
        .join(' ')
        .toLowerCase();
    return query.split(RegExp(r'\s+')).every(text.contains);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _store,
      builder: (context, _) {
        final all = _store.yarns;
        final query = _search.text.trim().toLowerCase();
        final shown = all.where((y) => _matches(y, query)).toList();

        final totalSkeins = all.fold<double>(0, (sum, y) => sum + y.skeins);
        final totalLength =
            all.fold<double>(0, (sum, y) => sum + (y.totalLength ?? 0));
        final summary = [
          skeinsText(totalSkeins),
          if (totalLength > 0) lengthText(totalLength),
        ].join(' · ');

        return SafeArea(
          bottom: false,
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Пряжа', style: Wool.title),
                        if (all.isNotEmpty)
                          Text('Дома: $summary', style: Wool.soft),
                      ],
                    ),
                  ),
                  if (all.length > 3)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: TextField(
                        controller: _search,
                        onChanged: (_) => setState(() {}),
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: 'Найти по названию, цвету, составу',
                          prefixIcon:
                              const Icon(Icons.search, color: Wool.rose),
                          suffixIcon: query.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Очистить',
                                  icon: const Icon(Icons.close),
                                  onPressed: () =>
                                      setState(() => _search.clear()),
                                ),
                        ),
                      ),
                    ),
                  Expanded(
                    child: all.isEmpty
                        ? EmptyState(
                            title: 'Запасы пока пусты',
                            text: 'Запиши мотки, которые лежат дома, — '
                                'и в магазине будет видно, что уже есть.',
                            actionLabel: 'Добавить пряжу',
                            onAction: () => _edit(null),
                            color: Wool.denim,
                          )
                        : shown.isEmpty
                            ? const EmptyState(
                                title: 'Ничего не нашлось',
                                text: 'Попробуй другое слово.',
                                color: Wool.sage,
                              )
                            : ListView.separated(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 14, 20, 110),
                                itemCount: shown.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, i) => YarnCard(
                                  yarn: shown[i],
                                  onTap: () => _edit(shown[i]),
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
                    label: 'Добавить пряжу',
                    onTap: () => _edit(null),
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

/// Карточка мотка: клубок его цвета (или фото), название и сколько осталось.
class YarnCard extends StatelessWidget {
  const YarnCard({
    super.key,
    required this.yarn,
    this.onTap,
    this.caption,
    this.trailing,
  });

  final Yarn yarn;
  final VoidCallback? onTap;

  /// Строка вместо «сколько дома» — например, «на проект: 2 мотка».
  final String? caption;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      if (yarn.colorName.trim().isNotEmpty) yarn.colorName.trim(),
      if (yarn.composition.trim().isNotEmpty) yarn.composition.trim(),
    ].join(' · ');
    final stock = [
      skeinsText(yarn.skeins),
      if (yarn.totalLength != null) lengthText(yarn.totalLength!),
      if (yarn.totalWeight != null) weightText(yarn.totalWeight!),
    ].join(' · ');

    return Patch(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          PhotoThumb(
            path: yarn.photo,
            size: 64,
            placeholder: YarnDot(color: Color(yarn.color), size: 60),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  yarn.title.isEmpty ? 'Без названия' : yarn.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Wool.bodyBold.copyWith(fontSize: 16.5),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Wool.soft,
                  ),
                const SizedBox(height: 4),
                Text(
                  caption ?? stock,
                  style: Wool.body.copyWith(
                    color: yarn.skeins <= 0 && caption == null
                        ? Wool.berry
                        : Wool.brown,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Форма «новая пряжа / изменить пряжу».
class YarnEditScreen extends StatefulWidget {
  const YarnEditScreen({super.key, this.yarn});

  final Yarn? yarn;

  @override
  State<YarnEditScreen> createState() => _YarnEditScreenState();
}

class _YarnEditScreenState extends State<YarnEditScreen> {
  late final Yarn _draft;
  late final TextEditingController _brand;
  late final TextEditingController _name;
  late final TextEditingController _colorName;
  late final TextEditingController _composition;
  late final TextEditingController _weight;
  late final TextEditingController _length;
  late final TextEditingController _skeins;
  late final TextEditingController _lot;
  late final TextEditingController _tool;
  late final TextEditingController _notes;
  String? _originalPhoto;
  bool _saved = false;
  String? _error;

  bool get _isNew => widget.yarn == null;

  @override
  void initState() {
    super.initState();
    _draft = widget.yarn?.copy() ?? Yarn();
    _originalPhoto = _draft.photo;
    String num(double? v) => v == null ? '' : fmtNum(v);
    _brand = TextEditingController(text: _draft.brand);
    _name = TextEditingController(text: _draft.name);
    _colorName = TextEditingController(text: _draft.colorName);
    _composition = TextEditingController(text: _draft.composition);
    _weight = TextEditingController(text: num(_draft.skeinWeight));
    _length = TextEditingController(text: num(_draft.skeinLength));
    _skeins = TextEditingController(text: fmtNum(_draft.skeins));
    _lot = TextEditingController(text: _draft.lot);
    _tool = TextEditingController(text: _draft.toolSize);
    _notes = TextEditingController(text: _draft.notes);
  }

  @override
  void dispose() {
    if (!_saved && _draft.photo != _originalPhoto) {
      Store.instance.discardPhoto(_draft.photo);
    }
    for (final c in [
      _brand,
      _name,
      _colorName,
      _composition,
      _weight,
      _length,
      _skeins,
      _lot,
      _tool,
      _notes,
    ]) {
      c.dispose();
    }
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

  void _stepSkeins(double delta) {
    final current = parseNum(_skeins.text) ?? 0;
    final next = (current + delta).clamp(0.0, 9999.0);
    setState(() => _skeins.text = fmtNum(next));
  }

  Future<void> _save() async {
    final brand = _brand.text.trim();
    final name = _name.text.trim();
    final skeins = parseNum(_skeins.text);
    final weight = parseNum(_weight.text);
    final length = parseNum(_length.text);

    String? error;
    if (brand.isEmpty && name.isEmpty) {
      error = 'Напиши хотя бы марку или название пряжи.';
    } else if (skeins == null || skeins < 0) {
      error = 'Сколько мотков? Можно дробно: 2,5.';
    } else if ((_weight.text.trim().isNotEmpty &&
            (weight == null || weight <= 0)) ||
        (_length.text.trim().isNotEmpty && (length == null || length <= 0))) {
      error = 'Вес и длину мотка — числами, например 50 и 100.';
    }
    if (error != null || skeins == null) {
      setState(() => _error = error);
      return;
    }

    _draft
      ..brand = brand
      ..name = name
      ..colorName = _colorName.text.trim()
      ..composition = _composition.text.trim()
      ..skeinWeight = weight
      ..skeinLength = length
      ..skeins = skeins
      ..lot = _lot.text.trim()
      ..toolSize = _tool.text.trim()
      ..notes = _notes.text.trim();
    final store = Store.instance;
    await store.saveYarn(_draft);
    _saved = true;
    if (_originalPhoto != _draft.photo) store.discardPhoto(_originalPhoto);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final yarn = widget.yarn!;
    final yes = await confirm(
      context,
      title: 'Удалить пряжу?',
      message: '«${yarn.title}» пропадёт из запасов и из проектов, '
          'где она указана.',
    );
    if (!yes || !mounted) return;
    Navigator.of(context).pop();
    await Store.instance.deleteYarn(yarn);
  }

  @override
  Widget build(BuildContext context) {
    const decimal = TextInputType.numberWithOptions(decimal: true);
    final store = Store.instance;
    final usedIn =
        _isNew ? const <ProjectYarn>[] : store.linksOfYarn(widget.yarn!.id!);

    return KnitScaffold(
      appBar: AppBar(
        title: Text(_isNew ? 'Новая пряжа' : 'Пряжа'),
        actions: [
          if (!_isNew)
            IconButton(
              tooltip: 'Удалить',
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
        ],
      ),
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
            controller: _brand,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Марка',
              hintText: 'Drops, Пехорка, Alize…',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Название',
              hintText: 'Nepal, Детская новинка…',
            ),
          ),
          const SizedBox(height: 16),
          const Text('Цвет', style: Wool.soft),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final color in Wool.yarnPalette)
                _Swatch(
                  color: color,
                  selected: _draft.color == color.toARGB32(),
                  onTap: () => setState(() => _draft.color = color.toARGB32()),
                ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _colorName,
            decoration: const InputDecoration(
              labelText: 'Название или номер цвета',
              hintText: 'пыльная роза, 3112',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _composition,
            decoration: const InputDecoration(
              labelText: 'Состав',
              hintText: '65% шерсть, 35% альпака',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _weight,
                  keyboardType: decimal,
                  decoration: const InputDecoration(
                    labelText: 'Вес мотка',
                    suffixText: 'г',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _length,
                  keyboardType: decimal,
                  decoration: const InputDecoration(
                    labelText: 'Длина нити',
                    suffixText: 'м',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              WoolButton(
                color: Wool.sage,
                size: 52,
                label: 'На моток меньше',
                onTap: () => _stepSkeins(-1),
                child: const Icon(Icons.remove),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _skeins,
                  keyboardType: decimal,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Мотков дома',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              WoolButton(
                color: Wool.rose,
                size: 52,
                label: 'На моток больше',
                onTap: () => _stepSkeins(1),
                child: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _lot,
                  decoration: const InputDecoration(
                    labelText: 'Партия',
                    hintText: 'с этикетки',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _tool,
                  decoration: const InputDecoration(
                    labelText: 'Спицы / крючок',
                    hintText: '4–5',
                    suffixText: 'мм',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notes,
            minLines: 2,
            maxLines: 6,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Заметки',
              hintText: 'Где купила, как стирать, на что отложена…',
              alignLabelWithHint: true,
            ),
          ),
          if (usedIn.isNotEmpty) ...[
            const SizedBox(height: 18),
            const Text('В проектах', style: Wool.heading),
            const SizedBox(height: 8),
            for (final link in usedIn)
              if (store.projectById(link.projectId) case final Project p)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '${p.name} — ${skeinsText(link.skeins)}',
                    style: Wool.body,
                  ),
                ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 14),
            Text(_error!, style: Wool.bodyBold.copyWith(color: Wool.berry)),
          ],
          const SizedBox(height: 22),
          PillButton(
            label: _isNew ? 'Добавить в запасы' : 'Сохранить',
            icon: Icons.check,
            onTap: _save,
          ),
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? Wool.berry : Colors.transparent,
              width: 2.5,
            ),
          ),
          padding: const EdgeInsets.all(2),
          child: CustomPaint(
            painter: YarnBallPainter(color: color, tail: false),
          ),
        ),
      ),
    );
  }
}
