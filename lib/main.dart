import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'device.dart';
import 'knit.dart';
import 'screens/counter_tab.dart';
import 'screens/projects.dart';
import 'screens/yarn.dart';
import 'store.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Wool.rose,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  Device.init();
  runApp(const KlubokApp());
}

class KlubokApp extends StatelessWidget {
  const KlubokApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Клубок',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      locale: const Locale('ru'),
      supportedLocales: const [Locale('ru')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: const _Startup(),
    );
  }
}

/// Открывает базу и показывает клубок, пока она грузится.
class _Startup extends StatefulWidget {
  const _Startup();

  @override
  State<_Startup> createState() => _StartupState();
}

class _StartupState extends State<_Startup> {
  late Future<void> _init = Store.instance.init();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _init,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            !snapshot.hasError) {
          return const HomeShell();
        }
        return KnitScaffold(
          body: snapshot.hasError
              ? EmptyState(
                  title: 'Ой, ниточка запуталась',
                  text: 'Не получилось открыть записи.\n${snapshot.error}',
                  actionLabel: 'Попробовать ещё раз',
                  onAction: () => setState(() => _init = Store.instance.init()),
                )
              : const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      YarnDot(color: Wool.rose, size: 110),
                      SizedBox(height: 16),
                      Text('Клубок', style: Wool.title),
                    ],
                  ),
                ),
        );
      },
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  final Store _store = Store.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _store.addListener(_onChange);
    _store.tab.addListener(_onChange);
    _applyDevice();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _store.removeListener(_onChange);
    _store.tab.removeListener(_onChange);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _applyDevice(force: true);
  }

  void _onChange() {
    if (!mounted) return;
    setState(() {});
    _applyDevice();
  }

  bool? _sentAwake;
  bool? _sentVolume;

  /// Экран не гаснет и кнопки громкости считают — только на вкладке счётчика.
  void _applyDevice({bool force = false}) {
    final counting = _store.tab.value == 0 && _store.currentProject != null;
    final awake = counting && _store.flag('keep_awake');
    final volume = counting && _store.flag('volume_keys');
    if (force || awake != _sentAwake) {
      _sentAwake = awake;
      Device.keepScreenOn(awake);
    }
    if (force || volume != _sentVolume) {
      _sentVolume = volume;
      Device.captureVolumeKeys(volume);
    }
  }

  @override
  Widget build(BuildContext context) {
    final index = _store.tab.value;
    return KnitScaffold(
      resizeToAvoidBottomInset: false,
      body: IndexedStack(
        index: index,
        sizing: StackFit.expand,
        children: const [CounterTab(), ProjectsTab(), YarnTab()],
      ),
      bottomNavigationBar: _WoolNavBar(
        index: index,
        onTap: (i) => _store.tab.value = i,
      ),
    );
  }
}

class _WoolNavBar extends StatelessWidget {
  const _WoolNavBar({required this.index, required this.onTap});

  final int index;
  final ValueChanged<int> onTap;

  static const _items = <(IconData, String)>[
    (Icons.plus_one, 'Счётчик'),
    (Icons.checkroom, 'Проекты'),
    (Icons.blur_circular, 'Пряжа'),
  ];

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return CustomPaint(
      painter: const RibPainter(color: Wool.rose),
      child: Padding(
        padding: EdgeInsets.fromLTRB(8, 10, 8, 10 + bottom),
        child: Row(
          children: [
            for (var i = 0; i < _items.length; i++)
              Expanded(
                // heightFactor: без него Center растягивается на всю высоту
                // экрана, и панель закрывает собой всё приложение.
                child: Center(
                  heightFactor: 1,
                  child: _NavItem(
                    icon: _items[i].$1,
                    label: _items[i].$2,
                    selected: i == index,
                    onTap: () => onTap(i),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Wool.berry : Wool.white;
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: fg),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: fg,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ],
    );
    const padding = EdgeInsets.symmetric(horizontal: 14, vertical: 10);
    return Semantics(
      button: true,
      selected: selected,
      child: selected
          ? Patch(
              color: Wool.cream,
              radius: 22,
              stitch: 9,
              padding: padding,
              elevated: false,
              child: content,
            )
          : GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
              child: Padding(padding: padding, child: content),
            ),
    );
  }
}
