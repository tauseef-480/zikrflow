import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'models.dart';

/// Replaces the web version's IndexedDB (`ZikrFlowDB`) with two Hive boxes:
///  - `zikrflow_state`  : one document ("main") with settings + counters,
///                        mirroring the old `appState` object store.
///  - `zikrflow_daily`  : one entry per date ("yyyy-MM-dd"), mirroring the
///                        old `dailyRecords` object store. This box is the
///                        single source of truth for history/streak, exactly
///                        like the original design.
class ZikrStore extends ChangeNotifier {
  static const _appBoxName = 'zikrflow_state';
  static const _dailyBoxName = 'zikrflow_daily';

  late Box _appBox;
  late Box _dailyBox;
  bool ready = false;

  String selectedZikr = builtInAzkar.first.id;
  int count = 0;
  int target = 100;
  int today = 0;
  int yesterday = 0;
  int week = 0;
  int total = 0;
  int streak = 0;
  int longestStreak = 0;
  String? lastDate;
  bool isDark = true;
  int completedTargets = 0;

  /// id -> {count, target}
  Map<String, Map<String, int>> todayByZikr = {};
  List<Zikr> customZikrs = [];
  List<String> favorites = [];

  List<Zikr> get allZikrs => [...builtInAzkar, ...customZikrs];

  Zikr get currentZikr => allZikrs.firstWhere(
        (z) => z.id == selectedZikr,
        orElse: () => builtInAzkar.first,
      );

  bool isFavorite(String id) => favorites.contains(id);

