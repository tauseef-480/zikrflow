import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import 'models.dart';
import 'store.dart';

/// Small color helper mirroring the web version's CSS variables for the
/// dark / light themes.
class _Palette {
  final bool dark;
  _Palette(this.dark);

  Color get bg => dark ? const Color(0xFF061713) : const Color(0xFFF4FAF7);
  Color get bg2 => dark ? const Color(0xFF0A211B) : const Color(0xFFE7F4ED);
  Color get card => dark ? Colors.white.withOpacity(.07) : Colors.white.withOpacity(.72);
  Color get card2 => dark ? Colors.white.withOpacity(.11) : Colors.white.withOpacity(.94);
  Color get border =>
      dark ? Colors.white.withOpacity(.12) : const Color(0xFF144632).withOpacity(.12);
  Color get text => dark ? const Color(0xFFF4FFF9) : const Color(0xFF10251D);
  Color get muted => dark ? const Color(0xFFA9C0B7) : const Color(0xFF61756C);
  Color get green => dark ? const Color(0xFF4ADE80) : const Color(0xFF168449);
  Color get gold => dark ? const Color(0xFFE8C76A) : const Color(0xFFAE8420);
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _searchController = TextEditingController();
  bool _favoritesOnly = false;
  int _ayatIndex = 0;
  String _historyPeriod = '7';
  String? _historyZikrId;

