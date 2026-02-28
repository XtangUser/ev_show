import 'package:flutter/foundation.dart';
import '../models/environment_info.dart';
import '../services/environment_registry.dart';
import '../services/scanner_service.dart';

enum ScanPhase { idle, scanning, done }

class ScanProvider extends ChangeNotifier {
  /// 所有环境项的可变副本（key: id）
  final Map<String, EnvironmentInfo> _items = {};

  ScanPhase _phase = ScanPhase.idle;
  DateTime? _lastScanTime;
  int _completedCount = 0;
  int _totalCount = 0;

  ScanPhase get phase => _phase;
  DateTime? get lastScanTime => _lastScanTime;
  int get completedCount => _completedCount;
  int get totalCount => _totalCount;

  double get progress => _totalCount == 0 ? 0.0 : _completedCount / _totalCount;

  bool get isScanning => _phase == ScanPhase.scanning;

  List<EnvironmentInfo> get allItems => _items.values.toList();

  int get foundCount =>
      _items.values.where((e) => e.status == ScanStatus.found).length;

  int get notFoundCount =>
      _items.values.where((e) => e.status == ScanStatus.notFound).length;

  /// 按分类分组
  Map<EnvironmentCategory, List<EnvironmentInfo>> get groupedItems {
    final map = <EnvironmentCategory, List<EnvironmentInfo>>{};
    for (final item in _items.values) {
      map.putIfAbsent(item.category, () => []).add(item);
    }
    // 按分类枚举顺序排序
    final sorted = Map.fromEntries(
      EnvironmentCategory.values
          .where((c) => map.containsKey(c))
          .map((c) => MapEntry(c, map[c]!)),
    );
    return sorted;
  }

  // ──────────────────────────────────────────────
  // 初始化：用 registry 预填数据，状态为 pending
  // ──────────────────────────────────────────────
  void _initItems() {
    _items.clear();
    for (final info in EnvironmentRegistry.all) {
      _items[info.id] = EnvironmentInfo(
        id: info.id,
        name: info.name,
        description: info.description,
        hint: info.hint,
        category: info.category,
        icon: info.icon,
        categoryColor: info.categoryColor,
        status: ScanStatus.pending,
      );
    }
  }

  // ──────────────────────────────────────────────
  // 开始扫描
  // ──────────────────────────────────────────────
  Future<void> startScan() async {
    if (_phase == ScanPhase.scanning) return;

    _phase = ScanPhase.scanning;
    _completedCount = 0;
    _initItems();

    final ids = _items.keys.toList();
    _totalCount = ids.length;

    notifyListeners();

    // 将所有扫描设为 scanning 状态
    for (final id in ids) {
      _items[id]!.status = ScanStatus.scanning;
    }
    notifyListeners();

    // 并发扫描（限制并发数避免系统过载）
    const concurrency = 8;
    final batches = <List<String>>[];
    for (var i = 0; i < ids.length; i += concurrency) {
      batches.add(
        ids.sublist(
          i,
          i + concurrency > ids.length ? ids.length : i + concurrency,
        ),
      );
    }

    for (final batch in batches) {
      await Future.wait(batch.map((id) => _scanOne(id)));
    }

    _phase = ScanPhase.done;
    _lastScanTime = DateTime.now();
    notifyListeners();
  }

  Future<void> _scanOne(String id) async {
    try {
      final result = await ScannerService.scan(id);
      final old = _items[id]!;

      _items[id] = EnvironmentInfo(
        id: old.id,
        name: old.name,
        description: old.description,
        hint: old.hint,
        category: old.category,
        icon: old.icon,
        categoryColor: old.categoryColor,
        status: result.found ? ScanStatus.found : ScanStatus.notFound,
        version: result.version,
        executablePath: result.path,
        errorMessage: result.error,
        extra: result.extra,
        instances: result.instances,
        scannedAt: DateTime.now(),
      );
    } catch (e) {
      final old = _items[id]!;
      _items[id] = EnvironmentInfo(
        id: old.id,
        name: old.name,
        description: old.description,
        hint: old.hint,
        category: old.category,
        icon: old.icon,
        categoryColor: old.categoryColor,
        status: ScanStatus.error,
        errorMessage: e.toString(),
      );
    } finally {
      _completedCount++;
      notifyListeners();
    }
  }
}
