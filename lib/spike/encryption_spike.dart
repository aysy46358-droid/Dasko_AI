
import 'dart:io';

import 'package:sqlite3/sqlite3.dart';

/// اختبار تجريبي فقط، وليس محرك الذاكرة الإنتاجي لـ Dasko AI.
Future<void> runEncryptionSpike() async {
  final tempDir =
      await Directory.systemTemp.createTemp('dasko_encryption_spike_');

  final dbPath = '${tempDir.path}/dasko_spike.db';

  // مفتاح اختباري فقط. لا تستخدمه في بيانات حقيقية.
  const testKey = 'Dasko-Spike-Test-Key-2026';
  const wrongKey = 'Definitely-Wrong-Test-Key';

  Database? db;
  Database? wrongDb;

  try {
    // 1. فتح قاعدة جديدة وضبط المفتاح قبل أي استعلام آخر.
    db = sqlite3.open(dbPath);
    db.execute("PRAGMA key = '$testKey'");

    // 2. إنشاء جدول وكتابة بيانات عربية.
    db.execute('''
      CREATE TABLE notes (
        id INTEGER PRIMARY KEY,
        body TEXT NOT NULL
      )
    ''');

    db.execute(
      'INSERT INTO notes (body) VALUES (?)',
      ['الذاكرة العربية المشفرة في Dasko AI'],
    );

    final rows = db.select('SELECT body FROM notes');

    if (rows.isEmpty ||
        rows.first['body'] != 'الذاكرة العربية المشفرة في Dasko AI') {
      throw StateError('FAIL: Arabic read/write test');
    }

    print('PASS: Arabic read/write');

    // 3. التحقق من توفر FTS5 والبحث عن كلمة عربية.
    db.execute('CREATE VIRTUAL TABLE notes_fts USING fts5(body)');

    db.execute(
      'INSERT INTO notes_fts (body) VALUES (?)',
      ['الذاكرة العربية المشفرة في Dasko AI'],
    );

    final matches = db.select(
      'SELECT body FROM notes_fts WHERE notes_fts MATCH ?',
      ['الذاكرة'],
    );

    if (matches.isEmpty) {
      throw StateError('FAIL: Arabic FTS5 search');
    }

    print('PASS: Arabic FTS5 search');

    // 4. التأكد من أن الملف لا يبدأ بترويسة SQLite العادية.
    final bytes = await File(dbPath).readAsBytes();
    const sqliteHeader = <int>[
      83, 81, 76, 105, 116, 101, 32, 102,
      111, 114, 109, 97, 116, 32, 51, 0,
    ];

    final headerIsPlainSqlite = bytes.length >= 16 &&
        List<int>.generate(16, (i) => bytes[i]).toString() ==
            sqliteHeader.toString();

    if (headerIsPlainSqlite) {
      throw StateError(
        'FAIL: Database still has the standard SQLite header',
      );
    }

    print('PASS: No standard plaintext SQLite header');

    // 5. إغلاق الاتصال الصحيح قبل تجربة المفتاح الخاطئ.
    db.dispose();
    db = null;

    var wrongKeyRejected = false;

    try {
      wrongDb = sqlite3.open(dbPath);
      wrongDb.execute("PRAGMA key = '$wrongKey'");

      // قراءة البيانات هي الاختبار؛ ضبط المفتاح وحده لا يكفي.
      wrongDb.select('SELECT * FROM notes');
    } catch (_) {
      wrongKeyRejected = true;
    } finally {
      wrongDb?.dispose();
      wrongDb = null;
    }

    if (!wrongKeyRejected) {
      throw StateError('FAIL: Wrong key was not rejected');
    }

    print('PASS: Wrong key rejected');

    print('SQLite version: ${sqlite3.version}');
    print('ALL SPIKE CHECKS PASSED');
  } finally {
    db?.dispose();
    wrongDb?.dispose();

    // قاعدة مؤقتة للاختبار فقط؛ تُحذف بعد انتهاء الاختبار.
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  }
}
