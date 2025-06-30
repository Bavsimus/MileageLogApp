// lib/models/arac_model.dart

import '../models/database_helper.dart';

class AracModel {
  final int? id;
  final String plaka;
  final int guzergahId;
  final int gunBasiKm; // <-- DEĞİŞTİ: double -> int
  final String kmAralik;
  final String haftasonuDurumu;
  final String marka;
  final DateTime? muayeneTarihi;
  final DateTime? kaskoTarihi;

  AracModel({
    this.id,
    required this.plaka,
    required this.guzergahId,
    required this.gunBasiKm, // <-- DEĞİŞTİ
    required this.kmAralik,
    required this.haftasonuDurumu,
    required this.marka,
    this.muayeneTarihi,
    this.kaskoTarihi,
  });

  Map<String, dynamic> toMap() {
    return {
      DatabaseHelper.columnId: id,
      DatabaseHelper.columnPlaka: plaka,
      DatabaseHelper.columnMarka: marka,
      DatabaseHelper.columnAracGuzergahId: guzergahId,
      DatabaseHelper.columnKmAralik: kmAralik,
      DatabaseHelper.columnGunBasiKm: gunBasiKm, // <-- Değişiklik yok, int olarak kaydedilecek
      DatabaseHelper.columnHaftasonuDurumu: haftasonuDurumu,
      DatabaseHelper.columnMuayeneTarihi: muayeneTarihi?.toIso8601String(),
      DatabaseHelper.columnKaskoTarihi: kaskoTarihi?.toIso8601String(),
    };
  }

  factory AracModel.fromMap(Map<String, dynamic> map) {
    return AracModel(
      id: map[DatabaseHelper.columnId],
      plaka: map[DatabaseHelper.columnPlaka] ?? '',
      marka: map[DatabaseHelper.columnMarka] ?? 'Belirtilmemiş',
      guzergahId: map[DatabaseHelper.columnAracGuzergahId] ?? 0,
      // --- DEĞİŞİKLİK BURADA ---
      // Veritabanından gelen sayısal değeri int'e çeviriyoruz.
      gunBasiKm: (map[DatabaseHelper.columnGunBasiKm] as num?)?.toInt() ?? 0,
      kmAralik: map[DatabaseHelper.columnKmAralik] ?? '',
      haftasonuDurumu: map[DatabaseHelper.columnHaftasonuDurumu] ?? '',
      muayeneTarihi: map[DatabaseHelper.columnMuayeneTarihi] != null
          ? DateTime.tryParse(map[DatabaseHelper.columnMuayeneTarihi])
          : null,
      kaskoTarihi: map[DatabaseHelper.columnKaskoTarihi] != null
          ? DateTime.tryParse(map[DatabaseHelper.columnKaskoTarihi])
          : null,
    );
  }
}