  @override
  void initState() {
    super.initState();
    _ayatIndex = DateTime.now().day % ayatList.length;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, textDirection: TextDirection.rtl), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ZikrStore>();
    final p = _Palette(store.isDark);
    final historyId = (_historyZikrId != null && store.allZikrs.any((z) => z.id == _historyZikrId))
        ? _historyZikrId!
        : store.selectedZikr;

    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            _header(store, p),
            const SizedBox(height: 16),
            _statsRow(store, p),
            const SizedBox(height: 20),
            _sectionTitle('ذکر منتخب کریں', 'اپنا پسندیدہ ذکر', p),
            const SizedBox(height: 8),
            _zikrSelector(store, p),
            const SizedBox(height: 20),
            _counterCard(store, p),
            const SizedBox(height: 20),
            _motivation(p),
            const SizedBox(height: 20),
            _sectionTitle('📊 آج کا ذکر', 'ذکر پر ٹچ کر کے Resume کریں', p),
            const SizedBox(height: 8),
            _todayBreakdown(store, p),
            const SizedBox(height: 20),
            _sectionTitle('📈 آپ کی پیش رفت', 'ذاتی ریکارڈ', p),
            const SizedBox(height: 8),
            _historyCard(store, p),
            const SizedBox(height: 20),
            _sectionTitle('📊 تفصیلی اعداد و شمار', 'ہفتہ اور ماہ', p),
            const SizedBox(height: 8),
            _detailedStats(store, p),
            const SizedBox(height: 20),
            _sectionTitle('🗓️ ذکر کی مکمل پیش رفت', 'دن، ہفتہ، ماہ اور تمام ریکارڈ', p),
            const SizedBox(height: 8),
            _zikrHistory(store, p, historyId),
            const SizedBox(height: 20),
            _backupSection(store, p),
            const SizedBox(height: 24),
            _footer(p),
          ],
        ),
      ),
    );
  }

  // -----------------------------------------------------------------
  // HEADER
  // -----------------------------------------------------------------
  Widget _header(ZikrStore store, _Palette p) {
    final ayat = ayatList[_ayatIndex % ayatList.length];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(20), border: Border.all(color: p.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: p.card2, borderRadius: BorderRadius.circular(14)),
                child: const Text('📿', style: TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ذِكر', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: p.text)),
                    Text('ZikrFlow', style: TextStyle(fontSize: 12, color: p.muted)),
                  ],
                ),
              ),
              IconButton(
                onPressed: store.toggleTheme,
                icon: Text(store.isDark ? '☾' : '☀', style: TextStyle(color: p.text, fontSize: 18)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () => setState(() => _ayatIndex = (_ayatIndex + 1) % ayatList.length),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: p.card2, borderRadius: BorderRadius.circular(14)),
              child: Column(
                children: [
                  Text(ayat.arabic, textAlign: TextAlign.center, style: TextStyle(fontSize: 17, height: 1.7, color: p.gold, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text(ayat.urdu, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: p.text)),
                  const SizedBox(height: 6),
                  Text(ayat.ref, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: p.muted)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------
  // STATS
  // -----------------------------------------------------------------
  Widget _statsRow(ZikrStore store, _Palette p) {
    final items = [
      ('📿', store.today, 'آج'),
      ('🔥', store.streak, 'مسلسل دن'),
      ('✳️', store.total, 'کل ذکر'),
      ('🎯', store.target, 'ہدف'),
    ];
    return Row(
      children: items
          .map((it) => Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: p.border)),
                  child: Column(
                    children: [
                      Text(it.$1, style: const TextStyle(fontSize: 18)),
                      const SizedBox(height: 6),
                      Text('${it.$2}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: p.text)),
                      const SizedBox(height: 2),
                      Text(it.$3, style: TextStyle(fontSize: 10, color: p.muted)),
                    ],
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _sectionTitle(String title, String subtitle, _Palette p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: p.text)),
        Text(subtitle, style: TextStyle(fontSize: 11, color: p.muted)),
      ],
    );
  }

  // -----------------------------------------------------------------
  // ZIKR SELECTOR
  // -----------------------------------------------------------------
  Widget _zikrSelector(ZikrStore store, _Palette p) {
    final query = _searchController.text.trim();
    final list = store.allZikrs.where((z) {
      if (_favoritesOnly && !store.isFavorite(z.id)) return false;
      if (query.isEmpty) return true;
      return z.name.contains(query) || z.arabic.contains(query) || z.translation.contains(query);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                textDirection: TextDirection.rtl,
                onChanged: (_) => setState(() {}),
                style: TextStyle(color: p.text),
                decoration: InputDecoration(
                  hintText: '🔍 ذکر تلاش کریں...',
                  hintStyle: TextStyle(color: p.muted),
                  filled: true,
                  fillColor: p.card,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: p.border)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: const Text('⭐ پسندیدہ'),
              selected: _favoritesOnly,
              onSelected: (v) => setState(() => _favoritesOnly = v),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...list.map((z) => _zikrTile(store, z, p)),
        const SizedBox(height: 4),
        OutlinedButton.icon(
          onPressed: () => _openZikrEditor(store),
          icon: const Text('➕'),
          label: const Text('اپنا ذکر شامل کریں'),
        ),
      ],
    );
  }

  Widget _zikrTile(ZikrStore store, Zikr z, _Palette p) {
    final selected = store.selectedZikr == z.id;
    final data = store.todayByZikr[z.id];
    final todayCount = data?['count'] ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: selected ? p.green.withOpacity(.15) : p.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => store.selectZikr(z.id),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () => store.toggleFavorite(z.id),
                  icon: Text(store.isFavorite(z.id) ? '⭐' : '☆', style: TextStyle(color: p.gold)),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(z.arabic, style: TextStyle(fontSize: 15, color: selected ? p.green : p.text, fontWeight: FontWeight.w700)),
                      Text(z.name, style: TextStyle(fontSize: 11, color: p.muted)),
                    ],
                  ),
                ),
                if (todayCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: p.card2, borderRadius: BorderRadius.circular(10)),
                    child: Text('$todayCount', style: TextStyle(fontSize: 12, color: p.text)),
                  ),
                if (z.isCustom) ...[
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _openZikrEditor(store, editing: z),
                    icon: const Text('✏️'),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _confirmDeleteCustomZikr(store, z),
                    icon: const Text('🗑️'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openZikrEditor(ZikrStore store, {Zikr? editing}) async {
    final arabicCtrl = TextEditingController(text: editing?.arabic ?? '');
    final nameCtrl = TextEditingController(text: editing?.name ?? '');
    final translationCtrl = TextEditingController(text: editing?.translation ?? '');
    final p = _Palette(store.isDark);

    await showDialog<void>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: p.bg2,
          title: Text(editing == null ? '➕ اپنا ذکر شامل کریں' : '✏️ ذکر میں ترمیم کریں', style: TextStyle(color: p.text)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: arabicCtrl, textDirection: TextDirection.rtl, decoration: const InputDecoration(labelText: '📿 عربی ذکر')),
                const SizedBox(height: 8),
                TextField(controller: nameCtrl, textDirection: TextDirection.rtl, decoration: const InputDecoration(labelText: '📝 ذکر کا نام')),
                const SizedBox(height: 8),
                TextField(
                  controller: translationCtrl,
                  textDirection: TextDirection.rtl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: '📖 ترجمہ — اختیاری'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('منسوخ')),
            FilledButton(
              onPressed: () {
                final arabic = arabicCtrl.text.trim();
                final name = nameCtrl.text.trim();
                if (arabic.isEmpty) {
                  _toast('براہ کرم عربی ذکر لکھیں');
                  return;
                }
                if (name.isEmpty) {
                  _toast('براہ کرم ذکر کا نام لکھیں');
                  return;
                }
                if (editing != null) {
                  store.editCustomZikr(editing.id, arabic: arabic, name: name, translation: translationCtrl.text.trim());
                  Navigator.pop(ctx);
                  _toast('Custom zikr تبدیل کر دیا گیا');
                } else {
                  store.addCustomZikr(arabic: arabic, name: name, translation: translationCtrl.text.trim());
                  Navigator.pop(ctx);
                  _toast('آپ کا ذکر کامیابی سے شامل ہوگیا');
                }
              },
              child: const Text('💾 محفوظ کریں'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteCustomZikr(ZikrStore store, Zikr z) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('کیا اس Custom Zikr کو حذف کرنا چاہتے ہیں؟'),
          content: Text(z.name),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('منسوخ')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حذف کریں')),
          ],
        ),
      ),
    );
    if (ok == true) {
      store.deleteCustomZikr(z.id);
      _toast('Custom zikr حذف کر دیا گیا');
    }
  }

  // -----------------------------------------------------------------
  // COUNTER CARD
  // -----------------------------------------------------------------
  Widget _counterCard(ZikrStore store, _Palette p) {
    final zikr = store.currentZikr;
    final progress = store.target > 0 ? (store.count / store.target).clamp(0.0, 1.0) : 0.0;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(22), border: Border.all(color: p.border)),
      child: Column(
        children: [
          Text(zikr.arabic, textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: p.text, height: 1.6)),
          if (zikr.translation.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(zikr.translation, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: p.muted)),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('ہدف', style: TextStyle(color: p.muted, fontSize: 12)),
              Text('${store.count} / ${store.target}', style: TextStyle(color: p.text, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(value: progress, minHeight: 10, backgroundColor: p.card2, valueColor: AlwaysStoppedAnimation(p.green)),
          ),
          const SizedBox(height: 26),
          GestureDetector(
            onTap: () => _onTapCount(store),
            child: Container(
              width: 170,
              height: 170,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [p.green.withOpacity(.25), p.card2]),
                border: Border.all(color: p.green, width: 3),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${store.count}', style: TextStyle(fontSize: 44, fontWeight: FontWeight.w900, color: p.text)),
                  const SizedBox(height: 4),
                  Text('ذکر کے لیے دبائیں', style: TextStyle(fontSize: 11, color: p.muted)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text('دائرے پر ٹچ کریں یا نیچے ذکر کا بٹن دبائیں', style: TextStyle(fontSize: 11, color: p.muted)),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: OutlinedButton(onPressed: store.undo, child: const Text('↶ واپس'))),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: p.green, foregroundColor: Colors.black),
                  onPressed: () => _onTapCount(store),
                  child: const Text('📿 ذکر شمار کریں'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: OutlinedButton(onPressed: () => _confirmReset(store), child: const Text('↻ صفر'))),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _targetChip(store, p, 33),
              _targetChip(store, p, 100),
              _targetChip(store, p, 300),
              _targetChip(store, p, 1000),
              ActionChip(label: const Text('اپنی تعداد'), onPressed: () => _customTargetDialog(store)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _targetChip(ZikrStore store, _Palette p, int value) {
    final active = store.target == value;
    return ChoiceChip(
      label: Text('$value'),
      selected: active,
      onSelected: (_) => store.selectTarget(value),
      selectedColor: p.green,
      labelStyle: TextStyle(color: active ? Colors.black : p.text),
    );
  }

  void _onTapCount(ZikrStore store) {
    final completed = store.increment();
    if (completed) _toast('ماشاءاللہ! ہدف مکمل ہوگیا 🤲');
  }

  Future<void> _confirmReset(ZikrStore store) async {
    if (store.count <= 0) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('کیا موجودہ ذکر کا شمار صفر کرنا چاہتے ہیں؟'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('منسوخ')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('صفر کریں')),
          ],
        ),
      ),
    );
    if (ok == true) {
      store.resetCurrent();
      _toast('موجودہ شمار صفر کر دیا گیا');
    }
  }

  Future<void> _customTargetDialog(ZikrStore store) async {
    final ctrl = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('اپنی تعداد مقرر کریں'),
          content: TextField(controller: ctrl, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'مثلاً 500')),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('منسوخ')),
            FilledButton(
              onPressed: () {
                final v = int.tryParse(ctrl.text.trim());
                if (v != null && v >= 1) {
                  store.selectTarget(v);
                  Navigator.pop(ctx);
                }
              },
              child: const Text('مقرر کریں'),
            ),
          ],
        ),
      ),
    );
  }

  // -----------------------------------------------------------------
  // MOTIVATION
  // -----------------------------------------------------------------
  Widget _motivation(_Palette p) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(18), border: Border.all(color: p.border)),
      child: Column(
        children: [
          const Text('🤲', style: TextStyle(fontSize: 28)),
          const SizedBox(height: 8),
          Text('ذکر کو اپنی روزمرہ زندگی کا حصہ بنائیں', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800, color: p.text)),
          const SizedBox(height: 8),
          Text(
            'اللہ تعالیٰ کو کثرت سے یاد کرنا ایک عظیم عبادت ہے۔ اس ایپ کو اپنی ذاتی پیش رفت دیکھنے کے لیے استعمال کریں اور اخلاص کے ساتھ ذکر کرنے کی کوشش کریں۔ حقیقی اجر اللہ تعالیٰ ہی کے اختیار میں ہے۔',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: p.muted, height: 1.6),
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------
  // TODAY BREAKDOWN
  // -----------------------------------------------------------------
  Widget _todayBreakdown(ZikrStore store, _Palette p) {
    final entries = store.todayBreakdown;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(18), border: Border.all(color: p.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('آج کا کل ذکر', style: TextStyle(color: p.muted)),
              Text('${store.today}', style: TextStyle(color: p.text, fontWeight: FontWeight.w800, fontSize: 16)),
            ],
          ),
          const Divider(height: 24),
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'آج ابھی کوئی ذکر شمار نہیں ہوا۔\nاللہ تعالیٰ کا ذکر شروع کریں 🤲',
                textAlign: TextAlign.center,
                style: TextStyle(color: p.muted),
              ),
            )
          else
            ...entries.map((e) {
              final zikr = store.allZikrs.firstWhere((z) => z.id == e.key, orElse: () => builtInAzkar.first);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: InkWell(
                  onTap: () => store.selectZikr(e.key),
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(zikr.name, style: TextStyle(color: p.text, fontWeight: FontWeight.w600)),
                              Text('${e.value['count']} / ${e.value['target']}', style: TextStyle(color: p.muted, fontSize: 12)),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => store.deleteTodayEntry(e.key),
                          icon: const Text('🗑️'),
                          visualDensity: VisualDensity.compact,
                          tooltip: 'آج کا شمار حذف کریں',
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------
  // HISTORY SUMMARY
  // -----------------------------------------------------------------
  Widget _historyCard(ZikrStore store, _Palette p) {
    final rows = [
      ('آج کا ذکر', store.today),
      ('کل کا ذکر', store.yesterday),
      ('اس ہفتے کا ذکر', store.week),
      ('کل مجموعہ', store.total),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(18), border: Border.all(color: p.border)),
      child: Column(
        children: rows
            .map((r) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(r.$1, style: TextStyle(color: p.muted)),
                      Text('${r.$2}', style: TextStyle(color: p.text, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  // -----------------------------------------------------------------
  // DETAILED STATS + ACHIEVEMENTS
  // -----------------------------------------------------------------
  Widget _detailedStats(ZikrStore store, _Palette p) {
    final grid = [
      ('گزشتہ 7 دن', store.sumHistory(7)),
      ('گزشتہ 30 دن', store.sumHistory(30)),
      ('پسندیدہ اذکار', store.favoritesCount),
      ('آج کے فعال اذکار', store.activeZikrsToday),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(18), border: Border.all(color: p.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.2,
            children: grid
                .map((g) => Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: p.card2, borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('${g.$2}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: p.text)),
                          Text(g.$1, style: TextStyle(fontSize: 10, color: p.muted)),
                        ],
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 10),
          Text('یہ اعداد آپ کی ذاتی counting پر مبنی ہیں۔', style: TextStyle(fontSize: 11, color: p.muted)),
          const SizedBox(height: 12),
          ...achievementDefs.map((a) {
            final unlocked = a.metric == 'total' ? store.total >= a.threshold : store.streak >= a.threshold;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: unlocked ? p.green.withOpacity(.14) : p.card2, borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  Text(a.icon, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a.title, style: TextStyle(color: p.text, fontWeight: FontWeight.w700, fontSize: 13)),
                        Text(a.desc, style: TextStyle(color: p.muted, fontSize: 11)),
                      ],
                    ),
                  ),
                  Text(unlocked ? 'مکمل ✓' : 'جاری', style: TextStyle(color: unlocked ? p.green : p.muted, fontSize: 11, fontWeight: FontWeight.w700)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------
  // PER-ZIKR HISTORY
  // -----------------------------------------------------------------
  Widget _zikrHistory(ZikrStore store, _Palette p, String historyId) {
    final rows = store.zikrHistoryRows(historyId, _historyPeriod);
    final total = rows.fold<int>(0, (sum, r) => sum + (r['count'] as int));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(18), border: Border.all(color: p.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<String>(
            value: historyId,
            items: store.allZikrs
                .map((z) => DropdownMenuItem(value: z.id, child: Text('${z.arabic} — ${z.name}', overflow: TextOverflow.ellipsis)))
                .toList(),
            onChanged: (v) => setState(() => _historyZikrId = v),
            decoration: InputDecoration(filled: true, fillColor: p.card2, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              _periodChip('7', '7 دن', p),
              _periodChip('30', '30 دن', p),
              _periodChip('90', '3 ماہ', p),
              _periodChip('all', 'تمام', p),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('مجموعہ', style: TextStyle(color: p.muted)),
              Text('$total', style: TextStyle(color: p.text, fontWeight: FontWeight.w800)),
            ],
          ),
          const Divider(height: 24),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text('اس مدت میں اس ذکر کا کوئی counting record موجود نہیں۔', textAlign: TextAlign.center, style: TextStyle(color: p.muted)),
            )
          else
            ...rows.map((r) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(r['date'] as String, style: TextStyle(color: p.muted, fontSize: 12)),
                      Text('${r['count']} / ${r['target']}', style: TextStyle(color: p.text, fontWeight: FontWeight.w700)),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

  Widget _periodChip(String value, String label, _Palette p) {
    final active = _historyPeriod == value;
    return ChoiceChip(
      label: Text(label),
      selected: active,
      onSelected: (_) => setState(() => _historyPeriod = value),
      selectedColor: p.green,
      labelStyle: TextStyle(color: active ? Colors.black : p.text),
    );
  }

  // -----------------------------------------------------------------
  // BACKUP
  // -----------------------------------------------------------------
  Widget _backupSection(ZikrStore store, _Palette p) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(18), border: Border.all(color: p.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('💾 ڈیٹا Backup', style: TextStyle(color: p.text, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: OutlinedButton(onPressed: () => _exportBackup(store), child: const Text('📤 Backup بنائیں'))),
              const SizedBox(width: 10),
              Expanded(child: OutlinedButton(onPressed: () => _importBackup(store), child: const Text('📥 Backup بحال کریں'))),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '⚠️ اہم: Backup file کو محفوظ جگہ پر ضرور رکھیں۔ App uninstall یا device reset ہونے کی صورت میں device data ضائع ہو سکتا ہے۔',
            style: TextStyle(fontSize: 11, color: p.muted, height: 1.5),
          ),
        ],
      ),
    );
  }

  Future<void> _exportBackup(ZikrStore store) async {
    try {
      final backup = store.exportBackup();
      final jsonStr = const JsonEncoder.withIndent('  ').convert(backup);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/tasbeeh-backup-${store.dateKey()}.json');
      await file.writeAsString(jsonStr);
      await Share.shareXFiles([XFile(file.path)], text: 'ZikrFlow Backup');
    } catch (_) {
      _toast('Backup بنانے میں مسئلہ پیش آیا');
    }
  }

  Future<void> _importBackup(ZikrStore store) async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json']);
      if (result == null || result.files.single.path == null) return;
      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      final backup = json.decode(content) as Map<String, dynamic>;
      if (backup['data'] is! Map) throw const FormatException('invalid backup');

      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('Backup بحال کریں؟'),
            content: const Text('Backup بحال کرنے سے موجودہ progress، settings اور custom zikr تبدیل ہو جائیں گے۔ کیا آپ جاری رکھنا چاہتے ہیں؟'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('منسوخ')),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('بحال کریں')),
            ],
          ),
        ),
      );
      if (ok == true) {
        await store.importBackup(backup);
        _toast('Backup بحال ہو گئی');
      }
    } catch (_) {
      _toast('Backup file درست نہیں ہے');
    }
  }

  // -----------------------------------------------------------------
  // FOOTER
  // -----------------------------------------------------------------
  Widget _footer(_Palette p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('📿 ذکر — Pro Tasbeeh & Zikr', textAlign: TextAlign.center, style: TextStyle(color: p.text, fontWeight: FontWeight.w700)),
        const SizedBox(height: 14),
        _infoTile('📖 ایپ کا استعمال', p, [
          'اوپر سے اپنا ذکر منتخب کریں، پھر دائرے یا "ذکر شمار کریں" بٹن کو ٹچ کر کے counting کریں۔',
          '• اوپر موجود فہرست سے اپنا پسندیدہ ذکر منتخب کریں۔',
          '• درمیان میں موجود بڑے دائرے کو ٹچ کریں۔',
          '• ہر ٹچ سے ایک ذکر شمار ہوگا۔',
          '• اگر count غلطی سے بڑھ جائے تو "واپس" دبائیں۔',
          '• "صفر" بٹن موجودہ منتخب ذکر کا شمار صفر کر دیتا ہے۔',
          '• 33، 100، 300 یا 1000 کا ہدف منتخب کیا جا سکتا ہے۔',
          '• "اپنی تعداد" کے ذریعے اپنی مرضی کا ہدف مقرر کریں۔',
          '• "اپنا ذکر شامل کریں" سے نیا custom zikr بنایا جا سکتا ہے۔',
          '• "آج کا ذکر" میں کسی ذکر پر ٹچ کر کے اس کی پچھلی progress دوبارہ Resume کی جا سکتی ہے۔',
          '• "آج کا ذکر" میں موجود 🗑️ سے صرف آج کا متعلقہ counting record حذف کیا جا سکتا ہے۔',
        ]),
        _infoTile('❓ مدد اور رہنمائی', p, [
          'اگر کسی feature کے استعمال میں مشکل ہو تو یہ رہنمائی دیکھیں۔ اہم data کے لیے Backup ضرور بنائیں۔',
          'Custom Zikr: "اپنا ذکر شامل کریں" دبائیں اور عربی ذکر، نام اور ترجمہ لکھ کر محفوظ کریں۔',
          'Edit: Custom zikr کے ساتھ موجود ✏️ بٹن سے معلومات تبدیل کی جا سکتی ہیں۔',
          'Delete: 🗑️ بٹن سے Custom Zikr مستقل طور پر delete کیا جا سکتا ہے۔ Built-in zikr delete نہیں کیے جا سکتے۔',
          'Resume: "آج کا ذکر" میں کسی ذکر کو ٹچ کریں تو اس کی پچھلی progress دوبارہ counter میں آ جائے گی۔',
          'Backup: Backup بنائیں اور JSON file کو محفوظ جگہ پر رکھیں۔ App uninstall یا device reset ہونے کی صورت میں data ضائع ہو سکتا ہے۔',
          'Privacy: یہ app آپ کے data کو صرف اسی device پر محفوظ رکھتی ہے۔ کسی online account کی ضرورت نہیں۔',
          'اہم یاد دہانی: ذکر کو صرف numbers مکمل کرنے کی دوڑ نہ بنائیں۔ اصل مقصد اللہ تعالیٰ کی یاد، اخلاص اور عبادت ہے۔',
        ]),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: p.border)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('📞 Help Desk', style: TextStyle(color: p.text, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text('مدد یا کسی بھی سوال کے لیے درج ذیل رابطے کے ذریعے ہم سے رابطہ کریں۔', style: TextStyle(color: p.muted, fontSize: 12)),
              const SizedBox(height: 10),
              SelectableText('📧 ahmadkhantk480@gmail.com', style: TextStyle(color: p.text), textDirection: TextDirection.ltr),
              const SizedBox(height: 6),
              SelectableText('📞 +92 319 8054094', style: TextStyle(color: p.text), textDirection: TextDirection.ltr),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'آپ کی ذکر کی progress اسی device میں محفوظ رہتی ہے۔ اہم data کے لیے Backup ضرور بنائیں۔\nحقیقی اجر اللہ تعالیٰ کے اختیار میں ہے۔\n\nCreated by Tauseef Ahmad',
          textAlign: TextAlign.center,
          style: TextStyle(color: p.muted, fontSize: 11, height: 1.6),
        ),
      ],
    );
  }

  Widget _infoTile(String title, _Palette p, List<String> lines) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: p.border)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(title, style: TextStyle(color: p.text, fontWeight: FontWeight.w700, fontSize: 13)),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: lines
                    .map((l) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(l, style: TextStyle(color: p.muted, fontSize: 12.5, height: 1.6)),
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
