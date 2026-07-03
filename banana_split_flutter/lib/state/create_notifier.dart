// lib/state/create_notifier.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:banana_split_flutter/crypto/crypto.dart';
import 'package:banana_split_flutter/crypto/passphrase.dart';

class CreateNotifier extends ChangeNotifier {
  PassphraseGenerator? _passphraseGenerator;
  bool _wordlistLoading = false;

  String _title = '';
  String _secret = '';
  int _totalShards = 5;
  int _requiredShards = 3;
  String _passphrase = '';
  List<String> _generatedShards = [];
  bool _isGenerating = false;
  bool _showResults = false;
  String? _error;
  bool _useManualPassphrase = false;

  // ═══════════════════════════════════════════════════
  // 改动：构造函数接收可空的 generator
  // ═══════════════════════════════════════════════════
  CreateNotifier(PassphraseGenerator? generator) {
    _passphraseGenerator = generator;
    // 如果 generator 已存在，立即生成；否则等用户点击"生成"时再加载
    if (_passphraseGenerator != null) {
      _passphrase = _passphraseGenerator!.generate(6);
    }
  }

  // ═══════════════════════════════════════════════════
  // 新增：懒加载 wordlist
  // ═══════════════════════════════════════════════════
  Future<void> _ensureGenerator() async {
    if (_passphraseGenerator != null) return;
    if (_wordlistLoading) {
      // 如果正在加载，等待完成
      await Future.doWhile(() => _wordlistLoading);
      return;
    }
    _wordlistLoading = true;
    try {
      final wordlistContent = await rootBundle.loadString('assets/wordlist.txt');
      _passphraseGenerator = PassphraseGenerator.fromString(wordlistContent);
      // 如果还没有 passphrase，自动生成一个
      if (_passphrase.isEmpty) {
        _passphrase = _passphraseGenerator!.generate(6);
        notifyListeners();
      }
    } finally {
      _wordlistLoading = false;
    }
  }

  // ... 所有 getter 保持不变 ...

  String get title => _title;
  String get secret => _secret;
  int get totalShards => _totalShards;
  int get requiredShards => _requiredShards;
  String get passphrase => _passphrase;
  List<String> get generatedShards => List.unmodifiable(_generatedShards);
  bool get isGenerating => _isGenerating;
  bool get showResults => _showResults;
  String? get error => _error;
  bool get useManualPassphrase => _useManualPassphrase;
  bool get secretTooLong => _secret.length > 1024;

  bool get canGenerate {
    final passphraseOk = !_useManualPassphrase || _passphrase.length >= 8;
    return _title.isNotEmpty &&
        _secret.isNotEmpty &&
        !secretTooLong &&
        _totalShards >= 3 &&
        _totalShards <= 255 &&
        _requiredShards >= 2 &&
        _requiredShards <= _totalShards &&
        _passphrase.isNotEmpty &&
        passphraseOk;
  }

  // ... update 方法保持不变 ...

  void updateTitle(String value) {
    _title = value;
    notifyListeners();
  }

  void updateSecret(String value) {
    _secret = value;
    notifyListeners();
  }

  void updateTotalShards(int value) {
    _totalShards = value.clamp(3, 255);
    _requiredShards = _requiredShards.clamp(2, _totalShards);
    notifyListeners();
  }

  void updateRequiredShards(int value) {
    _requiredShards = value.clamp(2, _totalShards);
    notifyListeners();
  }

  void updatePassphrase(String value) {
    _passphrase = value;
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════
  // 改动：toggleManualPassphrase 变成 async
  // ═══════════════════════════════════════════════════
  Future<void> toggleManualPassphrase() async {
    _useManualPassphrase = !_useManualPassphrase;
    if (!_useManualPassphrase) {
      await _ensureGenerator();
      if (_passphraseGenerator != null) {
        _passphrase = _passphraseGenerator!.generate(6);
      }
    }
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════
  // 改动：regeneratePassphrase 变成 async
  // ═══════════════════════════════════════════════════
  Future<void> regeneratePassphrase() async {
    await _ensureGenerator();
    if (_passphraseGenerator != null) {
      _passphrase = _passphraseGenerator!.generate(6);
      notifyListeners();
    }
  }

  // ═══════════════════════════════════════════════════
  // 改动：generate 开头调用 _ensureGenerator
  // ═══════════════════════════════════════════════════
  Future<void> generate() async {
    await _ensureGenerator();
    if (_passphraseGenerator == null) {
      _error = 'Failed to load wordlist';
      notifyListeners();
      return;
    }
    if (!canGenerate) return;

    _isGenerating = true;
    _error = null;
    notifyListeners();

    try {
      _generatedShards = await BananaCrypto.share(
        data: _secret,
        title: _title,
        passphrase: _passphrase,
        totalShards: _totalShards,
        requiredShards: requiredShards,
      );
      _showResults = true;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  void backToEdit() {
    _showResults = false;
    _error = null;
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════
  // 改动：reset 也变成 async
  // ═══════════════════════════════════════════════════
  Future<void> reset() async {
    _title = '';
    _secret = '';
    _totalShards = 5;
    _requiredShards = 3;
    _generatedShards = [];
    _isGenerating = false;
    _showResults = false;
    _error = null;
    _useManualPassphrase = false;
    await _ensureGenerator();
    if (_passphraseGenerator != null) {
      _passphrase = _passphraseGenerator!.generate(6);
    }
    notifyListeners();
  }
}
