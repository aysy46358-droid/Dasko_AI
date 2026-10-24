
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

class SpikeStep {
  const SpikeStep(this.name, this.passed, this.detail);

  final String name;
  final bool passed;
  final String detail;
}

Future<List<SpikeStep>> runEncryptionSpike() async {
  final steps = <SpikeStep>[];

  void step(String name, String Function() body) {
    try {
      steps.add(SpikeStep(name, true, body()));
    } catch (error) {
      steps.add(SpikeStep(name, false, error.toString()));
    }
  }

  final directory = await getApplicationSupportDirectory();
  final path = '${directory.path}/dasko_spike.db';

  for (final suffix in const ['', '-wal', '-shm', '-journal']) {
    final file = File('$path$suffix');
    if (file.existsSync()) {
      file.deleteSync();
    }
  }

  final random = Random.secure();
  final passphrase = base64UrlEncode(
    List<int>.generate(32, (_) => random.nextInt(256)),
  ).replaceAll('=', '');

  const arabicText = 'مرحباً بك في داسكو';

  Database? db;

  try {
    step('فتح قاعدة وتفعيل مفتاح التشفير', () {
      db = sqlite3.open(path);
      final cipher = db!.select('PRAGMA cipher;');

      if (cipher.isEmpty) {
        throw StateError('المحرك لا يدعم التشفير (PRAGMA cipher فارغ)');
      }

      db!.execute("PRAGMA key = '$passphrase';");
      return 'المحرك: ${cipher.first.columnAt(0)}';
    });

    if (db == null) {
      return steps;
    }

    step('كتابة وقراءة نص عربي', () {
      db!.execute(
        'CREATE TABLE messages (id TEXT PRIMARY KEY, content TEXT NOT NULL)',
      );

      db!.execute(
        'INSERT INTO messages (id, content) VALUES (?, ?)',
        ['m1', arabicText],
      );

      final rows = db!.select(
        'SELECT content FROM messages WHERE id = ?',
        ['m1'],
      );

      if (rows.isEmpty || rows.first['content'] != arabicText) {
        throw StateError('النص المقروء لا يطابق المكتوب');
      }

      return 'تمت القراءة بنجاح';
    });

    step('بحث FTS5 بالعربية', () {
      db!.execute('CREATE VIRTUAL TABLE memory_fts USING fts5(content)');

      db!.execute(
        'INSERT INTO memory_fts (content) VALUES (?)',
        ['أحب القهوة الصباحية وأعمل على مشروع داسكو'],
      );

      final hits = db!.select(
        'SELECT content FROM memory_fts WHERE memory_fts MATCH ?',
        ['القهوة'],
      );

      if (hits.isEmpty) {
        throw StateError('لم يُعثر على نتيجة');
      }

      return 'عدد النتائج: ${hits.length}';
    });

    step('إصدار SQLite', () {
      final row = db!.select('SELECT sqlite_version() AS v').first;
      return '${row['v']}';
    });

    step('إغلاق قاعدة البيانات', () {
      db!.close();
      db = null;
      return 'تم الإغلاق';
    });

    step('ترويسة الملف ليست SQLite عادياً', () {
      final raf = File(path).openSync();

      try {
        final header = String.fromCharCodes(raf.readSync(15));

        if (header == 'SQLite format 3') {
          throw StateError('ترويسة الملف مكشوفة: القاعدة غير مشفّرة');
        }

        return 'الترويسة مشفّرة';
      } finally {
        raf.closeSync();
      }
    });

    step('إعادة الفتح بالمفتاح الصحيح', () {
      final reopened = sqlite3.open(path);

      try {
        reopened.execute("PRAGMA key = '$passphrase';");

        final rows = reopened.select(
          'SELECT content FROM messages WHERE id = ?',
          ['m1'],
        );

        if (rows.isEmpty || rows.first['content'] != arabicText) {
          throw StateError('البيانات لم تُسترجع');
        }

        return 'البيانات سليمة بعد الإغلاق والفتح';
      } finally {
        reopened.close();
      }
    });

    step('رفض المفتاح الخاطئ', () {
      final wrong = sqlite3.open(path);

      try {
        wrong.execute("PRAGMA key = 'wrong-key-123';");
        wrong.select('SELECT count(*) FROM sqlite_master');
      } on SqliteException {
        return 'رُفض المفتاح الخاطئ كما هو متوقع';
      } finally {
        wrong.close();
      }

      throw StateError('فُتحت القاعدة بمفتاح خاطئ');
    });
  } finally {
    db?.close();
  }

  return steps;
}

class EncryptionSpikeScreen extends StatefulWidget {
  const EncryptionSpikeScreen({super.key});

  @override
  State<EncryptionSpikeScreen> createState() =>
      _EncryptionSpikeScreenState();
}

class _EncryptionSpikeScreenState extends State<EncryptionSpikeScreen> {
  late final Future<List<SpikeStep>> _future;

  @override
  void initState() {
    super.initState();
    _future = runEncryptionSpike();
  }

  String _report(List<SpikeStep> steps) {
    return steps
        .map((s) => '${s.passed ? 'PASS' : 'FAIL'} | ${s.name} | ${s.detail}')
        .join('\n');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تجربة القاعدة المشفّرة'),
        backgroundColor: Colors.black,
      ),
      body: FutureBuilder<List<SpikeStep>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: SelectableText('خطأ غير متوقع:\n${snapshot.error}'),
            );
          }

          final steps = snapshot.data ?? const <SpikeStep>[];
          final passedCount = steps.where((s) => s.passed).length;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'النتيجة: $passedCount من ${steps.length}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              for (final s in steps)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    s.passed ? Icons.check_circle : Icons.cancel,
                    color: s.passed
                        ? Colors.greenAccent
                        : Colors.redAccent,
                  ),
                  title: Text(s.name),
                  subtitle: Text(s.detail),
                ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => Clipboard.setData(
                  ClipboardData(text: _report(steps)),
                ),
                icon: const Icon(Icons.copy),
                label: const Text('نسخ النتيجة'),
              ),
            ],
          );
        },
      ),
    );
  }
}
