import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import '../models/arac_model.dart';
import '../models/guzergah_model.dart';

class DatabaseHelper {
  static const _databaseName = "AracTakip.db";
  static const _databaseVersion = 2;

  // --- Tablo İsimleri ---
  static const tableAraclar = 'araclar';
  static const tableGuzergahlar = 'guzergahlar';

  // --- Ortak Sütun Adı ---
  static const columnId = 'id';

  // --- Araclar Tablosu Sütunları ---
  static const columnPlaka = 'plaka';
  static const columnMarka = 'marka';
  static const columnKmAralik = 'kmAralik';
  static const columnGunBasiKm = 'gunBasiKm';
  static const columnHaftasonuDurumu = 'haftasonuDurumu';
  static const columnAracGuzergahId = 'guzergah_id'; // İsim çakışmasını önlemek için değiştirildi
  static const columnMuayeneTarihi = 'muayene_tarihi';
  static const columnKaskoTarihi = 'kasko_tarihi';

  // --- Guzergahlar Tablosu Sütunları ---
  static const columnGuzergahName = 'name';

  // --- Singleton Class Yapısı ---
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  _initDatabase() async {
  Directory documentsDirectory = await getApplicationDocumentsDirectory();
  String path = join(documentsDirectory.path, _databaseName);
  return await openDatabase(path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade, // <-- YENİ EKLENDİ
  );
}

  // --- TABLO OLUŞTURMA (DÜZELTİLMİŞ) ---
  Future _onCreate(Database db, int version) async {
  // Önce Güzergahlar tablosu
  await db.execute('''
    CREATE TABLE $tableGuzergahlar (
      $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
      $columnGuzergahName TEXT NOT NULL UNIQUE
    )
  ''');

  // Sonra Araçlar tablosu (TÜM SÜTUNLARI İÇEREN GÜNCEL HALİ)
  await db.execute('''
    CREATE TABLE $tableAraclar (
      $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
      $columnPlaka TEXT NOT NULL,
      $columnMarka TEXT NOT NULL,
      $columnAracGuzergahId INTEGER NOT NULL,
      $columnKmAralik TEXT NOT NULL,
      $columnGunBasiKm REAL NOT NULL,
      $columnHaftasonuDurumu TEXT NOT NULL,
      $columnMuayeneTarihi TEXT, -- YENİ SÜTUN BURADA DA OLMALI
      $columnKaskoTarihi TEXT,   -- YENİ SÜTUN BURADA DA OLMALI
      FOREIGN KEY ($columnAracGuzergahId) REFERENCES $tableGuzergahlar ($columnId) 
    )
  ''');
}

  // lib/helpers/database_helper.dart

Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
  if (oldVersion < 2) {
    // Sütunların var olup olmadığını kontrol etmek için tablonun bilgisini al
    var tableInfo = await db.rawQuery('PRAGMA table_info($tableAraclar)');
    List<String> existingColumns = tableInfo.map((row) => row['name'] as String).toList();

    // Sadece eksikse ekle
    if (!existingColumns.contains(columnMuayeneTarihi)) {
      await db.execute('ALTER TABLE $tableAraclar ADD COLUMN $columnMuayeneTarihi TEXT');
    }
    if (!existingColumns.contains(columnKaskoTarihi)) {
      await db.execute('ALTER TABLE $tableAraclar ADD COLUMN $columnKaskoTarihi TEXT');
    }
  }
}


  // --- ARAÇ CRUD METOTLARI ---
  Future<int> insert(AracModel arac) async {
    Database db = await instance.database;
    return await db.insert(tableAraclar, arac.toMap());
  }

  Future<List<AracModel>> getAllAraclar() async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(tableAraclar);
    return List.generate(maps.length, (i) {
      return AracModel.fromMap(maps[i]);
    });
  }

  Future<int> update(AracModel arac) async {
    Database db = await instance.database;
    int id = arac.id!;
    return await db.update(tableAraclar, arac.toMap(), where: '$columnId = ?', whereArgs: [id]);
  }

  Future<int> delete(int id) async {
    Database db = await instance.database;
    return await db.delete(tableAraclar, where: '$columnId = ?', whereArgs: [id]);
  }

  // --- GÜZERGAH CRUD METOTLARI ---
  Future<int> insertGuzergah(String guzergahAdi) async {
    Database db = await instance.database;
    return await db.insert(tableGuzergahlar, {columnGuzergahName: guzergahAdi});
  }

  Future<List<GuzergahModel>> getAllGuzergahlar() async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(tableGuzergahlar);
    return List.generate(maps.length, (i) {
      return GuzergahModel.fromMap(maps[i]);
    });
  }

  Future<int> deleteGuzergah(int id) async {
    Database db = await instance.database;
    return await db.delete(tableGuzergahlar, where: '$columnId = ?', whereArgs: [id]);
  }
}