  String dateKey([DateTime? d]) {
    final date = d ?? DateTime.now();
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  Future<void> init() async {
    await Hive.initFlutter();
    _appBox = await Hive.openBox(_appBoxName);
    _dailyBox = await Hive.openBox(_dailyBoxName);

    final saved = _appBox.get('main');
    if (saved != null) {
      final map = Map<dynamic, dynamic>.from(saved as Map);
      selectedZikr = (map['selectedZikr'] as String?) ?? builtInAzkar.first.id;
      target = ((map['target'] as num?) ?? 100).toInt();
      isDark = (map['isDark'] as bool?) ?? true;
      streak = ((map['streak'] as num?) ?? 0).toInt();
      longestStreak = ((map['longestStreak'] as num?) ?? 0).toInt();
      lastDate = map['lastDate'] as String?;
      completedTargets = ((map['completedTargets'] as num?) ?? 0).toInt();
      favorites = List<String>.from((map['favorites'] as List?) ?? []);
      customZikrs = ((map['customZikrs'] as List?) ?? [])
          .map((e) => Zikr.fromJson(Map<dynamic, dynamic>.from(e as Map)))
          .toList();
      final rawToday = Map<dynamic, dynamic>.from(map['todayByZikr'] ?? {});
      todayByZikr = {};
      rawToday.forEach((k, v) {
        final m = Map<dynamic, dynamic>.from(v as Map);
        todayByZikr[k.toString()] = {
          'count': ((m['count'] as num?) ?? 0).toInt(),
          'target': ((m['target'] as num?) ?? 100).toInt(),
        };
      });
    }

    if (target < 1) target = 100;

    _checkDay();
    _syncTodayRecord();
    _recomputeTotal();
    _recalculateStreak();
    _persist();

    ready = true;
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Daily-record helpers (Hive equivalent of the IndexedDB dailyRecords
  // object store).
  // ---------------------------------------------------------------------

  Map<String, dynamic> _rawDailyRecord(String key) {
    final raw = _dailyBox.get(key);
    if (raw == null) return {'date': key, 'total': 0, 'zikrs': <String, dynamic>{}};
    final map = Map<dynamic, dynamic>.from(raw as Map);
    return {
      'date': key,
      'total': ((map['total'] as num?) ?? 0).toInt(),
      'zikrs': Map<dynamic, dynamic>.from(map['zikrs'] ?? {}),
    };
  }

  Map<String, int> _zikrEntryFromRecord(Map<String, dynamic> record, String id) {
    final zikrs = Map<dynamic, dynamic>.from(record['zikrs'] ?? {});
    final value = zikrs[id];
    if (value == null) return {'count': 0, 'target': 100};
    final m = Map<dynamic, dynamic>.from(value as Map);
    return {
      'count': ((m['count'] as num?) ?? 0).toInt(),
      'target': ((m['target'] as num?) ?? 100).toInt(),
    };
  }

  Map<String, int> _ensureTodayEntry(String id) {
    final existing = todayByZikr[id];
    if (existing != null) return existing;
    final fresh = {'count': 0, 'target': target < 1 ? 100 : target};
    todayByZikr[id] = fresh;
    return fresh;
  }

  void _syncTodayRecord() {
    final key = dateKey();
    todayByZikr.removeWhere((id, data) => (data['count'] ?? 0) <= 0);

    var totalToday = 0;
    final zikrsOut = <String, dynamic>{};
    todayByZikr.forEach((id, data) {
      final c = data['count'] ?? 0;
      final t = (data['target'] ?? 100) < 1 ? 100 : data['target']!;
      zikrsOut[id] = {'count': c, 'target': t};
      totalToday += c;
    });

    _dailyBox.put(key, {'total': totalToday, 'zikrs': zikrsOut});
    today = totalToday;

    final sel = todayByZikr[selectedZikr];
    count = sel != null ? sel['count']! : 0;
    week = _sumHistoryFromRecords(7);
  }

  int _sumHistoryFromRecords(int days) {
    var sum = 0;
    final now = DateTime.now();
    final base = DateTime(now.year, now.month, now.day);
    for (var i = 0; i < days; i++) {
      final d = base.subtract(Duration(days: i));
      final rec = _rawDailyRecord(dateKey(d));
      sum += (rec['total'] as int?) ?? 0;
    }
    return sum;
  }

  void _recomputeTotal() {
    var sum = 0;
    for (final key in _dailyBox.keys) {
      final rec = _rawDailyRecord(key.toString());
      sum += (rec['total'] as int?) ?? 0;
    }
    total = sum;
  }

  bool _dayHasZikr(String key) {
    if (key == dateKey()) return today > 0;
    final rec = _rawDailyRecord(key);
    final zikrs = Map<dynamic, dynamic>.from(rec['zikrs'] ?? {});
    return zikrs.values.any((v) {
      final m = Map<dynamic, dynamic>.from(v as Map);
      return ((m['count'] as num?) ?? 0) > 0;
    });
  }

  void _recalculateStreak() {
    if (!_dayHasZikr(dateKey())) {
      streak = 0;
      return;
    }
    var s = 1;
    for (var i = 1; i < 10000; i++) {
      final d = DateTime.now().subtract(Duration(days: i));
      if (!_dayHasZikr(dateKey(d))) break;
      s++;
    }
    streak = s;
    if (s > longestStreak) longestStreak = s;
  }

  void _checkDay() {
    final todayKey = dateKey();
    if (lastDate == null) {
      lastDate = todayKey;
      return;
    }
    if (lastDate == todayKey) return;

    DateTime? oldDate;
    try {
      oldDate = DateTime.parse(lastDate!);
    } catch (_) {
      oldDate = null;
    }
    final newDate = DateTime.parse(todayKey);
    final diff = oldDate == null ? 2 : newDate.difference(oldDate).inDays;

    yesterday = today;
    today = 0;
    count = 0;
    todayByZikr = {};
    lastDate = todayKey;

    if (diff > 1) streak = 0;
  }

  void _persist() {
    _appBox.put('main', {
      'selectedZikr': selectedZikr,
      'target': target,
      'isDark': isDark,
      'streak': streak,
      'longestStreak': longestStreak,
      'lastDate': lastDate,
      'completedTargets': completedTargets,
      'favorites': favorites,
      'customZikrs': customZikrs.map((z) => z.toJson()).toList(),
      'todayByZikr': todayByZikr,
    });
  }

  // ---------------------------------------------------------------------
  // Counting actions
  // ---------------------------------------------------------------------

  /// Returns true when this tap just completed the target (so the UI can
  /// show the celebratory toast/animation).
  bool increment() {
    final zikr = currentZikr;
    final data = _ensureTodayEntry(zikr.id);
    if (data['count'] == 0) {
      data['target'] = target < 1 ? 100 : target;
    }
    target = data['target']!;
    data['count'] = (data['count'] ?? 0) + 1;
    data['target'] = target;
    todayByZikr[zikr.id] = data;
    count = data['count']!;

    _syncTodayRecord();
    _recomputeTotal();
    _recalculateStreak();

    final completed = count == target;
    if (completed) completedTargets += 1;

    _persist();
    notifyListeners();
    return completed;
  }

  void undo() {
    if (count <= 0) return;
    final zikr = currentZikr;
    final data = _ensureTodayEntry(zikr.id);
    final c = data['count'] ?? 0;
    data['count'] = c > 0 ? c - 1 : 0;
    todayByZikr[zikr.id] = data;

    _syncTodayRecord();
    _recomputeTotal();
    _recalculateStreak();
    _persist();
    notifyListeners();
  }

  void resetCurrent() {
    if (count <= 0) return;
    final zikr = currentZikr;
    final data = _ensureTodayEntry(zikr.id);
    data['count'] = 0;
    todayByZikr[zikr.id] = data;

    _syncTodayRecord();
    _recomputeTotal();
    _recalculateStreak();
    _persist();
    notifyListeners();
  }

  /// Deletes just today's counting record for [id] (used from the "today's
  /// breakdown" list) without touching the custom-zikr definition itself.
  void deleteTodayEntry(String id) {
    final data = todayByZikr[id];
    if (data == null || (data['count'] ?? 0) <= 0) return;
    todayByZikr.remove(id);
    if (selectedZikr == id) count = 0;

    _syncTodayRecord();
    _recomputeTotal();
    _recalculateStreak();
    _persist();
    notifyListeners();
  }

  void selectTarget(int t) {
    if (t < 1) return;
    target = t;
    final data = todayByZikr[selectedZikr];
    if (data != null) {
      data['target'] = t;
      data['count'] = count;
      todayByZikr[selectedZikr] = data;
    }
    _syncTodayRecord();
    _persist();
    notifyListeners();
  }

  /// Selects a zikr and resumes its saved progress for today (same as the
  /// web version's "Resume" behaviour).
  void selectZikr(String id) {
    if (!allZikrs.any((z) => z.id == id)) return;
    selectedZikr = id;
    final data = todayByZikr[id];
    if (data != null) {
      count = data['count'] ?? 0;
      target = (data['target'] ?? 100) < 1 ? 100 : data['target']!;
    } else {
      count = 0;
      if (target < 1) target = 100;
    }
    _persist();
    notifyListeners();
  }

  void toggleFavorite(String id) {
    if (favorites.contains(id)) {
      favorites.remove(id);
    } else {
      favorites.add(id);
    }
    _persist();
    notifyListeners();
  }

  void addCustomZikr({
    required String arabic,
    required String name,
    required String translation,
  }) {
    final id =
        'custom_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
    final zikr = Zikr(id: id, arabic: arabic, name: name, translation: translation, isCustom: true);
    customZikrs.add(zikr);
    selectedZikr = id;
    count = 0;
    todayByZikr[id] = {'count': 0, 'target': target < 1 ? 100 : target};
    _persist();
    notifyListeners();
  }

  void editCustomZikr(
    String id, {
    required String arabic,
    required String name,
    required String translation,
  }) {
    final idx = customZikrs.indexWhere((z) => z.id == id);
    if (idx == -1) return;
    customZikrs[idx] =
        Zikr(id: id, arabic: arabic, name: name, translation: translation, isCustom: true);
    _persist();
    notifyListeners();
  }

  void deleteCustomZikr(String id) {
    customZikrs.removeWhere((z) => z.id == id);
    todayByZikr.remove(id);
    favorites.remove(id);
    if (selectedZikr == id) {
      selectedZikr = builtInAzkar.first.id;
      final data = todayByZikr[selectedZikr];
      count = data?['count'] ?? 0;
      target = (data?['target'] ?? (target < 1 ? 100 : target));
    }
    _syncTodayRecord();
    _recomputeTotal();
    _recalculateStreak();
    _persist();
    notifyListeners();
  }

  void toggleTheme() {
    isDark = !isDark;
    _persist();
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Stats / history
  // ---------------------------------------------------------------------

  int sumHistory(int days) => _sumHistoryFromRecords(days);

  int get favoritesCount => favorites.length;

  int get activeZikrsToday =>
      todayByZikr.values.where((v) => (v['count'] ?? 0) > 0).length;

  List<MapEntry<String, Map<String, int>>> get todayBreakdown {
    final entries = todayByZikr.entries.where((e) => (e.value['count'] ?? 0) > 0).toList();
    entries.sort((a, b) => (b.value['count'] ?? 0).compareTo(a.value['count'] ?? 0));
    return entries;
  }

  List<Map<String, dynamic>> zikrHistoryRows(String id, String period) {
    final rows = <Map<String, dynamic>>[];
    final now = DateTime.now();
    final base = DateTime(now.year, now.month, now.day);
    final keys = _dailyBox.keys.map((k) => k.toString()).toList()..sort();
    for (final key in keys.reversed) {
      DateTime d;
      try {
        d = DateTime.parse(key);
      } catch (_) {
        continue;
      }
      final age = base.difference(d).inDays;
      if (age < 0) continue;
      if (period != 'all' && age >= (int.tryParse(period) ?? 0)) continue;
      final rec = _rawDailyRecord(key);
      final entry = _zikrEntryFromRecord(rec, id);
      if (entry['count']! > 0) {
        rows.add({'date': key, 'count': entry['count'], 'target': entry['target']});
      }
    }
    return rows;
  }

  // ---------------------------------------------------------------------
  // Backup / restore (replaces the web version's JSON download/upload)
  // ---------------------------------------------------------------------

  Map<String, dynamic> exportBackup() {
    final dailyRecords = <String, dynamic>{};
    for (final key in _dailyBox.keys) {
      dailyRecords[key.toString()] =
          Map<String, dynamic>.from(_dailyBox.get(key) as Map);
    }
    return {
      'app': 'ZikrFlow',
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'data': {
        'selectedZikr': selectedZikr,
        'target': target,
        'isDark': isDark,
        'streak': streak,
        'longestStreak': longestStreak,
        'lastDate': lastDate,
        'completedTargets': completedTargets,
        'favorites': favorites,
        'customZikrs': customZikrs.map((z) => z.toJson()).toList(),
        'todayByZikr': todayByZikr,
        'dailyRecords': dailyRecords,
      },
    };
  }

  Future<void> importBackup(Map<String, dynamic> backup) async {
    final data = Map<String, dynamic>.from(backup['data'] as Map);

    selectedZikr = (data['selectedZikr'] as String?) ?? selectedZikr;
    target = ((data['target'] as num?) ?? target).toInt();
    isDark = (data['isDark'] as bool?) ?? isDark;
    streak = ((data['streak'] as num?) ?? 0).toInt();
    longestStreak = ((data['longestStreak'] as num?) ?? 0).toInt();
    lastDate = data['lastDate'] as String?;
    completedTargets = ((data['completedTargets'] as num?) ?? 0).toInt();
    favorites = List<String>.from((data['favorites'] as List?) ?? []);
    customZikrs = ((data['customZikrs'] as List?) ?? [])
        .map((e) => Zikr.fromJson(Map<dynamic, dynamic>.from(e as Map)))
        .toList();

    todayByZikr = {};
    (Map<dynamic, dynamic>.from(data['todayByZikr'] ?? {})).forEach((k, v) {
      final m = Map<dynamic, dynamic>.from(v as Map);
      todayByZikr[k.toString()] = {
        'count': ((m['count'] as num?) ?? 0).toInt(),
        'target': ((m['target'] as num?) ?? 100).toInt(),
      };
    });

    await _dailyBox.clear();
    final records = Map<dynamic, dynamic>.from(data['dailyRecords'] ?? {});
    for (final entry in records.entries) {
      await _dailyBox.put(
        entry.key.toString(),
        Map<String, dynamic>.from(entry.value as Map),
      );
    }

    if (target < 1) target = 100;
    _checkDay();
    _syncTodayRecord();
    _recomputeTotal();
    _recalculateStreak();
    _persist();
    notifyListeners();
  }
}
