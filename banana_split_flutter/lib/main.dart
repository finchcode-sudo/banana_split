// lib/main.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:banana_split_flutter/crypto/passphrase.dart';
import 'package:banana_split_flutter/state/create_notifier.dart';
import 'package:banana_split_flutter/state/restore_notifier.dart';
import 'package:banana_split_flutter/screens/create_screen.dart';
import 'package:banana_split_flutter/screens/restore_screen.dart';
import 'package:banana_split_flutter/screens/about_screen.dart';
import 'package:banana_split_flutter/screens/files_screen.dart';
import 'package:banana_split_flutter/state/locale_notifier.dart';
import 'package:banana_split_flutter/widgets/language_selector.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ═══════════════════════════════════════════════════
  // 改动1: 先显示启动页，再加载数据
  // ═══════════════════════════════════════════════════
  runApp(const SplashScreenApp());

  // 加载 locale（这个很快，可以继续）
  final localeNotifier = LocaleNotifier();
  await localeNotifier.load();

  // 注册许可证（移到后台）
  LicenseRegistry.addLicense(() async* {
    yield const LicenseEntryWithLineBreaks(
      ['Banana Split'],
      'GNU General Public License v3.0\n\n'
      'This program is free software: you can redistribute it and/or modify '
      'it under the terms of the GNU General Public License as published by '
      'the Free Software Foundation, either version 3 of the License, or '
      '(at your option) any later version.\n\n'
      'This program is distributed in the hope that it will be useful, '
      'but WITHOUT ANY WARRANTY; without even the implied warranty of '
      'MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the '
      'GNU General Public License for more details.\n\n'
      'You should have received a copy of the GNU General Public License '
      'along with this program. If not, see https://www.gnu.org/licenses/.',
    );
  });

  // ═══════════════════════════════════════════════════
  // 改动2: 不再加载 wordlist，延迟到 CreateNotifier 中加载
  // 删掉这两行：
  // final wordlistContent = await rootBundle.loadString('assets/wordlist.txt');
  // final passphraseGenerator = PassphraseGenerator.fromString(wordlistContent);
  // ═══════════════════════════════════════════════════

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: localeNotifier),
        // 传 null，让 CreateNotifier 自己按需加载
        ChangeNotifierProvider(
          create: (_) => CreateNotifier(null),
        ),
        ChangeNotifierProvider(
          create: (_) => RestoreNotifier(),
        ),
      ],
      child: const BananaSplitApp(),
    ),
  );
}

// ═══════════════════════════════════════════════════
// 新增：启动页 Widget
// ═══════════════════════════════════════════════════
class SplashScreenApp extends StatelessWidget {
  const SplashScreenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Banana Split',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.amber,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.amber,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 64,
                color: Colors.amber,
              ),
              SizedBox(height: 24),
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('加载中...'),
            ],
          ),
        ),
      ),
    );
  }
}

// BananaSplitApp 保持不变
class BananaSplitApp extends StatelessWidget {
  const BananaSplitApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seedColor = Colors.amber;

    return Consumer<LocaleNotifier>(
      builder: (context, localeNotifier, _) => MaterialApp(
        title: 'Banana Split',
        locale: localeNotifier.locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: seedColor,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: seedColor,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        themeMode: ThemeMode.system,
        home: const HomeShell(),
      ),
    );
  }
}

// HomeShell 保持不变
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;
  final _filesKey = GlobalKey<FilesScreenState>();

  List<Widget> _buildScreens() => [
    const CreateScreen(),
    RestoreScreen(isActive: _selectedIndex == 1),
    FilesScreen(key: _filesKey),
    const AboutScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: const [LanguageSelectorButton()],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _buildScreens(),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
          if (index == 2) {
            _filesKey.currentState?.refresh();
          }
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.lock_outline),
            selectedIcon: const Icon(Icons.lock),
            label: l10n.tabCreate,
          ),
          NavigationDestination(
            icon: const Icon(Icons.qr_code_scanner_outlined),
            selectedIcon: const Icon(Icons.qr_code_scanner),
            label: l10n.tabRestore,
          ),
          NavigationDestination(
            icon: const Icon(Icons.folder_outlined),
            selectedIcon: const Icon(Icons.folder),
            label: l10n.tabFiles,
          ),
          NavigationDestination(
            icon: const Icon(Icons.info_outline),
            selectedIcon: const Icon(Icons.info),
            label: l10n.tabAbout,
          ),
        ],
      ),
    );
  }
}
